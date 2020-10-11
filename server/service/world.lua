--[[
ModuleName :
Path : service/world.lua
Author : jinlei
CreateTime : 2020-10-11 17:04:46
Description :
--]]
local skynet = require "skynet"
local logger = require "common.utils.logger"
dofile("lualib/common/base/preload.lua")

AUTOCODE = import("common/module/autocode.lua")
SCENE_MGR = import("lualib/world/scenemgr.lua")

local CMD = {}
function CMD.character_enter(agent, character)

end

function CMD.character_leave (agent, character)
	online_character[character] = nil
end

skynet.start (function ()
	SCENE_MGR.init_scene_service()

	skynet.dispatch ("lua", function (_, source, command, ...)
		local function pret (ok, ...)
			if not ok then
				skynet.ret()
			else
				skynet.retpack(...)
			end
		end
		local f = assert(CMD[command])
		pret(xpcall(f, __G_TRACE_BACK__, ...))
	end)
end)
