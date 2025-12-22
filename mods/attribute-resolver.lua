-- Attributes Resolver v1.0
local function serialize_modded_stats(ms)
    if type(ms) ~= 'table' then return nil end

    local parts = {}

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
            if desc and desc ~= '' then
                ud.customparams['i18n_en_tooltip'] = desc
            end
        end
    end
end