--[[
ModuleName :
Path : lualib/robot/main.lua
Author : jinlei
CreateTime : 2020-10-07 13:08:13
Description :
--]]
local crypt = require "client.crypt"
local logger = require "common.utils.logger"
local sproto_helper = require "common.utils.sproto_helper"

local user = {
	openid          = false,
	openkey         = false,
	clientkey       = false,
	serverid        = false,
	sessionid       = false,
	character_list  = false
}

function set_openid(openid)
	user.openid = openid
end

function set_openkey(openkey)
	user.openkey = openkey
end

function set_serverid(serverid)
	user.serverid = serverid
end

function login(host, port)
	NETWORK.connect(host, port)

	local clientkey =  crypt.randomkey()
	user.clientkey = clientkey
	local ckey = crypt.dhexchange(clientkey)

	local params = {ckey = ckey, openid = user.openid}
	NETWORK.send_request("handshake", params, response_handshake)
end

function response_handshake(args)
	logger.infof("response_handshake.challenge:%s", tostring(args.challenge))
	local challenge = args.challenge
	local skey = args.skey
	local secret = crypt.dhsecret(skey, user.clientkey)
	local hchallenge = crypt.hmac64(challenge, secret)
	local token = string.format("%s:%s",
		crypt.base64encode(user.openid),
		crypt.base64encode(user.openkey))
	local etoken = crypt.desencode(secret, token)

	local params = {
		hchallenge  = hchallenge,
		etoken      = etoken,
	}
	NETWORK.send_request ("auth", params, response_auth)
end

local AUTH_CODE_SUCCESS = 0
function response_auth(args)
	if args.code ~= AUTH_CODE_SUCCESS then
		return
	end
	-- 开始连接游戏网关
	NETWORK.connect(host, port)

	local sessionid = args.sessionid
	local token = args.token
	local htoken = crypt.hmac64(token, secret)
	local params = {
		sessionid = sessionid,
		token = token,
	}
	NETWORK.send_request("login", params, response_login)
end

function response_login(args)

end

function logout()

end

function enter_game(idx, race, sex)
	local character_list = user.character_list
	if not character_list then

	end


	NETWORK.send_request ("enter_game", params, response_auth)
end

