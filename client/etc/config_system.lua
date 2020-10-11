--[[
ModuleName :
Path : config_system.lua
Author : jinlei
CreateTime : 2020-10-05 23:52:31
Description :
--]]
local config = {}

config.login = {}
config.login.host = "127.0.0.1"
config.login.port = 7001

config.log = {}
config.log.level = 1
config.log.level_for_console = 1
config.log.dir = "../client_log"
config.log.cache_count = 1
config.log.time_format = "%Y%m%d %H:%M:%S"

return config

