-----------------------------------------------------
--File Name    : GuideTriggerOpenUI.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideTrigger          = require("GuideTrigger")
local GuideTriggerOpenUI    = luaclass("GuideTriggerOpenUI",GuideTrigger)

local ClientEventDef        = require("ClientEventDef")
local UIManager             = require("UIManager")
local UIDef                 = require("UIDef")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local GameWorldSystem       = require("GameWorldSystem")
local GameObjectSystem      = dynamic_require("GameObjectSystem")
-----------------------------------------------------

local function CheckWidgetVisible(self, Wnd)
    local tbTemplate = self.tbTemplate
    if tbTemplate.tbWidgetName == nil or #tbTemplate.tbWidgetName == 0 then
        self:DebugLog("GuideTriggerOpenUI:CheckWidgetVisible return true")
        return true
    end
    local pWidgetRef = Wnd.pWidgetRef
    if tbTemplate.tbPrefabName then
        for k,v in ipairs(tbTemplate.tbPrefabName)do
            pWidgetRef = pWidgetRef[v]
            if not pWidgetRef then
                self:LogError("GuideTriggerOpenUI:CheckWidgetVisible,not found prefab,prefab name="..v)
                self:DebugLog("GuideTriggerOpenUI:CheckWidgetVisible return false")
                return false
            end
        end
    end
    local SelectWidget = pWidgetRef[tbTemplate.tbWidgetName[1]]
    if not SelectWidget == nil or not SelectWidget:IsVisible() then
        self:DebugLog("GuideTriggerOpenUI:CheckWidgetVisible return false")
        return false
    end
    self:DebugLog("GuideTriggerOpenUI:CheckWidgetVisible return true")
    return true
end

local function CheckUIVisible(self)
    self:DebugLog(" GuideTriggerOpenUI CheckUIVisible")
    local szOpenUIName = self.tbTemplate.szOpenUIName
    local Wnd = UIManager:GetWnd(szOpenUIName)
    local tbTemplate = self.tbTemplate
    if(Wnd ~= nil and UIManager:IsWndOpen(szOpenUIName) and Wnd:IsVisible())then
        if(Wnd.tbTemplate.bPushToStack)then
            if(UIManager:IsShowTopUI(szOpenUIName))then
                self:DebugLog("GuideTriggerOpenUI:CheckUIVisible:CheckWidgetVisible")
                return CheckWidgetVisible(self, Wnd)
            else
                self:DebugLog("GuideTriggerOpenUI:CheckUIVisible return false")
                return false
            end
        else
            if(szOpenUIName == UIDef.UI_INTERACTION)then
                local nSelectNpcID = Wnd.nSelectNpcID
                if(nSelectNpcID ~= nil)then
                    local tbSelectedNpc = GameObjectSystem:FindByInstanceId(nSelectNpcID)
                    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
                    if(bIsInDungeon or not tbSelectedNpc)then
                        self:DebugLog("CheckUIVisible:return false,bIsInDungeon="..tostring(bIsInDungeon).." tbSelectedNpc="..tostring(tbSelectedNpc))
                        return false
                    end
                    local nCurrentSceneId = GameWorldSystem:GetWorld().nSceneId
                    local tbNpcId = tbTemplate.tbObjTemplateId
                    local nTargetSceneId = tbTemplate.nSceneId
                    for k,v in pairs(tbNpcId)do
                        self:DebugLog("CheckUIVisible:nTemplateID="..tostring(tbSelectedNpc.tbNpcTemplateData.nTemplateID).." v="..tostring(v).." option="..tostring(Wnd.tbOptions))
                        if(tbSelectedNpc.tbNpcTemplateData.nTemplateID == v and 
                        (nTargetSceneId == nil or nTargetSceneId == nCurrentSceneId) and 
                        Wnd.pWidgetRef.QuestDialog:IsVisible())then
                            self:DebugLog("GuideTriggerOpenUI:CheckUIVisible return true")
                            return true
                        end
                    end
                end
                return false
            end
            return CheckWidgetVisible(self, Wnd)
        end
    else
        return false
    end
end

--override
function GuideTriggerOpenUI:Begin()
    GuideTriggerOpenUI.super.Begin(self)
    if CheckUIVisible(self) then
        self:Trigger()
    else
        self:Break()
    end
end

function GuideTriggerOpenUI:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_UI, self, self.OnOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_STACK_TOP, self, self.OnOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_EXIT_CINEMATIC_MODE, self, self.OnExitCinematicMode)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHOT_LEAVE_CAMERA_MODE, self, self.OnExitCameraMode)
    EventHelper:RegisterEvent(ClientEventDef.EV_EXIT_LOADING, self, self.OnExitLoading)
end

function GuideTriggerOpenUI:OnOpenUI(szWndName)
    self:DebugLog("OnOpenUI,szWndName="..tostring(szWndName).." self.tbTemplate.szOpenUIName="..tostring(self.tbTemplate.szOpenUIName).." ngroup="..self.tbGuideTemplate.nGroup.." nstep="..self.tbGuideTemplate.nStep)
    if(szWndName ~= nil and szWndName == self.tbTemplate.szOpenUIName)then
        if CheckUIVisible(self) then
            self:Trigger()
        else
            self:Break()
        end
    end
end

function GuideTriggerOpenUI:IsTrigger()
    self.bIsTrigger = CheckUIVisible(self)
    return self.bIsTrigger
end


function GuideTriggerOpenUI:OnExitCinematicMode()
    if CheckUIVisible(self) then
        self:Trigger()
    else
        self:Break()
    end
end

function GuideTriggerOpenUI:OnExitCameraMode()
    if CheckUIVisible(self) then
        self:Trigger()
    else
        self:Break()
    end
end

function GuideTriggerOpenUI:OnExitLoading()
    if CheckUIVisible(self) then
        self:Trigger()
    else
        self:Break()
    end
end

return GuideTriggerOpenUI
