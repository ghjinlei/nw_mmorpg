--[[
ModuleName :
Path : lualib/scene/buff/base.lua
Author : louiejin
CreateTime : 2020-08-09 11:21:52
Description :
--]]

BuffBase = Object:inherit()

function BuffBase:on_init(OCI)
	self._owner = OCI.owner
end

function BuffBase:get_info(key)
	return get_buff_info(self:get_typeid(), key)
end

function BuffBase:reset()

end

function BuffBase:do_effect(effectname, data)

end

function BuffBase:on_attach()
	local owner = self._owner

	-- 监听事件
	local event_triggers = self:get_info("event_triggers")
	for _, trigger in pairs(event_triggers) do
		self:add_event_listener(self, trigger.type, trigger.key, function(event)
			self:do_effect(trigger.effect, event:get_data())
		end)
	end

	-- 设置定时器
	local timer_triggers = self:get_info("timer_triggers")
	for _, trigger in pairs(timer_triggers) do
		self:add_timer(trigger.delay, trigger.interval, trigger.count, function()
			self:do_effect(trigger.effect)
		end)
	end
end

function BuffBase:on_detach()
	local effect_name = self:get_info("detach_effect")
	self:do_effect(effect_name, effect_data)
end

local autocode_buff = false
local autocode_state = false

function get_buff_info(typeid)
	return autocode_buff[typeid]
end

function get_buff_value(typeid, key)
	return autocode_buff[typeid][key]
end

function get_state_info(attrid)
	return autocode_state[attrid]
end

function get_state_info_map()
	return autocode_state
end

function __init__(module, updated)

end
