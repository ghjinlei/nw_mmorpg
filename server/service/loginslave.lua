--[[
ModuleName :
Path : service/loginslave.lua
Author : jinlei
CreateTime : 2020-09-30 20:10:15
Description :
--]]

local skynet = require "skynet"
local socket = require "skynet.socket"
local crypt = require "client.crypt"
local logger = require "common.utils.logger"
local sproto_helper = require "common.utils.sproto_helper"
dofile("lualib/common/base/preload.lua")

local auth_timeout
local session_expire
local master
local connection = {}
local saved_session = {}

local CMD = {}
function CMD.init(m, id, conf)
	auth_timeout = conf.auth_timeout
	session_expire = conf.session_expire
	master = m
end

local function close(fd)
	if connection[fd] then
		socket.close(fd)
		connection[fd] = nil
	end
end

local function read_msg(fd)
	local s = socket.read (fd, 2) or error ()
	local size = s:byte(1) * 256 + s:byte(2)
	local msg = socket.read (fd, size) or error ()
	return sproto_helper.dispatch(msg, size)
end

local function send_msg(fd, msg)
	local package = string.pack (">s2", msg)
	socket.write(fd, package)
end

local AUTH_CODE_SUCCESS = 0
local function check_auth(token)
	return AUTH_CODE_SUCCESS
end

function CMD.auth(fd, addr)
	connection[fd] = addr
	skynet.timeout(auth_timeout * 100, function ()
		if connection[fd] == addr then
			logger.warningf ("connection %d from %s auth timeout!", fd, addr)
			close(fd)
		end
	end)

	socket.start (fd)
	socket.limit (fd, 8192)

	local type_, name, args, response = read_msg(fd)
	assert(type_ == "REQUEST" and name == "handshake" and args and args.ckey, "invalid handshake request")
	local challenge = crypt.randomkey()
	local ckey = args.ckey
	local serverkey = crypt.randomkey()
	local skey = crypt.dhexchange(serverkey)
	local msg = response({skey = skey, challenge = challenge})
	send_msg(fd, msg)

	type_, name, args, response = read_msg (fd)
	assert(type_ == "REQUEST" and name == "auth" and args and args.hchallenge and args.etoken, "invalid auth request")
	local secret = crypt.dhsecret(ckey, serverkey)
	local hchallenge = args.hchallenge
	assert(hchallenge == crypt.hmac64(challenge, secret), "invalid auth hchallenge")
	local etoken = args.etoken
	local token = crypt.desdecode(secret, etoken)
	local code = check_auth(token)
	if code == AUTH_CODE_SUCCESS then
		challenge = crypt.randomkey()
		token = crypt.randomkey()
		local sessionid, session = skynet.call (master, "lua", "save_session", openid, secret, challenge, token)
		msg = response({
				code = code,
				sessionid = sessionid,
				expire = session_expire,
				challenge = challenge,
				token = token,
				server = session.server,
			})
	else
		msg = response({ code = code, })
	end
	send_msg(fd, msg)

	close(fd)
end

function CMD.save_session(sessionid, openid, secret, challenge, token)
	saved_session[sessionid] = {openid = openid, secret = secret, challenge = challenge, token = token}
	skynet.timeout(session_expire * 100, function()
		local t = saved_session[sessionid]
		if t and t.openid == openid then
			saved_session[sessionid] = nil
		end
	end)
end

function CMD.verify(sessionid, htoken)
	local session = saved_session[session] or error ()
	assert(htoken == crypt.hmac64(session.token, session.secret), "invalid htoken")

	t.token = nil

	return t.openid
end

skynet.start(function ()
	sproto_helper.load(1)

	skynet.dispatch ("lua", function(_, _, command, ...)
		local function pret (ok, ...)
			if not ok then
				skynet.ret()
			else
				skynet.retpack(...)
			end
		end
		local f = assert(CMD[command])
		pret(xpcall(f, __G_TRACE_BACK__, ...))
	end)
end)
