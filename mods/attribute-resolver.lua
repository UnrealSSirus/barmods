-- Attributes Resolver v1.3
local function parse_all_stats_factors(v)
    -- Accept number | string (space-separated) | table (numbers/strings).
    local factors = {}
    local function push(x)
        local n = tonumber(x)
        if n then
            table.insert(factors, n)
        end
    end

    if type(v) == 'number' then
        push(v)
    elseif type(v) == 'string' then
        for token in string.gmatch(v, "%S+") do
            push(token)
        end
    elseif type(v) == 'table' then
        for _, x in ipairs(v) do
            push(x)
        end
    end

    return factors
end

local SOLAR_UPKEEP_UNITS = "|armadvsol|legsolar|corsolar|armsolar|legadvsol|coradvsol|" -- temp test

local function scale_all_stats(name, unit, factor)
    if type(factor) ~= 'number' then return end
    if factor == 1 then return end
    if factor == 0 then return end
    local inv = 1 / factor
    local u = unit
    local ceil = math.ceil
    local function mul(k, m)
        local v = u[k]
        if type(v) == 'number' then u[k] = v * m end
    end
    local function mulceil(k, m)
        local v = u[k]
        if type(v) == 'number' then u[k] = ceil(v * m) end
    end

    -- Basic stats
    mulceil('health', factor)
    for _, k in ipairs({
        'sightdistance','radardistance','sonardistance','seismicdistance','radardistancejam',
        'workertime','builddistance','turnrate','capturespeed','autoheal','idleautoheal',
    }) do
        mul(k, factor)
    end
    mul('speed', factor * 0.5)
    mulceil('cloakcost', 1 - factor)
    mulceil('cloakcostmoving', 1 - factor)
    if u.footprintx and u.footprintz then
        u.footprintx = ceil(u.footprintx / factor)
        u.footprintz = ceil(u.footprintz / factor)
    end

    -- Economy Stats
    for _, k in ipairs({'energystorage','metalstorage','energymake','windgenerator','extractsmetal'}) do
        mul(k, factor)
    end
    local eu = u.energyupkeep
    if type(eu) == 'number' then
        if eu < 0 then
            u.energyupkeep = eu * factor
        elseif eu > 0 then
            u.energyupkeep = eu * inv
        end
    end

    if type(u.customparams) == 'table' then
        local cap_v = u.customparams.energyconv_capacity
        local cap_n = tonumber(cap_v)
        if cap_n then
            local scaled_cap = ceil(cap_n * factor)
            if type(cap_v) == 'string' then
                u.customparams.energyconv_capacity = tostring(scaled_cap)
            else
                u.customparams.energyconv_capacity = scaled_cap
            end
        end

        local v = u.customparams.energyconv_efficiency
        local n = tonumber(v)
        if n then
            local scaled = n * factor
            if type(v) == 'string' then
                u.customparams.energyconv_efficiency = tostring(scaled)
            else
                u.customparams.energyconv_efficiency = scaled
            end
        end
    end

    -- Costs/build time:
    local costInv = inv
    if inv < 1 then
        costInv = 1 + ((inv - 1) * 0.25)
    end

    mulceil('buildtime', costInv)
    mulceil('buildcostmetal', costInv)
    mulceil('buildcostenergy', costInv)
    mulceil('metalcost', costInv)
    mulceil('energycost', costInv)

    local weaponBuff = factor
    if(factor > 1) then
        weaponBuff = factor * 0.5
    end

    -- Weapon stats: 
    if unit.weapondefs and type(unit.weapondefs) == 'table' then
        for _, wd in pairs(unit.weapondefs) do
            if type(wd) == 'table' then
                if type(wd.reloadtime) == 'number' then
                    wd.reloadtime = wd.reloadtime * (1 / weaponBuff)
                end
                if type(wd.range) == 'number' then
                    wd.range = wd.range * factor
                elseif type(wd.weaponrange) == 'number' then
                    wd.weaponrange = wd.weaponrange * factor
                end
                if wd.damage and type(wd.damage) == 'table' then
                    for dt, dv in pairs(wd.damage) do
                        if type(dv) == 'number' then
                            wd.damage[dt] = dv * weaponBuff
                        end
                    end
                end
                -- Weapon specific buffs
            end
        end
    end
end
local function serialize_modded_stats(ms)
    if type(ms) ~= 'table' then return nil end

    local parts = {}

    if ms.all_stats ~= nil then
        table.insert(parts, 'all_stats:' .. tostring(ms.all_stats))
    end

    if type(ms.basic) == 'table' then
        local basic_parts = {}
        for stat, value in pairs(ms.basic) do
            table.insert(basic_parts, stat .. '=' .. tostring(value))
        end
        table.sort(basic_parts)
        if #basic_parts > 0 then
            table.insert(parts, 'basic:' .. table.concat(basic_parts, ','))
        end
    end

    local weapon_count = 0
    if type(ms.weapon) == 'table' then
        for _, _ in pairs(ms.weapon) do
            weapon_count = weapon_count + 1
        end
    end
    if weapon_count > 0 then
        table.insert(parts, 'weapon:' .. tostring(weapon_count))
    end

    local dmg_entries = 0
    if type(ms.weapon_damage) == 'table' then
        for _, dmg_tbl in pairs(ms.weapon_damage) do
            if type(dmg_tbl) == 'table' then
                for _, _ in pairs(dmg_tbl) do
                    dmg_entries = dmg_entries + 1
                end
            end
        end
    end
    if dmg_entries > 0 then
        table.insert(parts, 'weapon_damage:' .. tostring(dmg_entries))
    end

    if #parts == 0 then return nil end
    return table.concat(parts, ' | ')
end

local function apply_buffered_modded_stats(name, unit)
    if not unit then return end
    if not unit.customparams then return end

    local ms = unit.customparams.modded_stats
    if type(ms) ~= 'table' then return end

    -- Preserve rarity/title before we serialize `modded_stats` into a compact string.
    -- `customParams` are safest as primitives; keeping rarity separate also avoids
    -- losing it during serialization.
    if ms.rarity ~= nil then
        unit.customparams.modded_rarity = tostring(ms.rarity)
    end
    if ms.prefix ~= nil then
        unit.customparams.modded_prefix = tostring(ms.prefix)
    end
    if ms.description ~= nil then
        unit.customparams.modded_description = tostring(ms.description)
    end

    -- Expand tier shorthand (if present) before applying any direct overrides.
    if ms.all_stats ~= nil then
        local factors = parse_all_stats_factors(ms.all_stats)
        for _, f in ipairs(factors) do
            scale_all_stats(name, unit, f)
        end
    end

    if type(ms.basic) == 'table' then
        for stat, value in pairs(ms.basic) do
            unit[stat] = value
        end
    end

    if type(ms.weapon) == 'table' and unit.weapondefs then
        for weapon_name, weapon_stats in pairs(ms.weapon) do
            local wd = unit.weapondefs[weapon_name]
            if wd and type(weapon_stats) == 'table' then
                for stat, value in pairs(weapon_stats) do
                    wd[stat] = value
                end
            end
        end
    end

    if type(ms.weapon_damage) == 'table' and unit.weapondefs then
        for weapon_name, dmg_tbl in pairs(ms.weapon_damage) do
            local wd = unit.weapondefs[weapon_name]
            if wd and wd.damage and type(dmg_tbl) == 'table' then
                for dt, value in pairs(dmg_tbl) do
                    wd.damage[dt] = value
                end
            end
        end
    end

    -- Replace the internal table with a compact string summary so it survives as a safe customParam
    -- and cannot be re-applied by accident.
    unit.customparams.modded_stats = serialize_modded_stats(ms)
end

local function load_en_unit_i18n()
    local file = VFS and VFS.LoadFile and VFS.LoadFile('language/en/units.json')
    if not file or file == "" then
        return {}, {}
    end
    local decoder = (Json and Json.decode) or nil
    if not decoder then
        return {}, {}
    end
    local ok, decoded = pcall(decoder, file)
    if not ok or not decoded or not decoded.units then
        return {}, {}
    end
    local names = (decoded.units and decoded.units.names) or {}
    return names
end

local EN_UNIT_NAMES = load_en_unit_i18n()



local UnitDefs = UnitDefs or {}
for name, ud in pairs(UnitDefs) do
    if not string.find(name, "scavengerboss") then
        ud.customparams = ud.customparams or {}

        if type(ud.customparams.modded_stats) == 'table' then
            apply_buffered_modded_stats(name, ud)
            local proxyName = (ud.customparams and ud.customparams.i18nfromunit) or name
            local baseHumanName = (EN_UNIT_NAMES and EN_UNIT_NAMES[proxyName]) or (EN_UNIT_NAMES and EN_UNIT_NAMES[name]) or proxyName
            local prefix = ud.customparams.modded_prefix
            local rarity = ud.customparams.modded_rarity
            local desc = ud.customparams.modded_description

            local name_parts = {}
            if prefix and prefix ~= '' then table.insert(name_parts, prefix) end
            if rarity and rarity ~= '' then table.insert(name_parts, rarity) end
            local title = table.concat(name_parts, ' ')
            if title ~= '' then
                title = title .. ' '
            end

            ud.customparams['i18n_en_humanname'] = title .. baseHumanName

            -- If this unit has metal-maker style conversion params, append a human-readable summary.
            local eff = ud.customparams and tonumber(ud.customparams.energyconv_efficiency)
            if eff and eff > 0 then
                local energy_per_metal = math.ceil(1 / eff)
                local conv_line = "Converts " .. tostring(energy_per_metal) .. " energy to 1 metal"
                if desc and desc ~= '' then
                    desc = desc .. "\n" .. conv_line
                else
                    desc = conv_line
                end
            end

            if desc and desc ~= '' then
                ud.customparams['i18n_en_tooltip'] = desc
            end
        end
    end
end