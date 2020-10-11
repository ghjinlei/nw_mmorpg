--[[
ModuleName :
Path : service/main.lua
Author : jinlei
CreateTime : 2020-09-30 19:41:06
Description :
--]]
local skynet = require "skynet"
require "skynet.manager"--------- import skynet.register
local config_system = require "config_system"
local config_server = config_system.server
local config_login = config_system.login
local config_game = config_system.game

local debug_console = false
local protoloader = false
local login = false
local game = false

local function main()
	debug_console = skynet.uniqueservice("debug_console", config_server.debug_console_port)
	protoloader = skynet.uniqueservice("protoloader")

	login = skynet.newservice("login")
	skynet.call(login, "lua", "open", config_login)
end

skynet.start(function()
	xpcall(main, function(err)
		print(err.."\n "..debug.traceback())
		os.exit()
	end)
end)

