-- Prefix Pack v1.1 (SSirus)

-- Tiers only modify health, cost, buildtime, damage, movement speed, reload speed
local PREFIX_CONFIG = {
    -- Default: most units receive no prefix at all.
    { id = 'none',    fn = 'none',    weight = 200,  label = '' },

    { id = 'cloak',    fn = 'cloak',    weight = 10,  label = 'Cloaking' },
    { id = 'stealthy',    fn = 'stealthy',    weight = 1,  label = 'Stealthy' },
    { id = 'undetectable',    fn = 'undetectable',    weight = 1,  label = 'Undetectable' },
    { id = 'spying',    fn = 'spying',    weight = 10,  label = 'Spying' }, -- Increased LOS
    { id = 'detecting',    fn = 'detecting',    weight = 10,  label = 'Detecting' }, -- Gains radar and sonar equal and seismic detection equalto los
    { id = 'amphibious',    fn = 'amphibious',    weight = 10,  label = 'Amphibious' }, -- Increases minWaterDepth and maxWaterDepth
    { id = 'emphmeral',    fn = 'emphmeral',    weight = 0,  label = 'Emphmeral' }, -- Increases cloak radius and cloaking time, doesn't block units
    { id = 'healthy',    fn = 'healthy',    weight = 10,  label = 'Healthy' }, -- Increases health
    { id = 'tanky',    fn = 'tanky',    weight = 10,  label = 'Tanky' }, -- 
    { id = 'speedy',    fn = 'speedy',    weight = 10,  label = 'Speedy' }, -- Increases speedy
    { id = 'regenerative',    fn = 'regenerative',    weight = 10,  label = 'Regenerative' }, -- Increases regenerative
    { id = 'jamming',    fn = 'jamming',    weight = 1,  label = 'Jamming' }, -- Jams radars and sonars
    { id = 'explosive',    fn = 'explosive',    weight = 1,  label = 'Explosive' }, -- Increases explosive damage
    { id = 'resourceful',    fn = 'resourceful',    weight = 5,  label = 'Resourceful' }, -- Increases resource gathering
    { id = 'blind',    fn = 'blind',    weight = 5,  label = 'Blind' }, -- Reduces LOS
}

 -- forgetful, randomly loses build options
 -- replicating, builds a copy of itself

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

-- Overwrite a field instead of appending (useful when a "combined" modifier
-- calls other modifiers for effects, but wants its own single display prefix).
local function set_field(ms, key, value)
    if value == nil or value == '' then return end
    ms[key] = value
end

local function none(unit)
    -- Intentionally does nothing (represents "no prefix assigned").
end

local function cloak(unit)
    unit.cancloak = true
    local energy_cost = unit.energycost or unit.buildcostenergy or 0
    unit.cloakcost = 50 + energy_cost * 0.01
    unit.cloakcostmoving = 200 + energy_cost * 0.01
    unit.mincloakdistance = 80

    -- Metadata for attribute-resolver.lua
    local ms = ensure_modded_stats(unit)
    append_field(ms, 'prefix', 'Cloaking', ' ')
    append_field(ms, 'description', 'Allows the unit to cloak', '\n')
end

local function stealthy(unit)
    unit.stealth = true

    -- Metadata for attribute-resolver.lua
    local ms = ensure_modded_stats(unit)
    append_field(ms, 'prefix', 'Stealthy', ' ')
    append_field(ms, 'description', 'Unit is stealthed', '\n')
end

local function undetectable(unit)
    cloak(unit)
    stealthy(unit)
    local ms = ensure_modded_stats(unit)
    set_field(ms, 'prefix', 'Undetectable')
end

local function jamming(unit)
    unit.radarDistanceJam = unit.sightdistance
    unit.sonarDistanceJam = unit.sonardistance

    -- Metadata for attribute-resolver.lua
    local ms = ensure_modded_stats(unit)
    append_field(ms, 'prefix', 'Jamming', ' ')
    append_field(ms, 'description', 'Unit jams radars and sonars', '\n')
end

local function spying(unit)
    unit.sightdistance = unit.sightdistance * 3
    local ms = ensure_modded_stats(unit)
    append_field(ms, 'prefix', 'Spying', ' ')
    append_field(ms, 'description', 'Unit gains 3x LOS', '\n')
end

local function detecting(unit)
    unit.radarDistance = unit.sightdistance
    unit.sightemitheight = 66
    unit.sonarDistance = unit.sightdistance
    unit.seismicdistance = unit.sightdistance
    unit.seismicsignature = 0
    local ms = ensure_modded_stats(unit)
    append_field(ms, 'prefix', 'Detecting', ' ')
    append_field(ms, 'description', 'Unit gains radar, sonar and seismic detection equal to LOS', '\n')
end

local function explosive(unit)
    unit.explodeas = 'crawl_blastsml'
    unit.selfdestructas = "crawl_blast"
    unit.selfdestructcountdown = 1
    local ms = ensure_modded_stats(unit)
    append_field(ms, 'prefix', 'Explosive', ' ')
    append_field(ms, 'description', 'Unit is much more volatile', '\n')
end

local function healthy(unit)
    unit.idleautoheal = 5
    unit.health = unit.health + 200 + unit.health * 0.12
    local ms = ensure_modded_stats(unit)
    append_field(ms, 'prefix', 'Healthy', ' ')
    append_field(ms, 'description', 'Unit gains 200hp + 12% max hp and heals when idle', '\n')
end

local function tanky(unit)
    unit.health = unit.health + 600 + unit.health * 0.12
    if unit.speed then
        unit.speed = unit.speed * 0.66
    end
    local ms = ensure_modded_stats(unit)
    append_field(ms, 'prefix', 'Tanky', ' ')
    append_field(ms, 'description', 'Unit gains 600hp + 50% max hp, speed is reduced by 33%', '\n')
end

local function regenerative(unit)
    unit.autoheal = 50
    local ms = ensure_modded_stats(unit)
    append_field(ms, 'prefix', 'Regenerative', ' ')
    append_field(ms, 'description', 'Unit heals 50hp per second', '\n')
end

local function resourceful(unit)
    local metal_cost = unit.metalcost or unit.buildcostmetal or 0
    local energy_cost = unit.energycost or unit.buildcostenergy or 0
    unit.metalmake = math.min(5, metal_cost * 0.01)
    unit.energymake = math.min(100, energy_cost * 0.01)
    local ms = ensure_modded_stats(unit)
    append_field(ms, 'prefix', 'Resourceful', ' ')
    append_field(ms, 'description', 'Generates 1% of its cost per second', '\n')
end

local function blind(unit)
    unit.sightdistance = unit.sightdistance * 0.2
    local ms = ensure_modded_stats(unit)
    append_field(ms, 'prefix', 'Blind', ' ')
    append_field(ms, 'description', 'Unit has reduced LOS', '\n')
end

local function amphibious(unit)
    unit.maxwaterdepth = 255
    local ms = ensure_modded_stats(unit)
    append_field(ms, 'prefix', 'Amphibious', ' ')
    append_field(ms, 'description', 'Unit can move on land and water (probably)', '\n')
end

local function speedy(unit)
    if not unit.speed then
        return
    end
    unit.speed = unit.speed * 2
    local ms = ensure_modded_stats(unit)
    append_field(ms, 'prefix', 'Speedy', ' ')
    append_field(ms, 'description', 'Unit is much faster', '\n')
end



-- Weighted random selection (similar to sirus-ranker.lua)
local prefix_weights
do
    local modifier_fns = {
        none = none,
        cloak = cloak,
        stealthy = stealthy,
        invisible = invisible,
        jamming = jamming,
        undetectable = undetectable,
        spying = spying,
        detecting = detecting,
        explosive = explosive,
        -- healthy = healthy,
        -- tanky = tanky,
        -- regenerative = regenerative,
        -- resourceful = resourceful,
        -- blind = blind,
        -- amphibious = amphibious,
        -- speedy = speedy,
        -- Note: other PREFIX_CONFIG entries are currently stubs (no function defined yet).
        -- They will be ignored until you implement them and add them here.
    }

    prefix_weights = {}
    for _, cfg in ipairs(PREFIX_CONFIG) do
        local fn = modifier_fns[cfg.fn]
        if fn and type(cfg.weight) == 'number' and cfg.weight > 0 then
            table.insert(prefix_weights, { fn, cfg.weight })
        end
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

local function assign_prefixes()
    local UnitDefs = UnitDefs or {}
    for name, ud in pairs(UnitDefs) do
        if not string.find(name, "scavengerboss") then
            local mod = get_random_modifier(prefix_weights)
            if mod then
                mod(ud)
            end
        end
    end
end

assign_prefixes()