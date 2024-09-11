local API = {}; ImmersionAPI = API;
-- Version
local IS_CLASSIC = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC 
local IS_RETAIL  = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

function API:IsClassic(...) return IS_CLASSIC end
function API:IsRetail(...)  return IS_RETAIL  end

API.ITERATORS = {
	GOSSIP    = IS_CLASSIC and 2 or IS_RETAIL and 2;
	ACTIVE    = IS_CLASSIC and 4 or IS_RETAIL and 4;
	AVAILABLE = IS_CLASSIC and 5 or IS_RETAIL and 6;
}

-- Chunk iterators
function API:GetGossipOptionIterator(...)   return self.ITERATORS.GOSSIP    end
function API:GetActiveQuestIterator(...)    return self.ITERATORS.ACTIVE    end
function API:GetAvailableQuestIterator(...) return self.ITERATORS.AVAILABLE end

-- Map select to table values
local function map(lambda, step, ...)
	local data = {}
	for i = 1, select('#', ...), step do
		data[#data + 1] = lambda(nil, i, ceil(i / step), ...)
	end
	return data
end

function API:MapGossipAvailableQuests(i, idx, ...)
	local title, level, trivial, frequency, repeatable = select(i, ...)
	return {
		title       = title,
		questLevel  = level,
		isTrivial   = trivial,
		frequency   = frequency,
		repeatable  = repeatable,
	}
end

function API:MapGossipActiveQuests(i, idx, ...)
	local title, level, trivial, complete = select(i, ...)
	return {
		title       = title,
		questLevel  = level,
		isTrivial   = trivial,
		isComplete  = complete,
	}
end

function API:MapGossipOptions(i, idx, ...)
	local name, icon = select(i, ...)
	return {
		name           = name,
		type           = icon,
		gossipOptionID = idx,
	}
end

-- Quest pickup API
function API:CloseQuest(onQuestClosed, ...)
	if onQuestClosed and IS_WOW10 then return end;
	return CloseQuest and CloseQuest(...)
end

function API:GetGreetingText(...)
	return GetGreetingText and GetGreetingText(...)
end

function API:GetTitleText(...)
	return GetTitleText and GetTitleText(...)
end

function API:GetProgressText(...)
	return GetProgressText and GetProgressText(...)
end

function API:GetRewardText(...)
	return GetRewardText and GetRewardText(...)
end

function API:GetQuestText(...)
	return GetQuestText and GetQuestText(...)
end

function API:QuestGetAutoAccept(...)
	return QuestGetAutoAccept and QuestGetAutoAccept(...)
end

function API:QuestIsFromAdventureMap(...)
	return QuestIsFromAdventureMap and QuestIsFromAdventureMap(...)
end

function API:QuestIsFromAreaTrigger(...)
	return QuestIsFromAreaTrigger and QuestIsFromAreaTrigger(...)
end

function API:QuestFlagsPVP(...)
	return QuestFlagsPVP and QuestFlagsPVP(...)
end

function API:GetQuestIconOffer(quest)
	if QuestUtil and QuestUtil.GetQuestIconOffer then
		return QuestUtil.GetQuestIconOffer(
			quest.isLegendary,
			quest.frequency,
			quest.repeatable,
			QuestUtil.ShouldQuestIconsUseCampaignAppearance(quest.questID)
		)
	end
	local icon =
		( quest.isLegendary and 'AvailableLegendaryQuestIcon') or
		( quest.frequency and quest.frequency > 1 and 'DailyQuestIcon') or
		( quest.repeatable and 'DailyActiveQuestIcon') or
		( 'AvailableQuestIcon' )
	return ([[Interface\GossipFrame\%s]]):format(icon)
end

function API:GetQuestIconActive(quest)
	if QuestUtil and QuestUtil.GetQuestIconActive then
		return QuestUtil.GetQuestIconActive(
			quest.isComplete,
			quest.isLegendary,
			quest.frequency,
			quest.repeatable,
			QuestUtil.ShouldQuestIconsUseCampaignAppearance(quest.questID)
		)
	end
	local icon =
		( quest.isComplete ) and (
			( quest.isLegendary and  'ActiveLegendaryQuestIcon') or
			( quest.isComplete and 'ActiveQuestIcon')
		) or ( 'InCompleteQuestIcon' )
	return ([[Interface\GossipFrame\%s]]):format(icon)
end

-- Quest content API
function API:GetSuggestedGroupNum(...)
	return GetSuggestedGroupNum and GetSuggestedGroupNum(...) or 0
end

function API:GetNumQuestRewards(...)
	return GetNumQuestRewards and GetNumQuestRewards(...) or 0
end

function API:GetNumQuestChoices(...)
	return GetNumQuestChoices and GetNumQuestChoices(...) or 0
end

function API:GetNumRewardCurrencies(...)
	return GetNumRewardCurrencies and GetNumRewardCurrencies(...) or 0
end

function API:GetRewardMoney(...)
	return GetRewardMoney and GetRewardMoney(...) or 0
end

function API:GetRewardSkillPoints(...)
	return GetRewardSkillPoints and GetRewardSkillPoints(...) or 0
end

function API:GetRewardXP(...)
	return GetRewardXP and GetRewardXP(...) or 0
end

function API:GetRewardArtifactXP(...)
	return GetRewardArtifactXP and GetRewardArtifactXP(...) or 0
end

function API:GetRewardHonor(...)
	return GetRewardHonor and GetRewardHonor(...) or 0
end

function API:GetRewardTitle(...)
	return GetRewardTitle and GetRewardTitle(...)
end

function API:GetNumRewardSpells(...)
	return GetNumRewardSpells and GetNumRewardSpells(...) or 0
end

function API:GetMaxRewardCurrencies(...)
	return GetMaxRewardCurrencies and GetMaxRewardCurrencies(...) or 0
end

function API:GetNumQuestItems(...)
	return GetNumQuestItems and GetNumQuestItems(...) or 0
end

function API:GetQuestMoneyToGet(...)
	return GetQuestMoneyToGet and GetQuestMoneyToGet(...) or 0
end

function API:GetNumQuestCurrencies(...)
	return GetNumQuestCurrencies and GetNumQuestCurrencies(...) or 0
end

function API:GetSuperTrackedQuestID(...)
	return C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID(...)
end

function API:GetAvailableQuestInfo(...)
	if GetAvailableQuestInfo then
		return GetAvailableQuestInfo(...)
	end
	return IsAvailableQuestTrivial(...)
end

function API:IsActiveQuestLegendary(...)
	return IsActiveQuestLegendary and IsActiveQuestLegendary(...)
end

function API:IsQuestCompletable(...)
	return IsQuestCompletable and IsQuestCompletable(...)
end

-- Gossip API
function API:CloseGossip(onGossipClosed, ...)
	if onGossipClosed and IS_WOW10 then return end;
	return (C_GossipInfo and C_GossipInfo.CloseGossip or CloseGossip)(...)
end

function API:ForceGossip(...)
	if ForceGossip then return ForceGossip(...) end
	return C_GossipInfo.ForceGossip(...)
end

function API:CanAutoSelectGossip(dontAutoSelect)
	local gossip, option = self:GetGossipOptions()
	if ( #gossip > 0 ) then
		local firstOption = gossip[1];
		option = firstOption.selectOptionWhenOnlyOption and firstOption.gossipOptionID;
		option = option or (firstOption.type and firstOption.type:lower() ~= 'gossip' and 1)
	end
	if option then
		if not dontAutoSelect then
			self:SelectGossipOption(option)
		end
		return true
	end
end

function API:GetGossipText(...)
	if GetGossipText then return GetGossipText(...) end
	return C_GossipInfo.GetText()
end

function API:GetNumGossipAvailableQuests(...)
	if GetNumGossipAvailableQuests then return GetNumGossipAvailableQuests(...) end
	return C_GossipInfo.GetNumAvailableQuests(...)
end

function API:GetNumGossipActiveQuests(...)
	if GetNumGossipActiveQuests then return GetNumGossipActiveQuests(...) end
	return C_GossipInfo.GetNumActiveQuests(...)
end

function API:GetNumGossipOptions(...)
	return (GetNumGossipOptions or 
		C_GossipInfo and C_GossipInfo.GetNumOptions or
		C_GossipInfo and C_GossipInfo.GetOptions and
		function() return #C_GossipInfo.GetOptions() end)(...)
end

function API:GetGossipAvailableQuests(...)
	if GetGossipAvailableQuests then
		return map(
			API.MapGossipAvailableQuests,
			API:GetAvailableQuestIterator(),
			GetGossipAvailableQuests(...)
		)
	end
	return C_GossipInfo.GetAvailableQuests(...)
end

function API:GetGossipActiveQuests(...)
	if GetGossipActiveQuests then
		return map(
			API.MapGossipActiveQuests,
			API:GetActiveQuestIterator(),
			GetGossipActiveQuests(...)
		)
	end
	return C_GossipInfo.GetActiveQuests(...)
end

function API:GetGossipOptions(...)
	if GetGossipOptions then
		return map(
			API.MapGossipOptions,
			API:GetGossipOptionIterator(),
			GetGossipOptions(...)
		)
	end
	return C_GossipInfo.GetOptions(...)
end

-- Quest greeting API
function API:GetNumActiveQuests(...)
	return GetNumActiveQuests and GetNumActiveQuests(...) or 0
end

function API:GetNumAvailableQuests(...)
	return GetNumAvailableQuests and GetNumAvailableQuests(...) or 0
end

-- Gossip/quest selectors API
function API:SelectActiveQuest(...)
	if SelectActiveQuest then
		return SelectActiveQuest(...)
	end
end

function API:SelectAvailableQuest(...)
	if SelectAvailableQuest then
		return SelectAvailableQuest(...)
	end
end

function API:SelectGossipOption(...)
	return (C_GossipInfo and C_GossipInfo.SelectOption or SelectGossipOption)(...)
end

function API:SelectGossipActiveQuest(...)
	return (C_GossipInfo and C_GossipInfo.SelectActiveQuest or SelectGossipActiveQuest)(...)
end

function API:SelectGossipAvailableQuest(...)
	return (C_GossipInfo and C_GossipInfo.SelectAvailableQuest or SelectGossipAvailableQuest)(...)
end

-- Misc
function API:GetUnitName(...)
	return GetUnitName and GetUnitName(...)
end

function API:GetPortraitAtlas()
	if GetAtlasInfo and GetAtlasInfo('TalkingHeads-PortraitFrame') then
		return 'TalkingHeads-PortraitFrame';
	end
	return 'TalkingHeads-Alliance-PortraitFrame';
end

function API:IsAzeriteItem(...)
	if C_AzeriteEmpoweredItem then
		return 	C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(...) and
				C_AzeriteEmpoweredItem.IsAzeritePreviewSourceDisplayable(...)
	end
end

function API:IsCharacterNewlyBoosted(...)
	return IsCharacterNewlyBoosted and IsCharacterNewlyBoosted(...)
end

function API:IsFollowerCollected(...)
	return C_Garrison and C_Garrison.IsFollowerCollected(...)
end

function API:GetNamePlateForUnit(...)
	return C_NamePlate and C_NamePlate.GetNamePlateForUnit(...)
end

function API:GetCreatureID(unit)
	local guid = unit and UnitGUID(unit)
	return guid and tonumber(guid:sub(7, 7 + 6 - 1), 16)
end

function API:CloseItemText(...)
	if CloseItemText then return CloseItemText(...) end
end

function API:GetQuestDetailsTheme(...)
	if C_QuestLog and C_QuestLog.GetQuestDetailsTheme then
		return C_QuestLog.GetQuestDetailsTheme(...)
	end
end

function API:GetQuestItemInfoLootType(...)
	if GetQuestItemInfoLootType then
		return GetQuestItemInfoLootType(...)
	end
end

-- Interaction manager, events from PlayerInteractionFrameManager.lua
local CloseOnInteractionTypes = Enum and Enum.PlayerInteractionType and {
	[Enum.PlayerInteractionType.AdventureJournal] = true;
	[Enum.PlayerInteractionType.AlliedRaceDetailsGiver] = true;
	[Enum.PlayerInteractionType.Auctioneer] = true;
	[Enum.PlayerInteractionType.AzeriteForge] = true;
	[Enum.PlayerInteractionType.AzeriteRespec] = true;
	[Enum.PlayerInteractionType.Banker] = true;
	[Enum.PlayerInteractionType.BlackMarketAuctioneer] = true;
	[Enum.PlayerInteractionType.ChromieTime] = true;
	[Enum.PlayerInteractionType.ContributionCollector] = true;
	[Enum.PlayerInteractionType.CovenantSanctum] = true;
	[Enum.PlayerInteractionType.GarrArchitect] = true;
	[Enum.PlayerInteractionType.GarrMission] = true;
	[Enum.PlayerInteractionType.GuildBanker] = true;
	[Enum.PlayerInteractionType.IslandQueue] = true;
	[Enum.PlayerInteractionType.ItemInteraction] = true;
	[Enum.PlayerInteractionType.ItemUpgrade] = true;
	[Enum.PlayerInteractionType.MailInfo] = true;
	[Enum.PlayerInteractionType.MajorFactionRenown] = true;
	[Enum.PlayerInteractionType.Merchant] = true;
	[Enum.PlayerInteractionType.ObliterumForge] = true;
	[Enum.PlayerInteractionType.Registrar] = true;
	[Enum.PlayerInteractionType.Renown] = true;
	[Enum.PlayerInteractionType.ScrappingMachine] = true;
	[Enum.PlayerInteractionType.Soulbind] = true;
	[Enum.PlayerInteractionType.TabardVendor] = true;
	[Enum.PlayerInteractionType.TaxiNode] = true;
	[Enum.PlayerInteractionType.Trainer] = true;
	[Enum.PlayerInteractionType.Transmogrifier] = true;
	[Enum.PlayerInteractionType.Trophy] = true;
	[Enum.PlayerInteractionType.VoidStorageBanker] = true;
	[Enum.PlayerInteractionType.WeeklyRewards] = true;
	[Enum.PlayerInteractionType.WorldMap] = true;
} or {};

function API:ShouldCloseOnInteraction(type)
	return CloseOnInteractionTypes[type];
end

function API:GetQuestID()
	return 0; -- not yet implemented.
end

-- Mixin Implementation

function API.Mixin(object, ...)
	for i = 1, select("#", ...) do
		local mixin = select(i, ...);
		for k, v in pairs(mixin) do
			object[k] = v;
		end
	end

	return object;
end

function API.CreateFromMixins(...)
	return API.Mixin({}, ...)
end 

-- Object and Frame Pool

local ObjectPoolMixin = {};

function ObjectPoolMixin:OnLoad(creationFunc, resetterFunc)
	self.creationFunc = creationFunc;
	self.resetterFunc = resetterFunc;

	self.activeObjects = {};
	self.inactiveObjects = {};

	self.numActiveObjects = 0;
end

function ObjectPoolMixin:Acquire()
	local numInactiveObjects = #self.inactiveObjects;
	if numInactiveObjects > 0 then
		local obj = self.inactiveObjects[numInactiveObjects];
		self.activeObjects[obj] = true;
		self.numActiveObjects = self.numActiveObjects + 1;
		self.inactiveObjects[numInactiveObjects] = nil;
		return obj, false;
	end

	local newObj = self.creationFunc(self);
	if self.resetterFunc then
		self.resetterFunc(self, newObj);
	end
	self.activeObjects[newObj] = true;
	self.numActiveObjects = self.numActiveObjects + 1;
	return newObj, true;
end

function ObjectPoolMixin:Release(obj)
	if self:IsActive(obj) then
		self.inactiveObjects[#self.inactiveObjects + 1] = obj;
		self.activeObjects[obj] = nil;
		self.numActiveObjects = self.numActiveObjects - 1;
		if self.resetterFunc then
			self.resetterFunc(self, obj);
		end

		return true;
	end

	return false;
end

function ObjectPoolMixin:ReleaseAll()
	for obj in pairs(self.activeObjects) do
		self:Release(obj);
	end
end

function ObjectPoolMixin:EnumerateActive()
	return pairs(self.activeObjects);
end

function ObjectPoolMixin:GetNextActive(current)
	return (next(self.activeObjects, current));
end

function ObjectPoolMixin:IsActive(object)
	return (self.activeObjects[object] ~= nil);
end

function ObjectPoolMixin:GetNumActive()
	return self.numActiveObjects;
end

function ObjectPoolMixin:EnumerateInactive()
	return ipairs(self.inactiveObjects);
end

function API.CreateObjectPool(creationFunc, resetterFunc)
	local objectPool = API.CreateFromMixins(ObjectPoolMixin);
	objectPool:OnLoad(creationFunc, resetterFunc);
	return objectPool;
end

local FramePoolMixin = API.CreateFromMixins(ObjectPoolMixin);

local function FramePoolFactory(framePool)
	return CreateFrame(framePool.frameType, nil, framePool.parent, framePool.frameTemplate);
end

function FramePoolMixin:OnLoad(frameType, parent, frameTemplate, resetterFunc)
	ObjectPoolMixin.OnLoad(self, FramePoolFactory, resetterFunc);
	self.frameType = frameType;
	self.parent = parent;
	self.frameTemplate = frameTemplate;
end

function FramePoolMixin:GetTemplate()
	return self.frameTemplate;
end

local function FramePool_Hide(framePool, frame)
	frame:Hide();
end

local function FramePool_HideAndClearAnchors(framePool, frame)
	frame:Hide();
	frame:ClearAllPoints();
end

function API.CreateFramePool(frameType, parent, frameTemplate, resetterFunc)
	local framePool = API.CreateFromMixins(FramePoolMixin);
	framePool:OnLoad(frameType, parent, frameTemplate, resetterFunc or FramePool_HideAndClearAnchors);
	return framePool;
end

local TexturePoolMixin = API.CreateFromMixins(ObjectPoolMixin);

local function TexturePoolFactory(texturePool)
	return texturePool.parent:CreateTexture(nil, texturePool.layer, texturePool.textureTemplate, texturePool.subLayer);
end

function TexturePoolMixin:OnLoad(parent, layer, subLayer, textureTemplate, resetterFunc)
	ObjectPoolMixin.OnLoad(self, TexturePoolFactory, resetterFunc);
	self.parent = parent;
	self.layer = layer;
	self.subLayer = subLayer;
	self.textureTemplate = textureTemplate;
end

local TexturePool_Hide = FramePool_Hide;
local TexturePool_HideAndClearAnchors = FramePool_HideAndClearAnchors;

function API.CreateTexturePool(parent, layer, subLayer, textureTemplate, resetterFunc)
	local texturePool = API.CreateFromMixins(TexturePoolMixin);
	texturePool:OnLoad(parent, layer, subLayer, textureTemplate, resetterFunc or TexturePool_HideAndClearAnchors);
	return texturePool;
end

local FontStringPoolMixin = API.CreateFromMixins(ObjectPoolMixin);

local function FontStringPoolFactory(fontStringPool)
	return fontStringPool.parent:CreateFontString(nil, fontStringPool.layer, fontStringPool.fontStringTemplate, fontStringPool.subLayer);
end

function FontStringPoolMixin:OnLoad(parent, layer, subLayer, fontStringTemplate, resetterFunc)
	ObjectPoolMixin.OnLoad(self, FontStringPoolFactory, resetterFunc);
	self.parent = parent;
	self.layer = layer;
	self.subLayer = subLayer;
	self.fontStringTemplate = fontStringTemplate;
end

local FontStringPool_Hide = FramePool_Hide;
local FontStringPool_HideAndClearAnchors = FramePool_HideAndClearAnchors;

function API.CreateFontStringPool(parent, layer, subLayer, fontStringTemplate, resetterFunc)
	local fontStringPool = API.CreateFromMixins(FontStringPoolMixin);
	fontStringPool:OnLoad(parent, layer, subLayer, fontStringTemplate, resetterFunc or FontStringPool_HideAndClearAnchors);
	return fontStringPool;
end

-- CTime After function replacement
local IM_TimerAfterFrame = nil
local IM_TimerAfterTable = {};

function API.TimerAfter(delay, func, ...)
	if(type(delay)~="number" or type(func)~="function") then
	  return false;
	end
	if (IM_TimerAfterFrame == nil) then
	  IM_TimerAfterFrame = CreateFrame("Frame","IM_TimerAfterFrame", UIParent);
	  IM_TimerAfterFrame:SetScript("onUpdate",function (self,elapse)
		local count = #IM_TimerAfterTable;
		local i = 1;
		while(i<=count) do
		  local waitRecord = tremove(IM_TimerAfterTable,i);
		  local d = tremove(waitRecord,1);
		  local f = tremove(waitRecord,1);
		  local p = tremove(waitRecord,1);
		  if(d>elapse) then
			tinsert(IM_TimerAfterTable,i,{d-elapse,f,p});
			i = i + 1;
		  else
			count = count - 1;
			f(unpack(p));
		  end
		end
	  end);
	end
	tinsert(IM_TimerAfterTable,{delay,func,{...}});
	return true;
end 
  
-- Convenience functions

function API.SetShown(frame, boolean)
  if(boolean) then
    frame:Show()
  else
    frame:Hide()
  end -- lol
end


function API.SetEnabled(button, boolean)
  if (boolean) then
    button:Enable()
  else
    button:Disable()
  end
end

-- SetAtlas?

local CP_Atlases = {
["groupfinder-button-cover"]={"Interface\\AddOns\\ConsolePort\\Textures\\Button\\Buttons.BLP", 300, 46, 0.000976562, 0.293945, 0.331055, 0.375977, false, false},
["adventureguide-microbutton-alert"]={"Interface\\AddOns\\BlizzCompat\\Compat\\BlizzardUI\\AdventureGuideMicrobuttonAlert.BLP", 28, 28, 0.03125, 0.90625, 0.03125, 0.90625, false, false},
}; 
function API.SetAtlas(TextureObject, atlas)
	if(CP_Atlases[atlas]) then
		local c_atlas = CP_Atlases[atlas];
		TextureObject:SetTexture(c_atlas[1]);
		TextureObject:SetSize(c_atlas[2], c_atlas[3]);
		TextureObject:SetTexCoord(c_atlas[4],c_atlas[5],c_atlas[6], c_atlas[7]);
	end 
end
 
API.SOUNDKIT = { 
    IG_QUEST_LIST_OPEN = 875,
    IG_QUEST_LIST_CLOSE = 876,
    IG_QUEST_LIST_SELECT = 877,
    IG_QUEST_LIST_COMPLETE = 878,
    IG_QUEST_CANCEL = 879
};