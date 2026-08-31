local luaclass = require("luaclass")
local BattleGameModeBaseClass = dynamic_require("BattleCommonGameMode")
local FFAGameMode = luaclass("FFAGameMode", BattleGameModeBaseClass)
local DungeonQuitDialogType = require("DungeonQuitDialogType")
local BotAISystem = dynamic_require("BotAISystem")

local FFAGameModeStepClass = require("FFAGameModeStep")
local CampDef = require("CampDefine")

FFAGameMode.tbPlayerStarts = nil
FFAGameMode.nPlayerStartIndex = 0

FFAGameMode.tbBotStarts = nil
FFAGameMode.nBotStartIndex = 0

local nShipMaxRadius = 5000
local nSearchRadius = 1

function FFAGameMode:Init(nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    FFAGameMode.super.Init(self, nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)

    self.tbPlayerStarts = pGameMode:GetAllPlayerStart()
    self.nPlayerStartIndex = 0

    local tbStep = self:CreateStep(FFAGameModeStepClass, tbGameState.nStepId)
    tbStep:SetParams(tbGameState)

    return true
end

local function AddValidBotLocation(nX, nY, tbBotLocations)
    local pOceanNavGridManager = CommonShell.GetCommon(GWorld):GetOceanNavGridManager()
    local Location = Vector()
    Location.X = nX
    Location.Y = nY
    Location.Z = 0
    local bSuccess = false
    bSuccess, Location = pOceanNavGridManager:GetNearestSafeLocation(nShipMaxRadius, nSearchRadius, Location)
    if bSuccess then
        local tbLocation = {}
        tbLocation.X = Location.X
        tbLocation.Y = Location.Y
        tbLocation.Z = 100
        table.insert(tbBotLocations, tbLocation)
        return true
    end
    log("FFA found bad bot location. X =", nX, ", Y =", nY)
    return false
end

function FFAGameMode:InitBotStarts(nRequestCount)
    local nRealCount = 0
    self.nBotStartIndex = 0
    self.tbBotStarts = {}

    local tbBotStarts = self.tbBotStarts

    local tbMapSize = self.tbJsonTableFile.tbContainer.MapSize[1]
    local nHeight = tbMapSize.Height
    local nWidth = tbMapSize.Width
    assert(nHeight > 0)
    assert(nWidth > 0)
    local nWCount = math.sqrt(nRequestCount * nWidth / nHeight)
    local nHCount = nWCount * nHeight / nWidth
    nWCount = math.ceil(nWCount)
    nHCount = math.ceil(nHCount)
    local nCeilWidth = nWidth / nWCount
    local nCeilHeight = nHeight / nHCount
    local nStartX = nCeilWidth / 2 - nWidth / 2
    local nStartY = nHeight / 2 - nCeilHeight / 2

    log("FFA -------------- nHeight, nWidth:", nHeight, nWidth)
    log("FFA -------------- nWCount, nHCount:", nWCount, nHCount)
    log("FFA -------------- nCeilWidth, nCeilHeight:", nCeilWidth, nCeilHeight)
    log("FFA -------------- nStartX, nStartY:", nStartX, nStartY)

    for i=1,nHCount do
        if nRealCount >= nRequestCount then
            break
        end
        local nY = nStartY - (i - 1) * nCeilHeight
        for j=1,nWCount do
            if nRealCount >= nRequestCount then
                break
            end
            local nX = nStartX + (j - 1) * nCeilWidth
            if AddValidBotLocation(nX, nY, tbBotStarts) then
                nRealCount = nRealCount + 1
            end
        end
    end
    return nRealCount
end

function FFAGameMode:FindPlayerStartJsonData(tbGamePlayer)
    local tbPlayerStarts = self.tbPlayerStarts
    if(tbPlayerStarts == nil or #tbPlayerStarts == 0) then
        logerror("FFAGameMode:FindPlayerStartJsonData failed, Can not find player start")
        return
    end

    local tbJsonData = {}
    tbJsonData.Transform = {}
    local tbTransform = tbJsonData.Transform

    if BotAISystem:IsBot(tbGamePlayer) then
        self.nBotStartIndex = self.nBotStartIndex + 1
        local tbBotStarts = self.tbBotStarts
        if tbBotStarts == nil then
            logerror("FFA error. tbBotStarts nil. Please calling InitBotStarts first. ")
            return
        end
        if self.nBotStartIndex > #tbBotStarts then
            logerror("FFA error. No more bot starts found. Max count: ", #tbBotStarts)
            return
        end
        local tbBotStart = tbBotStarts[self.nBotStartIndex]
        tbTransform.X = tbBotStart.X
        tbTransform.Y = tbBotStart.Y
        tbTransform.Z = tbBotStart.Z
        tbTransform.Yaw = 0

        log("FFA bot location: X =", tbBotStart.X, ", Y =", tbBotStart.Y)
    else
        local pOceanNavGridManager = CommonShell.GetCommon(GWorld):GetOceanNavGridManager()
        local tbMapSize = self.tbJsonTableFile.tbContainer.MapSize[1]
        local nHeight = tbMapSize.Height // 2
        local nWidth = tbMapSize.Width // 2
        assert(nHeight > 0)
        assert(nWidth > 0)

        local bSuccess = false
        local pLocation = Vector()
        local nRetryTimes = 0
        while true do
            nRetryTimes = nRetryTimes + 1
            pLocation.X = math.random(-nWidth, nWidth)
            pLocation.Y = math.random(-nHeight, nHeight)
            pLocation.Z = 100
            bSuccess, pLocation = pOceanNavGridManager:GetNearestSafeLocation(nShipMaxRadius, nSearchRadius, pLocation)
            if bSuccess then
                break
            end
        end

        tbTransform.X = pLocation.X
        tbTransform.Y = pLocation.Y
        tbTransform.Z = pLocation.Z
        tbTransform.Yaw = 0
        log("FFA player location: X =", pLocation.X, ", Y =", pLocation.Y, ", Retry times:", nRetryTimes)
    end

    tbJsonData.CampType = CampDef.Type.CAMP_ALLHOSTILE
    return tbJsonData
end

function FFAGameMode:GetQuitDungeonDialogType()
    log("FFAGameMode:GetQuitDungeonDialogType")
    return DungeonQuitDialogType.FFA
end

return FFAGameMode
