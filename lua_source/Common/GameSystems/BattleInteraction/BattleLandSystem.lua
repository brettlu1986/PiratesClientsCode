local luaclass = require("luaclass")
local BattleLandSystem = luaclass("BattleLandSystem")

local GameObjectSystem = dynamic_require("GameObjectSystem")
--local BattleVolumeHelper = require("BattleVolumeHelper")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local PropName = require("PropName")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleHumanWeaponSystemNew = dynamic_require("BattleHumanWeaponSystemNew")
-- local EventManager = require("EventManager")
-- local CommonEventDef = require("CommonEventDef")

local BATTLE_CHANGETOSHIP_BAR_ID = 1
local BATTLE_CHANGETOHUMAN_BAR_ID = 8

BattleLandSystem.TYPE_LAND = EPiratesGridRegionType.Land
BattleLandSystem.TYPE_OCEAN = EPiratesGridRegionType.Ocean
BattleLandSystem.TYPE_SHORE = EPiratesGridRegionType.Shore
BattleLandSystem.TYPE_PORT = EPiratesGridRegionType.Port
BattleLandSystem.CLOSEST_POSITION_RADIUS = 50000
BattleLandSystem.tbChanged = nil

-- local function RandomPoint(tbStartPoint, tbEndPoint)
--     local tbTransform = {}

--     tbTransform.X = math.random(math.floor(tbStartPoint.X), math.floor(tbEndPoint.X))
--     tbTransform.Y = math.random(math.floor(tbStartPoint.Y), math.floor(tbEndPoint.Y))
--     tbTransform.Z = tbStartPoint.Z
--     return tbTransform
-- end

-- local function RandomArray(tbGroup)
--     local nIndex = math.random(1, #tbGroup)
--     return tbGroup[nIndex]
-- end

-- local function GetYaw(tbCurLocation, tbDestLocation)
--     local pVector = KismetMathLibrary.Subtract_VectorVector(tbCurLocation, tbDestLocation)
--     local Rotator = KismetMathLibrary.Conv_VectorToRotator(pVector)
--     return Rotator.Yaw
-- end

local function ChangeToShip(tbPlayer, tbTransform)
    local pLocation = tbPlayer:GetLocation()
    log("landsystem change to ship: ", tbPlayer.szName, pLocation.X, pLocation.Y)
    local nShipId = tbPlayer:GetShipTemplateId()
    BattleGameModeSystem:GetGameMode():ChangeToShip(tbPlayer, nShipId, tbTransform)
end

local function ChangeToHuman(tbPlayer, tbTransform)
    local pLocation = tbPlayer:GetLocation()
    log("landsystem change to human", pLocation.X, pLocation.Y)
    local nHumanId = tbPlayer:GetHumanTemplateId()
    BattleGameModeSystem:GetGameMode():ChangeToHuman(tbPlayer, nHumanId, tbTransform)
end

local function CacheCurrentWeaponToHumanProperty(tbPlayer)
    BattleHumanWeaponSystemNew:SaveCurrentWeaponToOwner(tbPlayer)
end

local function GetCurLocation(self, tbPlayer)
    local bIsShip = tbPlayer:IsShip()
    local Location = tbPlayer:GetLocation()
    if bIsShip then
        return Location
    end

    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local nRegionType = GridTypeManager:GetRegionType(Location.X, Location.Y)
    if nRegionType ~= self.TYPE_PORT then
        return Location
    end

    -- 11月底过会版本临时修改，因为生成地形是格子状的，空气墙是线状的，导致人贴着空气墙可能在port区域。
    -- 如果是人，并且在port区域，则把坐标定为shore区域（因为无法通过port区域查找port区域）
    local bRet, NewLoction = GridTypeManager:GetClosestPositionOfRegionType(Location.X, Location.Y, self.TYPE_SHORE)
    if not bRet then
        logerror(string.format("BattleLandSystem GetCurLocation %d %s, pos=%d, %d", tbPlayer.nPlayerId, tbPlayer.szName, Location.X, Location.Y))
        return Location
    end
    return NewLoction
end

--------------------------------------------------------------------
function BattleLandSystem:Init()
    self.tbChanged = {}
    return true
end

function BattleLandSystem:Uninit()
    self.tbChanged = nil
end

function BattleLandSystem:GetTargetRegionTypeByLocation(tbPlayer)
    local Location = tbPlayer:GetLocation()
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local nRegionType = GridTypeManager:GetRegionType(Location.X, Location.Y)
    local bIsShip = tbPlayer:IsShip()
    local nTargetRegionType = nil

    if(nRegionType == self.TYPE_PORT and bIsShip) then
        nTargetRegionType = self.TYPE_SHORE
    -- 11月底过会版本临时修改，因为生成地形是格子状的，空气墙是线状的，导致人贴着空气墙可能在port区域。所以先不进行人的区域判断
    elseif (not bIsShip) then
    -- elseif(nRegionType == self.TYPE_SHORE and not bIsShip) then
        if(nRegionType == self.TYPE_SHORE or nRegionType == self.TYPE_PORT) then
            nTargetRegionType = self.TYPE_PORT
        end
    end

    -- if(nTargetRegionType ~= nil) then
    --     -- 检查是否能找到最近的点，如果找不到一样返回nil
    --     local bRet, _NewLoction = GridTypeManager:GetClosestPositionOfRegionType(Location.X, Location.Y,
    --         self.CLOSEST_POSITION_RADIUS, nTargetRegionType)
    --     if(not bRet) then
    --         nTargetRegionType = nil
    --     end
    -- end

    return nTargetRegionType
end

function BattleLandSystem:OnStartChangeDisplay(nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer == nil then
        return false
    end

    local nPlayerServerInstanceId = tbPlayer:GetServerInstanceId()
    -- 已由ProgressBarComponent统一接管
    -- local pUEActor = tbPlayer.pUEActor
    -- if(pUEActor.ShipMovementComponent) then
    --     pUEActor.ShipMovementComponent:StopMovementImmediately()
    -- elseif (pUEActor.CharacterMovement) then
    --     pUEActor.CharacterMovement:StopHumanMovementImmediately()
    -- end

    local nTargetRegionType = self:GetTargetRegionTypeByLocation(tbPlayer)
    if(nTargetRegionType == nil) then
        local Location = tbPlayer:GetLocation()
        log("TargetRegionType is nil", tbPlayer.szName, tbPlayer:GetServerInstanceId(), Location.X, Location.Y, Location.Z)
        return false
    end
    local bIsShip = tbPlayer:IsShip()
    if not bIsShip then
        CacheCurrentWeaponToHumanProperty(tbPlayer)
    end
    local nProgressBarId = bIsShip and BATTLE_CHANGETOHUMAN_BAR_ID or BATTLE_CHANGETOSHIP_BAR_ID
    local ProgressBarComponent = tbPlayer.ProgressBarComponent
    if ProgressBarComponent then
        local OnDisplaySuccess = function(tbParams)
            self:OnEndChangeDisplay(tbParams)
        end
        local OnDisplayAborted = function(tbParams)
            self:OnBreakChangingDisplay(tbParams)
        end
        local tbData = {}
        tbData.nTargetRegionType = nTargetRegionType
        tbData.nPlayerServerInstanceId = nPlayerServerInstanceId
        tbData.nSenderUniqueId = nSenderUniqueId

        local nControlModeSwitchSpeedRatio = tbPlayer.ShipBattlePropertyComponent:GetProp(PropName.nControlModeSwitchSpeedRatio)
        local nDefaultTime = ProgressBarComponent:GetTime(nProgressBarId)
        local nNewSwitchTime = nDefaultTime * nControlModeSwitchSpeedRatio
        ProgressBarComponent:Start(nProgressBarId, tbData, OnDisplaySuccess, OnDisplayAborted, nNewSwitchTime)
    else
        logerror("BattleLandSystem:OnStartChangeDisplay ProgressBarComponent is nil")
    end
    return true
end

function BattleLandSystem:OnEndChangeDisplay(tbParams)
    if tbParams == nil then
        logerror("BattleLandSystem:OnEndChangeDisplay can't Find delay data :", tbParams.nPlayerServerInstanceId)
        return false
    end

    local nPlayerServerInstanceId = tbParams.nPlayerServerInstanceId
    local tbPlayer = GameObjectSystem:FindByInstanceId(nPlayerServerInstanceId)
    if tbPlayer == nil then
        return false
    end

    local nTargetRegionType = tbParams.nTargetRegionType
    assert(nTargetRegionType ~= nil)
    local nCheckTargetRegionType = self:GetTargetRegionTypeByLocation(tbPlayer)
    if(nCheckTargetRegionType ~= nTargetRegionType) then
        self:OnBreakChangingDisplay(tbParams)
        return false
    end

    local Location = GetCurLocation(self, tbPlayer)
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local bRet, NewLoction = GridTypeManager:GetClosestPositionOfRegionType(Location.X, Location.Y, nTargetRegionType)
    if(not bRet) then
        logerror(string.format("BattleLandSystem OnEndChangeDisplay %d %s %d", tbPlayer.nPlayerId, tbPlayer.szName, nTargetRegionType))
        return false
    end

    log("landsystem change to location : ", tbPlayer.szName, NewLoction.X, NewLoction.Y)
    if(nTargetRegionType == self.TYPE_SHORE) then
        ChangeToHuman(tbPlayer, NewLoction)
    elseif(nTargetRegionType == self.TYPE_PORT) then
        ChangeToShip(tbPlayer, NewLoction)
    else
        error("invalid target region type")
    end

    self:RecordChangeDisplay(tbPlayer)
    return true
end

function BattleLandSystem:OnBreakChangingDisplay(tbParams)
    local nSenderUniqueId = tbParams.nSenderUniqueId
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer == nil then
        return false
    end
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_BreakChangeDisplay)
    return true
end

function BattleLandSystem:RecordChangeDisplay(tbPlayer, bIsOver)
    local nPlayerId = tbPlayer:GetPlayerId()
    if self.tbChanged[nPlayerId] == nil then
        self.tbChanged[nPlayerId] = {nFirstChangeTime = GlobalVariableSystem:GetLocalTime(), nCount = 1}
    else
        self.tbChanged[nPlayerId].nCount = self.tbChanged[nPlayerId].nCount + 1
    end
end

-- function BattleLandSystem:RecordChangeDisplay(tbPlayer, bIsOver)
--     local nPlayerId = tbPlayer:GetPlayerId()
--     local bIsFirst = self.tbChanged[nPlayerId] == nil

--     if not bIsOver then
--         EventManager:OnFireEvent(CommonEventDef.EV_LOG_CHANGE_DISPLAY, tbPlayer, bIsFirst, false)
--         self.tbChanged[nPlayerId] = true
--     elseif bIsFirst then
--         -- 直到游戏结束，没有做过人船切换
--         EventManager:OnFireEvent(CommonEventDef.EV_LOG_CHANGE_DISPLAY, tbPlayer, false, true)
--     end
-- end

-- function BattleLandSystem:Reborn(nVolumeId, nPlayerServerInstanceId)
--     local tbPlayer = GameObjectSystem:FindByInstanceId(nPlayerServerInstanceId)
--     if tbPlayer == nil then
--         return
--     end

--     local tbVolume = BattleVolumeHelper:GetVolume(nVolumeId)
--     if tbVolume == nil then
--         logerror("BattleLandSystem:Reborn can't Find Volume id: ", nVolumeId)
--         return
--     end

--     local bShip = tbPlayer:IsShip()
--     local tbTransforms = bShip and BattleTransformPointHelper:Find(tbVolume.IslandTransformId)
--         or BattleTransformPointHelper:Find(tbVolume.SeaTransformId)

--     if tbTransforms == nil then
--         error("BattleLandSystem:Reborn can't Find transform id: ", tbVolume.IslandTransformId, tbVolume.SeaTransformId)
--         return
--     end
--     if tbTransforms.Type == TransformDef.TransformType.Volume then
--         local nTransformId = RandomArray(tbTransforms.Volume)
--         tbTransforms = BattleTransformPointHelper:Find(nTransformId)
--         if tbTransforms == nil then
--             error("BattleLandSystem:Reborn can't Find transform id: ", nTransformId)
--             return
--         end
--     end

--     local tbPoint = tbTransforms.StartPoint and RandomPoint(tbTransforms.StartPoint, tbTransforms.EndPoint)
--         or RandomArray(tbTransforms.Group)
--     tbPoint.Yaw = GetYaw(tbPlayer:GetLocation(), Vector{X=tbPoint.X, Y=tbPoint.Y, Z=tbPoint.Z})

--     if bShip then
--         ChangeToHuman(tbPlayer, tbPoint)
--     else
--         ChangeToShip(tbPlayer, tbPoint)
--     end
-- end

function BattleLandSystem:GetPlayerChangeDisplayInfo(nPlayerId)
    return self.tbChanged[nPlayerId]
end

return BattleLandSystem()