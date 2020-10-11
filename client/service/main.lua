--[[
ModuleName :
Path : service/main.lua
Author : jinlei
CreateTime : 2020-10-04 17:44:21
Description :
--]]
local skynet = require "skynet"
local socket = require "skynet.socket"
dofile("lualib/common/base/preload.lua")

local robotmap = {}
local function add_robot(robotid1, robotid2)
	robotid2 = robotid2 or robotid1
	for robotid = robotid1, robotid2 do
		local openid = "robot_" .. tostring(robotid)
		local robot_addr = skynet.newservice("robot", openid)
		local robot = {openid = openid, addr = robot_addr}
		robotmap[robotid] = robot
	end
end

local select_robotlist = {}
local function select_robot(robotid1, robotid2)
	select_robotlist = {}
	robotid1 = robotid1 < 1 and 1 or robotid1
	robotid2 = robotid2 or robotid1
	for robotid = robotid1, robotid2 do
		local robot = robotmap[robotid]
		if robot then
			table.insert(select_robotlist, robot)
		end
	end
end

local CMD = {}
function CMD.add(args, cmdline)
	local robotid1 = tonumber(args[1])
	local robotid2 = tonumber(args[2])
	add_robot(robotid1, robotid2)
end

function CMD.sel(args, cmdline)
	local robotid1 = tonumber(args[1])
	local robotid2 = tonumber(args[2])
	select_robot(robotid1, robotid2)
end

function CMD.login(args, cmdline)
	for _, robot in ipairs(select_robotlist) do
		skynet.send(robot.addr, "lua", "login")
	end
end

function CMD.logout(args, cmdline)
	for _, robot in ipairs(select_robotlist) do
		skynet.send(robot.addr, "lua", "logout")
	end
end

function CMD.info(args, cmdline)

end

function CMD.help()
	skynet.error([[
usage(avaliable commands):
        add        :eg      add 10           : add a robot id = 10
                    eg      add 10 100       : add robots id from 10 to 100
        sel        :eg      sel 10           : select a robot id = 10
                    eg      sel 10 100       : select robot id in range [1, 100]"
        login      :eg      login            : login all select robots
	enter      :eg      enter            : enter game
        info       :eg      info             : info
        logout     :eg      logout           : logout all select robots
]])
end

function main_loop()
	local stdin = socket.stdin()
	--socket.lock(stdin)
	while true do
		local cmdline = socket.readline(stdin, "\n")
		local args = string.split(cmdline, " ")
		cmd = table.remove(args, 1)
		local func = CMD[cmd]
		if func then
			func(args, cmdline)
		end
	end
	--socket.unlock(stdin)
end

skynet.start(function()
	skynet.error("init service start :main ......")
	skynet.uniqueservice("protoloader")

	skynet.fork(main_loop)
	skynet.error("init service finish :main")
end)


