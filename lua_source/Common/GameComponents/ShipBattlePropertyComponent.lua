-----------------------------------------------------
--File Name    : ShipBattlePropertyComponent.lua
--Author       : Song Fuhao
--Create Time  : 2018-09-08
--Description  : 船形态 战斗属性逻辑相关
-----------------------------------------------------

local luaclass = require("luaclass")
local BattlePropertyComponentBase = require("BattlePropertyComponentBase")
local ShipBattlePropertyComponent = luaclass("ShipBattlePropertyComponent",BattlePropertyComponentBase)

-- local MathUtil = require("MathUtil")
local PropName = require("PropName")
local DelayTimer = require("DelayTimer")
local DungeonIni = require("DungeonIni")
local ShipCategory = require("ShipCategory")
local PropNameShip = require("PropNameShip")
local ShipDataTable = require("ShipDataTable")
local PropNameCommon = require("PropNameCommon")
local BattleTeamSystem = require("BattleTeamSystem")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleAbilitySystem = require("BattleAbilitySystem")
local ProgressBarTableNew = require("ProgressBarTableNew")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local NPCDataTable = require("NPCDataTable")
local TriggerIni = require("TriggerIni")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

-- 船救助队友对应ProgressbarTable中的ID
local SHIP_RESCUED_PROGRESS_ID = 23
-- 舰船击杀回血Buff
local SHIP_RECOVERED_HP_BY_KILLING_BUFF_ID = 90004
-- 全局Cache，字符串处理开销
local tbBpNotifyDispatcherNameCaches = {}

ShipBattlePropertyComponent.nHpId = PropName.nShipHp
ShipBattlePropertyComponent.nEpId = PropName.nShipEp
ShipBattlePropertyComponent.nMaxHpBaseId = PropName.nShipMaxHpBase
ShipBattlePropertyComponent.nMaxHpId = PropName.nShipMaxHp
ShipBattlePropertyComponent.nMaxEpId = PropName.nShipMaxEp
ShipBattlePropertyComponent.nHpShieldId = PropName.nShipHpShield
ShipBattlePropertyComponent.nIsDyingId = PropName.bIsShipDying
ShipBattlePropertyComponent.nIsRescuingId = PropName.bIsShipRescuing
ShipBattlePropertyComponent.nIsDeadId = PropName.bIsShipDead
ShipBattlePropertyComponent.nIsAlreadyDeadId = PropName.bIsShipAlreadyDead
ShipBattlePropertyComponent.nMinHpRatioId = PropName.nShipMinHpRatio
ShipBattlePropertyComponent.nDamageRatioFromNpcId = PropName.nShipDamageRatioFromNpc
ShipBattlePropertyComponent.nDamageRatioToNpcId = PropName.nShipDamageRatioToNpc
ShipBattlePropertyComponent.nDamageRatioId = PropName.nShipDamageRatio

ShipBattlePropertyComponent.tbDelayHideActorHandle = nil

-- 将变量同步回蓝图时的FunctionName
local function GetBpNotifyDispatcherName(szPropertyName)
    local szDispatcherName = tbBpNotifyDispatcherNameCaches[szPropertyName]
    if szDispatcherName == nil then
        szDispatcherName = string.format("On%sChanged", szPropertyName)
        tbBpNotifyDispatcherNameCaches[szPropertyName] = szDispatcherName
    end
    return szDispatcherName
end

-- 将变量同步回蓝图
local function SyncBpProp(self, szPropertyName, varNewValue, bWithNotify)
    if self.Owner:IsShip() and self.Owner.pUEActor then
        local pShipPropertyComponent = self.Owner.pUEActor.ShipPropertyComponent
        pShipPropertyComponent[szPropertyName] = varNewValue
        if bWithNotify then
            local szDispatcherName = GetBpNotifyDispatcherName(szPropertyName)
            pShipPropertyComponent[szDispatcherName]:call(varNewValue)
        end
    end
end

local function GetTemplateProperty(self, szPropertyName, varDefaultValue)
    local nTemplateId = self:GetProp(PropName.nShipTemplateId)
    local tbTemplate = ShipDataTable:GetTemplate(nTemplateId)
    return tbTemplate and tbTemplate[szPropertyName] or varDefaultValue
end

local function GetDefaultShipRescuedTime()
    return ProgressBarTableNew:GetTemplate(SHIP_RESCUED_PROGRESS_ID).nTime
end

local function OnShipTemplateIdChanged(self, nShipTemplateId)
    if GlobalVariableSystem:IsServerLogic() then
        self:SetPropOriginValue(PropName.nShipListenRange       , GetTemplateProperty(self, "nListenRange"              , 0))
        self:SetPropOriginValue(PropName.nShipVisibleDistance   , GetTemplateProperty(self, "nVisibleDistance"          , 0) * 100)
    end
    self:SetPropOriginValue(PropName.nShipCategory              , GetTemplateProperty(self, "nCategory"                 , ShipCategory.BattleShip))
    self:SetPropOriginValue(PropName.nShipMaxDyingHp            , GetTemplateProperty(self, "nDyingHp"                  , 0))
    self:SetPropOriginValue(PropName.nShipRescuedHp             , GetTemplateProperty(self, "nRescuedHp"                , 0))
    self:SetPropOriginValue(PropName.nShipDyingHpReduceSpeed    , GetTemplateProperty(self, "nDyingHpReduceSpeed"       , 0))
    self:SetPropOriginValue(PropName.nShipMoraleConsumedSpeed   , GetTemplateProperty(self, "nMoraleDecreasePerSecond"  , 0))
    self:SetPropOriginValue(PropName.nMaxLeanDegress            , GetTemplateProperty(self, "nMaxLeanDegress"           , 0))
end

local function OnShipCategoryChanged(self, nShipCategory)
    SyncBpProp(self, "ShipCategory", ShipCategory.GetBPEnum(nShipCategory))
end

local function OnMaxLeanDegressChanged(self, nMaxLeanDegress)
    local tbOwner = self.Owner
    if GlobalVariableSystem:IsClient()
    and (tbOwner.ObjectType == GameObjectTypeDef.PlayerSelf)
    and tbOwner:IsShip()
    and tbOwner.pUEActor then
        local pShipModel = tbOwner.pUEActor.ShipModelActor
        local pFlotageComponent = pShipModel and pShipModel.Flotage
        if pFlotageComponent then
            pFlotageComponent:SetShipRollMaxDegree(nMaxLeanDegress)
            log("[FlotageComponent] SetShipRollMaxDegree", nMaxLeanDegress)
        end
    end
end

local function OnFiringRangeRatioChanged(self, nFiringRangeRatio)
    SyncBpProp(self, "FiringRangeRatio", nFiringRangeRatio, true)
end

local function OnFiringRangeDeltaChanged(self, nFiringRangeDelta)
    SyncBpProp(self, "FiringRangeDelta", nFiringRangeDelta, true)
end

local function OnFiringRotationRangeDeltaChanged(self, nFiringRotationRangeDelta)
   SyncBpProp(self, "FiringRotationRangeDelta", nFiringRotationRangeDelta, true)
end

local function OnFiringRotationRangeRatioChanged(self, nFiringRotationRangeRatio)
   SyncBpProp(self, "FiringRotationRangeRatio", nFiringRotationRangeRatio, true)
end

local function OnPowderKegFiringAngleRatioChanged(self, nPowderKegFiringAngleRatio)
    SyncBpProp(self, "PowderKegFiringAngleRatio", nPowderKegFiringAngleRatio, true)
end

local function OnTelescopeScaleChanged(self, nTelescopeScale)
    EventManager:OnFireEvent(CommonEventDef.EV_ON_SHIP_TELESCOPE_SCALE_CHANGED, self.Owner, nTelescopeScale)
end

local function OnShipBotTypeChanged(self, nAIType)
    local tbOwner = self.Owner
    local pUEActor = tbOwner.pUEActor
    if GlobalVariableSystem:IsClient()
    and (tbOwner.ObjectType == GameObjectTypeDef.PlayerOther)
    and  tbOwner:IsShip()
    and  tbOwner.pUEActor then
        if nAIType > 0 then
            local nPersonality = nAIType // 100
            local nLevel = nAIType - nPersonality * 100
            if nPersonality <= 0 then -- 普通机器人
                pUEActor:ShowShipBotName(tbOwner.szName)
            else
                local szName = tostring(self.Owner:GetServerInstanceId()) .. "[" .. tbOwner.szName .. "]"
                local tbPersonalityLabel = {
                    [3] = "[平衡]",
                    [4] = "[保守]",
                    [5] = "[激进]",
                    [6] = "[队友]",
                }
                if tbPersonalityLabel[nPersonality] then
                    szName = szName .. tbPersonalityLabel[nPersonality]
                end
                if nLevel >= 0 then
                    szName = szName .. "[Lv." .. tostring(nLevel) .. "]"
                end
                pUEActor:ShowShipBotName(szName)
            end
        else
            pUEActor:HideShipBotName()
        end
    end
end

local function OnFireSoundReductionChanged(self, nNewFireSoundReduction)
    SyncBpProp(self, "FireWithMuffler", nNewFireSoundReduction > 0 and 1 or 0)
end

local function UpdateShotBaseInfo(self)
    if self.Owner:IsShip() and ((self.Owner:GetObjectType() == GameObjectTypeDef.PlayerSelf) or GlobalVariableSystem:IsServerLogic()) then
        local ActiveWeaponItem = BattleShipWeaponSystem:GetActiveWeaponItem(self.Owner)
        if ActiveWeaponItem then
            ActiveWeaponItem:UpdateShotBaseInfo()
        end
    end
end

local function OnShipRecoveredHpByKillingChanged(self, nShipRecoveredHpByKilling)
    if GlobalVariableSystem:IsServerLogic() then
        if nShipRecoveredHpByKilling == self:GetPropOriginValue(PropName.nShipRecoveredHpByKilling) then
            self.Owner.BuffComponentServer:RemoveBuffById(SHIP_RECOVERED_HP_BY_KILLING_BUFF_ID)
        else
            self.Owner.BuffComponentServer:AddBuffWithInstigator(self.Owner, SHIP_RECOVERED_HP_BY_KILLING_BUFF_ID)
        end
    end
end

local function RestoreMastVisibleByTeammateWeaponState(self)
    if GlobalVariableSystem:IsClient() then
        local tbLocalPlayer = require("GamePlayerSelfHelper"):Get() -- 因为这个文件在服务器也跑，所以这个req只能是函数内部
        if BattleTeamSystem:CheckTeammate(self.Owner, tbLocalPlayer) then
            local bMastVisible = BattleShipWeaponSystem:GetActiveWeaponSlot(tbLocalPlayer) == ShipWeaponSlotDef.UNKNOWN
            self.Owner.pUEActor:SetMastVisible(bMastVisible)
        end
    end
end

local function OnWeaponResChanged(self, tbWeaponResData)
    if GlobalVariableSystem:IsClient() then
        local ShipAvatarComponent = self.Owner.ShipAvatarComponent
        if ShipAvatarComponent then
            ShipAvatarComponent:OnWeaponResChanged(tbWeaponResData)
        end
    end
end

local function OnAvatarResChanged(self, tbAvatarResData)
    if GlobalVariableSystem:IsClient() then
        local ShipAvatarComponent = self.Owner.ShipAvatarComponent
        if ShipAvatarComponent then
            ShipAvatarComponent:OnAvatarResChanged(tbAvatarResData)
        end
    end
end

local function OnShipPartBrokenStatusChanged(self, tbBrokenStatusData)
    if GlobalVariableSystem:IsClient() then
        local ShipAvatarComponent = self.Owner.ShipAvatarComponent
        if ShipAvatarComponent then
            ShipAvatarComponent:OnShipPartBrokenStatusChanged(tbBrokenStatusData)
        end
    end
end

local function OnShipArmorGradeChanged(self, nShipArmorGrade)
    if GlobalVariableSystem:IsClient() then
        local ShipAvatarComponent = self.Owner.ShipAvatarComponent
        if ShipAvatarComponent then
            ShipAvatarComponent:OnShipArmorGradeChanged(nShipArmorGrade)
        end
    end
end

local function OnShipBuffChanged(self, pBuffType, nPropId)
    if GlobalVariableSystem:IsServerLogic() then
        local pShipMovementComponent = self.Owner.pUEActor and self.Owner.pUEActor.ShipMovementComponent
        if pShipMovementComponent then
            pShipMovementComponent:EmptyShipMoveGearBuff(true, pBuffType);
            -- local nAddValue = self:GetPropAddValue(nPropId)
            -- if nAddValue ~= 0 then
            --     pShipMovementComponent:AddShipMoveGearValueBuff(true, pBuffType, nAddValue);
            -- end
            local nMultiplyValue = self:GetPropMultiplyValue(nPropId)
            if nMultiplyValue ~= 0 then
                -- 接口需要传入一个放大100倍的整数值，所以传入前需要四舍五入
                pShipMovementComponent:AddShipMoveGearBuff(true, pBuffType, nMultiplyValue - 1);
            end
        end
    end
end

local function OnAngularAccelerationAdditionChanged(self)
    OnShipBuffChanged(self, EShipMoveGearBuffType.ANGULAR_ACCELERATION, PropName.nAngularAccelerationAddition)
end

local function OnAngularDecelerationAdditionChanged(self)
    OnShipBuffChanged(self, EShipMoveGearBuffType.ANGULAR_DECELERATION, PropName.nAngularDecelerationAddition)
end

local function OnAngularMaxSpeedAdditionChanged(self)
    OnShipBuffChanged(self, EShipMoveGearBuffType.MAX_ANGULAR_SPEED, PropName.nAngularMaxSpeedAddition)
end

local function OnLinearAccelerationAdditionChanged(self)
    OnShipBuffChanged(self, EShipMoveGearBuffType.LINEAR_ACCELERATION, PropName.nLinearAccelerationAddition)
end

local function OnLinearDecelerationAdditionChanged(self)
    OnShipBuffChanged(self, EShipMoveGearBuffType.LINEAR_DECELERATION, PropName.nLinearDecelerationAddition)
end

local function OnLinearMaxSpeedAdditionChanged(self)
    OnShipBuffChanged(self, EShipMoveGearBuffType.MAX_LINEAR_SPEED, PropName.nLinearMaxSpeedAddition)
end

local function OnShipVisibleDistanceChanged(self, nShipVisibleDistance)
    SyncBpProp(self, "SquaredVisibleDistance", nShipVisibleDistance * nShipVisibleDistance)
end

local function OnShipListenRangeChanged(self, nShipListenRange)
    if self.Owner.pUEActor and not GlobalVariableSystem:IsServerLogic() then
        self.Owner.pUEActor.ListenRange = nShipListenRange
    end
end

local function TriggerPropertyChangedCallback(self)
    self:TriggerPropCallback(PropName.nShipCategory)
    self:TriggerPropCallback(PropName.nFiringRangeRatio)
    self:TriggerPropCallback(PropName.nFiringRangeDelta)
    self:TriggerPropCallback(PropName.nFiringRotationRangeDelta)
    self:TriggerPropCallback(PropName.nFiringRotationRangeRatio)
    self:TriggerPropCallback(PropName.nAngularAccelerationAddition)
    self:TriggerPropCallback(PropName.nAngularDecelerationAddition)
    self:TriggerPropCallback(PropName.nAngularMaxSpeedAddition)
    self:TriggerPropCallback(PropName.nLinearAccelerationAddition)
    self:TriggerPropCallback(PropName.nLinearDecelerationAddition)
    self:TriggerPropCallback(PropName.nLinearMaxSpeedAddition)
    self:TriggerPropCallback(PropName.nShipVisibleDistance)
end

--------------------------------------
-- Override Protected begin

function ShipBattlePropertyComponent:GetDefaultMaxHp()
    return GetTemplateProperty(self, "nHp", 0)
end

function ShipBattlePropertyComponent:GetDefaultMaxEp()
    return GetTemplateProperty(self, "nMaxMorale", 0)
end

-- 定义Property属性
-- fnDefine(self, nPropId, varDefaultValue, fnCallback)
-- @ nPropId            PropName.lua中对应Id
-- @ varDefaultValue    默认值
-- @ fnCallback         值变化时触发的回调函数（可不传）
function ShipBattlePropertyComponent:DefineProperties(fnDefine, tbParams)
    log("[Performance] ShipBattlePropertyComponent:DefineProperties Begin")

    fnDefine(self, PropName.nShipTemplateId                 , -1                        , OnShipTemplateIdChanged               ) -- 当前船模板Id
    fnDefine(self, PropName.nShipResTemplateId              , -1                        , nil                                   ) -- 当前船资源Id

    local nShipRescuedTime          = GetDefaultShipRescuedTime()
    local nShipPickupRange          = TriggerIni.tbPickTrigger.nOceanTriggerRadius

    fnDefine(self, PropName.nShipCategory                   , ShipCategory.BattleShip   , OnShipCategoryChanged                 ) -- 当前船分类
    fnDefine(self, PropName.nMaxLeanDegress                 , 0                         , OnMaxLeanDegressChanged               ) -- 当前船最大倾斜角度

    -- ShipPart
    fnDefine(self, PropName.nFireDamageResistance           , 0.0                       , nil                                   ) -- 燃烧抗性
    fnDefine(self, PropName.nLeakDamageResistance           , 0.0                       , nil                                   ) -- 漏水抗性
    fnDefine(self, PropName.nSlowSpeedResistance            , 0.0                       , nil                                   ) -- 减速抗性
    fnDefine(self, PropName.nStunResistance                 , 0.0                       , nil                                   ) -- 定身抗性

    -- Weapon
    -- fnDefine(self, PropName.nActiveThrownItemTemplateId     , -1                        , OnActiveThrownItemTemplateIdChanged   ) -- 当前激活的投掷物Id
    -- fnDefine(self, PropName.nActiveWeaponSlot               , ShipWeaponSlotDef.UNKNOWN , OnActiveWeaponSlotChanged             ) -- 当前激活的武器槽位的Index
    fnDefine(self, PropName.nActiveWeaponTemplateId         , -1                        , nil                                   ) -- 当前激活的武器TemplateId

    -- WeaponAttachment
    fnDefine(self, PropName.nTelescopeScale                 , 0                         , OnTelescopeScaleChanged               ) -- 倍镜
    fnDefine(self, PropName.nCoreDetect                     , 0                         , nil                                   ) -- 核心区探测
    fnDefine(self, PropName.nReloadSpeedDelta               , 0                         , nil                                   ) -- 加快装填速度差值
    fnDefine(self, PropName.nReloadSpeedRatio               , 1.0                       , nil                                   ) -- 加快装填速度比例
    fnDefine(self, PropName.nFiringRangeDelta               , 0                         , OnFiringRangeDeltaChanged             ) -- 最大射程差值
    fnDefine(self, PropName.nFiringRangeRatio               , 1.0                       , OnFiringRangeRatioChanged             ) -- 最大射程比例
    fnDefine(self, PropName.nFiringRotationRangeDelta       , 0                         , OnFiringRotationRangeDeltaChanged     ) -- 增加射界差值
    fnDefine(self, PropName.nFiringRotationRangeRatio       , 1.0                       , OnFiringRotationRangeRatioChanged     ) -- 增加射界比例
    fnDefine(self, PropName.nFiringIntervalDelta            , 0                         , nil                                   ) -- 调整开火间隔差值
    fnDefine(self, PropName.nFiringIntervalRatio            , 1.0                       , nil                                   ) -- 调整开火间隔比例
    fnDefine(self, PropName.nFireSoundReduction             , 0                         , OnFireSoundReductionChanged           ) -- 武器消音
    fnDefine(self, PropName.nBulletTriggerRangeRatio        , 1                         , UpdateShotBaseInfo                    ) -- 子弹触发范围比例
    fnDefine(self, PropName.nBulletTriggerRangeDelta        , 0                         , UpdateShotBaseInfo                    ) -- 子弹触发范围差值
    fnDefine(self, PropName.nBulletMinRadiusDamageAddition  , 0                         , UpdateShotBaseInfo                    ) -- 子弹爆炸边缘伤害加成
    fnDefine(self, PropName.nBulletSpeedRatio               , 1                         , UpdateShotBaseInfo                    ) -- 子弹速度比例
    fnDefine(self, PropName.nBulletSpeedDelta               , 0                         , UpdateShotBaseInfo                    ) -- 子弹速度差值
    fnDefine(self, PropName.nPerfectFiringRangeBegin        , 0                         , nil                                   ) -- 最佳射击起始距离差值
    fnDefine(self, PropName.nPerfectFiringRangeEnd          , 0                         , nil                                   ) -- 最佳设计距离结束差值
    fnDefine(self, PropName.nWeaponDamageIntervalDelta      , 0                         , nil                                   ) -- 近战武器伤害间隔差值
    fnDefine(self, PropName.nWeaponDamageIntervalRatio      , 1                         , nil                                   ) -- 近战武器伤害间隔比例
    fnDefine(self, PropName.nShipBulletDeviationRatio       , 1                         , nil                                   ) -- 舰船子弹未开镜散布
    fnDefine(self, PropName.nShipBulletAimDeviationRatio    , 1                         , nil                                   ) -- 舰船子弹开镜散布
    fnDefine(self, PropName.nShipDebuffTimeRatio            , 1                         , nil                                   ) -- 舰船Debuff时间
    fnDefine(self, PropName.nShipRecoveredHpByKilling       , 1                         , OnShipRecoveredHpByKillingChanged     ) -- 舰船击杀对手时回血百分比，默认值为1为了方便值被Overlap后产生回调，下面几个速度值相同

    -- 建造相关加成
    fnDefine(self, PropName.tbMaterialCollector             , nil                       , nil                                   ) -- 收集任何未被收集过的木材或布料时，额外获得
    fnDefine(self, PropName.nBuildingTimeAddition           , 0                         , nil                                   ) -- 建造时间加成
    fnDefine(self, PropName.nPartBuildingTimeAddition       , 0                         , nil                                   )
    fnDefine(self, PropName.nWeaponBuildingTimeAddition     , 0                         , nil                                   )
    fnDefine(self, PropName.nShipBuildingTimeAddition       , 0                         , nil                                   )
    fnDefine(self, PropName.nPartBuildingMaterialRatio      , 1                         , nil                                   )
    fnDefine(self, PropName.nWeaponBuildingMaterialRatio    , 1                         , nil                                   )
    fnDefine(self, PropName.nShipBuildingMaterialRatio      , 1                         , nil                                   )

    -- 点火率/漏水率相关
    fnDefine(self, PropName.tbBurningProbInfo               , nil                       , nil                                   ) -- 点火率特殊加成(根据不同武器加成)
    fnDefine(self, PropName.tbLeakingProbInfo               , nil                       , nil                                   ) -- 漏水率特殊加成(根据不同武器加成)
    fnDefine(self, PropName.nBurningProb                    , 1.0                       , nil                                   ) -- 点火率加成
    fnDefine(self, PropName.nLeakingProb                    , 1.0                       , nil                                   ) -- 漏水率加成
    fnDefine(self, PropName.nBurningProofProb               , 1.0                       , nil                                   ) -- 点火抗性加成
    fnDefine(self, PropName.nLeakingProofProb               , 1.0                       , nil                                   ) -- 漏水抗性加成

    fnDefine(self, PropName.nControlModeSwitchSpeedRatio    , 1.0                       , nil                                   ) -- 人船之间切换缩短相应比例时间
    fnDefine(self, PropName.tbAttackReductionDamageRatioInfo, nil                       , nil                                   ) -- 攻击减速敌人伤害加成

    fnDefine(self, PropName.nShipBotType                     , 0                        , OnShipBotTypeChanged                  ) -- 机器人标识

    -- 船的外观相关
    fnDefine(self, PropName.rShipWeaponResData              , {}                        , OnWeaponResChanged                    ) -- 船武器资源
    fnDefine(self, PropName.rShipAvatarResData              , {}                        , OnAvatarResChanged                    ) -- 船零件外观资源
    fnDefine(self, PropName.rShipPartBrokenStatus           , {}                        , OnShipPartBrokenStatusChanged         ) -- 船零件破损状态
    fnDefine(self, PropName.nShipArmorGrade                 , 0                         , OnShipArmorGradeChanged               ) -- 船护甲等级

    fnDefine(self, PropName.nShipExtraPackageCapacityValue  , 0                         , nil                                   ) -- 船背包的附加容量
    fnDefine(self, PropName.nShipExtraMaterialCapacityRatio , 0                         , nil                                   ) -- 船材料上限附加比例
    fnDefine(self, PropName.nShipMaxDyingHp                 , 0                         , nil                                   ) -- 船重伤下最大血量
    fnDefine(self, PropName.nShipRescuedHp                  , 0                         , nil                                   ) -- 船重伤恢复后血量
    fnDefine(self, PropName.nShipDyingHpReduceSpeed         , 0                         , nil                                   ) -- 船重伤下掉血速度
    fnDefine(self, PropName.nShipRescuedTime                , nShipRescuedTime          , nil                                   ) -- 船救援时间
    fnDefine(self, PropName.nBurningDamageRatioCaused       , 1                         , nil                                   ) -- 舰船武器的点火伤害
    fnDefine(self, PropName.nLeakingDamageRatioCaused       , 1                         , nil                                   ) -- 舰船武器的漏水伤害
    fnDefine(self, PropName.nBurningDamageRatioTaken        , 1                         , nil                                   ) -- 舰船受到的点火伤害
    fnDefine(self, PropName.nLeakingDamageRatioTaken        , 1                         , nil                                   ) -- 舰船受到的漏水伤害
    fnDefine(self, PropName.nShipAttack                     , 0                         , nil                                   ) -- 船基础攻击值
    fnDefine(self, PropName.nShipHeadDamageRatio            , 1                         , nil                                   ) -- 船头减伤比例
    fnDefine(self, PropName.nShipBodyDamageRatio            , 1                         , nil                                   ) -- 船身减伤比例
    fnDefine(self, PropName.nShipSternDamageRatio           , 1                         , nil                                   ) -- 船尾减伤比例
    fnDefine(self, PropName.nShipSailDamageRatio            , 1                         , nil                                   ) -- 船帆减伤比例
    fnDefine(self, PropName.nShipDeckDamageRatio            , 1                         , nil                                   ) -- 船甲板减伤比例
    fnDefine(self, PropName.nShipCaptainRoomDamageRatio     , 1                         , nil                                   ) -- 核心区减伤比例
    fnDefine(self, PropName.nShipPartDurability             , 0                         , nil                                   ) -- 舰船零件耐久加成
    fnDefine(self, PropName.nShipItemUsingTime              , 0                         , nil                                   ) -- 舰船使用物品时间加成
    fnDefine(self, PropName.nShipListenRange                , 0                         , OnShipListenRangeChanged              ) -- 船听力加成
    fnDefine(self, PropName.nShipPickupRange                , nShipPickupRange          , nil                                   ) -- 船拾取范围加成
    fnDefine(self, PropName.nShipMoraleConsumedSpeed        , 0                         , nil                                   ) -- 船拾取范围加成
    fnDefine(self, PropName.nAngularAccelerationAddition    , 1                         , OnAngularAccelerationAdditionChanged  ) -- 船转向加速度加成，默认值为1为了方便值被Overlap后产生回调，下面几个速度值相同
    fnDefine(self, PropName.nAngularDecelerationAddition    , 1                         , OnAngularDecelerationAdditionChanged  ) -- 船转向减速度加成
    fnDefine(self, PropName.nAngularMaxSpeedAddition        , 1                         , OnAngularMaxSpeedAdditionChanged      ) -- 船最大转向速度加成
    fnDefine(self, PropName.nLinearAccelerationAddition     , 1                         , OnLinearAccelerationAdditionChanged   ) -- 船直行加速度加成
    fnDefine(self, PropName.nLinearDecelerationAddition     , 1                         , OnLinearDecelerationAdditionChanged   ) -- 船直行减速度加成
    fnDefine(self, PropName.nLinearMaxSpeedAddition         , 1                         , OnLinearMaxSpeedAdditionChanged       ) -- 船最大直行速度加成
    fnDefine(self, PropName.nShipVisibleDistance            , 0                         , OnShipVisibleDistanceChanged          ) -- 船的隐蔽性/被发现距离

    fnDefine(self, PropName.nSmallCannonDamageAddition      , 0                         , nil                                   ) -- 增加/减少回旋炮武器伤害
    fnDefine(self, PropName.nPowderKegDamageAddition        , 0                         , nil                                   ) -- 增加/减少爆桶武器伤害
    fnDefine(self, PropName.nCarronadeDamageAddition        , 0                         , nil                                   ) -- 增加/减少臼炮武器伤害
    fnDefine(self, PropName.nTorpedoDamageAddition          , 0                         , nil                                   ) -- 增加/减少陷阱武器伤害
    fnDefine(self, PropName.nSakersDamageAddition           , 0                         , nil                                   ) -- 增加/减少霰弹炮武器伤害
    fnDefine(self, PropName.nDartleDamageAddition           , 0                         , nil                                   ) -- 增加/减少转轮炮武器伤害
    fnDefine(self, PropName.nAssaultGunDamageAddition       , 0                         , nil                                   ) -- 增加/减少加农炮武器伤害
    fnDefine(self, PropName.nSnipeGunDamageAddition         , 0                         , nil                                   ) -- 增加/减少曲射炮武器伤害
    fnDefine(self, PropName.nEmbolonDamageAddition          , 0                         , nil                                   ) -- 增加/减少撞角武器伤害
    fnDefine(self, PropName.nFlamerDamageAddition           , 0                         , nil                                   ) -- 增加/减少喷火器武器伤害
    fnDefine(self, PropName.nSternCannonDamageAddition      , 0                         , nil                                   ) -- 增加/减少船尾炮武器伤害
    fnDefine(self, PropName.nPowderKegFiringRoundCountDelta , 0                         , nil                                   ) -- 增加/减少臼炮武器开火轮数
    fnDefine(self, PropName.nCarronadeFiringRoundCountDelta , 0                         , nil                                   ) -- 增加/减少臼炮武器开火轮数
    fnDefine(self, PropName.nPowderKegFiringAngleRatio      , 1.0                       , OnPowderKegFiringAngleRatioChanged    ) -- 增加/减少爆桶发射夹角比率

    fnDefine(self, PropName.rCharacterAllBuff               , {}                        , nil                                   ) -- 角色Buff改变（只在初始化时同步）
    fnDefine(self, PropName.rShipWeaponBulletLoadingInfo    , {}                        , nil                                   ) -- 同步舰船武器装填状态

    ShipBattlePropertyComponent.super.DefineProperties(self, fnDefine, tbParams)
    log("[Performance] ShipBattlePropertyComponent:DefineProperties End")
end

function ShipBattlePropertyComponent:OnActorPreCreated(pUEActor)
    OnShipTemplateIdChanged(self)
    ShipBattlePropertyComponent.super.OnActorPreCreated(self, pUEActor)
end

function ShipBattlePropertyComponent:OnActorCreated(pUEActor)
    ShipBattlePropertyComponent.super.OnActorCreated(self, pUEActor)

    if self.Owner:IsShip() then
        self:BindRepProperties(PropNameShip.GetRepIds())

        if GlobalVariableSystem:IsClient()
        and (self.Owner.ObjectType == GameObjectTypeDef.PlayerSelf) then
            pUEActor:InitShipOnlyPlayerSelf()
        end

        TriggerPropertyChangedCallback(self)
        OnShipRecoveredHpByKillingChanged(self, self:GetProp(PropName.nShipRecoveredHpByKilling))
        RestoreMastVisibleByTeammateWeaponState(self)
        pUEActor.ShipPropertyComponent.CharacterName = self.Owner.szName
    else
        self:BindRepProperties(PropNameCommon.GetRepIds())
    end
end

function ShipBattlePropertyComponent:OnActorDestroyed()
    if self.tbDelayHideActorHandle then
        DelayTimer:ClearTimer(self.tbDelayHideActorHandle)
        self.tbDelayHideActorHandle = nil
    end
    ShipBattlePropertyComponent.super.OnActorDestroyed(self)
end

function ShipBattlePropertyComponent:HandleIsDeadChanged()
    local pUEActor = self.Owner.pUEActor
    if not pUEActor then
        return
    end

    -- 立即停船&关闭移动系统
    local pShipMovementComponent = pUEActor.ShipMovementComponent
    pShipMovementComponent:StopMovementImmediately()
    pShipMovementComponent:SetComponentTickEnabled(false)

    -- 关闭Tick
    pUEActor:SetActorTickEnabled(false)

    -- 关闭碰撞
    pUEActor:CloseAllSPFD()
    pUEActor.ShipBox:SetCollisionEnabled(ECollisionEnabled.NoCollision)

    -- 通知蓝图死亡状态变化
    SyncBpProp(self, "IsDead", true)

    if GlobalVariableSystem:IsClient() then
        -- 客户端播放死亡动画
        local function fnHideActor()
            self.tbDelayHideActorHandle = nil
            pUEActor:SetActorHiddenInGame(true)
            pUEActor.ShipModel.ChildActor:Sink()
            -- local pSkeletalMeshComponent = pUEActor.ShipAvatarComponent:GetSkeletalMeshComponent()
            -- local pAnimInstance = pSkeletalMeshComponent:GetAnimInstance()
            -- pAnimInstance.Dead = true
        end
        local nHideShipActorDelayTime
        if self.Owner.ObjectType == GameObjectTypeDef.Npc then
            local tbNpcTemplate = NPCDataTable:GetTemplate(self.Owner.nTemplateId)
            nHideShipActorDelayTime = tbNpcTemplate.nHideDelayTimeAfterDeath
        else
            nHideShipActorDelayTime = DungeonIni.tbDead.nHideShipActorDelayTime
        end
        if nHideShipActorDelayTime > 0 then
            self.tbDelayHideActorHandle = DelayTimer:DelayRun(fnHideActor, nHideShipActorDelayTime)
        else
            fnHideActor()
        end

        -- 客户端播放死亡特效、音效
        local nShipDeadParticleResId = DungeonIni.tbDead.nShipDeadParticleResId
        local szShipDeadSoundRes = DungeonIni.tbDead.szShipDeadSoundRes
        BattleAbilitySystem:PlayParticleEffect(self.Owner, nShipDeadParticleResId)
        BattleAbilitySystem:PlaySound(self.Owner, szShipDeadSoundRes, true)

        -- 客户端隐藏头顶名字片
        local HeadInfoComponent = self.Owner.HeadInfoComponent
        if HeadInfoComponent then
            HeadInfoComponent:SetVisibility(false)
        end
    end
end

function ShipBattlePropertyComponent:HandleIsDyingChanged(bIsDying)
    local pUEActor = self.Owner.pUEActor
    if pUEActor then
        pUEActor:OnIsDyingChanged(bIsDying)
    end
end

function ShipBattlePropertyComponent:HandleIsAlreadyDead()
    local pUEActor = self.Owner.pUEActor
    if pUEActor then
        -- 关闭碰撞
        pUEActor:CloseAllSPFD()
        pUEActor.ShipBox:SetCollisionEnabled(ECollisionEnabled.NoCollision)
        -- 关闭Tick
        pUEActor.ShipMovementComponent:SetComponentTickEnabled(false)
        pUEActor:SetActorTickEnabled(false)
        -- 隐藏角色
        pUEActor:SetActorHiddenInGame(true)
    end
end
-- Override Protected end
--------------------------------------

--------------------------------------
-- Public begin
function ShipBattlePropertyComponent:SetShipTemplateId(nTemplateId)
    self:SetPropOriginValue(PropName.nShipTemplateId, nTemplateId)
end

function ShipBattlePropertyComponent:ResetShipHpAndEpWhenShipChange(bFullHp)
    local nOldHpPercent = self:GetHpPercent()
    local nNewMaxHp = self:GetDefaultMaxHp()
    self:SetPropOriginValue(self.nMaxHpBaseId, nNewMaxHp)
    local nNewHp = self:GetMaxHp()
    if not bFullHp then
        nNewHp = nOldHpPercent * nNewHp
    end
    self:SetPropOriginValue(self.nHpId, nNewHp)
    self:SetPropOriginValue(self.nMaxEpId, self:GetDefaultMaxEp())
end

function ShipBattlePropertyComponent:GetMaxDyingHp()
    return self:GetProp(PropName.nShipMaxDyingHp)
end

function ShipBattlePropertyComponent:GetRescuedHp()
    return self:GetProp(PropName.nShipRescuedHp)
end

function ShipBattlePropertyComponent:GetDyingHpReduceSpeed()
    return self:GetProp(PropName.nShipDyingHpReduceSpeed)
end

function ShipBattlePropertyComponent:GetRescuedTime()
    return self:GetProp(PropName.nShipRescuedTime)
end
-- public end
--------------------------------------

return ShipBattlePropertyComponent