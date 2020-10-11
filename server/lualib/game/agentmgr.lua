--[[
ModuleName :
Path : lualib/game/agentmgr.lua
Author : jinlei
CreateTime : 2020-10-11 21:26:09
Description :
--]]
local skynet = require "skynet"
local config_system = require "config_system"
local config_game = config_system.game

gate = false

online_account2agent = {}
online_fd2agent = {}

database_pool = {}
database_idx = 0
local function next_db()
	database_idx = database_idx % #database_pool + 1
	return database_pool[database_idx]
end

total_agent_count = 0
free_agent_pool = {}
local function new_agent()
	local agent
	if #free_agent_pool > 0 then
	        agent = table.remove(free_agent_pool)
	else
	        agent = skynet.newservice("agent", gate, skynet.self())
	        total_agent_count = total_agent_count + 1
	end
	return agent
end

local function free_agent(agent)
	table.insert(free_agent_pool, agent)
end

local function get_use_agent_count()
        return total_agent_count - #free_agent_pool
end

function login_account(fd, accountid)
	local agent = online_account2agent[accountid]
	if agent then  -- 账号已存在，顶号
		skynet.call (agent, "lua", "kick", accountid)
	end
	agent = new_agent()

	online_fd2agent[fd] = agent
	online_account2agent[accountid] = agent
	skynet.call(agent, "lua", "start", fd, accountid)
end

function close_agent(fd)
	local a = online_fd2agent[fd]
	online_fd2agent[fd] = nil
	if a then
		skynet.call(gate, "lua", "kick", fd)
		skynet.send(a, "lua", "disconnect")
	end
end

local database_count = config_game.agent_database_count or 1
function init_agent()
        for i = 1, database_count do
                db = skynet.newservice("database")
                table.insert(database_pool, db)
        end

        -- 预分配一定数量的agent
        for i = 1, config_game.pre_alloc_agent_count or 0 do
                local agent = skynet.newservice("agent", gate, skynet.self(), next_db())
                free_agent(agent)
        end
        total_agent_count = #free_agent_pool
end

