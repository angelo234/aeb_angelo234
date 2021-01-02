-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local json_hit_arr = {}

local M = {}

function aeb_angelo234_castRay(json_param)
	local params = jsonDecode(json_param)

	local json_origin = params[1]
	local json_dest = params[2]
	
	local origin = vec3(json_origin.x, json_origin.y, json_origin.z)
	local dest = vec3(json_dest.x, json_dest.y, json_dest.z)
	
	local hit = nil
	
	--Debug Mode?
	if params[6] then
		hit = castRayDebug(origin, dest, params[3], params[4])	
	else
		hit = castRay(origin, dest, params[3], params[4])
	end

	if hit == nil then
		json_hit_arr[params[5]] = {}
	
		return "'" .. jsonEncode(json_hit_arr) .. "'"
	
	else
		local info = {hit.norm, hit.dist, hit.pt, params[5]}

		json_hit_arr[params[5]] = info
		
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
	
	local objects = map.objects
	
	local this_veh_pos = objects[this_veh_id].pos
	
	local min_distance = 9999
	
	for veh_id, value in pairs(objects) do
		if veh_id ~= this_veh_id then
			local bb = be:getObjectByID(veh_id):getSpawnWorldOOBB()
			
			local other_veh_pos = vec3(bb:getCenter())
			local x = bb:getHalfExtents().x * vec3(bb:getAxis(0))
			local y = bb:getHalfExtents().y * vec3(bb:getAxis(1))
			local z = bb:getHalfExtents().z * vec3(bb:getAxis(2))
			
			local distance = intersectsRay_OBB(raycast_origin, raycast_dir, other_veh_pos, x, y, z) 
			--local distance = (this_veh_pos - other_veh_pos):length()
			if distance < 0 then
				distance = 9999
			end
			
			min_distance = math.min(distance, min_distance)
		end
	end
	
	return "'" .. jsonEncode({min_distance}) .. "'"
end

return M