--[[
ModuleName :
Path : network.lua
Author : jinlei
CreateTime : 2020-10-07 13:31:02
Description :
--]]

local skynet = require "skynet"
local socket = require "skynet.socket"
local logger = require "common.utils.logger"
local sproto_helper = require "common.utils.sproto_helper"

local conn_fd = false
local recv_buffer = ""
local function loop_recv()
	while true do
		local data = socket.read(conn_fd)
		if not data then
			break
		end
		recv_buffer = recv_buffer .. data
	end
end

function connect(host, port)
	conn_fd = socket.open(host, port)
	skynet.fork(loop_recv)
end

function disconnect()
	socket.close(conn_fd)
	conn_fd = nil
end

local function send_message (fd, msg)
	local package = string.pack (">s2", msg)
	socket.write(fd, package)
end

local sessionmap = {}
local session_id = 0
function send_request (name, args, callback)
	logger.infof("send_request,name=%s", name)
	session_id = session_id + 1
	local msg = sproto_helper.pack_msg(name, args, session_id)
	send_message (conn_fd, msg)
	if callback then
		sessionmap[session_id] = { cb = callback }
	end
end

local function handle_request(name, args, response)
	local ret_msg = sproto_helper.handle(name, args, response)
	if ret_msg then
		send_message(conn_fd, ret_msg)
	end
end

local function handle_response(session_id, args)
	local session = sessionmap[session_id]
	if not session then
		return
	end

	if session.cb then
		session.cb(args)
	end
end

local function handle_message(t, ...)
	print("handle_message:", t, ...)
	if t == "REQUEST" then
		handle_request(...)
	else
		handle_response(...)
	end
end

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte (1) * 256 + text:byte (2)
	if size < s + 2 then
		return nil, text
	end

	return text:sub (3, 2 + s), text:sub (3 + s)
end

function tick()
	while true do
		local msg
		msg, recv_buffer = unpack_package(recv_buffer)
		if not msg then
			break
		end

		xpcall(function()
			handle_message(sproto_helper.dispatch(msg))
		end, __G_TRACE_BACK__)
	end
end

