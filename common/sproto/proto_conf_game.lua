local conf_game = {}

conf_game.c2s = [[
.package {
	type 0 : integer
	session 1 : integer
}

login 1 {
	request {
		sessionid     0 : integer
		htoken        1 : string
	}
	response {
		code          0 : integer
	}
}
]]

conf_game.s2c = [[
.package {
	type 0 : integer
	session 1 : integer
}
]]
return conf_game
