-----------------------------------------------------
--File Name    : MiniMapSystem.lua
--Author       : Ran Jie
--Create Time  : 2019-09-02
--Description  : 小地图系统
-----------------------------------------------------
local SelfEventHelper = require("SelfEventHelper")


local MiniMapSystem = {}
local ClientEventDef = require("ClientEventDef")
local ControlModeDef = require("ControlModeDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SaveGameDef = require("SaveGameDef")
local ControlModeSystem = require("ControlModeSystem")
local DelayTimer = require("DelayTimer")
local Timer = require("Timer")
local PropName = require("PropName")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonCommonProtoNames")
local UIMapIni = require("UIMapIni")
local SoundManager = require("SoundManager")
local WorldMapUtil = require("WorldMapUtil")
local SceneDataTable = require("SceneDataTable")
local DungeonDataTable = require("DungeonDataTable")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local UIMapResDataTable = require("UIMapResDataTable")
local GameWorldSystem = require("GameWorldSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local UIManager = require("UIManager")
local UIStateDef = require("UIStateDef")

local GRID_TYPE_SHORE = EPiratesGridRegionType.Shore
local PORT_SHOW_TIME = UIMapIni.tbMMap.nPortMarkShowTime
local PORT_MARK_SOUND_ID = 900040
local WATCH_BATTLE_MAP_MODE = 4

MiniMapSystem.tbMapSymbolVisible = nil
MiniMapSystem.bWaitStage = nil
MiniMapSystem.nLandId = nil
MiniMapSystem.nVehicleId = nil
MiniMapSystem.VehicleLocation = nil
MiniMapSystem.NearbyDiamondLocation = nil
MiniMapSystem.bFoundNearbyDiamond = false
MiniMapSystem.RefreshDiamondTimerHandle = nil

local function OnRefreshNearbyDiamond(self)
    local tbPlayer = GamePlayerSelfHelper:Get()
    if not tbPlayer or tbPlayer:IsDead() then
        return
    end
    -- logdebug("**[Decoration-Chart]**: OnRefreshNearbyDiamond: Send request to server...")
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_RequestNearbyDiamond)
end

local function TryDestroyDiamondRefreshTimer(self)
    if self.RefreshDiamondTimerHandle then
        self.RefreshDiamondTimerHandle:Clear()
        self.RefreshDiamondTimerHandle = nil
    end
end

local function TryCreateDiamondRefreshTimer(self, nTime)
    if (not self.RefreshDiamondTimerHandle and nTime >= 0) then
        -- logdebug("**[Decoration-Chart]**: Start diamond refresh timer: nTime=", nTime)
        self.RefreshDiamondTimerHandle = Timer.NewTimerMethod(self, OnRefreshNearbyDiamond, nTime, true)
    end
end

local function OnEndWaitStageAndStartBattle(self, bWaitStage)
    if bWaitStage then
        -- logdebug("**[Decoration-Chart]**: Still in wait stage, DO NOT start timer: bWaitStage=", bWaitStage)
        return
    end

    local tbPlayer = GamePlayerSelfHelper:Get()
    local PropertyComponent = tbPlayer.HumanBattlePropertyComponent
    local nDiamondRefreshInterval = PropertyComponent:GetProp(PropName.nDiamondRefreshTimeOnMap)
    -- logdebug("**[Decoration-Chart]**: End wait stage and Start Battle, try starting timer: nDiamondRefreshInterval=", nDiamondRefreshInterval)

    TryCreateDiamondRefreshTimer(self, nDiamondRefreshInterval)
end

local function OnRecvWaitStageInfo(self, rWaitStage)
    log("MiniMapSystem:OnRecvWaitStageInfo",rWaitStage.bWaitStage)
    self.bWaitStage = rWaitStage.bWaitStage
    OnEndWaitStageAndStartBattle(self, self.bWaitStage)
end

local function ClearShowPortTimer(self)
    if self.tbShowPortTimer then
        DelayTimer:ClearTimer(self.tbShowPortTimer)
        self.tbShowPortTimer = nil
    end
end 

local function ClearShowPortSound(self)
    if self.PortMarkSound then
        SoundManager:DeleteSound(self.PortMarkSound)
        self.PortMarkSound = nil
    end
end

local function ClearNearbyDiamondCache(self)
    self.bFoundNearbyDiamond = false
    self.NearbyDiamondLocation.X = 0
    self.NearbyDiamondLocation.Y = 0
    self.NearbyDiamondLocation.Z = 0
end

local function OnLeaveDungeon(self)
    self:SaveLandId(0)
    ClearShowPortTimer(self)
    ClearShowPortSound(self)
    WorldMapUtil.nCurrentSliderValue = 0
    self.bWaitStage = nil
    self.nVehicleId = nil
    self.VehicleLocation = nil

    TryDestroyDiamondRefreshTimer(self)
    ClearNearbyDiamondCache(self)
end

function MiniMapSystem:Init()
    self.tbMapSymbolVisible = {}
    self.nVehicleId = nil
    self.VehicleLocation = {X = 0, Y = 0}

    self.NearbyDiamondLocation = Vector()
    self.RefreshDiamondTimerHandle = nil

    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_WAIT_STAGE_STATE_CHANGED, self, OnRecvWaitStageInfo)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE, self, OnLeaveDungeon)
    --EventHelper:RegisterEvent(CommonEventDef.EV_ON_VEHICLE_STATE_CHANGE, self, OnVehicleStateChange)
    --EventHelper:RegisterEvent(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE, self, OnControlModeActive)
    return true
end

function MiniMapSystem:Uninit()
    self.EventHelper:UnregisterAll()

    TryDestroyDiamondRefreshTimer(self)
    ClearNearbyDiamondCache(self)

    ClearShowPortTimer(self)
    ClearShowPortSound(self)
end

function MiniMapSystem:SetMapSymbolVisible(nCategory, bVisible)
    log("MiniMapSystem:SetMapSymbolVisible,nCategory, bVisible=",nCategory, bVisible)
    if nCategory then
        self.tbMapSymbolVisible[nCategory] = bVisible
        self.EventHelper:FireEvent(ClientEventDef.EV_MAP_SYMBOL_VISIBLE_CHANGED, nCategory, bVisible)
    end
end

function MiniMapSystem:GetMapSymbolVisible(nCategory)
    return self.tbMapSymbolVisible[nCategory]
end

function MiniMapSystem:IsFFAWaitStage()
    return self.bWaitStage
end

function MiniMapSystem:SaveLandId(nInLandId)
    local nLandId = 0
    if nInLandId then
        nLandId = nInLandId
    else
        if ControlModeSystem:GetCurrentModeType() == ControlModeDef.HUMAN then
            local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
            local pSelfLocation = GamePlayerSelfHelper:Get():GetLocation()
            nLandId = GridTypeManager:GetLandID(pSelfLocation.X, pSelfLocation.Y)
            if nLandId == 0 then
                local bResult, pClosestLocation = GridTypeManager:GetClosestPositionOfRegionType(pSelfLocation.X, pSelfLocation.Y, GRID_TYPE_SHORE)
                if bResult and pClosestLocation then
                    nLandId = GridTypeManager:GetLandID(pClosestLocation.X, pClosestLocation.Y)
                else
                    logerror("MiniMapSystem:SaveLandId failed, self location=", pSelfLocation.X, pSelfLocation.Y)
                end
            end
        end
    end
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    pSaveGameMgr:AddIntData(SaveGameDef.UI_MAP_LAND_ID, nLandId)
    pSaveGameMgr:Save()
end

function MiniMapSystem:GetLandId()
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    return pSaveGameMgr:GetIntDataWithDefault(SaveGameDef.UI_MAP_LAND_ID, 0)
end

function MiniMapSystem:SetLastVehicleId(nVehicleId)
    self.nVehicleId = nVehicleId
end

function MiniMapSystem:GetLastVehicleId()
    return self.nVehicleId
end

function MiniMapSystem:SetLastVehicleLocation(nX, nY)
    if not self.VehicleLocation then
        self.VehicleLocation = {}
    end
    self.VehicleLocation.X = nX
    self.VehicleLocation.Y = nY
end

function MiniMapSystem:GetLastVehicleLocation()
    return self.VehicleLocation
end

function MiniMapSystem:GetNearbyDiamondLocation()
    return self.NearbyDiamondLocation
end

function MiniMapSystem:IsFoundNearbyDiamond()
    return self.bFoundNearbyDiamond
end

function MiniMapSystem:ShowPort(nInShowTime)
    ClearShowPortTimer(self)
    ClearShowPortSound(self)
    local nShowTime = nInShowTime
    if not nShowTime then
        nShowTime = PORT_SHOW_TIME
    end
    self.tbShowPortTimer = DelayTimer:DelayRun(function()
        self.tbShowPortTimer = nil
        ClearShowPortSound(self)
        self.EventHelper:FireEvent(ClientEventDef.EV_SHOW_HUMAN_SHIP_PORT, false)
    end, nShowTime)
    self.PortMarkSound = SoundManager:PlaySoundEffect(PORT_MARK_SOUND_ID, false)
    self.EventHelper:FireEvent(ClientEventDef.EV_SHOW_HUMAN_SHIP_PORT, true)
end

function MiniMapSystem:IsShowPort()
    return self.tbShowPortTimer
end

function MiniMapSystem:GetMapMode()
    local ActiveUIState = UIManager:GetActiveState()
    if ActiveUIState.szName == UIStateDef.StateName.UI_WATCH_BATTLE_STATE or ActiveUIState.szName == UIStateDef.StateName.UI_BOT_WATCH_STATE then
        return WATCH_BATTLE_MAP_MODE
    end
    local tbMapResData = self:GetMapResData()
    return tbMapResData.nMode
end

function MiniMapSystem:GetMapResData()
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    local tbSceneOrDungeonTemplate = nil
    local nSceneId = nil
    if(bIsInDungeon) then
        nSceneId = BattleGameModeSystem.nDungeonId
        tbSceneOrDungeonTemplate = DungeonDataTable:GetTemplate(nSceneId)
    else
        nSceneId = GameWorldSystem:GetWorld().nSceneId
        tbSceneOrDungeonTemplate = SceneDataTable:GetTemplate(nSceneId)
    end
    if(tbSceneOrDungeonTemplate == nil)then
        logerror("[MiniMapSystem] GetMapResData:tbSceneOrDungeonTemplate is nil")
        return
    end
    local tbMapResData = UIMapResDataTable:GetTemplate(tbSceneOrDungeonTemplate.nUIRadarMapId)
    return tbMapResData
end

function MiniMapSystem:HandleServerNearbyDiamondInfo(tbPlayer, bFound, nNearByX, nNearByY, nNearByZ)
    self.bFoundNearbyDiamond = bFound
    self.NearbyDiamondLocation.X = nNearByX
    self.NearbyDiamondLocation.Y = nNearByY
    self.NearbyDiamondLocation.Z = nNearByZ
    -- logdebug("**[Decoration-Chart]**: HandleServerNearbyDiamondInfo: bFound, nNearByX, nNearByY, nNearByZ =", bFound, nNearByX, nNearByY, nNearByZ)
    self.EventHelper:FireEvent(ClientEventDef.EV_NEARBY_DIAMOND_REFRESHED)
end

return MiniMapSystem