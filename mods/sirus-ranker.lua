-- Tiers Mod v0.4 (SSirus)

-- CONFIG VALUES
local TIER_CONFIG = {
    -- NOTE: `effect_str` preserves the exact tooltip formatting (e.g. "1.0" instead of "1").
    { id = 'junk',      fn = 'junk',      weight = 4,  label = 'Junk',      effect = 0.65 },
    { id = 'faulty',    fn = 'faulty',    weight = 7,  label = 'Faulty',    effect = 0.85 },
    { id = 'common',    fn = 'common',    weight = 45, label = 'Common',    effect = 1.00 },
    { id = 'uncommon',  fn = 'uncommon',  weight = 15, label = 'Uncommon',  effect = 1.10 },
    { id = 'rare',      fn = 'rare',      weight = 12, label = 'Rare',      effect = 1.20 },
    { id = 'epic',      fn = 'epic',      weight = 8,  label = 'Epic',      effect = 1.35 },
    { id = 'legendary', fn = 'legendary', weight = 5,  label = 'Legendary', effect = 1.50 },
    { id = 'mythic',    fn = 'mythic',    weight = 3,  label = 'Mythic',    effect = 1.75 },
    { id = 'ancient',   fn = 'ancient',   weight = 1,  label = 'Ancient',   effect = 2.00 },
}

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
        set_modded_stats(name, unit, label, stats, effect)
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

    for _, cfg in ipairs(TIER_CONFIG) do
        local fn = modifier_fns[cfg.fn]
        table.insert(tier_weights, { fn, cfg.weight })
        mapping[fn] = cfg.label or cfg.id or cfg.fn
        mapping_effect[fn] = cfg.effect
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

local function assign_modifiers()
    local extra_mutation_chance = 0.1
    local UnitDefs = UnitDefs or {}
    for name, ud in pairs(UnitDefs) do
        if not string.find(name, "scavengerboss") then
            local modifiers = {}
            repeat
                table.insert(modifiers, get_random_modifier(tier_weights))
            until math.random() > extra_mutation_chance
                if mod then
                    mod(ud)
                end
        end
    end


    for name, ud in pairs(UnitDefs) do
        if factions[string.sub(name, 1, 3)] then
            local modifiers = {}
            repeat
                table.insert(modifiers, get_random_modifier(tier_weights))
            until math.random() > extra_mutation_chance
            local s = '('
            local mods = {}
            for _, mod in ipairs(modifiers) do
                mod(name, ud)
                table.insert(mods, mod)
            end
            local mod_labels = {}
            for _, mod in ipairs(mods) do
                table.insert(mod_labels, mapping[mod])
            end
        end
    end
end
assign_modifiers()