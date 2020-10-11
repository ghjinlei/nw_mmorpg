local skynet = require "skynet"
local sprotoloader = require "sprotoloader"
local sprotoparser = require "sprotoparser"

local proto_conf_login = require "common.sproto.proto_conf_login"
local proto_conf_game = require "common.sproto.proto_conf_game"

local proto_idx = {
	LOGIN = 1,
	LOGIN_C2S = 1,
	LOGIN_S2C = 2,

	GAME = 3,
	GAME_C2S = 3,
	GAME_S2C = 4,
}

skynet.start(function()
	sprotoloader.save(sprotoparser.parse(proto_conf_login.c2s), proto_idx.LOGIN_C2S)
	sprotoloader.save(sprotoparser.parse(proto_conf_login.s2c), proto_idx.LOGIN_S2C)

	sprotoloader.save(sprotoparser.parse(proto_conf_game.c2s), proto_idx.GAME_C2S)
	sprotoloader.save(sprotoparser.parse(proto_conf_game.s2c), proto_idx.GAME_S2C)

	skynet.error("protoloader.lua finish")
	-- don't call skynet.exit() , because sproto.core may unload and the global slot become invalid
end)
