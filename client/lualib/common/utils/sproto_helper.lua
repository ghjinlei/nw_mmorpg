--[[
ModuleName :
Path : lualib/common/utils/sproto_helper.lua
Author : jinlei
CreateTime : 2020-03-30 19:38:52
Description :
--]]
local sprotoloader = require "sprotoloader"
local sproto_host
local sproto_request

local sproto_helper = {}

function sproto_helper.load(index)
	sproto_host = sprotoloader.load(index):host "package"
	sproto_request = sproto_host:attach(sprotoloader.load(index + 1))
end

local msg_handlers = {}
function sproto_helper.reg_msghandler(proto_name, handler)
	assert(type(proto_name) == "string")
	msg_handlers[proto_name] = handler
end

function sproto_helper.reg_msghandlers(handlers)
	for proto_name, handler in pairs(handlers) do
		sproto_helper.reg_msghandler(proto_name, handler)
	end
end

function sproto_helper.dispatch(msg, sz)
	return sproto_host:dispatch(msg, sz)
end

local empty_table = {}
function sproto_helper.handle(name, args, response, ...)
	local handler = msg_handlers[name]
	if not handler then
		return false, "sproto does not include" .. name
	end

	local ret = handler(args, ...)
	return response and response(ret or empty_table)
end

function sproto_helper.pack_msg(proto_name, args, session)
	return sproto_request(proto_name, args, session)
end

return sproto_helper
