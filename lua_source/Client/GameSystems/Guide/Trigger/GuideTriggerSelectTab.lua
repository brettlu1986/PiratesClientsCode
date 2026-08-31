-----------------------------------------------------
--File Name    : GuideTriggerSelectTab.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerSelectTab = luaclass("GuideTriggerSelectTab",GuideTrigger)

local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")


GuideTriggerSelectTab.bMainTaskHidden = false

local function CheckSelectedTab(self, Wnd)
    local tbTemplate = self.tbTemplate
    if(tbTemplate.tbWidgetName == nil or #tbTemplate.tbWidgetName == 0)then
        self:DebugLog("1111GuideTriggerSelectTab:CheckSelectedTab return false")
        return false
    end
    local ScriptClass = Wnd
    if(tbTemplate.tbPrefabName ~= nil)then
        for k,v in ipairs(tbTemplate.tbPrefabName)do
            ScriptClass = ScriptClass[v]
            if(ScriptClass == nil)then
                self:LogError("GuideTriggerSelectTab:CheckSelectedTab,not found prefab,prefab name="..v)
                self:DebugLog("22222GuideTriggerSelectTab:CheckSelectedTab return false")
                return false
            end
        end
    end
    local TabHelper = ScriptClass[tbTemplate.tbWidgetName[1]]
    if(TabHelper.nSelectedIdx == tbTemplate.nSelectedTabIndex)then
        self:DebugLog("3333GuideTriggerSelectTab:CheckSelectedTab return true, TabHelper.nSelectedIdx="..tostring(TabHelper.nSelectedIdx).." tbTemplate.nSelectedTabIndex="..tostring(tbTemplate.nSelectedTabIndex))
        return true
    end
    self:DebugLog("4444GuideTriggerSelectTab:CheckSelectedTab return false")
    return false
end

local function CheckUITabVisible(self)
    local szOpenUIName = self.tbTemplate.szOpenUIName
    local Wnd = UIManager:GetWnd(szOpenUIName)
    if(Wnd ~= nil and UIManager:IsWndOpen(szOpenUIName))then
        if(Wnd.tbTemplate.bPushToStack)then
            if Wnd.pbMainLeftPanel then
                self.bMainTaskHidden = Wnd.pbMainLeftPanel.bHidden
            end
            --logdebug("GuideTriggerSelectTab:CheckUITabVisible:self.bMainTaskHidden=",self.bMainTaskHidden)
            if(UIManager:IsStackTopUI(szOpenUIName))then
                self:DebugLog("5555GuideTriggerSelectTab:CheckUITabVisible:CheckSelectedTab")
                return CheckSelectedTab(self, Wnd)
            else
                self:DebugLog("1111GuideTriggerSelectTab:CheckUITabVisible return false")
                return false
            end
        else
            self:DebugLog("6666GuideTriggerSelectTab:CheckUITabVisible:CheckSelectedTab")
            return CheckSelectedTab(self, Wnd)
        end
    else
        self:DebugLog("4444GuideTriggerSelectTab:CheckUITabVisible return false")
        return false
    end
end

local function IsMainTaskRelated(self)
    local tbTemplate = self.tbTemplate
    if(tbTemplate.szOpenUIName == UIDef.UI_MAIN and tbTemplate.tbPrefabName ~= nil 
    and tbTemplate.tbPrefabName[1] == "pbMainLeftPanel")then
        return true
    end
    return false
end
--override
function GuideTriggerSelectTab:Begin()
    GuideTriggerSelectTab.super.Begin(self)
    if(CheckUITabVisible(self) and not self.bMainTaskHidden)then
        self:Trigger()
    end
end

function GuideTriggerSelectTab:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_UI, self, self.OnOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_STACK_TOP, self, self.OnOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_SELECT_TAB, self, self.OnTabSelected)
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_MAIN_TASK_VISIBLE, self, self.OnMainTaskVisible)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_ANIMATION_END, self, self.OnUIAnimEnd)
    EventHelper:RegisterEvent(ClientEventDef.EV_EXIT_CINEMATIC_MODE, self, self.OnExitCinematicMode)
end

function GuideTriggerSelectTab:OnOpenUI(szWndName)
    self:DebugLog("GuideTriggerSelectTab:OnOpenUI,szWndName="..tostring(szWndName).." self.tbTemplate.szOpenUIName="..tostring(self.tbTemplate.szOpenUIName).." ngroup="..self.tbGuideTemplate.nGroup.." nstep="..self.tbGuideTemplate.nStep)
    if(szWndName ~= nil and szWndName == self.tbTemplate.szOpenUIName)then
        if(CheckUITabVisible(self) and not self.bMainTaskHidden)then
            self:Trigger()
        end
    end
end

function GuideTriggerSelectTab:OnTabSelected(szWndName, nSelectedIndex)
    self:DebugLog("szWndName="..szWndName.." nSelectedIndex="..nSelectedIndex)
    if(szWndName ~= nil and szWndName == self.tbTemplate.szOpenUIName)then
        if(CheckUITabVisible(self) and not self.bMainTaskHidden)then
            self:Trigger()
        end
    end
end

function GuideTriggerSelectTab:OnMainTaskVisible(bHidden)
    self:DebugLog("GuideTriggerSelectTab:OnMainTaskVisible,bHidden="..tostring(bHidden))
    
    self.bMainTaskHidden = bHidden
end

function GuideTriggerSelectTab:OnUIAnimEnd(szUIName)
    self:DebugLog("GuideTriggerSelectTab:OnUIAnimEnd,szUIName="..tostring(szUIName))
    if(CheckUITabVisible(self))then
        if(szUIName == UIDef.UI_MAIN)then
            if(not self.bMainTaskHidden and IsMainTaskRelated(self))then
                self:Trigger()
            end
        end
    end
end

function GuideTriggerSelectTab:OnExitCinematicMode()
    self:DebugLog("GuideTriggerSelectTab:OnExitCinematicMode,self.bMainTaskHidden="..tostring(self.bMainTaskHidden))
    if(CheckUITabVisible(self))then
        if(IsMainTaskRelated(self))then
            if(not self.bMainTaskHidden)then
                self:Trigger()
            end
        else
            self:Trigger()
        end
    end
end

function GuideTriggerSelectTab:IsTrigger()
    self.bIsTrigger = CheckUITabVisible(self) and not self.bMainTaskHidden
    return self.bIsTrigger
end

return GuideTriggerSelectTab
