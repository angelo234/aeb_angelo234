-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local max_raycast_distance = 10
local distance_from_obstacle = 0.5
local distance_from_front_of_car = 2

local iteration_num = 0

local last_system_active = false
local system_active = false

local function performGERaycast(origin, dest, index)
	local param_arr = {origin, dest, false, true, index, true}
	
	obj:queueGameEngineLua("be:getPlayerVehicle(0):queueLuaCommand('raycastdata = ' .. parking_aid_angelo234_castRay('" ..jsonEncode(param_arr) .. "'))")

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
	
	distance = distance - distance_from_obstacle - distance_from_front_of_car

	return {distance, true}
end

local function processGERaycastVehiclesGetDistance(origin, dest, dir, index)
	local this_veh_id = obj:getID()	
	
	local param_arr = {this_veh_id, max_raycast_distance, origin, dest, dir, index}
	
	obj:queueGameEngineLua("be:getPlayerVehicle(0):queueLuaCommand('vehicleraycastdata = ' .. parking_aid_angelo234_getDistanceToVehicleInPath('" ..jsonEncode(param_arr) .. "'))")

	local data = jsonDecode(vehicleraycastdata)
	
	if data == nil then
		return {9999, vec3(0,0,0)}
	end
	
	if data[index] == nil then
		return {9999, vec3(0,0,0)}
	end
	
	local distance = data[index][1]
	local velocity_other_veh = data[index][2]
	
	distance = distance - distance_from_obstacle - distance_from_front_of_car

	return {distance, velocity_other_veh}
end

local function getRaycastData(dt)
	local distance_min = 9999 
	local h1 = 0.5
	local h2 = 0.4

	--5 degrees
	local vfov = 0.0872665
	local iterations = 8
	local rad_per_iter = vfov / iterations
	--2 degrees
	local offset_rads = 0.0349066
	
	for i = 1 + iteration_num, iterations, 4 do
		local offset_rot = vec3(0,0,offset_rads - rad_per_iter * i)
		local dir = vec3(obj:getDirectionVector()):__add(offset_rot):normalized()
	
		--local offset_pos = vec3(0,0,1) + vec3(dir.x * 2, dir.y * 2, 0)
		local offset_pos = vec3(0,0,1)
		--dump(vec3(obj:getVelocity()) * dt)
		
		local pos = vec3(obj:getPosition()) + 2 * vec3(obj:getVelocity()) * dt
		--local pos = vec3(obj:getFrontPosition())
		
		local origin = pos:__add(offset_pos)
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

local function getVehicleRaycastData(dt)
	local distance_min = 9999 

	--5 degrees
	local vfov = 0.0872665
	local iterations = 8
	local rad_per_iter = vfov / iterations
	--2 degrees
	local offset_rads = 0.0349066
	
	local data_arr = {}
	local closest_index = 1
	
	for i = 1 + iteration_num, iterations, 4 do
		local offset_rot = vec3(0,0,offset_rads - rad_per_iter * i)
		local dir = vec3(obj:getDirectionVector()):__add(offset_rot):normalized()
	
		--local offset_pos = vec3(0,0,1) + vec3(dir.x * 2, dir.y * 2, 0)
		local offset_pos = vec3(0,0,1)
		--dump(vec3(obj:getVelocity()) * dt)
		
		local pos = vec3(obj:getPosition()) + 2 * vec3(obj:getVelocity()) * dt
		--local pos = vec3(obj:getFrontPosition())
		
		local origin = pos:__add(offset_pos)
		local dest = dir:__mul(max_raycast_distance):__add(origin)	
		
		local data = processGERaycastVehiclesGetDistance(origin, dest, dir, i)

		data_arr[i] = data

		distance_min = math.min(data[1], distance_min)
		
		if distance_min == data[1] then
			closest_index = i
		end
	end

	return data_arr[closest_index]
end

local function calculateTTCAndBrake(distance_min, veh_speed)	
	--Full Braking
	local acc = 1 * 9.81
	local time_to_brake = veh_speed / (2 * acc)

	--Time to collision
	local ttc = distance_min / veh_speed
	
	--print("distance: " .. tonumber(string.format("%.2f", distance_min)))
	
	--print("TTC: " .. tonumber(string.format("%.2f", ttc)) .. ", TTC for braking: " .. tonumber(string.format("%.2f", time2)))

	--Maximum Braking
	if ttc <= time_to_brake then
		--print("filter: " .. input.state.brake.filter)
	
		system_active = true
		input.event("brake", 1, -1)
		
		--print("AUTOMATIC EMERGENCY BRAKING ACTIVATED!")
	--Deactivate system
	else
		--print("system deactivated")
	
		system_active = false
	
		if last_system_active ~= system_active then
			input.event("brake", 0, -1)
		end
	end
end

local function updateGFX(dt)
	local this_veh_speed = vec3(obj:getVelocity()):length()
	
	--Check if in reverse and if true, disable system
	local in_reverse = electrics.values.reverse

	if in_reverse == 1 then
		obj:queueGameEngineLua("parking_aid_angelo234_reverseCam(" .. dt .. ")")
	
		if system_active then
			input.event("brake", 0, -1)
			system_active = false
		end
			
		return
	end

	if system_active then	
		--Once stopped, if system was activated before, disable it and release brakes
		if this_veh_speed < 0.1 then
			input.event("brake", 0, -1)
			system_active = false
			return
			
		--Keep brakes applied if system was activated before to stop car
		elseif this_veh_speed < 2 then
			input.event("brake", 1, -1)
			
			return	
		end
	end
	
	if this_veh_speed < 1.5 then
		return
	end
	
	--x = ?
	--y = ?
	--z = pitch

	local distance_min_raycast = getRaycastData(dt)
	
	local veh_raycast_data = getVehicleRaycastData(dt)
	local distance_min_vehicle = veh_raycast_data[1]

	local distance_min = math.min(distance_min_raycast, distance_min_vehicle)
	
	--local distance_min = distance_min_raycast
	--local other_veh_velocity = vec3(0,0,0)
	
	calculateTTCAndBrake(distance_min, this_veh_speed)
	
	
	
	
	if iteration_num ~= 3 then
		iteration_num = iteration_num + 1
	else
		iteration_num = 0
	end
	
	last_system_active = system_active
end
 
M.updateGFX = updateGFX 
 
return M