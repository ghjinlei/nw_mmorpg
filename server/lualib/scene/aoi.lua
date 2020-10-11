--[[
ModuleName : AOI
Path : lualib/scene/aoi.lua
Author : louiejin
CreateTime : 2020-08-07 15:32:28
Description :
--]]
local skynet = require "skynet"
local laoi = require "laoi"
local sproto_helper = require "common.utils.sproto_helper"

local math_ceil = math.ceil
local math_floor = math.floor

Grid = Object:inherit()
function Grid:on_init(OCI)
	self._dirty = false
	self._entitymap = {}
	self._avatarmap = {}
	self._npcmap = {}
	self._movedmap = {}
end

function Grid:entity_enter(entitynode)
	local entityid = entitynode.entityid
	assert(not self._entitymap[entityid])

	self._entitymap[entityid] = entitynode
	if self._isavatar then
		self._avatarmap[entityid] = entitynode
	else
		self._npcmap[entityid] = entitynode
	end
end

function Grid:entity_leave(entityid)
	self._entitymap[entityid] = nil
	self._avatarmap[entityid] = nil
	self._npcmap[entityid] = nil
	self._movedmap[entityid] = nil
end

function Grid:sync2avatars()
	if not self._dirty then
		return
	end

	if not next(self._avatarmap) then
		self._movedmap = {}
		self._dirty = false
	end

	local movedlist = {}
	for _, entitynode in pairs(self._movedmap) do
		table.insert(movedlist, entitynode)
	end

	self._scene:multi_send_to_avatars("aoi_move_multi", {entitylist = movedlist}, self._avatarmap)

	self._movedmap = {}
	self._dirty = false
end

AOI = Object:inherit()
function AOI:on_init(OCI)
	self._scene = OCI.scene
	self._height = math_ceil(OCI.heigth / OCI.gridsize)
	self._width = math_ceil(OCI.width / OCI.gridsize)
	self._gridmap = {}
	self._circlemap = {}
	self._entitymap = {}
	self._entitycount = 0
	self._updatetime = 0
	self._c_aoi = laoi.space_create()

	for gridz = 0, self._height - 1 do
		for gridx = 0, self._width - 1 do
			local idx = self:gridxz2idx(gridx, gridz)
			self._gridmap[idx] = Grid:New({scene = self._scene, gridx = gridx, gridz = gridx, idx = idx})
		end
	end

	self:call_fre(1, function()
		self:update(1)
	end)
end

function AOI:gridxz2idx(gridx, gridz)
	return gridz * self._width + gridx
end

function AOI:idx2gridxz(idx)
	return idx % self._width, math_floor(idx / self._width)
end

function AOI:get_grid_by_xz(x, z)
	local gridx = math_floor(x / self._gridsize)
	local gridz = math_floor(z / self._gridsize)
	local idx = self:gridxz2idx(gridx, gridz)
	return self._gridmap[idx]
end

-- 格子编号从小到大排列
function AOI:get_neighbor_grid_list(grid)
	local grididxlist = {}
	local min_gridx = grid.gridx - 1 < 0 and 0 or grid.gridx - 1
	local max_gridx = grid.gridx + 1 > self._width and self._width or grid.gridx + 1
	local min_gridz = grid.gridz - 1 < 0 and 0 or grid.gridz - 1
	local max_gridz = grid.gridz + 1 > self._height and self._height or grid.gridz + 1

	for gridz = min_gridz, max_gridz do
		for gridx = min_gridx, max_gridx do
			local grididx = self:gridxz2idx(gridx, gridz)
			table.insert(grididxlist, grididx)
		end
	end
	return grididxlist
end

function AOI:entity_enter(entity, x, z)
	local entityid = entity:get_entityid()
	self._c_aoi.enter(entityid, x, z)

	local entitynode = {
		entityid = entityid,
		x = math_floor(x),
		z = math_floor(z),
	}
	self._entitymap[entityid] = entitynode

	local grid = self:get_grid_by_xz(x, z)
	-- 通知周围entity,进入消息
	if grid then
		grid:entity_enter(entitynode)
		local grididxlist = self:get_neighbor_grid_list(grid)
		self:notify_neighbor_of_me_enter(grididxlist, entitynode)
	end
	self._entitycount = self._entitycount + 1
end

function AOI:entity_leave(entityid)
	local entitynode = self._entitymap[entityid]
	assert(entitynode)

	-- 1.处理c_aoi
	self._c_aoi:leave(entityid)

	-- 2.处理grid
	local grid = entitynode.grid
	grid:entity_leave(entityid)

	-- 3.删除entity
	self._entitymap[entityid] = nil

	--4.通知周围entity,离开消息
	local grididxlist = self:get_neighbor_grid_list(grid)
	self:notify_on_entity_leave(grididxlist, entitynode)

	self._entitycount = self._entitycount - 1
end

function AOI:calc_grid_diff(old_grid, new_grid)
	local old_neighborlist = self:get_neighbor_grid_list(old_grid)
	local new_neighborlist = self:get_neighbor_grid_list(new_grid)

	local keeplist, addlist, rmvlist = {}, {}, {}

	local oldsize = #old_neighborlist
	local newsize = #new_neighborlist
	local i, j = 1, 1
	while(i <= oldsize or j <= newsize) do
		local oldidx = old_neighborlist[i] or 999999
		local newidx = new_neighborlist[j] or 999999
		if newidx < oldidx then
			table.insert(addlist, newidx)
			j = j + 1
		elseif newidx == oldidx then
			table.insert(keeplist, oldidx)
			i, j = i + 1, j + 1
		elseif newidx > oldidx then
			table.insert(rmvlist, oldidx)
			i = i + 1
		end
	end
	
	return keeplist, addlist, rmvlist
end

function AOI:entity_move(entityid, x, z)
	-- 1.处理c_aoi
	self._c_aoi.move(entityid, x, z)

	-- 2.处理grid
	local entitynode = self._entitymap[entityid]
	x = math_floor(x)
	z = math_floor(z)
	if x == entitynode.x and z == entitynode.z then
		return
	end
	entitynode.x = x
	entitynode.z = z

	local old_grid = entitynode.grid
	local new_grid = self:get_grid_by_xz(x, z)

	local keeplist
	if old_grid == new_grid then
		keeplist = self:get_neighbor_grid_list(old_grid)
	else
		local addlist, rmvlist
		keeplist, addlist, rmvlist = self:calc_grid_diff(old_grid, new_grid)
		-- 1.清理旧grid
		old_grid:entity_leave(entityid)
		-- 2.通知rmv列表,离开消息
		self:notify_neighbor_of_me_leave(rmvlist, entitynode)
		-- 3.通知自己,rmv列表所有entity都离开了
		if entitynode.isavatar then
			self:notify_me_of_neighbor_leave(rmvlist, entitynode)
		end
		-- 4.通知add列表,进入消息
		self:notify_neighbor_of_me_enter(addlist, entitynode)
		-- 5.通知自己,add列表所有entity都进入
		if entitynode.isavatar then
			self:notify_me_of_neighbor_enter(addlist, entitynode)
		end
	end

	self:notify_neighbor_of_me_move(keeplist, entitynode)
end

function AOI:notify_neighbor_of_me_enter(grididxlist, entitynode)
	local packedmsg = sproto_helper.packmsg("aoi_enter", {entity = entitynode})
	for _, grididx in ipairs(grididxlist) do
		local grid = self._gridmap[grididx]
		self._scene:multi_send_to_avatars_packed(packedmsg, grid._avatarmap)
	end
end

function AOI:notify_me_of_neighbor_enter(grididxlist, entitynode)
	local entitylist = {}
	for grididx, _ in ipairs(grididxlist) do
		local grid = self._gridmap[grididx]
		for _, entitynode in pairs(grid._entitymap) do
			table.insert(entitylist, entitynode)
		end
	end
	self._scene:send_to_avatar("aoi_enter_multi", {entitylist = entitylist}, entitynode.entityid)
end

function AOI:notify_neighbor_of_me_move(grididxlist, entitynode)
	-- 这个不需要实时刷新
	local entityid = entitynode.entityid
	local dirtymap = self._dirtymap
	for grididx, _ in ipairs(grididxlist) do
		local grid = self._gridmap[grididx]
		grid._movedmap[entityid] = entitynode
		grid._dirty = true
		dirtymap[grididx] = true
	end
end

function AOI:notify_neighbor_of_me_leave(grididxlist, entitynode)
	local packedmsg = sproto_helper.packmsg("aoi_leave", {entity = entitynode})
	for _, grididx in ipairs(grididxlist) do
		local grid = self._gridmap[grididx]
		grid._movedmap[entitynode.entityid] = nil
		self._scene:multi_send_to_avatars_packed(packedmsg, grid._avatarmap)
	end
end

function AOI:notify_me_of_neighbor_leave(grididxlist, entitynode)
	local entitylist = {}
	for _, grididx in ipairs(grididxlist) do
		local grid = self._gridmap[grididx]
		for _, entitynode in pairs(grid._entitymap) do
			table.insert(entitylist, entitynode)
		end
	end
	self._scene:send_to_avatar("aoi_leave_multi", {entitylist = entitylist}, entitynode.entityid)
end

function AOI:register_circle(key, circle)
	self._circlemap[key] = circle
end

function AOI:unregister_circle(key)
	self._circlemap[key] = nil
end

function AOI:update(deltatime)
	self:update_all_circles(deltatime)
	self:sync2allavatars(deltatime)
end

function AOI:update_circle(circle, deltatime)
	if circle.interval then
		circle.updatetime = circle.updatetime + deltatime
		if circle.updatetime < circle.interval then
			return
		end
		circle.updatetime = 0
	end

	local c_aoi = self._c_aoi

	local entitymap = circle.entitymap
	local new_entitymap = c_aoi:search_circle(circle.center, circle.radius)

	local enterfunc = circle.enter
	if enterfunc then
		for entityid, _ in pairs(new_entitymap) do
			if not entitymap[entityid] then
				enterfunc(entityid)
			end
		end
	end

	local exitfunc = circle.exit
	if exitfunc then
		for entityid, _ in pairs(entitymap) do
			if not new_entitymap[entityid] then
				exitfunc(entityid)
			end
		end
	end

	for k in pairs(entitymap) do
		entitymap[k] = nil
	end

	for k, v in pairs(new_entitymap) do
		entitymap[k] = v
	end
end

function AOI:update_all_circles(deltatime)
	for _, circle in pairs(self._circlemap) do
		self:update_circle(circle, deltatime)
	end
end

function AOI:sync2allavatars(deltatime)
	local updatetime = self._updatetime
	updatetime = updatetime + deltatime
	if updatetime * 100 < self._entitycount then
		self._updatetime = updatetime
		return
	end
	self._updatetime = 0

	for gridid, _ in pairs(self._dirtymap) do
		self._gridmap[gridid]:sync2avatars()
	end
	self._dirtymap = {}
end

