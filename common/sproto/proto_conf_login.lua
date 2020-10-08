local conf_login = {}

conf_login.c2s = [[
.package {
	type      0 : integer
	session   1 : integer
}

handshake 1 {
	request {
		operator      0 : integer
		channel       1 : integer
		platform      2 : integer
		openid        3 : string
		appid         5 : string
		os            6 : string
		imei          7 : string
		idfa          8 : string
	}
	response {
		code          0 : integer
		msg           1 : string
		salt          2 : string
		patch         3 : string
		server_sec    4 : integer
		server_usec   5 : integer
		server_tzone  6 : integer
	}
}

auth 2 {
	request {
		data          0 : string
	}
	response {
		code          0 : integer
		msg           1 : string
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
