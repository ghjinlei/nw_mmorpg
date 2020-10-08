--[[
ModuleName : TIMER
Path : module/timer
Author : louiejin
CreateTime : 2019-08-16 23:39:14
Description :
--]]

local add_timer = IMPL_TIMER.add_timer
local remove_timer = IMPL_TIMER.remove_timer

function table_remove_timer(tbl, timerid)
	remove_timer(timerid)
	if not tbl.__timers then return end
	tbl.__timers[timerid] = nil
end

function table_remove_all_timers(tbl)
	local timerid_map = tbl.__timers
	if not tbl.__timers then return end
	for timerid, _ in pairs(timerid_map) do
		remove_timer(timerid)
	end
	tbl.__timers = nil
end

-- 关联Object
Object.remove_timer = table_remove_timer
Object.remove_all_timers = table_remove_all_timers

local add_timer_func_map = {}
function add_timer_func_map.call_after(delay, callback)
	return add_timer(delay, 0, 1, callback)
end

function add_timer_func_map.call_after_fre(delay, interval, count, callback)
	return add_timer(delay, interval, count, callback)
end

function add_timer_func_map.call_fre(interval, callback)
	return add_timer(interval, interval, - 1, callback)
end

local function time2delay(time)
	return time - TIME.get_time_millis()
end

function add_timer_func_map.call_at(time, callback)
	return add_timer(time2delay(time), 0, 1, callback)
end

function add_timer_func_map.call_at_fre(time, interval, count, callback)
	return add_timer(time2delay(time), interval, count, callback)
end

local function table_add_timerid(tbl, timerid)
	if not tbl.__timers then
		tbl.__timers = {}
	end
	tbl.__timers = {}
	return timerid
end

function __init__(module, updated)
	--[[
		TIMER.table_call_after(tbl, delay, callback)
		TIMER.table_call_after_fre(tbl, delay, interval, count, callback)
		TIMER.table_call_fre(tbl, interval, callback, key)
		TIMER.table_call_at(tbl, time, callback)
		TIMER.table_call_at_fre(tbl, time, interval, count, callback)

		对应的删除函数：
			TIMER.table_remove_timer(tbl, timerKey)
			TIMER.table_remove_all_timers(tbl)
	--]]
	for funcname, func in pairs(add_timer_func_map) do
		module["table_" .. funcname] = function(tbl, ...)
			return table_add_timerid(tbl, func(...))
		end
	end

	--[[
		Object:call_after(delay, callback)
		Object:call_after_fre(delay, interval, count, callback)
		Object:call_fre(interval, callback, key)
		Object:call_at(time, callback)
		Object:call_at_fre(time, interval, count, callback)

		对应的删除函数：
			Object:remove_timer(timerKey)
			Object:table_remove_all_timers()
	--]]
    for funcname, func in pairs(add_timer_func_map) do
        Object[funcname] = function(obj, ...)
            return table_add_timerid(obj, func(...))
        end
    end
end
