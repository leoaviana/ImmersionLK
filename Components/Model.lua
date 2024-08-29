local Model, GetTime, API, _, L, ani, m2 = {}, GetTime, ImmersionAPI, ...
L.ModelMixin = Model

----------------------------------
-- Animation wrappers
----------------------------------
function Model:Read()  self:SetAnimation(self.ani.reading) end
function Model:Ask()   self:SetAnimation(self.ani.asking) end
function Model:Yell()  self:SetAnimation(self.ani.yelling) end
function Model:Talk()  self:SetAnimation(self.ani.talking) end
function Model:Reset() self:SetAnimation(0) end

function Model:RunNextAnimation() if
	self.reading then self:Read() elseif
	self.asking  then self:Ask() elseif
	self.yelling then self:Yell() elseif
	self.talking then self:Talk() else
	self:Reset() end 
end 


local Started = false 
local RunTime = 2000
local Seqtime = 0 

local varieibol

local function RunAnimation(self, elapsed)
	Seqtime = Seqtime + (elapsed * 1000)
	if Seqtime > RunTime then 
		self:SetScript("OnUpdate", nil)
		Started = false
		return  
	end  
	
	self:SetSequenceTime(self.animation, Seqtime)
end

function Model:StopAll()
	self:SetScript("OnUpdate", nil)
	Started = false
	Seqtime = 0
end

function Model:SetAnimation(...)
	self.animation = ...
	self.animstart = GetTime()
 
	--getmetatable(self).__index.SetSequence(self, ...) 

	if(type(self:GetModel()) == "table") or self.animation == 0 then return end  

	if(Model.AnimReplacementWorkaround[self:GetModel()]) then  
		if(... == self.ani.talking) then
			if(Model.AnimReplacementWorkaround[self:GetModel()]["talk"]) then
				if(Model.AnimReplacementWorkaround[self:GetModel()]["talk"] ~= "") then
					self.animation = tonumber(Model.AnimReplacementWorkaround[self:GetModel()]["talk"]);
				end
			end					
		elseif(... == self.ani.yelling) then
			if(Model.AnimReplacementWorkaround[self:GetModel()]["yell"]) then
				if(Model.AnimReplacementWorkaround[self:GetModel()]["yell"] ~= "") then
					self.animation = tonumber(Model.AnimReplacementWorkaround[self:GetModel()]["yell"]);
				end
			end
		elseif(... == self.ani.asking) then
			if(Model.AnimReplacementWorkaround[self:GetModel()]["ask"]) then
				if(Model.AnimReplacementWorkaround[self:GetModel()]["ask"] ~= "") then
					self.animation = tonumber(Model.AnimReplacementWorkaround[self:GetModel()]["ask"]);
				end
			end
		elseif(... == self.ani.reading) then
			if(Model.AnimReplacementWorkaround[self:GetModel()]["read"]) then
				if(Model.AnimReplacementWorkaround[self:GetModel()]["read"] ~= "") then
					self.animation = tonumber(Model.AnimReplacementWorkaround[self:GetModel()]["read"]);
				end
			end
		end  
	end 


	if(not Started == true) then 
		Seqtime = 0  
		self:SetScript("OnUpdate", nil) 
		Started = false
	end 

	Seqtime = 0
	self:SetScript("OnUpdate", RunAnimation) 
	Started = true
end

----------------------------------
-- Unit stuff
----------------------------------
function Model:IsPlayer() return self.unit == 'player' end
function Model:IsNPC()    return self.unit == 'npc' or self.unit == 'questnpc' end
function Model:IsEther()  return self.unit == 'ether' end
function Model:GetUnit()  return self.unit end

function Model:GetCreature()
	return self.creatureID or API:GetCreatureID(self.unit)
end

function Model:SetUnit(unit)
	self.unitDirty = unit
	if self:IsVisible() then
		self:ClearModel()
		self:MarkDefectModel(false)
		self:ApplyModelFromUnit(unit)
	end
end

function Model:MarkDefectModel(enabled)
	self.defectmodel = enabled
end

function Model:IsDefectModel()
	return self.defectmodel
end

function Model:ApplyModelFromUnit(unit) 
	if self.file[unit] then unit = "player" end
		--self:SetModel(self.file[unit])
		--self:SetCamDistanceScale(.4)
		--self:SetPortraitZoom(0)
		--self:SetPosition(0, 0, .25)
		--self.unit = 'ether' 
--	else
	local mt = getmetatable(self).__index	
	local creatureID = tonumber(unit) and tonumber(unit) or unit ~= 'player' and API:GetCreatureID(unit) or nil
	local apply = creatureID and mt.SetCreature or unit and mt.SetUnit 
	--self:SetCamDistanceScale(1) 
	--self:SetPortraitZoom(.85)
	self:SetPosition(0, 0, 0)
	if apply then 
		apply(self, creatureID or unit)
		self.creatureID = creatureID
		self.unit = tonumber(unit) and 'npc' or unit
	end
--	end  

	-- apply face camera workarounds if available/needed
	if(Model.AnimCameraWorkaround[self:GetModel()]) then
		if(Model.AnimCameraWorkaround[self:GetModel()]["nofacecamera"]) then
			local cameraworkaround = L.splitstr(Model.AnimCameraWorkaround[self:GetModel()]["camerapos"], ',');
			local camwrkX = tonumber(cameraworkaround[1]);
			local camwrkY = tonumber(cameraworkaround[2]);
			local camwrkZ = tonumber(cameraworkaround[3]);

			self:SetPosition(camwrkX,camwrkY,camwrkZ)
		else
			self:SetCamera(0);
		end
	else
		self:SetCamera(0);
	end 
end

----------------------------------
-- Calculate state and remaining time
----------------------------------
function Model:SetRemainingTime(start, remaining)
	self.timestamp = start or GetTime()
	self.delay = remaining or 0 
end

function Model:GetRemainingTime(start, remaining)
	if start and remaining then
		local time = GetTime()
		local diff = time - start
		-- shave off a second to avoid awkwardly long animation sequences
		if diff < ( remaining  - 1 ) then
			return time, diff
		end
	end
end

function Model:IsPrematureFinish(start)
	if start then
		local difference = GetTime() - start
		return difference < self.premature, difference
	end
end

function Model:PrepareAnimation(text, isEmote, isSequence)
	-- if no unit/text or if the text is a description rather than spoken words
	if ( not self.unit or not text ) or ( isEmote ) then
		for state in pairs(self.ani) do
			self[state] = nil
		end
	else
		self.reading = self.unit:match('player') and true
		if not self.reading then
			self.asking  = text:match('?')
			self.yelling = text:match('!')
			self.talking = true
		end
	end
end

function Model:RunSequence(remainingTime, isSequence) 
	if self:IsNPC() then
		self:StopAll()
		if not L('disableanisequence') then 
			self:SetRemainingTime(GetTime(), remainingTime)
			if self.asking and not isSequence then
				self:Ask()
			elseif self.yelling then
				self:Randomize(self.ani.yelling)
			else
				self:Talk()
			end
		end
	elseif self:IsPlayer() then
		self:Read()
	end
end

function Model:Randomize(animation)
	local rand = random(2) == 2
	self:SetAnimation(rand and animation or self.ani.asking)
end

----------------------------------
-- Handler
---------------------------------- 

function Model:OnAnimFinished() 
	if self:IsDefectModel() then return end
	-----------------------------------
	local isPremature, difference = self:IsPrematureFinish(self.animstart)
	if isPremature then
		--self:MarkDefectModel(true)
		--self:Reset() 
		--return
	end 
	-----------------------------------
	if self:IsPlayer() then
		self:Read()
	else
		local newTime, difference = self:GetRemainingTime(self.timestamp, self.delay)
		if newTime and difference then 
			self:SetRemainingTime(newTime, ( self.delay - 1) - difference)
			self.talking = true
			if self.asking then
				self:Ask() 
			elseif self.yelling then
				self:Randomize(self.ani.yelling)
			else
				self:Talk() 
			end
		else
			self:SetRemainingTime(nil, nil)
			self:PrepareAnimation(nil, nil)
			--self:Reset()
		end
	end
end

function Model:OnShow() 
	self:ClearModel()
	if self.unitDirty then
		self:MarkDefectModel(false)
		self:ApplyModelFromUnit(self.unitDirty)
	end
end 
 
----------------------------------
-- Consts
----------------------------------

-- AnimReplacementWorkaround:
-- used on models which has a bugged talk,yell,ask,read animation OR no face camera on Model frame.
-- (blood elf female based skeleton has multiple talk anim for example and must be replaced to another animation
-- because unfortunately it glitches.)
-- beware that using custom patches that changes ingame models to hd models may also cause some problems related
-- to character face camera.

Model.AnimReplacementWorkaround = {
["character\\bloodelf\\female\\bloodelffemale.m2"] = {["talk"]="65",["yell"]="",["ask"]="",["read"]="" }, -- multiple talk animations, unexpected behavior on PlayerModel frame, replacing to ask instead
["creature\\alexstrasza\\ladyalexstrasa.m2"] = {["talk"]="65",["yell"]="",["ask"]="",["read"]="" }, -- multiple talk animations, unexpected behavior on PlayerModel frame, replacing to ask instead
["creature\\bloodqueen\\bloodqueen.m2"] = {["talk"]="65",["yell"]="",["ask"]="",["read"]="" }, -- multiple talk animations, unexpected behavior on PlayerModel frame, replacing to ask instead
["creature\\felelfcasterfemale\\felelfcasterfemale.m2"] = {["talk"]="65",["yell"]="",["ask"]="",["read"]="" }, -- multiple talk animations, unexpected behavior on PlayerModel frame, replacing to ask instead
["creature\\felelfhunterfemale\\felelfhunterfemale.m2"] = {["talk"]="65",["yell"]="",["ask"]="",["read"]="" }, -- multiple talk animations, unexpected behavior on PlayerModel frame, replacing to ask instead
["creature\\ladysylvanaswindrunner\\ladysylvanaswindrunner.m2"] = {["talk"]="65",["yell"]="",["ask"]="",["read"]="" }, -- multiple talk animations, unexpected behavior on PlayerModel frame, replacing to ask instead
}


-- AnimCameraWorkaround
-- this workaround applies on models which there is no face camera available, for example a model appears as
-- a distant body in the model frame, should not happen on original files, but may happen on mods such as 
-- HD models from WoD.

Model.AnimCameraWorkaround = {
["creature\\jaina\\jaina2.m2"] = {["nofacecamera"]="true", ["camerapos"]="2.2,0.3,0.1" }, -- no face camera on this model from a custom patch wod models
["creature\\thralldoomplate\\thrall.m2"] = {["nofacecamera"]="true", ["camerapos"]="4,0.0,-0.6" }, -- no face camera on this model from a custom patch wod models
}

Model.ani = {
	reading = 63,
	asking  = 65,
	yelling = 64,
	talking = 60,
}

Model.file = {
	AvailableQuest	= 'interface\\buttons\\talktome.m2',
	ActiveQuest		= 'interface\\buttons\\talktomequestionmark.m2',
	IncompleteQuest = 'interface\\buttons\\talktomequestion_grey.m2',
	GossipGossip	= 'interface\\buttons\\talktome_chat.m2',
}

Model.LightValues = {
	1, 	-- enabled
	0, 	-- omni
	-250,	-- dirX
	0,		-- dirY
	0,		-- dirZ
	0.25,	-- dirIntensity
	1,		-- ambR
	1,		-- ambG
	1,		-- ambB
	75,		-- ambIntensity
	1,		-- dirR
	1,		-- dirG
	1,		-- dirB
}

Model.premature = 0.5