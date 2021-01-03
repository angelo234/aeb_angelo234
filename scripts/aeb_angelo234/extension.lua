-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local json_hit_arr = {}
local json_hit_veh_arr = {}

local M = {}

function aeb_angelo234_castRay(json_param)
	local params = jsonDecode(json_param)

	local origin = vec3(params[1].x, params[1].y, params[1].z)
	local dest = vec3(params[2].x, params[2].y, params[2].z)
	local includeTerrain = params[3]
	local renderGeometry = params[4]
	local index = params[5]
	local debug_mode = params[6]
	
	local hit = nil
	
	--Debug Mode?
	if debug_mode then
		hit = castRayDebug(origin, dest, includeTerrain, renderGeometry)	
	else
		hit = castRay(origin, dest, includeTerrain, renderGeometry)
	end

	if hit == nil then
		json_hit_arr[index] = {}
	
		return "'" .. jsonEncode(json_hit_arr) .. "'"
	
	else
		local info = {hit.norm, hit.dist, hit.pt, index}

		json_hit_arr[index] = info
		
		return "'" .. jsonEncode(json_hit_arr) .. "'"
	end	
end

function aeb_angelo234_getDistanceToVehicleInPath(json_param)
	local params = jsonDecode(json_param)
	
	local this_veh_id = params[1]
	local max_raycast_distance = params[2]
	local raycast_origin = vec3(params[3].x, params[3].y, params[3].z)
	local raycast_dest = vec3(params[4].x, params[4].y, params[4].z)
	local raycast_dir = vec3(params[5].x, params[5].y, params[5].z)
	local index = params[6]

	local min_distance = 9999
	local min_veh_id = -1

	--local objects = map.objects
	--local this_veh_pos = objects[this_veh_id].pos
	
	--map.objects for some reason only updates when removing vehicles
	--so this is a workaround to get all vehicle IDs
	
	local veh_names = {}
	
	Lua:findObjectsByClassAsTable("BeamNGVehicle", veh_names)
	
	--[[
	local this_velocity = vec3(be:getObjectByID(this_veh_id).obj:getVelocity())
	local this_bb = be:getObjectByID(this_veh_id):getSpawnWorldOOBB()		
	local this_veh_pos = vec3(this_bb:getCenter())
	local this_x = this_bb:getHalfExtents().x * vec3(this_bb:getAxis(0))
	local this_y = 250 * vec3(this_bb:getAxis(1))
	local this_z = this_bb:getHalfExtents().z * vec3(this_bb:getAxis(2))
	]]--
	
	for _, veh_name in pairs(veh_names) do
		local veh_id = scenetree.findObject(veh_name):getID()
	
		--print(veh_id)
		if veh_id ~= this_veh_id then	
			local bb = be:getObjectByID(veh_id):getSpawnWorldOOBB()
			
			local other_veh_pos = vec3(bb:getCenter())
			local x = bb:getHalfExtents().x * vec3(bb:getAxis(0))
			local y = bb:getHalfExtents().y * vec3(bb:getAxis(1))
			local z = bb:getHalfExtents().z * vec3(bb:getAxis(2))

			--local overlap = overlapsOBB_OBB(this_veh_pos, this_x, this_y, this_z, other_veh_pos, x, y, z)		
			--print(overlap)
			--local distance = 9999

			local distance = intersectsRay_OBB(raycast_origin, raycast_dir, other_veh_pos, x, y, z) 
			
			if distance < 0 then
				distance = 9999			
			end
			
			--print("distance: " .. distance)
			
			min_distance = math.min(distance, min_distance)
			
			if min_distance == distance then
				min_veh_id = veh_id
			end
		end
	end
	
	if json_hit_veh_arr[index] == nil then
		json_hit_veh_arr[index] = {}
	end
	
	if min_veh_id ~= -1 then
		local other_velocity = vec3(be:getObjectByID(min_veh_id).obj:getVelocity())
		json_hit_veh_arr[index][2] = other_velocity
	else
		json_hit_veh_arr[index][2] = vec3(0,0,0)
	end
	
	json_hit_veh_arr[index][1] = min_distance
	
	return "'" .. jsonEncode(json_hit_veh_arr) .. "'"
end

return M