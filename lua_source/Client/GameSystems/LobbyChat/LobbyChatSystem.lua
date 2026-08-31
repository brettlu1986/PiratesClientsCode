-----------------------------------------------------
--File Name    : LobbyChatSystem.lua
--Author       : Edward J
--Create Time  : 2019-04-01
--Description  : lobby Chat system
-----------------------------------------------------
local LobbyChatSystem   = {}

local Proto                         = require("ClientProtoNames")
local NetworkManager                = dynamic_require("NetworkManager")
local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
local FriendSystem                  = require("FriendSystem")
local SaveGameDef                   = require("SaveGameDef")
local StringUtil                    = require("StringUtil")
local dkjson                        = require("dkjson")
local GlobalVariableSystem          = require("GlobalVariableSystem_C")
local UITextDef                     = require("UITextDef")
local UIUtils                       = require("UIUtils")
local SelfEventHelper               = require("SelfEventHelper")
local ClientEventDef                = require("ClientEventDef")
local EventManager                  = require("EventManager")
local PlayerInfoSystem              = require("PlayerInfoSystem")
local L10N                          = require("L10N")
local SystemNotifactionDataTable    = require("SystemNotifactionDataTable")
local ItemDataTable                 = require("ItemDataTable")
local NotifyItemDataTable           = require("NotifyItemDataTable")
local ChatSystemHelper              = require("ChatSystemHelper")
local ChatIni                       = require("ChatIni")
local TeamIni                       = require("TeamIni")
local UISetUtils                    = require("UISetUtils")
-----------------------------------------------------
--系统频道常量
local GIFT_CATEGORY             = 13
local SAILOR_CATEGORY           = 15
local CARD_CATEGORY             = 21
--local STATIC_TEXT               = 3
-- local NORMAL_ITEM_NOTIFY_ID     = 1
-- local NORMAL_ITEM_REMOVE_NOTIFY_ID = 4
local HISTORY_MAX_COUNT         = ChatIni.tbConst.nHistoryMaxCount
local SHOW_TIMELINE_INTERVAL    = ChatIni.tbConst.nShowTimelineInterval
local ReturnCode                = Proto.ReturnCode
local LOBBY_MODE                = 1
local BATTLE_MODE               = 2
local EnterLobbyCount           = 0
local STRING_END_INDEX          = -4
local ErrorTab =
{
    [ReturnCode.CHAT_IN_COOLDOWN]       = UITextDef.CHAT_IN_COOLDOWN,
    [ReturnCode.CHAT_CONTENT_LENGTH]    = UITextDef.CHAT_CONTENT_LENGTH,
    [ReturnCode.CHAT_NO_TEAM]           = UITextDef.CHAt_NO_TEAM,
    [ReturnCode.CHAT_CHANNEL_INVALID]   = UITextDef.CHAT_CHANNEL_INVALID,
    [ReturnCode.CHAT_NO_ROOM]           = UITextDef.CHAT_NO_ROOM,
    [ReturnCode.CHAT_NO_FRIEND]         = UITextDef.CHAT_NO_FRIEND,
    [ReturnCode.CHAT_NOT_HAVE_CORPS]    = UITextDef.CHAT_NOT_HAVE_CORPS,
}

--暴露给其他模块用
LobbyChatSystem.EMsgType_Text           = 1
LobbyChatSystem.EMsgType_Voice          = 2
LobbyChatSystem.EMsgType_Teaming        = 3
LobbyChatSystem.CHAT_FRIEND             = Proto.ChatChannel.CHAT_FRIEND
LobbyChatSystem.CHAT_WORLD              = Proto.ChatChannel.CHAT_WORLD
LobbyChatSystem.CHAT_TEAM               = Proto.ChatChannel.CHAT_TEAM
LobbyChatSystem.CHAT_ROOM               = Proto.ChatChannel.CHAT_ROOM
LobbyChatSystem.CHAT_CORPS              = Proto.ChatChannel.CHAT_CORPS
LobbyChatSystem.CHAT_SYSTEM             = 5 --Proto.ChatChannel.SYSTEM
LobbyChatSystem.CHAT_TEAM_INVITE        = 6 --Proto.ChatChannel.CHAT_TEAM_INVITE
LobbyChatSystem.EXPRESSION_START_INDEX  = ChatSystemHelper.EXPRESSION_START_INDEX
LobbyChatSystem.EXPRESSION_END_INDEX    = ChatSystemHelper.EXPRESSION_END_INDEX
LobbyChatSystem.MAX_MSG_LENGTH          = ChatSystemHelper.MAX_MSG_LENGTH
LobbyChatSystem.FROM_FRIEND             = Proto.InviteFrom.FRIEND
LobbyChatSystem.FROM_CHAT               = Proto.InviteFrom.CHAT

LobbyChatSystem.SPLIT_SYMBOL            = "<br>"
LobbyChatSystem.INVALID_TEAM_ID         = -1
LobbyChatSystem.tbHistory               = nil
LobbyChatSystem.nPlayerSelfId           = nil
LobbyChatSystem.tbFriendList            = nil
LobbyChatSystem.pSaveGameMgr            = nil
LobbyChatSystem.ServerProxy             = nil
LobbyChatSystem.szPlayerSelfName        = nil
LobbyChatSystem.EventHelper             = nil
LobbyChatSystem.ECurrentMode            = nil
LobbyChatSystem.tbPlayerBaseInfo        = nil
LobbyChatSystem.PlayerSelf              = nil
LobbyChatSystem.pButtonList             = nil
LobbyChatSystem.nTimeStamp              = 0
LobbyChatSystem.tbChannelCooldown       = nil
LobbyChatSystem.NORMAL_ITEM             = 1
LobbyChatSystem.SPECIAL_ITEM            = 2
LobbyChatSystem.NOTIFY_TEXT             = 4
LobbyChatSystem.BIG_HORN                = 1
LobbyChatSystem.SMALL_HORN              = 2

LobbyChatSystem.NEWSYSTEMOPEN           = true
-----------------------------------------------------

local function RfreshFriendList(self)
    local FriendComponent = FriendSystem:GetComponent()
    local tbFriends = FriendComponent:GetFriends()
    self.tbFriendList = nil
    self.tbFriendList = tbFriends
end

local function VerifyHistoryTab(self, eChannel)
    local tbHistory = self.tbHistory
    if not tbHistory[eChannel] then
        tbHistory[eChannel] = {}
    end
    return tbHistory[eChannel]
end

local function GetPlayerSelfName(self)
    assert(self.PlayerSelf)
    return self.PlayerSelf:GetName()
end

local function CaculateFriendShowTimeLine(self, tbOneFriendHistory, tbTable)
    local nCount = tbOneFriendHistory == nil and 0 or #tbOneFriendHistory
    if nCount == 0 then
        tbTable.NeedTimeLine = true
        return
    end
    local tbTemp = tbOneFriendHistory[nCount]
    local nLastTime = tbTemp.nTime
    local nTime = tbTable.nTime
    tbTable.NeedTimeLine = ((nTime - nLastTime) >= SHOW_TIMELINE_INTERVAL) and true or false
end

local function AddToFriendHistory(self, tbHistory, tbArgs, nFriendId)
    if not tbHistory[nFriendId] then
        tbHistory[nFriendId] = {}
    end
    ChatSystemHelper.AddValueWithLimit(tbHistory[nFriendId], tbArgs, HISTORY_MAX_COUNT)
end

local function CreateHistoryDataTable(self, eChannel, nSenderId, szName, szContent, nTime, nFlags, bNewMsg, tbParams)
    local tbTemp = {}
    tbTemp.eChannel = eChannel
    tbTemp.nSenderId = nSenderId
    local nPlayerSelfId = self.nPlayerSelfId
    tbTemp.bSelf = (nSenderId == nPlayerSelfId) and true or false
    tbTemp.szName = szName
    szContent = ChatSystemHelper.ParseExpressionSymbol(szContent)
    tbTemp.szContent = szContent
    tbTemp.nTime = (nTime == 0) and GlobalVariableSystem:GetServerTimeUtc() or nTime
    tbTemp.nFlags = nFlags
    if eChannel == self.CHAT_FRIEND then
        if bNewMsg ~=nil then
            tbTemp.bNewMsg = bNewMsg
        else
            tbTemp.bNewMsg = true
            if tbTemp.bSelf then
                tbTemp.bNewMsg = false
            end
        end
    end
    
    if eChannel == self.CHAT_TEAM_INVITE then
        tbTemp.tbChannel = tbParams.tbChannel
        tbTemp.nTeamMode = tbParams.nTeamMode
    end

    return tbTemp
end

local function OnClearTeamMembers(self)
    self.tbHistory[self.CHAT_TEAM] = {}
end

local function InitChannelCooldown(self, eChannel, nCooldown)
    if not self.tbChannelCooldown then
        return
    end
    local tbTemp = {}
    tbTemp.nCDTime = nCooldown
    tbTemp.nTimeStamp = 0
    self.tbChannelCooldown[eChannel] = tbTemp
end

local function SetChannelCooldownStamp(self, eChannel, nTimeStamp)
    if not self.tbChannelCooldown then
        return
    end
    local tbTemp = self.tbChannelCooldown[eChannel]
    if not tbTemp then
        return
    end

    tbTemp.nTimeStamp = nTimeStamp
end

local function PlayerSummaryToPlayerBasicInfo(tbSummary)
    local tbBasicInfo = {}
    tbBasicInfo.nAvatarId = tbSummary.avatar_id
    tbBasicInfo.szName = tbSummary.name
    tbBasicInfo.nPlayerId = tbSummary.id
    tbBasicInfo.nLevel = tbSummary.level
    tbBasicInfo.nExp = tbSummary.exp
    tbBasicInfo.nRank = tbSummary.rank
    tbBasicInfo.nTeamSize = tbSummary.team_size
    return tbBasicInfo
end

function LobbyChatSystem:GetPlayerBaseInfoFromCache(nPlayerId)
    local tbPlayerBaseInfo = self.tbPlayerBaseInfo
    assert(tbPlayerBaseInfo)
    for k, baseInfo in pairs(tbPlayerBaseInfo) do
        if nPlayerId == baseInfo.nPlayerId then
            return baseInfo
        end
    end
    return nil
end

function LobbyChatSystem:AddPlayerBaseInfo(tbSummaries)
    log("[LobbyChatSystem] AddPlayerBaseInfo")
    local tbPlayerBaseInfo = self.tbPlayerBaseInfo
    assert(tbPlayerBaseInfo)
    assert(tbSummaries)
    for _, tbSummary in ipairs(tbSummaries) do
        local nId = tbSummary.id
        if not nId then
            return
        end
        log("[LobbyChatSystem] AddPlayerBaseInfo Ready To Fire")
        local tbCache = self:GetPlayerBaseInfoFromCache(nId)
        local tbBaseInfo = PlayerSummaryToPlayerBasicInfo(tbSummary)
        if tbCache then
            tbCache = tbBaseInfo
        else
            ChatSystemHelper.AddValueWithLimit(tbPlayerBaseInfo, tbBaseInfo, HISTORY_MAX_COUNT)
        end
        EventManager:OnFireEvent(ClientEventDef.EV_REFRESH_PLAYER_BASEINFO, tbBaseInfo)
    end
end

function LobbyChatSystem:GetPlayerBaseInfo(nPlayerId)
    local tbPlayerBaseInfo = self.tbPlayerBaseInfo
    assert(tbPlayerBaseInfo)
    local tbCache = self:GetPlayerBaseInfoFromCache(nPlayerId)
    if tbCache then
        return tbCache
    end
    local tbPlayerIdList = {}
    table.insert(tbPlayerIdList, nPlayerId)
    local tbHasSystemCache, __ = PlayerInfoSystem:HasPlayerSummaries(tbPlayerIdList)
    if #tbHasSystemCache ~= 0 then --由于聊天系统的特殊性，每次只取一个id的信息，所以只要tbHasSystemCache没有数据，就说明需要重新取
        local tbPlayerSystemCache = PlayerInfoSystem:GetPlayerSummariesFromLocal(tbPlayerIdList)
        return tbPlayerSystemCache[1]
    end
    PlayerInfoSystem:RequestPlayerSummariesFromServer(tbPlayerIdList)
    return nil
end

function LobbyChatSystem:GetPlayerBaseInfoFromServer(nPlayerId)
    local tbPlayerIdList = {}
    table.insert(tbPlayerIdList, nPlayerId)
    PlayerInfoSystem:RequestPlayerSummariesFromServer(tbPlayerIdList)
end

function LobbyChatSystem:SaveFriendHistory()
    --防止在未进入大厅时退出 此事没有gameplayer
    if not self.ECurrentMode then
        return
    end
    local tbHistory = VerifyHistoryTab(self, self.CHAT_FRIEND)
    local nPlayerSelfId = self.nPlayerSelfId
    local tbSaveHistory =
    {
        nPlayerId = nPlayerSelfId,
        tbHistory = tbHistory,
    }
    local szHistory = dkjson.encode(tbSaveHistory)
    self.pSaveGameMgr:AddStringData(SaveGameDef.FRIEND_CHAT, szHistory)
    self.pSaveGameMgr:Save()
end

function LobbyChatSystem:RecoverFriendHistory()
    local szSavedData = self.pSaveGameMgr:GetStringData(SaveGameDef.FRIEND_CHAT)
    if StringUtil.IsEmptyString(szSavedData) then
        return
    end
    local tbSaveData = dkjson.decode(szSavedData)
    local nPlayerSelfId = self.nPlayerSelfId
    if tonumber(tbSaveData.nPlayerId) ~= nPlayerSelfId then
        return
    end
    local tbHistory = tbSaveData.tbHistory
    local nPlayerId, szPlayerName, szContent, nTime, nOverrideId, bNewMsg
    for id, friend in pairs(tbHistory) do
        for i, item in ipairs(friend) do
            nPlayerId = tonumber(item.nSenderId)
            szPlayerName = item.szName
            szContent = item.szContent
            nTime = tonumber(item.nTime)
            nOverrideId = (nPlayerId == nPlayerSelfId) and tonumber(id) or nil
            bNewMsg = item.bNewMsg
            self:OnRecieveMsg(self.CHAT_FRIEND, nPlayerId, szPlayerName, szContent, nTime, nil, nOverrideId, bNewMsg)
        end
    end
end

function LobbyChatSystem:GetHistory(eChannel)
    return VerifyHistoryTab(self, eChannel)
end

function LobbyChatSystem:GetFriendHistoryById(nFriendId)
    local tbHistory = VerifyHistoryTab(self, self.CHAT_FRIEND)
    return tbHistory[nFriendId] and tbHistory[nFriendId] or nil
end

function LobbyChatSystem:GetUnreadMsgFriendCount()
    local tbHistory = VerifyHistoryTab(self, self.CHAT_FRIEND)
    local nCount = 0
    for k, tbFriendData in pairs(tbHistory) do
        local nNewMsgCount = 0
        for index, tbMsgData in ipairs(tbFriendData) do
            if tbMsgData.bNewMsg then
                nNewMsgCount = nNewMsgCount + 1
                break
            end
        end
        if nNewMsgCount > 0 then
            nCount = nCount + 1
        end
    end
    return nCount
end

function LobbyChatSystem:GetUnreadMsgFriendById(nFriendId)
    local tbHistory = VerifyHistoryTab(self, self.CHAT_FRIEND)
    local tbFriendData = tbHistory[nFriendId]
    local nCount = 0
    if not tbFriendData then
        return nCount
    end
    for index, tbMsgData in ipairs(tbFriendData) do
        if tbMsgData.bNewMsg then
            nCount = nCount + 1
        end
    end
    return nCount
end

function LobbyChatSystem:IsFriendMsgUnread(nFriendId)
    local tbHistory = VerifyHistoryTab(self, self.CHAT_FRIEND)
    local tbFriendData = tbHistory[nFriendId]
    if not tbFriendData then
        return false
    end
    for index, tbMsgData in ipairs(tbFriendData) do
        if tbMsgData.bNewMsg then
            return true
        end
    end
    return false
end

function LobbyChatSystem:ResetFriendUnreadMsg(nFriendId)
    if not self:IsFriendMsgUnread(nFriendId) then
        return
    end
    local tbFriendHistory = self:GetFriendHistoryById(nFriendId)
    if tbFriendHistory then
        for index, tbMsgData in ipairs(tbFriendHistory) do
            if tbMsgData.bNewMsg then
                -- logdebug("===================ResetFriendUnreadMsg Index===================" .. index)
                tbMsgData.bNewMsg = false
            end
        end
    end
end

function LobbyChatSystem:GetFriendList()
    return self.tbFriendList
end

function LobbyChatSystem:PackTextMsg(szMsg)
    return self:PackMsgWithSymbol(self.SPLIT_SYMBOL, self.EMsgType_Text, szMsg)
end

function LobbyChatSystem:PackVoiceMsg(szMsg, szUrl)
    return self:PackMsgWithSymbol(self.SPLIT_SYMBOL, self.EMsgType_Voice, szMsg, szUrl)
end

function LobbyChatSystem:PackTeamMsg(szMsg, nToatalCount, nCurrentCount, nPlayerId, nTeamId)
    return self:PackMsgWithSymbol(self.SPLIT_SYMBOL, self.EMsgType_Teaming, szMsg, nToatalCount, nCurrentCount, nPlayerId, nTeamId)
end

function LobbyChatSystem:PackMsgWithSymbol(szSplitSymbol, ...)
    local tbArg = { ... }
    local szContent = ""
    for i,v in ipairs(tbArg) do
        szContent = string.format("%s%s%s", szContent, tostring(v), szSplitSymbol)
    end
    local nSunIndex = -(string.len(szSplitSymbol) + 1)
    szContent = string.sub(szContent, 1, nSunIndex)
    return szContent
end

function LobbyChatSystem:CreateSystemItemsTab(tbItems, nItemId, nCount)
    tbItems = (not tbItems) and {} or tbItems
    local szItemId = tostring(nItemId)
    tbItems[szItemId] = nCount
end

function LobbyChatSystem:SetSystemContent(nType, nLoopCount, nInterval, nPriority, content, szPlayerName)
    local tbTemp = {}
    tbTemp.nType = nType
    tbTemp.nLoopCount = nLoopCount
    tbTemp.nInterval = nInterval
    tbTemp.nPriority = nPriority
    if nType == self.NOTIFY_TEXT then
        tbTemp.notify_text = content
    else
        tbTemp.system_channel_item = content
        tbTemp.player_name = szPlayerName
    end
    local szSystemContent = dkjson.encode(tbTemp)
    return szSystemContent
end

local function GetItemsText(tbItems)
    local szItems = ""
    if not tbItems then
        return szItems
    end
    for szId, nCount in pairs(tbItems) do
        local nId = tonumber(szId)
        local tbItemTemplate = ItemDataTable:GetTemplate(nId)
        if not tbItemTemplate then
            break
        end
        local szItemName = L10N:ToString(tbItemTemplate.l10nName)
        if nCount then
            szItemName = szItemName .. "*" .. nCount
        end
        local nGrade = tbItemTemplate.nGrade
        local l10nGradeColorText = UITextDef.ITEM_GRADE_COLOR_TEXT[nGrade]
        if l10nGradeColorText then
            local l10nItemName = L10N:Format(UITextDef.CHAT_MESSAGE_ITEM_GRADE_FORMAT, l10nGradeColorText, szItemName)
            szItemName = L10N:ToString(l10nItemName)
        end
        szItems = szItems .. szItemName .. "、"
    end
    szItems = string.sub(szItems, 1, STRING_END_INDEX)
    return szItems
end

local function GetNotifyTemplate(self, nType)
    local tbTemplate = nil
    if nType == self.SPECIAL_ITEM then
        tbTemplate = SystemNotifactionDataTable:GetTemplate(2)
    elseif nType == self.NORMAL_ITEM then
        tbTemplate = SystemNotifactionDataTable:GetTemplate(1)
    elseif nType == self.NOTIFY_TEXT then
        tbTemplate = SystemNotifactionDataTable:GetTemplate(1)
    end
    return tbTemplate
end

function LobbyChatSystem:GetSystemContentText(szContent)
    local tbData = dkjson.decode(szContent)
    if type(tbData) ~= "table" then
        return nil
    end
    local nType = tonumber(tbData.nType)
    local tbTemplate = GetNotifyTemplate(self, nType)
    if not tbTemplate then
        return
    end
    local szMsg = L10N:ToString(tbTemplate.l10nMsg)
    if nType == self.SPECIAL_ITEM then
        local szPlayerName = tbData.player_name
        local szItems = GetItemsText(tbData.system_channel_item)
        szMsg = string.format(szMsg, szPlayerName, szItems)
    elseif nType == self.NORMAL_ITEM then
        local szItems = GetItemsText(tbData.system_channel_item)
        szMsg = string.format(szMsg, szItems)
    elseif nType == self.NOTIFY_TEXT then
        szMsg = tbData.notify_text
    end
    return szMsg
end

function LobbyChatSystem:OnAwardNotification(tbAwardDatas)
    if not tbAwardDatas then
        logerror("LobbyChatSystem OnAwardNotification tbAwardDatas is nil")
        return
    end
    local tbItems = {}
    for _, tbAddedItemDatas in ipairs(tbAwardDatas) do
        for _, v in ipairs(tbAddedItemDatas.tbAwardDatas) do
            local nItemTemplateId = v.nItemTemplateId
            local nCount = v.nCount
            if NotifyItemDataTable:IsContain(nItemTemplateId) then
                return
            end
            self:CreateSystemItemsTab(tbItems, nItemTemplateId, nCount)
        end
    end
    self:SendToSystem(self.NORMAL_ITEM, 0, 0, 0, tbItems)
end

function LobbyChatSystem:CheckRemoveItemCanNotify(nItemTemplateId)
    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    if not tbItemTemplate then
        return false
    end
    local nItemCategory = tbItemTemplate.nCategory
    if nItemCategory == GIFT_CATEGORY
    or nItemCategory == CARD_CATEGORY
    or nItemCategory == SAILOR_CATEGORY then
        return false
    end
    return true
end

function LobbyChatSystem:OnRemoveItem(nItemTemplateId)
    if not self:CheckRemoveItemCanNotify(nItemTemplateId) then
        return
    end
    local tbItems = {}
    self:CreateSystemItemsTab(tbItems, nItemTemplateId, 1)
    self:SendToSystem(self.NORMAL_ITEM, 0, 0, 0, tbItems)
end


function LobbyChatSystem:SendToSystem(nType, nLoopCount, nInterval, nPriority, Content, szPlayerName)
    local szContent = self:SetSystemContent(nType, nLoopCount, nInterval, nPriority, Content, szPlayerName)
    self:OnRecieveMsg(self.CHAT_SYSTEM, nil, nil ,szContent ,nil, nil, nil)
end

function LobbyChatSystem:UnpackContent(szContent)
    local tbContent = StringUtil.Split(szContent, self.SPLIT_SYMBOL)
    return tbContent
end

local function CheckCDTime(self, eChannel)
    if not self.tbChannelCooldown then
        return
    end
    local tbChannelCooldown = self.tbChannelCooldown[eChannel]
    local nCurrentStamp = GlobalVariableSystem:GetServerTimeUtc()
    local nPassedTime = nCurrentStamp - tbChannelCooldown.nTimeStamp
    local nRemainTime = tbChannelCooldown.nCDTime - nPassedTime
    if nRemainTime <= 0 then
        return true
    else
        UIUtils.ShowToast(L10N:Format(UITextDef.CHAT_TIME_REMINE, nRemainTime))
        return false
    end
end

function LobbyChatSystem:SendToTeamInvite(eChannel, tbEChannel, nDungeonId, nTeamMode)
    if eChannel ~= self.CHAT_TEAM_INVITE then
        return false
    end
    if not CheckCDTime(self, eChannel) then
        return
    end
    local tbPacket = {}
    tbPacket.channel = tbEChannel
    tbPacket.dungeon_id = nDungeonId
    tbPacket.team_mode = nTeamMode
    self.ServerProxy:SendPacket(Proto.c2s_RecruitTeammate, tbPacket)
end

function LobbyChatSystem:SendMsg(eChannel, szContent, nRecipientId)
    if eChannel < self.CHAT_FRIEND or eChannel > self.CHAT_TEAM_INVITE then
        return false
    end

    if not CheckCDTime(self, eChannel) then
        return
    end
    szContent = ChatSystemHelper.CheckMsgSensitiveWords(szContent)
    local tbPacket = {}
    tbPacket.channel = eChannel
    tbPacket.content = szContent
    tbPacket.recipient_id = nRecipientId
    self.ServerProxy:SendPacket(Proto.c2s_Chat, tbPacket)
    if eChannel == self.CHAT_FRIEND then
        local nTime = GlobalVariableSystem:GetServerTimeUtc()
        local szPlayerSelfName = GetPlayerSelfName(self)
        local nPlayerSelfId = self.nPlayerSelfId
        --由于一对一消息不会回发，即我发个朋友的信息不会回发给我自己
        --所以当我自己给好友发消息时，用自己的数据模拟一下收包，并且
        --我的发给某个好友的消息应该存在于以这个好友id为key的数组中
        --所以添加了一个overrideSenderId用于标明中个消息应该存储的位置
        self:OnRecieveMsg(eChannel, nPlayerSelfId, szPlayerSelfName, szContent, nTime, nil, nRecipientId)
    end
    return true
end

function LobbyChatSystem:GetMsgType(szContent)
    local tbContent = self:UnpackContent(szContent)
    local eMsgType = tonumber(tbContent[1])
    return eMsgType
end

function LobbyChatSystem:OnRecieveTeamInvite(nSenderId, szName, nMember, tbChannel, nDungeonId, nTeamMode)
    local DefaultTeamMode = 4
    local szContent = LobbyChatSystem:PackTeamMsg("", nTeamMode and nTeamMode or DefaultTeamMode, nMember, nSenderId, -1)
    local tbParams = {}
    tbParams.tbChannel = tbChannel
    tbParams.nTeamMode = nTeamMode
    szName = not szName and "" or szName
    if GlobalVariableSystem.bEnterLobby3D then
        self:OnRecieveMsg(self.CHAT_TEAM_INVITE, nSenderId, szName, szContent, 0, nil, nil, nil, tbParams)
    else
        self:OnRecieveMsg(self.CHAT_WORLD, nSenderId, szName, szContent, 0, nil, nil, nil, tbParams)
    end
end

function LobbyChatSystem:IsLatest(nSenderId, nTime)
    local tbHistory = VerifyHistoryTab(self, self.CHAT_TEAM_INVITE)
    for i,v in ipairs(tbHistory) do
        local eMsgType = self:GetMsgType(v.szContent)
        if eMsgType == self.EMsgType_Teaming then
            if nSenderId == v.nSenderId then
                if nTime < v.nTime then
                    return false
                end
            end    
        end
    end
    return true
end

function LobbyChatSystem:OnRecieveMsg(eChannel, nSenderId, szName, szContent, nTime, nFlags, overrideSenderId, bNewMsg, tbParams)
    if eChannel < self.CHAT_FRIEND or eChannel > self.CHAT_TEAM_INVITE then
        return
    end
    if nSenderId == self.nPlayerSelfId and nFlags ~= self.BIG_HORN and nFlags ~= self.SMALL_HORN then
        local eTempChannel = eChannel
        --由于没有一个单独的组队频道，所以当组队频道的消息返回时，
        --要解析一下消息的类型，如果是组队消息，那么需要重置一下
        --组队频道的时间戳
        local eMsgType = self:GetMsgType(szContent)
        if eMsgType == self.EMsgType_Teaming then
            eTempChannel = self.CHAT_TEAM_INVITE
            nTime = 0
        end
        local nTimeStamp = GlobalVariableSystem:GetServerTimeUtc()
        SetChannelCooldownStamp(self, eTempChannel, nTimeStamp)
    end
    local eCurrentMode = self.ECurrentMode
    local tbTemp = CreateHistoryDataTable(self, eChannel, nSenderId, szName, szContent, nTime, nFlags, bNewMsg, tbParams)
    local tbHistory = VerifyHistoryTab(self, eChannel)
    if nFlags and nFlags == self.BIG_HORN then
        UIUtils.ShowTopMsgNotifaction(tbTemp)
    end
    if eChannel ~= self.CHAT_FRIEND and eCurrentMode == LOBBY_MODE then
        ChatSystemHelper.AddValueWithLimit(tbHistory, tbTemp, HISTORY_MAX_COUNT)
        if eChannel == self.CHAT_SYSTEM then
            UIUtils.ShowSystemNotifaction(szContent)
        end
    elseif eChannel == self.CHAT_FRIEND and (eCurrentMode == LOBBY_MODE or eCurrentMode == BATTLE_MODE) then
        local friendIdKey = overrideSenderId == nil and nSenderId or overrideSenderId
        local tbOneFriendHistory = self:GetFriendHistoryById(friendIdKey)
        CaculateFriendShowTimeLine(self, tbOneFriendHistory, tbTemp)
        AddToFriendHistory(self, tbHistory, tbTemp, friendIdKey)
        if eCurrentMode == BATTLE_MODE then
            EventManager:OnFireEvent(ClientEventDef.EV_CHAT_TO_BATTLE_FRIEND, nSenderId, szName, szContent)
        end
    end
    if eCurrentMode == BATTLE_MODE then
        return
    end
    -- 通知UI
    local bFriendRecord = bNewMsg ~= nil
    EventManager:OnFireEvent(ClientEventDef.EV_RECEIVE_CHAT_MESSAGE, eChannel, tbTemp, bFriendRecord)
end

function LobbyChatSystem:OnRecieveErrorCode(eReturnCode, eChatChannel, nRemainTime)
    log("Recieve Chat Error Code", eReturnCode)
    local l10nToast = ErrorTab[eReturnCode]
    if eReturnCode == ReturnCode.CHAT_IN_COOLDOWN then
        local tbChannelCooldown = self.tbChannelCooldown[eChatChannel]
        local nCurrentStamp = GlobalVariableSystem:GetServerTimeUtc()
        local nPassedTime = nCurrentStamp - tbChannelCooldown.nTimeStamp
        local nlocalRemainTime = tbChannelCooldown.nCDTime - nPassedTime
        local nTime = nlocalRemainTime <= 0 and nRemainTime or nlocalRemainTime
        UIUtils.ShowToast(L10N:Format(UITextDef.CHAT_TIME_REMINE, nTime))
    else
        if l10nToast then
            UIUtils.ShowToast(l10nToast)
        end
    end
    EventManager:OnFireEvent(ClientEventDef.EV_CHAT_SEND_FAILED)
end

function LobbyChatSystem:OnRecieveBanChat(nSinceStamp, nUntilStamp, szReason)
    -- local szSinceTime = ""
    local szUntilTime = ""
    if nSinceStamp and nUntilStamp then
        -- szSinceTime = os.date("%Y-%m-%d %H:%M:%S",nSinceStamp)
        szUntilTime = os.date("%Y-%m-%d %H:%M:%S",nUntilStamp)
    end
    local l10ninfo = L10N:Format(UISetUtils.GetL10NTextByKey("CHAT_BANNED_INFO"), szReason, szUntilTime)
    UIUtils.ShowToast(l10ninfo)
end

function LobbyChatSystem:OnRecieveUnbanChat()
    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("CHAT_UNBANNED_INFO"))
end

function LobbyChatSystem:Init()
    self.tbHistory = {}
    self.tbPlayerBaseInfo = {}
    self.tbChannelCooldown = {}
    self.pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    self.ServerProxy = NetworkManager:GetHubServerProxy()
    self:BindEvent()
    local tbCooldown = ChatIni.tbCoolDown
    local nInviteCoolDown = TeamIni.nTeamRecruitCoolDown
    InitChannelCooldown(self, self.CHAT_WORLD, tbCooldown.nWorld)
    InitChannelCooldown(self, self.CHAT_FRIEND, tbCooldown.nFriend)
    InitChannelCooldown(self, self.CHAT_ROOM, tbCooldown.nRoom)
    InitChannelCooldown(self, self.CHAT_TEAM, tbCooldown.nTeam)
    InitChannelCooldown(self, self.CHAT_CORPS, tbCooldown.nCorp)
    InitChannelCooldown(self, self.CHAT_TEAM_INVITE, nInviteCoolDown)
    return true
end

function LobbyChatSystem:Uninit()
    self:SaveFriendHistory()
    self.pSaveGameMgr = nil
    self.ServerProxy = nil
    self.tbHistory = nil
    self:UnbindEvent()
end

function LobbyChatSystem:ResetHistory()
    self.tbHistory[self.CHAT_TEAM] = {}
    self.tbHistory[self.CHAT_WORLD] = {}
    self.tbHistory[self.CHAT_ROOM] = {}
    self.tbHistory[self.CHAT_CORPS] = {}
    self.tbHistory[self.CHAT_SYSTEM] = {}
end

function LobbyChatSystem:OnEnterLobby()
    EnterLobbyCount = EnterLobbyCount + 1
    self.ECurrentMode = LOBBY_MODE
    if not self.PlayerSelf then
        self.PlayerSelf = GamePlayerSelfHelper:Get()
        self.nPlayerSelfId = self.PlayerSelf.nPlayerId
    end
    --只有在首次进入到lobby时才需要恢复好友聊天数据
    --因为好友消息在离开lobby后是不会清除的
    if EnterLobbyCount == 1 then
        self:RecoverFriendHistory()
    end
end

function LobbyChatSystem:OnUILogin()
    self.PlayerSelf = nil
    EnterLobbyCount = 0
end

function LobbyChatSystem:OnLeaveLobby()
    self.ECurrentMode = nil
    self:SaveFriendHistory()
    self:ResetHistory()
end

function LobbyChatSystem:OnEnterBattle()
    self.ECurrentMode = BATTLE_MODE

end

function LobbyChatSystem:OnLeaveBattle()
    self.ECurrentMode = nil
end

function LobbyChatSystem:BindEvent()
    self.EventHelper = SelfEventHelper()
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_APPLY_FRIEND_STATE,  self, RfreshFriendList)
    EventHelper:RegisterEvent(ClientEventDef.EV_FRESH_FRIEND_STATE,  self, RfreshFriendList)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_SUMMARIES_RECEIVED,  self, self.AddPlayerBaseInfo)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_READY,  self, self.OnEnterLobby)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_LOBBY,  self, self.OnLeaveLobby)
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE,  self, self.OnEnterBattle)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE,  self, self.OnEnterBattle)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_CLEAR_MEMBERS,  self, OnClearTeamMembers)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_LOGIN, self, self.OnUILogin)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHAT_RESET_FRIEND_UREAD_STATE, self, self.ResetFriendUnreadMsg)
end

function LobbyChatSystem:UnbindEvent()
    local EventHelper = self.EventHelper
    EventHelper:UnregisterEvent(ClientEventDef.EV_APPLY_FRIEND_STATE,  self, RfreshFriendList)
    EventHelper:UnregisterEvent(ClientEventDef.EV_FRESH_FRIEND_STATE,  self, RfreshFriendList)
    EventHelper:UnregisterEvent(ClientEventDef.EV_PLAYER_SUMMARIES_RECEIVED, self, self.AddPlayerBaseInfo)
    EventHelper:UnregisterEvent(ClientEventDef.EV_LOBBY_READY,  self, self.OnEnterLobby)
    EventHelper:UnregisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_LOBBY,  self, self.OnLeaveLobby)
    EventHelper:UnregisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE,  self, self.OnEnterBattle)
    EventHelper:UnregisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE,  self, self.OnEnterBattle)
    EventHelper:UnregisterEvent(ClientEventDef.EV_TEAM_CLEAR_MEMBERS,  self, OnClearTeamMembers)
    EventHelper:UnregisterEvent(ClientEventDef.EV_UI_LOGIN, self, self.OnUILogin)
    EventHelper:UnregisterEvent(ClientEventDef.EV_CHAT_RESET_FRIEND_UREAD_STATE, self, self.ResetFriendUnreadMsg)
    self.EventHelper = nil
end


return LobbyChatSystem