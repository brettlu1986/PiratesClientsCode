local luaclass = require("luaclass")
local BattleTemplateActorSystem = luaclass("BattleTemplateActorSystem")

local ResourceManager = require("ResourceManager")
local GameObjectSystem = nil    -- 延迟require，防止递归
local GameObjectTypeDef = require("GameObjectTypeDef")
local SelfEventHelper = require("SelfEventHelper")
local CommonEventDef = require("CommonEventDef")

local HUMAN_CELL_SIZE = 5000
local SHIP_CELL_SIZE = 30000
local MANAGER_CLASS = '/Script/Common.TemplateActorDataManager'
MANAGER_CLASS = MANAGER_CLASS:load()

local DEFAULT_REGION_INDEX = 1

BattleTemplateActorSystem.tbRegionInfos = nil
BattleTemplateActorSystem.nCurrentRegion = nil
BattleTemplateActorSystem.bInitRegion = false

local function CreateManager()
    local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
    local pManager = ExtendBlueprintFunctions.CreateObject(MANAGER_CLASS, pGameInstance)
    ResourceManager:Hold(pManager)
    return pManager
end

local function DestoryManager(pManager)
    if(isvalidhandle(pManager)) then
        pManager:Clear()
        ResourceManager:Unhold(pManager)
    end
end

function BattleTemplateActorSystem:GetCurrentManager()
    local tbMapInfo = self.tbRegionInfos[self.nCurrentRegion]
    return tbMapInfo.pManager
end

local function OnPlayerPostLogin(self, tbGamePlayer)
    local pUEController = tbGamePlayer.pUEController
    if(pUEController == nil or not self.bInitRegion) then
        return
    end

    local pTemplateActorDataComponent = pUEController.TemplateActorData
    if(pTemplateActorDataComponent) then
        local pManager = self:GetCurrentManager()
        assert(pManager)
        pTemplateActorDataComponent:RegisterToManager(pManager)
        -- PostLogin之后发rpc客户端才能收得到，所以这里掉这个
        pTemplateActorDataComponent:InitClientMapInfo()
    end
end

function BattleTemplateActorSystem:Init()
    GameObjectSystem = dynamic_require("GameObjectSystem")
    local tbRegionInfos = {}
    self.tbRegionInfos = tbRegionInfos

    local tbDefaultRegionInfo = {}
    tbRegionInfos[DEFAULT_REGION_INDEX] = tbDefaultRegionInfo
    self.nCurrentRegion = DEFAULT_REGION_INDEX

    local pManager = CreateManager()
    tbDefaultRegionInfo.pManager = pManager
    CommonShell.Get(GWorld):SetTemplateActorDataManager(pManager)

    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerPostLogin)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_RELOGIN, self, OnPlayerPostLogin)
    return true
end

function BattleTemplateActorSystem:Uninit()
    -- 打下统计数据
    -- local pCurrerntManager = self:GetCurrentManager()
    -- if(isvalidhandle(pCurrerntManager)) then
    --     log("BattleTemplateActorSystem:Uninit")
    --     pCurrerntManager:PrintDebugInfo()
    -- end

    self.EventHelper:UnregisterAll()

    for k, tbRegionInfo in ipairs(self.tbRegionInfos) do
        DestoryManager(tbRegionInfo.pManager)
    end
    CommonShell.Get(GWorld):SetTemplateActorDataManager(nil)

    self.tbRegionInfos = nil
    self.nCurrentRegion = nil
end

function BattleTemplateActorSystem:GetDefaultRegionInfo()
    return self.tbRegionInfos[DEFAULT_REGION_INDEX]
end

local function InitMap(tbRegionInfo, nWidth, nHeight, nCenterX, nCenterY)
    local pManager = tbRegionInfo.pManager
    if(pManager == nil) then
        pManager = CreateManager()
        tbRegionInfo.pManager = pManager
    end

    local nHalfWidth = nWidth/2
    local nHalfHeight = nHeight/2
    tbRegionInfo.nMinX = nCenterX - nHalfWidth
    tbRegionInfo.nMaxX = nCenterX + nHalfWidth
    tbRegionInfo.nMinY = nCenterY - nHalfHeight
    tbRegionInfo.nMaxY = nCenterY + nHalfHeight
    pManager:Init(nWidth, nHeight, nCenterX, nCenterY, HUMAN_CELL_SIZE, SHIP_CELL_SIZE)
end

function BattleTemplateActorSystem:InitDefaultRegion(nWidth, nHeight, nCenterX, nCenterY)
    self.bInitRegion = true
    InitMap(self.tbRegionInfos[DEFAULT_REGION_INDEX], nWidth, nHeight, nCenterX, nCenterY)
end

function BattleTemplateActorSystem:CreateOtherRegion(nWidth, nHeight, nCenterX, nCenterY)
    local tbRegionInfo = {}
    InitMap(tbRegionInfo, nWidth, nHeight, nCenterX, nCenterY)
    table.insert(self.tbRegionInfos, tbRegionInfo)
    return #self.tbRegionInfos
end

function BattleTemplateActorSystem:SwitchToDefaultRegion(bDestoryOld)
    self:SwitchRegion(DEFAULT_REGION_INDEX, bDestoryOld)
end

function BattleTemplateActorSystem:SwitchRegion(nNewRegionIndex, bDestoryOld)
    local nCurrentRegion = self.nCurrentRegion
    if(nCurrentRegion == nNewRegionIndex) then
        return
    end

    log("BattleTemplateActorSystem:SwitchRegion", nNewRegionIndex, bDestoryOld)

    self.nCurrentRegion = nNewRegionIndex
    local tbNewRegionInfo = self.tbRegionInfos[nNewRegionIndex]
    assert(tbNewRegionInfo)

    local pManager = tbNewRegionInfo.pManager
    assert(pManager)
    CommonShell.Get(GWorld):SetTemplateActorDataManager(pManager)

    local pComponent, bRegister
    local tbAllObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for tbObject, _ in pairs(tbAllObjects) do
        if(tbObject.pUEController ~= nil) then
            pComponent = tbObject.pUEController.TemplateActorData
            if(pComponent) then
                bRegister = pComponent:RegisterToManager(pManager)
                if(pComponent:IsUpdateEnabled() and bRegister) then
                    -- 之前已经开始update了，换了manager需要重新让客户端初始化一次
                    pComponent:InitClientMapInfo()
                end
            end
        end
    end

    local tbOldRegionInfo = self.tbRegionInfos[nCurrentRegion]
    if(bDestoryOld and tbOldRegionInfo) then
        DestoryManager(tbOldRegionInfo.pManager)
        tbOldRegionInfo.pManager = nil
    end
end

function BattleTemplateActorSystem:FinishInit()
    for _, tbMapInfo in ipairs(self.tbRegionInfos) do
        if(tbMapInfo.pManager) then
            tbMapInfo.pManager:FinishInit()
        end
    end
    log("BattleTemplateActorSystem:FinishInit")
end

function BattleTemplateActorSystem:ZipYaw(nYaw)
    if(nYaw == nil) then
        return 0
    end

    while(nYaw > 360) do
        nYaw = nYaw - 360
    end
    while(nYaw < 0) do
        nYaw = nYaw + 360
    end
    return math.floor(nYaw / 360 * 65535)
end

function BattleTemplateActorSystem:UnzipYaw(nYaw)
    return nYaw / 65535.0 * 360
end

function BattleTemplateActorSystem:Add(nInstanceId, nTemplateId, X, Y, Z, Yaw, CustomType)
    local bRet = false
    for _, tbMapInfo in ipairs(self.tbRegionInfos) do
        if(tbMapInfo.pManager and
            X >= tbMapInfo.nMinX and X <= tbMapInfo.nMaxX and
            Y >= tbMapInfo.nMinY and Y <= tbMapInfo.nMaxY) then
            tbMapInfo.pManager:AddData(nInstanceId, nTemplateId, X, Y, Z, self:ZipYaw(Yaw), CustomType)
            bRet = true
        end
    end

    return bRet
end

function BattleTemplateActorSystem:AddGlobal(nInstanceId, nTemplateId, X, Y, Z, Yaw, CustomType)
    local bRet = false
    for _, tbMapInfo in ipairs(self.tbRegionInfos) do
        if(tbMapInfo.pManager and
            X >= tbMapInfo.nMinX and X <= tbMapInfo.nMaxX and
            Y >= tbMapInfo.nMinY and Y <= tbMapInfo.nMaxY) then
            tbMapInfo.pManager:AddGlobalData(nInstanceId, nTemplateId, X, Y, Z, self:ZipYaw(Yaw), CustomType)
            bRet = true
        end
    end

    return bRet
end

function BattleTemplateActorSystem:Remove(nInstanceId)
    if(self.tbRegionInfos == nil) then
        return
    end

    local tbMapInfo = self.tbRegionInfos[self.nCurrentRegion]
    assert(tbMapInfo and tbMapInfo.pManager)
    tbMapInfo.pManager:RemoveData(nInstanceId)
end

function BattleTemplateActorSystem:SetPickuped(nInstanceId)
    local tbMapInfo = self.tbRegionInfos[self.nCurrentRegion]
    assert(tbMapInfo and tbMapInfo.pManager)
    tbMapInfo.pManager:SetPickuped(nInstanceId)
end

function BattleTemplateActorSystem:SetWatchedTarget(tbObject, tbWatchedTarget)
    if(tbObject == nil) then
        return
    end

    local pUEController = tbObject.pUEController
    local pUETarget = tbWatchedTarget and tbWatchedTarget.pUEActor or nil
    if(pUEController == nil) then
        return
    end

    local pComponent = pUEController.TemplateActorData
    if(pComponent == nil) then
        return
    end

    pComponent:SetWatchedTarget(pUETarget)
end

return BattleTemplateActorSystem()
