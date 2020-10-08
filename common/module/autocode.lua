--[[
ModuleName : AUTOCODE
Path : common/module/autocode.lua
Author : jinlei
CreateTime : 2020-04-20 17:35:52
Description :
--]]
local EVENT_AUTOCODE_UPDATED = "EVENT_AUTOCODE_UPDATED"

local function load_autocode(relapath)
	local func, err = g_loadfile(relapath, nil)
	assert(func, err)

	local autocode = {}
	setmetatable(autocode, {__index = _G})
	setfenv(func, new)()

	return autocode
end

-- 配置表，不需要热更新，直接载入替换即可
function init_autocode(relapath, observer, on_loaded)
	local autocode = load_autocode(relapath)
	if observer then
		EVENT.add_listener(observer, nil, EVENT_AUTOCODE_UPDATED, relapath, function(event)
			local autocode = event:get_data()
			on_loaded(autocode)
		end)
	end
	on_loaded(autocode)
end

-- 更新autocode只需要发热更新消息,由相应模块重新载入autocode
function update_autocode(relapath)
	local autocode = load_autocode(relapath)
	EVENT.dispatch(nil, EVENT_AUTOCODE_UPDATED, relapath, autocode)
end

function get_content(autocode, sheetname, key2conv)
	local content = autocode.get_content(sheetname)
	if not key2conv then
		return content
	end

	local new_content = {}
	for id, info in pairs(content) do
		local new_info = {}
		for k, conv in pairs(key2conv) do
			if type(conv) == "function" then
				new_info[k] = conv(info)
			else
				new_info[k] = info
			end
		end
		new_content[id] = new_info
	end

	return new_content
end
