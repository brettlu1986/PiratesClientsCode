-----------------------------------------------------
--File Name    : UPVoiceSpeakerCtr.lua
--Author       : Edward J
--Create Time  : 2019-01-07
--Description  : UPVoiceMicCtr
-----------------------------------------------------
local luaclass              = require("luaclass")
local UPFFABase             = require("UPFFABase")
local UPVoiceSpeakerCtr     = luaclass("UPVoiceSpeakerCtr", UPFFABase)

local UIUtils               = require("UIUtils")
local UISetUtils            = require("UISetUtils")
local GVoiceSDKSystem       = require("GVoiceSDKSystem")
local ClientEventDef        = require("ClientEventDef")
local EventManager          = require("EventManager")
-- local SaveGameDef           = require("SaveGameDef")
local UIResourceDef         = require("UIResourceDef")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local GVoiceDebug           = require("GVoiceDebug")
local DelayTimer            = require("DelayTimer")
local BattleGameModeSystem  = dynamic_require("BattleGameModeSystem")
local TutorialDungeonIni    = require("TutorialDungeonIni")
local GVoiceOpCtrlHelper    = require("GVoiceOpCtrlHelper")
-----------------------------------------------------
local Visible                   = ESlateVisibility.Visible
local Collapsed                 = ESlateVisibility.Collapsed
local SPEAKALL                  = GVoiceOpCtrlHelper.SPEAKER.ALL
local SPEAKTEAM                 = GVoiceOpCtrlHelper.SPEAKER.TEAM
local SPEAKNO                   = GVoiceOpCtrlHelper.SPEAKER.MUTE
local MAX_TEAM_MEMBER_COUNT     = 3

UPVoiceSpeakerCtr.tbSpeakerSelectEffect         = nil
UPVoiceSpeakerCtr.bVisible                      = true
UPVoiceSpeakerCtr.nCurrentSpeakerOption         = SPEAKALL
UPVoiceSpeakerCtr.tbTeamMemberPrefabList        = nil
UPVoiceSpeakerCtr.pDelaySetDefaultHandler       = nil
-----------------------------------------------------
local function SetOwnerBtnVisible(self, bVisible)
    local pOwnerWidgetRef = self.Owner.pWidgetRef
    if not pOwnerWidgetRef then
        return
    end
    local pBtn = pOwnerWidgetRef.btnTalk01
    if not pBtn then
        return
    end
    local nDungeonId = BattleGameModeSystem:GetCurrentDungeonId()
    if nDungeonId == TutorialDungeonIni.nDungeonId then
        return 
    end
    pBtn:SetVisibility(bVisible and Visible or Collapsed)
end

local function SetOwnerBtnBrush(self, szIcon)
    local pOwnerWidgetRef = self.Owner.pWidgetRef
    if not pOwnerWidgetRef then
        return
    end
    local pBtn = pOwnerWidgetRef.btnTalk01
    if not pBtn then
        return
    end
    local pIcon = szIcon:load()
    UISetUtils.SetButtonBrushRes(pBtn, pIcon)
end

local function SetOwnerBtnText(self, nOption)
    local pOwnerWidgetRef = self.Owner.pWidgetRef
    if not pOwnerWidgetRef then
        return
    end
    local pTxt = pOwnerWidgetRef.txtTalk01
    if not pTxt then
        return
    end
    local szText = ""
    if nOption == SPEAKALL then
        szText = UISetUtils.GetL10NTextByKey("UI_STATIC_VOICE_ALL")
    elseif nOption == SPEAKTEAM then
        szText = UISetUtils.GetL10NTextByKey("UI_STATIC_VOICE_TEAM")
    elseif nOption == SPEAKNO then
        szText = UISetUtils.GetL10NTextByKey("UI_STATIC_VOICE_MUTE")
    end
    pTxt:setText(szText)
end

local function ShowMembers(self, bShow)
    self.pWidgetRef.vbMembers:SetVisibility(bShow and Visible or Collapsed)
end

local function ClearDelayTimer(self)
    if self.pDelaySetDefaultHandler then
        DelayTimer:ClearTimer(self.pDelaySetDefaultHandler)
    end
    self.pDelaySetDefaultHandler = nil
end

local function RefrshMemberInfo(self)
    GVoiceDebug:DebugLog("RefrshMemberInfo ")
    local nDungeonId = BattleGameModeSystem:GetCurrentDungeonId()
    if nDungeonId == TutorialDungeonIni.nDungeonId then
        return 
    end
    local nSelfPlayerId = GlobalVariableSystem.nSelfLobbyPlayerId
    local tbPlayerIds = GVoiceSDKSystem.GetTeamPlayerIds()
    if not tbPlayerIds then
        GVoiceDebug:DebugLog("tbPlayerids is nil!")
        return
    end
    local nIndex = 1
    for i, nPlayerId in ipairs(tbPlayerIds) do
        if nPlayerId and nPlayerId ~= nSelfPlayerId then
            local tbData = {}
            local pMemberItem = self.tbTeamMemberPrefabList[nIndex]
            if pMemberItem and not pMemberItem:IsSetData() then
                GVoiceDebug:DebugLog("SetData ")
                tbData.nTeamIndex = i
                tbData.nPlayerId = nPlayerId
                tbData.szRoomName = GVoiceSDKSystem:GetCurrentTeamRoomName()
                -- tbData.nVoiceMemberId = GVoiceSDKSystem:GetVoiceMemberId(tostring(nPlayerId))
                pMemberItem:SetData(tbData)
                pMemberItem:Activate()
            end
            nIndex = nIndex + 1
        end
    end
end

local function OnFFATeamChange(self)
    RefrshMemberInfo(self)
    -- local nPlayerCount = GVoiceSDKSystem.GetTeamPlayerCount()
    -- local tbPlayerIds = GVoiceSDKSystem.GetTeamPlayerIds()
    -- if nPlayerCount ~= #tbPlayerIds then
    --     RefrshMemberInfo(self)
    -- end
    -- if nPlayerCount == #tbPlayerIds then
    --     self.EventHelper:UnregisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self, OnFFATeamChange)
    -- end
end

local function OnSelectSpeakMode(self, nSelectedKey)
    self.nCurrentSpeakerOption = nSelectedKey
    GVoiceOpCtrlHelper.SetCurrentSpeakerOp(nSelectedKey)
    GVoiceDebug:DebugLog("set nCurrentSpeakerOp = " .. nSelectedKey)
    if not self.tbSpeakerSelectEffect then
        return
    end
    for nKey, pWidget in pairs(self.tbSpeakerSelectEffect) do
        local bResult =  nKey == nSelectedKey
        pWidget:SetVisibility(bResult and Visible or Collapsed)
    end
end

local function InitSpeakerSelectEffect(self, nKey, pWidget)
    self.tbSpeakerSelectEffect[nKey] = pWidget
end

local function OnMicCtrOpen(self)
    if self.bVisible then
        self:Deactivate()
    end
end

-- 如果是bDelay触发，那就说明此人无队伍
function UPVoiceSpeakerCtr:InitDefaultSelect(bSingle)
    local nDungeonId = BattleGameModeSystem:GetCurrentDungeonId()
    if nDungeonId == TutorialDungeonIni.nDungeonId then
        return 
    end
    local nDefaultSpeakerOption = GVoiceOpCtrlHelper.GetCurrentSpeakerOp()
    GVoiceDebug:DebugLog("****************InitDefaultSelect*************** " .. tostring(nDefaultSpeakerOption))
    if nDefaultSpeakerOption >= SPEAKALL and nDefaultSpeakerOption <= SPEAKNO then
        OnSelectSpeakMode(self, nDefaultSpeakerOption)
        SetOwnerBtnBrush(self, UIResourceDef.DUNGEON_VOICE_SPEAKER_ICON[nDefaultSpeakerOption])
        SetOwnerBtnText(self, nDefaultSpeakerOption)
    end
    if nDefaultSpeakerOption == SPEAKTEAM then
        ShowMembers(self, true)
    else
        ShowMembers(self, false)
    end
    RefrshMemberInfo(self)
    SetOwnerBtnVisible(self, true)
    ClearDelayTimer(self)
end

function UPVoiceSpeakerCtr:Toggle()
    if self.bVisible then
        self:Deactivate()
    else
        self:Activate()
    end
end

function UPVoiceSpeakerCtr:DelaySetDefaultOption()
    ClearDelayTimer(self)
    self.pDelaySetDefaultHandler = DelayTimer:DelayRun(function()
        self:InitDefaultSelect(true)
    end, 3)
end

function UPVoiceSpeakerCtr:Activate()
    self.super.Activate(self)
    self.pWidgetRef:SetVisibility(Visible)
    self.bVisible = true
    EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_SPEAKER_CTR_OPEN)
    SetOwnerBtnBrush(self, UIResourceDef.VOICE_PANEL_CLOSE)
    SetOwnerBtnText(self)
end

function UPVoiceSpeakerCtr:Deactivate()
    self.super.Deactivate(self)
    self.pWidgetRef:SetVisibility(Collapsed)
    self.bVisible = false
    local nIndex = self.nCurrentSpeakerOption
    SetOwnerBtnBrush(self, UIResourceDef.DUNGEON_VOICE_SPEAKER_ICON[nIndex])
    SetOwnerBtnText(self, nIndex)
end

function UPVoiceSpeakerCtr:OnLoad()
    self.super.OnLoad(self)
    self:Deactivate()
    local pWidgetRef = self.pWidgetRef
    self.tbSpeakerSelectEffect = {}
    self.tbTeamMemberPrefabList = {}
    InitSpeakerSelectEffect(self, SPEAKALL, pWidgetRef.imgSelect01)
    InitSpeakerSelectEffect(self, SPEAKTEAM, pWidgetRef.imgSelect02)
    InitSpeakerSelectEffect(self, SPEAKNO, pWidgetRef.imgSelect03)
    for i = 1, MAX_TEAM_MEMBER_COUNT do
        local tbTeamMemberPrefab = self.PrefabHelper:BindPrefab(pWidgetRef["pbMainTalkSub0"..i])
        table.insert(self.tbTeamMemberPrefabList, tbTeamMemberPrefab)
        tbTeamMemberPrefab:Deactivate()
    end
end

function UPVoiceSpeakerCtr:OnShow()
    GVoiceDebug:DebugLog("UPVoiceSpeakerCtr:OnShow")
    local bSingle = GVoiceSDKSystem.IsSelfSinglePlayer()
    self:InitDefaultSelect(bSingle)
end

function UPVoiceSpeakerCtr:OnUnload()
    self.super.OnUnload()
    self.bVisible = false
end

function UPVoiceSpeakerCtr:ClickBtnByKey(nKey)
    if nKey == SPEAKALL then
        self:OnAlwaysAllClicked()
    elseif nKey == SPEAKTEAM then
        self:OnAlwaysTeamClicked()
    elseif nKey == SPEAKNO then
        self:OnAlwaysNoClicked()
    end
end

function UPVoiceSpeakerCtr:OnAlwaysAllClicked()
    if GVoiceSDKSystem:EnableCurrentAllRoomSpeaker(true) then
        GVoiceDebug:DebugLog("=====Speaker OnAlwaysAllClicked=====")
        GVoiceSDKSystem:EnableCurrentTeamRoomSpeaker(true)
        GVoiceSDKSystem:EnableSpeaker(true)
        OnSelectSpeakMode(self, SPEAKALL)
        ShowMembers(self, false)
    end
    self:Deactivate()
end

function UPVoiceSpeakerCtr:OnAlwaysTeamClicked()
    if GVoiceSDKSystem.IsSelfSinglePlayer() then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("VOICE_NOT_A_TEAM"))
        return
    end
    if GVoiceSDKSystem:EnableCurrentTeamRoomSpeaker(true) then
        GVoiceDebug:DebugLog("===== Speaker OnAlwaysTeamClicked=====")
        GVoiceSDKSystem:EnableCurrentAllRoomSpeaker(false)
        GVoiceSDKSystem:EnableSpeaker(true)
        OnSelectSpeakMode(self, SPEAKTEAM)
        ShowMembers(self, true)
    end
    self:Deactivate()
end

function UPVoiceSpeakerCtr:OnAlwaysNoClicked()
    GVoiceSDKSystem:EnableSpeaker(false)
    OnSelectSpeakMode(self, SPEAKNO)
    ShowMembers(self, false)
    self:Deactivate()
end

function UPVoiceSpeakerCtr:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAlwaysAll.OnClicked,  self, self.OnAlwaysAllClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAlwaysTeam.OnClicked, self, self.OnAlwaysTeamClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAlwaysNo.OnClicked,   self, self.OnAlwaysNoClicked)

    EventHelper:RegisterEvent(ClientEventDef.EV_GV_ON_MIC_CTR_OPEN, self, OnMicCtrOpen)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self, OnFFATeamChange)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_GV_ON_VOICE_MEMBER_ID_CHANGE, self, RefrshMemberInfo)
end

return UPVoiceSpeakerCtr