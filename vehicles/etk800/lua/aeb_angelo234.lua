-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local last_system_active = false
local system_active = false
local brake_applications = 0

local function perform_raycast(origin, dest)
	obj:queueGameEngineLua("aeb_angelo234_func_params[0] = '" .. jsonEncode(origin) .. "'")
	obj:queueGameEngineLua("aeb_angelo234_func_params[1] = '" .. jsonEncode(dest) .. "'")
	obj:queueGameEngineLua("aeb_angelo234_func_params[2] = true")
	obj:queueGameEngineLua("aeb_angelo234_func_params[3] = true")
	
	obj:queueGameEngineLua('be:getPlayerVehicle(0):queueLuaCommand("raycastdata = (\'"..aeb_angelo234_castRayDebug().."\')")')
	
	if raycastdata == nil or raycastdata == "no_hit" then
		return nil
	end
	
	--Parameters: hit.norm, hit.dist, hit.pt
	local json_hit = jsonDecode(raycastdata)
	
	return json_hit
end

local function updateGFX(dt)
	if system_active and brake_applications < 2 then
		brake_applications = brake_applications + 1
		--return
	end

	local speed = vec3(obj:getVelocity()):length()
	
	--Check if in reverse and if true, disable system
	local in_reverse = electrics.values.reverse

	if in_reverse == 1 then
		if system_active then
			input.event("brake", 0, -1)
			system_active = false
		end
			
		return
	end

	if system_active then	
		--Once stopped, if system was activated before, disable it and release brakes
		if speed < 0.1 then
			input.event("brake", 0, -1)
			system_active = false
			return
			
		--Keep brakes applied if system was activated before to stop car
		elseif speed < 3 then
			input.event("brake", 1, -1)
			
			return	
		end
	end
	
	local max_d = 500
	local h1 = 0.5
	local h2 = 0.4

	--Set origin of raycast offset from center of vehicle
	local offset_pos1 = vec3(0,0,0)
	local offset_pos2 = vec3(0,0,0)
	
	local offset_rot1 = vec3(0,0,0.03)
	local offset_rot2 = vec3(0,0,0.015)
	
	local dir1 = vec3(obj:getDirectionVector()):__add(offset_rot1):normalized()
	local dir2 = vec3(obj:getDirectionVector()):__add(offset_rot2):normalized()
	
	offset_pos1:set(
	offset_pos1.x * dir1.x,
	offset_pos1.y * dir1.y,
	offset_pos1.z * dir1.z
	)
	
	offset_pos2:set(
	offset_pos2.x * dir2.x,
	offset_pos2.y * dir2.y,
	offset_pos2.z * dir2.z
	)

	local origin1 = vec3(obj:getPosition()):__add(offset_pos1)
	local origin2 = vec3(obj:getPosition()):__add(offset_pos2)

	local dest1 = dir1:__mul(500):__add(origin1)
	local dest2 = dir2:__mul(500):__add(origin2)

	--x = ?
	--y = ?
	--z = pitch
	
	--Cast ray from front of vehicle x distance away
	--local d1 = obj:castRayStatic(pos:__add(offset_pos1):toFloat3(), dir:__add(offset_rot1):normalized():toFloat3(), max_d)	
	--local d2 = obj:castRayStatic(pos:__add(offset_pos2):toFloat3(), dir:__add(offset_rot2):normalized():toFloat3(), max_d)

	--1st Raycast

	local json_hit1 = perform_raycast(origin1, dest1)
	
	if json_hit1 == nil then
		return
	end
	
	local distance1 = json_hit1[2]
	
	distance1 = distance1 - 2.5
	
	local norm1 = json_hit1[1]
	
	local norm1_x = math.abs(norm1.x)
	local norm1_y = math.abs(norm1.y)
	
	if norm1_x < 0.5 and norm1_y < 0.5 then
		return
	end
	
	--print("distance 1: " ..distance1)
	--dump(json_hit1[1])


	--2nd Raycast

	local json_hit2 = perform_raycast(origin2, dest2)
	
	if json_hit2 == nil then
		return
	end
	
	local distance2 = json_hit2[2]
	
	distance2 = distance2 - 2.5

	local norm2 = json_hit2[1]
	
	local norm2_x = math.abs(norm2.x)
	local norm2_y = math.abs(norm2.y)
	
	if norm2_x < 0.5 and norm2_y < 0.5 then
		return
	end
	
	local distance_min = math.min(distance1, distance2)

	--print(distance_min)

	--local margin_of_error_time = 0.5

	--Partial Braking
	local acc1 = 0.4 * 9.81
	local time1 = speed / (2 * acc1)
	
	--Full Braking
	local acc2 = 1 * 9.81
	local time2 = speed / (2 * acc2)

	--Time to collision
	local ttc = distance_min / speed
	
	print("TTC: " .. tonumber(string.format("%.2f", ttc)) .. ", TTC for braking: " .. tonumber(string.format("%.2f", time2)))

	--Maximum Braking
	if ttc <= time2 then
		--print("filter: " .. input.state.brake.filter)
	
		system_active = true
		input.event("brake", 1, -1)

		brake_applications = 1
		
		print("AUTOMATIC EMERGENCY BRAKING ACTIVATED!")
			
	--Moderate Braking
	--elseif ttc <= t1 then
	--	system_active = true
	--	input.event("brake", 0.4, FILTER_DIRECT)
	--Deactivate system
	else
		system_active = false
	
		if last_system_active ~= system_active then
			input.event("brake", 0, -1)
		end
	end
	
	last_system_active = system_active
end
 
M.updateGFX = updateGFX 
 
return M