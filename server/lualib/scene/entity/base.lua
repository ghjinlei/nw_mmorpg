--[[
ModuleName :
Path : lualib/scene/entity/base.lua
Author : louiejin
CreateTime : 2020-08-09 07:02:20
Description :
--]]
Entity = Object:inherit()

function Entity:on_init()

end

function Entity:on_release()
end

function Entity:after_enter_scene()
end

function Entity:update()
end

function Entity:collision_test(point_entity, scale)
	scale = scale or 1
	local volume = self:get_info("collision_volume")
	local pos = self:get_position()

	local point_volume = point_entity:get_info("collision_volume")
	local point_pos = point_entity:get_position()

	local distance_sqr = MATH.distance_pow(pos, point_pos)
	local min_distance = scale *(volume.radius + point_volume.radius)
	local min_distance_sqr = min_distance * min_distance
	if distance_sqr > min_distance_sqr then
		return false
	end

	local diff_y = pos[2] - point_pos[2]
	if diff_y > 0 and diff_y > point_volume.height then
		return false
	elseif -diff_y > volume.height then
		return false
	end

	return true
end

