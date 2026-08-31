local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local FriendPacketProcessor = luaclass("FriendPacketProcessor", NetMessageProcessorBase)
local NetworkManager = dynamic_require("NetworkManager")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local Proto = require("ClientProtoNames")
local FriendSystem = require("FriendSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UITextDef = require("UITextDef")
local L10N = require("L10N")
local UIDef = require("UIDef")
local UIManager = require("UIManager")
local UIUtils = require("UIUtils")

local function GetFailedToast(nReturnCode)
    local ReturnCode = Proto.ReturnCode
    if nReturnCode == ReturnCode.ALREADY_SEND_GIFT_TODAY then
        return UITextDef.FRIEND_ALREADY_SEND_TODY
    elseif nReturnCode == ReturnCode.TODAY_SEND_GIFT_LIMIT then
        return UITextDef.FRIEND_SEND_GIFT_LIMIT
    elseif nReturnCode == ReturnCode.RELATIONSHIP_COUNT_LIMIT then 
        return UITextDef.FRIEND_RELATION_COUNT_LIMIT
    elseif nReturnCode == ReturnCode.RESERVATION_NO_REPLY then 
        return UITextDef.FRIEND_RESERVATION_NO_REPLY
    else
        return nil
    end
end

local function OnRecvGetFriends(self, tbPacket)
    FriendSystem:OnRecvGetFriends(tbPacket)
end

local function OnRecvDeleteFriend(self, tbPacket)
    FriendSystem:OnRecvDeleteFriend(tbPacket)
end

local function OnRecvNotifyDeleteFriend(self, tbPacket)
    FriendSystem:OnRecvNotifyDeleteFriend(tbPacket)
end

local function OnRecvPreciseSearch(self, tbPacket)
    FriendSystem:OnRecvPreciseSearch(tbPacket)
end

local function OnRecvApplyFriend(self, tbPacket)
    FriendSystem:OnRecvApplyFriend(tbPacket)
end

local function OnRecvNotifyApplyFriend(self, tbPacket)
    FriendSystem:OnRecvNotifyApplyFriend(tbPacket)
end

local function OnRecvGetApplyFriends(self, tbPacket)
    FriendSystem:OnRecvGetApplyFriends(tbPacket)
end

local function OnRecvAddFriend(self, tbPacket)
    FriendSystem:OnRecvAddFriend(tbPacket)
end

local function OnRecvNotifyAddFriend(self, tbPacket)
    FriendSystem:OnRecvNotifyAddFriend(tbPacket)
end

local function OnRecvDeleteApplyFriend(self, tbPacket)
    FriendSystem:OnRecvDeleteApplyFriend(tbPacket)
end

local function OnRecvAddAllApplyFriend(self, tbPacket)
    FriendSystem:OnRecvAddAllApplyFriend(tbPacket)
end

local function OnRecvDeleteAllApplyFriend(self, tbPacket)
    FriendSystem:OnRecvDeleteAllApplyFriend(tbPacket)
end

local function OnRecvGetApplyFriendCount(self, tbPacket)
    FriendSystem:OnRecvGetApplyFriendCount(tbPacket)
end

-- local function OnNotifyFriendSummaryChanged(self, tbPacket)
--     FriendSystem:OnNotifyFriendSummaryChanged(tbPacket)
-- end

local function OnRecvPlayerIntimacyChanged(self, tbPacket)
    FriendSystem:OnRecvPlayerIntimacyChanged(tbPacket)
end

local function ShowErrorToast(nReturnCode, szFormatToast)
    if nReturnCode ~= Proto.ReturnCode.OK then
        local l10nToast = GetFailedToast(nReturnCode)
        if l10nToast ~= nil then
            UIUtils.ShowToast(l10nToast)
        else  
            UIUtils.ShowToast(L10N:Format(szFormatToast, nReturnCode))
        end
    end
end

local function OnRecvFriendGift(self, tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode == Proto.ReturnCode.OK then  
        UIUtils.ShowToast(UITextDef.FRIEND_SEND_COIN_SUCCESS)
        FriendSystem:AddSendCoinPlayer(tbPacket.player_id, tbPacket.time)
        EventManager:OnFireEvent(ClientEventDef.EV_SEND_COIN_SUCCESS, tbPacket.player_id)
    end
    ShowErrorToast(nReturnCode, UITextDef.FRIEND_SEND_GIFT_FAIL)
end

local function OnRecvCreateRelationShip(self, tbPacket)
    local nReturnCode = tbPacket.return_code
    ShowErrorToast(nReturnCode, UITextDef.FRIEND_CREATE_RELATION_FAIL)
end

local function OnRecApplyCreateRelationShip(self, tbPacket)
    local nReturnCode = tbPacket.return_code
    ShowErrorToast(nReturnCode, UITextDef.FRIEND_APPLY_RELATION_FAIL)
end

local function OnRecSetRelationshipPriority(self, tbPacket)
    local nReturnCode = tbPacket.return_code
    ShowErrorToast(nReturnCode, UITextDef.FRIEND_SET_PRIORITY_FAIL)
end

local function OnRecCancelRelationship(self, tbPacket)
    local nReturnCode = tbPacket.return_code
    ShowErrorToast(nReturnCode, UITextDef.FRIEND_CANCEL_RELATION_FAIL)
end

local function OnRecApplyCancelRelationship(self, tbPacket)
    local nReturnCode = tbPacket.return_code
    ShowErrorToast(nReturnCode, UITextDef.FRIEND_APPLY_CANCEL_RELATION_FAIL)
end

local function OnRecFriendRelationships(self, tbPacket)
    FriendSystem:OnRecFriendRelationships(tbPacket)
end

local function OnRecRelationshipPriorityChanged(self, tbPacket)
    FriendSystem:OnRecRelationshipPriorityChanged(tbPacket)
end

local function OnRecvRelationshipChanged(self, tbPacket)
    FriendSystem:OnRecvRelationshipChanged(tbPacket)
end

local function OnRecSendFriendReservation(self, tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode == Proto.ReturnCode.OK then 
        local ReservationStateDef = Proto.FriendReservation_FriendReservationState
        FriendSystem:AddReservationId(tbPacket.player_id, ReservationStateDef.APPLYING)
        EventManager:OnFireEvent(ClientEventDef.EV_NOTIFY_RESERVATION_RESULT, {player_get_reservation_id = tbPacket.player_id, state = ReservationStateDef.APPLYING})
    end
    ShowErrorToast(nReturnCode, UITextDef.FRIEND_SEND_RESERVATION_FAIL)
end

local function OnRecieveFriendInvite(self, tbPacket)
    local nFriendId = tbPacket.player_id
    EventManager:OnFireEvent(ClientEventDef.EV_DUNGEON_RECEIVE_INVITE, nFriendId)
end

local function OnRecieveAcceptFriendReservation(self, tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode == Proto.ReturnCode.OK then  
        EventManager:OnFireEvent(ClientEventDef.EV_ACCEPT_RESERVATION_SUCCESS, tbPacket.player_id)
    end
    ShowErrorToast(nReturnCode, UITextDef.FRIEND_ACCEPT_RESERVATION_FAIL) 
end 

local function ShowReservationAgreeUI(self, tbReservationResult)
    local FriendComponent = FriendSystem:GetComponent()
    if not FriendComponent then  
        return
    end

    local nPlayerId = GamePlayerSelfHelper:Get():GetPlayerId()
    if nPlayerId == tbReservationResult.player_send_reservation_id  then  
        local tbFriendInfo = FriendComponent:GetFriend(tbReservationResult.player_get_reservation_id)
        if not tbFriendInfo or not tbFriendInfo.player_summary then  
            return
        end

        if not UIManager:IsWndOpen(UIDef.UI_LOBBY_TEAM_ORDER) then
            UIManager:OpenWnd(UIDef.UI_LOBBY_TEAM_ORDER)
        end
        EventManager:OnFireEvent(ClientEventDef.EV_TEAM_ORDER_RESULT, UIDef.UP_FRIEND_ACCEPT_ORDER, {name = tbFriendInfo.player_summary.name})
    end
end

local function ShowExcuteReservationUI(self, tbReservation)
    if tbReservation == nil then return end  
    if not UIManager:IsWndOpen(UIDef.UI_LOBBY_TEAM_ORDER) then
        UIManager:OpenWnd(UIDef.UI_LOBBY_TEAM_ORDER)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_TEAM_ORDER_RESULT, UIDef.UP_FRIEND_PLAY_TOGETHER, {tbReservation = tbReservation})
end

local function OnRecieveFriendReservationResult(self, tbPacket)
    local nState = tbPacket.reservation.state
    local ReservationStateDef = Proto.FriendReservation_FriendReservationState
    if nState == ReservationStateDef.APPLYING or nState == ReservationStateDef.ESTABLISHED then  
        FriendSystem:AddReservationId(tbPacket.reservation.player_get_reservation_id, tbPacket.reservation.state)
    end

    if nState == ReservationStateDef.ESTABLISHED then 
        ShowReservationAgreeUI(self, tbPacket.reservation)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_NOTIFY_RESERVATION_RESULT, tbPacket.reservation)
end

local function OnRecSendReservationList(self, tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode == Proto.ReturnCode.OK then  
        EventManager:OnFireEvent(ClientEventDef.EV_SEND_CHECK_RESERVATIO_LIST_OK)
    end
end

local function OnRecExcuteFriendReservation(self, tbPacket)
    ShowExcuteReservationUI(self, tbPacket.reservation)
end  

local function OnRecGetFriendRelations(self, tbPacket)
    EventManager:OnFireEvent(ClientEventDef.EV_GET_FRIEND_RELATIONS, tbPacket)
end
-- 注册处理包
function FriendPacketProcessor:RegisterPackets()
    self:BindMethod(Proto.s2c_GetFriends, self, OnRecvGetFriends)
    self:BindMethod(Proto.s2c_DeleteFriend, self, OnRecvDeleteFriend)
    self:BindMethod(Proto.s2c_NotifyDeleteFriend, self, OnRecvNotifyDeleteFriend)
    self:BindMethod(Proto.s2c_PreciseSearch, self, OnRecvPreciseSearch)
    self:BindMethod(Proto.s2c_ApplyFriend, self, OnRecvApplyFriend)
    self:BindMethod(Proto.s2c_NotifyApplyFriend, self, OnRecvNotifyApplyFriend)
    self:BindMethod(Proto.s2c_GetApplyFriends, self, OnRecvGetApplyFriends)
    self:BindMethod(Proto.s2c_AddFriend, self, OnRecvAddFriend)
    self:BindMethod(Proto.s2c_NotifyAddFriend, self, OnRecvNotifyAddFriend)
    self:BindMethod(Proto.s2c_DeleteApplyFriend, self, OnRecvDeleteApplyFriend)
    self:BindMethod(Proto.s2c_AddAllApplyFriend, self, OnRecvAddAllApplyFriend)
    self:BindMethod(Proto.s2c_DeleteAllApplyFriend, self, OnRecvDeleteAllApplyFriend)
    self:BindMethod(Proto.s2c_GetApplyFriendCount, self, OnRecvGetApplyFriendCount)
    -- self:BindMethod(Proto.s2c_NotifyFriendSummaryChanged, self, OnNotifyFriendSummaryChanged)
    self:BindMethod(Proto.s2c_NotifyFriendIntimacyChanged, self, OnRecvPlayerIntimacyChanged)
    self:BindMethod(Proto.s2c_SendFriendGift, self, OnRecvFriendGift)
    self:BindMethod(Proto.s2c_ApplyCreateRelationship, self, OnRecvCreateRelationShip)
    self:BindMethod(Proto.s2c_NotifyRelationshipChange, self, OnRecvRelationshipChanged)
    self:BindMethod(Proto.s2c_HandleCreateRelationshipApply, self, OnRecApplyCreateRelationShip)
    self:BindMethod(Proto.s2c_SetRelationshipPriority, self, OnRecSetRelationshipPriority)
    self:BindMethod(Proto.s2c_NotifyRelationshipPriority, self, OnRecRelationshipPriorityChanged)
    self:BindMethod(Proto.s2c_ApplyCancelRelationship, self, OnRecCancelRelationship)
    self:BindMethod(Proto.s2c_HandleCancelRelationshipApply, self, OnRecApplyCancelRelationship)
    self:BindMethod(Proto.s2c_GetFriendRelationshipsByList, self, OnRecFriendRelationships)

    self:BindMethod(Proto.s2c_SendFriendReservation, self, OnRecSendFriendReservation)
    self:BindMethod(Proto.s2c_NotifyFriendReservationApply, self, OnRecieveFriendInvite)
    self:BindMethod(Proto.s2c_AcceptFriendReservation, self, OnRecieveAcceptFriendReservation)
    self:BindMethod(Proto.s2c_NotifyFriendReservationResult, self, OnRecieveFriendReservationResult)
    self:BindMethod(Proto.s2c_SendReservationList, self, OnRecSendReservationList)
    self:BindMethod(Proto.s2c_NotifyFriendReservation, self, OnRecExcuteFriendReservation)
    self:BindMethod(Proto.s2c_GetFriendRelationships, self, OnRecGetFriendRelations)
end

function FriendPacketProcessor:Init()
    FriendPacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()

    return true
end

-- 结束
function FriendPacketProcessor:Uninit()
    FriendPacketProcessor.super.Uninit(self)
end

return FriendPacketProcessor
