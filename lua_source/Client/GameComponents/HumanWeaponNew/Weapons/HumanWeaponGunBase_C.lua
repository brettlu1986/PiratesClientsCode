local luaclass = require("luaclass")
local HumanWeaponGunBase = require("HumanWeaponGunBase")
local HumanWeaponGunBase_C = luaclass("HumanWeaponGunBase_C", HumanWeaponGunBase)

--local Timer = require("Timer")
--local HumanWeaponHelper = require("HumanWeaponHelper")
local HumanWeaponMisc = require("HumanWeaponMisc")
local HumanWeaponDef = require("HumanWeaponDef")
local HumanWeaponCalculator = require("HumanWeaponCalculator")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local ClientEventDef = require("ClientEventDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local AutoBattleSystem = require("AutoBattleSystem")
local HumanWeaponHelper = require("HumanWeaponHelper")
local PropName = require("PropName")
local AnimDef = require("AnimDef")
local HumanWeaponHitEffectHelper = require("HumanWeaponHitEffectHelper")

local AttackExitType = HumanWeaponMisc.AttackExitType
local FIRE_TYPE = HumanWeaponDef.FireType

local pTempVector1 = Vector()
local pTempVector2 = Vector()
local TempTable = {}
local TempTable2 = {}

HumanWeaponGunBase_C.tbAttackInfo = nil
HumanWeaponGunBase_C.tbSubAttackInfo = nil
HumanWeaponGunBase_C.bWaitingReloadResult = false
HumanWeaponGunBase_C.bNeedPlayAttackMontage = true
local function CopyVector(Dest, From)
    Dest.X = From.X
    Dest.Y = From.Y
    Dest.Z = From.Z
end

local function TableToTempVector1(tbVector)
    CopyVector(pTempVector1, tbVector)
    return pTempVector1
end

local function TableToTempVector2(tbVector)
    CopyVector(pTempVector2, tbVector)
    return pTempVector2
end

function HumanWeaponGunBase_C:PlayAttackMontage()
    if not self.bNeedPlayAttackMontage then  
        return 
    end
    local szAttackKey = self.bAiming and AnimDef.ON_GUN_AIM_FIRE or AnimDef.ON_GUN_FIRE
    self.OwnerComponent:PlayMontageWithAnimKey(szAttackKey)
end

function HumanWeaponGunBase_C:OnStateActivate(nState)
    HumanWeaponGunBase_C.super.OnStateActivate(self, nState)

    if(nState == HumanWeaponStateDef.RELOADING) then
        self.bWaitingReloadResult = true
        EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_RELOADED_ACTIVATE,
            self.nCurrentStateElapsedTime, self.Owner:GetServerInstanceId())
    elseif(nState == HumanWeaponStateDef.HOLDED) then
        if((self.bServer or self.OwnerComponent.bPlayerSelf) and not self.bWaitingReloadResult) then
            -- self.nRemainAmmo = nil
            -- self:GetAmmoInfo()
            -- logdebug("OnStateActivate self:GetCurrentAmmo()", self:GetCurrentAmmo())
            if(self:GetCurrentAmmo() == 0) then
                self.OwnerComponent:Reload()
            end
        end

    elseif(nState == HumanWeaponStateDef.UNHOLDED) then
        -- 这个需要开吗？防止换弹过程中换枪什么的
        self.bWaitingReloadResult = false
        self.nRemainAmmo = nil
    end
end

function HumanWeaponGunBase_C:OnStateDeactivate(nState, bCancel)
    HumanWeaponGunBase_C.super.OnStateDeactivate(self, nState, bCancel)

    -- 单机逻辑
    if(nState == HumanWeaponStateDef.RELOADING) then
        EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_RELOADED_DEACTIVATE, self.Owner:GetServerInstanceId(), bCancel)
        if(bCancel) then
            self:CancelReload()
        elseif(self.bServer) then
            self:ReloadImpInServer()
        end
    end
end

function HumanWeaponGunBase_C:OnCreated(OwnerComponent, nInstanceId, nTemplateId, nSlot)
    HumanWeaponGunBase_C.super.OnCreated(self, OwnerComponent, nInstanceId, nTemplateId, nSlot)

    -- 这么搞是为了不频繁创建table
    self.tbAttackInfo = {}
    self.tbSubAttackInfo = {
        OnActivate = self.AttackInClient,   -- 攻击，子类重载
        OnDeactivate = self.OnAttackFinished,   -- 攻击结束
        nDuration = 0,                          -- 持续时间
    }
    self:AddAttackSubState(self.tbAttackInfo, self.tbSubAttackInfo)
end

function HumanWeaponGunBase_C:SetAmmoReloadResult(nCurrentAmmo)
    self:SetCurrentAmmo(nCurrentAmmo)
    self.bWaitingReloadResult = false
    local tbProperty = self:GetProperty()
    if self.OwnerComponent.bInAttacking and tbProperty[HumanWeaponDef.Property.FireType] == HumanWeaponDef.FireType.Auto then 
        self.OwnerComponent:StartAttack()
    end
end

function HumanWeaponGunBase_C:IsWaitingReloadResult()
    return self.bWaitingReloadResult
end

function HumanWeaponGunBase_C:AmmoCheck()
    if not self.bServer then 
        local nRemainAmmo = self.nRemainAmmo
        nRemainAmmo = nRemainAmmo - self:GetOwnerProperty(PropName.nBulletCostPerAttack)
        self.nRemainAmmo = nRemainAmmo
        assert(nRemainAmmo >= 0)
    end    
end

function HumanWeaponGunBase_C:AttackInClient(tbAttackInfo)
    self:FillBPAttackParams(tbAttackInfo)
    self:PlayAttackMontage()
    self.pWeaponActor:PlayAttackEffect()
    self:AmmoCheck()
    EventManager:OnFireEvent(ClientEventDef.EV_HUMAN_WEAPON_GUN_ATTACK, self)
    local tbProperty = self:GetProperty()
    self.OwnerComponent:CreateDispersionTimer(tbProperty.nDispersionRecover)
end

function HumanWeaponGunBase_C:ShakeCamera()
    local tbProperty = self:GetProperty()
    local nDuration, ta, ra, po, bRecoverV = HumanWeaponCalculator.CaculateRecoil(self.Owner, tbProperty, self.bAiming)
    local bFollowPitch = not self.bAiming
    local nShakeCount, bRecoil, nFov, nDecayParam = 1, true, 0, 0
    EventManager:OnFireEvent(ClientEventDef.EV_FIRE_CAMERA_SHAKE, ta, ra, po, nDuration, nFov, nDecayParam, nShakeCount, bRecoil, bFollowPitch, bRecoverV)
    EventManager:OnFireEvent(ClientEventDef.EV_TO_FIRE_AIM_ABSORPTION, self.Owner, tbProperty.nFireAbsorptionSpeed, tbProperty.nFireAbsorptionInterp)
end

function HumanWeaponGunBase_C:OnAttackFinished(tbAttackInfo, bCancel)
    if(bCancel) then
        return
    end
    -- 这里可以播放枪口打完子弹的特效
    self.pWeaponActor:StopAttackEffect()
end

function HumanWeaponGunBase_C:GenerateAttackInfo()
    local tbProperty = self:GetProperty()
    assert(tbProperty)

    local tbAttackInfo = self.tbAttackInfo
    local tbSubAttackInfo = self.tbSubAttackInfo
    -- 枪从打出就开始算cd了，cd-duration就是真正的cd时间
    -- local nCD = tbProperty.nCD
    -- local nAttackDuration = tbProperty.nRateOfFire
    local nCD = self:GetOwnerProperty(PropName.nAttackCD)
    local nAttackDuration = self:GetOwnerProperty(PropName.nAttackRate)
    tbAttackInfo.nCD = nCD > nAttackDuration and (nCD - nAttackDuration) or nil
    tbAttackInfo.nExitTypeWhenFinish = AttackExitType.CURRENT_STATE_FINISHED

    local nTimes = 0
    local nFireType = tbProperty.nFireType

    if(nFireType == FIRE_TYPE.Single) then
        nTimes = 1
    elseif(nFireType == FIRE_TYPE.Triple) then
        local nMaxAmmo = 3
        local nCurrentAmmo = self:GetCurrentAmmo()
        nTimes = nCurrentAmmo < nMaxAmmo and nCurrentAmmo or nMaxAmmo
    else
        nTimes = self:GetCurrentAmmo()
        tbAttackInfo.nExitTypeWhenFinish = AttackExitType.ALL_STATE_FINISHED
    end

    tbAttackInfo.nAllLoopCount = nTimes
    tbSubAttackInfo.nDuration = nAttackDuration

    return tbAttackInfo
end

function HumanWeaponGunBase_C:FillBPAttackParams(tbAttackInfo)
    -- 这块先这么凑合吧，从蓝图挪过来太累
    local pWeaponActor = self.pWeaponActor
    local bAim = self.bAiming
    local tbWeaponProperty = self:GetProperty()
    local nDispersionRatio = self:GetOwnerProperty(PropName.nDispersionRatio)
    local SpreadAngle = HumanWeaponCalculator.CalculateSpreadAngle(self.OwnerComponent.Owner, tbWeaponProperty) 
    
    SpreadAngle.X = SpreadAngle.X * nDispersionRatio
    SpreadAngle.Y = SpreadAngle.Y * nDispersionRatio
    pWeaponActor.SpreadAngle = SpreadAngle
    pWeaponActor.DeviationX = bAim and tbWeaponProperty.nAimDeviationX or tbWeaponProperty.nDeviationX
    pWeaponActor.DeviationY = bAim and tbWeaponProperty.nAimDeviationY or tbWeaponProperty.nDeviationY
    pWeaponActor.DeviationX = pWeaponActor.DeviationX * nDispersionRatio
    pWeaponActor.DeviationY = pWeaponActor.DeviationY * nDispersionRatio
    local MaxBulletCountOnceTime = self:GetOwnerProperty(PropName.nBulletCostPerAttack) * self:GetOwnerProperty(PropName.nBulletCountPerAttack)    
    pWeaponActor.MaxBulletCountOnceTime = MaxBulletCountOnceTime

    pWeaponActor.BulletDamage =self:GetOwnerProperty(PropName.nDamagePerAttack)
    pWeaponActor.BulletSpeed = self:GetOwnerProperty(PropName.nBulletInitialSpeed)
    pWeaponActor.BulletRange = self:GetOwnerProperty(PropName.nAttackRegion)*100
    pWeaponActor.SectorAngle = self:GetOwnerProperty(PropName.nSectorDegree)   
end

function HumanWeaponGunBase_C:OnHitNotifies(StartPos, tbAttackEnds, tbTackers, tbDamageTypes)
    local pWeaponActor = self.pWeaponActor
    if not pWeaponActor then
        return
    end
    local OnHitNotify = pWeaponActor.OnHitNotify
    StartPos = TableToTempVector1(StartPos)
    if tbTackers and tbDamageTypes and #tbDamageTypes > 0 then
        for i, szDamageType in ipairs(tbDamageTypes) do
            local pTaker = GameObjectSystem:FindByInstanceId(tbTackers[i])
            if pTaker and GameObjectSystem:IsCharacter(pTaker) and not pTaker:IsDead() then
                local pLocation = HumanWeaponHelper.GetLocationByHitType(pTaker.pUEActor, szDamageType)
                if pLocation then
                    -- local Dir = KismetMathLibrary.GetDirectionUnitVector(StartPos, pLocation)
                    local pHitPlayer, pHitResult = OnHitNotify(pWeaponActor, StartPos, pLocation)
                    if pHitPlayer then
                        local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pHitPlayer)
                        local tbObject = GameObjectSystem:FindByUniqueId(nUniqueID)
                        self:PlayHitAnimation(tbObject)
                        local nHumanBodyDef = HumanWeaponHelper.GetHitBodyType(pHitResult)
                        HumanWeaponHitEffectHelper:PlayHitEffectAndSound(tbObject, nHumanBodyDef, self.nTemplateId, pHitResult)
                    end
                end
            end
        end
    else 
        for _, v in ipairs(tbAttackEnds) do
            local pHitPlayer, pHitResult = 
            OnHitNotify(pWeaponActor, StartPos, TableToTempVector2(v))
            if pHitPlayer then
                local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pHitPlayer)
                local tbObject = GameObjectSystem:FindByUniqueId(nUniqueID)
                --self:PlayHitAnimation(tbObject)
                local nHumanBodyDef = HumanWeaponHelper.GetHitBodyType(pHitResult)
                HumanWeaponHitEffectHelper:PlayHitEffectAndSound(tbObject, nHumanBodyDef, self.nTemplateId, pHitResult)
            end
        end        
    end
end


function HumanWeaponGunBase_C:OnRepGunAttackRoute(tbRepData)
    if(tbRepData == nil) then
        return
    end
    self:PlayAttackMontage()
    if self.pWeaponActor then 
        self.pWeaponActor:PlayAttackEffect()
    end
    self:OnHitNotifies(tbRepData.start, tbRepData.ends)
end

function HumanWeaponGunBase_C:OnRepGunAttackOnceResult(tbRepData)
    if(tbRepData == nil) then
        return
    end
    if(not self.bSelf or AutoBattleSystem:InAutoBattle()) then
        -- 自己已经播过了
        self:PlayAttackMontage()
        self.pWeaponActor:PlayAttackEffect()
    end

    TempTable = {}
    TempTable[1] = tbRepData.end_pos
    local tbTackers = {tbRepData.taker}
    if tbRepData.hit_type and tbRepData.hit_type > 0 then
        local szDamageType = HumanWeaponHelper.GetHumanPartPropertyName(tbRepData.hit_type)
        TempTable2 = {}
        TempTable2[1] = szDamageType
        self:OnHitNotifies(tbRepData.start, TempTable, tbTackers, TempTable2)
    else
        self:OnHitNotifies(tbRepData.start, TempTable)
    end
end

function HumanWeaponGunBase_C:OnRepGunAttackMultiResult(tbRepData)
    if(tbRepData == nil) then
        return
    end

    if(not self.bSelf or AutoBattleSystem:InAutoBattle()) then
        -- 自己已经播过了
        self:PlayAttackMontage()
        self.pWeaponActor:PlayAttackEffect()
    end

    local tbEnds = {}
    for _, v in pairs(tbRepData.hit_ends) do
        table.insert(tbEnds, v)
    end
    for _, v in pairs(tbRepData.miss_ends) do
        table.insert(tbEnds, v)
    end

    if tbRepData.hit_types and #tbRepData.hit_types > 0 then
        TempTable2 = {}
        for i,v in ipairs(tbRepData.hit_types) do
            local szDamageType = HumanWeaponHelper.GetHumanPartPropertyName(v)
            TempTable2[i] =  szDamageType
        end

        self:OnHitNotifies(tbRepData.start, tbEnds, tbRepData.takers, TempTable2)
    else
        -- self:OnHitNotifies(tbRepData.start, TempTable)
        self:OnHitNotifies(tbRepData.start, tbEnds)
    end
end

function HumanWeaponGunBase_C:CancelReload()
    HumanWeaponGunBase_C.super.CancelReload(self)
    local nState = self.nState
    if nState ==  HumanWeaponStateDef.RELOADING then
        self:StopMontage(nState)
    end
    self.bWaitingReloadResult = false
end

function HumanWeaponGunBase_C:IsReloading()
    return self.OwnerComponent:GetCurrentState() == HumanWeaponStateDef.RELOADING and true or false
end
return HumanWeaponGunBase_C