-----------------------------------------------------
--File Name    : GuideStep.lua
--Description  : 新手指引步骤
-----------------------------------------------------
local luaclass          = require("luaclass")
local GuideStep         = luaclass("GuideStep")

local GuideDebug            = require("GuideDebug")
local EventManager          = require("EventManager")
local ClientEventDef        = require("ClientEventDef")
local GuideTriggerDataTable = require("GuideTriggerDataTable")
local GuideActionDataTable  = require("GuideActionDataTable")
local UIManager             = require("UIManager")
local UIDef                 = require("UIDef")
local WndDataTable          = require("WndDataTable")
-----------------------------------------------------
--member veriable
local ANIM_END_TRGGER_TYPE = "GuideTriggerUIAnimationEnd"

GuideStep.tbGuideTriggers   = nil
GuideStep.tbGuideActions    = nil
GuideStep.OnStepEndCallBack = nil
GuideStep.tbTemplate        = nil
GuideStep.bAllActionEnd     = false
GuideStep.bAllTriggerEnd    = false
GuideStep.bBegin            = false
GuideStep.bEnded            = false
GuideStep.Owner             = nil
GuideStep.bSkip             = false
GuideStep.tbSharedInfo      = nil
GuideStep.tbAnimEndForcely  = nil
GuideStep.nBeginActionTimeStamp = 0
GuideStep.nEndActionTimeStamp = 0
-----------------------------------------------------

local function IsInLobbyModule(nModuleId)
    return nModuleId == 1 or nModuleId == 2 or nModuleId == 3
end

local function CheckNeedRegisterAnimEndForcely(self, tbTemplate)
    if not tbTemplate then
        return
    end
    local szTriggerType = "GuideTrigger" .. tbTemplate.szTriggerType
    local szWndName = tbTemplate.szOpenUIName
    local tbszAnimName = tbTemplate.tbWidgetName
    if szWndName and tbszAnimName and szTriggerType == ANIM_END_TRGGER_TYPE then
        local szAnimName = tbszAnimName[1]
        self:DebugLog("CheckNeedRegisterAnimEndForcely Anim name = " .. szAnimName)
        UIManager:SetRegisterAnimEndForcelyWithWndName(szWndName, szAnimName)
    end
end

local function LogPreProcess(self, szMsg)
    local szTemp = "[GuideStep] " ..szMsg
    if self.tbTemplate then
        local tbTemplate = self.tbTemplate
        local nGroup = tbTemplate.nGroup
        local nStep = tbTemplate.nStep
        szTemp = szTemp .. " ngroup = ".. tostring(nGroup) .. " nStep = " .. tostring(nStep)
    end
    return szTemp
end

function GuideStep:Init(Owner, tbTemplate)
    self.tbTemplate = tbTemplate
    if not tbTemplate then
        self:LogError("Init error,tbTemplate==nil")
        return
    end
    self:DebugLog("Init")
    self.Owner = Owner
    self.tbGuideTriggers = {}
    self.tbSharedInfo = {}
    self.tbAnimEndForcely = {}
    for k, v in ipairs(tbTemplate.tbTriggerKey)do
        local tbTriggerTemplate = GuideTriggerDataTable:GetTemplate(v)
        if tbTriggerTemplate then
            local szClassName = "GuideTrigger"..tbTriggerTemplate.szTriggerType
            local GuideTriggerClass = require(szClassName)
            local GuideTrigger = GuideTriggerClass()
            CheckNeedRegisterAnimEndForcely(self, tbTriggerTemplate)
            self:DebugLog("InitTrigger TriggerName = " .. szClassName)
            GuideTrigger:Init(self, nil, k, tbTriggerTemplate, tbTemplate, function(nIndex) self:OnTriggerEnd(nIndex) end, function(nIndex) self:OnTriggerBreak(nIndex) end)
            table.insert(self.tbGuideTriggers, GuideTrigger)
        else
            self:LogError("Init error,tbTriggerTemplate==nil,trigger id="..v)
            return
        end
    end

    self.tbGuideActions = {}
    for k, v in ipairs(tbTemplate.tbActionKey)do
        local tbActionTemplate = GuideActionDataTable:GetTemplate(v)
        if tbActionTemplate then
            local GuideActionClass = require("GuideAction" .. tbActionTemplate.szActionType)
            local GuideAction = GuideActionClass()
            self:DebugLog("InitAction ActionName = " .. "GuideAction" .. tbActionTemplate.szActionType)
            GuideAction:Init(self, k, tbActionTemplate, tbTemplate, function(nIndex) self:OnActionEnd(nIndex) end)
            table.insert(self.tbGuideActions, GuideAction)
        else
            self:LogError("guide step init error:action nil,step=" .. tbTemplate.nStep .. " action id=" .. v)
        end
    end
end

function GuideStep:Uninit()
    self:DebugLog("Uninit")
    if self.tbGuideTriggers then
        for i,v in ipairs(self.tbGuideTriggers) do
            v:End()
            v:Uninit()
        end
    end
    self.tbGuideTriggers = nil
    if self.tbGuideActions then
        for i,v in ipairs(self.tbGuideActions) do
            v:End()
            v:Uninit()
        end
    end
    self.tbGuideActions = nil
    self.tbSharedInfo = nil
    self.tbAnimEndForcely = nil
    self.OnStepEndCallBack = nil
end

function GuideStep:BindEndCallBack(OnStepEndCallBack)
    self.OnStepEndCallBack = OnStepEndCallBack
end

function GuideStep:Begin()
    self:DebugLog("Begin")
    self.bBegin = true
    self.bEnded = false
    self.bAllActionEnd = false
    for i,v in ipairs(self.tbGuideTriggers) do
        v:Begin()
    end
end

function GuideStep:End()
    if self.bEnded then
        return
    end
    self:DebugLog("End")
    -- self:SetModuleState()
    self.bBegin = false
    self.bEnded = true
    local tbTemplate = self.tbTemplate
    if self.tbGuideTriggers then
        for i,v in ipairs(self.tbGuideTriggers) do
            v:End()
        end
    end
    if self.tbGuideActions then
        for i,v in ipairs(self.tbGuideActions) do
            v:End()
        end
    end
    EventManager:OnFireEvent(ClientEventDef.EV_UI_GUIDE_END_STEP, tbTemplate.nModuleId, tbTemplate.nGroup, tbTemplate.nStep)
    self.nEndActionTimeStamp = math.floor(KismetSystemLibrary.GetGameTimeInSeconds(GWorld))
    EventManager:OnFireEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_GUIDE_END, string.format("%d%d",tbTemplate.nGroup, tbTemplate.nStep), tbTemplate.szDesc, self.nEndActionTimeStamp-self.nBeginActionTimeStamp)
end

function GuideStep:Interrupt()
    self:DebugLog("Interrupt")
    self.bBegin = false
    self.bEnded = false
    self.bAllActionEnd = false
    if self.tbGuideTriggers then
        for i,v in ipairs(self.tbGuideTriggers) do
            v:Interrupt()
        end
    end
    if self.tbGuideActions then
        for i,v in ipairs(self.tbGuideActions) do
            v:Interrupt()
        end
    end
end

function GuideStep:RestartTrigger()
    self:DebugLog("RestartTrigger")
    for i,v in ipairs(self.tbGuideTriggers) do
        v:Begin()
    end
end

function GuideStep:SetGuideZOrder()
    self:DebugLog("SetGuideZOrder")
    local tbTemplate = self.tbTemplate
    UIManager:CloseWnd(UIDef.UI_GUIDE)
    local Action = self.tbGuideActions[1]
    if not Action then
        self:LogError("SetGuideZOrder none Step in Group, nGroup = " .. tostring(tbTemplate.nGroup))
        return
    end
    local szTargetWndName = Action.tbTemplate.szUIName
    local tbActionTemplate = WndDataTable:GetTemplate(szTargetWndName)
    local nZOrder = 40
    if tbActionTemplate then
        nZOrder = tbActionTemplate.nZOrder 
    end
    --对于新大厅，底部的bottom按钮的层级是一致不变的，相对最高的，所以可定会对浮动层级有影响，所以在此对
    --大厅内的引导（moduleid == 1），进行此步操作，使其总是大于底部的bottom按钮的层级,以后建议在module
    --表里配置
    -- if self.Owner.Owner.nModuleId == 1 then
    if IsInLobbyModule(self.Owner.Owner.nModuleId) then
        local nBottomMenuTemplate = WndDataTable:GetTemplate(UIDef.UI_LOBBY_BOTTOM_MENU)
        if nBottomMenuTemplate then
            local nBottomMenuZOrder = nBottomMenuTemplate.nZOrder
            nZOrder = math.max(nBottomMenuZOrder, nZOrder)
        end
    end
    local tbArgs = {}
    tbArgs.nZOrder = nZOrder + 1
    self:DebugLog("SetGuideZOrder TargetWnd ZOrder = " .. nZOrder .. "New ZOrder = " .. tbArgs.nZOrder)
    local GuideWnd = UIManager:OpenWnd(UIDef.UI_GUIDE, tbArgs)
    local nDelayResponseTime = tbTemplate.nDelayResponseTime
    if nDelayResponseTime then
        EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_DELAY_RESPONSE, nDelayResponseTime)
    end
    if GuideWnd and tbTemplate.bIsModal then
        --重新打开引导UI后，会RestUI，会失去spacescreen，所以在这里打开
        EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_SHOW_SPACE_SCREEN, true)
    end
end

function GuideStep:SetModuleState()
    self:DebugLog("SetModuleState")
    local tbOpenModuleId = self.tbTemplate.tbOpenModuleId
    local ModuleRef = nil
    if tbOpenModuleId then
        local GroupRef = self.Owner
        if GroupRef then
            ModuleRef = GroupRef.Owner
            if ModuleRef then
                ModuleRef:SetHasNextModule(true)
            end
        end
        EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_SET_MODULE, true, tbOpenModuleId)
    end
    local tbEndModuleId = self.tbTemplate.tbEndModuleId
    local tbEndId = {}
    --endmodel不能关闭自己，因为时序会有问题，所以在此去除掉自己的moduleid
    if tbEndModuleId then
        if ModuleRef then
            local nModuleId = ModuleRef.nModuleId
            for i, v in ipairs(tbEndModuleId) do
                if nModuleId ~= v then
                    table.insert(tbEndId, v)
                end
            end
        end
        EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_SET_MODULE, false, tbEndId)
    end
end

function GuideStep:OnTriggerBreak(nIndex)
    self:DebugLog("OnTriggerBreak, nIndex = "..nIndex)
    self:RestartTrigger()
end

function GuideStep:OnTriggerEnd(nIndex)
    self:DebugLog("OnTriggerEnd, nIndex = " .. nIndex)
    local bAllTriggerEnd = true
    for i, v in ipairs(self.tbGuideTriggers)do
        if v.nIndex ~= nIndex and not v:IsTrigger() then
            bAllTriggerEnd = false
        end        
    end
    self.bAllTriggerEnd = bAllTriggerEnd
    if bAllTriggerEnd then
        self:DebugLog("All Triggers End")
        for k,v in ipairs(self.tbGuideTriggers)do
            v:End()
        end
        if self.tbTemplate.nStep == 1 then  --由于group有触发后排队的机制，所以需要在这里特殊处理一下，第一步应该先通知module开始
            self:DebugLog("step == 1 Send to Group !")
            self.Owner:GroupReadyToStart()
        else
            self:BeginAction()
        end
    end
end

function GuideStep:ForceBeginStep()
    self:DebugLog("ForceBeginStep")
    self.bAllTriggerEnd = true
    for k,v in ipairs(self.tbGuideTriggers)do
        v:End()
    end
    self:BeginAction()
end

function GuideStep:BeginAction()
    self:DebugLog("BeginAction")
    --一个Group的第一步不需要在trigger触发时就将UI模态住
    --应该在被触发后再去控制UI
    if self.tbTemplate.nStep == 1 then
        self:SetGuideZOrder()
    end
    local tbTemplate = self.tbTemplate
    EventManager:OnFireEvent(ClientEventDef.EV_UI_GUIDE_BEGIN_STEP, tbTemplate.nModuleId, tbTemplate.nGroup, tbTemplate.nStep)
    self.nBeginActionTimeStamp = math.floor(KismetSystemLibrary.GetGameTimeInSeconds(GWorld))
    for k, v in ipairs(self.tbGuideActions)do
        self:DebugLog("k="..k.." action key="..v.tbTemplate.szKey)
        if not self.bAllActionEnd and not v:IsEnded() then
            v:Begin()
        end
    end
end

function GuideStep:OnStepEnd(nGroup, nStep)
    if self.OnStepEndCallBack then
        self.OnStepEndCallBack(self.tbTemplate.nGroup, self.tbTemplate.nStep)
        self.OnStepEndCallBack = nil
    end
    self:SetModuleState()
end

function GuideStep:OnActionEnd(nIndex)
    self:DebugLog("OnActionEnd nIndex = " .. nIndex)
    if self.bAllActionEnd then
        return
    end
    local tbGuideActions = self.tbGuideActions
    local pAction = tbGuideActions[nIndex]
    if pAction then
        pAction:End()
    end
    for i,v in ipairs(tbGuideActions) do
        if not v:IsEnded() then
            return
        end
    end
    self.bAllActionEnd = true
    self:DebugLog("OnActionEnd All Actions End")
    self.bBegin = false
    local tbTemplate = self.tbTemplate
    self:OnStepEnd(tbTemplate.nGroup, tbTemplate.nStep)
end

function GuideStep:IsAllTriggerEnd()
    return self.bAllTriggerEnd and self.bBegin
end

function GuideStep:IsAllActionEnd()
    return self.bAllActionEnd
end

function GuideStep:SetSharedInfo(szKey, value)
    self:DebugLog("SetSharedInfo")
    local tbSharedInfo  = self.tbSharedInfo
    if not tbSharedInfo then
        self:LogError("tbSharedInfo is nil!")  
        return
    end
    tbSharedInfo[szKey] = value
end

function GuideStep:GetSharedInfo(szKey)
    self:DebugLog("GetSharedInfo")
    local tbSharedInfo  = self.tbSharedInfo
    if not tbSharedInfo then
        self:LogError("tbSharedInfo is nil!")  
        return nil
    end
    return tbSharedInfo[szKey]
end

function GuideStep:ForceEnd()
    self:DebugLog("ForceEnd")
    if self.tbGuideTriggers then
        for i,v in ipairs(self.tbGuideTriggers) do
            v:End()
        end
    end
    if self.tbGuideActions then
        for i,v in ipairs(self.tbGuideActions) do
            if not v:IsEnded() then
                v:End()
            end
        end
    end
    local tbTemplate = self.tbTemplate
    self:OnStepEnd(tbTemplate.nGroup, tbTemplate.nStep)
end

function GuideStep:DebugLog(szMsg)
    szMsg = LogPreProcess(self, szMsg)
    GuideDebug:DebugLog(szMsg)
end

function GuideStep:Log(szMsg)
    szMsg = LogPreProcess(self, szMsg)
    GuideDebug:Log(szMsg)
end

function GuideStep:LogError(szMsg)
    szMsg = LogPreProcess(self, szMsg)
    GuideDebug:LogError(szMsg)
end

return GuideStep