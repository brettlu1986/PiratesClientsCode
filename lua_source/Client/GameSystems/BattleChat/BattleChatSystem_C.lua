-----------------------------------------------------
--File Name    : BattleChatSystem_S.lua
--Author       : Edward J
--Create Time  : 2019-03-19
--Description  : Chat system client
-----------------------------------------------------
local luaclass           = require("luaclass")
local BattleChatSystem   = require("BattleChatSystem")
local BattleChatSystem_C = luaclass("BattleChatSystem_C", BattleChatSystem)

local L10N                  = require("L10N")
local CommonEventDef        = require("CommonEventDef")
local EventManager          = require("EventManager")
local NetworkManager        = dynamic_require("NetworkManager")
local ProtoD                = require("DungeonCommonProtoNames")
local Proto                 = require("ClientProtoNames")
local ChatSystemHelper      = require("ChatSystemHelper")
local UIUtils               = require("UIUtils")
local UITextDef             = require("UITextDef")
local StringUtil            = require("StringUtil")
local LobbyChatSystem       = require("LobbyChatSystem")
local ClientEventDef        = require("ClientEventDef")
local SelfEventHelper       = require("SelfEventHelper")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local GVoiceSDKSystem       = require("GVoiceSDKSystem")
local SoundManager          = require("SoundManager")
local GVoiceOpCtrlHelper    = require("GVoiceOpCtrlHelper")
local FriendSystem          = require("FriendSystem")
local PointTipsHelper       = require("PointTipsHelper")
-----------------------------------------------------
local MAX_SELF_HISTORY_COUNT    = 50
local MAX_TEAM_HISTORY_COUNT    = 50
local MAX_FRIEND_HISTORY_COUNT  = 50
local eCheckResult              = ChatSystemHelper.eCheckResult
-- local pSaveGameMgr              = ClientShell.GetClient(GWorld):GetSaveGameManager()

BattleChatSystem_C.FRIEND_HISTORY_TAG   = "<br>"
BattleChatSystem_C.EFriendHistory_Other = 0
BattleChatSystem_C.EFriendHistory_Mine  = 1
BattleChatSystem_C.tbSelfHistory        = nil   --玩家对话历史
BattleChatSystem_C.tbTeamHistory        = nil   --队内对话历史
BattleChatSystem_C.tbFriendHistory      = nil   --好友对话历史
BattleChatSystem_C.bFriednDisturb       = false --好友勿扰开关 true为请勿打扰
BattleChatSystem_C.EventHelper          = nil
-----------------------------------------------------

local function CheckLengthValid(szMsg)
    szMsg = ChatSystemHelper.ColorLabelTrim(szMsg)
    return ChatSystemHelper.CheckLengthValid(szMsg)
end

local function ShowToast(eResult)
    if eResult == eCheckResult.TooLong then
        UIUtils.ShowToast(UITextDef.CHAT_LENGTH_LIMITE)
    elseif eResult == eCheckResult.TooShort then
        UIUtils.ShowToast(UITextDef.CHAT_NOT_EMPTY)
    else
        UIUtils.ShowToast(UITextDef.CHAT_RESULT_UNKNOW)
    end
end

local function GetLocalFriendName(self, nFriendId)
    local FriendComponent = FriendSystem:GetComponent()
    local tbFriendInfo = FriendComponent:GetFriend(nFriendId)
    if not tbFriendInfo then
        return ""
    end
    local szName = tbFriendInfo.player_summary.name
    if not szName then
        return ""
    end
    return szName
end

function BattleChatSystem_C:SetFirendDisturb(bState)
    self.bFriednDisturb = bState
end

function BattleChatSystem_C:GetFirendDisturb()
    return self.bFriednDisturb
end

function BattleChatSystem_C:AddSelfHistory(szMsg)
    local tbHistory = self.tbSelfHistory
    local szStaticText = string.gsub(L10N:ToString(UITextDef.UI_STATIC_SELFCHAT_PREFIX),"'","\"")
    szMsg = string.format(szStaticText, szMsg)
    ChatSystemHelper.AddValueWithLimit(tbHistory, szMsg, MAX_SELF_HISTORY_COUNT)
    self:AddTeamHistory(szMsg)
end

function BattleChatSystem_C:GetSelfHistory()
    return self.tbSelfHistory
end

function BattleChatSystem_C:AddTeamHistory(szMsg)
    local tbHistory = self.tbTeamHistory
    ChatSystemHelper.AddValueWithLimit(tbHistory, szMsg, MAX_TEAM_HISTORY_COUNT)
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLECHAT_TEAM_NEW_MSG, szMsg)
end

function BattleChatSystem_C:GetTeamHistory()
    return self.tbTeamHistory
end

function BattleChatSystem_C:RemoveInviteFromHistory(nFriendId)
    local tbHistory = self.tbFriendHistory
    if self.bFriednDisturb or not tbHistory then
        return false
    end
    local tbTempHistory, nIndex = self:GetOneFriendInvite(nFriendId)
    if not tbTempHistory or not nIndex then
      return false
    end    
    return table.remove(tbHistory, nIndex)
end

function BattleChatSystem_C:AddInviteToFriendHistory(nFriendId)
    local tbHistory = self.tbFriendHistory
    if self.bFriednDisturb or not tbHistory then
        return
    end
    local tbTempHistory, __ = self:GetOneFriendInvite(nFriendId)
    if tbTempHistory then
      return  
    end    
    tbTempHistory = {}
    tbTempHistory.nTag = ChatSystemHelper.INVITE
    tbTempHistory.nFriendId = nFriendId
    tbTempHistory.szName = GetLocalFriendName(self, nFriendId)
    tbTempHistory.nNewCount = 1
    table.insert(tbHistory, tbTempHistory)
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLECHAT_FRIEND_NEW_MSG, nFriendId, "INVITE")
end

function BattleChatSystem_C:AddFriendHistory(nFriendId, szName, szMsg, bSelf)
    local tbHistory = self.tbFriendHistory
    if self.bFriednDisturb or not tbHistory then
        return
    end
    local tbTempHistory = self:GetOneFriendHistory(nFriendId)
    if tbTempHistory == nil then
        tbTempHistory = {}
        table.insert(tbHistory, tbTempHistory)
        tbTempHistory.nTag = ChatSystemHelper.MSG
        tbTempHistory.nFriendId = nFriendId
        tbTempHistory.szName = szName
        tbTempHistory.nNewCount = 0
        tbTempHistory.tbMsg = {}
    end
    szMsg = ChatSystemHelper.ParseExpressionSymbol(szMsg)
    szMsg = string.format("%s%s%s", bSelf and self.EFriendHistory_Mine or self.EFriendHistory_Other, self.FRIEND_HISTORY_TAG, szMsg)
    ChatSystemHelper.AddValueWithLimit(tbTempHistory.tbMsg, szMsg, MAX_FRIEND_HISTORY_COUNT)
    tbTempHistory.nNewCount = tbTempHistory.nNewCount + 1

    EventManager:OnFireEvent(ClientEventDef.EV_BATTLECHAT_FRIEND_NEW_MSG, nFriendId, szMsg)

end

function BattleChatSystem_C:ReadFriendHistory(nFriendId)
    local tbFriendDialog = self:GetOneFriendHistory(nFriendId)
    if tbFriendDialog == nil then
        return false
    end
    tbFriendDialog.nNewCount = 0
    return true
end

function BattleChatSystem_C:GetOneFriendHistory(nFriendId)
    local tbHistory = self.tbFriendHistory
    if not nFriendId then
        return nil
    end
   for k,v in pairs(tbHistory) do
       if v.nFriendId == nFriendId and v.nTag == ChatSystemHelper.MSG then
            return v
       end
   end
   return nil
end

function BattleChatSystem_C:GetOneFriendInvite(nFriendId)
    local tbHistory = self.tbFriendHistory
    if not nFriendId then
        return nil, nil
    end
   for k,v in pairs(tbHistory) do
       if v.nFriendId == nFriendId and v.nTag == ChatSystemHelper.INVITE then
            return v, k
       end
   end
   return nil, nil
end

function BattleChatSystem_C:GetFriendHistoryPreview(nFriendId)
    local tbData = self:GetOneFriendHistory(nFriendId)
    if tbData == nil then
        return ""
    end
    local tbMsg = tbData.tbMsg
    local nMsgCount = #tbMsg
    local szMsgData = tbMsg[nMsgCount]
    local tbMsgData = StringUtil.Split(szMsgData, self.FRIEND_HISTORY_TAG)
    local szResutl = tbMsgData[3] and tbMsgData[3] or ""
    return szResutl
end

function BattleChatSystem_C:FriendHasNewMsg()
    for k,v in pairs(self.tbFriendHistory) do
        if v.nNewCount > 0 then
            return true
        end
    end
    return false
end

function BattleChatSystem_C:GetFriendName(nFriendId)
    local tbData = self:GetOneFriendHistory(nFriendId)
    if tbData == nil then
        return ""
    end
    return tbData.szName
end

function BattleChatSystem_C:GetFriendHistory()
    return self.tbFriendHistory
end

function BattleChatSystem_C:SendMsgToTeam(szMsg, nSoundId)
    local eResult = CheckLengthValid(szMsg)
    if eResult ~= eCheckResult.Correct then
        ShowToast(eResult)
        return false
    end
    local tbPacket = {}
    tbPacket.content = szMsg
    tbPacket.sound_id = nSoundId
    if self:CheckSoundEnable() and nSoundId and nSoundId > 0 then
        SoundManager:PlaySoundEffect(nSoundId)
    end
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoD.c2d_Chat, tbPacket)
    return true
end

function BattleChatSystem_C:SendPointLocationToTeam(pos, pointType)
    local pX, pY, pZ = pos.X, pos.Y, pos.Z
    local tbPacket = {}
    tbPacket.posX = pX
    tbPacket.posY = pY
    tbPacket.posZ = pZ
    tbPacket.point_type = ProtoD.c2d_PointLocation_PointType.LOCATION
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoD.c2d_PointLocation, tbPacket)
    return true
end

function BattleChatSystem_C:OnRecieveTeamMsg(szSenderName, szContent, nSoundId)
    if self:CheckSoundEnable() and nSoundId and nSoundId > 0 then
        SoundManager:PlaySoundEffect(nSoundId)
    end
    local szMsg = string.format( "%s : %s", szSenderName, szContent)
    self:AddTeamHistory(szMsg)
end

function BattleChatSystem_C:OnRecieveVoiceRoomMemberId(nPlayerId, nMemberId)
   GVoiceSDKSystem:SetVoiceMemberidToPlayerId(nMemberId, tostring(nPlayerId))
end

function BattleChatSystem_C:OnRecievePointLocation(nPlayerId, pos, pointType)
    EventManager:OnFireEvent(ClientEventDef.EV_TEAM_MEMBER_POINT_LOCATE,PointTipsHelper.Proto_PointType[pointType], pos)
end

function BattleChatSystem_C:SendMsgToFriend(szMsg, nFriendId)
    local eResult = CheckLengthValid(szMsg)
    if eResult ~= eCheckResult.Correct then
        ShowToast(eResult)
        return false
    end
    szMsg = LobbyChatSystem:PackTextMsg(szMsg)
    local CHAT_FRIEND = Proto.ChatChannel.CHAT_FRIEND
    self:AddFriendHistory(nFriendId, "", szMsg, true)
    LobbyChatSystem:SendMsg(CHAT_FRIEND, szMsg, nFriendId)
    return true
 end

function BattleChatSystem_C:OnRecieveFriendMsg(nSenderId, szSenderName, szContent)
    if nSenderId ~= GamePlayerSelfHelper:Get().nPlayerId then
        self:AddFriendHistory(nSenderId, szSenderName, szContent)
    end
end

function BattleChatSystem_C:OnRecieveFriendInvite(nSenderId)
    if nSenderId ~= GamePlayerSelfHelper:Get().nPlayerId then
        self:AddInviteToFriendHistory(nSenderId)
    end
end

function BattleChatSystem_C:SendVoiceRoomMemberIdToTeam(nInstanceId, nMemberId)
    local tbPacket = {}
    tbPacket.instance_id = nInstanceId
    tbPacket.member_Id = nMemberId
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoD.c2d_ChatRoomMemberId, tbPacket)
end

function BattleChatSystem_C:CheckSoundEnable()
    local nDefaultSpeakerOption = GVoiceOpCtrlHelper.GetCurrentSpeakerOp
    return nDefaultSpeakerOption ~= GVoiceOpCtrlHelper.SPEAKER.MUTE
end

function BattleChatSystem_C:Init()
    self.tbSelfHistory   = {}
    self.tbTeamHistory   = {}
    self.tbFriendHistory = {}
    self.bFriednDisturb  = false
    self:BindEvent()
    return true
end

function BattleChatSystem_C:Uninit()
    self.tbSelfHistory   = nil
    self.tbTeamHistory   = nil
    self.tbFriendHistory = nil
    self:UnbindEvent()
    self.EventHelper = nil
end

function BattleChatSystem_C:BindEvent()
    self.EventHelper = SelfEventHelper()
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_CHAT_TO_BATTLE_FRIEND, self, self.OnRecieveFriendMsg)
    EventHelper:RegisterEvent(ClientEventDef.EV_DUNGEON_RECEIVE_INVITE, self, self.OnRecieveFriendInvite)
end

function BattleChatSystem_C:UnbindEvent()
    local EventHelper = self.EventHelper
    EventHelper:UnregisterEvent(ClientEventDef.EV_CHAT_TO_BATTLE_FRIEND, self, self.OnRecieveFriendMsg)
    EventHelper:UnregisterEvent(ClientEventDef.EV_DUNGEON_RECEIVE_INVITE, self, self.OnRecieveFriendInvite)
end


return BattleChatSystem_C()