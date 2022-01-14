local tbl = require(script:WaitForChild("table"))

-----------------------------------------------------------
-------------------- MODULE DEFINITION --------------------
-----------------------------------------------------------

local PartCacheStatic = {}
PartCacheStatic.__index = PartCacheStatic
PartCacheStatic.__type = "PartCache" -- For compatibility with TypeMarshaller

-- TYPE DEFINITION: Part Cache Instance
export type PartCache = {
	Open: {[number]: Attachment},
	InUse: {[number]: Attachment},
	CurrentCacheParent: Instance,
	Template: Attachment,
	ExpansionSize: number
}

-----------------------------------------------------------
----------------------- STATIC DATA -----------------------
-----------------------------------------------------------					

-- A CFrame that's really far away. Ideally. You are free to change this as needed.
local CF_REALLY_FAR_AWAY = CFrame.new(0, 10e8, 0)

-- Format params: methodName, ctorName
local ERR_NOT_INSTANCE = "Cannot statically invoke method '%s' - It is an instance method. Call it on an instance of this class created via %s"

-- Format params: paramName, expectedType, actualType
local ERR_INVALID_TYPE = "Invalid type for parameter '%s' (Expected %s, got %s)"

-----------------------------------------------------------
------------------------ UTILITIES ------------------------
-----------------------------------------------------------

--Similar to assert but warns instead of errors.
local function assertwarn(requirement: boolean, messageIfNotMet: string)
	if requirement == false then
		warn(messageIfNotMet)
	end
end

--Dupes a part from the template.
local function MakeFromTemplate(template: Attachment, currentCacheParent: Instance): Attachment
	local attachment: Attachment = template:Clone()
	-- ^ Ignore W000 type mismatch between Instance and BasePart. False alert.
	
	attachment.CFrame = CF_REALLY_FAR_AWAY
	attachment.Parent = currentCacheParent
	return attachment
end

function PartCacheStatic.new(template: Attachment, numPrecreatedParts: number?, currentCacheParent: Instance?): PartCache
	local newNumPrecreatedParts: number = numPrecreatedParts or 5
	local newCurrentCacheParent: Instance = currentCacheParent or workspace.Terrain
	
	--PrecreatedParts value.
	--Same thing. Ensure it's a number, ensure it's not negative, warn if it's really huge or 0.
	assert(numPrecreatedParts > 0, "PrecreatedParts can not be negative!")
	assertwarn(numPrecreatedParts ~= 0, "PrecreatedParts is 0! This may have adverse effects when initially using the cache.")
	
	template = template:Clone()
	
	local object: PartCache = {
		Open = {},
		InUse = {},
		CurrentCacheParent = newCurrentCacheParent,
		Template = template,
		ExpansionSize = 10
	}
	setmetatable(object, PartCacheStatic)
	
	for _ = 1, newNumPrecreatedParts do
		tbl.insert(object.Open, MakeFromTemplate(template, object.CurrentCacheParent))
	end
	object.Template.Parent = nil
	
	return object
end

-- Gets a part from the cache, or creates one if no more are available.
function PartCacheStatic:GetPart(): Attachment
	assert(getmetatable(self) == PartCacheStatic, ERR_NOT_INSTANCE:format("GetPart", "PartCache.new"))
	
	if #self.Open == 0 then
		warn("No attachments available in the cache! Creating [" .. self.ExpansionSize .. "] new attachment instance(s) - this amount can be edited by changing the ExpansionSize property of the PartCache instance... (This cache now contains a grand total of " .. tostring(#self.Open + #self.InUse + self.ExpansionSize) .. " parts.)")
		for i = 1, self.ExpansionSize, 1 do
			tbl.insert(self.Open, MakeFromTemplate(self.Template, self.CurrentCacheParent))
		end
	end
	local attachment = self.Open[#self.Open]
	self.Open[#self.Open] = nil
	tbl.insert(self.InUse, attachment)
	return attachment
end

-- Returns a part to the cache.
function PartCacheStatic:ReturnPart(part: Attachment)
	assert(getmetatable(self) == PartCacheStatic, ERR_NOT_INSTANCE:format("ReturnPart", "PartCache.new"))
	
	local index = tbl.indexOf(self.InUse, part)
	if index ~= nil then
		tbl.remove(self.InUse, index)
		tbl.insert(self.Open, part)
	else
		error("Attempted to return part \"" .. part.Name .. "\" (" .. part:GetFullName() .. ") to the cache, but it's not in-use! Did you call this on the wrong part?")
	end
end

-- Sets the parent of all cached parts.
function PartCacheStatic:SetCacheParent(newParent: Instance)
	assert(getmetatable(self) == PartCacheStatic, ERR_NOT_INSTANCE:format("SetCacheParent", "PartCache.new"))
	assert(newParent:IsDescendantOf(workspace) or newParent == workspace, "Cache parent is not a descendant of Workspace! Parts should be kept where they will remain in the visible world.")
	
	self.CurrentCacheParent = newParent
	for i = 1, #self.Open do
		self.Open[i].Parent = newParent
	end
	for i = 1, #self.InUse do
		self.InUse[i].Parent = newParent
	end
end

-- Adds numParts more parts to the cache.
function PartCacheStatic:Expand(numParts: number): ()
	assert(getmetatable(self) == PartCacheStatic, ERR_NOT_INSTANCE:format("Expand", "PartCache.new"))
	if numParts == nil then
		numParts = self.ExpansionSize
	end
	
	for i = 1, numParts do
		tbl.insert(self.Open, MakeFromTemplate(self.Template, self.CurrentCacheParent))
	end
end

-- Destroys this cache entirely. Use this when you don't need this cache object anymore.
function PartCacheStatic:Dispose()
	assert(getmetatable(self) == PartCacheStatic, ERR_NOT_INSTANCE:format("Dispose", "PartCache.new"))
	for i = 1, #self.Open do
		self.Open[i]:Destroy()
	end
	for i = 1, #self.InUse do
		self.InUse[i]:Destroy()
	end
	self.Template:Destroy()
	self.Open = {}
	self.InUse = {}
	self.CurrentCacheParent = nil
	
	self.GetPart = nil
	self.ReturnPart = nil
	self.SetCacheParent = nil
	self.Expand = nil
	self.Dispose = nil
end

return PartCacheStatic