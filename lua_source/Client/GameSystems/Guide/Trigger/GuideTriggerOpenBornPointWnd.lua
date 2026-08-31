-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideTriggerOpenUI                = require("GuideTriggerOpenUI")
local GuideTriggerOpenBornPointWnd      = luaclass("GuideTriggerOpenBornPointWnd", GuideTriggerOpenUI)

local ClientEventDef        = require("ClientEventDef")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local UIManager             = require("UIManager")
-----------------------------------------------------

local function CheckWidgetVisible(self, Wnd)
    local tbTemplate = self.tbTemplate
    if tbTemplate.tbWidgetName == nil or #tbTemplate.tbWidgetName == 0 then
        self:DebugLog("CheckWidgetVisible return true")
        return true
    end
    local pWidgetRef = Wnd.pWidgetRef
    if tbTemplate.tbPrefabName ~= nil then
        for k,v in ipairs(tbTemplate.tbPrefabName)do
            pWidgetRef = pWidgetRef[v]
            if(pWidgetRef == nil)then
                self:LogError("CheckWidgetVisible,not found prefab,prefab name="..v)
                self:DebugLog("CheckWidgetVisible return false")
                return false
            end
        end
    end
    local SelectWidget = pWidgetRef[tbTemplate.tbWidgetName[1]]
    if SelectWidget == nil or not SelectWidget:IsVisible() then
        self:DebugLog("CheckWidgetVisible return false")
        return false
    end
    self:DebugLog("CheckWidgetVisible return true")
    return true
end

local function CheckUIVisible(self)
    self:DebugLog("CheckUIVisible")
    local szOpenUIName = self.tbTemplate.szOpenUIName
    local Wnd = UIManager:GetWnd(szOpenUIName)
    self:DebugLog("CheckUIVisible " .. tostring(UIManager:IsWndOpen(szOpenUIName)) .. " " .. tostring(Wnd:IsVisible()))
    if Wnd ~= nil and UIManager:IsWndOpen(szOpenUIName) and Wnd:IsVisible() then
        if Wnd.tbTemplate.bPushToStack then
            if(UIManager:IsShowTopUI(szOpenUIName))then
                self:DebugLog("CheckUIVisible:CheckWidgetVisible")
                return CheckWidgetVisible(self, Wnd)
            else
                self:DebugLog("CheckUIVisible return false")
                return false
            end
        else
            self:DebugLog("CheckUIVisible:CheckWidgetVisible")
            return CheckWidgetVisible(self, Wnd)
        end
    else
        self:DebugLog("CheckUIVisible return false")
        return false
    end
end


function GuideTriggerOpenBornPointWnd:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_EXIT_LOADING, self, self.OnExitLoading)
end

function GuideTriggerOpenBornPointWnd:OnOpenUI(szWndName)
    self:DebugLog("OnOpenUI,szWndName="..tostring(szWndName).." self.tbTemplate.szOpenUIName="..tostring(self.tbTemplate.szOpenUIName).." ngroup="..self.tbGuideTemplate.nGroup.." nstep="..self.tbGuideTemplate.nStep)
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    if not bIsInDungeon then
        return
    end
    if szWndName ~= nil and szWndName == self.tbTemplate.szOpenUIName then
        if CheckUIVisible(self) then
            self:Trigger()
        else
            self:Break()
        end
    end
end

function GuideTriggerOpenBornPointWnd:OnExitLoading()
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_UI, self, self.OnOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_STACK_TOP, self, self.OnOpenUI)
end


return GuideTriggerOpenBornPointWnd
