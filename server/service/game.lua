local skynet = require "skynet"
local logger = require "common.utils.logger"
local sproto_helper = require "sproto_helper"
local config_system = require "config_system"
local config_gate = config_system.gate

local AGENT_MGR = import("lualib/game/agentmgr.lua")

local logind = ...
local gate

local CMD = {}
local SOCKET = {}

function SOCKET.open(fd, addr)
	skynet.error("New client from : " .. addr)
end

function SOCKET.close(fd)
	print("socket close",fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	print("socket error",fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	print("socket warning", fd, size)
end

local function do_auth(fd, msg, sz)
	local type_, name, args, response = sproto_helper:dispatch (msg, sz)
	assert(type_ == "REQUEST")
	assert(name == "login")
	assert(args.sessionid and args.htoken)
	local sessionid = args.sessionid
	local htoken = args.htoken
	local accountid = skynet.call (logind, "lua", "verify", sessionid, htoken)
	return accountid
end

local function do_login(fd, accountid)
	AGENT_MGR.login_account(fd, accountid)
end

function SOCKET.data(fd, msg)
	local ok, accountid = xpcall(do_auth, __G_TRACE_BACK__, fd, msg)
	if ok then
		xpcall(do_login, __G_TRACE_BACK__, fd, accountid)
	else
		skynet.call(gate, "lua", "kick", fd)
	end
end

function CMD.start()
	skynet.call(gate, "lua", "open" , conf)
end

function CMD.close(fd)
	AGENT_MGR.close_agent(fd)
end

skynet.start(function()
	sproto_helper.load(1)

	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

	gate = skynet.newservice("gate")
	AGENT_MGR.gate = gate
end)
