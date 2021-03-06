-- part of lua-backup project
-- filesystem output

Output_scp = inheritsFrom(OutputInterface)

function Output_scp:new(config) 
	local inst = Output_scp:create()
	inst:init(config)
	return inst
end

function Output_scp:ssh(cmd) 	
	self.stats.connections = self.stats.connections + 1
	shell.WetStart("ssh", self.argdict, nil, self.destination, cmd)
end

function Output_scp:scp(localfile, remotefile) 	
	self.stats.connections = self.stats.connections + 1
	
	local data = {
		localfile,
		self.destination .. ":" .. remotefile,
	}
	
	shell.WetStart("scp", self.argdict, data)
end

function Output_scp:init(config) 
	self.name = "scp"
	self.stats = {
		count = 0,
		bytes = 0,
		connections = 0,
	}
	OutputInterface.init(self, config)
	
	self.argdict = {
		p = config.connection.port,
	}
	
	self.destination = config.connection.user .. "@" .. config.connection.host
	
	self:ssh("mkdir -p '" .. config.dir .. "'")
end

function Output_scp:processFile(file, islog)
	local outdir
	local outfile
	if self.config.dir then
		outdir = self.config.dir .. "/"
	else
		outdir = "./"
	end
			
	local index = file:find("/[^/]*$")
	local fname = file:sub(index+1)		
	local remotefile = outdir .. fname
		
	self:scp(file, remotefile)
	
	self.stats.count = self.stats.count + 1
	self.stats.bytes = self.stats.bytes + shell.fsize(file)
	
	return remotefile
end

function Output_scp:put(file)
	self:processFile(file, false)
end

function Output_scp:putLog(file)
	local remotef = self:processFile(file, true)
	OutputInterface.putLog(self, remotef)
end

function Output_scp:OnSummary(info)
	OutputInterface.OnSummary(self, info)
	log:info(self, "Total files copied: ", self.stats.count, " (", string.format("%.2f", self.stats.bytes / 1024 / 1024), " MiB); Connections made: ", self.stats.connections)
end
