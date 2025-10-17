
-- Behavior tree logic for bots

runfile "/bots/globals.lua"

BTree = {}

function BTree.Create(object)
	local self = ShallowCopy(BTree, object)

	self.state = nil
	self.statefn = nil
	self.statefnname = nil
	self.deadstate = nil

	return self
end

function BTree:onthink()
	if self.statefn ~= nil and coroutine.status(self.statefn) == "dead" then
		self.deadstate = self.state
		self.state = nil
		self.statefn = nil
		self.statefnname = nil
	end

	local state, fn = self:ChooseState("Root")
	if self.state ~= state then
		if self.state ~= nil then
			self:LeaveState(self.state, state)
		elseif self.deadstate ~= nil then
			self:LeaveState(self.deadstate, state)
		end
		self.deadstate = nil
		self.state = state
		self.statefnname = fn
		self.statefn = coroutine.create(fn)
	end

	local ok, message = coroutine.resume(self.statefn, self)
	if not ok then
		Echo(message)
	end
end

function BTree:ChooseState(node, state)
	if state == nil then
		state = node
	else
		state = state..":"..node
	end

	fn = self["State_" .. node]
	if fn ~= nil and type(fn) == 'function' then
		return state, fn
	end

	fn = self["Choose_" .. node]
	if fn ~= nil and type(fn) == 'function' then
		nextNode = fn(self)
		local state, fn = self:ChooseState(nextNode, state) -- Store result so its included in profiling of this function
		return state, fn
	end

	Echo("Error, undefined BTree state:  " .. state)
end

function BTree:LeaveState(oldstate, newstate)
	oldnodes = Game.ExplodeString(oldstate, ":")
	newnodes = Game.ExplodeString(newstate, ":")

	local diverge = false
	for index,oldnode in ipairs(oldnodes) do
		local newnode = newnodes[index]
		if newnode == nil then
			return
		end

		if diverge or oldnode ~= newnode then
			diverge = true
			fn = self["Leave_" .. oldnode]
			if fn ~= nil and type(fn) == 'function' then
				fn(self)
			end
		end
	end
end
