-- Self-Balanced Randomizer
function get_rnd_number(from_val, to_val, split_chance)
	from_val = from_val or 0.5
	to_val = to_val or 2.0
	split_chance = split_chance or 0.5

	local num
	if math.random() < split_chance then
		local range_min = math.min(from_val, 1)
		local range_max = math.max(from_val, 1)
		local current_range_size = range_max - range_min
		num = math.random() * current_range_size + range_min
	else
		local range_min = math.min(1, to_val)
		local range_max = math.max(1, to_val)
		local current_range_size = range_max - range_min
		num = math.random() * current_range_size + range_min
	end
	return num
end

for name, ud in pairs(UnitDefs) do
if not string.find(name, "scavengerboss") then
	local log_power = 0

	local o_metal = ud.metalcost or ud.buildcostmetal or 404
	local o_energy = ud.energycost or ud.buildcostenergy or 404
	local o_buildtime = ud.buildtime or 404

	-- The terminal of base weights for self-balance
	-- Range weight end result decreases based on spread and velocity, and is up to x3 higher for units that approach 0 movespeed.
	local BASE_HEALTH = 0.55
	local BASE_SPEED = 0.65
	local BASE_ACC = 0.09
	local BASE_DEC = 0.06
	local BASE_TURNRATE = 0.12
	local BASE_SIGHT = 0.15
	local BASE_DAMAGE = 0.60
	local BASE_RELOAD = -0.50
	local BASE_RANGE = 0.45
	local BASE_AOE = 0.05
	local BASE_SPRAYANGLE = -0.25
	local BASE_VELOCITY = 0.18
	local BASE_BURST = 0.59

	-- HEALTH
	local health_val = ud.health or ud.maxdamage
	if health_val then
		local mult = get_rnd_number(0.6, 4, 0.6)
		local new_health = math.ceil(health_val * mult)
		ud.health = new_health
		ud.maxdamage = new_health
		log_power = log_power + BASE_HEALTH * math.log(mult)
	end

	-- SPEED
	if ud.speed then
		local mult = get_rnd_number(0.5, 3, 0.6)
		ud.speed = ud.speed * mult
		log_power = log_power + BASE_SPEED * math.log(mult)
	end

	-- ACCELERATION
	if ud.maxacc then
		local mult = get_rnd_number(0.4, 3, 0.45)
		ud.maxacc = ud.maxacc * mult
		log_power = log_power + BASE_ACC * math.log(mult)
	end

	-- DECELERATION
	if ud.maxdec then
		local mult = get_rnd_number(0.4, 3, 0.45)
		ud.maxdec = ud.maxdec * mult
		log_power = log_power + BASE_DEC * math.log(mult)
	end

	-- TURNRATE
	if ud.turnrate then
		local mult = get_rnd_number(0.4, 3, 0.45)
		ud.turnrate = ud.turnrate * mult
		log_power = log_power + BASE_TURNRATE * math.log(mult)
	end

	-- SIGHT
	if ud.sightdistance then
		local mult = get_rnd_number(0.3, 1.5, 0.6)
		ud.sightdistance = ud.sightdistance * mult
		log_power = log_power + BASE_SIGHT * math.log(mult)
	end

	-- WEIGHTLESS UNIT STATS
	ud.verticalspeed = ud.verticalspeed and ud.verticalspeed * get_rnd_number(0.4, 3, 0.6)
	ud.idleautoheal = ud.idleautoheal and ud.idleautoheal * get_rnd_number(0.6, 10, 0.8)
	ud.idletime = ud.idletime and ud.idletime * get_rnd_number(0.6, 1.9, 0.45)

	-- WEAPONS (counts up non-bogus weapons to proportionally reduce the weight of each)
	if ud.weapondefs then
		local weapon_count = 0
		local not_bogus = {}

		for w_name, w_def in pairs(ud.weapondefs) do
			local is_bogus = false
			if w_def.customparams and w_def.customparams.bogus and w_def.customparams.bogus == 1 then
				if w_def.damage then
					local default_dmg = w_def.damage.default or 0
					local vtol_dmg = w_def.damage.vtol or 0
					if default_dmg == 0 and vtol_dmg == 0 then
						is_bogus = true
					end
				else
					is_bogus = true
				end
			end

			if not is_bogus then
				weapon_count = weapon_count + 1
				not_bogus[w_name] = w_def
			end
		end

		local w_weight = 1 / math.sqrt(weapon_count)
		local fixmednum1

		for w_name, w_def in pairs(not_bogus) do
			local is_napalm = (w_def.soundhitdry == "flamhit1")

			local o_vel = w_def.weaponvelocity or 1000
			local o_spray = w_def.sprayangle or 0
			local o_flight = w_def.flighttime
			local o_gravity = w_def.mygravity or 0.11
			local o_burst = w_def.burst or 0
			local o_burstrate = w_def.burstrate or 0

			-- DAMAGE
			if w_def.damage and not is_napalm then
				if w_def.damage.default then
					local dmg_mult = get_rnd_number(0.4, 2.2, 0.45)
					w_def.damage.default = w_def.damage.default * dmg_mult
					log_power = log_power + (BASE_DAMAGE * w_weight) * math.log(dmg_mult)
					
					if w_def.thickness then w_def.thickness = w_def.thickness * dmg_mult end
					if w_def.laserflaresize then w_def.laserflaresize = w_def.laserflaresize * dmg_mult end
				end

				if w_def.damage.vtol then
					local vtol_mult = get_rnd_number(0.4, 2.2, 0.45)
					w_def.damage.vtol = w_def.damage.vtol * vtol_mult
					log_power = log_power + (BASE_DAMAGE * 0.2 * w_weight) * math.log(vtol_mult)
				end
			end

			-- RELOAD
			if w_def.reloadtime then
				local reload_mult = get_rnd_number(0.3, 1.9, 0.45)
				w_def.reloadtime = w_def.reloadtime * reload_mult
				log_power = log_power + (BASE_RELOAD * w_weight) * math.log(reload_mult)
			end

			-- BURST
			if w_def.burst then
				local burst_mult = get_rnd_number(0.6, 1.67, 0.6)
				local new_burst = w_def.burst * burst_mult
				w_def.burst = math.floor(new_burst + 0.5)
				local orig_projectiles = o_burst + 1
				local new_projectiles = w_def.burst + 1
				local proj_mult = new_projectiles / orig_projectiles
				log_power = log_power + (BASE_BURST * w_weight) * math.log(proj_mult)
			end

			-- RANGE 
			local range_mult = 1.0
			if w_def.range then

				local slowness = 1.0
				if ud.speed then
					local speed = ud.speed
					slowness = 1.0 + 2.0 * (0.25)^(speed / 100.0)
					if slowness < 1.0 then slowness = 1.0 end
				else
					slowness = 3.0
				end

				range_mult = get_rnd_number(0.4, 2.5, 0.45)
				w_def.range = w_def.range * range_mult

				local range_weight = BASE_RANGE * w_weight * slowness

				if w_def.weapontype == "BeamLaser" then
					range_weight = range_weight * 1.3
				elseif w_def.weapontype == "LightningCannon" then
					range_weight = range_weight * 1.6
				end

				local new_vel = w_def.weaponvelocity or o_vel
				if w_def.tracking == false and new_vel < 1000 then
					range_weight = range_weight * (new_vel / 1000)
				end

				if w_def.tracking == false and w_def.sprayangle then
					local new_spray = w_def.sprayangle or o_spray
					if new_spray > 0 then
						range_weight = range_weight - (new_spray / 10000)
						if range_weight < 0 then range_weight = 0 end
					end
				end

				log_power = log_power + range_weight * math.log(range_mult)

				if w_def.flighttime then
					w_def.flighttime = w_def.flighttime * range_mult
				end

				if w_def.mygravity ~= nil or w_def.weaponvelocity then
					w_def.mygravity = (w_def.mygravity or 0.11) / range_mult
				end
			end

			-- WEAPON VELOCITY 
			if w_def.weaponvelocity then
				local vel_mult = get_rnd_number(0.4, 2.2, 0.45)
				w_def.weaponvelocity = w_def.weaponvelocity * vel_mult
				log_power = log_power + (BASE_VELOCITY * w_weight) * math.log(vel_mult)

				if w_def.mygravity ~= nil then
					w_def.mygravity = w_def.mygravity * (vel_mult * vel_mult)
				end

				if w_def.flighttime and o_flight then
					w_def.flighttime = w_def.flighttime / vel_mult
				end
			end

			-- AREA OF EFFECT
			if w_def.areaofeffect and not is_napalm and not w_def.noexplode then
				local aoe_mult = get_rnd_number(0.4, 3.3, 0.6)
				local new_aoe = w_def.areaofeffect * aoe_mult
				w_def.areaofeffect = new_aoe

				local aoe_scale = new_aoe / 100
				local aoe_weight = BASE_AOE * (aoe_scale^1.5) * w_weight
				log_power = log_power + aoe_weight * math.log(aoe_mult)
			end

			-- SPRAYANGLE
			if w_def.sprayangle then
				local spray_mult = get_rnd_number(0.5, 3, 0.6)
				local new_spray = w_def.sprayangle * spray_mult
				w_def.sprayangle = new_spray

				local spray_weight = BASE_SPRAYANGLE * w_weight
				if new_spray > 0 then
					spray_weight = spray_weight / math.pow(new_spray, 1/3)
				end

				log_power = log_power + spray_weight * math.log(spray_mult)
			end

			-- WEIGHTLESS WEAPON STATS
			w_def.weapontimer = w_def.weapontimer and w_def.weapontimer * get_rnd_number(0.6, 1.67, 0.6)
			w_def.beamtime = w_def.beamtime and w_def.beamtime * get_rnd_number(0.6, 1.67, 0.6)
			w_def.edgeeffectiveness = w_def.edgeeffectiveness and w_def.edgeeffectiveness * get_rnd_number(0.6, 1.67, 0.6)
			w_def.burstrate = w_def.burstrate and w_def.burstrate * get_rnd_number(0.6, 1.67, 0.6)
			w_def.impulsefactor = w_def.impulsefactor and w_def.impulsefactor * get_rnd_number(0.6, 1.67, 0.6)
			if w_def.startvelocity then
				local startvel_mult = get_rnd_number(0.4, 2.5, 0.6)
				w_def.startvelocity = w_def.startvelocity * startvel_mult
				if w_def.flighttime and startvel_mult < 1 then
					w_def.flighttime = w_def.flighttime / startvel_mult
				end
			end
			if w_def.weaponacceleration then
				local accel_mult = get_rnd_number(0.4, 2.5, 0.6)
				w_def.weaponacceleration = w_def.weaponacceleration * accel_mult
				if w_def.flighttime and accel_mult < 1 then
					w_def.flighttime = w_def.flighttime / accel_mult
				end
			end			

			-- Miscellaneous limits
			if w_def.edgeeffectiveness and w_def.edgeeffectiveness > 0.9 then
				w_def.edgeeffectiveness = 0.9
			end

			if w_def.ownerExpAccWeight then
				w_def.ownerExpAccWeight = math.min(w_def.ownerExpAccWeight, 1.5)
			end

			if w_def.customparams and w_def.customparams.overrange_distance then
				w_def.customparams.overrange_distance = 72000
			end

			-- OPman's limits 
			if w_name == "legicbm" or w_name == "nuclear_missile" or w_name == "crblmssl" or 
			   w_name == "sdmssl" or w_name == "fmd_rocket" or w_name == "amd_rocket" then
				if w_def.range and w_def.range > 72000 then
					w_def.range = 72000
				end
			end

			if w_name == "legmed_missile" then
				fixmednum1 = w_def.range
			end

			if w_name == "laser" and fixmednum1 then
				w_def.range = fixmednum1
			end
		end
	end

	-- COSTS (50% base for pace)
	local cost_mult = math.exp(log_power)
	cost_mult = math.max(0.1, math.min(10.0, cost_mult)) * 0.5

	local mcost = math.ceil(o_metal * cost_mult)
	local ecost = math.ceil(o_energy * cost_mult)
	local bpcost = math.ceil(o_buildtime * cost_mult)

	-- normalize big eco by cost, else too much simcity efficiency 
	if (ud.speed == nil or ud.speed < 1) then
		-- Handle energy producers
		if ud.energymake then
			if ud.energymake > 0 and ud.energymake <= 500 then
				mcost = math.ceil(mcost + ud.energymake * 0.5)
			elseif ud.energymake > 500 then
				mcost = math.ceil(mcost + (ud.energymake - 400))
			end
		end
		if ud.tidalgenerator and ud.tidalgenerator > 0 then
			mcost = math.ceil(mcost + 10)
		end
		if ud.windgenerator and ud.windgenerator > 0 then
			mcost = math.ceil(mcost + ud.windgenerator * 0.4)
		end

		local cp = ud.customparams
		if cp and cp.energyconv_capacity and cp.energyconv_efficiency then
			mcost = math.ceil(mcost + (cp.energyconv_efficiency - 0.014) * cp.energyconv_capacity * 200)
		end

		if ud.builder == true then
			mcost = math.ceil(mcost * 1.5)
			ecost = math.ceil(ecost * 1.5)
			bpcost = math.ceil(bpcost * 1.5)
		end
	end

	ud.metalcost = mcost
	ud.energycost = ecost
	ud.buildtime = bpcost
end
end


-- bugfixed Burst/Reload overlap (20% allowance for chance of constant machineguns) 
for name, ud in pairs(UnitDefs) do
	if ud.weapondefs then
		for w_name, w_def in pairs(ud.weapondefs) do
			if w_def.burst and w_def.reloadtime and w_def.burstrate and w_def.burstrate > 0 then
				local reload = w_def.reloadtime
				local bpcost = w_def.burstrate * w_def.burst

				if reload <= bpcost * 0.8 then
					local cycles = math.floor(bpcost / reload) + 1
					local proj = w_def.projectiles or 1
					local newproj = proj * cycles
					w_def.projectiles = newproj
					w_def.reloadtime = reload * (newproj / proj)
				end
			end
		end
	end
end

-- normalize coms with big and smol D-guns 
for name, ud in pairs(UnitDefs) do
	if ud.weapondefs then
		for w_name, w_def in pairs(ud.weapondefs) do
			if w_name == "disintegrator" then
				local d = w_def.range
				
				if d and ud.speed then
					if d < 250 then
						ud.speed = ud.speed + (250 - d) * 0.1
					elseif d > 250 then
						local smult = 1.0 - (d - 250) * 0.001
						if smult < 0.5 then smult = 0.5 end
						ud.speed = ud.speed * smult
					end
				end
				break
			end
		end
	end
end