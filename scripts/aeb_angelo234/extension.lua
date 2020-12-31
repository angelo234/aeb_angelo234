-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local aeb_angelo234_json_hit_arr = {}

local M = {}

function aeb_angelo234_castRayDebug(json_param)
	local params = jsonDecode(json_param)

	local json_origin = params[1]
	local json_dest = params[2]
	
	local origin = vec3(json_origin.x, json_origin.y, json_origin.z)
	local dest = vec3(json_dest.x, json_dest.y, json_dest.z)
 
	local hit = castRayDebug(
	origin,
	dest,
	params[3],
	params[4]
	)
	
	if hit == nil then
		aeb_angelo234_json_hit_arr[params[5]] = {}
	
		return "'" .. jsonEncode(aeb_angelo234_json_hit_arr) .. "'"
	
	else
		local info = {hit.norm, hit.dist, hit.pt, params[5]}

		aeb_angelo234_json_hit_arr[params[5]] = info
		
		return "'" .. jsonEncode(aeb_angelo234_json_hit_arr) .. "'"
	end	
end


return M