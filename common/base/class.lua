--[[
ModuleName :
Path : class.lua
Author : jinlei
CreateTime : 2019-06-21 16:11:43
Description :
--]]
-- 获取一个class的父类
function super(cls)
	return cls.__superclass
end

function get_class(obj)
	local mt = getmetatable(obj)
	if mt then
		return mt.__class
	end
end

function is_class(tbl)
	return tbl.__classname and true or false
end

local readonly_mt = {
	__newindex = function()
		assert(false, "readonly")
	end
}
local function set_classmetatable(cls)
	cls.__class_mt = {__index = cls, __class = cls}
	setmetatable(cls.__class_mt, readonly_mt)
end

local function inherit_with_copy(baseCls, cls)
	cls = cls or {}

	if not basecls.__superclass then
		basecls.__superclass = {}
		setmetatable(basecls.__subclass, {__mode = "v"})
	end
	table.insert(basecls.__subclass, cls)

	for k, v in pairs(basecls) do
		if not cls[k] and type(v) == "function" then
			cls[k] = v
		end
	end

	cls.__superclass = basecls

	local mt = getmetatable(cls) or {}
	mt.__call = function(...)
		return cls:new(...)
	end
	setmetatable(cls, mt)
	setClassMetatable(cls)

	return cls
end

Object = {
	__classname = "Object",

	inherit = inherit_with_copy,
}
set_classmetatable(Object)

function Object:tostring()
	local oid = self:get_oid()
	local classname = self:get_classname()
	return string.format("objectid:%d,classname:%s", oid, classname)
end

function Object:get_classname()
	return self.__classname
end

function Object:attach_to_class(obj)
	setmetatable(obj, self.__class_mt)
	return obj
end

__g_objectid__ = __g_objectid__ or 10000
local function gen_objectid()
	__g_objectid__ = __g_objectid__ + 1
	return __g_objectid__
end

__g_objectid_map__ = __g_objectid_map__ or {}
setmetatable(__g_objectid_map__, {__mode = "v"})

local function on_init()
end

function Object:new(...)
	local obj = {
		_objectid = gen_objectid()
	}

	self:attach_to_class(obj)
	__g_objectid_map__[obj._objectid] = obj

	obj:__init__(...)

	return obj
end

function Object:get_oid()
	return self._objectid
end

function Object:on_init(...)
end

function Object:release()
	if self.__released then
		return
	end

	if TIMER then
		TIMER.remove_all_timers(self)
	end
	if EVENT then
		EVENT.remove_all_events(self)
	end

	self.__released = true
end

function Object:on_release()
end

