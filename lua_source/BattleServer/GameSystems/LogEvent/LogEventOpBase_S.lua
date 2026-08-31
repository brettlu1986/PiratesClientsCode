local luaclass = require("luaclass")
local LogEventOpBase = require("LogEventOpBase")
local LogEventOpBase_S = luaclass("LogEventOpBase_S", LogEventOpBase)

local Analytics = require("DungeonAnalyticsProtoNames")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattlePrepareSystem = require("BattlePrepareSystem")

-------------------------------local function-----------------------------------------------
local function SaveCommonPropertys(self, tbPacket)
    tbPacket.map_id = BattleGameModeSystem.nDungeonId
    tbPacket.game_mode = Analytics.BattleGameModeInfo.CLASSIC

    local team_mode = nil
    local nTeamModeId = BattleGameModeSystem:GetGameInitData().nTeamModeId
    if nTeamModeId == 1 then
        team_mode = Analytics.BattleTeamMode.SINGLE
    elseif nTeamModeId == 2 then
        team_mode = Analytics.BattleTeamMode.DOUBLE
    else
        team_mode = Analytics.BattleTeamMode.FOUR
    end

    tbPacket.team_mode = team_mode
    tbPacket.dungeon_id = BattleGameModeSystem:GetDungeonSessionId()
end

-------------------------------public function-----------------------------------------------
function LogEventOpBase_S:LogEvent(nPropName, tbPacket)
    logevent(nPropName, tbPacket)
end

--获取公共属性
--必须选点界面出来之后才能调用次函数！
function LogEventOpBase_S:GetBattleCommonPropertys()
    if self.tbParam.bIsBattleBegin then
        local tbRet = {}
        tbRet.dungeon_uuid = self.tbParam.szDungeonUuid
        tbRet.consume_time = math.floor(GlobalVariableSystem:GetLocalTime() - self.tbParam.nBattleBeginTime)
        local nTeamModeId = BattleGameModeSystem:GetGameInitData().nTeamModeId
        if nTeamModeId == 1 then
            tbRet.team_mode = Analytics.BattleCommonPropertys_BattleTeamMode.SINGLE
        elseif nTeamModeId == 2 then
            tbRet.team_mode = Analytics.BattleCommonPropertys_BattleTeamMode.DOUBLE
        else
            tbRet.team_mode = Analytics.BattleCommonPropertys_BattleTeamMode.FOUR
        end
        tbRet.game_mode_info = Analytics.BattleCommonPropertys_GameModeInfo.CLASSIC

        return tbRet
    end
    logerror("GetBattleCommonPropertys failed!")
    return nil
end

--向tbPacket内设置人埋点数据的公共数据
function LogEventOpBase_S:SavePlayerCommonPropertysToPacket(nPlayerId, tbPacket)
    local tbPrepareInfo = BattlePrepareSystem:GetPlayerPrepareInfo(nPlayerId)
    if tbPrepareInfo then
        tbPacket.channel = tbPrepareInfo.szChannel
    else
        tbPacket.channel = "UnDefined"
    end

    tbPacket.player_id = nPlayerId
    SaveCommonPropertys(self, tbPacket)
end

--向tbPacket内设置副本统计数据的公共数据
function LogEventOpBase_S:SaveDungeonCommonPropertysToPacket(tbPacket)
    tbPacket.channel = "dungeon" --固定值
    SaveCommonPropertys(self, tbPacket)
end

--把map数据转成字符串，键值用:分隔，键值用szSeparator分隔
function LogEventOpBase_S:MapToString(tbMap, szSeparator)
    local szRet = ""
    local bFirst = true
    for Key, Value in pairs(tbMap) do
        if not bFirst then
            szRet = szRet..szSeparator
        else
            bFirst = false
        end

        szRet = szRet..Key..":"..Value
    end

    return szRet
end

--把Array数据转成字符串，用szSeparator分隔
function LogEventOpBase_S:ArrayToString(tbArray, szSeparator)
    local szRet = ""
    local bFirst = true
    for _, Value in pairs(tbArray) do
        if not bFirst then
            szRet = szRet..szSeparator
        else
            bFirst = false
        end

        szRet = szRet..Value
    end

    return szRet
end

--获取战斗开始后已经过去的时间
function LogEventOpBase_S:GetBattleElapsedTime()
    return math.floor(GlobalVariableSystem:GetLocalTime() - self.tbParam.nBattleBeginTime)
end

function LogEventOpBase_S:GetLocationDetailInfo(fX, fY)
    local tbRet = {}
    local nX = math.ceil(fX)
    local nY = math.ceil(fY)
    tbRet.grid_region_type = self:GetGridRegionType(fX,fY)
    tbRet.point_x = nX
    tbRet.point_y = nY

    local nNumber = 100 --todo 将来可能需要根据dungeon_id不同配置不同的值
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbMapSize = tbGameMode.tbJsonTableFile.tbContainer.MapSize[1]
    local nMapSize = math.ceil(tbMapSize.GamePlayWidth)
    local nBlockNumber = math.ceil(nMapSize / nNumber)
    local nMapHalfSize = nMapSize / 2
    nX = nX + nMapHalfSize
    nY = nY + nMapHalfSize

    tbRet.grid_region_x = math.floor(nX/nBlockNumber)
    tbRet.grid_region_y = math.floor(nY/nBlockNumber)

    return tbRet
end

function LogEventOpBase_S:GetPlayerLocationDetailInfo(tbPlayer)
    local pLocation = tbPlayer:GetLocation()
    return self:GetLocationDetailInfo(pLocation.X, pLocation.Y)
end

function LogEventOpBase_S:GetGridRegionType(fX, fY)
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local nRealRegionType = GridTypeManager:GetRegionType(fX, fY)
    local eGridRegionType = nil
    if nRealRegionType ==  EPiratesGridRegionType.Land then
        eGridRegionType = Analytics.GridRegionType.LAND
    elseif nRealRegionType ==  EPiratesGridRegionType.Ocean then
        eGridRegionType = Analytics.GridRegionType.OCEAN
    elseif nRealRegionType ==  EPiratesGridRegionType.Shore then
        eGridRegionType = Analytics.GridRegionType.LAND
    elseif nRealRegionType ==  EPiratesGridRegionType.Port then
        eGridRegionType = Analytics.GridRegionType.OCEAN
    elseif nRealRegionType ==  EPiratesGridRegionType.Rock then
        eGridRegionType = Analytics.GridRegionType.ROCK
    elseif nRealRegionType ==  EPiratesGridRegionType.Lake then
        eGridRegionType = Analytics.GridRegionType.LAND
    end
    return eGridRegionType
end

function LogEventOpBase_S:GetPlayerGridRegionType(tbPlayer)
    local pLocation = tbPlayer:GetLocation()
    return self:GetGridRegionType(pLocation.X, pLocation.Y)
end

return LogEventOpBase_S