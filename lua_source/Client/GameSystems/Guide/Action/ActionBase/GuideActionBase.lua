-----------------------------------------------------
--File Name    : GuideActionBase.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass          = require("luaclass")
local GuideActionBase   = luaclass("GuideActionBase")

local SelfEventHelper       = require("SelfEventHelper")
local UIManager             = require("UIManager")
local UIDef                 = require("UIDef")
local ClientEventDef        = require("ClientEventDef")
local DelayTimer            = require("DelayTimer")
local SelfTimerHelperClass  = require("SelfTimerHelper")
local GuideDebug            = require("GuideDebug")
local EventManager          = require("EventManager")
-----------------------------------------------------
local DEFAULT_UI_ORDER = 41

--member veriable
GuideActionBase.nIndex                      = 0
GuideActionBase.Owner                       = nil
GuideActionBase.OnActionEndFunc             = nil
GuideActionBase.tbTemplate                  = nil
GuideActionBase.tbGuideTemplate             = nil
GuideActionBase.TimerHelper                 = nil
GuideActionBase.DelayTimerHandle            = nil
GuideActionBase.DelayCloseTimerHandle       = nil
GuideActionBase.SoundEffect                 = nil
GuideActionBase.bIsModal                    = false
GuideActionBase.bInAction                   = false
GuideActionBase.bUIControl                  = true
GuideActionBase.bEnded                      = false
GuideActionBase.bExecuted                   = false
-----------------------------------------------------

local function LogPreProcess(self, szMsg)
    local szTemp = "[GuideAction] "
    local tbTemplate = self.tbTemplate
    local tbGuideTemplate = self.tbGuideTemplate
    if tbTemplate and tbGuideTemplate then
        szTemp = szTemp .. tbTemplate.szActionType .. ":" .. szMsg .. " ngroup = ".. tbGuideTemplate.nGroup .. " nstep = " .. tbGuideTemplate.nStep .. " nIndex = " .. self.nIndex
    else
        szTemp = szTemp .. szMsg
    end
    return szTemp
end

function GuideActionBase:Init(Owner, nIndex, tbTemplate, tbGuideTemplate, OnActionEndFunc)
    self.EventHelper = SelfEventHelper()
    self.TimerHelper = SelfTimerHelperClass()
    self.Owner              = Owner
    self.nIndex             = nIndex
    self.OnActionEndFunc    = OnActionEndFunc
    self.tbTemplate         = tbTemplate
    self.tbGuideTemplate    = tbGuideTemplate
    self.bInAction          = false
    self.bIsModal           = tbGuideTemplate.bIsModal
    self.bUIControl         = true
    self.bEnded             = false
    self.bExecuted          = false
    self:DebugLog("Init")
    return true
end

function GuideActionBase:Uninit()
    self:DebugLog("Uninit")
    self.EventHelper:UnregisterAll()
    self.TimerHelper:ClearAllTimer()
    self:CloseDelayTimer()
    self:CloseDelayCloseTimer()
	self.bExecuted = false
    self.OnActionEndFunc = nil
    self.bInAction = false
    self.bEnded = true
end

function GuideActionBase:Begin()
    self:DebugLog("Begin")
    self.bInAction = true
    self.EventHelper:UnregisterAll()
    self.TimerHelper:ClearAllTimer()
    self:BindEvent()
    local tbTemplate = self.tbTemplate 
    if tbTemplate.nDelayTime > 0 then
        self:CloseDelayTimer()
        self.DelayTimerHandle = DelayTimer:DelayRun(function() self:OnDelayTimerFunc(tbTemplate) end, tbTemplate.nDelayTime)
    else
        self.DelayTimerHandle = DelayTimer:RunNextTick(function() self:OnDelayTimerFunc(tbTemplate) end)
    end
end

function GuideActionBase:EndAction()
    self:DebugLog("EndAction")
    if self.OnActionEndFunc then
        self:DebugLog("OnActionEndFunc")
        self.OnActionEndFunc(self.nIndex)
        self.OnActionEndFunc = nil
    end
end

function GuideActionBase:End()
    self:DebugLog("End")
    if self.bEnded then
        self:DebugLog("already done!")
        return
    end
	self.OnActionEndFunc = nil
    self.bInAction = false
    self.bEnded = true 
    self.bExecuted = false
    self.EventHelper:UnregisterAll()
    self.TimerHelper:ClearAllTimer()
    self:CloseDelayTimer()
    self:CloseDelayCloseTimer()
end

function GuideActionBase:Interrupt()
    self:DebugLog("Interrupt")
    self.EventHelper:UnregisterAll()
    self.TimerHelper:ClearAllTimer()
    self:CloseDelayTimer()
    self:CloseDelayCloseTimer()
    self.bInAction = false
    self.bEnded = false
    self.bExecuted = false
end

function GuideActionBase:CloseDelayTimer()
    self:DebugLog("CloseDelayTimer")
    if self.DelayTimerHandle then
        DelayTimer:ClearTimer(self.DelayTimerHandle)
        self.DelayTimerHandle = nil
    end
end

function GuideActionBase:CloseDelayCloseTimer()
    self:DebugLog("CloseDelayCloseTimer")
    if self.DelayCloseTimerHandle then
        DelayTimer:ClearTimer(self.DelayCloseTimerHandle)
        self.DelayCloseTimerHandle = nil
    end
end

function GuideActionBase:OnDelayTimerFunc(tbTemplate)
    self:DebugLog("OnDelayTimerFunc")
    self:DoAction(tbTemplate)
    self:AfterDoAction(tbTemplate)
    if not self.bExecuted then
        self:ExeOnece(tbTemplate)
        self.bExecuted = true    
    end
    if self.tbTemplate.nShowDuration > 0 then
        self:CloseDelayCloseTimer()
        self.DelayCloseTimerHandle = DelayTimer:DelayRun(function() self:OnTimerFunc() end, tbTemplate.nShowDuration)
    end
end

function GuideActionBase:BindEvent()
    self:DebugLog("BindEvent")
    self.EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_CLICK_ANYWHERE, self, self.OnClickAnywhere)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_CINEMATIC_MODE, self, self.OnEnterCinematicMode)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_SHOT_ENTER_CAMERA_MODE, self, self.OnEnterCameraMode)
end

function GuideActionBase:GetParentUserWidget()
    self:DebugLog("GetParentUserWidget")
    local tbTemplate = self.tbTemplate
    local Wnd = UIManager:GetWnd(tbTemplate.szUIName)
    if not Wnd or not UIManager:IsWndOpen(tbTemplate.szUIName)then
        self:LogError("GetPrefab,wnd nil,uiname="..tostring(tbTemplate.szUIName))
        return
    end
    local pWidgetRef = Wnd.pWidgetRef
    for k, v in ipairs(tbTemplate.tbPrefabName)do
        pWidgetRef = pWidgetRef[v]
        if not pWidgetRef then
            self:LogError("GetPrefab,can't find prefab,name=", v)
            return
        end
    end
    return pWidgetRef
end

function GuideActionBase:GetSelectWidgets()
    self:DebugLog("GetSelectWidgets tbWidgetName" .. tostring(self.tbTemplate.tbWidgetName[1]))
    local tbSelectWidgets = {}
    local tbTemplate = self.tbTemplate
    local pWidgetRef = self:GetParentUserWidget()
    self:DebugLog("GetSelectWidgets pWidgetRef = " .. tostring(pWidgetRef))
    if not pWidgetRef then
        return tbSelectWidgets
    end
    for k, v in ipairs(tbTemplate.tbWidgetName)do
        self:DebugLog("GetSelectWidgets tbWidgetName = " .. v)
        local pSelectWidget = pWidgetRef[v]
        if pSelectWidget then
            table.insert(tbSelectWidgets, pSelectWidget)
        else
            self:LogError("GetSelectWidgets,can't find widgeht,name=", v)
        end
    end
    return tbSelectWidgets
end

function GuideActionBase:GetSelectPrefab()
    self:DebugLog("GetSelectPrefab tbWidgetName" .. tostring(self.tbTemplate.tbWidgetName[1]))
    local tbSelectWidgets = {}
    local pWidgetRef = self:GetParentUserWidget()
    self:DebugLog("GetSelectWidgets pWidgetRef = " .. tostring(pWidgetRef))
    if not pWidgetRef then
        return tbSelectWidgets
    end
    table.insert(tbSelectWidgets, pWidgetRef)
    return tbSelectWidgets
end

function GuideActionBase:GetGuideWnd()
    self:DebugLog("GetGuideWnd")
    local GuideWnd = UIManager:GetWnd(UIDef.UI_GUIDE)
    if not GuideWnd then
        local tbArgs = {}
        tbArgs.nZOrder = DEFAULT_UI_ORDER
        GuideWnd = UIManager:OpenWnd(UIDef.UI_GUIDE, tbArgs)
    end
    return GuideWnd
end

function GuideActionBase:OpenGuideWnd()
    self:DebugLog("OpenGuideWnd")
    local GuideWnd = UIManager:OpenWnd(UIDef.UI_GUIDE)
    return GuideWnd
end

function GuideActionBase:IsGuideWndOpen()
    local bOpen = UIManager:IsWndOpen(UIDef.UI_GUIDE)
    return bOpen
end

function GuideActionBase:CloseGuide()
    self:DebugLog("CloseGuide1")
    local GuideWnd = self:GetGuideWnd()
    if GuideWnd ~= nil and self:IsGuideWndOpen() then 
        self:DebugLog("CloseGuide2")
        self:End()
        UIManager:CloseWnd(UIDef.UI_GUIDE)
    end
end

function GuideActionBase:ForceEndCurrentStep()
    self:DebugLog("ForceEndCurrentStep")
    local pStep = self.Owner
    if not pStep then
        return
    end
    pStep:ForceEnd()
end

function GuideActionBase:ForceEndCurrentGroup()
    self:DebugLog("ForceEndCurrentGroup")
    local pStep = self.Owner
    if not pStep then
        return
    end
    local pGroup = pStep.Owner
    if not pGroup then
        return
    end
    self:DebugLog("ForceEndCurrentGroup pGroup:ForceEnd")
    local GuideWnd = self:GetGuideWnd()
    if GuideWnd then
        UIManager:CloseWnd(UIDef.UI_GUIDE)
    end
    local bEnableEnd = self.tbTemplate.bEnableEnd
    pGroup:ForceEnd(bEnableEnd)
end

function GuideActionBase:DoAction(tbTemplate)
    self:DebugLog("DoAction")
end

function GuideActionBase:AfterDoAction(tbTemplate)
    self:DebugLog("AfterDoAction")
end

function GuideActionBase:ExeOnece()
    self:DebugLog("ExeOnece")
    
end

function GuideActionBase:OnTimerFunc()
    self:DebugLog("OnTimerFunc")
    self:End()
end

function GuideActionBase:InAction()
    self:DebugLog("IsAction")
    return self.bInAction
end

function GuideActionBase:IsEnded()
    self:DebugLog("IsEnded")
    return self.bEnded
end

function GuideActionBase:OnClickAnywhere()
    self:DebugLog("OnClickAnywhere")
    self:End()
end

function GuideActionBase:OnEnterCinematicMode()
	self:DebugLog("OnEnterCinematicMode")
    self:ForceEndCurrentGroup()
end

function GuideActionBase:OnEnterCameraMode()
    self:DebugLog("OnEnterCameraMode")
    self:ForceEndCurrentGroup() 
end

function GuideActionBase:OnLeaveProcedureBattle()
    self:DebugLog("OnLeaveProcedureBattle")
    self:ForceEndCurrentGroup() 
end

function GuideActionBase:AddValue(tbTable, key, value)
    if not tbTable or not key then
        return nil
    end
    tbTable[key] = value
end

function GuideActionBase:CallUIFunc(szFuncName, tbParams)
    self:DebugLog("CallUIFunc" .. " FuncName = " .. szFuncName)
    EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_CALL_FUNC, szFuncName, tbParams)
end

function GuideActionBase:SetSharedInfo(szKey, value)
    self:DebugLog("SetSharedInfo")
    self.Owner:SetSharedInfo(szKey, value)
end

function GuideActionBase:GetSharedInfo(szKey)
    self:DebugLog("SetSharedInfo")
    return self.Owner:GetSharedInfo(szKey)
end

function GuideActionBase:SetGroupSharedInfo(szKey, value)
    self:DebugLog("SetGroupSharedInfo")
    self.Owner.Owner:SetSharedInfo(szKey, value)
end

function GuideActionBase:GetGroupSharedInfo(szKey)
    self:DebugLog("GetGroupSharedInfo")
    return self.Owner.Owner:GetSharedInfo(szKey)
end

function GuideActionBase:SetModuleSharedInfo(szKey, value)
    self:DebugLog("SetModuleSharedInfo")
    self.Owner.Owner:SetModuleSharedInfo(szKey, value)
end

function GuideActionBase:GetModuleSharedInfo(szKey)
    self:DebugLog("GetModuleSharedInfo")
    return self.Owner.Owner:GetModuleSharedInfo(szKey)
end

function GuideActionBase:CallShowSpaceScreen(bShow)
    self:DebugLog("CallShowSpaceScreen " .. tostring(bShow))
    EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_SHOW_SPACE_SCREEN,bShow)
end

function GuideActionBase:DebugLog(szMsg)
    szMsg = LogPreProcess(self, szMsg)
    GuideDebug:DebugLog(szMsg)
end

function GuideActionBase:Log(szMsg)
    szMsg = LogPreProcess(self, szMsg)
    GuideDebug:Log(szMsg)
end

function GuideActionBase:LogError(szMsg)
    szMsg = LogPreProcess(self, szMsg)
    GuideDebug:LogError(szMsg)
end

return GuideActionBase
