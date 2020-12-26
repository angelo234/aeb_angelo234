-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

--JS uses this value when resetting app but not level
aeb_angelo234_func_params = {}

local M = {}

local function clear_array()
	for x in pairs (aeb_angelo234_func_params) do
		aeb_angelo234_func_params[x] = nil
	end
end

function aeb_angelo234_castRayDebug()
	local json_origin = jsonDecode(aeb_angelo234_func_params[0])
	local json_dest = jsonDecode(aeb_angelo234_func_params[1])
	
	local origin = vec3(json_origin.x, json_origin.y, json_origin.z)
	local dest = vec3(json_dest.x, json_dest.y, json_dest.z)
 
	local hit = castRayDebug(
	origin,
	dest,
	aeb_angelo234_func_params[2],
	aeb_angelo234_func_params[3]
	)
	
	if hit == nil then
		return "no_hit"
	end	
	
	clear_array()
	
	local info = {hit.norm, hit.dist, hit.pt}
	
	local json_hit = jsonEncode(info)

	return json_hit
end

return M