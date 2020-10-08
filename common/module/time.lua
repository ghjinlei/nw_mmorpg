--[[
ModuleName :
Path : time.lua
Author : jinlei
CreateTime : 2020-07-02 17:24:22
Description :
--]]

get_time = os.time

function get_time_millis()
	local sec, usec = misc.gettimeofday()
	return sec + usec / 1e6
end

--将"2005-06-01 00:00:00"格式的日期转换为time table形式
function date2table(datetime)
	if type(datetime) ~= "string" or
		not string.match(datetime, "^%d+%-%d+%-%d+ %d+:%d+:%d+$") then
		return
	end

	local match_table = {}

	for item in string.gmatch(datetime, "%d+") do
		table.insert(match_table, item)
	end

	local time_table = {}
	time_table.year = match_table[1]
	time_table.month = match_table[2]
	time_table.day = match_table[3]
	time_table.hour = match_table[4]
	time_table.min = match_table[5]
	time_table.sec = match_table[6]
	return time_table
end

--将"00:00:00"格式的日期转化为time table形式
function daytime2table(daytime)
	if type(daytime) ~= "string" or not string.match(daytime, "%d+:%d+:%d+$") then
		return
	end
	local match_table = {}

	for item in string.gmatch(daytime, "%d+") do
		table.insert(match_table, item)
	end

	local time_table = {}
	time_table.hour = match_table[1]
	time_table.min = match_table[2]
	time_table.sec = match_table[3]
	return time_table
end

--将"2006-06-01 10:00:00"这样的时间转换为秒
function date2sec(datetime)
	return os.time(date2table(datetime))
end

--将"10:00:00"这样的时间转化为秒
function daytime2sec(daytime)
	local time_table = daytime2table(daytime)
	return time_table.hour * 3600 + time_table.min * 60 + time_table.sec
end

--将秒数转成字符串 "2009-01-03 22:10:53"
function sec2datetime(sec)
	return os.date("%Y-%m-%d %H:%M:%S", sec or os.time())
end
