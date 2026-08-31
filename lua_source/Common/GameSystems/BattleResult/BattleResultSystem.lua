local luaclass = require("luaclass")
local BattleResultSystem = luaclass("BattleResultSystem")

local SelfEventHelper = require("SelfEventHelper")
local BattlePrepareSystem = require("BattlePrepareSystem")
local CommonEventDef = require("CommonEventDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local PlayerStatsHelper = require("PlayerStatsHelper")
local BattleTeamSystem = require("BattleTeamSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local HumanDataTable = require("HumanDataTable")
local GameObjectTypeDef = require("GameObjectTypeDef")
local EventManager = require("EventManager")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local NetworkManager = dynamic_require("NetworkManager")
local BotAISystem = dynamic_require("BotAISystem")
local BattleItemSystemServer = require("BattleItemSystemServer")
local BattleResultServerIni = require("BattleResultServerIni")
local ProtoDC = require("DungeonCommonProtoNames")
local HumanAvatarHelper = require("HumanAvatarHelper")

local DEATH_PLAYBACK_COUNT = 3

--玩家结算数据，Key为InstanceId
BattleResultSystem.tbPlayerResultData = nil  --玩家的结算数据
BattleResultSystem.tbBattleEndTeams   = nil  --哪些队伍已经战斗结束，存储了他们结束时的序号
BattleResultSystem.nPlayerCount = nil
BattleResultSystem.EventHelper = nil

BattleResultSystem.tbPlayerToLobbyRewards = nil

--战斗已经结束的人员列表。死亡玩家,胜利玩家，主动退出副本以及额外胜利的玩家(跟玩法相关)会被标记为战斗结束。
BattleResultSystem.tbBattleEndPlayersList = nil
BattleResultSystem.nWinnerBuffId = 0         --无敌buff,吃鸡队伍使用

--战斗未结束主动退出的人员列表
BattleResultSystem.tbEscapePlayersList = nil

-------------------------------------
function BattleResultSystem:Init()
    self.tbPlayerResultData = {}
    self.tbBattleEndTeams = {}
    self.tbPlayerToLobbyRewards = {}
    self.tbBattleEndPlayersList  = {}
    self.tbEscapePlayersList = {}
    self.nPlayerCount = 0
    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, self.OnPlayerLogin)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGOUT, self, self.OnPlayerLogout)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_PRE_DEAD, self, self.OnPawnPreDead)
end

function BattleResultSystem:Uninit()
    self.EventHelper:UnregisterAll()
end

function BattleResultSystem:OnPlayerLogin(tbPlayer)
    self.nPlayerCount = self.nPlayerCount + 1
end

function BattleResultSystem:OnPlayerLogout(tbPlayer)
    self.nPlayerCount = math.max(0, self.nPlayerCount - 1)
end

function BattleResultSystem:GetPlayerToLobbyRewards(nInstanceId)
    local tbPlayerToLobbyRewards = self.tbPlayerToLobbyRewards
    local tbData = tbPlayerToLobbyRewards[nInstanceId]
    if tbData == nil then
        tbData = {}
        tbPlayerToLobbyRewards[nInstanceId] = tbData
    end
    return tbData
end

function BattleResultSystem:OnPawnPreDead( tbGameObject)
    if tbGameObject and tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf and GlobalVariableSystem:IsServerLogic()  then
        local nPlayerInstanceId = tbGameObject:GetServerInstanceId()
        local nItemInsId = BattleItemSystemServer:GetUnequippedLeastStackCountInstanceId(nPlayerInstanceId, 
            BattleResultServerIni.nRusultEquipLevelupItem)
        if nItemInsId then  
            local tbItem = BattleItemSystemServer:GetItem(nItemInsId)
            local nStackCount = tbItem:GetStackCount()
            local nRewardCount = 0

            local tbData = self:GetPlayerToLobbyRewards(nPlayerInstanceId)
            tbData.nItemId = BattleResultServerIni.nRusultEquipLevelupItem
            local bLogOutDead = self:IsPlayerEscape(nPlayerInstanceId)   
            if bLogOutDead then  
                nRewardCount = 0  --设置登出死亡，不给任何东西
            else  
                if nStackCount > 0 then  
                    local nDeadLeft = math.ceil(BattleResultServerIni.nDeadLossPercent * nStackCount)  --修改死亡掉落  的数值
                    log("reward count 1:::", nStackCount, nDeadLeft)
                    tbItem:SetStackCount(nDeadLeft)
                    nRewardCount = nStackCount - nDeadLeft --给玩家奖励的数值
                    if nRewardCount >= BattleResultServerIni.nRewardMax then  
                        nRewardCount = BattleResultServerIni.nRewardMax
                    end
                    log("reward count 2:::", nRewardCount)
                end
            end
            tbData.nItemCount = nRewardCount
        end
    end
end
-------------------------------------
function BattleResultSystem:SetWinnerBuffId(nBuffId)
    self.nWinnerBuffId = nBuffId
end

function BattleResultSystem:GetPlayerResultData(nInstanceId, bCreate)
    local tbPlayerResultData = self.tbPlayerResultData
    local tbData = tbPlayerResultData[nInstanceId]
    if tbData == nil and bCreate then
        tbData = {}
        tbPlayerResultData[nInstanceId] = tbData
    end
    return tbData
end

--todo 目前仅供单机副本使用,将来单机副本和吃鸡都使用SavePlayerResultData，通过传参的方法赋予不同的值。
function BattleResultSystem:CreatePlayerResultData(tbPlayer)
    if not tbPlayer then
        return
    end
    local nPlayerInstanceId = tbPlayer:GetServerInstanceId()
    log("BattleResultSystem:CreatePlayerResultData",nPlayerInstanceId, tbPlayer:GetName())
    local tbData = self:GetPlayerResultData(nPlayerInstanceId,true)
    tbData.nPlayerCount = self.nPlayerCount
    tbData.nTeamRank = 1
    tbData.tbTeamPlayerStaticsData = {}
    local tbTeamMembers = BattleTeamSystem:GetTeamMembersByPlayer(tbPlayer)
    if tbTeamMembers then
        for k, v in ipairs(tbTeamMembers) do
            log("BattleResultSystem:CreatePlayerResultData,tbTeamMembers:name=", k, v:GetName(), v:GetPlayerId())
            local PlayerStaticsData = self:CreateTeamPlayerStaticsData(v)
            table.insert(tbData.tbTeamPlayerStaticsData, PlayerStaticsData)
        end
    else
        local PlayerStaticsData = self:CreateTeamPlayerStaticsData(tbPlayer)
        table.insert(tbData.tbTeamPlayerStaticsData, PlayerStaticsData)
    end
    return tbData
end

function BattleResultSystem:CreateTeamPlayerStaticsData(tbPlayer)
    local tbTeamPlayerStaticsData = {}
    local nPlayerId = tbPlayer:GetPlayerId()
    tbTeamPlayerStaticsData.nInstanceId = tbPlayer:GetServerInstanceId()
    tbTeamPlayerStaticsData.nPlayerId = nPlayerId
    tbTeamPlayerStaticsData.name = tbPlayer:GetName()
    if GlobalVariableSystem:IsServerLogic() then
        tbTeamPlayerStaticsData.nAvatarId = tbPlayer.tbPrepareInfo.nHumanId
        tbTeamPlayerStaticsData.nFashionId  = BattlePrepareSystem:GetFashionTemplateIds(nPlayerId)
        tbTeamPlayerStaticsData.appearances = BattlePrepareSystem:GetAppearancePartData(nPlayerId)
    else
        tbTeamPlayerStaticsData.nAvatarId = tbPlayer.nDungeonHumanId
        tbTeamPlayerStaticsData.nFashionId = {}
        tbTeamPlayerStaticsData.appearances = HumanAvatarHelper.GetDefaultAppearancePartData(tbPlayer.nDungeonHumanId)
    end

    local nDungeonId = BattleGameModeSystem.nDungeonId
    log("BattleResultSystem:CreateTeamPlayerStaticsData,nPlayerId=",nPlayerId)
    PlayerStatsHelper:GetClientStatisticsData(nPlayerId, 1, 0, nDungeonId, tbTeamPlayerStaticsData)
    return tbTeamPlayerStaticsData
end
-----------------------------------------------------------------------------------------------------

function BattleResultSystem:SendPlayerStatisticsDataToLobby(tbPlayer, nPlayerRank, nExtraScore, nTeamId, tbLobbyRewardsData)
    return nil
end

function BattleResultSystem:SendTeamStatisticsDataToLobby(tbTeamdata, nTeamId, nTeamRank, nMVPPlayerId, nPlayerCount, nTeamCount)
    return nil
end

function BattleResultSystem:SaveClientShowAwardsToPacket(tbAwards, tbPacket)
end

local function SaveClientStatisticsToPacket(self, tbPlayer, nRank, nExtraScore, tbAwards, tbPacket)
    local nPlayerId = tbPlayer.nPlayerId
    local nDungeonId = BattleGameModeSystem.nDungeonId
    if not BotAISystem:IsBot(tbPlayer) then
        PlayerStatsHelper:GetClientStatisticsData(nPlayerId, nRank, nExtraScore, nDungeonId, tbPacket)
        if tbAwards ~= nil then
            self:SaveClientShowAwardsToPacket(tbAwards, tbPacket)
        end
    else
        PlayerStatsHelper:GetBotStatisticsData(nPlayerId, nRank, nExtraScore, nDungeonId, tbPacket)
    end
end

-- 记录玩家结算数据
function BattleResultSystem:SavePlayerResult(tbPlayer, bTeamDead, bRank, nPlayerRank, nTeamId, nAdditionalScore)
    if tbPlayer == nil then
        return
    end

    local nInstanceId = tbPlayer:GetServerInstanceId()
    local tbDeadResult = self:GetPlayerResultData(nInstanceId,true)

    -- 个人数据
    tbDeadResult.nInstanceId = nInstanceId
    local nPlayerId = tbPlayer:GetPlayerId()
    tbDeadResult.nPlayerId = nPlayerId
    local tbHumanTemplate = HumanDataTable:GetTemplate(tbPlayer.tbPrepareInfo.nHumanId)
    if tbHumanTemplate then
        tbDeadResult.nGenderType = tbHumanTemplate.nGender
    end
    tbDeadResult.name = tbPlayer:GetName()
    tbDeadResult.nAvatarId   = tbPlayer.tbPrepareInfo.nHumanId
    tbDeadResult.nFashionId  = BattlePrepareSystem:GetFashionTemplateIds(nPlayerId)
    tbDeadResult.appearances = BattlePrepareSystem:GetAppearancePartData(nPlayerId)

    -- 有名次则为最终结算数据,没名次为临时数据
    -- 当队伍都死亡时候，如果还存在没有名次的玩家，给予当前结算玩家排名。避免重伤下同时死亡结算没有名次问题
    if (bRank and nPlayerRank) or (bTeamDead and tbDeadResult.nPlayerRank == nil) then
        tbDeadResult.nPlayerRank = nPlayerRank
    end

    local tbLobbyRewardsData = self:GetPlayerToLobbyRewards(tbPlayer:GetServerInstanceId())
    if not tbPlayer:IsDead() then  --没有死亡的 如果有 原力之尘 那么可全部带回大厅
        local nItemInsId = BattleItemSystemServer:GetUnequippedLeastStackCountInstanceId(tbPlayer:GetServerInstanceId(), 
            BattleResultServerIni.nRusultEquipLevelupItem)
        if nItemInsId then  
            local tbItem = BattleItemSystemServer:GetItem(nItemInsId)
            local nStackCount = tbItem:GetStackCount()
            tbLobbyRewardsData.nItemId = BattleResultServerIni.nRusultEquipLevelupItem
            if nStackCount >= BattleResultServerIni.nRewardMax then  
                nStackCount = BattleResultServerIni.nRewardMax
            end
            tbLobbyRewardsData.nItemCount = nStackCount
        end
    end

    -- 统计信息
    if bRank and nPlayerRank then
        local tbAwards = self:SendPlayerStatisticsDataToLobby(tbPlayer, bRank and nPlayerRank or nil, nAdditionalScore, nTeamId, tbLobbyRewardsData)
        SaveClientStatisticsToPacket(self, tbPlayer, bRank and nPlayerRank or nil, nAdditionalScore, tbAwards,tbDeadResult)
    else
        SaveClientStatisticsToPacket(self, tbPlayer, bRank and nPlayerRank or nil, nAdditionalScore, nil,tbDeadResult)
    end
end

local function GetTableCount(tbData)
    local nCount = 0
    for _, tbInfo in pairs(tbData) do
        if tbInfo then
            nCount = nCount + 1
        end
    end
    return nCount
end

--返回队伍战斗结束时的顺序号，0开始
function BattleResultSystem:SetTeamBattleEnd(nTeamId)
    if self.tbBattleEndTeams[nTeamId] == nil then
        self.tbBattleEndTeams[nTeamId] = GetTableCount(self.tbBattleEndTeams)
    end

    return self.tbBattleEndTeams[nTeamId]
end

function BattleResultSystem:IsTeamBattleEnd(nTeamId)
    return self.tbBattleEndTeams[nTeamId]
end

function BattleResultSystem:MarkPlayerBattleEnd(tbPlayer)
    if tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
        local nInstanceId = tbPlayer:GetServerInstanceId()
        self.tbBattleEndPlayersList[nInstanceId] = true

        EventManager:OnFireEvent(CommonEventDef.EV_PLAYER_BATTLE_END, tbPlayer)
    end
end

function BattleResultSystem:IsPlayerBattleEnd(nInstanceId)
    return self.tbBattleEndPlayersList[nInstanceId]
end

function BattleResultSystem:GetBattleEndPlayerList()
    return self.tbBattleEndPlayersList
end

function BattleResultSystem:MarkPlayerEscape(nInstanceId)
    self.tbEscapePlayersList[nInstanceId] = true
end

function BattleResultSystem:IsPlayerEscape(nInstanceId)
    return self.tbEscapePlayersList[nInstanceId]
end

-- 检查玩家队伍成员是否全部战斗结束，是则返回队伍排名
function BattleResultSystem:TryGetTeamRankAfterPlayerBattleEnd(tbBattleEndActor, nTeamCount)
    local nTeamId = BattleTeamSystem:FindTeamId(tbBattleEndActor)
    local tbMemberObjects = BattleTeamSystem:GetTeamMembers(nTeamId)

    for _, tbGamePlayer in ipairs(tbMemberObjects) do
        local nInstanceId = tbGamePlayer:GetServerInstanceId()
        local bPlayerBattleEnd  = self:IsPlayerBattleEnd(nInstanceId)
        if (not bPlayerBattleEnd and tbGamePlayer ~= tbBattleEndActor) then
            return false, nil
        end
    end

    local nBattleEndIndex = self:SetTeamBattleEnd(nTeamId)
    local nTeamRank = nTeamCount - nBattleEndIndex
    return true, nTeamRank
end

-- MVP计算
function BattleResultSystem:GetTeamMVP(tbPlayer)
    if tbPlayer == nil or tbPlayer.BattleTeamComponent == nil then
        return 0, 0
    end

    local tbTeamData = tbPlayer.BattleTeamComponent.tbTeamdata
    return PlayerStatsHelper:GetTeamMVP(tbTeamData)
end

local function SavePlayerResultData(self, tbPlayer, bTeamDead, bRank, nPlayerRank, nTeamId)
    --todo 暂时不用额外胜利分，因为额外胜利分本身跟玩法相关，这里的代码追求的是与代码无关,如果需要额外胜利功能，这里需要考虑怎么传入额外胜利分
    --local nInstanceId = tbPlayer:GetServerInstanceId()
    --local nAdditionalScore = BattleFFAAdditionalSuccessHelper:GetPlayerAdditionalScoreByInstanceId(nInstanceId)
    local nAdditionalScore = 0
    self:SavePlayerResult(tbPlayer, bTeamDead, bRank, nPlayerRank, nTeamId, nAdditionalScore)
end

local function GetTeamResultPacket(self, tbPlayer, nTeamModeId, nPlayerCount, nTeamCount, nPlayerRank)
    -- 结算
    local tbPacket = {}
    local bTeamDead, nTeamRank = self:TryGetTeamRankAfterPlayerBattleEnd(tbPlayer, nTeamCount)
    local nTeamId = BattleTeamSystem:FindTeamId(tbPlayer)
    local nPlayerInstanceId = tbPlayer:GetServerInstanceId()

    if nPlayerRank == 1 then
        nTeamRank = 1
    end

    -- 队伍数据
    tbPacket.nMode = nTeamModeId
    tbPacket.bTeamDead = bTeamDead
    tbPacket.nTeamRank = nTeamRank
    tbPacket.nPlayerCount = nPlayerCount
    tbPacket.nTeamCount  = nTeamCount

    SavePlayerResultData(self, tbPlayer, bTeamDead, true, nPlayerRank, nTeamId)

    -- 组织队伍结算数据
    tbPacket.FFATeamResult = {}
    local tbTeamdata = tbPlayer.BattleTeamComponent.tbTeamdata
    for _, tbData in ipairs(tbTeamdata) do
        local nInstanceId = tbData.nInstanceId
        local tbGameObject = GameObjectSystem:FindByInstanceId(nInstanceId)
        if nInstanceId ~= nPlayerInstanceId then
            SavePlayerResultData(self, tbGameObject, bTeamDead, false, nPlayerRank, nTeamId)
        end
        local tbResultData = self:GetPlayerResultData(nInstanceId)
        if tbResultData then
            table.insert(tbPacket.FFATeamResult, tbResultData)
        end
    end

    local nMVPInstanceId, nMVPPlayerId = self:GetTeamMVP(tbPlayer)
    if bTeamDead then
        tbPacket.nMVPInstanceId = nMVPInstanceId
        tbPacket.nMVPPlayerId = nMVPPlayerId
    end

    local tbRet = {}
    tbRet.tbPacket = tbPacket
    tbRet.bTeamDead = bTeamDead
    tbRet.tbTeamdata = tbTeamdata
    tbRet.nTeamId  = nTeamId
    tbRet.nTeamRank = nTeamRank
    tbRet.nMVPPlayerId = nMVPPlayerId

    return tbRet
end

-- 处理胜利玩家
local function OnPlayerSuccess(self, tbPlayer)
    tbPlayer.BuffComponentServer:RemoveAllBuff()
    tbPlayer.BuffComponentServer:AddBuffById(self.nWinnerBuffId)
end

function BattleResultSystem:GetWinerTeamId()
    local nTeamAlive = 0
    local nWinerTeamId = 0
    local tbAllTeamsInfo = BattleTeamSystem:GetAllTeamInfo()
    for nTeamId, tbTeam in pairs(tbAllTeamsInfo) do
        if  not self:IsTeamBattleEnd(nTeamId) and
            tbTeam.tbGameObjects             and
            #tbTeam.tbGameObjects > 0        then
            nTeamAlive = nTeamAlive + 1
            nWinerTeamId = nTeamId
        end
    end
    if nTeamAlive == 1 then
        return nWinerTeamId
    end
    return -1
end

local function IsBotInTeam(tbMembers)
    for _, v in pairs(tbMembers) do
        if BotAISystem:IsBot(v) then
            return true
        end
    end
    return false
end

local function IsBotTeam(tbMembers)
    for _, v in pairs(tbMembers) do
        if not BotAISystem:IsBot(v) then
            return false
        end
    end
    return true
end

--return (bGameOver,nWinerTeamId)
local function TryCheckIsGameOver(self, nTeamModeId, nPlayerCount, nTeamCount)
    local nWinerTeamId = self:GetWinerTeamId()
    if nWinerTeamId == -1 then
        return false,nil
    end

    local tbWinPacket = {}
    local nTeamRank = 1
    -- 队伍数据
    tbWinPacket.nMode = nTeamModeId
    tbWinPacket.bTeamDead = true
    tbWinPacket.nTeamRank = nTeamRank
    tbWinPacket.nPlayerCount = nPlayerCount
    tbWinPacket.nTeamCount  = nTeamCount

    local tbOnePlayer = nil
    local tbWinerMembers = BattleTeamSystem:GetTeamMembers(nWinerTeamId)
    for _, tbWinnerPlayer in ipairs(tbWinerMembers) do
        local nInstanceId = tbWinnerPlayer:GetServerInstanceId()
        local bPlayerBattleEnd  = self:IsPlayerBattleEnd(nInstanceId)
        if not bPlayerBattleEnd then
            tbOnePlayer = tbWinnerPlayer
            SavePlayerResultData(self, tbWinnerPlayer, true, true, nTeamRank, nWinerTeamId)
            OnPlayerSuccess(self,tbWinnerPlayer)
        end
    end

    tbWinPacket.FFATeamResult = {}
    local tbTeamdata = tbOnePlayer.BattleTeamComponent.tbTeamdata
    for _, tbData in ipairs(tbTeamdata) do
        local tbResultData = self:GetPlayerResultData(tbData.nInstanceId)
        if tbResultData then
            table.insert(tbWinPacket.FFATeamResult, tbResultData)
        end
    end

    local nMVPInstanceId, nMVPPlayerId = self:GetTeamMVP(tbOnePlayer)
    tbWinPacket.nMVPInstanceId = nMVPInstanceId
    tbWinPacket.nMVPPlayerId = nMVPPlayerId
    for _, tbPlayer in ipairs(tbWinerMembers) do
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_FFATeamResult, tbWinPacket)
    end

    if IsBotInTeam(tbWinerMembers) and GlobalVariableSystem.bEnableAIGameCore and GlobalVariableSystem.EnableDLAgent then
        EventManager:OnFireEvent(CommonEventDef.EV_BOT_TEAM_BATTLE_END, tbWinPacket)
    end

    if not IsBotTeam(tbWinerMembers) then
        self:SendTeamStatisticsDataToLobby(tbTeamdata, nWinerTeamId, nTeamRank, nMVPPlayerId, nPlayerCount, nTeamCount)
    end

    return true,nWinerTeamId
end

-- 给队伍中观战玩家发送队伍排名
local function SendBattleResultToViewers(self, tbGamePlayer, tbPacket)
    local tbTeamMembers = BattleTeamSystem:GetTeamMembersByPlayer(tbGamePlayer)
    for _, tbPlayer in ipairs(tbTeamMembers) do
        local nInstanceId = tbPlayer:GetServerInstanceId()
        local bPlayerBattleEnd  = self:IsPlayerBattleEnd(nInstanceId)
        if tbPlayer ~= tbGamePlayer and bPlayerBattleEnd then
            NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_FFATeamResult, tbPacket)
        end
    end
end

--玩家进入结算
--return (bGameOver,nWinerTeamId)
function BattleResultSystem:EnterPlayerResult(tbPlayer, nTeamModeId, nPlayerCount, nTeamCount, nPlayerRank, bSendResultToClient, bAdditionSuccess)
    local tbRet = GetTeamResultPacket(self,tbPlayer,nTeamModeId,nPlayerCount,nTeamCount,nPlayerRank)
    if bSendResultToClient then
        if bAdditionSuccess then
            NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_FFAKillBossResult, tbRet.tbPacket)
        else
            NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_FFATeamResult, tbRet.tbPacket)
        end
    end

    if tbRet.bTeamDead then
        local tbTeamMembers = BattleTeamSystem:GetTeamMembersByPlayer(tbPlayer)

        -- 队伍死亡给观战队友结算
        SendBattleResultToViewers(self, tbPlayer, tbRet.tbPacket)

        -- 统计组队数据
        if not IsBotTeam(tbTeamMembers) then
            self:SendTeamStatisticsDataToLobby(tbRet.tbTeamdata, tbRet.nTeamId, tbRet.nTeamRank, tbRet.nMVPPlayerId, nPlayerCount, nTeamCount)
        end

        -- 有队伍已经battleEnd
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_TEAM_BATTLE_END, tbRet.nTeamId, tbRet.nTeamRank)

        if IsBotInTeam(tbTeamMembers) and GlobalVariableSystem.bEnableAIGameCore and GlobalVariableSystem.EnableDLAgent then
            EventManager:OnFireEvent(CommonEventDef.EV_BOT_TEAM_BATTLE_END, tbRet.tbPacket)
        end
    end

    return TryCheckIsGameOver(self, nTeamModeId, nPlayerCount, nTeamCount)
end



function BattleResultSystem:CreateDeathPlaybackStaticsData(tbPlayer)
    local tbRet = {}
    tbRet.DeathPlaybacks = PlayerStatsHelper:CreateDeathPlaybackStaticsData(tbPlayer, DEATH_PLAYBACK_COUNT)
    return tbRet
end

return BattleResultSystem()