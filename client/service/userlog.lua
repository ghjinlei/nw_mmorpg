--[[
ModuleName :
Path : service/userlog.lua
Author : jinlei
CreateTime : 2020-10-05 16:48:56
Description :
--]]
local skynet = require "skynet"
require "skynet.manager"
local logger = require "common.utils.logger"
local config_log = require "config_system".log
local fs = require "common.utils.fs"
dofile("lualib/common/base/preload.lua")

local log_dirpath = config_log.dir
local max_cache_count = config_log.cache_count or 1
local log_shift_time = config_log.shift_time or 3600

local function gen_log_filepath(time_now)
	return string.format("%s/%s.log", log_dirpath, os.date("%Y%m%d%H", time_now))
end

local Logger = {}
function Logger:new()
	local o = {
		_log_file      = nil,
		_log_file_time = 0,
		_log_size      = 0,
		_cache_count   = 0,
	}
	setmetatable(o, {__index = self})
	return o
end

function Logger:start()
	local msg = "-----------------LOGGER START-----------------"
	local log = logger.format_log(msg, logger.loglevel_info)
	self:add_log(log)
end

function Logger:shutdown()
	local msg = "-----------------LOGGER SHUTDOWN-----------------"
	local log = logger.format_log(msg, logger.loglevel_info)
	self:add_log(log)
	self:close_log_file()
end

function Logger:flush()
	if self._log_file and self._cache_count > 0 then
		self._log_file:flush()
		self._cache_count = 0
	end
end

function Logger:open_log_file(time_now)
	self:close_log_file()

	local new_log_filepath = gen_log_filepath(time_now)
	local dirpath = fs.dirname(new_log_filepath)
	if not fs.isdir(dirpath) then
		fs.mkdir(dirpath)
	end

	self._log_file = assert(io.open(new_log_filepath, "a+"))
	self._log_file_time = time_now
	self._log_size = self._log_file:seek("end")
end

function Logger:close_log_file()
	if self._log_file then
		self:flush()
		self._log_file:close()
		self._log_file = nil
	end
end

function Logger:add_log(log)
	local time_now = math.floor(skynet.time())
	if time_now - self._log_file_time >= log_shift_time then
		self:open_log_file(time_now)
	end

	self._log_file:write(log .. "\n")
	self._log_size = self._log_size + #log
	self._cache_count = self._cache_count + 1

	-- 超过max_cache_count行刷新
	if self._cache_count >= max_cache_count then
		self:flush()
	end
end

local logger_ins
local function on_message(msg, address)
	if not logger_ins then
		return
	end

	local msg_len = #msg
	if msg_len > 3 then
		if string.match(msg, "^%[20") then
			logger_ins:add_log(msg)
		else
			logger_ins:add_log(msg)
			logger.print_console(msg, logger.loglevel_skynet)
		end
	elseif msg == logger.cmd_shutdown then
		logger_ins:shutdown(msg, address)
		logger_ins = nil
	end
end

local function log_traceback(err)
	print("\27[31m" .. "USERLOG ERROR:" .. tostring(err) .. "\n" ..  debug.traceback() .. "\27[0m")
end

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
	dispatch = function(_, address, msg)
		xpcall(function()
			on_message(msg, address)
		end, log_traceback)
	end
}

skynet.start(function()
	xpcall(function()
		logger_ins = Logger:new()
		logger_ins:start()
	end, log_traceback)

	skynet.register ".logger"
end)

