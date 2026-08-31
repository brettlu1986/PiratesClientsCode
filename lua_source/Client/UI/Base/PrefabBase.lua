-----------------------------------------------------
--File Name    : PrefabBase.lua
--Author       : Song Fuhao
--Create Time  : 2016-06-17
--Description  : Prefab基类
-----------------------------------------------------

local luaclass = require("luaclass")
local PrefabBase = luaclass("PrefabBase")

-- import require
local SelfEventHelper = require("SelfEventHelper")
local SelfPrefabHelper = require("SelfPrefabHelper")
local SelfTimerHelper = require("SelfTimerHelper")
local SelfWidgetHelper = require("SelfWidgetHelper")
local SelfUILogicHelper = require("SelfUILogicHelper")
local UISetUtils = require("UISetUtils")

-- member variable
PrefabBase.EventHelper      = nil
PrefabBase.PrefabHelper     = nil
PrefabBase.TimerHelper      = nil
PrefabBase.WidgetHelper     = nil
PrefabBase.UILogicHelper    = nil
PrefabBase.Owner            = nil
PrefabBase.WndCreator       = nil
PrefabBase.bEntered         = false
PrefabBase.bEventBinded     = false
PrefabBase.bShowed          = false


-- public function
function PrefabBase:Create(tbTemplate, pWidgetRef)
    self.tbTemplate = tbTemplate
    self.pWidgetRef = pWidgetRef
    self.EventHelper = SelfEventHelper()
    self.PrefabHelper = SelfPrefabHelper()
    self.TimerHelper = SelfTimerHelper()
    self.WidgetHelper = SelfWidgetHelper()
    self.UILogicHelper = SelfUILogicHelper()

    self.PrefabHelper:SetOwner(self.Owner)
    self.PrefabHelper:SetWndCreator(self.WndCreator)
    self.UILogicHelper:SetOwner(self)

    self:OnCreate()
    self:LoadResource()
end

function PrefabBase:SetOwner(Owner)
    self.Owner = Owner
end

function PrefabBase:SetWndCreator(WndCreator)
    self.WndCreator = WndCreator
end

function PrefabBase:Destroy()
    self:Exit()
    self:UnbindEvent()
    self:UnloadResource()
    self.UILogicHelper:DestroyAllUILogic()
    self:OnDestroy()

    self.PrefabHelper = nil
    self.EventHelper = nil
    self.TimerHelper = nil
    self.WidgetHelper = nil
    self.UILogicHelper = nil

    self.pWidgetRef = nil
    self.tbTemplate = nil
end

function PrefabBase:LoadText()
    local tbText = ClientShell.GetClient(GWorld):GetTextWidget(self.pWidgetRef)
    for _, v in ipairs(tbText) do
        UISetUtils.UpdateByTextSelfKey(v)
    end
end

function PrefabBase:LoadResource()
    if not self.pWidgetRef then
        self.pWidgetRef = self.WndCreator:CreateUMG(self.tbTemplate.szUIPath)
    end
    self:LoadText()
    self:OnLoad()
    self.UILogicHelper:OnLoad()
end

function PrefabBase:UnloadResource()
    self:OnUnload()
    self.UILogicHelper:OnUnload()
    self.PrefabHelper:UnbindAllPrefab()
    self.WidgetHelper:DestroyAllWidget()
    if(self.pWidgetRef) then
        self.WndCreator:DestroyUMG(self.pWidgetRef)
    end
end

function PrefabBase:BindEvent()
    if not self.bEventBinded then
        self.bEventBinded = true
        self:OnBindEvent(self.EventHelper)
        self.UILogicHelper:BindEvent()
        self.PrefabHelper:BindEvent()
    end
end

function PrefabBase:UnbindEvent()
    self:OnUnbindEvent(self.EventHelper)
    self.EventHelper:UnregisterAll()
    self.UILogicHelper:UnbindEvent()
    self.PrefabHelper:UnbindEvent()
    self.TimerHelper:ClearAllTimer()
    self.bEventBinded = false
end

function PrefabBase:Enter()
    if not self.bEntered then
        self.bEntered = true
        self:OnEnter()
        self.UILogicHelper:OnEnter()
        self.PrefabHelper:Enter()
    end
end

function PrefabBase:Show()
    if not self.bShowed then
        self.bShowed = true
        self:OnShow()
        self.UILogicHelper:OnShow()
        self.PrefabHelper:Show()
    end
end

function PrefabBase:Hide()
    self:OnHide()
    self.UILogicHelper:OnHide()
    self.PrefabHelper:Hide()
    self.bShowed = false
end

function PrefabBase:Exit()
    self:OnExit()
    self.UILogicHelper:OnExit()
    self.PrefabHelper:Exit()
    self.bEntered = false
end

function PrefabBase:Pause()
    self:OnPause()
    self.UILogicHelper:OnPause()
    self.PrefabHelper:Pause()
end

function PrefabBase:Resume()
    self:OnResume()
    self.UILogicHelper:OnResume()
    self.PrefabHelper:Resume()
end

function PrefabBase:OnCreate()
end

function PrefabBase:OnDestroy()
end

function PrefabBase:OnLoad()
end

function PrefabBase:OnUnload()
end

function PrefabBase:OnEnter()
end

function PrefabBase:OnShow()
end

function PrefabBase:OnHide()
end

function PrefabBase:OnExit()
end

function PrefabBase:OnBindEvent(EventHelper)
end

function PrefabBase:OnUnbindEvent(EventHelper)
end

function PrefabBase:OnPause()
end

function PrefabBase:OnResume()
end

--动画播放注册
function PrefabBase:PlayAnimation(szAnimName, StartTime, LoopNum, PlayMode, Speed, funcEnd, szInfo)
    self:PlayAnimationWithUserWidget(self.pWidgetRef, szAnimName, StartTime, LoopNum, PlayMode, Speed, funcEnd, szInfo)
end

function PrefabBase:StopAnimation(szAnimName)
    self:StopAnimationWithUserWidget(self.pWidgetRef, szAnimName)
end


function PrefabBase:PlayAnimationWithUserWidget(pWidgetRef, szAnimName, StartTime, LoopNum, PlayMode, Speed, funcEnd, szInfo)
    if self.Owner then
        self.Owner:PlayAnimationWithUserWidget(pWidgetRef, szAnimName, StartTime, LoopNum, PlayMode, Speed, funcEnd, szInfo)
    else
        logwarning("[UI]PrefabBase:PlayAnimation:prefab has not owner, please check it, prefab name=", self.tbTemplate.szPrefabName)
    end
end

function PrefabBase:StopAnimationWithUserWidget(pWidgetRef, szAnimName)
    if self.Owner then
        self.Owner:StopAnimationWithUserWidget(pWidgetRef, szAnimName)
    else
        logwarning("[UI]PrefabBase:StopAnimation:prefab has not owner, please check it, prefab name=", self.tbTemplate.szPrefabName)
    end
end

function PrefabBase:IsAnimationPlaying(szAnimName)
    if self.Owner then
        return self.Owner:IsAnimationPlaying(szAnimName)
    else
        logwarning("[UI]PrefabBase:IsAnimationPlaying:prefab has not owner, please check it, prefab name=", self.tbTemplate.szPrefabName)
    end
    return false
end

return PrefabBase
