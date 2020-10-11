--[[
ModuleName :
Path : lualib/common/module/serv_timer.lua
Author : jinlei
CreateTime : 2019-06-21 15:21:44
Description :
--]]
local skynet = require "skynet"

__timermap = {}
setmetatable(__timermap, {__mode = "v"})

__timerid = 0
local function gen_timerid()
	__timerid = __timerid + 1
	return __timerid
end

local function new_timer(start, interval, count, func)
	local timer = {
		start = math.ceil(start * 100),
		interval = math.ceil(interval * 100),
		count = count,
		func = func,
	}
	if timer.start < 1 then
		timer.start = 1
	end
	if timer.interval < 1 then
		timer.interval = 1
	end
end

function add_timer(start, interval, count, func)
	if count == 0 then
		return
	end

	local timerid = gen_timerid()
	local timer = new_timer(start, interval, count, func)
	__timermap[timerid] = timer

	local function trigger_func()
		local func = timer.func
		if not func then
			return
		end

		func()

		local count = timer.count
		if count > 0 then
			count = count - 1
			timer.count = count
		end

		if count == 0 then
			return
		end

		skynet.timeout(timer.interval, trigger_func)
	end

	skynet.timeout(timer.start, trigger_func)
end

function remove_timer(timerid)
	local timer = __timermap[timerid]
	if not timer then
		return
	end
	__timermap[timerid] = nil
	timer.func = nil
end

