
-----------------------------------------------------
--File Name    : HumanBattlePropertyComponent.lua
--Author       : Luzheng
--Create Time  : 2018-08-21
--Description  : 人形态 战斗属性逻辑相关
-----------------------------------------------------

local luaclass = require("luaclass")
local BattlePropertyComponentBase = require("BattlePropertyComponentBase")
local HumanBattlePropertyComponent = luaclass("HumanBattlePropertyComponent",BattlePropertyComponentBase)

local HumanMoraleIni = require("HumanMoraleIni")
local RadarmapSoundListenIni = require("RadarmapSoundListenIni")
local PropName = require("PropName")
local DungeonIni = require("DungeonIni")
local ProgressBarTableNew = require("ProgressBarTableNew")
local GameObjectTypeDef = require("GameObjectTypeDef")
local HumanFightDataTable = require("HumanFightDataTable")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local HumanSwimmingIni = require("HumanSwimmingIni")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local HumanVehicleHelper = require("HumanVehicleHelper")
local DelayTimer = require("DelayTimer")
local SelfAnimationHelper = require("SelfAnimationHelper")
local HumanMiscPropertyDefaultIni = require("HumanMiscPropertyDefaultIni")
local PropNameCommon = require("PropNameCommon")
local PropNameHuman = require("PropNameHuman")
local NPCDataTable = require("NPCDataTable")
local TriggerIni = require("TriggerIni")

-- 船救助队友对应ProgressbarTable中的ID
local HUMAN_RESCUED_PROGRESS_ID = 24

HumanBattlePropertyComponent.nHpId = PropName.nHumanHp
HumanBattlePropertyComponent.nEpId = PropName.nHumanEp
HumanBattlePropertyComponent.nMaxHpBaseId = PropName.nHumanMaxHpBase
HumanBattlePropertyComponent.nMaxHpId = PropName.nHumanMaxHp
HumanBattlePropertyComponent.nMaxEpId = PropName.nHumanMaxEp
HumanBattlePropertyComponent.nHpShieldId = PropName.nHumanHpShield
HumanBattlePropertyComponent.nIsDyingId = PropName.bIsHumanDying
HumanBattlePropertyComponent.nIsRescuingId = PropName.bIsHumanRescuing
HumanBattlePropertyComponent.nIsDeadId = PropName.bIsHumanDead
HumanBattlePropertyComponent.nIsAlreadyDeadId = PropName.bIsHumanAlreadyDead
HumanBattlePropertyComponent.nMinHpRatioId = PropName.nHumanMinHpRatio
HumanBattlePropertyComponent.nDamageRatioFromNpcId = PropName.nHumanDamageRatioFromNpc
HumanBattlePropertyComponent.nDamageRatioToNpcId = PropName.nHumanDamageRatioToNpc
HumanBattlePropertyComponent.nDamageRatioId = PropName.nHumanDamageRatio

HumanBattlePropertyComponent.tbDelayHideActorHandle = nil

local function LOG(self, ...)
    log("[HumanBattlePropertyComponent]", self.Owner.szName, ...)
end

local function GetTemplateProperty(self, szPropertyName, varDefaultValue)
    local nTemplateId = self:GetProp(PropName.nHumanTemplateId)
    local tbTemplate = HumanFightDataTable:GetTemplate(nTemplateId)
    return tbTemplate and tbTemplate[szPropertyName] or varDefaultValue
end

local function GetDefaultHumanRescuedTime(self)
    return ProgressBarTableNew:GetTemplate(HUMAN_RESCUED_PROGRESS_ID).nTime
end

local function GetDefaultMaxStamina()
    return HumanSwimmingIni.nMaxStamina
end

local function OnHumanTemplateIdChanged(self, nHumanTemplateId)
    if GlobalVariableSystem:IsServerLogic() then
        self:SetPropOriginValue(self.nMaxHpBaseId, self:GetDefaultMaxHp())
        self:SetPropOriginValue(self.nHpId, self:GetMaxHp())
        self:SetPropOriginValue(self.nMaxEpId, self:GetDefaultMaxEp())
    end
end

local function OnHumanBotTypeChanged(self, nAIType)
    local tbOwner = self.Owner
    local pUEActor = tbOwner.pUEActor
    if GlobalVariableSystem:IsClient()
    and (tbOwner.ObjectType == GameObjectTypeDef.PlayerOther)
    and  tbOwner:IsHuman()
    and  pUEActor then
        if nAIType > 0 then
            local nPersonality = nAIType // 100
            local nLevel = nAIType - nPersonality * 100
            if nPersonality <= 0 then -- 普通机器人
                pUEActor:ShowHumanBotName(tbOwner.szName, 150)
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
                pUEActor:ShowHumanBotName(szName, 150)
            end
        else
            pUEActor:HideHumanBotName()
        end
    end
end

local function OnDiamondRefreshTimeChanged(self, nDiamondRefreshTimeOnMap)
    EventManager:OnFireEvent(CommonEventDef.EV_DIAMOND_REFRESH_TIME_ON_MAP_CHANGED, self.Owner:GetServerInstanceId(), nDiamondRefreshTimeOnMap)
end

local function OnChangeSwimmingStamina(self, nStamina)
    -- PropName.nSwimmingStamina = nStamina
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_SWIMMING_STAMINA_CHANGE, self.Owner:GetServerInstanceId(), nStamina)
end

local function OnHumanListenRangeChanged(self, nHumanListenRange)
    if self.Owner.pUEActor and not GlobalVariableSystem:IsServerLogic() then
        self.Owner.pUEActor.ListenRange = nHumanListenRange
    end
end

local function OnHumanPickup(self, tbPickupData)
    if not tbPickupData then
        return
    end
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_PICKUP_ACTION, self.Owner, tbPickupData.instance_id, tbPickupData.template_id)
end

local function OnHumanFootStepSoundSettingIndexChanged(self, nSettingIndex)
    if not GlobalVariableSystem:IsServerLogic() and self.Owner.pUEActor and self.Owner.pUEActor.AnimationSoundComponent then
        log("OnHumanFootStepSoundSettingIndexChanged SetSoundSettingIndex:", nSettingIndex)
        self.Owner.pUEActor.AnimationSoundComponent:SetSoundSettingIndex(nSettingIndex)
    end
end

local function OnHumanWeaponAttackSoundSettingIndexChanged(self, nSettingIndex)
    if not GlobalVariableSystem:IsServerLogic() and self.Owner.pUEActor and self.Owner.pUEActor.PlayerProperty then
        log("OnHumanWeaponAttackSoundSettingIndexChanged SetSoundSettingIndex:", nSettingIndex)
        self.Owner.pUEActor.PlayerProperty:SetAttackSoundIndex(nSettingIndex)
    end
end

local function OnHumanArmorChanged(self, nArmorId)
    if not GlobalVariableSystem:IsServerLogic() then
        -- EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_ARMOR_CHANGED, self.Owner, nArmorId)
        self.Owner.DelegateComponent.OnHumanArmorChanged:Fire(nArmorId)
    end
end

--------------------------------------
-- Override Protected begin

function HumanBattlePropertyComponent:GetDefaultMaxHp()
    return GetTemplateProperty(self, "nHp", 0)
end

function HumanBattlePropertyComponent:GetDefaultMaxEp()
    return GetTemplateProperty(self, "nEp", 0)
end

-- 定义Property属性
-- fnDefine(self, nPropId, varDefaultValue, fnCallback)
-- @ nPropId            PropName.lua中对应Id
-- @ varDefaultValue    默认值
-- @ fnCallback         值变化时触发的回调函数（可不传）
function HumanBattlePropertyComponent:DefineProperties(fnDefine, tbParams)
    log("[Performance] HumanBattlePropertyComponent:DefineProperties Begin")
    local nHumanTemplateId = (tbParams and tbParams.nHumanTemplateId) and tbParams.nHumanTemplateId or -1
    fnDefine(self, PropName.nHumanTemplateId,                   nHumanTemplateId,           OnHumanTemplateIdChanged    )   -- 当前人物模板Id

    local nCommonRecoverLimit       = GetTemplateProperty(self, "nCommonRecoverLimit",  0)
    local nEpReduceSpeed            = GetTemplateProperty(self, "nEpReduceSpeed",       0)
    local nHeadInjuryRatio          = GetTemplateProperty(self, "nHeadInjuryRatio",     0)
    local nBodyInjuryRatio          = GetTemplateProperty(self, "nBodyInjuryRatio",     0)
    local nAllFoursInjuryRatio      = GetTemplateProperty(self, "nAllFoursInjuryRatio", 0)
    local nHumanMaxDyingHp          = GetTemplateProperty(self, "nDyingHp",             0)
    local nHumanRescuedHp           = GetTemplateProperty(self, "nRescuedHp",           0)
    local nHumanDyingHpReduceSpeed  = GetTemplateProperty(self, "nDyingHpReduceSpeed",  0)
    local nHumanListenRange         = RadarmapSoundListenIni.nHumanListenRange
    local nHumanPickupRange         = TriggerIni.tbPickTrigger.nLandTriggerRadius
    local nDiamondRefreshTimeOnMap  = DungeonIni.tbFFA.nDiamondRefreshTimeOnMap
    local nHumanRescuedTime         = GetDefaultHumanRescuedTime()
    local nSwimmingStamina          = GetDefaultMaxStamina()
    local nHumanMoraleConsumedSpeed = HumanMoraleIni.tbHumanMorale.nDecreaseValue
    fnDefine(self, PropName.nCommonRecoverLimit,                nCommonRecoverLimit                                     )   -- 一般药物恢复上限制
    fnDefine(self, PropName.nEpReduceSpeed,                     nEpReduceSpeed                                          )   -- 能量值消耗速度
    fnDefine(self, PropName.nHeadInjuryRatio,                   nHeadInjuryRatio                                        )   -- 头部受伤比例
    fnDefine(self, PropName.nBodyInjuryRatio,                   nBodyInjuryRatio                                        )   -- 头部受伤比例
    fnDefine(self, PropName.nAllFoursInjuryRatio,               nAllFoursInjuryRatio                                    )   -- 头部受伤比例
    fnDefine(self, PropName.nHumanBotType,                      0,                          OnHumanBotTypeChanged       )   -- 机器人标识
    fnDefine(self, PropName.nHumanMaxDyingHp,                   nHumanMaxDyingHp                                        )   -- 人重伤下最大血量
    fnDefine(self, PropName.nHumanRescuedHp,                    nHumanRescuedHp                                         )   -- 人重伤恢复后血量
    fnDefine(self, PropName.nHumanDyingHpReduceSpeed,           nHumanDyingHpReduceSpeed                                )   -- 人重伤下掉血速度
    fnDefine(self, PropName.nHumanRescuedTime,                  nHumanRescuedTime                                       )   -- 人救援时间
    fnDefine(self, PropName.nHumanExtraPackageCapacityValue,    0                                                       )   -- 人背包的附加容量
    fnDefine(self, PropName.bCanSeeAirDropOnMap ,               false,                      nil                         )   -- 是否可以在地图上看见空投图标
    fnDefine(self, PropName.bCanSeeDiamondOnMap ,               false,                      nil                         )   -- 是否可以在地图上看见最近的宝石
    fnDefine(self, PropName.nDiamondRefreshTimeOnMap ,          nDiamondRefreshTimeOnMap,   OnDiamondRefreshTimeChanged )   -- 地图上看见最近的宝石的刷新时间间隔
    fnDefine(self, PropName.nSwimmingStamina,                   nSwimmingStamina,           OnChangeSwimmingStamina     )
    fnDefine(self, PropName.nHumanItemUsingTime,                0                                                       )   -- 人使用物品时间加成
    fnDefine(self, PropName.nHumanListenRange,                  nHumanListenRange,          OnHumanListenRangeChanged   )   -- 人听力范围
    fnDefine(self, PropName.nHumanPickupRange,                  nHumanPickupRange,          nil                         )   -- 人拾取范围
    fnDefine(self, PropName.nHumanMoraleConsumedSpeed,          nHumanMoraleConsumedSpeed                               )   -- 人拾取范围

    fnDefine(self, PropName.nHumanAttack,                       0                                                       )   -- 人攻击力加成
    fnDefine(self, PropName.nHumanAttackInterval,               0                                                       )   -- 人攻击时间间隔加成
    fnDefine(self, PropName.nHumanReloadTime,                   0                                                       )   -- 人装弹时间加成
    fnDefine(self, PropName.rHumanPickupItem,                   nil,                          OnHumanPickup              )   -- 人拾取物品
    fnDefine(self, PropName.nHumanFootStepSoundSettingIndex,    -1,              OnHumanFootStepSoundSettingIndexChanged)   -- 脚步声设置索引
    fnDefine(self, PropName.nHumanWeaponAttackSoundSettingIndex,-1,              OnHumanWeaponAttackSoundSettingIndexChanged)   -- 脚步声设置索引
    fnDefine(self, PropName.nCurrentArmorTemplateId,            -1,              OnHumanArmorChanged                    )   -- 人当前armortemplateId

    local tbDefaultValue = HumanMiscPropertyDefaultIni.tbDefault
    fnDefine(self, PropName.nAttackCD,                          tbDefaultValue.nAttackCD                                )   -- 人攻击输入cd
    fnDefine(self, PropName.nAttackRate,                        tbDefaultValue.nAttackRate                              )   -- 人射速
    fnDefine(self, PropName.nAttackRegion,                      tbDefaultValue.nAttackRegion                            )   -- 人射程/近战武器攻击范围
    fnDefine(self, PropName.nBulletCapacity,                    tbDefaultValue.nBulletCapacity                          )   -- 子弹容量
    fnDefine(self, PropName.nBulletCostPerAttack,               tbDefaultValue.nBulletCostPerAttack                     )   -- 一次性扣弹数
    fnDefine(self, PropName.nBulletCountPerAttack,              tbDefaultValue.nBulletCountPerAttack                    )   -- 一次性打出的子弹个数
    fnDefine(self, PropName.nBulletInitialSpeed,                tbDefaultValue.nBulletInitialSpeed                      )   -- 子弹初速度
    fnDefine(self, PropName.nBulletSpeedMagnification,          tbDefaultValue.nBulletSpeedMagnification                )   -- 蓄力满子弹速度倍率
    fnDefine(self, PropName.nBulletDispersionMagnification,     tbDefaultValue.nBulletDispersionMagnification           )   -- 蓄力满散布倍率
    fnDefine(self, PropName.nDamagePerAttack,                   tbDefaultValue.nDamagePerAttack                         )   -- 单发伤害
    fnDefine(self, PropName.nDamageFullCharge,                  tbDefaultValue.nDamageFullCharge                        )   -- 蓄力满伤
    fnDefine(self, PropName.nDispersionRatio,                   tbDefaultValue.nDispersionRatio                         )   -- 武器扩散倍率系数
    fnDefine(self, PropName.nFireballExplosiveInnerRadius,      tbDefaultValue.nFireballExplosiveInnerRadius            )   -- 火球爆炸范围（内径）
    fnDefine(self, PropName.nFireballExplosiveOutsideRadius,    tbDefaultValue.nFireballExplosiveOutsideRadius          )   -- 火球爆炸范围（外径）
    fnDefine(self, PropName.nRecoilHorizontalRatio,             tbDefaultValue.nRecoilHorizontalRatio                   )   -- 后坐力水平值倍率系数
    fnDefine(self, PropName.nRecoilVerticalRatio,               tbDefaultValue.nRecoilVerticalRatio                     )   -- 后坐力垂直值倍率系数
    fnDefine(self, PropName.nSectorDegree,                      tbDefaultValue.nSectorDegree                            )   -- 扇形角度
    fnDefine(self, PropName.nAttackCoefficient,                 tbDefaultValue.nAttackCoefficient                       )   -- 攻击动作系数
    fnDefine(self, PropName.nReloadCoefficient,                 tbDefaultValue.nReloadCoefficient                       )   -- 换弹动作系数

    fnDefine(self, PropName.nClimbCoefficient,                  tbDefaultValue.nClimbCoefficient                        )   -- 攀爬系数
    fnDefine(self, PropName.nMountCoefficient,                  tbDefaultValue.nMountCoefficient                        )   -- 上下马系数
    fnDefine(self, PropName.nResistFallDownCoefficient,         tbDefaultValue.nResistFallDownCoefficient               )   -- 坠落减伤
    fnDefine(self, PropName.nResistFallOffHorseCoefficient,     tbDefaultValue.nResistFallOffHorseCoefficient           )   -- 坠马减伤


    HumanBattlePropertyComponent.super.DefineProperties(self, fnDefine, tbParams)
    log("[Performance] HumanBattlePropertyComponent:DefineProperties End")
end

function HumanBattlePropertyComponent:OnActorCreated(pUEActor)
    HumanBattlePropertyComponent.super.OnActorCreated(self, pUEActor)

    if self.Owner:IsHuman() then
        self:BindRepProperties(PropNameHuman.GetRepIds())

        pUEActor.HeadInjuryFactor = GetTemplateProperty(self, "nHeadInjuryRatio",1)
        pUEActor.BodyInjuryFactor = GetTemplateProperty(self, "nBodyInjuryRatio",1)
        pUEActor.AllFoursInjuryFactor = GetTemplateProperty(self, "nAllFoursInjuryRatio",1)
    else
        self:BindRepProperties(PropNameCommon.GetRepIds())
    end
end

function HumanBattlePropertyComponent:OnActorDestroyed()
    if self.tbDelayHideActorHandle then
        DelayTimer:ClearTimer(self.tbDelayHideActorHandle)
        self.tbDelayHideActorHandle = nil
    end
    HumanBattlePropertyComponent.super.OnActorDestroyed(self)
end

function HumanBattlePropertyComponent:HandleIsAlreadyDead()
    self:HandleIsDeadChanged()
end

local function DisablePlayerCollision(self)
    local pUEActor = self.Owner.pUEActor
    pUEActor.Uparm_l:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    pUEActor.Uparm_r:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    pUEActor.Forearm_l:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    pUEActor.Forearm_r:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    pUEActor.Head:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    pUEActor.Body:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    pUEActor.Thigh_r:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    pUEActor.Thigh_l:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    pUEActor.Calf_l:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    pUEActor.Calf_r:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    pUEActor.CapsuleComponent:SetCollisionEnabled(ECollisionEnabled.NoCollision)

    if pUEActor.AimSphereCollision then
        pUEActor.AimSphereCollision:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    end
end

local function DisableMovement(self)
    local pUEActor = self.Owner.pUEActor
    pUEActor.CharacterMovement:StopMovementImmediately()
    pUEActor.CharacterMovement:DisableMovement()
    pUEActor.CharacterMovement:SetComponentTickEnabled(false)
    pUEActor.CharacterMovement.GravityScale = 0
end

function HumanBattlePropertyComponent:HandleIsDeadChanged()
    LOG(self, "HandleIsDeadChanged 1")
    if not self.Owner:IsHuman() then
        logerror("HumanBattlePropertyComponent:HandleIsDeadChanged owner is not human.", self.Owner.szName, self.Owner:GetServerInstanceId())
        return
    end
    LOG(self, "HandleIsDeadChanged 2")
    HumanVehicleHelper.ClearVehicle(self.Owner)

    local pUEActor = self.Owner.pUEActor
    if not pUEActor or not pUEActor.Uparm_l then
        return
    end
    LOG(self, "HandleIsDeadChanged 3")

    --死亡了 需要从载具上 脱离出来 不然死亡视角会跟着马一直跑
    local pAttachParent = pUEActor:GetAttachParentActor()
    if pAttachParent then
        pUEActor:K2_DetachFromActor(EDetachmentRule.KeepWorld, EDetachmentRule.KeepWorld, EDetachmentRule.KeepWorld)
    end

    --通知蓝图
    pUEActor.IsDead = true

    if GlobalVariableSystem:IsClient() then
        LOG(self, "HandleIsDeadChanged 4")
        -- 客户端隐藏角色Actor
        local function fnHideActor()
            LOG(self, "HandleIsDeadChanged 8")
            self.tbDelayHideActorHandle = nil
            pUEActor:UnRegisterFromSignificance()

            pUEActor:SetActorHiddenInGame(true)
            local ChildActors = pUEActor:GetAttachedActors()
            for i,v in ipairs(ChildActors) do
                v:SetActorHiddenInGame(true)
            end

            DisablePlayerCollision(self)

            DisableMovement(self)
        end
        local nHideHumanActorDelayTime
        if self.Owner.ObjectType == GameObjectTypeDef.Npc then
            local tbNpcTemplate = NPCDataTable:GetTemplate(self.Owner.nTemplateId)
            nHideHumanActorDelayTime = tbNpcTemplate.nHideDelayTimeAfterDeath
        else
            nHideHumanActorDelayTime = DungeonIni.tbDead.nHideHumanActorDelayTime
        end
        if nHideHumanActorDelayTime > 0 then
            LOG(self, "HandleIsDeadChanged 5")
            self.tbDelayHideActorHandle = DelayTimer:DelayRun(fnHideActor, nHideHumanActorDelayTime)
        else
            LOG(self, "HandleIsDeadChanged 6")
            fnHideActor()
        end

        -- 客户端隐藏头顶名字片
        local HeadInfoComponent = self.Owner.HeadInfoComponent
        if HeadInfoComponent then
            LOG(self, "HandleIsDeadChanged 7")
            HeadInfoComponent:SetVisibility(false)
        end

        -- 客户端播放死亡特效
        SelfAnimationHelper:PlayHumanAnimation(self.Owner, SelfAnimationHelper.AnimDef.HUMAN_DEAD)
        -- if self.Owner.ObjectType ~= GameObjectTypeDef.Npc then
        --     local nHumanDeadParticleResId = DungeonIni.tbDead.nHumanDeadParticleResId
        --     BattleAbilitySystem:PlayParticleEffect(self.Owner, nHumanDeadParticleResId)
        -- end
    else
        DisablePlayerCollision(self)
        DisableMovement(self)
    end
end

function HumanBattlePropertyComponent:HandleIsDyingChanged(bIsDying)
    local Owner = self.Owner
    Owner.HumanWeaponComponent:OnDyingChanged(bIsDying)
    Owner.GameVehicleComponent:OnDyingChanged(bIsDying)
    Owner.HumanMovementStateComponent:OnDyingChanged(bIsDying)
end

function HumanBattlePropertyComponent:HandleIsRescuingChanged(bIsRescuing)
    local HumanMovementStateComponent = self.Owner.HumanMovementStateComponent
    if HumanMovementStateComponent then
        HumanMovementStateComponent:SetRescuingChanged(bIsRescuing)
    end
end

function HumanBattlePropertyComponent:SetSwimmingStamina(nStamina)
    self:SetPropOriginValue(PropName.nSwimmingStamina, nStamina)
end

function HumanBattlePropertyComponent:GetSwimmingStamina()
    return self:GetProp(PropName.nSwimmingStamina)
end

function HumanBattlePropertyComponent:GetMaxDyingHp()
    return self:GetProp(PropName.nHumanMaxDyingHp)
end

function HumanBattlePropertyComponent:GetRescuedHp()
    return self:GetProp(PropName.nHumanRescuedHp)
end

function HumanBattlePropertyComponent:GetDyingHpReduceSpeed()
    return self:GetProp(PropName.nHumanDyingHpReduceSpeed)
end

function HumanBattlePropertyComponent:GetMountCoefficient()
    return self:GetProp(PropName.nMountCoefficient)
end

function HumanBattlePropertyComponent:GetRescuedTime()
    return self:GetProp(PropName.nHumanRescuedTime)
end

function HumanBattlePropertyComponent:GetResistFallOffHorseCoefficient()
    return self:GetProp(PropName.nResistFallOffHorseCoefficient)
end
-- Override Protected end
--------------------------------------

return HumanBattlePropertyComponent