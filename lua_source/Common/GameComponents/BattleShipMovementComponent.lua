local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local BattleShipMovementComponent = luaclass("BattleShipMovementComponent", GameComponentBaseClass)

local ShipMovementIni = require("ShipMovementIni")
local ShipPathMoveGearDataTable = require("ShipPathMoveGearDataTable")
local ShipDataTable = require("ShipDataTable")
local ShipGearDataTable = require("ShipGearDataTable")
local ShipMovementDef = require("ShipMovementDef")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local LuaPosture = ShipMovementDef.ShipPostureDef
local CppPosture = {
    [LuaPosture.FullSail]   = EShipPosture.FullSail,
    [LuaPosture.HalfSail]   = EShipPosture.HalfSail,
    [LuaPosture.Reef]       = EShipPosture.Reef,
    [LuaPosture.Sinking]    = EShipPosture.Sinking
}

local INVALID_LUA_POSTURE = -1
local tbShipGearData = {}
local tbPathMoveGearConfig = {}

BattleShipMovementComponent.pMovementComponent = nil
BattleShipMovementComponent.nLastPostureBeforeSink = INVALID_LUA_POSTURE

local function LOG(self, ...)
    log("[BattleShipMovementComponent]", self.Owner.szName, ...)
end

local function CreateShipGearData(GearId)
    tbShipGearData[GearId] = ShipGearData()
end

local function CreatePathMoveGearConfig(PathMoveId)
    tbPathMoveGearConfig[PathMoveId] = ShipPathMoveGearConfig()
end

local function CreateBasicGearConfigs(nShipTemplateId)
    local tbShipTemplate = ShipDataTable:GetTemplate(nShipTemplateId)
    if tbShipTemplate == nil then
        logerror("CreateBasicGearConfigs tbShipTemplate error, id is", nShipTemplateId)
    end
    local tbTemplateArray = ShipGearDataTable:GetTemplateArray(tbShipTemplate.nGearId)
    local tbShipGearDataArray = {}
    for i, tbTemplate in ipairs(tbTemplateArray) do
        if tbShipGearData[i] == nil then
            CreateShipGearData(i)
        end
        tbShipGearData[i].LinearAcceleration = tbTemplate.nLinearAcceleration
        tbShipGearData[i].LinearDeceleration = tbTemplate.nLinearDeceleration
        tbShipGearData[i].MaxLinearSpeed = tbTemplate.nMaxLinearSpeed
        tbShipGearData[i].AngularAcceleration = tbTemplate.nAngularAcceleration
        tbShipGearData[i].MaxAngularSpeed = tbTemplate.nMaxAngularSpeed
        tbShipGearData[i].AngularDeceleration = tbTemplate.nAngularDeceleration
        table.insert(tbShipGearDataArray, tbShipGearData[i])
    end
    return tbShipGearDataArray
end

local function CreatePathMoveGearConfigs()
    local tbPathMoveGearConfigs = ShipPathMoveGearDataTable.tbContainer
    local PathMoveGearConfigArray = {}
    for i = 1, #tbPathMoveGearConfigs do
        local tbItem = tbPathMoveGearConfigs[i]
        if tbPathMoveGearConfig[i] == nil then
            CreatePathMoveGearConfig(i)
        end
        tbPathMoveGearConfig[i].MaxSteerAngle = tbItem.nMaxSteerAngle
        tbPathMoveGearConfig[i].MinDistance = tbItem.nMinDistance
        PathMoveGearConfigArray[i] = tbPathMoveGearConfig[i]
    end
    return PathMoveGearConfigArray
end

local function RestoreLastPosture(self)
    local pLastPosture = self.Owner.pLastPosture
    if pLastPosture then
        self.pMovementComponent:SetPosture(pLastPosture)
        self.Owner.pLastPosture = nil
        log("restore posture :",self.Owner.szName)
    end
end

local function OnPlayerShipToChangeServer(self, tbPlayer)
    if tbPlayer == self.Owner then
        -- 没有什么位置好放，拿SelfOwner临时存一下
        tbPlayer.pLastPosture = tbPlayer:GetModelActor().ShipMovementComponent:GetPosture()
    end
end


-- @server only
-- 记住当前姿势，并进入沉没姿势
local function EnterSinkPosture(self)
    LOG(self, "EnterSinkPosture")
    self.nLastPostureBeforeSink = enumtoint(self.pMovementComponent:GetPosture())
    self:SetPosture(LuaPosture.Sinking)
end

-- @server only
-- 离开沉没姿势，返回之前记住的姿势
local function ExitSinkPosture(self)
    LOG(self, "ExitSinkPosture")
    if self.nLastPostureBeforeSink ~= INVALID_LUA_POSTURE then
        self:SetPosture(self.nLastPostureBeforeSink)
        self.nLastPostureBeforeSink = INVALID_LUA_POSTURE
    end
end

local function OnIsDyingChanged(self, bIsDying)
    if bIsDying then
        EnterSinkPosture(self)
    else
        ExitSinkPosture(self)
    end
end

function BattleShipMovementComponent.InitMovementData(pMovementComponent, nShipTemplateId)
    local ShipMovementConfig = ShipMovementConfig()

    local tbSyncParams = ShipMovementIni.tbSyncParams
    ShipMovementConfig.ClientMinSyncInterval = tbSyncParams.nClientMinSyncInterval
    ShipMovementConfig.ClientMaxSyncInterval = tbSyncParams.nClientMaxSyncInterval
    ShipMovementConfig.ServerMaxSyncInterval = tbSyncParams.nServerMaxSyncInterval
    ShipMovementConfig.MaxSimTimeDiff = tbSyncParams.nMaxSimTimeDiff
    ShipMovementConfig.ClientMaxLerpTime = tbSyncParams.nClientMaxLerpTime

    local tbCollisionParams = ShipMovementIni.tbCollisionParams
    ShipMovementConfig.SweepPullBackDistance = tbCollisionParams.nSweepPullBackDistance
    ShipMovementConfig.MinAdjustDistanceForPenetration = tbCollisionParams.nMinAdjustDistanceForPenetration
    ShipMovementConfig.MaxAdjustStepsForPenetration = tbCollisionParams.nMaxAdjustStepsForPenetration
    ShipMovementConfig.MinSlideSpeedFactor = tbCollisionParams.nMinSlideSpeedFactor
    ShipMovementConfig.MaxImpactResolveTime = tbCollisionParams.nMaxImpactResolveTime
    ShipMovementConfig.ImpactMiddleAreaAngle = tbCollisionParams.nImpactMiddleAreaAngle

    local tbMisc = ShipMovementIni.tbMisc
    ShipMovementConfig.ReturnToBasicGearLinearDecelerationMultiplier = tbMisc.nReturnToBasicGearLinearDecelerationMultiplier
    ShipMovementConfig.ReturnToBasicGearAngularDecelerationMultiplier = tbMisc.nReturnToBasicGearAngularDecelerationMultiplier

    ShipMovementConfig.BasicGearConfigs = CreateBasicGearConfigs(nShipTemplateId)
    ShipMovementConfig.PathMoveGearConfigs = CreatePathMoveGearConfigs()

    local tbMovementParams = ShipMovementIni.tbMovementParams
    ShipMovementConfig.SafeTeleportDistance = tbMovementParams.nSafeTeleportDistance
    pMovementComponent:InitData(false, ShipMovementConfig)
end

function BattleShipMovementComponent:OnCreate(Owner, tbParams)
    BattleShipMovementComponent.super.OnCreate(self, Owner, tbParams)
    if tbParams then
        self.nShipTemplateId = tbParams.nShipTemplateId
    end
    if GlobalVariableSystem:IsServerLogic() then
        self.Owner.ShipBattlePropertyComponent.OnIsDyingChanged:Bind(OnIsDyingChanged, self)
    end
    EventManager:BindEventMethod(CommonEventDef.EV_ON_PLAYER_SHIP_TO_CHANGE_SERVER, self, OnPlayerShipToChangeServer)
    return true
end

function BattleShipMovementComponent:OnDestroy(...)
    EventManager:UnBindEventMethod(CommonEventDef.EV_ON_PLAYER_SHIP_TO_CHANGE_SERVER, self, OnPlayerShipToChangeServer)
    if GlobalVariableSystem:IsServerLogic() then
        self.Owner.ShipBattlePropertyComponent.OnIsDyingChanged:Unbind(OnIsDyingChanged, self)
    end
    BattleShipMovementComponent.super.OnDestroy(self, ...)
end

function BattleShipMovementComponent:OnActorPreCreated(pUEActor)
    BattleShipMovementComponent.super.OnActorPreCreated(self, pUEActor)
    self.pMovementComponent = pUEActor.ShipMovementComponent

    -- 客户端挪到了ActorChannelOpen时处理
    if(GlobalVariableSystem:IsServerLogic()) then
        BattleShipMovementComponent.InitMovementData(pUEActor.ShipMovementComponent, self.nShipTemplateId)
    end

    RestoreLastPosture(self)
end

function BattleShipMovementComponent:OnActorCreated(pUEActor)
    if(GlobalVariableSystem:IsServerLogic()) then
        pUEActor.ShipMovementComponent:MoveShipToSafeLocation()
    end
end

function BattleShipMovementComponent:SetPosture(nPosture)
    if self.pMovementComponent
    and (not self.Owner:IsDead())
    and ((not self.Owner:IsDying()) or (nPosture == LuaPosture.Sinking)) then
        self.pMovementComponent:SetPosture(CppPosture[nPosture])
        LOG(self, "SetPosture nPosture =", nPosture)
    end
end

function BattleShipMovementComponent:GetPosture()
    local nPosture = LuaPosture.FullSail
    if self.pMovementComponent then
        nPosture = enumtoint(self.pMovementComponent:GetPosture())
    end
    return nPosture
end

return BattleShipMovementComponent
