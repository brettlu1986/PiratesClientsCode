
local luaclass              = require("luaclass")
local UPFriendQuickTipBase   = require("UPFriendQuickTipBase")
local UPFriendPlayTogether   = luaclass("UPFriendPlayTogether", UPFriendQuickTipBase)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UISetUtils= require("UISetUtils")
local L10N = require("L10N")
local Proto = require("ClientProtoNames")
local FriendSystem = require("FriendSystem")
local TeamSystem = require("TeamSystem")
local UIUtils = require("UIUtils")
local MatchmakingSystem = require("MatchmakingSystem")
local ClientEventDef = require("ClientEventDef")

UPFriendPlayTogether.nOtherPlayerId = nil
UPFriendPlayTogether.bInvite = nil

local function RefreshPlayInfo(self)
    if self.nOtherPlayerId == nil then return end  
end

local function GetCantPlayToast(self)
    if self.nOtherPlayerId == nil then return "" end  
    local FriendComponent = FriendSystem:GetComponent()
    local tbFriendInfo = FriendComponent:GetFriend(self.nOtherPlayerId)
    if tbFriendInfo == nil or tbFriendInfo.player_summary == nil then  
        return ""
    end
    local tbSummary = tbFriendInfo.player_summary
    local nStatus = tbSummary.status
    local nTeamSize = tbSummary.team_size
    local tbTeamMemberData = TeamSystem:GetTeamMemberData(tbFriendInfo.id)
    local nTeamMemberCountLimit = TeamSystem:GetTeamMemberCountLimit()
    self.bInvite = false
    if nStatus == Proto.PlayerStatus.IDLE then
        if TeamSystem:IsWaitingInvitedPlayer(tbFriendInfo.id) then 
            return UISetUtils.GetL10NTextByKey("UI_CANNOT_PLAY_WAIT_OTHER")
        elseif TeamSystem:IsWaitingAppliedPlayer(tbFriendInfo.id) then 
            return UISetUtils.GetL10NTextByKey("UI_CANNOT_PLAY_WAIT_JOIN")
        elseif nTeamSize > 0 then
            if not tbTeamMemberData then  
                if nTeamSize < nTeamMemberCountLimit then
                    return nil
                elseif nTeamSize == nTeamMemberCountLimit then 
                    return UISetUtils.GetL10NTextByKey("UI_CANNOR_PLAY_OTHERTEAM_FULL")
                end 
            end
            return ""
        else
            local nSelfTeamCount = #TeamSystem:GetTeamMemberIds()
            if nSelfTeamCount < nTeamMemberCountLimit then
                self.bInvite = true
                return nil
            elseif nSelfTeamCount == nTeamMemberCountLimit then  
                return UISetUtils.GetL10NTextByKey("UI_CANNOR_PLAY_SELFTEAM_FULL")
            end
        end
    end
    return UISetUtils.GetL10NTextByKey("UI_CANNOT_PLAY_TOGETHER")
end

local function OnBtnYes(self)
    self:Deactivate()
end  

local function OnBtnPlay(self)
    local szToast = GetCantPlayToast(self)
    if szToast ~= nil and szToast ~= "" then  
        UIUtils.ShowToast(szToast)
    else 
        if MatchmakingSystem:IsMatchmaking() then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("TEAM_MATCH_MAKING"))
            return 
        end
        if self.bInvite then
            TeamSystem:RequestInvitePlayer(self.nOtherPlayerId)
        else
            TeamSystem:RequestApplyJoin(self.nOtherPlayerId)
        end
    end
    self:Deactivate()
end

function UPFriendPlayTogether:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnYes.OnClicked, self, OnBtnYes)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnPlay.OnClicked, self, OnBtnPlay)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS, self, RefreshPlayInfo)
end

local function GetFriendName(nPlayerId)
    local szFriendName = ""
    local FriendComponent = FriendSystem:GetComponent()
    if not FriendComponent then  
        return szFriendName
    end
    local tbFriendInfo = FriendComponent:GetFriend(nPlayerId)
    if not tbFriendInfo or not tbFriendInfo.player_summary then  
        return szFriendName
    end
    szFriendName = tbFriendInfo.player_summary.name
    return szFriendName
end

function UPFriendPlayTogether:Activate(tbParams)
    UPFriendPlayTogether.super.Activate(self, tbParams)
    local nPlayerId = GamePlayerSelfHelper:Get():GetPlayerId()
    local tbReservation = tbParams.tbReservation
    local l10nStr = nil
    if nPlayerId == tbReservation.player_send_reservation_id then  
        l10nStr = UISetUtils.GetL10NTextByKey("UI_INVITER_ORDER")
        self.nOtherPlayerId = tbReservation.player_get_reservation_id
    elseif nPlayerId == tbReservation.player_get_reservation_id then  
        l10nStr = UISetUtils.GetL10NTextByKey("UI_GETTER_ORDER")
        self.nOtherPlayerId = tbReservation.player_send_reservation_id
    end
    l10nStr = L10N:Format(l10nStr, GetFriendName(self.nOtherPlayerId))
    self.pWidgetRef.txtInvite:SetText(l10nStr)

    if self.nOtherPlayerId ~= nil then
        FriendSystem:ClearReservationId(self.nOtherPlayerId)
        self.EventHelper:FireEvent(ClientEventDef.EV_UPDATE_CLEAR_RESERVATION, self.nOtherPlayerId)
    end
end

function UPFriendPlayTogether:Deactivate()
    UPFriendPlayTogether.super.Deactivate(self)
    
end

return UPFriendPlayTogether