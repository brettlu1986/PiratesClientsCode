-----------------------------------------------------
--File Name    : UPVoiceMicCtr.lua
--Author       : Edward J
--Create Time  : 2019-01-07
--Description  : UPVoiceMicCtr
-----------------------------------------------------
local luaclass          = require("luaclass")
local UPFFABase         = require("UPFFABase")
local UPVoiceMicCtr     = luaclass("UPVoiceMicCtr", UPFFABase)

local UIUtils               = require("UIUtils")
local UISetUtils            = require("UISetUtils")
local GVoiceSDKSystem       = require("GVoiceSDKSystem")
local ClientEventDef        = require("ClientEventDef")
local EventManager          = require("EventManager")
local UIResourceDef         = require("UIResourceDef")
local DelayTimer            = require("DelayTimer")
local GVoiceDebug           = require("GVoiceDebug")
local BattleGameModeSystem  = dynamic_require("BattleGameModeSystem")
local TutorialDungeonIni    = require("TutorialDungeonIni")
local GVoiceOpCtrlHelper    = require("GVoiceOpCtrlHelper")
-----------------------------------------------------
--系统频道
local Visible                   = ESlateVisibility.Visible
local Collapsed                 = ESlateVisibility.Collapsed
local SPEAKALL                  = GVoiceOpCtrlHelper.MIC.ALL
local SPEAKTEAM                 = GVoiceOpCtrlHelper.MIC.TEAM
local SPEAKNO                   = GVoiceOpCtrlHelper.MIC.MUTE
local PRESSALL                  = GVoiceOpCtrlHelper.MIC.PRESSALL
local PRESSTEAM                 = GVoiceOpCtrlHelper.MIC.PRESSTEAM

UPVoiceMicCtr.tbMicSelectEffect         = nil
UPVoiceMicCtr.bVisible                  = true
UPVoiceMicCtr.nCurrentMicOption         = SPEAKNO
UPVoiceMicCtr.PRESSALL                  = PRESSALL
UPVoiceMicCtr.PRESSTEAM                 = PRESSTEAM
UPVoiceMicCtr.pDelaySetDefaultHandler   = nil
-----------------------------------------------------
local function SetOwnerBtnVisible(self, bVisible)
    local pOwnerWidgetRef = self.Owner.pWidgetRef
    if not pOwnerWidgetRef then
        return
    end
    local pBtn = pOwnerWidgetRef.btnTalk02
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
    local pBtn = pOwnerWidgetRef.btnTalk02
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
    local pTxt = pOwnerWidgetRef.txtTalk02
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
    elseif nOption == PRESSALL then
        szText = UISetUtils.GetL10NTextByKey("UI_STATIC_VOICE_ALL")
    elseif nOption == PRESSTEAM then
        szText = UISetUtils.GetL10NTextByKey("UI_STATIC_VOICE_TEAM")
    end
    pTxt:setText(szText)
end

local function ClearDelayTimer(self)
    if self.pDelaySetDefaultHandler then
        DelayTimer:ClearTimer(self.pDelaySetDefaultHandler)
    end
    self.pDelaySetDefaultHandler = nil
end

-- local function OnSinglePlayer(self)
--     GVoiceDebug:DebugLog("OnSinglePlayer")
--     self:InitDefaultSelect(true)
-- end

local function OnSelectMicMode(self, nSelectedKey)
    self.nCurrentMicOption = nSelectedKey
    GVoiceOpCtrlHelper.SetCurrentMicOp(nSelectedKey)
    if not self.tbMicSelectEffect then
        return
    end
    for nKey, pWidget in pairs(self.tbMicSelectEffect) do
        local bResult =  nKey == nSelectedKey
        pWidget:SetVisibility(bResult and Visible or Collapsed)
    end
end

local function InitMicSelectEffect(self, nKey, pWidget)
    self.tbMicSelectEffect[nKey] = pWidget
end

local function OnSpeakerCtrOpen(self)
    if self.bVisible then
        self:Deactivate()
    end
end

function UPVoiceMicCtr:InitDefaultSelect(bSingle)
    local nDungeonId = BattleGameModeSystem:GetCurrentDungeonId()
    if nDungeonId == TutorialDungeonIni.nDungeonId then
        return 
    end
    local nDefaultMicOption = GVoiceOpCtrlHelper.GetCurrentMicOp()
    if nDefaultMicOption >= SPEAKALL and nDefaultMicOption <= PRESSTEAM then
        -- if bSingle then
        --     if nDefaultMicOption == SPEAKTEAM then
        --         nDefaultMicOption = SPEAKALL
        --     end
        -- end
        OnSelectMicMode(self, nDefaultMicOption)
        SetOwnerBtnBrush(self, UIResourceDef.DUNGEON_VOICE_MIC_ICON[nDefaultMicOption])
        SetOwnerBtnText(self, nDefaultMicOption)
    end
    SetOwnerBtnVisible(self, true)
    ClearDelayTimer(self)
end

function UPVoiceMicCtr:Toggle()
    if self.bVisible then
        self:Deactivate()
    else
        self:Activate()
    end
end

function UPVoiceMicCtr:DelaySetDefaultOption()
    ClearDelayTimer(self)
    self.pDelaySetDefaultHandler = DelayTimer:DelayRun(function()
        self:InitDefaultSelect(true)
    end, 3)
end

function UPVoiceMicCtr:Activate()
    self.super.Activate(self)
    self.pWidgetRef:SetVisibility(Visible)
    self.bVisible = true
    EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_MIC_CTR_OPEN)
    SetOwnerBtnBrush(self, UIResourceDef.VOICE_PANEL_CLOSE)
    SetOwnerBtnText(self)
end

function UPVoiceMicCtr:Deactivate()
    self.super.Deactivate(self)
    self.pWidgetRef:SetVisibility(Collapsed)
    self.bVisible = false
    local nIndex = self.nCurrentMicOption
    SetOwnerBtnBrush(self, UIResourceDef.DUNGEON_VOICE_MIC_ICON[nIndex])
    SetOwnerBtnText(self, nIndex)
end

function UPVoiceMicCtr:OnLoad()
    self.super.OnLoad(self)
    self:Deactivate()
    local pWidgetRef = self.pWidgetRef
    self.tbMicSelectEffect = {}
    InitMicSelectEffect(self, SPEAKALL, pWidgetRef.imgSelect01)
    InitMicSelectEffect(self, SPEAKTEAM, pWidgetRef.imgSelect02)
    InitMicSelectEffect(self, SPEAKNO, pWidgetRef.imgSelect03)
    InitMicSelectEffect(self, PRESSALL, pWidgetRef.imgSelect04)
    InitMicSelectEffect(self, PRESSTEAM, pWidgetRef.imgSelect05)
end

function UPVoiceMicCtr:OnShow()
    GVoiceDebug:DebugLog("UPVoiceMicCtr:OnShow")
    local bSingle = GVoiceSDKSystem.IsSelfSinglePlayer()
    self:InitDefaultSelect(bSingle)
end

function UPVoiceMicCtr:OnUnload()
    self.super.OnUnload()
    -- SaveDefaultSelect(self)
    self.tbMicSelectEffect = nil
    self.bVisible = false
end

function UPVoiceMicCtr:ClickBtnByKey(nKey)
    if nKey == SPEAKALL then
        self:OnAlwaysAllClicked()
    elseif nKey == SPEAKTEAM then
        self:OnAlwaysTeamClicked()
    elseif nKey == SPEAKNO then
        self:OnAlwaysNoClicked()
    elseif nKey == PRESSALL then
        self:OnPassAllClicked()
    elseif nKey == PRESSTEAM then
        self:OnPassTeamClicked()
    end
end

function UPVoiceMicCtr:OnAlwaysAllClicked()
    GVoiceDebug:DebugLog("OnAlwaysAllClicked")
    if not GVoiceSDKSystem:CheckMicEnable() then
        return
    end
    if GVoiceSDKSystem:EnableCurrentAllRoomMicrophone(true) then
        GVoiceDebug:DebugLog("===== Mic OnAlwaysAllClicked=====")
        GVoiceSDKSystem:EnableCurrentTeamRoomMicrophone(true)
        GVoiceSDKSystem:EnableMic(true)
        OnSelectMicMode(self, SPEAKALL)
    end
    self:Deactivate()
end

function UPVoiceMicCtr:OnAlwaysTeamClicked()
    GVoiceDebug:DebugLog("OnAlwaysTeamClicked")
    if GVoiceSDKSystem.IsSelfSinglePlayer() then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("VOICE_NOT_A_TEAM"))
        return
    end
    if not GVoiceSDKSystem:CheckMicEnable() then
        return
    end
    if GVoiceSDKSystem:EnableCurrentTeamRoomMicrophone(true) then
        GVoiceDebug:DebugLog("===== Mic OnAlwaysTeamClicked=====")
        GVoiceSDKSystem:EnableCurrentAllRoomMicrophone(false)
        GVoiceSDKSystem:EnableMic(true)
        OnSelectMicMode(self, SPEAKTEAM)
    end
    self:Deactivate()
end

function UPVoiceMicCtr:OnAlwaysNoClicked()
    GVoiceDebug:DebugLog("OnAlwaysNoClicked")
    GVoiceSDKSystem:EnableMic(false)
    OnSelectMicMode(self, SPEAKNO)
    self:Deactivate()
end

function UPVoiceMicCtr:OnPassAllClicked()
    if not GVoiceSDKSystem:CheckMicEnable() then
        return
    end
    if GVoiceSDKSystem:EnableCurrentAllRoomMicrophone(true) then
        GVoiceDebug:DebugLog("===== Mic OnPassAllClicked=====")
        GVoiceSDKSystem:EnableCurrentTeamRoomMicrophone(true)
        GVoiceSDKSystem:EnableMic(false)
        OnSelectMicMode(self, PRESSALL)
    end
    self:Deactivate()
end

function UPVoiceMicCtr:OnPassTeamClicked()
    if GVoiceSDKSystem.IsSelfSinglePlayer() then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("VOICE_NOT_A_TEAM"))
        return
    end
    if not GVoiceSDKSystem:CheckMicEnable() then
        return
    end
   if GVoiceSDKSystem:EnableCurrentTeamRoomMicrophone(true) then
    GVoiceSDKSystem:EnableCurrentAllRoomMicrophone(false)
        GVoiceSDKSystem:EnableMic(false)
        OnSelectMicMode(self, PRESSTEAM)
   end
   self:Deactivate()
end

function UPVoiceMicCtr:GetCurrentMicOption()
    return self.nCurrentMicOption
end

function UPVoiceMicCtr:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAlwaysAll.OnClicked,  self, self.OnAlwaysAllClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAlwaysTeam.OnClicked, self, self.OnAlwaysTeamClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAlwaysNo.OnClicked,   self, self.OnAlwaysNoClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnPassAll.OnClicked,    self, self.OnPassAllClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnPassTeam.OnClicked,   self, self.OnPassTeamClicked)

    EventHelper:RegisterEvent(ClientEventDef.EV_GV_ON_SPEAKER_CTR_OPEN, self, OnSpeakerCtrOpen)
end

return UPVoiceMicCtr