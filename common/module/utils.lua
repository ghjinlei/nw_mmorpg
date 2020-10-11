--[[
ModuleName :
Path : common/module/utils.lua
Author : jinlei
CreateTime : 2020-10-10 22:48:57
Description :
--]]
function dump(t, name, depth)
	if not t then
		print(string.format("table: [%s] is nil", name))
		return
	end

	local output = ""
	output = output .. string.format("dumping table: [%s]\n", name or t)
	local function comp_func(a, b)
		local type_a = type(a)
		local type_b = type(b)
		if type_a == type_b then
			return a < b
		else
			return type_a < type_b
		end
	end

	local function do_dump(t, pre, depth)
		for k, v in pairs_orderly(t, comp_func) do
			output = output .. string.format(
				"\t%s[%s](%s) = %s(%s)\n",
				pre,
				tostring(k),
				type(k),
				tostring(v),
				type(v))

			if type(v) == type({}) then
				if depth ~= 0 then
					do_dump(v, pre.."\t", depth-1)
				end
			end
		end
	end
	do_dump(t, "", depth or 4)
	output = output .. string.format("end")

	return output
end

