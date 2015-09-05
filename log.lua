-- part of lua-backup project
-- log support

local console_mt
console_mt = {
    -- attributes
    reset = 0,
    clear = 0,
    bright = 1,
    dim = 2,
    underscore = 4,
    blink = 5,
    reverse = 7,
    hidden = 8,

    -- foreground
    black = 30,
    red = 31,
    green = 32,
    yellow = 33,
    blue = 34,
    magenta = 35,
    cyan = 36,
    white = 37,

    -- background
    onblack = 40,
    onred = 41,
    ongreen = 42,
    onyellow = 43,
    onblue = 44,
    onmagenta = 45,
    oncyan = 46,
    onwhite = 47,
	
	make = function(value)
		return string.char(27) .. '[' .. tostring(value) .. 'm'
	end,
	__index = function(t, name)
		local v = console_mt[name]
		if not v then
			return ""
		end
		return console_mt.make(v)
	end,
	__newindex = function(t, k, v)
		return nil
	end,	
}

console = setmetatable({}, console_mt)

local Log = {}
local Log_mt = { __index = Log }

function Log:create()
    local new_inst = {}  
    setmetatable( new_inst, Log_mt )
    return new_inst
end

function Log:isLogOpened()
	return self.file ~= nil
end

function Log:removeLogFile()
	shell.removeFile(self.logFile)
end

function Log:openLog(dir)
	local d = os.date("*t")
	local fn = string.format("%sluabackup_%04d%02d%02d_%02d%02d%02d.log", dir, d.year, d.month, d.day, d.hour, d.min, d.sec)	
	self.file = io.open(fn, "w")
	self.logFile = fn
end

function Log:closeLog()
	if not self.file then
		return
	end
	
	self.file:close()
	self.file = nil
end

function Log:getLogFile()
	return self.logFile
end

function Log:print(...)
	local i
	local d = os.date("*t")
	local dname = string.format("[%04d-%02d-%02d %02d:%02d:%02d]", d.year, d.month, d.day, d.hour, d.min, d.sec)	
	local line = dname
	for i = 1, select("#",...) do
	
		local v = select(i, ...)
		local t = type(v)
		if t == "table" and v.log_info then
			line = line .. v:log_info()
			if i == 2 then
				line = line .. ": "
			else
				line = line .. " "
			end
		else 
			line = line .. tostring(v);
		end
    end
	if self.file then
		self.file:write(line, "\n")
	end
	print(line)
end

local function log_common(ltype)
	local types = {
		info = function ()
			return "info"
		end,
		error = function ()
			return console.red .. "err " .. console.reset
		end,	
		warning = function ()
			return console.yellow .. "warn" .. console.reset
		end,
		os = function ()
			return console.cyan .. " os " .. console.reset
		end,	
		shell = function ()
			return console.blue .. " sh " .. console.reset
		end,		
	}
		
	return "[" .. types[ltype]() .. "] "
end

function Log:info(...) 
	self:print(log_common("info"), ...)
end

function Log:os(...) 
	self:print(log_common("os"), ...)
end

function Log:shell(...) 
	self:print(log_common("shell"), ...)
end

function Log:error(...) 
	self:print(log_common("error"), ...)
end

function Log:warning(...) 
	self:print(log_common("warning"), ...)
end

log = Log:create()
