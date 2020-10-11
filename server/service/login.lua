--[[
ModuleName :
Path : service/login.lua
Author : jinlei
CreateTime : 2020-09-30 20:08:29
Description :
--]]

local skynet = require "skynet"
local socket = require "skynet.socket"

local sessionid = 1
local slavelist = {}
local nslave

local CMD = {}

function CMD.open(conf)
	for i = 1, conf.slave_count do
		local s = skynet.newservice("loginslave")
		skynet.call(s, "lua", "init", skynet.self(), i, conf)
		table.insert(slavelist, s)
	end
	nslave = #slavelist

	local host = conf.host or "0.0.0.0"
	local port = tonumber(conf.port)
	local sock = socket.listen(host, port)

	local balance = 1
	socket.start(sock, function(fd, addr)
		print("connect socket:", fd, addr)
		local s = slavelist[balance]
		balance = balance % nslave + 1
		skynet.call (s, "lua", "auth", fd, addr)
	end)
end

function CMD.save_session(openid, secret, challenge, token)
	local sessionid_ = sessionid
	sessionid = sessionid + 1

	local s = slavelist[sessionid % nslave + 1]
	skynet.call(s, "lua", "save_session", sessionid_, openid, secret, challenge, token)
	return sessionid_
end

function CMD.verify(sessionid, htoken)
	local s = slavelist[sessionid % nslave + 1]
	return skynet.call(s, "lua", "verify", sessionid, htoken)
end

skynet.start(function()
	skynet.dispatch("lua", function(_, _, command, ...)
		local f = assert(CMD[command])
		skynet.retpack(f(...))
	end)
end)

