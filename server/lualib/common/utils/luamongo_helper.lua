--[[
ModuleName :
Path : lualib/common/utils/luamongo_helper.lua
Author : jinlei
CreateTime : 2020-07-05 13:52:07
Description :
--]]

local luamongo_helper = {}

local key_chain_list = {

}

local collectionname2keymap = false
local function init_collectionname2keymap()
	collectionname2keymap = {}
	for _, key_chain in ipairs(key_chain_list) do
		local keylist = string.split(key_chain, ".")
		local size = #keylist
		local keymap = collectionname2keymap
		for idx, key in ipairs(keylist) do
			local subkeymap = keymap[key]
			if not subkeymap then
				if idx < size then
					subkeymap = {}
				else
					subkeymap = 1
				end
				keymap[key] = subkeymap
			end
		end
	end
end
init_collectionname2keymap()

local function convert_key(tbl, keymap, convfunc)
	convfunc = convfunc or tonumber

	for key, subkeymap in pairs(keymap) do
		local convkeys = {}
		if key == "*" then
			convkeys = table.keys(tbl)
		elseif tbl[key] then
			table.insert(convkeys, key)
		end

		for _, convkey in ipairs(convkeys) do
			local subtbl = tbl[convkey]
			if subkeymap == 1 then
				for k, v in pairs(subtbl) do
					subtbl[k] = nil
					subtbl[convfunc(k)] = v
				end
			else
				convert_key(subtbl, subkeymap, convfunc)
			end
		end
	end
end

function luamongo_helper.mongo2lua(name, tbl)
	local keymap = collectionname2keymap[name]
	if not keymap then
		return tbl
	end
	return convert_key(tbl, keymap, tonumber)
end

return luamongo_helper
