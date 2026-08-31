-----------------------------------------------------
--File Name    : UPLobbyChatTeaming.lua
--Author       : Edward J
--Create Time  : 2019-04-10
--Description  : lobby Chat Teaming Panel
-----------------------------------------------------
local luaclass              = require("luaclass")
local PrefabBase            = require("PrefabBase")
local UPLobbyChatTeaming    = luaclass("UPLobbyChatTeaming", PrefabBase)

local LobbyChatSystem       = require("LobbyChatSystem")
local TeamSystem            = require("TeamSystem")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local UIUtils               = require("UIUtils")
local UISetUtils            = require("UISetUtils")
local ProtoName             = require("ClientProtoNames")
-----------------------------------------------------
local Visible               = ESlateVisibility.Visible
local Collapsed             = ESlateVisibility.Collapsed
local TEXT_HAVE_CHAT_ROOM   = "聊天室（%s）"
local TEXT_NO_CHAT_ROOM     = "聊天室（未加入聊天室）"
local TEXT_COLOR_ENABEL     = '<text color="#00ADFFFF">%s</>'
local TEXT_COLOR_DISABLE    = '<text color="#FF0000">%s</>'
local CHAT_TEAM_INVITE      = LobbyChatSystem.CHAT_TEAM_INVITE
local ERecruitChannel       = ProtoName.RecruitChannel
local TEAM_FOUR             = 4
local TEAM_TWO              = 2
local DEFAULT_DUNGEON_ID    = 1
local SINGEL_TEAM_NUMBER    = 1
local eErrorCode = {
    ["INVALID"]     = 0,
    ["NOACCESSN"]   = 1,
    ["BEFULL"]      = 2
}

UPLobbyChatTeaming.tbSendChannel    = nil
UPLobbyChatTeaming.nTeamMemberCount = 1
UPLobbyChatTeaming.PlayerSelf       = nil
UPLobbyChatTeaming.bFull            = false
UPLobbyChatTeaming.bTargetModeEnable= false
UPLobbyChatTeaming.nTeamMode        = 4
UPLobbyChatTeaming.eChangeError     = eErrorCode.INVALID
-----------------------------------------------------

local function OnCheckBoxClick(self, eChannel, bCheckState)
    self.tbSendChannel[eChannel] = bCheckState
end

local function RefreshCorpsItem(self)
    local bInCorps = false --判断是否有军团
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.checkBox_corps:SetVisibility(bInCorps and Visible or Collapsed)
    OnCheckBoxClick(self, ERecruitChannel.CORPS, bInCorps)
end 

local function RefreshRoomItemState(self)
    local pWidgetRef = self.pWidgetRef
    local bInRoom = false --判断是否有聊天室
    local szRoomName = "刺激"
    -- pWidgetRef.checkBox_room:SetIsEnabled(bInRoom)
    pWidgetRef.checkBox_room:SetVisibility(bInRoom and Visible or Collapsed)
    OnCheckBoxClick(self, ERecruitChannel.ROOM, bInRoom)
    local szChatRoom = bInRoom and string.format(TEXT_HAVE_CHAT_ROOM, szRoomName) or TEXT_NO_CHAT_ROOM
    pWidgetRef.txtChatRoom:SetText(szChatRoom)
end

local function IsSelectedSendChannel(self)
    for eChannel, bSend in pairs(self.tbSendChannel) do
        if bSend then
            return true
        end
    end
    return false
end

local function ShowErrorToast(self)
    local eChangeError = self.eChangeError
    if eChangeError == eErrorCode.BEFULL then
        local pWidgetRef = self.pWidgetRef
        local bcbFour = pWidgetRef.cbFour
        if bcbFour:IsChecked() then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("TAMING_FULL"))
        else
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("TAMING_TWO_FULL"))
        end
        return false
    end

    if eChangeError == eErrorCode.NOACCESSN then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("TAMING_MODE_NOT_MATCH"))
        return false
    end
    return true
end

local function IsTeamLeader(self)
    local tbPlayer = GamePlayerSelfHelper:Get()
    if not tbPlayer then
        return false
    end
    return TeamSystem:IsTeamLeader(tbPlayer.nPlayerId)
end
local function ChangeMatchCondition(self, nTeamMode)
    if not TeamSystem:IsInTeam() or IsTeamLeader(self) then
        TeamSystem:ChangeMatchCondition(nTeamMode, true, 100011)
    end
end

local function RefreshTeamMemberInfo(self, nTeamMemberCount, nTargetTeamMode)
    local pWidgetRef = self.pWidgetRef
    local szText = ""
    if nTeamMemberCount >= nTargetTeamMode then
        szText = string.format(TEXT_COLOR_DISABLE, nTeamMemberCount .. "/" .. nTargetTeamMode)
        self.eChangeError = eErrorCode.BEFULL
    else
        szText = string.format(TEXT_COLOR_ENABEL, nTeamMemberCount .. "/" .. nTargetTeamMode)
    end
    pWidgetRef.txtNumber:setText(szText)
end

local function OnTeamLeaderChangeTeamMode(self, nTargetTeamMode, nCurrentTeamMode, nTeamMemberCount)
    local bSameTeamMode = nTargetTeamMode == nCurrentTeamMode
    if not bSameTeamMode then
        ChangeMatchCondition(self, nTargetTeamMode)
    end
    RefreshTeamMemberInfo(self, nTeamMemberCount, nTargetTeamMode)
end

local function OnTeammateChangeTeamMode(self, nTargetTeamMode, nCurrentTeamMode, nTeamMemberCount)
    local bSameTeamMode = nTargetTeamMode == nCurrentTeamMode
    RefreshTeamMemberInfo(self, nTeamMemberCount, nTargetTeamMode)
    if not bSameTeamMode then
        self.eChangeError = eErrorCode.NOACCESSN
        return
    end
end

local function CheckChangeEnable(self, nTargetTeamMode)
    if not TeamSystem:IsInTeam() then
        ChangeMatchCondition(self, nTargetTeamMode)
        RefreshTeamMemberInfo(self, SINGEL_TEAM_NUMBER, nTargetTeamMode)
        return
    end
    local bIsTeamLeader = IsTeamLeader(self)
    local tbPlayerIds = TeamSystem:GetTeamMemberIds()
    local nTeamMemberCount = #tbPlayerIds
    local nCurrentTeamMode = TeamSystem.nTeamMode
    if bIsTeamLeader then
        OnTeamLeaderChangeTeamMode(self, nTargetTeamMode, nCurrentTeamMode, nTeamMemberCount)
    else
        OnTeammateChangeTeamMode(self, nTargetTeamMode, nCurrentTeamMode, nTeamMemberCount)
    end
end

local function OnClickModeFour(self, bCheckState)
    local pWidgetRef = self.pWidgetRef
    local pcbTow = pWidgetRef.cbTow
    local bcbFour = pWidgetRef.cbFour
    self.eChangeError = eErrorCode.INVALID
    if bCheckState then
        self.nTeamMode = TEAM_FOUR
        pcbTow:SetCheckedState(ECheckBoxState.Unchecked)
    else
        if not pcbTow:IsChecked() then
            bcbFour:SetCheckedState(ECheckBoxState.Checked)
        end
    end
    CheckChangeEnable(self, TEAM_FOUR)
    ShowErrorToast(self)
end

local function OnClickModeTwo(self, bCheckState)
    local pWidgetRef = self.pWidgetRef
    local pcbTow = pWidgetRef.cbTow
    local bcbFour = pWidgetRef.cbFour
    self.eChangeError = eErrorCode.INVALID
    if bCheckState then
        self.nTeamMode = TEAM_TWO
        bcbFour:SetCheckedState(ECheckBoxState.Unchecked)
    else
        if not pcbTow:IsChecked() then
            pcbTow:SetCheckedState(ECheckBoxState.Checked)
        end
    end
    CheckChangeEnable(self, TEAM_TWO)
    ShowErrorToast(self)
end

function UPLobbyChatTeaming:OnBtnSend()
    if not ShowErrorToast(self) then
        return
    end
    local bAnyChannel = IsSelectedSendChannel(self)
    if not bAnyChannel then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("NONE_CHANNEL"))
        return
    end
    local tbEChannel = {}
    local bSendTeamInvite = false
    for eChannel, bSend in pairs(self.tbSendChannel) do
        if bSend then
            bSendTeamInvite = true
            table.insert(tbEChannel, eChannel)        
        end
    end
    if bSendTeamInvite then
        LobbyChatSystem:SendToTeamInvite(CHAT_TEAM_INVITE, tbEChannel, DEFAULT_DUNGEON_ID, self.nTeamMode)
    end
end

function UPLobbyChatTeaming:Activate()
    RefreshCorpsItem(self)
    RefreshRoomItemState(self)
    self.pWidgetRef:SetVisibility(Visible)
end

function UPLobbyChatTeaming:Deactivate()
    self.pWidgetRef:SetVisibility(Collapsed)
end

function UPLobbyChatTeaming:OnLoad()
    self.tbSendChannel = {}
    OnCheckBoxClick(self, ERecruitChannel.WORLD, true) --世界频道默认必选
    OnClickModeFour(self, true)
    self:Activate() 
end

function UPLobbyChatTeaming:OnUnload()
    self.tbSendChannel = nil
end

function UPLobbyChatTeaming:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegateFunc(pWidgetRef.checkBox_world.OnCheckStateChanged, function(bCheckState) OnCheckBoxClick(self,  ERecruitChannel.WORLD, bCheckState) end)
    EventHelper:RegisterCppDelegateFunc(pWidgetRef.checkBox_corps.OnCheckStateChanged, function(bCheckState) OnCheckBoxClick(self,  ERecruitChannel.ROOM, bCheckState) end)
    EventHelper:RegisterCppDelegateFunc(pWidgetRef.cbFour.OnCheckStateChanged, function(bCheckState) OnClickModeFour(self, bCheckState) end)
    EventHelper:RegisterCppDelegateFunc(pWidgetRef.cbTow.OnCheckStateChanged, function(bCheckState) OnClickModeTwo(self, bCheckState) end)
end

return UPLobbyChatTeaming