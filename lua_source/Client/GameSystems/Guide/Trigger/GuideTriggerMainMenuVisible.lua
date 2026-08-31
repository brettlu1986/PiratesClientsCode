-----------------------------------------------------
--File Name    : GuideTriggerMainMenuVisible.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerMainMenuVisible = luaclass("GuideTriggerMainMenuVisible",GuideTrigger)

local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")


GuideTriggerMainMenuVisible.bMainMenuVisible = false
GuideTriggerMainMenuVisible.bAnimEnd = true


local function CheckUIVisible(self)
    local szOpenUIName = self.tbTemplate.szOpenUIName
    local Wnd = UIManager:GetWnd(szOpenUIName)
    local tbTemplate = self.tbTemplate
    if(Wnd ~= nil and UIManager:IsWndOpen(szOpenUIName))then
        if(szOpenUIName == UIDef.UI_MAIN and Wnd.pbMainMenu ~= nil)then
            self.bMainMenuVisible = not Wnd.pbMainMenu.bMainCollapsed
            if(Wnd.tbTemplate.bPushToStack)then
                if(UIManager:IsStackTopUI(szOpenUIName))then
                    self:DebugLog("5555GuideTriggerMainMenuVisible:CheckUIVisible:return true")
                    return self.bMainMenuVisible == tbTemplate.bIsEnable
                else
                    self:DebugLog("1111GuideTriggerMainMenuVisible:CheckUIVisible return false")
                    return false
                end
            else
                self:DebugLog("6666GuideTriggerMainMenuVisible:CheckUIVisible:return true")
                return self.bMainMenuVisible == tbTemplate.bIsEnable
            end
        end
        
    else
        self:DebugLog("4444GuideTriggerMainMenuVisible:CheckUIVisible return false")
        return false
    end
end


--override
function GuideTriggerMainMenuVisible:Begin()
    GuideTriggerMainMenuVisible.super.Begin(self)
    if(CheckUIVisible(self) and self.bAnimEnd)then
        self:Trigger()
    end
end

function GuideTriggerMainMenuVisible:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_UI, self, self.OnOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_STACK_TOP, self, self.OnOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_MAIN_MENU_VISIBLE, self, self.OnMainMenuVisible)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_ANIMATION_END, self, self.OnUIAnimEnd)
    EventHelper:RegisterEvent(ClientEventDef.EV_EXIT_CINEMATIC_MODE, self, self.OnExitCinematicMode)
end

function GuideTriggerMainMenuVisible:OnOpenUI(szWndName)
    self:DebugLog("GuideTriggerMainMenuVisible:OnOpenUI,szWndName="..tostring(szWndName).." self.tbTemplate.szOpenUIName="..tostring(self.tbTemplate.szOpenUIName).." ngroup="..self.tbGuideTemplate.nGroup.." nstep="..self.tbGuideTemplate.nStep)
    if(szWndName ~= nil and szWndName == self.tbTemplate.szOpenUIName)then
        if(CheckUIVisible(self) and self.bAnimEnd)then
            self:Trigger()
        end
    end
end

function GuideTriggerMainMenuVisible:OnUIAnimEnd(szUIName)
    self:DebugLog("GuideTriggerMainMenuVisible:OnUIAnimEnd,szUIName="..tostring(szUIName))
    if(CheckUIVisible(self))then
        if(szUIName == self.tbTemplate.szOpenUIName)then
            self.bAnimEnd = true
            if(self.bMainMenuVisible == self.tbTemplate.bIsEnable)then
                self:Trigger()
            end
        end
    end
end

function GuideTriggerMainMenuVisible:OnMainMenuVisible(bVisible)
    self:DebugLog("GuideTriggerMainMenuVisible:OnObjectiveVisible,bVisible="..tostring(bVisible))
    self.bAnimEnd = false
    self.bMainMenuVisible = bVisible
end

function GuideTriggerMainMenuVisible:OnExitCinematicMode()
    self:DebugLog("GuideTriggerMainMenuVisible:OnExitCinematicMode,self.bMainMenuVisible="..tostring(self.bMainMenuVisible))
    if(CheckUIVisible(self) and self.bAnimEnd)then
        self:Trigger()
    end
end

function GuideTriggerMainMenuVisible:IsTrigger()
    self.bIsTrigger = CheckUIVisible(self) and self.bAnimEnd
    return self.bIsTrigger
end

return GuideTriggerMainMenuVisible
