local ParachutingNewIni = require("ParachutingNewIni")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
-- local GameTriggerType = require("GameTriggerType")
-- local BotAISystem = dynamic_require("BotAISystem")
local BattleTransporterHelper = require("BattleTransporterHelper")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BitHelper = require("BitHelper")
local BattleTransformPointHelper = require("BattleTransformPointHelper")
local TransformDef = require("BattleTransformDef")
-- local D2CHelper = require("D2CHelper")
local DungeonIni = require("DungeonIni")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local SpawnerDef = require("SpawnerDef")
local BattleTeamSystem = require("BattleTeamSystem")
local ProtoDR = require("DungeonRepProtoNames")
local AIHelper = require("AIHelper")
local Timer = require("Timer")

local SelectionPointHelper = {}
local COORDINATE_PROPORTION = 100
local LANDCELLSIZE = 2
local LAND_TYPE = EPiratesGridRegionType.Land
local MAX_PLAYER_COUNT = 100
-- vbp: virtual_bot_point
local VBP_LINE_SHIP_VALUE = {
    MIN = -3,
    MAX = 3
}

-- bot虚拟选点
local VBP_RATIO_INTERVAL = 30 -- 选点时长
local VBP_RATIO_TIMER = 1   -- 每隔x秒nBotPlayerBaseRatio增加1，最大为16
local VBP_BOT_PLAYER_BASE_MAX_COUNT = 16

local SELECTION_TYPE = {
    MANUAL  = 0,
    AUTO    = 1,
    FOLLOW  = 2
}

SelectionPointHelper.bNoobDungeon = nil
SelectionPointHelper.tbMapCells = nil
SelectionPointHelper.tbNoobPoints = nil
SelectionPointHelper.tbLandMapPos = nil
SelectionPointHelper.tbSelectedPlayer = nil
SelectionPointHelper.tbSelectedTeam = nil
SelectionPointHelper.tbAutoPointInfos = nil
SelectionPointHelper.bHasResource = nil

SelectionPointHelper.nStartMoveTime = nil
SelectionPointHelper.nTriggerMoveVelocity = nil
SelectionPointHelper.nTriggerMoveDistance = nil

SelectionPointHelper.tbResourceTransforms = nil
SelectionPointHelper.tbLandTransforms = nil
SelectionPointHelper.tbOceanTransforms = nil
SelectionPointHelper.bHideOtherSelectionPoint = nil

SelectionPointHelper.tbSelectedTransporterPlayer = nil

SelectionPointHelper.tbBotPlayerRatioData = nil
SelectionPointHelper.tbVBPAutoSendTimer = nil

SelectionPointHelper.TYPE_ROCK = EPiratesGridRegionType.Rock
SelectionPointHelper.TYPE_OCEAN = EPiratesGridRegionType.Ocean

-- SelectionPointHelper.tbPosList = nil
local function GetNoobArea(self)
    local bNoob = BattleGameModeSystem:GetGameInitData().bNoob
    self.bNoobDungeon = bNoob
    if not bNoob then
        log("not noob dungeon")
        return
    end
    local tbFFANoob = DungeonIni.tbFFANoob
    local nAreadId = 0
    for i = 1, #tbFFANoob.tbDungeonId do
        if tbFFANoob.tbDungeonId[i] == BattleGameModeSystem.nDungeonId then
            nAreadId = tbFFANoob.nAreaId
            break
        end
    end
    if nAreadId <= 0 then
        self.bNoobDungeon = false
        log("noob dungeon but no noob area")
        return
    end

    log("get noob area start:")
    local tbNoobPoints = {}
    local TransformType = TransformDef.TransformType
    local fnParseGroup = function(tbPoints)
        if tbPoints.StartPoint and tbPoints.EndPoint then
            table.insert(tbNoobPoints, tbPoints)
        end
    end

    local tbPoint = BattleTransformPointHelper:Find(nAreadId)
    if tbPoint then
        if (tbPoint.Type == TransformType.Transform) then
            fnParseGroup(tbPoint)
        elseif (tbPoint.Type == TransformType.Volume) then
            local tbVolume = tbPoint.Volume
            for key, value in ipairs(tbVolume) do
                local tbVolumePoint = BattleTransformPointHelper:Find(value)
                fnParseGroup(tbVolumePoint)
            end
        end
    end
    self.tbNoobPoints = tbNoobPoints
    log("get noob area end:", #self.tbNoobPoints)
end

local function IsInNoobArea(self, nMinX, nMinY, nMaxX, nMaxY)
    if not self.bNoobDungeon then
        return false
    end

    for i, v in ipairs(self.tbNoobPoints) do
        if nMinX >= v.StartPoint.X and nMaxX <= v.EndPoint.X and
            nMinY >= v.StartPoint.Y and nMinY <= v.EndPoint.Y then
            return true
        end
    end
    return false
end

local function IsInRange(nAutoSelectionMaxRadius, nAutoSelectionMinRadius, nMinX, nMaxX, nMinY, nMaxY)
    local nDistance1 = math.sqrt((nMinX)^2 + (nMinY)^2)
    local nDistance2 = math.sqrt((nMaxX)^2 + (nMaxY)^2)

    -- 范围：
    local bInArea = (nDistance1 >= nAutoSelectionMinRadius) and (nDistance2 >= nAutoSelectionMinRadius)
        and (math.max(math.abs(nMinX), math.abs(nMaxX)) <= nAutoSelectionMaxRadius)
        and (math.max(math.abs(nMinY), math.abs(nMaxY)) <= nAutoSelectionMaxRadius)

    return bInArea
end

local function DividingMapCell(self)
    local tbReadyArea = ParachutingNewIni.tbReadyArea
    local nMapCellWidth   = tbReadyArea.nMapCellWidth
    local nMapCellHeight  = tbReadyArea.nMapCellHeight
    local nAutoSelectionMaxRadius = tbReadyArea.nAutoSelectionMaxRadius
    local nAutoSelectionMinRadius = tbReadyArea.nAutoSelectionMinRadius

    local tbGameMode = BattleGameModeSystem:GetGameMode()
    if tbGameMode.tbJsonTableFile.tbContainer.MapSize == nil then
        logerror("DividingMapCell no mapsize")
        return
    end
    local tbMapSize = tbGameMode.tbJsonTableFile.tbContainer.MapSize[1]
    local nX = math.ceil(tbMapSize.GamePlayWidth / 2)
    local nY = math.ceil(tbMapSize.GamePlayHeight / 2)
    local nCol = math.ceil(tbMapSize.GamePlayWidth / nMapCellWidth)
    local nRow = math.ceil(tbMapSize.GamePlayWidth / nMapCellHeight)
    local nIndex = 1

    self.nTriggerMoveDistance = math.min(nX, nY)
    self.nTriggerMoveVelocity = self.nTriggerMoveDistance / ParachutingNewIni.tbTransport.nTriggerTime

    local nCount = 0
    local tbMapCells = {}
    local nNoobCount = 0
    for i  = 1, nRow do
        local tbMapRow = {}
        local nMinY = -nY + (i - 1) * nMapCellHeight
        local nMaxY = nMinY + nMapCellHeight
        for j = 1, nCol do
            local nMinX = -nX + (j - 1) * nMapCellWidth
            local nMaxX = nMinX + nMapCellWidth
            local bInArea = IsInRange(nAutoSelectionMaxRadius, nAutoSelectionMinRadius, nMinX, nMaxX, nMinY, nMaxY)
            local bInNoobArea = IsInNoobArea(self, nMinX, nMinY, nMaxX, nMaxY)
            if bInNoobArea then
                nNoobCount = nNoobCount + 1
            end
            local tbMapCell = {bHasResource = false, bInNoobArea = bInNoobArea,
                nPlayerCount = 0, bPlayerBornArea = bInArea,
                nMinX = nMinX, nMaxX = nMaxX, nMinY = nMinY, nMaxY = nMaxY,
                nRow = i, nCol = j, nId = nIndex}
            if bInArea then
                nCount = nCount + 1
            end
            table.insert(tbMapRow, tbMapCell)
            nIndex = nIndex + 1
        end
        table.insert(tbMapCells, tbMapRow)
    end
    if nNoobCount == 0 and self.bNoobDungeon then
        error("dividing map cell failed: no noob area")
    end
    log("DividingMapCell valid cell ", nCount)
    self.tbMapCells = tbMapCells
end

local function DividingLandMapCell(self)
    log("DividingLandMapCell")
    local tbReadyArea = ParachutingNewIni.tbReadyArea
    local nMapCellWidth   = tbReadyArea.nMapCellWidth
    local nMapCellHeight  = tbReadyArea.nMapCellHeight
    local nAutoSelectionMaxRadius = tbReadyArea.nAutoSelectionMaxRadius
    local nAutoSelectionMinRadius = tbReadyArea.nAutoSelectionMinRadius

    local tbGameMode = BattleGameModeSystem:GetGameMode()
    if tbGameMode.tbJsonTableFile.tbContainer.MapSize == nil then
        return
    end
    local tbMapSize = tbGameMode.tbJsonTableFile.tbContainer.MapSize[1]
    local nX = math.ceil(tbMapSize.GamePlayWidth / 2)
    local nY = math.ceil(tbMapSize.GamePlayHeight / 2)
    local nCol = math.ceil(tbMapSize.GamePlayWidth / nMapCellWidth)
    local nRow = math.ceil(tbMapSize.GamePlayWidth / nMapCellHeight)

    local nLandCellWidth = nMapCellWidth / LANDCELLSIZE
    local nLandCellHeight = nMapCellHeight / LANDCELLSIZE
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local tbLandMapPos = {}
    for i = 1, nRow * LANDCELLSIZE do
        local nMinY = -nY + (i - 1) * nLandCellHeight
        local nMaxY = nMinY + nLandCellHeight
        for j = 1, nCol * LANDCELLSIZE do
            local nMinX = -nX + (j - 1) * nLandCellWidth
            local nMaxX = nMinX + nLandCellWidth
            local bInArea = IsInRange(nAutoSelectionMaxRadius, nAutoSelectionMinRadius, nMinX, nMaxX, nMinY, nMaxY)
            if bInArea then
                local nRegionType = GridTypeManager:GetRegionType(nMinX, nMinY)
                if nRegionType == LAND_TYPE then
                    table.insert(tbLandMapPos, {nX = nMinX, nY = nMinY})
                end
            end
        end
    end
    log("DividingLandMapCell End", #tbLandMapPos)
    self.tbLandMapPos = tbLandMapPos
end

local function GetMapCell(self, nX, nY)
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbMapSize = tbGameMode.tbJsonTableFile.tbContainer.MapSize[1]
    local nMapCellWidth = ParachutingNewIni.tbReadyArea.nMapCellWidth
    local nMapCellHeight= ParachutingNewIni.tbReadyArea.nMapCellHeight
    local nHalfW = math.ceil(tbMapSize.GamePlayWidth / 2)
    local nHalfH = math.ceil(tbMapSize.GamePlayHeight / 2)

    local nCurCol = math.ceil((nX + nHalfW) / nMapCellWidth)
    local nCurRow = math.ceil((nY + nHalfH) / nMapCellHeight)
    return self.tbMapCells[nCurRow] and self.tbMapCells[nCurRow][nCurCol]
end

local function FillMapCell(self)
    -- 机器人跳伞出生点不采用偏移后的资源点，直接采用策划种的点
    local tbMapCell
    self.bHasResource = false
    for i, v in ipairs(self.tbResourceTransforms) do
        tbMapCell = GetMapCell(self, v.tbTransform.X, v.tbTransform.Y)
        if tbMapCell and tbMapCell.bPlayerBornArea then
            tbMapCell.bHasResource = true
            if tbMapCell.tbResourcePos == nil then
                tbMapCell.tbResourcePos = {}
            end
            -- log("[selectpoint] resource pos: ", #tbMapCell.tbResourcePos, v.tbTransform.X, v.tbTransform.Y, v.tbTransform.Z)
            table.insert(tbMapCell.tbResourcePos, {nX = v.tbTransform.X, nY = v.tbTransform.Y, nZ = v.tbTransform.Z})
            tbMapCell.bIsOcean = tbMapCell.bIsOcean or v.bIsOcean
            self.bHasResource = true
        end
    end
end
-------------------------------------------------------------
-- 获取所有的player 或者 bot
-- local nPlayerCount = 1
local function GetAllObject(self, bIsBot)
    local tbObjs = {}
    local tbAllObjs = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for v, _ in pairs(tbAllObjs) do
        local nInstanceId = v:GetServerInstanceId()
        if self.tbSelectedPlayer[nInstanceId] == nil
            and ((bIsBot and AIHelper:ShouldSkipParachute(v)) --是机器人并且跳过跳伞阶段
            -- 不是机器人 或者 是机器人但是不跳过跳伞阶段
            or (not bIsBot and not AIHelper:ShouldSkipParachute(v) )) then
            table.insert(tbObjs, nInstanceId)
        end
    end
    return tbObjs
    -- local tbObjs = {}
    -- if bIsBot then
    --     for i = 1, 100 - nPlayerCount do
    --         table.insert(tbObjs, i + nPlayerCount)
    --     end
    -- else
    --     for i = 1, nPlayerCount do
    --         table.insert(tbObjs, i)
    --     end
    -- end
    -- return tbObjs
end

local function RandomInCell(self, tbMapCell, nInstanceId, nSelectionType)
    -- 随机地图格子中的x,y
    local nX = math.random(tbMapCell.nMinX, tbMapCell.nMaxX)
    local nY = math.random(tbMapCell.nMinY, tbMapCell.nMaxY)

    local tbData = {}
    tbData.nInstanceId = nInstanceId
    local nPosX = math.floor(nX / COORDINATE_PROPORTION)
    local nPosY = math.floor(nY / COORDINATE_PROPORTION)
    tbData.nPos = BitHelper:XYToPos(nPosX, nPosY)

    self:SetSelectionPoint(tbData.nInstanceId, tbData.nPos, nPosX * COORDINATE_PROPORTION, nPosY * COORDINATE_PROPORTION, 0, nSelectionType)

    return tbData, nPosX, nPosY
end

local function ResourceCell(self, tbMapCell, nInstanceId, nIndex)
    if nIndex == nil then
        nIndex = 1
    end
    local nX = tbMapCell.tbResourcePos[nIndex].nX
    local nY = tbMapCell.tbResourcePos[nIndex].nY
    local nZ = tbMapCell.tbResourcePos[nIndex].nZ

    local tbData = {}
    tbData.nInstanceId = nInstanceId
    local nPosX = math.floor(nX)-- / COORDINATE_PROPORTION)
    local nPosY = math.floor(nY)-- / COORDINATE_PROPORTION)
    local nPosZ = math.ceil(nZ)-- / COORDINATE_PROPORTION)
    -- tbData.nPos = BitHelper:XYToPos(nPosX, nPosY)

    -- log("[selectpoint] bot point: ", tbData.nInstanceId, nIndex, nX, nY, nZ)
    self:SetSelectionPoint(tbData.nInstanceId, tbData.nPos, nPosX, nPosY, nPosZ, -1)

    return tbData, nPosX, nPosY
end

local function NearResourceCell(self, tbMapCell, nInstanceId)
    local nRow = tbMapCell.nRow
    local nCol = tbMapCell.nCol

    local tbCells = {}
    local tbHasPlayerCells = {}
    local nStep = 1
    if tbMapCell.bIsOcean then
        -- 如果是海，100米内再有资源的几率比较小
        nStep = 3
    end
    for i = -1 * nStep, 1 * nStep, nStep do
        local tbRowCells = self.tbMapCells[nRow + i]
        if tbRowCells ~= nil then
            for j = -1 * nStep, 1 * nStep, nStep do
                local tbCell = tbRowCells[nCol + j]
                if tbCell ~= nil and tbCell.tbResourcePos ~= nil then
                    if tbCell.nPlayerCount > 0 then
                        if #tbCell.tbResourcePos > 1 then
                            table.insert(tbHasPlayerCells, tbCell)
                        end
                    else
                        table.insert(tbCells, tbCell)
                    end
                end
            end
        end
    end

    local tbTempCells = #tbCells > 0 and tbCells or tbHasPlayerCells
    if #tbTempCells == 0 then
        return
    end
    local nIndex = math.random(1, #tbTempCells)
    local nResIndex = math.random(1, #tbTempCells[nIndex].tbResourcePos)
    return ResourceCell(self, tbTempCells[nIndex], nInstanceId, nResIndex)
end

local function SetTeamSelectionPoint(self, nInstanceId, tbMapCell)
    local tbPlayer = GameObjectSystem:FindByInstanceId(nInstanceId)
    if tbPlayer and tbPlayer.BattleTeamComponent then
        local BattleTeamComponent = tbPlayer.BattleTeamComponent
        local nTeamId = BattleTeamComponent.nTeamId
        log("[selectpoint] set team selection point ", nTeamId)
        if self.tbSelectedTeam[nTeamId] == nil then
            if tbMapCell ~= nil then
                log("[selectpoint] player ", tbPlayer.nPlayerId, nTeamId, tbMapCell.nId)
                self.tbSelectedTeam[nTeamId] = {tbMapCell = tbMapCell, nPlayerId = tbPlayer.nPlayerId}
            end
        elseif self.tbSelectedTeam[nTeamId].nPlayerId == tbPlayer.nPlayerId then
            if tbMapCell ~= nil then 
                self.tbSelectedTeam[nTeamId].tbMapCell = tbMapCell
            else
                log("[selectpoint] cancel team point ", tbPlayer.nPlayerId, nTeamId)
                self.tbSelectedTeam[nTeamId] = nil
                local tbMembers = BattleTeamSystem:GetTeamMembers(nTeamId)
                for _, tbMember in ipairs(tbMembers) do
                    if self.tbSelectedPlayer[tbMember.nPlayerId] ~= nil then
                        log("[selectpoint] reset team point ", tbMember.nPlayerId, nTeamId)
                        self.tbSelectedTeam[nTeamId] = {tbMapCell = self.tbSelectedPlayer[tbMember.nPlayerId].tbMapCell, nPlayerId = tbMember.nPlayerId}
                        break
                    end
                end                
            end
        else
            if tbMapCell ~= nil then
                local tbLeader = BattleTeamComponent:GetTeamLeader()
                local nLeaderInstanceId = tbLeader and tbLeader.nInstanceId
                if nLeaderInstanceId and nLeaderInstanceId == nInstanceId then
                    self.tbSelectedTeam[nTeamId] = {tbMapCell = tbMapCell, nPlayerId = tbPlayer.nPlayerId}
                    log("[selectpoint] leader ", tbLeader.nPlayerId, nTeamId, tbMapCell.nId)
                end
            else
                log("[selectpoint] cancel is not select firster or leader")
            end
        end
    end
end

local function SelectPointFromTeam(self, nInstanceId)
    local tbPlayer = GameObjectSystem:FindByInstanceId(nInstanceId)
    if tbPlayer and tbPlayer.BattleTeamComponent then
        local BattleTeamComponent = tbPlayer.BattleTeamComponent
        local nTeamId = BattleTeamComponent.nTeamId
        local tbTeamSelectionData = self.tbSelectedTeam[nTeamId]
        log("[selectpoint] get team point ", tbPlayer.nPlayerId, nTeamId)
        if tbTeamSelectionData then
            local tbMapCell = tbTeamSelectionData.tbMapCell
            log("[selectpoint] geted team point ", tbPlayer.nPlayerId, nTeamId, tbMapCell.nId)
            local tbData = RandomInCell(self, tbMapCell, nInstanceId, SELECTION_TYPE.FOLLOW)
            return tbData
        end
    end
end

local function SelectBotPointFromTeam(self, nInstanceId)
    local tbPlayer = GameObjectSystem:FindByInstanceId(nInstanceId)
    if tbPlayer and tbPlayer.BattleTeamComponent then
        local BattleTeamComponent = tbPlayer.BattleTeamComponent
        local nTeamId = BattleTeamComponent.nTeamId
        local tbTeamSelectionData = self.tbSelectedTeam[nTeamId]
        log("[selectpoint] get bot team point ", tbPlayer.nPlayerId, nTeamId)
        if tbTeamSelectionData then
            local tbMapCell = tbTeamSelectionData.tbMapCell
            log("[selectpoint] geted bot team point ", tbPlayer.nPlayerId, nTeamId, tbMapCell.nId)
            return NearResourceCell(self, tbMapCell, nInstanceId)
        end
    end
end

local function AutoPlayerSelectionPoint(self, tbPlayer)
    local tbMapCells = {}
    local tbTempCells = {}
    for _, tbMapRow in ipairs(self.tbMapCells) do
        for _, tbMapCell in ipairs(tbMapRow) do
            if self.bNoobDungeon then
                if tbMapCell.bPlayerBornArea and tbMapCell.bInNoobArea then
                    if tbMapCell.nPlayerCount <= 0 then
                        table.insert(tbMapCells, tbMapCell)
                    else
                        table.insert(tbTempCells, tbMapCell)
                    end
                end
            else
                if self.bHasResource then
                    if tbMapCell.bPlayerBornArea and tbMapCell.bHasResource then
                        -- log("AutoPlayerSelectionPoint add cell has resource", tbMapCell.nPlayerCount)
                        if tbMapCell.nPlayerCount <= 0 then
                            table.insert(tbMapCells, tbMapCell)
                        else
                            table.insert(tbTempCells, tbMapCell)
                        end
                    end
                else
                    if tbMapCell.bPlayerBornArea then
                        -- log("AutoPlayerSelectionPoint add cell ", tbMapCell.nPlayerCount)
                        if tbMapCell.nPlayerCount <= 0 and tbMapCell.bInNoobArea then
                            table.insert(tbMapCells, tbMapCell)
                        else
                            table.insert(tbTempCells, tbMapCell)
                        end
                    end
                end
            end
        end
    end

    if #tbMapCells == 0 then
        tbMapCells = tbTempCells
        logwarning("AutoPlayerSelectionPoint no blank cell")
    end

    self.tbAutoPointInfos = {}

    local tbAllPlayers = tbPlayer ~= nil and {tbPlayer:GetServerInstanceId()} or GetAllObject(self, false)
    local nRandomIndex
    local nObjIndex, nObjCount, nCellIndex, nCellCount  = 1, #tbAllPlayers, 1, #tbMapCells
    local tbTempCell1, tbTempCell2
    local tbData

    log("AutoPlayerSelectionPoint has resource=", self.bHasResource)
    log(string.format("AutoPlayerSelectionPoint objCount= %d, mapCellCount = %d, allCellCount =%d", nObjCount, nCellCount, #self.tbMapCells))
    while nObjIndex <= nObjCount do
        -- 队伍自动选点
        tbData = SelectPointFromTeam(self, tbAllPlayers[nObjIndex])
        if tbData == nil then
            -- 随机地图格子
            nRandomIndex = math.random(nCellIndex, nCellCount)
            tbTempCell1, tbTempCell2 = tbMapCells[nCellIndex], tbMapCells[nRandomIndex]
            tbMapCells[nCellIndex], tbMapCells[nRandomIndex] = tbTempCell2, tbTempCell1

            -- 随机地图格子中的x,y
            tbData = RandomInCell(self, tbTempCell2, tbAllPlayers[nObjIndex], SELECTION_TYPE.AUTO)
            table.insert(self.tbAutoPointInfos, tbData)
            -- 如果地图格子比玩家数少，则循环
            nObjIndex = nObjIndex + 1
            nCellIndex = nCellIndex + 1
            if nCellIndex >= nCellCount then
                logwarning("AutoPlayerSelectionPoint player count > map cell count !")
                nCellIndex = 1
            end
        else
            table.insert(self.tbAutoPointInfos, tbData)
            nObjIndex = nObjIndex + 1
        end
    end

    return tbData
end

--------------------------start--分布bot-----------------------
-- 遍历格子，排除玩家占有和影响的格子
-- 计算格子和玩家的距离。
-- 根据距离和是否有资源，设置格子权重
-- 根据权重随机分配bot
--------------------------------------------------------------
local function CollectPlayerAndBotCell(self, tbBotObjs)
    local nDefaultCellCount = ParachutingNewIni.tbReadyArea.nBPDefaultCellCount

    local fnDistance = function(nRow, nCol)
        local nMinDistance = 99999999
        for _, v in pairs(self.tbSelectedPlayer) do
            local tbMapCell = v.tbMapCell
            nMinDistance = math.min(math.max(math.abs(tbMapCell.nRow - nRow), math.abs(tbMapCell.nCol - nCol)), nMinDistance)
        end
        -- 小于nDefaultCellCount为bot离玩家最小的距离，bot不能选点
        if nMinDistance <= nDefaultCellCount then
            return 0
        end
        -- 距离权重占比高于资源
        return nMinDistance - nDefaultCellCount
    end

    local tbBotCells = {tbResource = {}, tbNoResource = {}}

    for _, tbMapRow in ipairs(self.tbMapCells) do
        for _, tbMapCell in ipairs(tbMapRow) do
            if tbMapCell.bPlayerBornArea and tbMapCell.nPlayerCount <= 0 then
                if fnDistance(tbMapCell.nRow, tbMapCell.nCol) > 0 then
                    if tbMapCell.bHasResource then
                        table.insert(tbBotCells.tbResource, tbMapCell)
                    else
                        table.insert(tbBotCells.tbNoResource, tbMapCell)
                    end
                end
            end
        end
    end

    return tbBotCells
end
--
local function BotSelectionPoint(self, tbBotObjs, tbBotCells)
    if #tbBotCells.tbResource + #tbBotCells.tbNoResource == 0 then
        logerror("FFASelectionPointStep bot selection cell count = 0")
        return
    end

    local nObjIndex, nObjCount = 1, #tbBotObjs

    local fnSetBotPoint = function(tbCells)
        local nCellCount = #tbCells
        if nCellCount == 0 then
            return
        end
        local nCellIndex, nRandomIndex = 1, 1
        local tbTempCell1, tbTempCell2
        local tbData
        while nObjIndex <= nObjCount do
            if self.tbSelectedPlayer[tbBotObjs[nObjIndex]] == nil then
                tbData = SelectBotPointFromTeam(self, tbBotObjs[nObjIndex])
                if tbData == nil then
                    nRandomIndex = math.random(nCellIndex, nCellCount)
                    tbTempCell1, tbTempCell2 = tbCells[nCellIndex], tbCells[nRandomIndex]
                    tbCells[nCellIndex], tbCells[nRandomIndex] = tbTempCell2, tbTempCell1

                    -- 随机地图格子中的x,y
                    if tbTempCell2.tbResourcePos ~= nil then
                        tbData = ResourceCell(self, tbTempCell2, tbBotObjs[nObjIndex])
                    else
                        tbData = RandomInCell(self, tbTempCell2, tbBotObjs[nObjIndex], -1)
                    end
                    table.insert(self.tbAutoPointInfos, tbData)
                    nObjIndex = nObjIndex + 1
                    nCellIndex = nCellIndex + 1
                    if nCellIndex > nCellCount then
                        break
                    end
                else
                    table.insert(self.tbAutoPointInfos, tbData)
                    nObjIndex = nObjIndex + 1
                end
            else
                nObjIndex = nObjIndex + 1
            end
        end
    end

    log(string.format("BotSelectionPoint BotCount = %d, ResourceCellCount = %d, NoResourceCellCount = %d", nObjCount, #tbBotCells.tbResource, #tbBotCells.tbNoResource))
    while nObjIndex <= nObjCount do
        fnSetBotPoint(tbBotCells.tbResource)
        fnSetBotPoint(tbBotCells.tbNoResource)
    end
end

local function AutoBotSelectionPoint(self)
    local tbBotObjs = GetAllObject(self, true)
    if #tbBotObjs > 0 then
        log("FFASelectionPointStep AutoBotSelectionPoint start ")
        local tbBotCells = CollectPlayerAndBotCell(self, tbBotObjs)
        BotSelectionPoint(self, tbBotObjs, tbBotCells)
        log("FFASelectionPointStep AutoBotSelectionPoint end ", #self.tbAutoPointInfos)
    end
end
---------------------------end --分布bot

local function SelectionLandPoint(self, tbPlayer)
    if self.tbLandMapPos == nil then
        DividingLandMapCell(self)
    end
    local nIndex = math.random( 1, #self.tbLandMapPos )
    local tbPos = self.tbLandMapPos[nIndex]
    local pLocation = Vector{X = tbPos.nX, Y = tbPos.nY, Z = 10000}
    local nZ = EngineExtActorShell.GetLocationZOnFloor(GWorld, pLocation, {}, 10000, -50000)
    return {X = pLocation.X, Y = pLocation.Y, Z = nZ, Yaw = 0}
end

local function SelectionPointFromLast(self, tbPlayer, tbTransporters, nMinDis, nMaxDis)
    local tbMapCells = {}
    for nRow, tbMapRow in ipairs(self.tbMapCells) do
        for _, tbMapCell in ipairs(tbMapRow) do
            if tbMapCell.bPlayerBornArea then
                local nMinX, nMaxX = tbMapCell.nMinX, tbMapCell.nMaxX
                local nMinY, nMaxY = tbMapCell.nMinY, tbMapCell.nMaxY
                local nDistance1 = math.sqrt((nMinX)^2 + (nMinY)^2)
                local nDistance2 = math.sqrt((nMaxX)^2 + (nMaxY)^2)
                local bInArea = (nDistance1 > nMinDis and nDistance1 < nMaxDis)
                    or (nDistance2 > nMinDis and nDistance2 < nMaxDis)

                if bInArea then
                    table.insert(tbMapCells, tbMapCell)
                end
            end
        end
    end

    if #tbMapCells == 0 then
        logerror("SelectionPointFromLast no cells")
        return false
    end

    local nIndex = math.random(1, #tbMapCells)
    local tbMapCell = tbMapCells[nIndex]
    -- 随机地图格子中的x,y
    local tbData, nX, nY = RandomInCell(self, tbMapCell, tbPlayer:GetServerInstanceId(), SELECTION_TYPE.AUTO)
    tbData.nTransporterId = self:GetTransporter(nX * COORDINATE_PROPORTION, nY * COORDINATE_PROPORTION)

    local nTransporterUniqueId
    for i, v in ipairs(tbTransporters) do
        if v.nTransporterId == tbData.nTransporterId then
            nTransporterUniqueId = v.nUniqueId
        end
    end
    if nTransporterUniqueId == nil then
        logerror("SelectionPointFromLast no transporter", tbData.nTransporterId)
        return false
    end
    local tbTransporter = GameObjectSystem:FindByUniqueId(nTransporterUniqueId)
    if tbTransporter == nil or tbTransporter.pUEActor == nil then
        logerror("SelectionPointFromLast no transporter or pueactor")
        return false
    end
    log("carry late player ")
    tbTransporter.pUEActor:CarryPlayer(tbPlayer.pUEActor, nX * COORDINATE_PROPORTION, nY * COORDINATE_PROPORTION)

    return true
end

local function SetTeamMemberTransporter(self, nInstanceId)
    local nTransporterId = self.tbSelectedPlayer[nInstanceId].nTransporterId

    self.tbSelectedTransporterPlayer[nInstanceId] = nTransporterId
    log("[selectpoint] set transporter ", nInstanceId, nTransporterId)
    local tbPlayer = GameObjectSystem:FindByInstanceId(nInstanceId)
    if tbPlayer == nil or tbPlayer.BattleTeamComponent == nil then
        return
    end

    local BattleTeamComponent = tbPlayer.BattleTeamComponent
    local nTeamId = BattleTeamComponent.nTeamId
    local tbTeamSelectionData = self.tbSelectedTeam[nTeamId]
    if tbTeamSelectionData.nPlayerId ~= tbPlayer.nPlayerId then
        return
    end

    local tbTeamMembers = BattleTeamSystem:GetTeamMembers(nTeamId)
    if tbTeamMembers ~= nil then
        for _, tbTeamMember in pairs(tbTeamMembers) do
            if self.tbSelectedPlayer[tbTeamMember.nServerInstanceId] == nil then
                self.tbSelectedTransporterPlayer[tbTeamMember.nServerInstanceId] = nTransporterId
                log("[selectpoint] set transporter member", tbTeamMember.nServerInstanceId, nTransporterId)
            end
        end
    end
end

local function CancelTeamMemberTransporter(self, nInstanceId)
    self.tbSelectedTransporterPlayer[nInstanceId] = nil
    log("[selectpoint] cancel transporter ", nInstanceId)
    local tbPlayer = GameObjectSystem:FindByInstanceId(nInstanceId)
    if tbPlayer == nil or tbPlayer.BattleTeamComponent == nil then
        return
    end

    local BattleTeamComponent = tbPlayer.BattleTeamComponent
    local nTeamId = BattleTeamComponent.nTeamId
    local tbTeamSelectionData = self.tbSelectedTeam[nTeamId]
    if tbTeamSelectionData == nil then
        return
    end
    if tbTeamSelectionData.nPlayerId ~= tbPlayer.nPlayerId then
        return
    end

    local tbTeamMembers = BattleTeamSystem:GetTeamMembers(nTeamId)
    if tbTeamMembers ~= nil then
        for _, tbTeamMember in pairs(tbTeamMembers) do
            if self.tbSelectedPlayer[tbTeamMember.nServerInstanceId] == nil then
                self.tbSelectedTransporterPlayer[tbTeamMember.nServerInstanceId] = nil
                log("[selectpoint] cancel transporter member", tbTeamMember.nServerInstanceId)
            end
        end
    end
end

local function OnSpawnTypeOver(self, nSpawnType)
    if nSpawnType == SpawnerDef.SpawnerType.ITEMDROP then
        -- 资源点填充地图格子
        log("SelectionPointHelper:FillMapCell")
        self:FillMapCell()
    end
end

local function DestroyVBPTimer(self)
    if self.tbVBPAutoSendTimer ~= nil then
        self.tbVBPAutoSendTimer:Clear()
        self.tbVBPAutoSendTimer = nil
    end
end

local function OnProcessStateChanged(self, nState)
    if nState == ProtoDR.rFFAProcessState_EState.SELECTION then
        local tbTransporters = BattleTransporterHelper:GetAll()
        local nBotCount = #(GetAllObject(self, false))
        if nBotCount > 0 then
            local nTransporterCount = #(BattleTransporterHelper:GetTransporters())

            local nBotPlayerBaseRatio = math.floor((MAX_PLAYER_COUNT - nBotCount) / nBotCount)
            nBotPlayerBaseRatio = math.max(nBotPlayerBaseRatio, 0)

            local tbBaseValueParam = {}
            for i = VBP_LINE_SHIP_VALUE.MIN, VBP_LINE_SHIP_VALUE.MAX do
                table.insert(tbBaseValueParam, i)
            end
            local fnVBPGetRandomBaseMaxCount = function()
                local nIndex = math.random(1, #tbBaseValueParam)
                local nResult = tbBaseValueParam[nIndex]
                table.remove(tbBaseValueParam, nIndex)
                return nResult
            end
            local tbRadio = self.tbBotPlayerRatioData
            for _, v in pairs(tbTransporters) do
                local nTemp = math.min(nBotPlayerBaseRatio, VBP_BOT_PLAYER_BASE_MAX_COUNT + fnVBPGetRandomBaseMaxCount())
                tbRadio.tbBotPlayerBaseRatio[v.TransporterId] = nTemp
                tbRadio.tbBotPlayerRatio[v.TransporterId] = math.max(((MAX_PLAYER_COUNT - nBotCount) - nTransporterCount * nTemp) / nBotCount, 0)
                log("vbp base ratio ", v.TransporterId, nTemp)
            end
        end

        local fnAutoSendTransporterPlayerCount = function()
            for _, v in pairs(tbTransporters) do
                self:SendTransporterPlayerCount(v.TransporterId)
            end
        end
        local nInterval = math.random(5, 10)
        self.tbVBPAutoSendTimer = Timer.NewTimer(fnAutoSendTransporterPlayerCount, nInterval, true)
    else
        if nState >= ProtoDR.rFFAProcessState_EState.SELECTION_LOCK then
            DestroyVBPTimer(self)
        end
    end
end

local function OnPlayerEnter(self, tbPlayer)
    local nTeamId = BattleTeamSystem:FindTeamIdByInstanceId(tbPlayer.nServerInstanceId)
    local tbTeamMembers = BattleTeamSystem:GetTeamMembers(nTeamId)
    local RPCNetworkProxy = NetworkManager:GetRPCNetworkProxy()

    local PointInfos = {}
    if tbTeamMembers ~= nil then
        for _, tbTeamMember in pairs(tbTeamMembers) do
            local tbSelectedPoint = self.tbSelectedPlayer[tbTeamMember.nServerInstanceId]
            if tbSelectedPoint ~= nil then
                local nX = math.floor(tbSelectedPoint.nX / COORDINATE_PROPORTION) 
                local nY = math.floor(tbSelectedPoint.nY / COORDINATE_PROPORTION)
                local nPos = BitHelper:XYToPos(nX, nY)
            
                local tbData = {}
                tbData.nInstanceId = tbTeamMember.nServerInstanceId
                tbData.nPos = nPos
                table.insert(PointInfos, tbData)
            end
        end
    end

    if #PointInfos == 0 then
        return
    end
    local d2c_FFASelectionPoint = {}
    d2c_FFASelectionPoint.PointInfos = PointInfos
    RPCNetworkProxy:SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_FFASelectionPoint, d2c_FFASelectionPoint) 
end

function SelectionPointHelper:Init()
    -- 获得新手本区域
    GetNoobArea(self)
    -- 地图分格
    DividingMapCell(self)
    -- 填充地图格子
    -- FillMapCell(self)
    --
    self.tbSelectedPlayer = {}
    self.tbSelectedTeam = {}
    self.tbResourceTransforms = {}
    self.tbSelectedTransporterPlayer = {}
    self.tbBotPlayerRatioData = {
        tbBotPlayerBaseRatio = {},
        tbBotPlayerRatio = {}
    }
    self.bHideOtherSelectionPoint = not ParachutingNewIni.tbReadyArea.bOtherSelectionPoint
    EventManager:BindEventMethod(CommonEventDef.EV_SPAWN_TYPE_OVER , self, OnSpawnTypeOver)
    EventManager:BindEventMethod(CommonEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnProcessStateChanged)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerEnter)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_RELOGIN, self, OnPlayerEnter)
end

function SelectionPointHelper:Uninit()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_RELOGIN, self, OnPlayerEnter)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerEnter)
    EventManager:UnBindEventMethod(CommonEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnProcessStateChanged)
    EventManager:UnBindEventMethod(CommonEventDef.EV_SPAWN_TYPE_OVER , self, OnSpawnTypeOver)
    DestroyVBPTimer(self)
    self.tbSelectedTeam = nil
    self.tbSelectedPlayer = nil
    self.tbMapCells = nil
    self.tbLandTransforms = nil
    self.tbOceanTransforms = nil
    self.tbResourceTransforms = nil
    self.tbSelectedTransporterPlayer = nil
    self.tbBotPlayerRatioData = nil
end

function SelectionPointHelper:FillMapCell()
    FillMapCell(self)
end

-- function SelectionPointHelper:InitPlayerSelectionPoint(tbPlayer)
--     local tbSelectionPoint = {
--         nInstanceId = tbPlayer:GetServerInstanceId(),
--         nX = 0,
--         nY = 0
--     }
--     table.insert(self.tbPosList, tbSelectionPoint)
-- end

-- local function LogEvent(self)
--     for k, v in pairs(self.tbSelectedPlayer) do
--         if v.nPlayerId and v.nPlayerId > 0 then
--             EventManager:OnFireEvent(CommonEventDef.EV_LOG_CHOOSE_DROP_ZONE, v)
--         end
--     end
-- end

local function SetTransporterPlayerCount(self)
    for i, v in ipairs(self.tbAutoPointInfos) do
        local tbData = self.tbSelectedPlayer[v.nInstanceId]
        if tbData ~= nil then
            self.tbSelectedTransporterPlayer[v.nInstanceId] = tbData.nTransporterId
        end
    end
end

function SelectionPointHelper:AutoSelectionPoint()
    -- 没有选点的玩家随机选点
    AutoPlayerSelectionPoint(self)
    -- 设置同航线人数
    SetTransporterPlayerCount(self)

    -- bot选点
    EventManager:OnFireEvent(CommonEventDef.EV_FFA_BOT_AUTO_SELECTION_POINT_START, self)
    AutoBotSelectionPoint(self)
    EventManager:OnFireEvent(CommonEventDef.EV_FFA_BOT_AUTO_SELECTION_POINT_END, self)
    --
    EventManager:OnFireEvent(CommonEventDef.EV_FFA_AUTO_SELECTION_POINT)
    -- 向客户端发送随机选点
    local nAutoPointCount = #self.tbAutoPointInfos
    if nAutoPointCount > 0 then
        if self:GetHideOtherSelectionPoint() then
            local tbSendedTeamId = {}
            local RPCNetworkProxy = NetworkManager:GetRPCNetworkProxy()
            for i, v in ipairs(self.tbAutoPointInfos) do
                local nTeamId = BattleTeamSystem:FindTeamIdByInstanceId(v.nInstanceId)
                if tbSendedTeamId[nTeamId] == nil then
                    tbSendedTeamId[nTeamId] = {}
                end
                table.insert(tbSendedTeamId[nTeamId], v)
            end
            for k, v in pairs(tbSendedTeamId) do
                local d2c_FFASelectionPoint = {PointInfos=v}
                local tbTeamMembers = BattleTeamSystem:GetTeamMembers(k)
                if tbTeamMembers ~= nil then
                    for _, tbTeamMember in pairs(tbTeamMembers) do
                        RPCNetworkProxy:SendToClient(tbTeamMember:GetUEControllerUniqueId(), ProtoDC.d2c_FFASelectionPoint, d2c_FFASelectionPoint)
                    end
                end
            end

            -- local tbTransporters = BattleTransporterHelper:GetAll()
            -- for _, v in pairs(tbTransporters) do
            --     log("AutoSelectionPoint send count: ", v.TransporterId)
            --     self:SendTransporterPlayerCount(v.TransporterId)
            -- end
        else
            local d2c_FFASelectionPoint = {
                PointInfos = self.tbAutoPointInfos
            }
            NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_FFASelectionPoint, d2c_FFASelectionPoint, false)
        end
    end

    -- LogEvent(self)
end

function SelectionPointHelper:SelectionPoint(tbPlayer)
    return AutoPlayerSelectionPoint(self, tbPlayer)
end

function SelectionPointHelper:GetTransporter(nX, nY)
    local tbTransporters = BattleTransporterHelper:GetAll()
    local nMinDistance, nTransporterId, nDistance = -1, 0, 0
    for _, v in pairs(tbTransporters) do
        nDistance = math.sqrt((nX - v.StartNode.X)^2 + (nY - v.StartNode.Y)^2)
        if nMinDistance < 0 or nMinDistance > nDistance then
            nMinDistance = nDistance
            nTransporterId = v.TransporterId
        end
    end
    return nTransporterId
end

function SelectionPointHelper:SetSelectionPoint(nInstanceId, nPos, nX, nY, nZ, nSelectionType)
    local tbPointInfo = {}
    tbPointInfo.nInstanceId = nInstanceId
    tbPointInfo.nPos = nPos
    tbPointInfo.nX = nX
    tbPointInfo.nY = nY
    tbPointInfo.nZ = nZ
    tbPointInfo.nTransporterId = self:GetTransporter(tbPointInfo.nX, tbPointInfo.nY)
    tbPointInfo.nCount = 0

    -- ChangePlayerSelectionPoint(self, nInstanceId, nX, nY)
    local tbMapCell = GetMapCell(self, tbPointInfo.nX, tbPointInfo.nY)
    if tbMapCell then
        local tbGameObject = GameObjectSystem:FindByInstanceId(nInstanceId)
        local nPlayerId = tbGameObject and tbGameObject:GetPlayerId() or 0
        tbMapCell.nPlayerCount = tbMapCell.nPlayerCount + 1
        local tbOldData = self.tbSelectedPlayer[nInstanceId]
        log("select point ", nPlayerId, nSelectionType, tbPointInfo.nX, tbPointInfo.nY, tbPointInfo.nZ)
        self.tbSelectedPlayer[nInstanceId] = {tbMapCell = tbMapCell, nPlayerId = nPlayerId, nCount = tbOldData and tbOldData.nCount + 1 or 1,
            nX = tbPointInfo.nX, nY = tbPointInfo.nY, nZ = tbPointInfo.nZ, nSelectionType = nSelectionType, nTransporterId = tbPointInfo.nTransporterId}
        SetTeamSelectionPoint(self, nInstanceId, tbMapCell)
    else
        logerror("SetSelectionPoint not find mapcell ", tbPointInfo.nY, tbPointInfo.nY)
    end
end

function SelectionPointHelper:StartMove()
    self.nStartMoveTime = GlobalVariableSystem:GetLocalTime()
end

function SelectionPointHelper:RandomSpawnPlayer(tbPlayer, tbTransporters)
    local nCurTime = GlobalVariableSystem:GetLocalTime()
    local nStartMoveTime = GlobalVariableSystem:GetLocalTime()
    if self.nStartMoveTime ~= nil then
        nStartMoveTime = self.nStartMoveTime
    end
    log("SelectionPointHelper:RandomSpawnPlayer: ", nStartMoveTime)
    local nOverTime = nCurTime - nStartMoveTime
    local nDistance = self.nTriggerMoveVelocity * nOverTime

    local tbReadyArea = ParachutingNewIni.tbReadyArea
    local nAutoSelectionMaxRadius = tbReadyArea.nAutoSelectionMaxRadius

    local nAutoSelectionMinRadius = tbReadyArea.nAutoSelectionMinRadius

    local nMin = math.max(nAutoSelectionMinRadius, nDistance)
    SelectionPointFromLast(self, tbPlayer, tbTransporters, nMin, nAutoSelectionMaxRadius)
end

function SelectionPointHelper:GetInBattleBornPos(tbPlayer)
    local nCurTime = GlobalVariableSystem:GetLocalTime()
    local nStartMoveTime = GlobalVariableSystem:GetLocalTime()
    if self.nStartMoveTime ~= nil then
        nStartMoveTime = self.nStartMoveTime
    end
    log("SelectionPointHelper:GetInBattleBornPos: ", nStartMoveTime)
    local nOverTime = nCurTime - nStartMoveTime
    local nDistance = self.nTriggerMoveVelocity * nOverTime

    local tbReadyArea = ParachutingNewIni.tbReadyArea
    local nAutoSelectionMaxRadius = tbReadyArea.nAutoSelectionMaxRadius

    if nDistance >= self.nTriggerMoveDistance or nDistance >= nAutoSelectionMaxRadius then
        log("GetInBattleBornPos no transporter")
    -- 船已经行驶完了
        return SelectionLandPoint(self)
    end
end

function SelectionPointHelper:GetBornPos(nInstanceId)
    local tbInfo = self.tbSelectedPlayer[nInstanceId]
    if tbInfo then
        return tbInfo.nX, tbInfo.nY, tbInfo.nZ, tbInfo.nTransporterId
    end
end

function SelectionPointHelper:SetBornPos(nInstanceId, nX, nY, nZ)
    local tbData = {}
    tbData.nInstanceId = nInstanceId
    local nPosX = math.floor(nX)
    local nPosY = math.floor(nY)
    local nPosZ = math.ceil(nZ)

    log("set born pos ", nInstanceId)
    self:SetSelectionPoint(tbData.nInstanceId, tbData.nPos, nPosX, nPosY, nPosZ, -1)
end

function SelectionPointHelper:ManualSelectionPoint(nInstanceId, nPos, nX, nY)
    self:SetSelectionPoint(nInstanceId, nPos, nX * COORDINATE_PROPORTION, nY * COORDINATE_PROPORTION, 0, SELECTION_TYPE.MANUAL)
    SetTeamMemberTransporter(self, nInstanceId)
    return self.tbSelectedPlayer[nInstanceId] and self.tbSelectedPlayer[nInstanceId].nTransporterId
end

function SelectionPointHelper:CancelSelectionPoint(nInstanceId)
    if self.tbSelectedPlayer[nInstanceId] == nil then
        return false
    end
    log("[selectpoint] cancel select point ", nInstanceId)
    self.tbSelectedPlayer[nInstanceId] = nil
    CancelTeamMemberTransporter(self, nInstanceId)
    SetTeamSelectionPoint(self, nInstanceId)
    return true
end

function SelectionPointHelper:AddResourceTransform(tbTransform)
    if self.tbResourceTransforms ~= nil then
        -- 联网本才进来
        local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
        local nRegionType = GridTypeManager:GetRegionType(tbTransform.X, tbTransform.Y)
        if nRegionType ~= self.TYPE_ROCK then
            local tbData = {tbTransform = tbTransform, bIsOcean = self.TYPE_OCEAN == nRegionType}
            table.insert(self.tbResourceTransforms, tbData)
        end
    end
end

function SelectionPointHelper:SetHideOtherSelectionPoint(bHide)
    self.bHideOtherSelectionPoint = bHide
end

function SelectionPointHelper:GetHideOtherSelectionPoint()
    return self.bHideOtherSelectionPoint
end

function SelectionPointHelper:GetTransporterPlayerCount(nTransporterId)
    local nCount = 0
    for k, v in pairs(self.tbSelectedTransporterPlayer) do
        if v == nTransporterId then
            nCount = nCount + 1
        end
    end
    return nCount
end

function SelectionPointHelper:SendTransporterPlayerCount(nTransporterId)
    local nCount = self:GetTransporterPlayerCount(nTransporterId)
    if ParachutingNewIni.tbReadyArea.bBotVirtualSelectionPoint then
        local tbRatio = self.tbBotPlayerRatioData

        local tbGameState = BattleGameModeSystem:GetGameState()
        local rStepRemainTime = tbGameState.rStepRemainTime
        local nBaseRatio = 0
        if rStepRemainTime and tbRatio.tbBotPlayerBaseRatio[nTransporterId] then
            local nTime = math.max(VBP_RATIO_INTERVAL - rStepRemainTime.nTime, 0)
            nBaseRatio = math.min(math.floor(nTime / VBP_RATIO_TIMER), tbRatio.tbBotPlayerBaseRatio[nTransporterId])
        end
        -- bot基数随时间递增到tbRatio.nBotPlayerBaseRatio
        local nBotPlayerRatio = tbRatio.tbBotPlayerRatio[nTransporterId] or  0
        nCount = nCount + math.floor(nBotPlayerRatio * nCount) + nBaseRatio
    end
    local d2c_FFATransporterPlayerCount = {
        nCount = nCount
    }
    local RPCNetworkProxy = NetworkManager:GetRPCNetworkProxy()
    local tbPlayer
    for k, v in pairs(self.tbSelectedTransporterPlayer) do
        if v == nTransporterId then
            tbPlayer = GameObjectSystem:FindByInstanceId(k)
            if tbPlayer ~= nil then
                RPCNetworkProxy:SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_FFATransporterPlayerCount, d2c_FFATransporterPlayerCount)
            end
        end
    end
end

function SelectionPointHelper:GetSelectedTransporterId(nInstanceId)
    return self.tbSelectedTransporterPlayer[nInstanceId]
end

function SelectionPointHelper:SendTransporterPlayerCountByPlayer(tbPlayer)
    local nTransporterId = self:GetSelectedTransporterId(tbPlayer.nServerInstanceId)
    if nTransporterId ~= nil then
        log("SelectionPointHelper:SendTransporterPlayerCountByPlayer ", tbPlayer.nServerInstanceId)
        return
    end
    SelectionPointHelper:SendTransporterPlayerCount(nTransporterId)
end

function SelectionPointHelper:GetRandomBornPosByRegionType(bIsOcean)
    if self.tbLandTransforms == nil then
        self.tbLandTransforms = {}
        self.tbOceanTransforms = {}
        for i, v in ipairs(self.tbResourceTransforms) do
            if v.bIsOcean then
                table.insert(self.tbOceanTransforms, v)
            else
                table.insert(self.tbLandTransforms, v)
            end
        end
    end

    local tbData
    if bIsOcean then
        local nIndex = math.random(1, #self.tbOceanTransforms)
        tbData = self.tbOceanTransforms[nIndex]
    else
        local nIndex = math.random(1, #self.tbLandTransforms)
        tbData = self.tbLandTransforms[nIndex]
    end
    return tbData.tbTransform.X, tbData.tbTransform.Y, tbData.tbTransform.Z
end

function SelectionPointHelper:GetSelectionData()
    return self.tbSelectedPlayer
end

function SelectionPointHelper:GetPlayerSelectionInfo(nInstanceId)
    return self.tbSelectedPlayer[nInstanceId]
end

return SelectionPointHelper