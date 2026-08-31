local luaclass = require("luaclass")
local HumanWeaponBase = luaclass("HumanWeaponBase")

local HumanWeaponHelper = require("HumanWeaponHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local PropName = require("PropName")
local DungeonIni = require("DungeonIni")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local HumanWeaponStateDef = require("HumanWeaponStateDef")

local CHECK_COUNT_LIMIT = DungeonIni.tbCheaterCheck.nCheckCountLimit

HumanWeaponBase.REP_PROPERTY_CLEAR_TIME = 1
HumanWeaponBase.EMPTY_TABLE = {}

HumanWeaponBase.nTemplateId = nil
HumanWeaponBase.nSlot = nil
HumanWeaponBase.nInstanceId = nil
HumanWeaponBase.OwnerComponent = nil
HumanWeaponBase.bAiming = false
HumanWeaponBase.nRemainAmmo = nil
HumanWeaponBase.nMaxAmmo = nil
HumanWeaponBase.bServer = false
HumanWeaponBase.bStantalone = false
HumanWeaponBase.tbProperty = nil
HumanWeaponBase.tbBaseProperty = nil
HumanWeaponBase.ReloadTimer = nil
HumanWeaponBase.tbAttachments = nil
HumanWeaponBase.Owner = nil
HumanWeaponBase.pOwnerActor = nil
HumanWeaponBase.tbBPInfo = nil
HumanWeaponBase.rHumanAttackSubState = nil
HumanWeaponBase.nLastAttackTime = nil
HumanWeaponBase.OwnerPropertyComponent = nil
HumanWeaponBase.tbIllegalAttackCount = {}

function HumanWeaponBase:OnCreated(OwnerComponent, nInstanceId, nTemplateId, nSlot)
    self.OwnerComponent = OwnerComponent
    self.Owner = OwnerComponent.Owner
    self.OwnerPropertyComponent = OwnerComponent.Owner.HumanBattlePropertyComponent
    self.nTemplateId = nTemplateId
    self.nSlot = nSlot
    self.nInstanceId = nInstanceId
    self.bServer = GlobalVariableSystem:IsServerLogic()
    self.bStantalone = GlobalVariableSystem:IsStandaloneServer()
    self.bClient = GlobalVariableSystem:IsClient()
    self.pOwnerActor = OwnerComponent.Owner.pUEActor
    self.rHumanAttackSubState = OwnerComponent.rHumanAttackSubState

    self.tbBPInfo = HumanWeaponHelper.GetWeaponBPInfo(nSlot, nTemplateId)

    self.nLastAttackTime = ExtendBlueprintFunctions:GetPlatformMilliseconds()
    assert(self.tbBPInfo)    
end

function HumanWeaponBase:OnDestroyed()
end

function HumanWeaponBase:OnServerHolded()
end

function HumanWeaponBase:OnServerUnHolded()
end
-- 当前武器如果是自己则触发activate
-- function HumanWeaponBase:OnActivate()
-- end

-- function HumanWeaponBase:OnDeactivate()
-- end

function HumanWeaponBase:CreateWeaponProperty()
    self.tbProperty, self.tbBaseProperty = HumanWeaponHelper.CreateCommonWeaponProperty(self.nTemplateId)
    if(self.tbAttachments) then
        self:UpdateAttachments(self.tbAttachments)
    end
    return self.tbProperty
end

function HumanWeaponBase:UpdateAttachments(tbAttachments)
    if(self.tbProperty) then
        HumanWeaponHelper.UpdatePropertyWithAttachments(self.tbProperty, self.tbBaseProperty, tbAttachments)
    else
        self.tbAttachments = tbAttachments
    end
end

function HumanWeaponBase:GetInstanceId()
    return self.nInstanceId
end

function HumanWeaponBase:GetTemplateId()
    return self.nTemplateId
end

function HumanWeaponBase:GetSlot()
    return self.nSlot
end

function HumanWeaponBase:GetOwner()
    return self.Owner
end

function HumanWeaponBase:GetOwnerComponent()
    return self.OwnerComponent
end

function HumanWeaponBase:GetType()
    -- 必须实现，参照HumanWeaponMisc.Type
    assert(false)
    return nil
end

function HumanWeaponBase:IsType(nType)
    return self:GetType() & nType ~= 0
end

function HumanWeaponBase:GetProperty()
    local tbProperty = self.tbProperty
    if(tbProperty == nil) then
        self:CreateWeaponProperty()
        tbProperty = self.tbProperty
    end
    return tbProperty
end

function HumanWeaponBase:GetRepAttackSubState()
    return self.rHumanAttackSubState:Get()
end

function HumanWeaponBase:SetRepAttackSubState(nState)
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_SUB_STATE_CHANGE, self:GetInstanceId(), self.Owner:GetServerInstanceId(), nState)
    return self.rHumanAttackSubState:Set(nState)
end

-- 这函数本来是放到客户端的，为了不让每武器都继承个_C放这了
function HumanWeaponBase:GenerateAttackInfo()
    --[[
    函数AddSubState参数：
    tbAttackInfo  = {
        nCD = float,                -- 可选，下次在进入Attacking状态所需要的时间
        nExitTypeWhenFinish,        -- 可选，当外部finish时如何退出Attacking状态，type定义参考HumanWeaponAttackHelper.ExitType
        nAllLoopCount,              -- 可选，所有子状态的循环次数，-1无限循环，>0则会循环指定次数，注意：此变量会在子状态都执行完后进行修改
    },
    tbSubStateInfo = {
        OnActivate,                 -- 可选，状态激活时触发
        OnDeactivate,               -- 可选，状态结束时触发
        nDuration,                  -- 可选，状态持续时间，小于0或者nil时状态不会停止，等于0时状态激活后立即结束
        bCanDeactivateExternally,   -- 可选，当外部finish时可以deactivate当前子状态
    },

    OnFinished(tbWeapon, bCancel) 结束时会回掉回来
]]
    return nil
end

-- 专门为服务器发起的攻击使用，多用于ai，如果未打中nDamageType请填nil，必须实现
function HumanWeaponBase:CheatAttack(Target, nDamageType, tbParam)
    assert(false)
end

function HumanWeaponBase:CancelCheatAttack()
    
end

function HumanWeaponBase:GetOwnerProperty(nProtoId)
    local Value = self.OwnerPropertyComponent:GetProp(nProtoId)
    -- local szName = PropName.FindName(nProtoId)
    -- log("GetOwnerProperty nTemplateId", self.nTemplateId, "szName", szName, "Value", Value)
    return Value
end

function HumanWeaponBase:GetMinAttackIntervalTime()
    return 0
end

function HumanWeaponBase:GetCurrentMontageInStateLength(nState)
    local szAnimKey
    local tbBPInfo = self.tbBPInfo
    if not tbBPInfo then
        return nil
    end
    local nTime = 0
    local PlayRate = 1
    if(nState == HumanWeaponStateDef.UNHOLDING) then
        szAnimKey = tbBPInfo.szUnholdedAnimKey
        nTime = 0.3
    elseif(nState == HumanWeaponStateDef.HOLDING) then
        szAnimKey = tbBPInfo.szHoldedAnimKey
    elseif(nState == HumanWeaponStateDef.RELOADING) then
        PlayRate = self:GetOwnerProperty(PropName.nReloadCoefficient)
        szAnimKey = tbBPInfo.szReloadAnimKey
    end
    if(szAnimKey == nil) then
        return nil
    end
    local pAnimMontage = self.OwnerComponent:GetMontageWithAnimKey(szAnimKey, true) 
    if not pAnimMontage then
        return 0
    end
    nTime = pAnimMontage.SequenceLength / PlayRate

    return nTime
end

function HumanWeaponBase:RecordIllegalAttack(nType, szReason)
    local tbIllegalAttackRecord = self.tbIllegalAttackCount[nType]
    if not tbIllegalAttackRecord then
        tbIllegalAttackRecord = {}
        tbIllegalAttackRecord.nCount = 0
    end

    tbIllegalAttackRecord.nCount = tbIllegalAttackRecord.nCount + 1
    tbIllegalAttackRecord.szRecentReason = szReason

    self.tbIllegalAttackCount[nType] = tbIllegalAttackRecord
end

function HumanWeaponBase:TryOnIllegalAttack()
    local nTotalCount = 0
    for nType, tbIllegalRecord in pairs(self.tbIllegalAttackCount) do
        nTotalCount = nTotalCount + tbIllegalRecord.nCount
        if nTotalCount > CHECK_COUNT_LIMIT then
            local szReason = tbIllegalRecord.szRecentReason
            HumanWeaponHelper.OnIllegalAttack(self.Owner,szReason)
            self.tbIllegalAttackCount = nil
            return szReason
        end
    end

    return nil
end

return HumanWeaponBase