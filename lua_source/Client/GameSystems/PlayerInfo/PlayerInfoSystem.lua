-----------------------------------------------------
--File Name    : PlayerInfoSystem.lua
--Author       : WuJizhou
--Create Time  : 3/21/2019, 2:59:30 PM
--Description  : PlayerInfoSystem
-----------------------------------------------------
local PlayerInfoSystem = {}

local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")



local function FillBasicSummaryToBasicInfo(tbBasicInfo, tbSummary)
    tbBasicInfo.nAvatarId = tbSummary.avatar_id
    tbBasicInfo.szName = tbSummary.name
    tbBasicInfo.nPlayerId = tbSummary.id
    tbBasicInfo.nLevel = tbSummary.level
    tbBasicInfo.nExp = tbSummary.exp
    tbBasicInfo.nRank = tbSummary.rank
    tbBasicInfo.nTeamSize = tbSummary.team_size
end

local function PlayerSummaryToPlayerBasicInfo(tbPlayerSummary)
    local tbSummary = tbPlayerSummary
    local tbBasicInfo = {}
    FillBasicSummaryToBasicInfo(tbBasicInfo, tbSummary)
    return tbBasicInfo
end

local bUseCache = false

-- key: player id, value : PlayerSummary
PlayerInfoSystem.tbLocalSummaries = {}

PlayerInfoSystem.nPlayerIdOfCurrentInfoRequest = -1


------------------------ Public Api ------------------------
--@deprecated
-- 获取nPlayerId玩家的基本信息，
-- 如果local有相关信息则直接返回tbData，
-- 如果没有则向服务器发起请求并返回nil，应监听事件来获得tbData
function PlayerInfoSystem:GetPlayerBasicInfo(nPlayerId)
    assert(nPlayerId)
    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbPlayer:GetPlayerId() == nPlayerId then
        local LobbyPropertyComponent = tbPlayer.LobbyPropertyComponent
        local tbBasicInfo = {}
        tbBasicInfo.nAvatarId = LobbyPropertyComponent:GetAvatarId()
        tbBasicInfo.szName = LobbyPropertyComponent:GetPlayerName()
        tbBasicInfo.nPlayerId = nPlayerId
        tbBasicInfo.nLevel = LobbyPropertyComponent:GetPlayerLevel()
        tbBasicInfo.nExp = LobbyPropertyComponent:GetPlayerExp()
        tbBasicInfo.nRank = tbPlayer.SeasonComponent:GetMaxRank()
        return tbBasicInfo
    else
        local tbSummary = self.tbLocalSummaries[nPlayerId]
        if tbSummary then
            local tbBasicInfo = PlayerSummaryToPlayerBasicInfo(tbSummary)
            return tbBasicInfo
        else
            self.nPlayerIdOfCurrentInfoRequest = nPlayerId
            self:RequestPlayerSummariesFromServer({nPlayerId})
            return nil
        end
    end
end


------------------ Packet Processor Callback ---------------

function PlayerInfoSystem:OnPlayerSummariesReceived(tbSummaries)
    local tbLocalSummaries = self.tbLocalSummaries
    if not tbLocalSummaries then
        tbLocalSummaries = {}
        self.tbLocalSummaries= tbLocalSummaries
    end
    for _, tbSummary in ipairs(tbSummaries) do
        local nId = tbSummary.id
        tbLocalSummaries[nId] = tbSummary
        if nId == self.nPlayerIdOfCurrentInfoRequest then
            local tbBasicInfo = PlayerSummaryToPlayerBasicInfo(tbSummary)
            EventManager:OnFireEvent(ClientEventDef.EV_OTHER_PLAYER_BASIC_INFO_RECEIVED, tbBasicInfo)
        end
    end
    EventManager:OnFireEvent(ClientEventDef.EV_PLAYER_SUMMARIES_RECEIVED, tbSummaries)
end

function PlayerInfoSystem:OnPlayerSummaryChangeNotified(tbSummary)
    local tbLocalSummaries = self.tbLocalSummaries
    if not tbLocalSummaries then
        tbLocalSummaries = {}
        self.tbLocalSummaries= tbLocalSummaries
    end
    local nId = tbSummary.id
    tbLocalSummaries[nId] = tbSummary
    EventManager:OnFireEvent(ClientEventDef.EV_PLAYER_SUMMARY_CHANGE_NOTIFIED, tbSummary)
end


------------------------ Public Api ------------------------


-- return two list
--@return1 本地拥有相应summary缓存的playerid :{playerid1, playerid2}
--@return2  本地没有有相应summary缓存的playerid :{playerid1, playerid2}
function PlayerInfoSystem:HasPlayerSummaries(tbPlayerIdList)
    local tbCachedPlayerIds = {}
    local tbNoCachedPlayerIds = {}
    local tbLocalSummaries = self.tbLocalSummaries
    for _, nPlayerId in ipairs(tbPlayerIdList) do
        if tbLocalSummaries[nPlayerId] and bUseCache then
            table.insert(tbCachedPlayerIds, nPlayerId)
        else
            table.insert(tbNoCachedPlayerIds, nPlayerId)
        end
    end
    return tbCachedPlayerIds, tbNoCachedPlayerIds
end

-- 向server请求获取List中所有id的playersummary, 即使本地有缓存，依旧会请求，收到回包后覆盖本地缓存数据
function PlayerInfoSystem:RequestPlayerSummariesFromServer(tbPlayerIdList)
    if tbPlayerIdList and #tbPlayerIdList > 0 then
        local c2s_PlayerSummaries = {}
        c2s_PlayerSummaries.player_ids = tbPlayerIdList
        NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_PlayerSummaries, c2s_PlayerSummaries)
    end
end

-- 从本地缓存中获取相应的玩家summary, 如果本地没有缓存，则返回的数据中没有该数据
-- 该接口使用前应确保本地含有所有的缓存，使用HasPlayerSummaries判断
--@return table : -- key: player id, value : PlayerSummary
function PlayerInfoSystem:GetPlayerSummariesFromLocal(tbPlayerIdList)
    local tbResult = {}
    local tbLocalSummaries = self.tbLocalSummaries
    if tbLocalSummaries then
        if tbPlayerIdList and #tbPlayerIdList > 0 then
            for _, nPlayerId in ipairs(tbPlayerIdList) do
                local tbSummary = tbLocalSummaries[nPlayerId]
                if tbSummary then
                    tbResult[nPlayerId] = tbSummary
                end
            end
        end
    end
    return tbResult
end





------------------------ Override Api ------------------------

function PlayerInfoSystem:Init()
    self.tbLocalSummaries = {}
    self.nPlayerIdOfCurrentInfoRequest = -1
    return true
end

function PlayerInfoSystem:Uninit()
    self.tbLocalSummaries = {}
    self.nPlayerIdOfCurrentInfoRequest = -1
end

return PlayerInfoSystem