-----------------------------------------------------
--File Name    : UPVoiceSpeakerItem.lua
--Author       : Edward J
--Create Time  : 2019-01-17
--Description  : UPVoiceMicCtr
-----------------------------------------------------
local luaclass              = require("luaclass")
local UPFFABase             = require("UPFFABase")
local UPVoiceSpeakerItem    = luaclass("UPVoiceSpeakerItem", UPFFABase)

local GVoiceSDKSystem   = require("GVoiceSDKSystem")
local UIResourceDef     = require("UIResourceDef")
local UISetUtils        = require("UISetUtils")
local GVoiceDebug       = require("GVoiceDebug")
local ClientEventDef    = require("ClientEventDef")
-----------------------------------------------------
local Visible                   = ESlateVisibility.Visible
local Collapsed                 = ESlateVisibility.Collapsed

UPVoiceSpeakerItem.tbData           = nil
UPVoiceSpeakerItem.szRoomName       = nil
UPVoiceSpeakerItem.nVoiceMemberId   = nil
UPVoiceSpeakerItem.nPlayerId        = nil
UPVoiceSpeakerItem.bEnable          = true
UPVoiceSpeakerItem.bSetData         = false
-----------------------------------------------------

local function RefreshMemberSpeakerState(self, bEnable)
    local pWidgetRef = self.pWidgetRef
    UISetUtils.SetImageBrushRes(pWidgetRef.imgState, bEnable and UIResourceDef.VOICE_MEMBER_SPEAKER_STATE_OPEN:load() or UIResourceDef.VOICE_MEMBER_SPEAKER_STATE_CLOSE:load())
end

local function OnBtnTeamClicked(self)
    local szRoomName = self.szRoomName
    local nVoiceMemberId = self.nVoiceMemberId
    local bEnable = self.bEnable
    bEnable = not bEnable
    self.bEnable = bEnable
    RefreshMemberSpeakerState(self, bEnable)
    GVoiceDebug:DebugLog("OnBtnTeamClicked szRoomName = " .. tostring(szRoomName) .. " nVoiceMemberId =" .. tostring(nVoiceMemberId) .. " enable " .. tostring(bEnable))
    -- GVoiceSDKSystem:ForbidMemberVoice(nVoiceMemberId, not bEnable, szRoomName)
    if not nVoiceMemberId then
        GVoiceDebug:DebugLog("not nVoiceMemberId")
        GVoiceSDKSystem:GetRoomMembers(szRoomName)
    else
        GVoiceDebug:DebugLog("ForbidMemberVoice")
        GVoiceSDKSystem:ForbidMemberVoice(nVoiceMemberId, not bEnable, szRoomName)
    end
end

local function OnRoomMemberInfo(self, nMemberId, szOpenId)
    local nOpenId = tonumber(szOpenId)
    if not self.nVoiceMemberId and nOpenId == self.nPlayerId then
        self.nVoiceMemberId = nMemberId
        GVoiceSDKSystem:ForbidMemberVoice(nMemberId, not self.bEnable, self.szRoomName)
    end
end

function UPVoiceSpeakerItem:IsSetData()
    --GVoiceDebug:DebugLog("IsSetData : " .. tostring(self.bSetData))
    return self.bSetData
end

function UPVoiceSpeakerItem:Activate(tbParam)
    local pWidgetRef = self.pWidgetRef
    if not pWidgetRef then
        return
    end
    pWidgetRef:SetVisibility(Visible)
end

function UPVoiceSpeakerItem:Deactivate()
    local pWidgetRef = self.pWidgetRef
    if not pWidgetRef then
        return
    end
    pWidgetRef:SetVisibility(Collapsed)
end

function UPVoiceSpeakerItem:OnLoad()
    self.super.OnLoad(self)
    self.tbData = {}
end

function UPVoiceSpeakerItem:OnUnload()
    self.super.OnUnload()
    self.bSetData = false
    self.nVoiceMemberId = nil
    self.nPlayerId = nil
end

function UPVoiceSpeakerItem:SetData(tbData)
    local pWidgetRef = self.pWidgetRef
    if not pWidgetRef then
        return
    end
    self.bSetData = true
    local nTeamIndex = tbData.nTeamIndex
    local szRoomName = tbData.szRoomName
    -- local nVoiceMemberId = tbData.nVoiceMemberId
    self.szRoomName = szRoomName
    self.nPlayerId = tbData.nPlayerId
    -- self.nVoiceMemberId = nVoiceMemberId
    -- if nVoiceMemberId ~= nil and szRoomName ~= nil then
    --     GVoiceDebug:DebugLog("SetData szRoomName : " .. tostring(szRoomName) .. " nVoiceMemberId : " .. tostring(nVoiceMemberId))
    --     self.bSetData = true
    -- end
    local pLinearColor = UIResourceDef.TEAM_INDEX_COLOR[nTeamIndex]
    if not pLinearColor then
        pLinearColor = UIResourceDef.COLOR.WHITE.LINEAR_COLOR
    end
    
    pWidgetRef.imgMember:SetColorAndOpacity(pLinearColor)
    pWidgetRef.txtMemberId:SetText(nTeamIndex)
end

function UPVoiceSpeakerItem:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnTeam.OnClicked,  self, OnBtnTeamClicked)
    EventHelper:RegisterEvent(ClientEventDef.EV_GV_ON_VOICE_ROOM_MEMBER_INFO, self, OnRoomMemberInfo)
end

return UPVoiceSpeakerItem