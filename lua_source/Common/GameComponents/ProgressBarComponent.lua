local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local ProgressBarComponent = luaclass("ProgressBarComponent", GameComponentBase)

local Timer = require("Timer")
local PropName = require("PropName")
local ProgressBarTableNew = require("ProgressBarTableNew")
local ProgressBarAbortEventReciever = require("ProgressBarAbortEventReciever")
local ProhibitType = require("ProhibitTypeDefine")
local ProgressBarProhibitTable = require("ProgressBarProhibitTable")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local D2CHelper = require("D2CHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleHumanWeaponSystemNew = dynamic_require("BattleHumanWeaponSystemNew")
local AIHelper = require("AIHelper")
local HumanMovementStateType = require("HumanMovementStateType")
local ProgressBarStateType = require("ProgressBarStateType")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

ProgressBarComponent.ProgressBarTimer = nil
ProgressBarComponent.EventReciever = nil
ProgressBarComponent.fnOnFinished = nil
ProgressBarComponent.fnOnAborted = nil
ProgressBarComponent.tbParams = nil
ProgressBarComponent.rProgressBar = nil
ProgressBarComponent.nHoldWeapon = nil
ProgressBarComponent.nTemplateId = nil
ProgressBarComponent.tbProgressBar = nil
ProgressBarComponent.nBuffIdInProgress = -1

local NO_PROGRESSBAR = 0
local tbProhibitTypeToKey = {
    [ProhibitType.LEFT_RIGHT_SIDE] = "bLeftRightSide",
    [ProhibitType.CRAWL] = "bCrawl",
    [ProhibitType.ANIMATION] = "bAnimation",
}

local tbAbortByMovementStateType = {
    [HumanMovementStateType.UpRight_State] = 1,
    [HumanMovementStateType.Crouch_State] = 10,
    [HumanMovementStateType.Crawl_State] = 100,
    [HumanMovementStateType.Swimming] = 1000
}

local tbInitProgressBar = {}
tbInitProgressBar.nTemplateId = NO_PROGRESSBAR
tbInitProgressBar.nTime  = NO_PROGRESSBAR
tbInitProgressBar.nState = ProgressBarStateType.None

local function AddBuffInProgress(self, tbProgressBarTable)
    local nBuffIdInProgress = -1
    if self.Owner:IsShip() then
        nBuffIdInProgress = tbProgressBarTable.nShipBuffId
    elseif self.Owner.HumanMovementStateComponent and self.Owner.HumanMovementStateComponent:IsInVehicle() then
        nBuffIdInProgress = tbProgressBarTable.nVehicleBuffId
    else
        nBuffIdInProgress = tbProgressBarTable.nHumanBuffId
    end
    if nBuffIdInProgress > 0 then
        self.Owner.BuffComponentServer:AddBuffWithInstigator(self.Owner, nBuffIdInProgress)
    end
    self.nBuffIdInProgress = nBuffIdInProgress
end

local function RemoveBuffInProgress(self)
    if self.nBuffIdInProgress > 0 then
        self.Owner.BuffComponentServer:RemoveBuffById(self.nBuffIdInProgress)
    end
    self.nBuffIdInProgress = -1
end

function ProgressBarComponent:OnActorCreated(pUEActor)
    ProgressBarComponent.super.OnActorCreated(self, pUEActor)

    local rComponent = self.Owner.CustomReplicationComponent
    self.rProgressBar = rComponent:BindMethod(PropName.ProgressBar,
        tbInitProgressBar, self, self.OnProgressBarChanged, false)
end

function ProgressBarComponent:ClearProgressBarInfo()
    self.fnOnFinished = nil
    self.fnOnAborted = nil
    self.tbParams = nil
    if not GlobalVariableSystem:IsStandaloneServer() then
        self.nHoldWeapon = nil
    end
    self.nTemplateId = nil
end

function ProgressBarComponent:ClearProgressBar(bDestroyed, nState)
    RemoveBuffInProgress(self)
    -- bDestroyed时候走过来会报错，因为生命周期WithGameObject改为WithUEActor所以Set方法会报错
    if self.rProgressBar and self.rProgressBar.Set and not bDestroyed then
        local tbProgressBar = self.rProgressBar:Get()
        if tbProgressBar then
            local tbTemp = {}
            tbTemp.nTemplateId = tbProgressBar.nTemplateId
            tbTemp.nTime = tbProgressBar.nCDTime
            tbTemp.nState = nState
            self.rProgressBar:Set(tbTemp)
        else
            self.rProgressBar:Set(tbInitProgressBar)
        end
    end

    if self.EventReciever and self.EventReciever.Uninit then
        self.EventReciever:Uninit()
    end

    if self.ProgressBarTimer then
        self.ProgressBarTimer:Clear()
        self.ProgressBarTimer = nil
    end
end

function ProgressBarComponent:OnActorDestroyed(pUEActor)
    ProgressBarComponent.super.OnActorDestroyed(self, pUEActor)
    if GlobalVariableSystem:IsServerLogic() then
        self:Abort(true)
    else
        self:ClearProgressBar(true, ProgressBarStateType.Finish)
    end
end

function ProgressBarComponent:RegisterAbortEvent(tbProgressBarTable, bHumanCrawlToCrouch, bIngoreMove)
    self.EventReciever = ProgressBarAbortEventReciever()
    self.EventReciever:Init(self, tbProgressBarTable, bHumanCrawlToCrouch, bIngoreMove)
end

function ProgressBarComponent:GetTime(nTemplateId)
    local tbProgressBarTable = ProgressBarTableNew:GetTemplate(nTemplateId)
    if tbProgressBarTable then
        return tbProgressBarTable.nTime
    end
    return nil
end

function ProgressBarComponent:GetCurrentTemplateId()
    if self:IsProgressing() then
        local tbProgressBar = self.rProgressBar:Get()
        return tbProgressBar.nTemplateId
    else
        return NO_PROGRESSBAR
    end
end

-- 同种读条不能重复触发
function ProgressBarComponent:Start(nTemplateId, tbParams, fnOnFinished, fnOnAborted, nNewTime)
    local tbProgressBarTable = ProgressBarTableNew:GetTemplate(nTemplateId)
    if tbProgressBarTable then
        local Owner = self.Owner
        if Owner:IsDying() and (not tbProgressBarTable.bStartInDying) then
            log("ProgressBarComponent:Start is dying ", self.Owner.nServerInstanceId)
            D2CHelper:NotifyProgressBarStartFailed(Owner) -- 暂时只有一种原因，保留了nFailedReasonId参数可扩展
            return false
        end
        if Owner:IsShip() and (not tbProgressBarTable.bStartInShipFiring) then
            local ActiveWeapon = BattleShipWeaponSystem:GetActiveWeaponItem(Owner)
            if ActiveWeapon and ActiveWeapon:IsInFiring() then
                return false
            end
        end
        if Owner:IsDead() then
            log("ProgressBarComponent:Start is dead ", self.Owner.nServerInstanceId)
            return false
        end

        if self:IsProgressing() and self.nTemplateId == nTemplateId then
            log("ProgressBarComponent:Start is same templateid ", self.Owner.nServerInstanceId)
            return false
        end

        if self.fnOnAborted then
            self.fnOnAborted(self.tbParams)
        end
        self:ClearProgressBar(false, ProgressBarStateType.None)
        self:ClearProgressBarInfo()

        self.nTemplateId = nTemplateId
        self.fnOnFinished = fnOnFinished
        self.fnOnAborted = fnOnAborted
        self.tbParams = tbParams

        local bIgnoreAbortByMove = tbProgressBarTable.bIgnoreAbortByMove
        local HumanMovementStateComponent = Owner.HumanMovementStateComponent
        if HumanMovementStateComponent then
            bIgnoreAbortByMove = not self:CheckNeedAbortByMove(tbProgressBarTable, HumanMovementStateComponent:GetCurrentState())
        end
        if not bIgnoreAbortByMove then
            if Owner:IsHuman() and Owner.GameVehicleComponent then
                if Owner.GameVehicleComponent:IsInVehicle() then
                    local tbVehicle = Owner.GameVehicleComponent:GetVehicle()
                    if tbVehicle then
                        tbVehicle:StopMove(tbProgressBarTable.bStopMoveImmediately)
                    end
                end
            end
            Owner:StopMove(tbProgressBarTable.bStopMoveImmediately)
        end
        if Owner:IsHuman() and AIHelper.IsAIControlled(Owner) and not GlobalVariableSystem:IsStandaloneServer() then
            if HumanMovementStateComponent:GetCurrentState() ~= HumanMovementStateType.Dying_State then
                local HumanWeaponComponent = Owner.HumanWeaponComponent
                self.nHoldWeapon = HumanWeaponComponent:GetCurrentWeaponInstanceId()
                -- 先存，这个为了变船处理的
                BattleHumanWeaponSystemNew:SaveCurrentWeaponToOwner(Owner)
                -- 具体cancelattack的操作客户端自己处理
                BattleHumanWeaponSystemNew:SetCurrentWeapon(Owner, 0)
            end
        end

        AddBuffInProgress(self, tbProgressBarTable)

        self:RegisterAbortEvent(tbProgressBarTable, tbProgressBarTable.bHumanCrawlToCrouch, tbProgressBarTable.bIgnoreAbortByMove)

        local nCDTime = tbProgressBarTable.nTime
        if nNewTime and nNewTime > 0 then
            nCDTime = nNewTime
        end
        local tbProgressBar = {}
        tbProgressBar.nTemplateId = nTemplateId
        tbProgressBar.nTime = nCDTime
        tbProgressBar.nState = ProgressBarStateType.Start
        self.rProgressBar:Set(tbProgressBar)
        self.ProgressBarTimer = Timer.NewTimerMethod(self, self.Finish, nCDTime, false)
        local nInstanceId = self.Owner:GetServerInstanceId()
        log("[Progressbar] Start", nInstanceId, nTemplateId, nCDTime)
        EventManager:OnFireEvent(CommonEventDef.EV_PROGRESS_CHANGED, nInstanceId, true, nTemplateId, nCDTime)
        return true
    else
        logerror("ProgressBarTableNew GetTemplate Error. nTemplateId:", nTemplateId)
    end
    return false
end

local function ReholdAILastWeapon(self)
    if GlobalVariableSystem:IsStandaloneServer() then
        return
    end
    local nHoldWeapon = self.nHoldWeapon
    if self.Owner:IsHuman() and nHoldWeapon and nHoldWeapon ~= 0 then
        local HumanWeaponComponent = self.Owner.HumanWeaponComponent
        HumanWeaponComponent:SetCurrentWeapon(nHoldWeapon)
    end
end

function ProgressBarComponent:Abort(bDestroy)
    if self:IsStarted() then
        local tbProgressBar = self.rProgressBar:Get()
        local nInstanceId = self.Owner:GetServerInstanceId()
        log("[Progressbar] Abort", nInstanceId, tbProgressBar.nTemplateId)
        self:ClearProgressBar(bDestroy, bDestroy and ProgressBarStateType.Finish or ProgressBarStateType.Abort)
        ReholdAILastWeapon(self)
        if self.fnOnAborted then
            self.fnOnAborted(self.tbParams)
        end
        self:ClearProgressBarInfo()
        EventManager:OnFireEvent(CommonEventDef.EV_PROGRESS_CHANGED, nInstanceId, false, tbProgressBar.nTemplateId, tbProgressBar.nTime)
    end
end

function ProgressBarComponent:Finish()
    local tbProgressBar = self.rProgressBar:Get()
    local nInstanceId = self.Owner:GetServerInstanceId()
    log("[Progressbar] Finish", nInstanceId, tbProgressBar.nTemplateId)
    self:ClearProgressBar(false, ProgressBarStateType.Finish)
    ReholdAILastWeapon(self)
    if self.fnOnFinished then
        self.fnOnFinished(self.tbParams)
    end
    self:ClearProgressBarInfo()
    EventManager:OnFireEvent(CommonEventDef.EV_PROGRESS_CHANGED, nInstanceId, false, tbProgressBar.nTemplateId, tbProgressBar.nTime)
end

function ProgressBarComponent:OnProgressBarChanged(_Property, tbNewProgressBar)
    if tbNewProgressBar then
        log("OnProgressBarChanged", t2s(tbNewProgressBar))
    end
end

function ProgressBarComponent:IsProgressing()
    local tbProgressBar = self.rProgressBar:Get()
    if tbProgressBar ~= nil and tbProgressBar.nTemplateId ~= nil
        and tbProgressBar.nTemplateId ~= NO_PROGRESSBAR and tbProgressBar.nState == ProgressBarStateType.Start then
        return true
    end
    return false
end

function ProgressBarComponent:IsStarted()
    return self.ProgressBarTimer ~= nil
end

function ProgressBarComponent:IsProhibit(nProhibitType)
    -- local tbProgressBar = self.rProgressBar:Get()
    -- if tbProgressBar == nil or tbProgressBar.nTemplateId == nil then
    --     return false
    -- end
    -- local nProgressBarId = tbProgressBar.nTemplateId
    -- if nProgressBarId ~= NO_PROGRESSBAR then
    if self:IsProgressing() then
        local tbProgressBar = self.rProgressBar:Get()
        local nProgressBarId = tbProgressBar.nTemplateId
        local tbProgressBarTable = ProgressBarTableNew:GetTemplate(nProgressBarId)
        if tbProgressBarTable then
            local nProhibitId
            if self.Owner:IsShip() then
                nProhibitId = tbProgressBarTable.nShipProhibitId
            else
                nProhibitId = tbProgressBarTable.nHumanProhibitId
            end
            local tbProhibitTable = ProgressBarProhibitTable:GetTemplate(nProhibitId)
            local sztbProhibitKey = tbProhibitTypeToKey[nProhibitType]
            if tbProhibitTable then
                if sztbProhibitKey and tbProhibitTable[sztbProhibitKey] then
                    return true
                end
            else
                logerror("ProgressBarProhibitTable:GetTemplate Error. nProhibitId:", nProhibitId)
            end
        else
            logerror("ProgressBarTableNew:GetTemplate Error. nProgressBarId:", nProgressBarId)
        end
    end
    return false
end

function ProgressBarComponent:CheckNeedAbortByMove(tbProgressBarTable, nMovementState)
    if tbProgressBarTable.bIgnoreAbortByMove then
        return false
    end
    local nAbortType = tbProgressBarTable.nAbortByMovementType
    if nAbortType == 0 then
        return false
    end
    if nMovementState == HumanMovementStateType.Vehicle then
        nMovementState = HumanMovementStateType.UpRight_State
    end
    local nAbortMod = tbAbortByMovementStateType[nMovementState]
    if not nAbortMod then
        return false
    end
    nAbortType = nAbortType % (nAbortMod * 10) / nAbortMod
    return nAbortType >= 1
end

return ProgressBarComponent