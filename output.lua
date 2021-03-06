-- part of lua-backup project
-- output interface

local Output = {}
local Output_mt = { __index = Output }

local function Output_create()
    local new_inst = {}   
    setmetatable( new_inst, Output_mt )
	new_inst.outputs = { }
    return new_inst
end

function Output:add(outp)
	self.outputs[#self.outputs + 1] = { 
		instance = outp, 
	}
end

function Output:putBackupFiles(files)
	local i,v
	for i,v in ipairs(self.outputs) do
		local inst = v.instance
		if inst:isBackupSink() then
			local fi, fv
			for fi,fv in ipairs(files) do
				log:info(inst, "Putting file '" .. fv .. "'")
				inst:put(fv)
			end
		end
	end
end

function Output:putLogFile(file)
	local i,v
	for i,v in ipairs(self.outputs) do
		local inst = v.instance
		if inst:isLogSink() then
			log:info(inst, "Putting log file '" .. file .. "'")
			inst:putLog(file)
		end
	end
end

function Output:onBeforeStart()
	for i,v in ipairs(self.outputs) do
		v.instance:onBeforeStart()
	end
end

function Output:onAfterStop()
	for i,v in ipairs(self.outputs) do
		v.instance:onAfterStop()
	end
end

function Output:OnSummary(summaryinfo)
	for i,v in ipairs(self.outputs) do
		v.instance:OnSummary(summaryinfo)
	end
end

output = Output_create()

---------------------------------------------

OutputInterface = {}
OutputInterface_mt = { __index = OutputInterface }

function OutputInterface:init(config)
	config = config or { }
	self.static = backup:getOutputStaticData(config.name)
	if config.name then
		self.name = config.name
	end
	self.config = config
	
	if config.triggers then
		self.triggers = config.triggers
	else
		self.triggers = { }
	end	
	
	if not config.mode then
		self.mode = { backup = "y" }
	else
		self.mode = config.mode
	end
end

function OutputInterface:log_info()
	return "Output " .. self:getName()
end

function OutputInterface:isBackupSink()
	return self.mode.backup
end

function OutputInterface:isLogSink()
	return self.mode.log
end

function OutputInterface:isSummarySink()
	return self.mode.summary
end

function OutputInterface:getName()
	if self.name then
		return self.name
	else
		return "Unnamed output"
	end
end

function OutputInterface:put(file)
end

function OutputInterface:putLog(file)
	if self.triggers.OnLogFile then
		self.triggers.OnLogFile(self, file)
	end
end

function OutputInterface:onBeforeStart()
	if self.triggers.onBeforeStart then
		log:info(self, "Executing trigger onBeforeStart")
		self.triggers.onBeforeStart(self)
	end
end

function OutputInterface:onAfterStop()
	if self.triggers.onAfterStop then
		log:info(self, "Executing trigger onAfterStop")
		self.triggers.onAfterStop(self)
	end
end

function OutputInterface:OnSummary(info)
	if self.triggers.OnSummary then
		self.triggers.OnSummary(self, info)
	end
end
