--[[
ModuleName :
Path : import.lua
Author : jinlei
CreateTime : 2019-05-22 09:43:43
Description :
--]]

_G.__import_modules = _G.__import_modules or {}
local __import_modules = _G.__import_modules
_G.__module_list = _G.__module_list or {}
local __module_list = _G.__module_list

_G.setfenv = _G.setfenv or function(f, t)
	f = (type(f) == 'function' and f or debug.getinfo(f + 1, 'f').func)
	local name
	local up = 0
	repeat
		up = up + 1
		name = debug.getupvalue(f, up)
	until name == '_ENV' or name == nil
	if name then
		debug.setupvalue(f, up, t)
	end
	return f
end

function is_module_imported(relapath)
	return __import_modules(relapath)
end

local function loadluafile(relapath)
	return g_loadfile(relapath, nil)
end

local function call_module_init(module, updated)
	if rawget(module, "__init__") then
		xpcall(module.__init__, __G_TRACE_BACK__, module, updated)
	end
end

local function insert_var_with_warning(t, k, v)
	print("warning: insert global var %s to %s", k, tostring(t))
	rawset(t, k, v)
end

local function do_import(relapath, env)
	local old = __import_modules[relapath]
	if old then
		return old
	end

	local func, err = loadluafile(relapath)
	if not func then
		return nil, err
	end

	local new = {__is_module__ = true}
	__import_modules[relapath] = new
	table.insert(__module_list, new)

	local mt = {__index = _G}
	setmetatable(new, mt)
	setfenv(func, new)()

	new.__import_time__ = os.time()
	mt.__newindex = insert_var_with_warning

	call_module_init(new, false)

	return new
end

function import(relapath, env)
	local module, err = do_import(relapath, env)
	assert(module, err)
	return module
end

