-- 在战斗中受到的hubserver的消息，返回大世界，结算消息等
local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local DungeonPacketProcessor_S = luaclass("DungeonPacketProcessor_S", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonProtoNames")
local DungeonLobbyProto = require("DungeonLobbyProtoNames")
local BattlePlayerPrepareInfoClass = require("BattlePlayerPrepareInfo")
local BattleBotPrepareInfoClass = require("BattleBotPrepareInfo")
local BattlePrepareSystem = require("BattlePrepareSystem")
local NetPlayerManager = require("NetPlayerManager_S")
local HubSenderManager = require("HubSenderManager_S")
local InitItemDataTable = require("InitItemDataTable")
local InitItemIni = require("InitItemIni")
local BaseUtil = require("BaseUtil")

local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local GameObjectSystem = dynamic_require("GameObjectSystem")

local ProtoDC = require("DungeonCommonProtoNames")
-- local BattleReviveModeTypeDef = require("BattleReviveModeTypeDef")
local BattleDataStatisticsSystem = dynamic_require("BattleDataStatisticsSystem")
local GlobalVariableSystem_S = require("GlobalVariableSystem_S")

-- 注册处理包
function DungeonPacketProcessor_S:RegisterPackets()
    self:BindMethod(Proto.s2d_GameSession, self, self.OnGameSession)
    self:BindMethod(Proto.s2d_PlayerPrepare, self, self.OnPlayerPrepare)
    -- self:BindMethod(Proto.s2d_ShowBattleResultAward, self, self.OnShowPVEBattleResultAward)
    -- self:BindMethod(Proto.s2d_ArenaShowAward, self, self.OnShowArenaBattleResultAward)
    self:BindMethod(Proto.s2d_KickPlayer, self, self.OnKickPlayer)
    -- self:BindMethod(Proto.s2d_RevivePlayer, self, self.OnRevivePlayer)
    -- self:BindMethod(Proto.s2d_BattlegroundShowAward, self, self.OnBattlegroundShowAward)
    -- self:BindMethod(Proto.s2d_ActivityDungeonShowAward, self, self.OnActivityDungeonShowAward)
    -- self:BindMethod(Proto.s2d_AssociationDungeonShowAward, self, self.OnAssociationDungeonShowAward)
    -- self:BindMethod(Proto.s2d_WorldbossShowAward, self, self.OnWorldbossShowAward)
    -- self:BindMethod(Proto.s2d_GuildbossShowAward, self, self.OnGuildbossShowAward)
    self:BindMethod(Proto.s2d_NotifyPlayerLeave,self,self.OnNotifyPlayerLeave)
    self:BindMethod(Proto.s2d_StopAcceptingNewPlayers,self,self.OnNotifyStopAcceptingNewPlayers)
end

-- 初始化
function DungeonPacketProcessor_S:Init()
    DungeonPacketProcessor_S.super.Init(self)
    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()
    return true
end

-- 结束
function DungeonPacketProcessor_S:Uninit()
    DungeonPacketProcessor_S.super.Uninit(self)
end

-- tbPacket : s2d_ArenaShowAward
function DungeonPacketProcessor_S:OnShowArenaBattleResultAward(tbPacket, nSocketId)
    -- 1、抛事件
    EventManager:OnFireEvent(CommonEventDef.EV_SHOW_PVP_BATTLE_RESULT_AWARD)
    -- 2、d2c发送给客户端 d2c_ShowArenaAward
    local d2c_ShowArenaAward = nil

    for k, player_award in pairs(tbPacket.player_awards) do
        -- tbPacket.player_id
        local GamePlayer = GameObjectSystem:FindPlayerByPlayerId(player_award.player_id)
        if GamePlayer ~= nil then
            d2c_ShowArenaAward = {}
            d2c_ShowArenaAward.result_type = player_award.result
            d2c_ShowArenaAward.delta_arena_point = player_award.delta_arena_point
            d2c_ShowArenaAward.awards = {}
            d2c_ShowArenaAward.enable_arena_point = tbPacket.enable_arena_point
            local tbAward = nil
            for _, award in pairs(player_award.awards) do
                tbAward = {}
                tbAward.g = award.g
                tbAward.d = award.d
                tbAward.p = award.p
                tbAward.count = award.count
                table.insert(d2c_ShowArenaAward.awards, tbAward)
            end
            BattleDataStatisticsSystem:SendFinishPlayerStatisticsToClient(player_award.player_id)
            NetworkManager:GetRPCNetworkProxy():SendToClient(GamePlayer:GetUEControllerUniqueId(),
                ProtoDC.d2c_ShowArenaAward , d2c_ShowArenaAward)
        else
            log("DungeonPacketProcessor_S:OnShowArenaBattleResultAward not send to player", player_award.player_id, ". Player not exist. ")
        end
    end
end

function DungeonPacketProcessor_S:OnKickPlayer(tbPacket, nSocketId)
    local nPlayerId = tbPacket.player_id
    local tbPlayer = GameObjectSystem:FindPlayerByPlayerId(nPlayerId)
    if tbPlayer then
        BattleGameModeSystem:KickPlayer(tbPlayer)
        -- if not ServerShell.GetServer(GWorld):KickPlayer(tbPlayer.pUEController) then
        --     logwarning("Kick player failed. PlayerId:", nPlayerId)
        -- end
    else
        logwarning("Kick player failed. Player not found.")
    end
end

-- tbPacket : s2d_ShowBattleResultAward
function DungeonPacketProcessor_S:OnShowPVEBattleResultAward(tbPacket, nSocketId)
    -- 1、抛事件
    EventManager:OnFireEvent(CommonEventDef.EV_SHOW_PVE_BATTLE_RESULT_AWARD)

    -- 2、d2c发送给客户端 d2c_ShowAward
    local d2c_ShowAward = nil
    for k, player_award in pairs(tbPacket.player_awards) do
        -- tbPacket.player_id
        local GamePlayer = GameObjectSystem:FindPlayerByPlayerId(player_award.player_id)
        if GamePlayer == nil then
            return
        end
        d2c_ShowAward = {}
        d2c_ShowAward.result_type = player_award.result_type
        d2c_ShowAward.awards = {}
        local tbAward = nil
        for _, award in pairs(player_award.awards) do
            tbAward = {}
            tbAward.g = award.g
            tbAward.d = award.d
            tbAward.p = award.p
            tbAward.count = award.count
            table.insert(d2c_ShowAward.awards, tbAward)
        end
        BattleDataStatisticsSystem:SendFinishPlayerStatisticsToClient(player_award.player_id)
        NetworkManager:GetRPCNetworkProxy():SendToClient(GamePlayer:GetUEControllerUniqueId(),
            ProtoDC.d2c_ShowAward , d2c_ShowAward)
    end
end

-- tbPacket : s2d_BattlegroundShowAward
function DungeonPacketProcessor_S:OnBattlegroundShowAward(tbPacket, nSocketId)
    -- 1、抛事件
    EventManager:OnFireEvent(CommonEventDef.EV_SHOW_PVE_BATTLE_RESULT_AWARD)

    -- 2、d2c发送给客户端 d2c_ShowBattlegroundAward
    local d2c_ShowBattlegroundAward = nil
    for k, player_award in pairs(tbPacket.player_awards) do
        -- tbPacket.player_id
        local GamePlayer = GameObjectSystem:FindPlayerByPlayerId(player_award.player_id)
        if GamePlayer == nil then
            return
        end
        d2c_ShowBattlegroundAward = {}
        d2c_ShowBattlegroundAward.result_type = player_award.result
        d2c_ShowBattlegroundAward.awards = {}
        d2c_ShowBattlegroundAward.daily_first_win_awards = {}
        local tbAward = nil
        for _, award in pairs(player_award.awards) do
            tbAward = {}
            tbAward.g = award.g
            tbAward.d = award.d
            tbAward.p = award.p
            tbAward.count = award.count
            table.insert(d2c_ShowBattlegroundAward.awards, tbAward)
        end
        local tbFirstWinAward = nil
        for _, firstWinAward in pairs(player_award.daily_first_win_awards) do
            tbFirstWinAward = {}
            tbFirstWinAward.g = firstWinAward.g
            tbFirstWinAward.d = firstWinAward.d
            tbFirstWinAward.p = firstWinAward.p
            tbFirstWinAward.count = firstWinAward.count
            table.insert(d2c_ShowBattlegroundAward.daily_first_win_awards, tbFirstWinAward)
        end

        BattleDataStatisticsSystem:SendFinishPlayerStatisticsToClient(player_award.player_id)
        NetworkManager:GetRPCNetworkProxy():SendToClient(GamePlayer:GetUEControllerUniqueId(),
            ProtoDC.d2c_ShowBattlegroundAward , d2c_ShowBattlegroundAward)
    end
end


-- tbPacket : s2d_ActivityDungeonShowAward
-- function DungeonPacketProcessor_S:OnActivityDungeonShowAward(tbPacket, nSocketId)
--     -- 1、抛事件
--     EventManager:OnFireEvent(CommonEventDef.EV_SHOW_PVE_BATTLE_RESULT_AWARD)

--     -- 2、d2c发送给客户端 d2c_ShowActivityDungeonAward
--     local d2c_ShowActivityDungeonAward = nil
--     for k, player_award in pairs(tbPacket.player_awards) do
--         local GamePlayer = GameObjectSystem:FindPlayerByPlayerId(player_award.player_id)
--         if GamePlayer == nil then
--             return
--         end
--         d2c_ShowActivityDungeonAward = {}
--         d2c_ShowActivityDungeonAward.result_type = player_award.result
--         d2c_ShowActivityDungeonAward.awards = {}
--         local tbAward = nil
--         for _, award in pairs(player_award.awards) do
--             tbAward = {}
--             tbAward.g = award.g
--             tbAward.d = award.d
--             tbAward.p = award.p
--             tbAward.count = award.count
--             table.insert(d2c_ShowActivityDungeonAward.awards, tbAward)
--         end
--         BattleDataStatisticsSystem:SendFinishPlayerStatisticsToClient(player_award.player_id)
--         NetworkManager:GetRPCNetworkProxy():SendToClient(GamePlayer:GetUEControllerUniqueId(),
--             ProtoDC.d2c_ShowActivityDungeonAward , d2c_ShowActivityDungeonAward)
--     end
-- end

-- tbPacket : s2d_AssociationDungeonShowAward
function DungeonPacketProcessor_S:OnAssociationDungeonShowAward(tbPacket, nSocketId)
    -- 1、抛事件
    EventManager:OnFireEvent(CommonEventDef.EV_SHOW_PVE_BATTLE_RESULT_AWARD)

    -- 2、d2c发送给客户端 d2c_ShowAssociationDungeonAward
    local d2c_ShowAssociationDungeonAward = nil
    for k, player_award in pairs(tbPacket.player_awards) do
        local GamePlayer = GameObjectSystem:FindPlayerByPlayerId(player_award.player_id)
        if GamePlayer == nil then
            return
        end
        d2c_ShowAssociationDungeonAward = {}
        d2c_ShowAssociationDungeonAward.result_type = player_award.result
        d2c_ShowAssociationDungeonAward.awards = {}
        local tbAward = nil
        for _, award in pairs(player_award.awards) do
            tbAward = {}
            tbAward.g = award.g
            tbAward.d = award.d
            tbAward.p = award.p
            tbAward.count = award.count
            table.insert(d2c_ShowAssociationDungeonAward.awards, tbAward)
        end
        BattleDataStatisticsSystem:SendFinishPlayerStatisticsToClient(player_award.player_id)
        NetworkManager:GetRPCNetworkProxy():SendToClient(GamePlayer:GetUEControllerUniqueId(),
            ProtoDC.d2c_ShowAssociationDungeonAward , d2c_ShowAssociationDungeonAward)
    end
end

-- tbPacket : s2d_WorldbossShowAward
function DungeonPacketProcessor_S:OnWorldbossShowAward(tbPacket, nSocketId)
    -- 1、抛事件
    EventManager:OnFireEvent(CommonEventDef.EV_SHOW_PVE_BATTLE_RESULT_AWARD)

    -- 2、d2c发送给客户端 d2c_ShowWorldbossAward
    local d2c_ShowWorldbossAward = nil
    for k, player_award in pairs(tbPacket.player_awards) do
        local GamePlayer = GameObjectSystem:FindPlayerByPlayerId(player_award.player_id)
        if GamePlayer == nil then
            return
        end
        d2c_ShowWorldbossAward = {}
        d2c_ShowWorldbossAward.result_type = player_award.result
        d2c_ShowWorldbossAward.awards = {}
        if player_award.awards then
            local tbAward = nil
            for _, award in pairs(player_award.awards) do
                tbAward = {}
                tbAward.g = award.g
                tbAward.d = award.d
                tbAward.p = award.p
                tbAward.count = award.count
                table.insert(d2c_ShowWorldbossAward.awards, tbAward)
            end
        end
        BattleDataStatisticsSystem:SendFinishPlayerStatisticsToClient(player_award.player_id)
        NetworkManager:GetRPCNetworkProxy():SendToClient(GamePlayer:GetUEControllerUniqueId(),
            ProtoDC.d2c_ShowWorldbossAward , d2c_ShowWorldbossAward)
    end
end

-- tbPacket : s2d_GuildbossShowAward
function DungeonPacketProcessor_S:OnGuildbossShowAward(tbPacket, nSocketId)
    -- 1、抛事件
    EventManager:OnFireEvent(CommonEventDef.EV_SHOW_PVE_BATTLE_RESULT_AWARD)

    -- 2、d2c发送给客户端 d2c_ShowGuildbossAward
    local d2c_ShowGuildbossAward = nil
    for k, player_award in pairs(tbPacket.player_awards) do
        local GamePlayer = GameObjectSystem:FindPlayerByPlayerId(player_award.player_id)
        if GamePlayer == nil then
            return
        end
        d2c_ShowGuildbossAward = {}
        d2c_ShowGuildbossAward.result_type = player_award.result
        d2c_ShowGuildbossAward.awards = {}
        if player_award.awards then
            local tbAward = nil
            for _, award in pairs(player_award.awards) do
                tbAward = {}
                tbAward.g = award.g
                tbAward.d = award.d
                tbAward.p = award.p
                tbAward.count = award.count
                table.insert(d2c_ShowGuildbossAward.awards, tbAward)
            end
        end
        BattleDataStatisticsSystem:SendFinishPlayerStatisticsToClient(player_award.player_id)
        NetworkManager:GetRPCNetworkProxy():SendToClient(GamePlayer:GetUEControllerUniqueId(),
            ProtoDC.d2c_ShowGuildbossAward , d2c_ShowGuildbossAward)
    end
end

function DungeonPacketProcessor_S:OnGameSession(tbPacket, nSocketId)
    local nEncryptionSeed = tbPacket.encrypt
    NetworkManager:GetRPCNetworkProxy():SetPacketEncryptionEnabled(nEncryptionSeed ~= nil and nEncryptionSeed ~= 0, nEncryptionSeed or 0)
    BattleGameModeSystem:SetDungeonSessionId(tbPacket.session_id)
    GlobalVariableSystem_S:SetStartTime(tbPacket.start_time)
    if tbPacket.revision_check_info ~= nil then
        local tbVersionInfo = {}
        for i, v in ipairs(tbPacket.revision_check_info) do
            tbVersionInfo[v.platform] = v.res_version
            log("set version ", v.platform, v.res_version)
        end
        GlobalVariableSystem_S:SetVersionInfo(tbVersionInfo)
    end

    EventManager:OnFireEvent(CommonEventDef.EV_GAME_SESSION_RECEIVED)
end

local function KickPlayer(nPlayerId)
    local tbPlayer = GameObjectSystem:FindPlayerByPlayerId(nPlayerId)
    if tbPlayer == nil then
        return
    end
    log("DungeonPacketProcessor_S KickPlayer", nPlayerId)
    BattleGameModeSystem:KickPlayer(tbPlayer)
end

function DungeonPacketProcessor_S:OnPlayerPrepare(tbPacket, nSocketId)
    local tbIds = {}
    local tbIndex = {}

    local nTeamModeId = BattleGameModeSystem:GetGameInitData().nTeamModeId

    for key, raw_player in ipairs(tbPacket.players) do
        local nToken = raw_player.token
        local nGroupIndex = raw_player.group_id
        local szPlayerSessionId = raw_player.player_session_id

        local bRet, Value = NetworkManager:GetHubServerProxy():Base64StringToMessage(DungeonLobbyProto.PlayerInfo, raw_player.info)
        if bRet then
            local player = msgtoluatable(Value)
            -- FOR DEBUG PURPOSE
            log("--- Preparing player data ---")
            BaseUtil:PrintTable(player)

            local nPlayerId = player.player_id
            KickPlayer(nPlayerId)

            NetPlayerManager:RegisterPlayer(nSocketId, nPlayerId)
            table.insert(tbIds, nPlayerId)

            local tbInfo = BattlePlayerPrepareInfoClass.Create(
                nPlayerId,
                player.name,
                player.human_id,
                nGroupIndex,
                nToken,
                szPlayerSessionId)

            tbInfo:SetLevel(player.level)
            tbInfo:SetAvatarId(player.avatar_id)
            tbInfo:SetAppearance(player.appearances)
            tbInfo:SetHumanFashion(player.fashions)
            tbInfo:SetHumanWeaponFashion(player.weapon_skins)
            tbInfo:SetDecoration(player.decoration)
            tbInfo:SetSailorIds(player.sailors) -- {1501101, 1501101, 1501101, 1501201, 1502101, 1502101}
            tbInfo:SetPartners(player.partners) -- {{partner_id=1610001, level=3},...}
            tbInfo:SetNoob(player.noob)
            tbInfo:SetLobbyTeamInfo(player.lobby_team_id, player.lobby_team_join_time)
            tbInfo:SetSeasons(player.seasons, nTeamModeId)
            tbInfo:SetAwardLimit(player.award_limited)
            tbInfo:AddShipPreparation(player.ships)
            tbInfo:AddShipPreparation(player.ship_weapons)
            tbInfo:AddShipPreparation(player.ship_parts)
            tbInfo:SetShipSkin(player.ship_skins)
            tbInfo:SetLandmark(player.landmarks)
            tbInfo:SetInitItems(InitItemDataTable:GetItems(InitItemIni.tbPrepareScene.nInitItemGroupId))      -- TODO:需替换成根据dungeonid来获得
            tbInfo:SetItemBuffs(player.buff_id)
            tbInfo:SetChannel(player.channel)
            tbInfo:SetMatchType(player.match_type)
            tbInfo:SetHumanFashionFlag(player.dry_fashion_flag)

            log("DungeonPacketProcessor_S:OnPlayerPrepare init formal items")

            -- 协会本用于标记第一个玩家为队长
            if tbIndex[nGroupIndex] == nil then
                tbIndex[nGroupIndex] = 0
            end
            tbIndex[nGroupIndex] = tbIndex[nGroupIndex] + 1
            tbInfo:SetIndex(tbIndex[nGroupIndex])

            BattlePrepareSystem:AddPlayerPrepareInfo(tbInfo)
        else
            logerror("DungeonPacketProcessor_S:OnPlayerPrepare player info decode failed. Token:", nToken, ". TeamId:", nGroupIndex, ". PlayerSessionId:", szPlayerSessionId)
        end
    end

    for key, bot in ipairs(tbPacket.bots) do
        local BattleBotPrepareInfo = BattleBotPrepareInfoClass()
        BattleBotPrepareInfo.nTemplateId = bot.template_id
        BattleBotPrepareInfo.szPlayerName = bot.name
        BattleBotPrepareInfo.nGroupIndex = bot.group_id
        BattleBotPrepareInfo.nPlayerId = bot.player_id
        BattlePrepareSystem:AddBotPrepareInfo(BattleBotPrepareInfo)
    end

    -- Maybe need to move sending resp logic to BattlePrepareSystem
    local d2s_PlayerReady =
    {
        rc = 0,
        player_ids = tbIds,
        id = tbPacket.id
    }
    HubSenderManager:SendbySocketId(Proto.d2s_PlayerReady, d2s_PlayerReady, nSocketId)

    EventManager:OnFireEvent(CommonEventDef.EV_ON_PLAYER_PREPARE, tbPacket, tbIds)
end

-- function DungeonPacketProcessor_S:OnRevivePlayer(tbPacket, nSocketId)
--     EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_REVIVE_RESULT, tbPacket.player_id, tbPacket.result, BattleReviveModeTypeDef.BackCityAndNow)
--     local tbPlayer = GameObjectSystem:FindPlayerByPlayerId(tbPacket.player_id)
--     if tbPlayer then
--         local tbreviveInfo = tbPlayer.tbPrepareInfo.tbReviveInfo
--         local reviveInfo = tbPacket.new_revive_info
--         tbreviveInfo.bCanRevive = reviveInfo.can_revive
--         tbreviveInfo.nReviveCostType = reviveInfo.revive_cost_type
--         tbreviveInfo.nReviveCostNum = reviveInfo.revive_cost_num
--     end

-- end

function DungeonPacketProcessor_S:OnNotifyPlayerLeave(tbPacket, nSocketId)
    log("Receive s2d_NotifyPlayerLeave")
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local nPlayerId = tbPacket.player_id
    local szPlayerSessionId = tbPacket.player_session_id
    local tbPlayer = GameObjectSystem:FindPlayerByPlayerId(nPlayerId)

    if tbGameMode ~= nil and tbPlayer ~= nil and tbPlayer.szPlayerSessionId == szPlayerSessionId then
        tbGameMode:NotifyPlayerLeave(tbPlayer)
    else
        logwarning("NotifyPlayerLeave failed. GameMode:", tbGameMode, "; Player:", tbPlayer)
        return
    end
end

function DungeonPacketProcessor_S:OnNotifyStopAcceptingNewPlayers(tbPacket, nSocketId)
    log("Receive s2d_StopAcceptingNewPlayers")
    EventManager:OnFireEvent(CommonEventDef.EV_NOTIFY_STOPACCEPTINGNEWPLAYERS)
end

return DungeonPacketProcessor_S
