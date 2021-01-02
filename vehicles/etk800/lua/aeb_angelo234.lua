-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local max_raycast_distance = 250

local last_system_active = false
local system_active = false
local brake_applications = 0

local function performGERaycast(origin, dest, index)
	local param_arr = {origin, dest, false, true, index, true}
	
	obj:queueGameEngineLua("be:getPlayerVehicle(0):queueLuaCommand('raycastdata = ' .. aeb_angelo234_castRay('" ..jsonEncode(param_arr) .. "'))")

	local data = jsonDecode(raycastdata)
	
	if data == nil then
		return nil
	end
	
	if data[index] == nil or data[index] == "no_hit" then
		return nil
	end
	
	--Parameters: hit.norm, hit.dist, hit.pt
	local hit = data[index]
	
	if table.getn(hit) == 0 then
		return nil
	end
	
	return hit
end

local function processGERaycastGetDistance(origin, dest, index)
	local hit = performGERaycast(origin, dest, index)
	
	if hit == nil then
		return {9999, false}
	end

	local norm = hit[1]
	
	local norm_x = math.abs(norm.x)
	local norm_y = math.abs(norm.y)
	
	local distance = hit[2]
	
	if norm_x < 0.5 and norm_y < 0.5 then
		return {distance, false}
	end
	
	distance = distance - 2.5

	return {distance, true}
end

local function processGERaycastVehiclesGetDistance(origin, dest, dir, index)
	local this_veh_id = obj:getID()	
	
	local param_arr = {this_veh_id, max_raycast_distance, origin, dest, dir, index}
	
	obj:queueGameEngineLua("be:getPlayerVehicle(0):queueLuaCommand('vehicleraycastdata = ' .. aeb_angelo234_getDistanceToVehicleInPath('" ..jsonEncode(param_arr) .. "'))")

	local data = jsonDecode(vehicleraycastdata)
	
	if data == nil then
		return 9999
	end
	
	if data[index] == nil then
		return 9999
	end
	
	local distance = data[index]
	
	distance = distance - 2.5

	return distance
end

local function getMinimumDistanceFromRaycast()
	local distance_min = 9999 
	local h1 = 0.5
	local h2 = 0.4

	--5 degrees
	local vfov = 0.0872665
	local iterations = 5
	local rad_per_iter = vfov / iterations
	--2 degrees
	local offset_rads = 0.0349066
	
	for i = 1, iterations do
		local offset_pos = vec3(0,0,1)
		local offset_rot = vec3(0,0,offset_rads - rad_per_iter * i)

		local dir = vec3(obj:getDirectionVector()):__add(offset_rot):normalized()
		
		--offset_pos:set(
		--offset_pos.x * dir.x,
		--offset_pos.y * dir.y,
		--offset_pos.z * dir.z
		--)
		
		local origin = vec3(obj:getPosition()):__add(offset_pos)
		local dest = dir:__mul(max_raycast_distance):__add(origin)	
		
		local distance_ge = processGERaycastGetDistance(origin, dest, i)
		
		--If it didn't hit a wall but maybe ground, then set distance as large value
		if distance_ge[2] == false then	
			distance_ge[1] = 9999
		end

		distance_min = math.min(distance_ge[1], distance_min)
	end

	--[[
	for i = 1, iterations do
		local offset_pos = vec3(0,0,0)
		local offset_rot = vec3(0,0,rad_per_iter * i + -0.0523599)

		local dir = vec3(obj:getDirectionVector()):__add(offset_rot):normalized()
		
		--offset_pos:set(
		--offset_pos.x * dir.x,
		--offset_pos.y * dir.y,
		--offset_pos.z * dir.z
		--)
		
		local origin = vec3(obj:getPosition()):__add(offset_pos)
		local dest = dir:__mul(max_raycast_distance):__add(origin)	
		
		local distance_ge = processGERaycastGetDistance(origin, dest, i)
		
		local distance_ve = obj:castRayStatic(origin:toFloat3(), dir:toFloat3(), max_raycast_distance)
		
		--8888 = hit the ground
		--9999 = didn't hit anything
		
		local margin_error = 1.5
		
		--If GE ray and VE ray are about same distance but GE ray didn't hit wall, then VE ray is irrelevant
		if distance_ge[2] == false then
			--print("GE: " .. distance_ge[1] .. ", VE: " .. distance_ve) 
		
			if distance_ge[1] < distance_ve + margin_error and distance_ge[1] > distance_ve - margin_error then
				--print("irrelevant")
				distance_ve = 8888
			end
			
			distance_ge[1] = 8888
		end
		
		distance_min = math.min(distance_ge[1], distance_min, distance_ve)
	end
	]]--
	
	return distance_min
end

local function getMinimumDistanceFromVehicles()
	local distance_min = 9999 

	--5 degrees
	local vfov = 0.0872665
	local iterations = 5
	local rad_per_iter = vfov / iterations
	--2 degrees
	local offset_rads = 0.0349066
	
	for i = 1, iterations do
		local offset_pos = vec3(0,0,1)
		local offset_rot = vec3(0,0,offset_rads - rad_per_iter * i)

		local dir = vec3(obj:getDirectionVector()):__add(offset_rot):normalized()
		
		--offset_pos:set(
		--offset_pos.x * dir.x,
		--offset_pos.y * dir.y,
		--offset_pos.z * dir.z
		--)
		
		local origin = vec3(obj:getPosition()):__add(offset_pos)
		local dest = dir:__mul(max_raycast_distance):__add(origin)	
		
		local distance = processGERaycastVehiclesGetDistance(origin, dest, dir, i)

		distance_min = math.min(distance, distance_min)
	end

	return distance_min
end

local function calculateTTCAndBrake(distance_min, speed)
	--Partial Braking
	local acc1 = 0.4 * 9.81
	local time1 = speed / (2 * acc1)
	
	--Full Braking
	local acc2 = 1 * 9.81
	local time2 = speed / (2 * acc2)

	--Time to collision
	local ttc = distance_min / speed
	
	--print("TTC: " .. tonumber(string.format("%.2f", ttc)) .. ", TTC for braking: " .. tonumber(string.format("%.2f", time2)))

	--Maximum Braking
	if ttc <= time2 then
		--print("filter: " .. input.state.brake.filter)
	
		system_active = true
		input.event("brake", 1, -1)

		brake_applications = 1
		
		--print("AUTOMATIC EMERGENCY BRAKING ACTIVATED!")
			
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
	
	if speed < 0.5 then
		return
	end
	
	--x = ?
	--y = ?
	--z = pitch

	local distance_min_raycast = getMinimumDistanceFromRaycast()
	local distance_min_vehicle = getMinimumDistanceFromVehicles()
	
	local distance_min = math.min(distance_min_raycast, distance_min_vehicle)
	
	calculateTTCAndBrake(distance_min, speed)
	
	last_system_active = system_active
end
 
M.updateGFX = updateGFX 
 
return M