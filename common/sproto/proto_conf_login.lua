local conf_login = {}

conf_login.c2s = [[
.package {
	type      0 : integer
	session   1 : integer
}

handshake 1 {
	request {
		ckey          0 : string
		openid        1 : string
	}
	response {
		skey          0 : string
		challenge     1 : string
	}
}

auth 2 {
	request {
		hchallenge    0 : string
		etoken        1 : string
	}
	response {
		code          0 : integer
		sessionid     1 : integer
		token         2 : string
	}
}
]]

conf_login.s2c = [[
.package {
	type      0 : integer
	session   1 : integer
}
]]

return conf_login
