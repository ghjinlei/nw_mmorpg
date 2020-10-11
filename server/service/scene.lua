--[[
ModuleName :
Path : service/scene.lua
Author : jinlei
CreateTime : 2020-10-11 17:04:25
Description :
--]]

skynet.start (function ()
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
