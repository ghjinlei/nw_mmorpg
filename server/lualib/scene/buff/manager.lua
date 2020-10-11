--[[
ModuleName : BUFF_MANAGER
Path : lualib/scene/buff/manager.lua
Author : louiejin
CreateTime : 2020-08-09 08:33:12
Description :
--]]

function create(OCI)
	return BuffManager:new(OCI)
end

BuffManager = Object:inherit()

function BuffManager:on_init(OCI)
	self._owner = OCI.owner
end

function BuffManager:add_buff(typeid, level, layer)
	local owner = self._owner
	-- 获取相同buff
	local samebuff
	for _, buff in pairs(owner._buffmap) do
		if buff:get_typeid() == typeid then
			samebuff = buff
		end
	end

	local buff_info = BUFF.get_buff_info(typeid)
	if samebuff then -- 如果已有相同buff，需要处理buff叠加还是替换
		-- 如果等级不符,更新等级
		if samebuff:get_level() ~= level then
			samebuff:set_level(level)
		end

		local layerlimit = buff_info[layerlimit] or 1
		local cur_layer = samebuff:get_layer()
		if cur_layer < layer_limit then
			local new_layer = cur_layer + layer
			new_layer = new_layer > layerlimit and layerlimit or new_layer
			samebuff:set_layer(new_layer)
		end

		-- 任何变更都需要重置buff
		samebuff:reset()
		self:recalc_attr()

		return samebuff
	else    -- 无相同buff，直接添加
		local imp_class_name = buff_info["imp_class"]
		local imp_class = get_buff_class(imp_class_name)
		
		local OCI = {
			typeid = typeid,
			level = level,
			layer = layer,
			owner = self._owner,
		}
		local buff = imp_class:new(OCI)
		local buffid = buff:get_buffid()
		owner:setinto_buffmap(buffid, buff)
		self:recalc_all()
		buff:on_attach()

		return buff
	end
end

function BuffManager:remove_buff_by_id(buffid, norecalc)
	local owner = self._owner
	local buff = owner:getfrom_buffmap(buffid)
	if buff then
		buff:on_detach()
		buff:release()
		owner:setinto_buffmap(buffid)

		if not norecalc then
			self:recalc_all()
		end
	end
end

function BuffManager:remove_buff_by_typeid(typeid, norecalc)
	for buffid, buff in pairs(self._buffmap) do
		if buff:get_typeid() == typeid then
			self:remove_buff_by_id(buffid, norecalc)
			break
		end
	end
end

function BuffManager:remove_all_buff()
	for buffid, _ in pairs(self._buffmap) do
		self:remove_buff_by_id(buffid)
	end
end

function BuffManager:foreach_buff(func)
	for buffid, buff in pairs(self._buffmap) do
		func(buff)
	end
end

function BuffManager:recalc_attr()
	local owner = self._owner

	local static_attr_map = owner:get_static_attr_map()

	local added_map, set_map = {}, {}
	for buffid, buff in pairs(self._buffmap) do
		buff:calc_attr(static_attr_map, added_map, set_map)
	end

	for attrid, value in pairs(setmap) do
		added_map[attrid] = value
	end

	local last_added_map = self._last_added_map
	for attrid, value in pairs(added_map) do
		owner:setinto_dyna_attr_map(attrid, value)
		last_added_map[attrid] = nil
	end

	for attrid, _ in pairs(last_added_map) do
		owner:setinto_dyna_attr_map(attrid)
	end
	self._last_added_map = added_map
end

function BuffManager:recalc_state()
	local owner = self._owner

	local statemap = {}
	for buffid, buff in pairs(self._buffmap) do
		buff:calc_state(statemap)
	end

	local dyna_attr_map = owner:get_dyna_attr_map()
	for attrid, attr_info in pairs(get_state_info_map()) do
		local cur = dyna_attr_map[attrid]
		local new = statemap[attrid]
		if new then
			-- 有该状态的免疫属性,则免疫该状态
			local immume_attr = state_info["immume_attr"] 
			if immume_attr and dyna_attr_map[immume_attr] then
				new = nil
			end
		end

		if cur ~= new then
			owner:setinto_dyna_attr_map(attrid, new)
		end
	end
end

function BuffManager:recalc_all()
	self:recalc_attr()
	self:recalc_state()
end

function BuffManager:on_release()
	local owner = self._owner
	local buffmap = owner:get_buffmap()
	for buffid, buff in pairs(buffmap) do
		buff:release()
		buffmap[buffid] = nil
	end
end

local buff_class_map = {}
function get_buff_class(name)
	return buff_class_map[name]
end

function __init__(module, updated)
	buff_class_map["battle"] = import("lualib/scene/buff/impl_battle.lua").BuffBattle
end
