-- Sol Invictus weapon injector
--
-- This repo's mods run in BAR's Lua environment where `UnitDefs` already exists.
-- The Sol Invictus unit is `legeheatraymech` (Legion T3). Its main beam weapon is
-- `weapondefs.heatray1` (mounted twice in its `weapons` list).
--
-- Configure TARGET_UNIT to inject that weapon into any other unit.

-- === CONFIG ===
local SOURCE_UNIT = "legeheatraymech"
local SOURCE_WEAPON = "heatray1" -- Sol Invictus heat ray weaponDef key

-- Set this to the unitdef name you want to receive the weapon, e.g. "armcom", "corak", etc.
local TARGET_UNIT = "" -- <-- fill me in

-- Optional: customize the injected weaponDef key on the target to avoid name collisions.
local TARGET_WEAPON_KEY = "solinvictus_heatray1"

-- Optional: how many mounts to add (Sol Invictus mounts heatray1 twice).
local TARGET_MOUNT_COUNT = 1

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

local function find_key_case_insensitive(tbl, wanted_key)
	if type(tbl) ~= "table" or type(wanted_key) ~= "string" then return nil end
	if tbl[wanted_key] ~= nil then return wanted_key end

	local wanted_l = lower(wanted_key)
	for k, _ in pairs(tbl) do
		if lower(k) == wanted_l then
			return k
		end
	end
	return nil
end

local function find_mount_for_weapon(unit, weapon_key)
	-- Try to find a `unit.weapons[]` entry that references this weaponDef.
	if type(unit) ~= "table" or type(unit.weapons) ~= "table" then return nil end
	local want_l = lower(weapon_key)

	for _, w in pairs(unit.weapons) do
		if type(w) == "table" then
			local def = w.def
			if type(def) == "string" and lower(def) == want_l then
				return w
			end
		end
	end

	-- Some content uses uppercase for `def` even when weapondefs key is lowercase.
	-- If we didn't find an exact match, fall back to case-insensitive compare.
	for _, w in pairs(unit.weapons) do
		if type(w) == "table" then
			local def = w.def
			if type(def) == "string" and lower(def) == want_l then
				return w
			end
		end
	end

	return nil
end

-- === main ===
local UnitDefs = UnitDefs or {}

if TARGET_UNIT == nil or TARGET_UNIT == "" then
	-- Nothing to do until configured.
	return
end

local src = UnitDefs[SOURCE_UNIT]
local dst = UnitDefs[TARGET_UNIT]
if type(src) ~= "table" or type(dst) ~= "table" then
	return
end

if type(src.weapondefs) ~= "table" then
	return
end

dst.weapondefs = dst.weapondefs or {}
dst.weapons = dst.weapons or {}

local src_weapon_key = find_key_case_insensitive(src.weapondefs, SOURCE_WEAPON)
if not src_weapon_key then
	return
end

-- Avoid collisions if the target already has this key.
local injected_key = TARGET_WEAPON_KEY
if type(injected_key) ~= "string" or injected_key == "" then
	injected_key = "solinvictus_" .. SOURCE_WEAPON
end
if dst.weapondefs[injected_key] ~= nil then
	-- Find a free suffix.
	local i = 2
	while dst.weapondefs[injected_key .. "_" .. tostring(i)] ~= nil do
		i = i + 1
	end
	injected_key = injected_key .. "_" .. tostring(i)
end

-- Copy weaponDef table.
dst.weapondefs[injected_key] = deepcopy(src.weapondefs[src_weapon_key])

-- Copy a matching mount entry (weapons[]), if one exists.
local mount = find_mount_for_weapon(src, src_weapon_key)
local mount_template
if mount then
	mount_template = deepcopy(mount)
	mount_template.def = injected_key
else
	-- Fallback: minimal mount entry (works, but will lack per-mount categories/flags).
	mount_template = { def = injected_key }
end

local count = tonumber(TARGET_MOUNT_COUNT) or 1
if count < 1 then count = 1 end

for _ = 1, count do
	table.insert(dst.weapons, deepcopy(mount_template))
end


