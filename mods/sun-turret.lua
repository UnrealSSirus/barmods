-- Sun Turrets (SSirus)
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

local function addBuildOption(unitDef, option)
	if type(unitDef) ~= "table" or type(unitDef.buildoptions) ~= "table" then return end
	for _, existing in ipairs(unitDef.buildoptions) do
		if existing == option then
			return
		end
	end
	table.insert(unitDef.buildoptions, option)
end

-- === weapon defs you can reuse ===
local SUN_HEATRAY_WEAPONDEF_T1 = {
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
	reloadtime = 0.033,
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
	},
}

local SUN_HEATRAY_WEAPONDEF_T15 = {
	areaofeffect = 90,
	avoidfeature = false,
	beamtime = 0.033,
	beamttl = 0.033,
	camerashake = 0.1,
	corethickness = 0.3,
	craterareaofeffect = 72,
	craterboost = 0,
	cratermult = 0,
	edgeeffectiveness = 0.15,
	energypershot = 8,
	explosiongenerator = "custom:heatray-large",
	firestarter = 90,
	firetolerance = 750,
	largebeamlaser = true,
	impulsefactor = 0,
	intensity = 5,
	laserflaresize = 6.5,
	name = "Experimental Thermal Ordnance Generators",
	noselfdamage = true,
	predictboost = 0,
	range = 600,
	reloadtime = 0.033,
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
		commanders = 11,
		default = 15,
		vtol = 11,
	},
	customparams = {
		exclude_preaim = true,
	},
}

local SUN_HEATRAY_WEAPONDEF_T3 = {
	areaofeffect = 90,
	avoidfeature = false,
	beamtime = 0.033,
	beamttl = 0.033,
	camerashake = 0.1,
	corethickness = 0.5,
	craterareaofeffect = 72,
	craterboost = 0,
	cratermult = 0,
	edgeeffectiveness = 0.3,
	energypershot = 20,
	explosiongenerator = "custom:heatray-large",
	firestarter = 90,
	firetolerance = 750,
	largebeamlaser = true,
	impulsefactor = 0,
	intensity = 5,
	laserflaresize = 6.5,
	name = "Experimental Thermal Ordnance Generators",
	noselfdamage = true,
	predictboost = 0,
	range = 1500,
	reloadtime = 0.01,
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
		commanders = 55,
		default = 77,
		vtol = 44,
	},
	customparams = {
		exclude_preaim = true,
	},
}


-- === turret configs ===
local TURRETS = {
	{
		-- UnitDef name (must be unique)
		unitName = "armldragonturret",

		-- Display strings
		humanName = "Light Dragon Turret",
		tooltip = "Light laser turret with a solar beam",

		-- Clone base
		baseUnit = "armllt",

		-- Weapon install
		weaponKey = "sun_heatray1", -- keep unique to avoid collisions with other mods
		weaponDef = SUN_HEATRAY_WEAPONDEF_T1,
		mountCount = 3,
	},
    {
		-- UnitDef name (must be unique)
		unitName = "armldragonturret2",

		-- Display strings
		humanName = "Heavy Dragon Turret",
		tooltip = "Heavy solar turret",

		-- Clone base
		baseUnit = "armllt",

		-- Weapon install
		weaponKey = "sun_heatray1", -- keep unique to avoid collisions with other mods
		weaponDef = SUN_HEATRAY_WEAPONDEF_T15,
		mountCount = 1,
	},
    {
		-- UnitDef name (must be unique)
		unitName = "armascturret",

		-- Display strings
		humanName = "Ascendant Beam Turret",
		tooltip = "Ascendant beam turret",

		-- Clone base
		baseUnit = "armllt",

		-- Weapon install
		weaponKey = "sun_heatray1", -- keep unique to avoid collisions with other mods
		weaponDef = SUN_HEATRAY_WEAPONDEF_T3,
		mountCount = 1,
	},
}

-- === main ===
local UnitDefs = UnitDefs or {}

local function ensure_custom_turret(cfg)
	if type(cfg) ~= "table" then return nil end
	local unitName = cfg.unitName
	local baseUnit = cfg.baseUnit
	if type(unitName) ~= "string" or unitName == "" then return nil end
	if type(baseUnit) ~= "string" or baseUnit == "" then return nil end

	local base = UnitDefs[baseUnit]
	if type(base) ~= "table" then
		return nil
	end

	-- Create the new turret as a clone of `baseUnit`.
	if UnitDefs[unitName] == nil then
		UnitDefs[unitName] = deepcopy(base)
	end

	local u = UnitDefs[unitName]
	if type(u) ~= "table" then return nil end

	-- Display name/tooltip (safe via customparams i18n)
	u.name = cfg.humanName or u.name
	u.description = cfg.tooltip or u.description
	u.customparams = u.customparams or {}
	if type(cfg.humanName) == "string" and cfg.humanName ~= "" then
		u.customparams.i18n_en_humanname = cfg.humanName
	end
	if type(cfg.tooltip) == "string" and cfg.tooltip ~= "" then
		u.customparams.i18n_en_tooltip = cfg.tooltip
	end

	-- Install weaponDef and mounts
	local weaponKey = cfg.weaponKey
	local weaponDef = cfg.weaponDef
	if type(weaponKey) ~= "string" or weaponKey == "" then return nil end
	if type(weaponDef) ~= "table" then return nil end

	u.weapondefs = u.weapondefs or {}
	u.weapondefs[weaponKey] = deepcopy(weaponDef)

	-- Keep base mount flags/categories (if any) but swap the weapon key.
	local mount_template = {}
	if type(base.weapons) == "table" and type(base.weapons[1]) == "table" then
		mount_template = deepcopy(base.weapons[1])
	end
	mount_template.def = weaponKey

	local mountCount = tonumber(cfg.mountCount) or 1
	if mountCount < 1 then mountCount = 1 end
	u.weapons = {}
	for _ = 1, mountCount do
		table.insert(u.weapons, deepcopy(mount_template))
	end

	return u
end

-- Build all custom turrets
local builtTurretNames = {}
for _, cfg in ipairs(TURRETS) do
	local u = ensure_custom_turret(cfg)
	if u then
		table.insert(builtTurretNames, cfg.unitName)
	end
end

-- Add all new turrets to Arm commanders build list (armcom + evocom levels)
for unitName, ud in pairs(UnitDefs) do
	if type(ud) == "table" and type(ud.buildoptions) == "table" then
		local cp = ud.customparams
		if type(cp) == "table" and cp.iscommander == true and lower(unitName):sub(1, 3) == "arm" then
			for _, newName in ipairs(builtTurretNames) do
				addBuildOption(ud, newName)
			end
		end
	end
end

