--[[
ModuleName :
Path : lualib/agent/character.lua
Author : jinlei
CreateTime : 2020-10-11 15:48:05
Description :
--]]
local sproto_helper = require "common.utils.sproto_helper"

Character = Object:inherit()

function save_account()
	skynet.call(database, "lua", "update_by_id", "account", accountid, account_data)
end

function find_account()
	-- 加载所有character数据
	local account_data  = skynet.call(database, "lua", "find_by_id", "account", accountid)
	return account_data
end

function save_character()
	if not character_dirty then 
		return
	end
	character_dirty = false

	if self.userId and self.saveData then
		skynet.call(database, "lua", "update_by_id", "character", characterid, character)
	end
end

local function create_character(name, race, sex)
	local character = {
		name = name,
		race = race,
		sex = sex,
		level = 1,
		exp = 1,
		scene_protoid = 1001,     -- 新手村1001
		movement = {
			mode = 0,
			pos = { x = r.pos_x, y = r.pos_y, z = r.pos_z, o = r.pos_o },
		},
	}
	return character
end

local handlers = {}
function handlers.character_list(args)
	local account_data = find_account()
	return character_list
end

function handlers.character_create(args)
	local name = args.name
	local race = args.race
	local sex = args.sex
	local character = create_character(name, race, sex)
	save_character()

	return {character = character}
end

function handlers.character_enter(args)
	local characterid = args.characterid
	local character = skynet.call (database, "lua", "character", "find_by_id", characterid)

	local world = skynet.uniqueservice ("world")
	skynet.call (world, "lua", "character_enter", characterid)

	return { character = character }
end

function __init__(module)
	sproto_helper.reg_msghandlers(handlers)
end

