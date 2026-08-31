-----------------------------------------------------
--File Name    : GuideStep.lua
--Author       : Edward J
--Create Time  : 2019-05-08
--Description  : 新手指引步骤
-----------------------------------------------------
local luaclass      = require("luaclass")
local GuideStep     = require("GuideStep")
local GuideGroup    = luaclass("GuideGroup")

local GuideDebug            = require("GuideDebug")
local SaveGameDef           = require("SaveGameDef")
local UIManager             = require("UIManager")
local UIDef                 = require("UIDef")
local DelayTimer            = require("DelayTimer")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local EventManager          = require("EventManager")
local ClientEventDef        = require("ClientEventDef")
-----------------------------------------------------
--member veriable

GuideGroup.tbGroupSteps     = nil
GuideGroup.tbSteps          = nil
GuideGroup.tbCurrentStep    = nil
GuideGroup.OnStart          = nil
GuideGroup.OnEnd            = nil
GuideGroup.Owner            = nil
GuideGroup.tbSharedInfo     = nil
GuideGroup.RestartTimer     = nil
GuideGroup.bInQueue         = false
GuideGroup.bInterrupt       = false
GuideGroup.bRunning         = false
GuideGroup.nAlwaysTrigger   = 1
GuideGroup.nCurrentStep     = 1
GuideGroup.nGroupId         = 0
GuideGroup.nStepCount       = 0
GuideGroup.nGuideType       = 0
GuideGroup.tbInterruptIds   = nil
-----------------------------------------------------

local function LogPreProcess(self, szMsg)
    local szTemp = ""
    szTemp = "[GuideGroup]" .. szMsg .. " ngroup = ".. tostring(self.nGroupId)
    return szTemp
end

local function ClearRestartTiemr(self)
    self:DebugLog("ClearRestartTiemr")
    if self.RestartTimer then
        DelayTimer:ClearTimer(self.RestartTimer)
        self.RestartTimer = nil
    end
end

function GuideGroup:Init(Owner, nGroupId, tbSteps)
    self.nGroupId = nGroupId
    self:DebugLog("Init")
    --取第一个step作为整个group的trigger
    --初始化group中的所有step
    self.Owner          = Owner
    self.tbGroupSteps   = {}
    self.tbSharedInfo   = {}
    self.tbInterruptIds = {}
    local tbGroupSteps = self.tbGroupSteps
    local nStepCount = 0
    for nStep, tbStepTemplate in ipairs(tbSteps) do
        local CurrentStep = GuideStep()
        if nStep == 1 then
            local nAlwaysTrigger = tbStepTemplate.nAlwaysTrigger
            self.nAlwaysTrigger = nAlwaysTrigger
            if nAlwaysTrigger > 1 then
                Owner:SetHasAlwaysTriggerGroup(true)
            end
            local nGuideType = tbStepTemplate.nGuideType
            local bInterrupt = tbStepTemplate.bInterrupt
            self.nGuideType = nGuideType
            self.bInterrupt = bInterrupt
            local bInQueue = tbStepTemplate.bInQueue
            self.bInQueue = bInQueue
        end
        CurrentStep:Init(self, tbStepTemplate)
        tbGroupSteps[nStep] = CurrentStep
        CurrentStep:BindEndCallBack(function(nEndGroup, nEndStep) self:OnStepEnd(nEndGroup, nEndStep)end)
        nStepCount = nStepCount + 1
    end
    self.nStepCount = nStepCount
    self.tbSteps = tbSteps
    self.bRunning = false
end

function GuideGroup:Uninit()
    self:DebugLog("Uninit")
    ClearRestartTiemr(self)
    local tbGroupSteps = self.tbGroupSteps
    if tbGroupSteps then
        for k,v in ipairs(tbGroupSteps)do
            v:Uninit()
        end
    end
    self.tbGroupSteps = nil
    self.tbSteps = nil
    self.tbCurrentStep = nil
    self.OnStart = nil
    self.OnEnd = nil
    self.tbSharedInfo = nil
    self.tbInterruptIds = nil
end

function GuideGroup:Begin()
    self:DebugLog("Begin")
    self:BeginStep(1)
end

function GuideGroup:End()
    self:DebugLog("End")
    self.bRunning = false
    local tbGroupSteps = self.tbGroupSteps
    if tbGroupSteps then
        for k,v in ipairs(tbGroupSteps)do
            v:End()
        end
    end
end

function GuideGroup:Interrupt()
    self:DebugLog("Interrupt")      
    self.bRunning = false
    local tbGroupSteps = self.tbGroupSteps
    if tbGroupSteps then
        for k,v in ipairs(tbGroupSteps)do
            v:Interrupt()
        end
    end
    local tbCurrentStep = tbGroupSteps[1]
    self.nCurrentStep = 1
    self:Restart(tbCurrentStep)
    self.tbCurrentStep = tbCurrentStep
    UIManager:CloseWnd(UIDef.UI_GUIDE)
end

function GuideGroup:SetBeInterruptByThisGroup(nGroupId)
    self:DebugLog("SetBeInterruptByThisGroup")
    if not nGroupId then
        return
    end
    self.tbInterruptIds[nGroupId] = true
end

function GuideGroup:CheckBeInterruptByThisGroup(nGroupId)
    self:DebugLog("CheckBeInterruptByThisGroup")
    if not nGroupId then
        return
    end
    if self.tbInterruptIds[nGroupId] then
        return true
    end
    return false
end

--一个开关，用于是否将此group的状态记录到服务器中。场景：当玩家没有点击一个引导，由于切换场景而强制结束了此引导，但又想让玩家下次上线时还能触发次引导
function GuideGroup:ForceEnd(bEnableEnd)
    self:DebugLog("ForceEnd bEnableEnd = " .. tostring(bEnableEnd))
    local bEnable = bEnableEnd
    local nSelfPlayerId = GamePlayerSelfHelper:Get().nPlayerId
    if bEnable then
        local nAlwaysTrigger = self.nAlwaysTrigger
        self:DebugLog("nAlwaysTrigger:" .. tostring(nAlwaysTrigger))
        local nModuleId = self.Owner.nModuleId
        local GuideSystem = self.Owner.Owner
        local szSaveKey = string.format( "%d_%s_%d_%d",nSelfPlayerId, SaveGameDef.GUIDE_REPEAT_MAX_TIME_PREFIX, nModuleId, self.nGroupId)
        local nRecordMaxTimes = GuideSystem:GetAllwaysTriggerCountWithDefault(szSaveKey, nAlwaysTrigger)
        self:DebugLog("=============================ForceEnd " .. nRecordMaxTimes)
        nRecordMaxTimes = nRecordMaxTimes - 1
        if nRecordMaxTimes > 0  then
            bEnable = false
            GuideSystem:SetAllwaysTriggerCount(szSaveKey, nRecordMaxTimes)
        else
            GuideSystem:ClearAllwaysTriggerCount(szSaveKey)
        end
    end
    local tbGroupSteps = self.tbGroupSteps
    if tbGroupSteps then
        for k,v in ipairs(tbGroupSteps)do
            v:End()
        end
    end
    self:OnGroupEnd(self.nGroupId, bEnable)
end

function GuideGroup:GetStep(nStepId)
    self:DebugLog("GetStep nStepId = " .. nStepId)
    local tbGroupSteps = self.tbGroupSteps
    if not tbGroupSteps then
        return nil
    end
    return tbGroupSteps[nStepId]
end

--开始一个step
function GuideGroup:BeginStep(nStep)
    self:DebugLog("BeginStep nStep = " .. tostring(nStep))
    local tbGroupSteps = self.tbGroupSteps
    if nStep > self.nStepCount then
        self:End()
        return
    end
    if tbGroupSteps[nStep].bSkip then
        self:DebugLog("BeginStep SKIP nStep = " .. tostring(nStep))
        self:OnStepEnd(self.nGroupId, nStep)
        return
    end
    --Group的第一步更像是一个Trigger
    --应当是第一步满足需求时，由step在begin action时对UI进行设置
    if nStep ~= 1 then
        tbGroupSteps[nStep]:SetGuideZOrder()
    end
    self.tbCurrentStep = tbGroupSteps[nStep]
    tbGroupSteps[nStep]:Begin()
end

function GuideGroup:Restart(tbStep)
    self:DebugLog("Restart")
    ClearRestartTiemr(self)
    --此做法是为了避免当有两组group的触发条件一样时，造成卡死。比如两个group的触发条件都是出现载具按钮，只要一个group没结束，另一个group会不停的进行restart
    local tbTargetStep = tbStep and tbStep or self.tbCurrentStep
    self.RestartTimer = DelayTimer:DelayRun(function() 
        if tbTargetStep then
            tbTargetStep:RestartTrigger()
        end
    end ,2)
end

function GuideGroup:SkipStep(nStep)
    self:DebugLog("SkipStep nStep = " .. nStep)
    local tbGroupSteps = self.tbGroupSteps
    if not tbGroupSteps or not tbGroupSteps[nStep] then
        return
    end
    tbGroupSteps[nStep].bSkip = true
end

function GuideGroup:OnGroupEnd(nGroupId, bEndEnable)
    if self.OnEnd then
        self:DebugLog(" Notify Module GroupEnd")
        self.OnEnd(self, nGroupId, bEndEnable)
    end
end

--当一个step完成时的回调
function GuideGroup:OnStepEnd(nEndGroup, nEndStep)
    self:DebugLog("OnStepEnd nGroup = " .. nEndGroup .. " nStep = " .. nEndStep)
    if nEndGroup ~= self.nGroupId then
        return
    end
    self.nCurrentStep = nEndStep + 1
    local nCurrentStep = self.nCurrentStep
    local nSelfPlayerId = GamePlayerSelfHelper:Get().nPlayerId
    local tbGroupSteps = self.tbGroupSteps
    if nCurrentStep > #self.tbGroupSteps then
        self:DebugLog(" All Step Finish")
        local nAlwaysTrigger = self.nAlwaysTrigger
        self:DebugLog("nAlwaysTrigger:" .. tostring(nAlwaysTrigger))
        local nModuleId = self.Owner.nModuleId
        local GuideSystem = self.Owner.Owner
        self:DebugLog("============================= " .. tostring(nModuleId) .. " groupId = " .. tostring(self.nGroupId))
        local szSaveKey = string.format( "%d_%s_%d_%d",nSelfPlayerId, SaveGameDef.GUIDE_REPEAT_MAX_TIME_PREFIX, nModuleId, self.nGroupId)
        local nRecordMaxTimes = GuideSystem:GetAllwaysTriggerCountWithDefault(szSaveKey, nAlwaysTrigger)
        self:DebugLog("=============================" .. nRecordMaxTimes)
        nRecordMaxTimes = nRecordMaxTimes - 1
        local bEndEnable = false
        if nRecordMaxTimes <= 0  then
            bEndEnable = true
            GuideSystem:ClearAllwaysTriggerCount(szSaveKey)
        else
            GuideSystem:SetAllwaysTriggerCount(szSaveKey, nRecordMaxTimes)
        end
        self:OnGroupEnd(self.nGroupId, bEndEnable)
        return
    else
        local pStep = tbGroupSteps[nEndStep]
        if pStep then
            pStep:End()
        end
    end
    self:BeginStep(nCurrentStep)
end

function GuideGroup:StartSteps()
    self:DebugLog("StartSteps")
    self.bRunning = true
    local pCurrentStep = self.tbCurrentStep
    pCurrentStep:SetGuideZOrder()
    pCurrentStep:BeginAction()
end

function GuideGroup:UIGuideShowSpaceScreen(bShow)
    local GuideWnd = UIManager:GetWnd(UIDef.UI_GUIDE)
    if GuideWnd then
        EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_SHOW_SPACE_SCREEN, bShow)
    end
end

function GuideGroup:GroupReadyToStart()
    self:DebugLog("GroupReadyToStart ")
    self.OnStart(self, self.nGroupId)
end

function GuideGroup:BindStartCallBack(StartCallBack)
    self.OnStart = StartCallBack
end

function GuideGroup:BindEndCallBack(EndCallBack)
    self.OnEnd = EndCallBack
end

function GuideGroup:SetSharedInfo(szKey, value)
    self:DebugLog("SetSharedInfo")
    local tbSharedInfo  = self.tbSharedInfo
    if not tbSharedInfo then
        self:LogError("tbSharedInfo is nil!")  
        return
    end
    tbSharedInfo[szKey] = value
end

function GuideGroup:GetSharedInfo(szKey)
    self:DebugLog("GetSharedInfo")
    local tbSharedInfo  = self.tbSharedInfo
    if not tbSharedInfo then
        self:LogError("tbSharedInfo is nil!")  
        return nil
    end
    return tbSharedInfo[szKey]
end

function GuideGroup:SetModuleSharedInfo(szKey, value)
    self:DebugLog("SetModuleSharedInfo")
    if not self.Owner then
        return
    end
    self.Owner:SetSharedInfo(szKey, value)
end

function GuideGroup:GetModuleSharedInfo(szKey)
    self:DebugLog("GetModuleSharedInfo")
    if not self.Owner then
        return
    end
    return self.Owner:GetSharedInfo(szKey)
end

function GuideGroup:DebugLog(szMsg)
    szMsg = LogPreProcess(self, szMsg)
    GuideDebug:DebugLog(szMsg)
end

function GuideGroup:Log(szMsg)
    szMsg = LogPreProcess(self, szMsg)
    GuideDebug:Log(szMsg)
end

function GuideGroup:LogError(szMsg)
    szMsg = LogPreProcess(self, szMsg)
    GuideDebug:LogError(szMsg)
end

return GuideGroup
