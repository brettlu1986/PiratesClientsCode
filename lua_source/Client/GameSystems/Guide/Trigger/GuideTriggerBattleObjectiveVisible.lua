-----------------------------------------------------
--File Name    : GuideTriggerBattleObjectiveVisible.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerBattleObjectiveVisible = luaclass("GuideTriggerBattleObjectiveVisible",GuideTrigger)

local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")


GuideTriggerBattleObjectiveVisible.bObjectiveVisible = false
GuideTriggerBattleObjectiveVisible.bAnimEnd = false


local function CheckUIVisible(self)
    local szOpenUIName = self.tbTemplate.szOpenUIName
    local Wnd = UIManager:GetWnd(szOpenUIName)
    local tbTemplate = self.tbTemplate
    if(Wnd ~= nil and UIManager:IsWndOpen(szOpenUIName))then
        if(szOpenUIName == UIDef.UI_BATTLE_MAIN and Wnd.pbBattleObjective ~= nil)then
            self.bObjectiveVisible = Wnd.pbBattleObjective.bPanelVisible
            if(Wnd.tbTemplate.bPushToStack)then
                if(UIManager:IsStackTopUI(szOpenUIName))then
                    self:DebugLog("CheckUIVisible:return true")
                    return self.bObjectiveVisible == tbTemplate.bIsEnable
                else
                    self:DebugLog("CheckUIVisible return false")
                    return false
                end
            else
                self:DebugLog("CheckUIVisible2:return true")
                return self.bObjectiveVisible == tbTemplate.bIsEnable
            end
        end
        
    else
        self:DebugLog("CheckUIVisible2 return false")
        return false
    end
end


--override
function GuideTriggerBattleObjectiveVisible:Begin()
    GuideTriggerBattleObjectiveVisible.super.Begin(self)
    if(CheckUIVisible(self) and self.bAnimEnd)then
        self:Trigger()
    end
end

function GuideTriggerBattleObjectiveVisible:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_UI, self, self.OnOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_STACK_TOP, self, self.OnOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_BATTLE_OBJECTIVE_VISIBLE, self, self.OnObjectiveVisible)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_ANIMATION_END, self, self.OnUIAnimEnd)
    EventHelper:RegisterEvent(ClientEventDef.EV_EXIT_CINEMATIC_MODE, self, self.OnExitCinematicMode)
end

function GuideTriggerBattleObjectiveVisible:OnOpenUI(szWndName)
    self:DebugLog("OnOpenUI,szWndName="..tostring(szWndName).." self.tbTemplate.szOpenUIName="..tostring(self.tbTemplate.szOpenUIName).." ngroup="..self.tbGuideTemplate.nGroup.." nstep="..self.tbGuideTemplate.nStep)
    if(szWndName ~= nil and szWndName == self.tbTemplate.szOpenUIName)then
        if(CheckUIVisible(self) and self.bAnimEnd)then
            self:Trigger()
        end
    end
end

function GuideTriggerBattleObjectiveVisible:OnUIAnimEnd(szUIName)
    self:DebugLog("OnUIAnimEnd,szUIName="..tostring(szUIName))
    if(CheckUIVisible(self))then
        if(szUIName == self.tbTemplate.szOpenUIName)then
            self.bAnimEnd = true
            if(self.bObjectiveVisible == self.tbTemplate.bIsEnable)then
                self:Trigger()
            end
        end
    end
end

function GuideTriggerBattleObjectiveVisible:OnObjectiveVisible(bVisible)
    self:DebugLog("OnObjectiveVisible,bVisible="..tostring(bVisible))
    self.bAnimEnd = false
    self.bObjectiveVisible = bVisible
end

function GuideTriggerBattleObjectiveVisible:OnExitCinematicMode()
    self:DebugLog("OnExitCinematicMode,self.bObjectiveVisible="..tostring(self.bObjectiveVisible))
    if(CheckUIVisible(self) and self.bAnimEnd)then
        self:Trigger()
    end
end

function GuideTriggerBattleObjectiveVisible:IsTrigger()
    self.bIsTrigger = CheckUIVisible(self) and self.bAnimEnd
    return self.bIsTrigger
end

return GuideTriggerBattleObjectiveVisible
