-----------------------------------------------------
--File Name    : GuideTriggerInteractionVisible.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerInteractionVisible = luaclass("GuideTriggerInteractionVisible",GuideTrigger)

local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")

GuideTriggerInteractionVisible.bIsPlayerSelfReady = false

local function GetMainWnd(self)
    local MainWnd = UIManager:GetWnd(UIDef.UI_MAIN)
    local BattleMainWnd = UIManager:GetWnd(UIDef.UI_BATTLE_MAIN)
    local Wnd = nil
    if(MainWnd ~= nil and UIManager:IsWndOpen(UIDef.UI_MAIN))then
        Wnd = MainWnd
    elseif(BattleMainWnd ~= nil and UIManager:IsWndOpen(UIDef.UI_BATTLE_MAIN))then
        Wnd = BattleMainWnd
    end
    return Wnd
end

local function CheckInteractionVisible(self)
    local Wnd = GetMainWnd(self)
    if(Wnd ~= nil)then
        local bWidgetVisible = Wnd.pWidgetRef.ovlQuickInteration:IsVisible()
        return bWidgetVisible == self.tbTemplate.bInteractionVisible
    end
    return false
end


--override
function GuideTriggerInteractionVisible:Begin()
    GuideTriggerInteractionVisible.super.Begin(self)
    if(CheckInteractionVisible(self))then
        self:Trigger()
    end
    
end

function GuideTriggerInteractionVisible:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_INTERACTION_CHANGE, self, self.OnInteractionVisible)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_STACK_TOP, self, self.OnOpenUI)
    
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_INTERACTION_BTN_VISIBLE, self, self.OnInteractionBtnVisible)
end

function GuideTriggerInteractionVisible:OnInteractionVisible(bVisible, nInteractionType, pNpc)
    self:DebugLog("OnInteractionVisible,bVisible="..tostring(bVisible).." ngroup="..self.tbGuideTemplate.nGroup.." nstep="..self.tbGuideTemplate.nStep)
    if(self.tbTemplate.bInteractionVisible == bVisible and nInteractionType == 1)then  
        self:Trigger()
    else
        self.bIsTrigger = false
    end
end

function GuideTriggerInteractionVisible:OnInteractionBtnVisible()
    if(CheckInteractionVisible(self))then
        self:Trigger()
    end
end

function GuideTriggerInteractionVisible:OnOpenUI(szWndName)
    --self:DebugLog("GuideTriggerInteractionVisible:OnOpenUI,szWndName="..tostring(szWndName).." ngroup="..self.tbGuideTemplate.nGroup.." nstep="..self.tbGuideTemplate.nStep)
    if((szWndName == UIDef.UI_BATTLE_MAIN or szWndName == UIDef.UI_MAIN) and CheckInteractionVisible(self))then
        --logdebug("GuideTriggerInteractionVisible:OnOpenUI,trigger")
        self:Trigger()
    end
end

function GuideTriggerInteractionVisible:IsTrigger()
    self.bIsTrigger = CheckInteractionVisible(self)
    --logdebug("GuideTriggerInteractionVisible:IsTrigger,self.bIsTrigger=",self.bIsTrigger," ngroup="..self.tbGuideTemplate.nGroup.." nstep="..self.tbGuideTemplate.nStep)
    return self.bIsTrigger
end

return GuideTriggerInteractionVisible
