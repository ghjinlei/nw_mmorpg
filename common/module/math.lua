--[[
ModuleName :
Path : common/module/math.lua
Author : jinlei
CreateTime : 2020-04-21 15:10:44
Description :
--]]

function gen_rotation_from_xyz(x, y, z, default_rotation)
	if x == 0 and y == 0 and z == 0 then
		return default_rotation
	end

	if z == 0 then
		return x > 0 and 90 or 270
	end

	local tan = x / z
	local radians = math.atan(tan)
	local angle = 180 * radians / math.pi
	if z < 0 then
		angle = angle + 180
	end
	if angle < 0 then
		angle = angle + 360
	end
	return angle
end

function gen_rotation_from_point(begin_point, end_point, default_rotation)
	local x = end_point[1] - begin_point[1]
	local y = end_point[2] - begin_point[2]
	local z = end_point[3] - begin_point[3]
	return gen_rotation_from_xyz(x, y, z, default_rotation)
end

function gen_rotation_from_vector(vector, default_rotation)
	return gen_rotation_from_point(vector[1], vector[2], vector[3], default_rotation)
end
