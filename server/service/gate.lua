local skynet = require "skynet"
local netpack = require "skynet.netpack"
local socketdriver = require "skynet.socketdriver"
local logger = require "common.utils.logger"
dofile("lualib/common/base/preload.lua")

local socket          -- listen socket
local queue           -- message queue
local maxclient = config_gate.maxclient or 1024
local client_number = 0
local CMD = setmetatable({}, { __gc = function() netpack.clear(queue) end })
local nodelay = false

local watchdog
--[[
	[fd] = {
		agent = xxx,
	}
--]]
local connection = {}
local forwarding = {}>---- agent -> connection

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

local MSG = {}

skynet.register_protocol {
	name = "socket",
	id = skynet.PTYPE_SOCKET,       -- PTYPE_SOCKET = 6
	unpack = function ( msg, sz )
		return netpack.filter( queue, msg, sz)
	end,
	dispatch = function (_, _, q, type, ...)
		queue = q
		if type then
			MSG[type](...)
		end
	end
}

local function dispatch_msg(fd, msg, sz)
	-- recv a package, forward it
	local c = connection[fd]
	local agent = c.agent
	if agent then
		-- It's safe to redirect msg directly , gateserver framework will not free msg.
		skynet.redirect(agent, c.client, "client", fd, msg, sz)
	else
		skynet.send(watchdog, "lua", "socket", "data", fd, skynet.tostring(msg, sz))
		-- skynet.tostring will copy msg to a string, so we must free msg here.
		skynet.trash(msg,sz)
	end
end

MSG.data = dispatch_msg

local function dispatch_queue()
	local fd, msg, sz = netpack.pop(queue)
	if fd then
		-- may dispatch even the handler.message blocked
		-- If the handler.message never block, the queue should be empty, so only fork once and then exit.
		skynet.fork(dispatch_queue)
		dispatch_msg(fd, msg, sz)

		for fd, msg, sz in netpack.pop, queue do
			dispatch_msg(fd, msg, sz)
		end
	end
end

MSG.more = dispatch_queue

function MSG.open(fd, address)
	if client_number >= maxclient then
		logger.infof("msg.open too many client! will close! fd=%d address=%s", fd, address)
		socketdriver.close(fd)
		return
	end
	client_number = client_number + 1
	logger.infof("msg.open fd=%d address=%s", fd, address)

	if nodelay then
		socketdriver.nodelay(fd)
	end

        local c = {
                fd = fd,
                ip = addr,
        }
        connection[fd] = c
        skynet.send(watchdog, "lua", "socket", "open", fd, addr)
end

local function close_fd(fd)
	local c = connection[fd]
	if c then
		connection[fd] = nil
	end
end

function MSG.close(fd)
	if fd ~= socket then
		local c = connection[fd]
		if c then
			skynet.send(c.conn, "lua", "socket", "close", fd)
		end
		close_fd(fd)
	else
		socket = nil
	end
end

function MSG.error(fd, msg)
	if fd ~= socket then
		skynet.send(c.conn, "lua", "socket", "error", fd, msg)
		close_fd(fd)
	else
		socketdriver.close(fd)
		logger.errorf("gateserver close listen socket, accept error:%s", tostring(msg))
	end
end

function MSG.warning(fd, sz)
	local c= connection[fd]
	if c then
		skynet.send(c.conn, "lua", "socket", "warning", fd, sz)
	end
end

-- 启动监听,开始服务
function CMD.open(source, conf)
	assert(not socket)
	local ip, port = conf.host, conf.port
	maxclient = conf.maxclient or 1024
	nodelay = conf.nodelay
	watchdog = conf.watchdog
	socket = socketdriver.listen(ip, port)
	logger.infof("******************socket open %d %s:%d******************", socket, ip, port)
	socketdriver.start(socket)
	return true
end

-- 关闭监听
function CMD.close()
	logger.infof("******************socket close %d***********************", socket or 0)
	if not socket then
		return
	end
	socketdriver.close(socket)
	socket = nil
end

local function unforward(c)
	if c.agent then
		c.agent = nil
		c.client = nil
	end
end

function CMD.forward(source, fd, client, address)
	local c = assert(connection[fd])
	unforward(c)
	c.client = client or 0
	c.agent = address or source
end

-- 关闭客户端连接
function CMD.close_fd(source, fd, reason)
	assert(fd and fd ~= socket)
	logger.infof("gate_close_fd,source=%s,fd=%s,reason=%s", tostring(source), tostring(fd), tostring(reason))

	connection[fd].conn = nil
	socketdriver.close(fd)
end

skynet.start(function()
	skynet.dispatch("lua", function (_, address, cmd, ...)
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

