-----------------------------------------------------
--File Name    : UPPlayerHeadHp.lua
--Author       : lzheng
--Create Time  : 2019-09-20
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPWidgetBase = require("UPWidgetBase")
local UPPlayerHeadHp = luaclass("UPPlayerHeadHp", UPWidgetBase)

local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local PlayerHeadInfoHelper = require("PlayerHeadInfoHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
 
local DamageTypeEx = require("DamageTypeEx")
local GameObjectTypeDef = require("GameObjectTypeDef")
local CommonEventDef = require("CommonEventDef")
local ClientEventDef = require("ClientEventDef")
local DamageHurtDef = require("DamageHurtDef")
local ShipRegionTypeDef = require("ShipRegionTypeDef")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")
local HeadHpIni = require("HeadHpIni")
local Timer = require("Timer")

local DEFAULT_HP_LEVEL = -1
local NPC_PEACE_STATE = 1
local ShipHurtTagDataTable

UPPlayerHeadHp.nCurrentHpLevel = DEFAULT_HP_LEVEL
UPPlayerHeadHp.OwnerPlayer = nil
UPPlayerHeadHp.nMaxHp = 0
UPPlayerHeadHp.tbCacheDamage = nil
UPPlayerHeadHp.bEnterDying = false

local CACHE_DAMGE_TIMER = "CacheDamageTimer"
local DAMAGE_FINISH_TIMER = "FinishTimer"

local MIN_PERCENT = 0.01
local tbExcludeDamageNumType = 
{
    DamageTypeEx.HUMAN_FIREBOMB,
    DamageTypeEx.SHIP_LEAKING,
    DamageTypeEx.SHIP_FIRING,
}

local DEFAULT_REGION = 0
local DEFAULT_REGION_COLOR = "FFFFFFFF"
local DEFAULT_HURT_TAG = DamageHurtDef.HURT_NONE
local VALID_CORE = 1
--人或者船的 重伤状态不一定会及时同步下来，有可能再一次受伤直接进入重伤，这时候重伤血条颜色可能会刷新不及时，特别是手枪或者曲射炮这种多次受伤的
local function CheckUseDyingHpColor(self, nHp, nDamage)
    local bUseDyingHp = false  

    local nHpAfterDamage = nHp - nDamage 
    
    local bDying = self.OwnerPlayer:IsDying()
    if nHpAfterDamage <= 0 and not bDying then   
        bUseDyingHp = true
    end
    return bUseDyingHp
end

local function GetCurrentHpLevel(self, nHpPercent, nHp, nDamage)
    local nCurrentHpLevel = DEFAULT_HP_LEVEL

    if not self.bEnterDying then   
        self.bEnterDying = CheckUseDyingHpColor(self, nHp, nDamage)
    end

    if not self.OwnerPlayer:IsDying() and not self.bEnterDying then
        local tbHpLevelPercents = HeadHpIni.tbHeadHpColors.tbHpLevelPercents
        for i,v in ipairs(tbHpLevelPercents) do
            if nHpPercent >= v then
                nCurrentHpLevel = i
                break
            end
        end
    end
    return nCurrentHpLevel
end

local function IsOwnerPlayerOther(self)
    return self.OwnerPlayer and self.OwnerPlayer:GetObjectType() == GameObjectTypeDef.PlayerOther 
end   

local function IsOwnerPlayerSelf(self)
    return self.OwnerPlayer and self.OwnerPlayer:GetObjectType() == GameObjectTypeDef.PlayerSelf 
end

local function IsOwnerDamageNpc(self)
    if self.OwnerPlayer and self.OwnerPlayer:GetObjectType() == GameObjectTypeDef.Npc then
        local tbNpcTemplateData = self.OwnerPlayer:GetTemplateData()
        return tbNpcTemplateData and tbNpcTemplateData.nInitState ~= NPC_PEACE_STATE  
    end
    return false
end

local function OnHpChanged(self, _, nMaxHp, _)
    self.nMaxHp = nMaxHp
end

local function SetHpVisible(self, bVisible)
    if self.pWidgetRef then 
        if bVisible then 
            self.Owner:SetVisibility(bVisible)
        end
        self.pWidgetRef:SetVisibility(bVisible and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Hidden)
        if self.Owner.pWidgetComponent then 
            self.Owner.pWidgetComponent:RequestRedraw()
        end
    end
end

local function IsTrainningCamp() 
    return GlobalVariableSystem:IsInTrainingCamp(BattleGameModeSystem.nDungeonId)
end

local function RefreshPlayerHpInfo(self, nHp, nMaxHp, nDamage)
    if IsTrainningCamp() then return end
    if not PlayerHeadInfoHelper.CanShowPlayerHp(self.OwnerPlayer) then return end
    if nDamage == 0 then return end
    
    --血量随时刷新
    if self.Owner.pWidgetComponent then
        self.Owner.pWidgetComponent:SetManuallyRedraw(false)
    end
    SetHpVisible(self, true)
    self:RefreshPlayerHp(nHp, nMaxHp, nDamage)
end

local function IsDestructibleObjectDamageInTrainningCamp( tbTaker)
    if tbTaker and tbTaker:GetObjectType() == GameObjectTypeDef.DestructibleObject and IsTrainningCamp() then
        return true
    end
    return false
end

local function IsExcludeDamageNum(nDamageType)
    for _, v in pairs(tbExcludeDamageNumType) do 
        if nDamageType == v then  
            return true
        end
    end
    return false
end

local function OnTakeDamage(self, tbTaker, tbCauser, nDamage, nDamageType, nHp, nWeaponTempId, tbExtraData)
    -- logdebug("on take damage :", tbExtraData.nRegionType, tbExtraData.nHurtTag)

    local bPlayerOtherTakeDamage = false 
    local bNpcTakeDamage = false
    local bSelfShipTakeDamage = false

    local PlayerSelf = GamePlayerSelfHelper:Get()
    -- PlayerOther take damage condition
    if IsOwnerPlayerOther(self) and not IsTrainningCamp() then
        local bOwnerIsTaker = tbTaker and tbTaker.nServerInstanceId == self.OwnerPlayer.nServerInstanceId 
        local bIsCauserClient = tbCauser and tbCauser.nServerInstanceId == PlayerSelf:GetServerInstanceId()
        local bTeammate = PlayerHeadInfoHelper.IsTeammate(self.OwnerPlayer)
        bPlayerOtherTakeDamage = bOwnerIsTaker and bIsCauserClient and not bTeammate
    end

    --npc take damage condition
    if IsOwnerDamageNpc(self) then   
        local bOwnerIsTaker = tbTaker and tbTaker.nServerInstanceId ==  self.OwnerPlayer.nServerInstanceId 
        local bIsCauserClient = tbCauser and tbCauser.nServerInstanceId == PlayerSelf:GetServerInstanceId()
        bNpcTakeDamage = bOwnerIsTaker and bIsCauserClient
    end

    --Player Self Ship TakeDamage 
    if IsOwnerPlayerSelf(self) then  
        local bOwnerIsTaker = tbTaker and tbTaker.nServerInstanceId ==  self.OwnerPlayer.nServerInstanceId 
        local bOwnerShip = self.OwnerPlayer and self.OwnerPlayer:IsShip()
        local bInAim =  BattleShipWeaponSystem:GetIsInAim(self.OwnerPlayer)
        local bEnabled = PlayerHeadInfoHelper.CanShowSelfShipDamageNum()
        bSelfShipTakeDamage = bOwnerIsTaker and bOwnerShip and (not bInAim) and bEnabled
    end

    --显示血条的
    if ( bPlayerOtherTakeDamage or bNpcTakeDamage ) then  
        RefreshPlayerHpInfo(self, nHp, self.nMaxHp, nDamage)
    end  

    local bDestructObjectDamageInTrain = IsDestructibleObjectDamageInTrainningCamp(tbTaker)
    if ( bPlayerOtherTakeDamage or bNpcTakeDamage or bDestructObjectDamageInTrain or bSelfShipTakeDamage) then  
        if not PlayerHeadInfoHelper.CanShowPlayerDamageNum(self.OwnerPlayer) then return end
        if IsExcludeDamageNum(nDamageType) then return end

        --伤害需要起一个timer, 小于一个 最小时间内的多次伤害需要cache起来
        local DamageTimer = Timer.GetOwnerTimer(self, CACHE_DAMGE_TIMER)
        --取受伤目标
        local tbDamageTarget = bDestructObjectDamageInTrain and tbTaker or self.OwnerPlayer
        local nDamageTargetInstanceId = tbDamageTarget:GetServerInstanceId()

        --因为存在多发击中的情况，万一同时击中不同目标，伤害需要根据目标来存
        if self.tbCacheDamage == nil then self.tbCacheDamage = {} end
        if self.tbCacheDamage[nDamageTargetInstanceId] == nil then self.tbCacheDamage[nDamageTargetInstanceId] = {} end
        --再按照武器来存伤害数据
        local tbTargetCacheDamage = self.tbCacheDamage[nDamageTargetInstanceId]
        if tbTargetCacheDamage[nWeaponTempId] == nil then 
            tbTargetCacheDamage[nWeaponTempId] = {} 
            tbTargetCacheDamage[nWeaponTempId].tbDamageInfo = {}
            tbTargetCacheDamage[nWeaponTempId].tbDamageCount = {}
            tbTargetCacheDamage[nWeaponTempId].nHurtFlag = DEFAULT_HURT_TAG
        end
        
        local bCalculateDamage = false
        if DamageTimer == nil then  
            Timer.StartOwnerTimer(self, CACHE_DAMGE_TIMER, self.OnCacheDamageTimeUp, HeadHpIni.nHeadHpMinTime)
            bCalculateDamage = true 
        else  
            if DamageTimer:GetElapsedTime() < HeadHpIni.nHeadHpMinTime then  
                bCalculateDamage = true
            end
        end 

        if bCalculateDamage then 
            --计算当前击中目标伤害
            local tbCacheDamage = tbTargetCacheDamage[nWeaponTempId]
            --用于船显示要害，漏水，着火的图标用
            local nExtraHurtFlag = tbExtraData.nHurtTag or DEFAULT_HURT_TAG
            tbCacheDamage.nHurtFlag = tbCacheDamage.nHurtFlag | nExtraHurtFlag

            local nRegion = tbExtraData.nRegionType
            if tbExtraData.nRegionType == nil or tbExtraData.nRegionType == DEFAULT_REGION then  
                nRegion = DEFAULT_REGION
            end
            --计算击中不同位置伤害累计
            if tbCacheDamage.tbDamageInfo[nRegion] == nil then  
                tbCacheDamage.tbDamageInfo[nRegion] = 0
            end
            tbCacheDamage.tbDamageInfo[nRegion] = tbCacheDamage.tbDamageInfo[nRegion] + nDamage

            --计算击中不同位置次数累计
            if tbCacheDamage.tbDamageCount[nRegion] == nil then  
                tbCacheDamage.tbDamageCount[nRegion] = 0
            end
            tbCacheDamage.tbDamageCount[nRegion] = tbCacheDamage.tbDamageCount[nRegion] + 1
        end

        --血条隐藏相关逻辑
        local nShowDuration = HeadHpIni.nHeadHpDuration
        if nDamage ~= 0 then
            local nHpPercent = (nHp - nDamage) * 1.0 / self.nMaxHp
            if nHpPercent < MIN_PERCENT then
                nShowDuration = HeadHpIni.nHeadHpEmptyDuration
            end
        end
        Timer.StartOwnerTimer(self, DAMAGE_FINISH_TIMER, self.OnShowDamageFinish, nShowDuration)
    end
end

local function OnDyingChanged(self, tbDyingOwner, bIsDying)
    
    local bOwnerIsDying = tbDyingOwner and tbDyingOwner.nServerInstanceId == self.OwnerPlayer.nServerInstanceId 
    if bOwnerIsDying and not bIsDying then  
        self.bEnterDying = false
    end
end

local function RegisterEvent(self)
    local bOwnerPlayerOther = IsOwnerPlayerOther(self)
    local bOwnerDamageNpc = IsOwnerDamageNpc(self)
      
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTakeDamage)
    
    if bOwnerPlayerOther or bOwnerDamageNpc then 
        local PropertyComponent = self.OwnerPlayer:GetCurrentPropertyComponent()
        OnHpChanged(self, nil, PropertyComponent:GetMaxHp() , nil)
        EventHelper:RegisterLuaDelegate(PropertyComponent.OnHpChanged, OnHpChanged, self)

        if bOwnerPlayerOther then
            EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED, self, OnDyingChanged)
        end
    end
end

local function ShowDamageInfoOnlyNum(self, tbCacheDamage, tbDamagetTarget)
    local pDamagePlayerLocation = PlayerHeadInfoHelper.GetDamageNumWorldStartLoc(tbDamagetTarget)
    for nWeaponId, tbWeaponDamageInfo in pairs(tbCacheDamage) do 
        local tbDamageInfo = tbWeaponDamageInfo.tbDamageInfo
        local tbCountInfo = tbWeaponDamageInfo.tbDamageCount
        local nRealCount = 0
        for nRegion, nCount in pairs(tbCountInfo) do 
            nRealCount = nRealCount + nCount
        end
        local nRealDamage = 0
        for nRegion, nDamage in pairs(tbDamageInfo) do 
            nRealDamage = nRealDamage + nDamage
        end

        if nRealDamage ~= 0 then
            local pDamageRatio = PlayerHeadInfoHelper.GetDamageRatio(nRealDamage, nWeaponId, nRealCount)
            local szColorStr, nFontSize = PlayerHeadInfoHelper.GetDamageColorStrAndFontSize(pDamageRatio)
            nFontSize = math.floor(nFontSize)
            self.EventHelper:FireEvent(ClientEventDef.EV_SHOW_FLOAT_NUM, pDamagePlayerLocation, nRealDamage, false, szColorStr, nFontSize)
        end
    end 
end  

local function ShowDamageInfoNumAndIcon(self, tbCacheDamage, tbDamagetTarget)
    if not tbDamagetTarget:IsShip() then  
        logerror("[PlayerHeadHp] will show damage info ,but target is not ship")
        return
    end
    local nShipTemplateId = tbDamagetTarget:GetShipTemplateId()
    local tbShipHurtTagData = ShipHurtTagDataTable:GetTemplate(nShipTemplateId)
    if tbShipHurtTagData == nil then  
        logerror("[PlayerHeadHp] will show damage info ,but tbShipHurtTagData is nil:", nShipTemplateId)
        return 
    end

    local pDamagePlayerLocation = PlayerHeadInfoHelper.GetDamageNumWorldStartLoc(tbDamagetTarget)
    local tbCorePart = tbShipHurtTagData.tbCoreTag
    local tbCorePartColor = tbShipHurtTagData.tbCoreColor
    for nWeaponId, tbWeaponDamageInfo in pairs(tbCacheDamage) do
        local tbDamageInfo = tbWeaponDamageInfo.tbDamageInfo
        local nHurtFlag = tbWeaponDamageInfo.nHurtFlag
        local tbCountInfo = tbWeaponDamageInfo.tbDamageCount

        local nRealDamage = 0
        for nRegion, nDamage in pairs(tbDamageInfo) do
            if tbCorePart[nRegion] and tbCorePart[nRegion] == VALID_CORE then  
                nHurtFlag = nHurtFlag | DamageHurtDef.HURT_CORE
            end
            nRealDamage = nRealDamage + nDamage
        end

        if nRealDamage ~= 0 then  
            local nMaxHitCountRegion, nMaxCount = DEFAULT_REGION, 0
            for nRegion, nCount in pairs(tbCountInfo) do 
                if nCount >= nMaxCount then  
                    nMaxCount = nCount
                    nMaxHitCountRegion = nRegion
                end
            end

            if nMaxHitCountRegion > ShipRegionTypeDef.DECK then   
                logerror("[PlayerHeadHp] wrong ship damage region type :", nMaxHitCountRegion)
            else  
                local szColorStr = nMaxHitCountRegion == DEFAULT_REGION and DEFAULT_REGION_COLOR or tbCorePartColor[nMaxHitCountRegion]
                -- log("final float info:", pDamagePlayerLocation.X, pDamagePlayerLocation.Y, pDamagePlayerLocation.Z, nRealDamage, szColorStr, HeadHpIni.nShipDamageFontSize, nHurtFlag)
                self.EventHelper:FireEvent(ClientEventDef.EV_SHOW_FLOAT_DAMAGE_INFO, pDamagePlayerLocation, nRealDamage, szColorStr, HeadHpIni.nShipDamageFontSize,
                    nHurtFlag)
            end
        end
    end
end

function UPPlayerHeadHp:OnCacheDamageTimeUp()
    for nInstanceId, tbCacheDamage in pairs(self.tbCacheDamage) do 
        local tbGameObject = GameObjectSystem:FindByInstanceId(nInstanceId)
        if tbGameObject then 
            if tbGameObject:GetObjectType() == GameObjectTypeDef.DestructibleObject then  
                ShowDamageInfoOnlyNum(self, tbCacheDamage, tbGameObject)
            else  
                if tbGameObject:IsHuman() then
                    ShowDamageInfoOnlyNum(self, tbCacheDamage, tbGameObject)
                else 
                    ShowDamageInfoNumAndIcon(self, tbCacheDamage, tbGameObject)
                end
            end
        end
    end
    self.tbCacheDamage = {}
    Timer.StopOwnerTimer(self, CACHE_DAMGE_TIMER)
end

function UPPlayerHeadHp:OnShowDamageFinish()
    if self.Owner.pWidgetComponent then
        self.Owner.pWidgetComponent:SetManuallyRedraw(true)
    end
    SetHpVisible(self, false)
end

function UPPlayerHeadHp:OnWidgetCreated()
    local pWidgetRef = self.pWidgetRef
    if not ShipHurtTagDataTable then
        ShipHurtTagDataTable = require("ShipHurtTagDataTable")
    end
    if pWidgetRef then 
        pWidgetRef.pgbHp.AnimDuration = HeadHpIni.nHpBarAnimTime
        pWidgetRef.pgbHp.TopAnimDuration = HeadHpIni.nHpBarTopAnimTime
        pWidgetRef.pgbHp.BeforeMiddleAnimDuration = HeadHpIni.nHpBarMidWaitTime
    end
    self.bEnterDying = false
end 

function UPPlayerHeadHp:OnUnload() 
    Timer.StopOwnerAllTimer(self, true)
end

function UPPlayerHeadHp:RefreshPlayerHp(nHp, nMaxHp, nDamage)
    local nHpPercent = (nHp - nDamage) * 1.0 / nMaxHp
    local pWidgetRef = self.pWidgetRef
    -- logdebug("damage , maxhp , nHp", nDamage, nMaxHp, nHp, nHpPercent)

    pWidgetRef.pgbHp:SetPercent(nHp * 1.0 / nMaxHp, false)
    pWidgetRef.pgbHp:SetPercent(nHpPercent, true)
    local nCurrentHpLevel = GetCurrentHpLevel(self, nHpPercent, nHp, nDamage)
    -- if nCurrentHpLevel ~= self.nCurrentHpLevel then
        self.nCurrentHpLevel = nCurrentHpLevel
        if  nCurrentHpLevel == DEFAULT_HP_LEVEL then
            pWidgetRef.pgbHp:SetTopImageTint(KMUMGLibrary.GetSlateColorFromHex(HeadHpIni.tbHeadHpColors.szDyingHpColor))
            pWidgetRef.imgHpBg:SetRenderOpacity(HeadHpIni.tbHeadHpColors.nDyingHpBgOpacity)
        else
            local tbHpLevelBgOpacities = HeadHpIni.tbHeadHpColors.tbHpLevelBgOpacities
            local tbHpLevelColors = HeadHpIni.tbHeadHpColors.tbHpLevelColors
            pWidgetRef.pgbHp:SetTopImageTint(KMUMGLibrary.GetSlateColorFromHex(tbHpLevelColors[nCurrentHpLevel]))
            pWidgetRef.imgHpBg:SetRenderOpacity(tbHpLevelBgOpacities[nCurrentHpLevel])
        end
    -- end
end

function UPPlayerHeadHp:SetHeadHpOwner(tbOwner)
    self.OwnerPlayer = tbOwner
    RegisterEvent(self)
end 


return UPPlayerHeadHp