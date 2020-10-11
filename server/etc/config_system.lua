--[[
ModuleName :
Path : config_system.lua
Author : jinlei
CreateTime : 2020-10-05 23:52:31
Description :
--]]
local config = {}

config.server = {}
config.server.host_id = 1001
config.server.host_name = "1001"
config.server.debug_console_port = 9002

config.dbserver = {}
config.dbserver.db_name = tostring(config.server.host_id)

config.login = {}
config.login.host = "127.0.0.1"
config.login.port = 7001
config.login.slave_count = 5          -- loginslave数量
config.login.auth_timeout = 10        -- 登录验证超时时间
config.login.session_expire = 10      -- 登录session存在10秒，在此期间进入游戏

config.game = {}
config.game.host = "127.0.0.1"
config.game.port = 8001

config.log = {}
config.log.level = 1
config.log.level_for_console = 1
config.log.dir = "../server_log"
config.log.cache_count = 1
config.log.time_format = "%Y%m%d %H:%M:%S"

return config

