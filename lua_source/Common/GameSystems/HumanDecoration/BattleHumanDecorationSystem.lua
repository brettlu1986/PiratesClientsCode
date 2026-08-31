-----------------------------------------------------
--File Name    : BattleHumanDecorationSystem.lua
--Author       : WuJizhou
--Create Time  : 2/25/2019, 4:22:27 PM
--Description  : BattleHumanDecorationSystem
-----------------------------------------------------

local PropName        = require("PropName")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local ItemDataTable = require("ItemDataTable")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattlePrepareSystem = dynamic_require("BattlePrepareSystem")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonCommonProtoNames")
local DiamondContainer = require("DiamondContainer")
local PropertyWrapperType = require("PropertyWrapperType")

local BattleHumanDecorationSystem = {}

local DIAMOND_REQUEST_TIME_TOLERANCE = 10.0

BattleHumanDecorationSystem.tbLastDiamondRequestTime = nil
BattleHumanDecorationSystem.tbLastDiamondCache = nil

local function OnPlayerLogin(self, tbPlayer)
    local tbPrepareInfo = BattlePrepareSystem:GetPlayerPrepareInfo(tbPlayer:GetPlayerId())
    if not tbPrepareInfo then
        return
    end
    local tbDecorationIds = tbPrepareInfo.tbHumanDecorationIds
    if not tbDecorationIds then
        return
    end
    for _, nTemplateId in ipairs(tbDecorationIds) do
        local tbTemplate = ItemDataTable:GetTemplate(nTemplateId)
        if tbTemplate then
            tbPlayer.BuffComponentServer:AddBuffById(tbTemplate.nBuffId, 1, tbTemplate.nLevel)
        end
    end
end


function BattleHumanDecorationSystem.ModifyHumanExtraPackageCapacityValue(tbPlayer, nValue)
    local PropertyComponent = tbPlayer.HumanBattlePropertyComponent
    PropertyComponent:PropOverlap(PropertyWrapperType.TYPE_ADD, PropName.nHumanExtraPackageCapacityValue, nValue)
end

function BattleHumanDecorationSystem.ModifyShipExtraPackageCapacityValue(tbPlayer, nValue)
    local PropertyComponent = tbPlayer.ShipBattlePropertyComponent
    PropertyComponent:PropOverlap(PropertyWrapperType.TYPE_ADD, PropName.nShipExtraPackageCapacityValue, nValue)
end

function BattleHumanDecorationSystem.ModifyShipExtraMaterialCapacityRatio(tbPlayer, nValue)
    local PropertyComponent = tbPlayer.ShipBattlePropertyComponent
    PropertyComponent:PropOverlap(PropertyWrapperType.TYPE_ADD, PropName.nShipExtraMaterialCapacityRatio, nValue)
end

function BattleHumanDecorationSystem.ModifyAirDropVisibleOnMap(tbPlayer, bValue)
    local PropertyComponent = tbPlayer.HumanBattlePropertyComponent
    PropertyComponent:PropOverlap(PropertyWrapperType.TYPE_OVERRIDE, PropName.bCanSeeAirDropOnMap, bValue)
end

function BattleHumanDecorationSystem.ModifyDiamondVisibleOnMap(tbPlayer, bValue)
    local PropertyComponent = tbPlayer.HumanBattlePropertyComponent
    PropertyComponent:PropOverlap(PropertyWrapperType.TYPE_OVERRIDE, PropName.bCanSeeDiamondOnMap, bValue)
end

function BattleHumanDecorationSystem.GetShipExtraMaterialCapacityRatio(tbPlayer)
    local PropertyComponent = tbPlayer.ShipBattlePropertyComponent
    return PropertyComponent:GetProp(PropName.nShipExtraMaterialCapacityRatio)
end

function BattleHumanDecorationSystem.GetShipExtraPackageCapacityValue(tbPlayer)
    local PropertyComponent = tbPlayer.ShipBattlePropertyComponent
    return PropertyComponent:GetProp(PropName.nShipExtraPackageCapacityValue)
end

function BattleHumanDecorationSystem.GetHumanExtraPackageCapacityValue(tbPlayer)
    local PropertyComponent = tbPlayer.HumanBattlePropertyComponent
    return PropertyComponent:GetProp(PropName.nHumanExtraPackageCapacityValue)
end

function BattleHumanDecorationSystem.GetAirDropVisibleOnMap(tbPlayer)
    local PropertyComponent = tbPlayer.HumanBattlePropertyComponent
    return PropertyComponent:GetProp(PropName.bCanSeeAirDropOnMap)
end

function BattleHumanDecorationSystem.GetDiamondVisibleOnMap(tbPlayer)
    local PropertyComponent = tbPlayer.HumanBattlePropertyComponent
    return PropertyComponent:GetProp(PropName.bCanSeeDiamondOnMap)
end


function BattleHumanDecorationSystem:Init()
    self.tbLastDiamondRequestTime = {}
    self.tbLastDiamondCache = {}
    if GlobalVariableSystem:IsServerLogic() then
        EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerLogin)
    end
    return true
end

function BattleHumanDecorationSystem:Uninit()
    if GlobalVariableSystem:IsServerLogic() then
        EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerLogin)
    end
    self.tbLastDiamondRequestTime = nil
    self.tbLastDiamondCache = nil
end

-- This function will only be called on server.
function BattleHumanDecorationSystem:HandleNearbyDiamondRequest(tbPlayer, nSenderUniqueId)
    -- logdebug("**[Decoration-Chart]**: Server Handle Nearby Diamond Request: nSenderUniqueId = ", nSenderUniqueId)
    if not tbPlayer then
        error("BattleHumanDecorationSystem:HandleNearbyDiamondRequest, tbPlayer is invalid.")
        return
    end

    local nPlayerId = tbPlayer:GetPlayerId()
    local PropertyComponent = tbPlayer.HumanBattlePropertyComponent
    local nDiamondRefreshInterval = PropertyComponent:GetProp(PropName.nDiamondRefreshTimeOnMap)
    log("BattleHumanDecorationSystem: Player diamond refresh interval, player id, player name:", nDiamondRefreshInterval, nPlayerId, tbPlayer.szName)

    local nLastRequestTime = self.tbLastDiamondRequestTime[nPlayerId]
    local nCurrentTime = GlobalVariableSystem:GetDSTimeSeconds()
    self.tbLastDiamondRequestTime[nPlayerId] = nCurrentTime
    
    if nLastRequestTime then
        if nCurrentTime - nLastRequestTime < nDiamondRefreshInterval - DIAMOND_REQUEST_TIME_TOLERANCE then
            logerror(string.format("BattleHumanDecorationSystem: Player requests nearby diamond info too frequently. Player id: %d, player name: %s, nCurrentTime: %.2f, nLastRequestTime: %.2f, nDiamondRefreshInterval: %.2f, tolerance: %.2f, os.time: %d", nPlayerId, tbPlayer.szName, nCurrentTime, nLastRequestTime, nDiamondRefreshInterval, DIAMOND_REQUEST_TIME_TOLERANCE, os.time()))
            return
        end
    end

    local bFound, nNearByX, nNearByY, nNearByZ = DiamondContainer:FindPlayerNearbyDiamondXYZ(tbPlayer)
    -- logdebug("**[Decoration-Chart]**: Server Find Player Nearby Diamond: bFound, nNearByX, nNearByY, nNearByZ =", bFound, nNearByX, nNearByY, nNearByZ)
    local d2c_NearbyDiamond =
    {
        bFound = bFound,
        nX = nNearByX,
        nY = nNearByY,
        nZ = nNearByZ
    }
    self.tbLastDiamondCache[nPlayerId] = d2c_NearbyDiamond
    NetworkManager:GetRPCNetworkProxy():SendToClient(nSenderUniqueId, Proto.d2c_NearbyDiamond, d2c_NearbyDiamond)
end

-- This function will only be called on server.
function BattleHumanDecorationSystem:SendLastDiamondIfExist(tbPlayer, nSenderUniqueId)
    -- logdebug("**[Decoration-Chart]**: Server send last diamond cache: nSenderUniqueId = ", nSenderUniqueId)
    if not tbPlayer then
        error("BattleHumanDecorationSystem:SendLastDiamondIfExist, tbPlayer is invalid.")
        return
    end

    local nPlayerId = tbPlayer:GetPlayerId()
    local d2c_NearbyDiamond = self.tbLastDiamondCache[nPlayerId]
    if d2c_NearbyDiamond and d2c_NearbyDiamond.bFound then
        -- logdebug("**[Decoration-Chart]**: Server found last diamond cache, send to player: nPlayerId, nSenderUniqueId = ", nPlayerId, nSenderUniqueId)
        NetworkManager:GetRPCNetworkProxy():SendToClient(nSenderUniqueId, Proto.d2c_NearbyDiamond, d2c_NearbyDiamond)
    end
end

return BattleHumanDecorationSystem