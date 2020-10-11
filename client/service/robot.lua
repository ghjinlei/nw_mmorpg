--[[
ModuleName :
Path : service/robot.lua
Author : jinlei
CreateTime : 2020-10-04 18:10:55
Description :
--]]
local skynet = require "skynet"
local sproto_helper = require "common.utils.sproto_helper"
local config_login = require "config_system".login
dofile("lualib/common/base/preload.lua")

NETWORK   = import("lualib/robot/network.lua")
AUTH      = import("lualib/robot/auth.lua")

local openid = ...

local TICK_INTERVAL = 100 -- 100毫秒tick一次
local function tick()
	NETWORK.tick()
	skynet.timeout(TICK_INTERVAL / 10, tick)
end

local CMD = {}
function CMD.login()
	AUTH.login(config_login.host, config_login.port)
end

function CMD.logout()
	AUTH.logout()
end

function CMD.enter_game(idx, race, sex)
	AUTH.enter_game(idx, race, sex)
end

skynet.start(function()
	sproto_helper.load(1)

	skynet.dispatch("lua", function(_, _, command, ...)
		local f = assert(CMD[command])
		skynet.retpack(f(...))
	end)

	AUTH.set_openid(openid)
	AUTH.set_openkey("openkey")
	skynet.timeout(1, tick)
end)
--]]

