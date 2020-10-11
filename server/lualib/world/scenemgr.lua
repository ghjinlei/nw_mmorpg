--[[
ModuleName :
Path : lualib/world/scenemgr.lua
Author : jinlei
CreateTime : 2020-10-11 17:22:04
Description :
--]]
local skynet = require "skynet"
local scene_map = { }

local scene_info_map = false
function init_scene_service()
	local self = skynet.self ()
	for protoid, sceneinfo in pairs (scene_info_map) do
		local s = skynet.newservice ("scene", self)
		skynet.call (s, "lua", "init", sceneinfo)
		scene_map[protoid] = s
	end
end

local function on_autocode_loaded(m)
	scene_info_map = AUTOCODE.get_content(m, "scene")
end

function __init__(module)
	AUTOCODE.init_autocode("autocode/scene.lua", module, on_autocode_loaded)
end
