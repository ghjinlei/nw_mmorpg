local skynet = require "skynet"
__G_TRACE_BACK__ = function(err)
	local errmsg = debug.traceback(err, 2)
	skynet.error(errmsg)
end

function g_loadfile(relapath, env)
	return loadfile("./" .. relapath, "bt", env)
end

function g_dofile(relapath)
	local m = nil
	xpcall(function()
		local func, err = assert(g_loadfile(relapath, _G))
		m = func()
	end, __G_TRACE_BACK__)
	return m
end

local function load_globalfilelist()
	local globalfilelist = {
		"common/base/macro.lua",
		"common/base/import.lua",
		"common/base/class.lua",
		"common/base/extend.lua",
	}

	for _, filepath in ipairs(globalfilelist) do
		g_dofile(filepath)
	end
end

load_globalfilelist()

xpcall(function()
	TIME          = import("common/module/time.lua")
	UTILS         = import("common/module/utils.lua")
end, function(err)
	print(err)
end)

