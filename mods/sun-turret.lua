-- Sun Turrets (SSirus)

local affectedUnits = {
    "armllt"
}

-- Give the light laser turret (armllt) the Sol Invictus heat ray (funny).
-- This version is fully local: copy/paste weaponDef here so you can tweak balance easily.
-- Original source for reference: `legeheatraymech` weapondefs.heatray1
local TARGET_WEAPON_KEY = "sun_heatray1" -- keep unique to avoid collisions with other mods

-- === helpers ===
local function lower(s)
	if type(s) ~= "string" then return "" end
	return string.lower(s)
end

local function deepcopy(x, seen)
	if type(x) ~= "table" then return x end
	if seen and seen[x] then return seen[x] end
	seen = seen or {}
	local out = {}
	seen[x] = out
	for k, v in pairs(x) do
		out[deepcopy(k, seen)] = deepcopy(v, seen)
	end
	return out
end

-- t1 version
local SUN_HEATRAY_WEAPONDEF = {
	areaofeffect = 90,
	avoidfeature = false,
	beamtime = 0.033,
	beamttl = 0.033,
	camerashake = 0.1,
	corethickness = 0.1,
	craterareaofeffect = 72,
	craterboost = 0,
	cratermult = 0,
	edgeeffectiveness = 0.15,
	energypershot = 4,
	explosiongenerator = "custom:heatray-large",
	firestarter = 90,
	-- tolerance = 750,
	firetolerance = 750,
	largebeamlaser = true,
	impulsefactor = 0,
	intensity = 5,
	laserflaresize = 6.5,
	name = "Experimental Thermal Ordnance Generators",
	noselfdamage = true,
	predictboost = 0,
	--proximitypriority = -1,
	range = 450,
	reloadtime = 0.033, -- was `.033` in the original; keep explicit for clarity while tweaking
	rgbcolor = "1 0.3 0",
	rgbcolor2 = "1 0.8 0.5",
	soundhitdry = "flamhit1",
	soundhitwet = "sizzle",
	soundstart = "heatray4burn",
	scrollspeed = 5,
	soundstartvolume = 11,
	soundtrigger = 1,
	texture3 = "largebeam",
	thickness = 6.5,
	tilelength = 500,
	turret = true,
	weapontype = "BeamLaser",
	damage = {
		commanders = 3,
		default = 5,
		vtol = 3,
	},
	customparams = {
		exclude_preaim = true,
		--sweepfire=0.4,--multiplier for displayed dps during the 'bonus' sweepfire stage, needed for DPS calcs
	},
}

-- === main ===
local UnitDefs = UnitDefs or {}

for _, targetName in ipairs(affectedUnits) do
	local dst = UnitDefs[targetName]
	if type(dst) == "table" then
		dst.weapondefs = dst.weapondefs or {}
		dst.weapons = dst.weapons or {}

		-- Install weaponDef (deep copy so your edits don't get mutated elsewhere).
		dst.weapondefs[TARGET_WEAPON_KEY] = deepcopy(SUN_HEATRAY_WEAPONDEF)

		-- Replace mount #1 to use the heat ray, keeping armllt's existing mount flags/categories.
		dst.weapons[1] = dst.weapons[1] or {}
		dst.weapons[1].def = TARGET_WEAPON_KEY
		dst.weapons[2] = dst.weapons[2] or {}
		dst.weapons[2].def = TARGET_WEAPON_KEY
		dst.weapons[3] = dst.weapons[3] or {}
		dst.weapons[3].def = TARGET_WEAPON_KEY
	end
end

