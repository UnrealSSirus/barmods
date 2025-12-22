-- random modifiers (1.1)

local function has_stat(name, unit, stat, t)
    local non_fac_name = string.sub(name, 4)
    local nomex = {mex=1, mext15=1, moho=1, geo=1, ageo=1, uwgeo=1, uwageo=1, }
    if nomex[non_fac_name] and (stat == 'footprintx' or stat == 'footprintz') then
        return false
    end
    if type(t) == 'function' then return true end
    local stat_type = math.abs(t)
    if stat_type == 1 then
        return not not unit[stat]
    elseif stat_type == 2 then
        return not not (unit.weapondefs and unit.weapondefs[stat])
    end
end

local function scale_basic_stat(name, unit, stat, factor)
    if unit[stat] then
        if stat == 'metalcost' and unit.buildcostmetal then
            stat = 'buildcostmetal'
        end
        if stat == 'energycost' and unit.buildcostenergy then
            stat = 'buildcostenergy'
        end
        unit[stat] = math.ceil(unit[stat] * factor)
    end
end

local function scale_weapon_stat(unit, stat, factor)
    if unit.weapondefs then
        for name, wd in pairs(unit.weapondefs) do
            if wd[stat] then
                wd[stat] = wd[stat] * factor
            end
        end
    end
end

local max_stat = 2^32

local function scale_stats(name, unit, stat_set, factor)
    for stat, t in pairs(stat_set) do
        if has_stat(name, unit, stat, t) then
            local stat_type, stat_isnegative, mod
            if type(t) == 'function' then
                stat_type = 3
                mod = t
            else
                stat_type = math.abs(t)
                stat_isnegative = t < 0
                mod = factor
            
                if stat_isnegative then
                    if factor == 0 then
                        mod = max_stat
                    else
                        mod = 1/factor
                    end
                end
            end
            if stat_type == 1 then
                scale_basic_stat(name, unit, stat, mod)
            elseif stat_type == 2 then
                scale_weapon_stat(name, unit, stat, mod)
            elseif stat_type == 3 then
                mod(unit, factor)
            end
        end
    end
end

local function random_choice(tbl)
    local n=0
    for _, _ in pairs(tbl) do
        n = n + 1
    end
    local i = math.random(1, n)
    local choice, value = nil, nil
    for j=1, i do
        choice, value = next(tbl, choice)
    end
    return {[choice]=value}
end

local function random_choices(tbl, n)
    local len = 0
    local list = {}
    local choices = {}
    for k, v in pairs(tbl) do
        table.insert(list, {[k]=v})
        len = len + 1
    end
    for _=1,n do
        local i = math.random(1, len)
        table.insert(choices, table.remove(list, i))
        if #list == 0 then
            break
        end
        len = len - 1
    end
    local ret = {}
    for _, pair in ipairs(choices) do
        local k = next(pair)
        assert(k ~= nil)
        ret[k] = pair[k]
    end
    return ret
end

local stats = {
    -- increase = good (1)
    autoheal=1, idleautoheal=1, builddistance=1, capturespeed=1, energymake=1, energystorage=1, metalmake=1, metalstorage=1, health=1, radardistance=1, sightdistance=1, sonardistance=1, speed=1, turnrate=1, workertime=1, maxwaterdepth=1, maxslope=1, maxacc=1, maxdec=1,
    -- decrease = good (-1)
    buildtime=-1, cloakcost=-1, cloakcostmoving=-1, energycost=-1, metalcost=-1,
    mincloakdistance=-1, footprintx=-1, footprintz=-1,
    -- weaponstats (-2 and 2)
    beamtime=2, range=2, weaponvelocity=2, size=2, edgeeffectiveness=2, impulsefactor=2,
    reloadtime=-2, energypershot=-2, metalpershot=-2, burstrate=-2, weapontimer=-2,

    -- special stats
    weapon_damage=function(ud, factor)
        if ud.weapondefs then
            for w, wd in pairs(ud.weapondefs) do
                wd = wd or {}
                if wd.damage then
                    for dt, dv in pairs(wd.damage) do
                        wd[dt] = dv * factor
                    end
                end
            end
        end
    end,
}

local speed_stats = {
    speed=1, metalmake=1, energymake=1, turnrate=1, maxacc=1, maxdec=1,
    burstrate=-2, reloadtime=-2, weaponvelocity=2
}

--[[
    faulty - -20% stats
    common - default
    uncommon - +10% stats
    rare - +50% stats
    corrupted - random super op stat
    mythic - +100% stats
    speedy - super fast

]]

local function faulty(name, unit)
    -- -20% stats
    scale_stats(name, unit, stats, 0.8)
end

local function common(name, unit)
    -- do nothing
end

local function uncommon(name, unit)
    -- +20% stats
    scale_stats(name, unit, stats, 1.2)
end

local function rare(name, unit)
    -- +50% stats
    scale_stats(name, unit, stats, 1.5)
end

local function corrupted(name, unit)
    -- random op stats
    -- 1 guaranteed stat, each increase is 90%
    -- 
    -- some stats aren't present, so does nothing
    local n = 1
    while math.random() <= 0.9 do
        n = n + 1
    end
    for i=1,n do
        local choice = random_choice(stats)
        scale_stats(name, unit, choice, 10)
    end
end

local function mythic(name, unit)
    -- +100% stats
    scale_stats(name, unit, stats, 2)
end

local function speedy(name, unit)
    -- all speed-like stats + 100%
    scale_stats(name, unit, speed_stats, 2)
end

local function reduce(tbl, func, start)
    for _, x in ipairs(tbl) do
        start = func(start, x)
    end
    return start
end

local function map(tbl, func)
    local new = {}
    for _, x in ipairs(tbl) do
        table.insert(new, func(x))
    end
    return new
end

local function get_random_modifier(prob_table)
    local s = reduce(prob_table, function (a, b) return a + b[2] end, 0)
    local tmp = 0
    local rolling_sum = map(prob_table, function (t)
        tmp = tmp + t[2]
        return tmp
    end)
    local x = math.random(1, s)
    for i, y in ipairs(rolling_sum) do
        if x <= y then
            return prob_table[i][1]
        end
    end
end

local modifier_p_table = {  -- probability weights
    {faulty, 20},
    {common, 100},
    {uncommon, 50},
    {rare, 20},
    {mythic, 10},
    {corrupted, 1},
    {speedy, 9}
}

local mapping = {
    [faulty]='faulty',
    [common]='common',
    [uncommon]='uncommon',
    [rare]='rare',
    [mythic]='mythic',
    [corrupted]='corrupted',
    [speedy]='speedy'
}

local extra_mutation_chance = 0.1

--local UnitDefs = require('unitdefs')

local UnitDefs = UnitDefs or {}
local factions = {arm=1, cor=1, leg=1}

--math.randomseed(os.time())

for name, ud in pairs(UnitDefs) do
    if factions[string.sub(name, 1, 3)] then
        local modifiers = {}
        repeat
            table.insert(modifiers, get_random_modifier(modifier_p_table))
        until math.random() > extra_mutation_chance
        local s = '('
        local mods = {}
        for _, mod in ipairs(modifiers) do
            mod(name, ud)
            table.insert(mods, mapping[mod])
        end
        s = s..table.concat(mods, ' ')..')'
        ud.customparams = ud.customparams or {}
        ud.customparams['i18n_en_tooltip'] = s
    end
end

--local function do_tests()
--    local UnitDefs = require('unitdefs')

--end

--do_tests()