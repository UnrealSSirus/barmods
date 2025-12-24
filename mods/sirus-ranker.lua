-- Tiers Mod v0.9 (SSirus)

-- CONFIG VALUES
local TIER_CONFIG = {
    { id = 'junk',      fn = 'junk',      weight = 4,  label = 'Junk',      effect = 0.65, power = -5 },
    { id = 'faulty',    fn = 'faulty',    weight = 7,  label = 'Faulty',    effect = 0.85, power = -3  },
    { id = 'common',    fn = 'common',    weight = 45, label = 'Common',    effect = 1.00, power = 0  },
    { id = 'uncommon',  fn = 'uncommon',  weight = 15, label = 'Uncommon',  effect = 1.10, power = 1  },
    { id = 'rare',      fn = 'rare',      weight = 12, label = 'Rare',      effect = 1.20, power = 2  },
    { id = 'epic',      fn = 'epic',      weight = 8,  label = 'Epic',      effect = 1.35, power = 3  },
    { id = 'legendary', fn = 'legendary', weight = 5,  label = 'Legendary', effect = 1.50, power = 4  },
    { id = 'mythic',    fn = 'mythic',    weight = 3,  label = 'Mythic',    effect = 1.75, power = 7  },
    { id = 'ancient',   fn = 'ancient',   weight = 1,  label = 'Ancient',   effect = 2.00, power = 15  },
}

-- Power balancing across factions
local FACTION_BUDGETS = {
    arm = 278,
    cor = 286,
    leg = 260,
}

-- Internal lookup tables (kept local to avoid leaking globals across other Lua files).
local tier_weights
local mapping
local mapping_effect
local mapping_power
local tier_index_to_fn
local tier_index_to_power



local function ensure_modded_stats(unit)
    unit.customparams = unit.customparams or {}
    local ms = unit.customparams.modded_stats
    if type(ms) ~= 'table' then
        ms = {}
        unit.customparams.modded_stats = ms
    end
    return ms
end

local function append_field(ms, key, value, sep)
    if value == nil or value == '' then return end
    sep = sep or ' '
    local cur = ms[key]
    if cur == nil or cur == '' then
        ms[key] = value
    else
        ms[key] = cur .. sep .. value
    end
end

local function set_field(ms, key, value)
    if value == nil or value == '' then return end
    ms[key] = value
end

-- Data-driven tier modifier (configured in TIER_CONFIG above).
local function make_tier_modifier(cfg)
    local label = cfg.label or cfg.id or cfg.fn or 'Unknown'
    local effect = cfg.effect
    local effect_str = tostring(effect)
    return function(name, unit)
        local ms = ensure_modded_stats(unit)
        append_field(ms, 'rarity', label, ' ')
        append_field(ms, 'all_stats', effect_str, ' ')
    end
end

-- Now that the modifier functions exist, resolve config -> function references.
do
    local modifier_fns = {}
    for _, cfg in ipairs(TIER_CONFIG) do
        modifier_fns[cfg.fn or cfg.id] = make_tier_modifier(cfg)
    end
    -- NOTE: `corrupted` can still be added separately if you define it and add it to TIER_CONFIG.

    tier_weights = {}
    mapping = {}
    mapping_effect = {}
    mapping_power = {}
    tier_index_to_fn = {}
    tier_index_to_power = {}

    for i, cfg in ipairs(TIER_CONFIG) do
        local fn = modifier_fns[cfg.fn]
        table.insert(tier_weights, { fn, cfg.weight })
        mapping[fn] = cfg.label or cfg.id or cfg.fn
        mapping_effect[fn] = cfg.effect
        mapping_power[fn] = cfg.power or 0
        tier_index_to_fn[i] = fn
        tier_index_to_power[i] = cfg.power or 0
    end
end

local function get_random_modifier(prob_table)
    local total = 0
    for _, t in ipairs(prob_table) do
        total = total + t[2]
    end
    if total <= 0 then return nil end

    local x = math.random(1, total)
    local running = 0
    for _, t in ipairs(prob_table) do
        running = running + t[2]
        if x <= running then
            return t[1]
        end
    end
end

local function get_faction_from_name(name)
    if type(name) ~= 'string' then return nil end
    local pref = string.lower(string.sub(name, 1, 3))
    if FACTION_BUDGETS[pref] then
        return pref
    end
    return nil
end

local function shuffle_in_place(arr)
    -- Fisher-Yates shuffle.
    for i = #arr, 2, -1 do
        local j = math.random(i)
        arr[i], arr[j] = arr[j], arr[i]
    end
    return arr
end

local function get_random_tier_index()
    -- Same distribution as `get_random_modifier(tier_weights)`, but returns the tier index for downgrade logic.
    local total = 0
    for _, cfg in ipairs(TIER_CONFIG) do
        total = total + (cfg.weight or 0)
    end
    if total <= 0 then return nil end

    local x = math.random(1, total)
    local running = 0
    for i, cfg in ipairs(TIER_CONFIG) do
        running = running + (cfg.weight or 0)
        if x <= running then
            return i
        end
    end
end

local function assign_modifiers()
    local extra_mutation_chance = 0.1
    local defs = UnitDefs or {}

    -- Power budgets are enforced per-faction; unit processing order is shuffled to avoid deterministic bias.
    local power_used = { arm = 0, cor = 0, leg = 0 }

    -- Gather eligible units into a list so we can shuffle iteration order.
    local units = {}
    for key, ud in pairs(defs) do
        local name = (type(key) == 'string' and key) or (type(ud) == 'table' and ud.name) or nil
        if name and not string.find(name, "scavengerboss") then
            table.insert(units, { name = name, unit = ud })
        end
    end
    shuffle_in_place(units)

    -- Decide and apply rarities/modifiers in the shuffled order, downgrading if a faction would exceed budget.
    for _, entry in ipairs(units) do
        local name = entry.name
        local ud = entry.unit
        local faction = get_faction_from_name(name)

        -- Always at least 1 rarity; each additional rarity is a 10% roll and can repeat.
        local did_any = false
        local function apply_one()
            local tier_idx = get_random_tier_index()
            if not tier_idx then return false end

            if faction then
                local budget = FACTION_BUDGETS[faction]
                local used = power_used[faction] or 0
                -- Downgrade until it fits the remaining budget (or we hit the lowest tier).
                while tier_idx > 1 and (used + (tier_index_to_power[tier_idx] or 0) > budget) do
                    tier_idx = tier_idx - 1
                end
                local final_power = tier_index_to_power[tier_idx] or 0
                power_used[faction] = used + final_power
            end

            local mod = tier_index_to_fn[tier_idx]
            if mod then
                mod(name, ud)
                did_any = true
            end
            return true
        end

        if apply_one() then
            while math.random() < extra_mutation_chance do
                if not apply_one() then break end
            end
        end

        -- Optional: stamp per-unit total power (debug/inspection). Safe no-op if `customparams` absent.
        if did_any and faction then
            ud.customparams = ud.customparams or {}
            ud.customparams.modded_faction = faction
        end
    end

    -- Optional debug summary (visible in infolog when running Spring). Won't error if Spring isn't available.
    if Spring and Spring.Echo then
        Spring.Echo("[sirus-ranker] faction power used: arm=" .. tostring(power_used.arm) .. "/" .. tostring(FACTION_BUDGETS.arm)
            .. " cor=" .. tostring(power_used.cor) .. "/" .. tostring(FACTION_BUDGETS.cor)
            .. " leg=" .. tostring(power_used.leg) .. "/" .. tostring(FACTION_BUDGETS.leg))
    end
end
assign_modifiers()