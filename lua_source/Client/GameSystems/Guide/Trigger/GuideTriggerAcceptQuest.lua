-----------------------------------------------------
--File Name    : GuideTriggerAcceptQuest.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerAcceptQuest = luaclass("GuideTriggerAcceptQuest",GuideTrigger)

local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

--override
function GuideTriggerAcceptQuest:BindEvent(EventHelper)
    
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_ACCEPT_QUEST, self, self.OnRefreshQuest)
	local QuestComponent = GamePlayerSelfHelper:Get().QuestComponent
	if(QuestComponent ~= nil)then
		-- local tbAccept = QuestComponent.tbAlreadyAccepts
		local tbQuestId = self.tbTemplate.tbQuestId
		
		-- if(tbAccept[tbQuestId[1]] ~= nil and tbAccept[tbQuestId[1]][tbQuestId[2]] ~= nil)then
		if(QuestComponent:GetQuest(tbQuestId[1], tbQuestId[2]) ~= nil)then
			self:DebugLog("BindEvent,Trigger")
			self:Trigger()
		end
	end
	
end

function GuideTriggerAcceptQuest:OnRefreshQuest(nQuestId, nQuestSubId, nNewSubQuestID)
	
	local tbQuestId = self.tbTemplate.tbQuestId
	if(tbQuestId[1]== nQuestId and tbQuestId[2]== nNewSubQuestID)then
		self:DebugLog("OnRefreshQuest")
		self:Trigger()
	end
    
end

function GuideTriggerAcceptQuest:IsTrigger()
    local QuestComponent = GamePlayerSelfHelper:Get().QuestComponent
	local bIsTrigger = false
	if(QuestComponent ~= nil)then
		-- local tbAccept = QuestComponent.tbAlreadyAccepts
		local tbQuestId = self.tbTemplate.tbQuestId
		
		-- if(tbAccept[tbQuestId[1]] ~= nil and tbAccept[tbQuestId[1]][tbQuestId[2]] ~= nil)then
		if(QuestComponent:GetQuest(tbQuestId[1], tbQuestId[2]) ~= nil)then
			self:DebugLog("IsTrigger,Trigger")
			bIsTrigger = true
		end
	end
	self.bIsTrigger = bIsTrigger
	return self.bIsTrigger
end

return GuideTriggerAcceptQuest
