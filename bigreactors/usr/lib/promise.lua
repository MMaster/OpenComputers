local uuid = require("uuid")
local oop = require("oop")
local event = require("event")

-- Workaround for a bug in OpenOS 1.7.1 on Lua 5.3 mode.
-- Hopefully this will be removed some day...
_G.bit32 = require("bit32")

local promise = {
	uuid_ = nil,
	onCompletionCallbacks_ = {},
	onFailureCallbacks_ = {},
	onFinallyCallbacks_ = {},
	retvalCompleted_ = nil,
	retvalFailed_ = nil,
	thread_ = nil,
	running_ = false
}
oop.make(promise)

function promise:construct(taskProc, ...)
	self.uuid_ = uuid.next()
	self.running_ = true
	self:launchWorker(taskProc, ...)
end

-- Private methods

function promise:launchWorker(taskProc, ...)
	local this = self
	local args = table.pack(...)

	self.thread_ = event.timer(0, function()
		this:workerProc(taskProc, table.unpack(args))
	end, 1)
	--thread.create(promise.workerProc, self, taskProc, ...)
end

function promise:workerProc(taskProc, ...)
	local retval = table.pack(xpcall(taskProc, function(...)
		self.retvalFailed_ = table.pack(...)
		self:onFailure(...)
	end, ...))

	-- If retval[1] is false, then the error handler has already been called.
	if retval[1] then
		-- The first value is the success indicator from xpcall. Remove it!
		table.remove(retval, 1)
		self.retvalCompleted_ = retval
		self:onComplete(table.unpack(retval))
	end
end

function promise:onComplete(...)
	if #self.onCompletionCallbacks_ == 0 then
		self:onFinally()
	else
		local next_task = table.remove(self.onCompletionCallbacks_, 1)
		self:launchWorker(next_task, ...)
	end
end

function promise:onFailure(...)
	for _, callback in pairs(self.onFailureCallbacks_) do
		xpcall(callback, function(...)
			io.stderr:write("[promise " .. self.uuid_ .. "] Error in failure handler\n" .. debug.traceback( ... ) .. "\n")
		end, ...)
	end

	if #self.onFailureCallbacks_ == 0 then
		io.stderr:write("[promise " .. self.uuid_ .. "] " .. debug.traceback( ... ) .. "\n")
	end

	self:onFinally()
end

function promise:onFinally()
	for _, callback in pairs(self.onFinallyCallbacks_) do
		xpcall(callback, function(...)
			io.stderr:write("[promise " .. self.uuid_ .. "] Error in finally handler\n" .. debug.traceback( ... ) .. "\n")
		end)
	end
	self.running_ = false
end

-- Public methods

function promise:after(callback, ...)
	checkArg(1, callback, "function")

	local args = table.pack(...)

	if self.running_ then
		table.insert(self.onCompletionCallbacks_, function(...)
			if #args > 0 then
				return callback(table.unpack(args), ...)
			else
				return callback(...)
			end
		end)
	elseif self.retvalCompleted_ == nil then
		-- Guess we failed...
	elseif #args > 0 then
		self:launchWorker(callback, ..., table.unpack(self.retvalCompleted_))
	else
		self:launchWorker(callback, table.unpack(self.retvalCompleted_))
	end

	return self
end

function promise:catch(callback, ...)
	checkArg(1, callback, "function")

	local this = self
	local args = table.pack(...)

	if self.retvalFailed_ == nil then
		table.insert(self.onFailureCallbacks_, function(...)
			if #args > 0 then
				return callback(table.unpack(args), ...)
			else
				return callback(...)
			end
		end)
	elseif #args > 0 then
		xpcall(callback, function(...)
			io.stderr:write("[promise " .. this.uuid_ .. "] Error in failure handler\n" .. debug.traceback( ... ) .. "\n")
		end, ..., table.unpack(self.retvalFailed_))
	else
		xpcall(callback, function(...)
			io.stderr:write("[promise " .. this.uuid_ .. "] Error in failure handler\n" .. debug.traceback( ... ) .. "\n")
		end, table.unpack(self.retvalFailed_))
	end

	return self
end

function promise:finally(callback, ...)
	checkArg(1, callback, "function")

	local this = self
	local args = table.pack(...)

	if self.retvalCompleted_ == nil and self.retvalFailed_ == nil then
		table.insert(self.onFinallyCallbacks_, function()
			return callback(table.unpack(args))
		end)
	else
		xpcall(callback, function(...)
			io.stderr:write("[promise " .. this.uuid_ .. "] Error in finally handler\n" .. debug.traceback( ... ) .. "\n")
		end, ...)
	end

	return self
end

function promise:wait()
	while self.running_ and self.thread_ ~= nil do
		os.sleep(0.05)
	end
end

return promise
