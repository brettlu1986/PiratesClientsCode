-----------------------------------------------------
--File Name    : GuideTriggerTaskShow.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerTaskShow = luaclass("GuideTriggerTaskShow",GuideTrigger)

local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")


--override
function GuideTriggerTaskShow:Begin()
    GuideTriggerTaskShow.super.Begin(self)
    self:OnTaskShow(nil)
end

function GuideTriggerTaskShow:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_TASK_SHOW, self, self.OnTaskShow)
end

function GuideTriggerTaskShow:OnTaskShow(tbQuestId)
    local MainWnd = UIManager:GetWnd(UIDef.UI_MAIN)
    if(MainWnd == nil)then
        return
    end
    local LeftTaskWidget = MainWnd.pWidgetRef.pbMainLeftPanel.pbMainLeftTask
    if(not LeftTaskWidget:IsVisible())then
        return
    end
    -- logdebug("GuideTriggerTaskShow:OnTaskShow1,ngroup="..self.tbGuideTemplate.nGroup.." nstep="..self.tbGuideTemplate.nStep)
    --local nGuideQuestId = self.tbGuideTemplate.nQuestId
    --local nGuideQuestSubId = self.tbGuideTemplate.nQuestSubId
    local SelfObj = GamePlayerSelfHelper:Get()
    local QuestComponent = SelfObj.QuestComponent
    -- local tbAccept = QuestComponent.tbAlreadyAccepts
    for k,v in pairs(self.tbGuideTemplate.tbQuestId)do
        -- if(tbAccept[v] ~= nil and tbAccept[v][self.tbGuideTemplate.nQuestSubId] ~= nil)then
        if(QuestComponent:GetQuest(v, self.tbGuideTemplate.nQuestSubId) ~= nil)then
            -- logdebug("GuideTriggerTaskShow:OnTaskShow2")
            self:Trigger()
            return
        end
    end

    -- for nQuestId,v in pairs(QuestComponent.tbAlreadyAccepts)do
    --     for nQuestSubId,info in pairs(v)do
    --         logdebug("nQuestId="..nQuestId.." nQuestSubId="..nQuestSubId.." nGuideQuestId="..nGuideQuestId.." nGuideQuestSubId="..nGuideQuestSubId)
    --         if(nQuestId == nGuideQuestId and nQuestSubId == nGuideQuestSubId)then
    --             logdebug("GuideTriggerTaskShow:OnTaskShow2")
    --             self:Trigger()
    --             return
    --         end
    --     end
    -- end
    --self:Trigger()
    -- local nGuideQuestId = self.tbGuideTemplate.nQuestId
    -- local nGuideQuestSubId = self.tbGuideTemplate.nQuestSubId
    -- for nQuestId,nQuestSubId in pairs(tbQuestId)do
    --     if(nGuideQuestId == nQuestId and nGuideQuestSubId == nQuestSubId )then
    --         logdebug("GuideTriggerTaskShow:OnTaskShow")
    --         self:Trigger()
    --         return
    --     end
    -- end
end

return GuideTriggerTaskShow
