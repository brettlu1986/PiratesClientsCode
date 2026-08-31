-----------------------------------------------------
--File Name    : ULLobbyVoiceCtrl.lua
--Author       : Edward J
--Create Time  : 4/20/2020
--Description  : ULLobbyVoiceCtrl
-----------------------------------------------------
local luaclass              = require("luaclass")
local UILogicBase           = require("UILogicBase")
local ULLobbyVoiceCtrl      = luaclass("ULLobbyVoiceCtrl", UILogicBase)

local GVoiceSDKSystem           = require("GVoiceSDKSystem")
local UISetUtils                = require("UISetUtils")
local UIResourceDef             = require("UIResourceDef")
local UIUtils                   = require("UIUtils")
local TeamSystem                = require("TeamSystem")
local DelayTimer                = require("DelayTimer")
local GVoiceOpCtrlHelper        = require("GVoiceOpCtrlHelper")
local ClientEventDef            = require("ClientEventDef")
local EventManager              = require("EventManager")
-----------------------------------------------------
local Visible                   = ESlateVisibility.Visible
local Collapsed                 = ESlateVisibility.Collapsed

local MICPANNELOPEND            = false
local SPEAKERPANNELOPEND        = false
local MICALL                    = GVoiceOpCtrlHelper.MIC.ALL
local MICTEAM                   = GVoiceOpCtrlHelper.MIC.TEAM
local MICNO                     = GVoiceOpCtrlHelper.MIC.MUTE
local PRESSALL                  = GVoiceOpCtrlHelper.MIC.PRESSALL
local PRESSTEAM                 = GVoiceOpCtrlHelper.MIC.PRESSTEAM

local SPEAKALL                  = GVoiceOpCtrlHelper.SPEAKER.ALL
local SPEAKTEAM                 = GVoiceOpCtrlHelper.SPEAKER.TEAM
local SPEAKNO                   = GVoiceOpCtrlHelper.SPEAKER.MUTE

local PRESS_TIME_OUT            = 10
local PRESS_INTERVAL            = 0.5

local SELECTED_BTN_EFFECT       = UIResourceDef.LOBBY_VOICE_BTN_HIGHLIGHT
local NORMAL_BTN_EFFECT         = UIResourceDef.LOBBY_VOICE_BTN_NORMAL

ULLobbyVoiceCtrl.nCurrentMicOp              = nil
ULLobbyVoiceCtrl.nCurrentSpeakerOp          = nil
ULLobbyVoiceCtrl.tbSpeakerSelectEffect      = nil
ULLobbyVoiceCtrl.tbMicSelectEffect          = nil
ULLobbyVoiceCtrl.pVoicePressTimer           = nil
ULLobbyVoiceCtrl.pDealyEffectTimer          = nil
ULLobbyVoiceCtrl.nVoiceMicPressedStart      = 0
ULLobbyVoiceCtrl.nVoiceMicPressedEnd        = 0
ULLobbyVoiceCtrl.bVoiceMicOnPressed         = false
-----------------------------------------------------

local function CreateEffectWidgetTable(pBtn, pImage, pText)
    local tbTemp = {}
    tbTemp.btn = pBtn
    tbTemp.img = pImage
    tbTemp.txt = pText
    return tbTemp
end

local function SetWidgetColorAndOpcity(pWidgetRef, ColorDef)
    if not pWidgetRef then
        return
    end
    pWidgetRef:SetColorAndOpacity(ColorDef)
end

local function InitSpeakerSelectEffect(self, nKey, tbEffectWidgets)
    self.tbSpeakerSelectEffect[nKey] = tbEffectWidgets
end

local function InitMicSelectEffect(self, nKey, tbEffectWidgets)
    self.tbMicSelectEffect[nKey] = tbEffectWidgets
end

local function OnMicSelectEffect(self, nSelectedKey)
    local nPreMicOp = self.nCurrentMicOp
    self.nCurrentMicOp = nSelectedKey
    GVoiceOpCtrlHelper.SetCurrentMicOp(nSelectedKey)
    if not self.tbMicSelectEffect then
        return
    end
    for nKey, tbWidgets in pairs(self.tbMicSelectEffect) do
        if nKey == nPreMicOp then
            local szIcon = NORMAL_BTN_EFFECT
            local pIcon = szIcon:load()
            UISetUtils.SetButtonBrushRes(tbWidgets.btn, pIcon)
            SetWidgetColorAndOpcity(tbWidgets.img, UIResourceDef.COLOR.WHITE.LINEAR_COLOR)
            SetWidgetColorAndOpcity(tbWidgets.txt, UIResourceDef.COLOR.WHITE.SLATE_COLOR)
        end

        if nKey == nSelectedKey then
            local szIcon = SELECTED_BTN_EFFECT
            local pIcon = szIcon:load()
            UISetUtils.SetButtonBrushRes(tbWidgets.btn, pIcon)
            SetWidgetColorAndOpcity(tbWidgets.img, UIResourceDef.COLOR.BLACK.LINEAR_COLOR)
            SetWidgetColorAndOpcity(tbWidgets.txt, UIResourceDef.COLOR.BLACK.SLATE_COLOR)
        end
    end
end

local function OnSpeakSelectEffect(self, nSelectedKey)
    local nPreSpeakerOp = self.nCurrentSpeakerOp
    self.nCurrentSpeakerOp = nSelectedKey
    GVoiceOpCtrlHelper.SetCurrentSpeakerOp(nSelectedKey)
    if not self.tbSpeakerSelectEffect then
        return
    end
    for nKey, tbWidgets in pairs(self.tbSpeakerSelectEffect) do
        if nKey == nPreSpeakerOp then
            local szIcon = NORMAL_BTN_EFFECT
            local pIcon = szIcon:load()
            UISetUtils.SetButtonBrushRes(tbWidgets.btn, pIcon)
            SetWidgetColorAndOpcity(tbWidgets.img, UIResourceDef.COLOR.WHITE.LINEAR_COLOR)
            SetWidgetColorAndOpcity(tbWidgets.txt, UIResourceDef.COLOR.WHITE.SLATE_COLOR)
        end

        if nKey == nSelectedKey then
            local szIcon = SELECTED_BTN_EFFECT
            local pIcon = szIcon:load()
            UISetUtils.SetButtonBrushRes(tbWidgets.btn, pIcon)
            SetWidgetColorAndOpcity(tbWidgets.img, UIResourceDef.COLOR.BLACK.LINEAR_COLOR)
            SetWidgetColorAndOpcity(tbWidgets.txt, UIResourceDef.COLOR.BLACK.SLATE_COLOR)
        end
    end
end

local function SetMicBtnBrush(self, szIcon)
    local pImg = self.pWidgetRef.imgMicStatus
    local pIcon = szIcon:load()
    UISetUtils.SetImageBrushRes(pImg, pIcon)
end

local function SetSpeakerBtnBrush(self, szIcon)
    local pImg = self.pWidgetRef.imgSpeakerStatus
    local pIcon = szIcon:load()
    UISetUtils.SetImageBrushRes(pImg, pIcon)
end

local function SetBtnText(self, pTxt ,nOption)
    local szText = ""
    if nOption == MICALL then
        szText = UISetUtils.GetL10NTextByKey("UI_STATIC_VOICE_ALL")
    elseif nOption == MICTEAM then
        szText = UISetUtils.GetL10NTextByKey("UI_STATIC_VOICE_TEAM")
    elseif nOption == MICNO then
        szText = UISetUtils.GetL10NTextByKey("UI_STATIC_VOICE_MUTE")
    elseif nOption == PRESSALL then
        szText = UISetUtils.GetL10NTextByKey("UI_STATIC_VOICE_ALL")
    elseif nOption == PRESSTEAM then
        szText = UISetUtils.GetL10NTextByKey("UI_STATIC_VOICE_TEAM")
    end
    pTxt:setText(szText)
end

local function CloseSpeakerPanel(self, eVisible)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrSpeaker:SetVisibility(eVisible)
    SPEAKERPANNELOPEND = not SPEAKERPANNELOPEND
    EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_LOBBY_SPECIAL_WIDGET_OPEN, not SPEAKERPANNELOPEND)
end

local function CloseMicPanel(self, eVisible)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrMic:SetVisibility(eVisible)
    pWidgetRef.bdrMicPress:SetVisibility(eVisible)
    MICPANNELOPEND = not MICPANNELOPEND
    EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_LOBBY_SPECIAL_WIDGET_OPEN, not MICPANNELOPEND)
end

local function OnClickSpeakerPanel(self)
    CloseSpeakerPanel(self, (SPEAKERPANNELOPEND and Collapsed or Visible))
    CloseMicPanel(self, Collapsed)
end

local function OnClickMicPanel(self)
    local nMicOption = self.nCurrentMicOp
    local pWidgetRef = self.pWidgetRef
    local nPressInterval = self.nVoiceMicPressedEnd - self.nVoiceMicPressedStart
    if nMicOption < PRESSALL or pWidgetRef.bdrMic:IsVisible() or nPressInterval < PRESS_INTERVAL then
        CloseMicPanel(self, (MICPANNELOPEND and Collapsed or Visible))
        CloseSpeakerPanel(self, Collapsed)
    end
end

local function ClearVoiceMicPressTimer(self)
    if  self.pVoicePressTimer then
        DelayTimer:ClearTimer(self.pVoicePressTimer)
        self.pVoicePressTimer = nil
    end
end

local function ClearDelayEffectTimer(self)
    if  self.pDealyEffectTimer then
        DelayTimer:ClearTimer(self.pDealyEffectTimer)
        self.pDealyEffectTimer = nil
    end
end

local function OnVoiceMicReleased(self)
    local nMicOption = self.nCurrentMicOp
    local pWidgetRef = self.pWidgetRef
    if nMicOption == PRESSALL or nMicOption == PRESSTEAM then
        if TeamSystem:IsInTeam() then
            GVoiceSDKSystem:EnableMic(false)
        end
        self.nVoiceMicPressedEnd = os.time()
        self.bVoiceMicOnPressed = false
        pWidgetRef.imgPress:SetVisibility(ESlateVisibility_Collapsed)
        ClearVoiceMicPressTimer(self)
        ClearDelayEffectTimer(self)
    end
end

local function OnVoiceMicPressed(self)
    local nMicOption = self.nCurrentMicOp
    local pWidgetRef = self.pWidgetRef
    if nMicOption == PRESSALL or nMicOption == PRESSTEAM then
        if TeamSystem:IsInTeam() then
            GVoiceSDKSystem:EnableMic(true)
        end
        self.nVoiceMicPressedStart = os.time()
        self.bVoiceMicOnPressed = true
        ClearDelayEffectTimer(self)
        self.pDealyEffectTimer = DelayTimer:DelayRun(function() pWidgetRef.imgPress:SetVisibility(ESlateVisibility_HitTestInvisible) end, PRESS_INTERVAL) 
        ClearVoiceMicPressTimer(self)
        self.pVoicePressTimer = DelayTimer:DelayRun(function() OnVoiceMicReleased(self) end, PRESS_TIME_OUT)
    end
end

local function OnClickMicAll(self)
    if TeamSystem:IsInTeam() then
        if GVoiceSDKSystem.bJoinLobbyTeamRoomSucess then
            if not GVoiceSDKSystem:CheckMicEnable() then
                CloseMicPanel(self, Collapsed)
                return
            end
            GVoiceSDKSystem:EnableMic(true)
        else
            GVoiceSDKSystem:JoinLobbyTeamRoom()
        end
    end
    OnMicSelectEffect(self, MICALL)
    SetMicBtnBrush(self,  UIResourceDef.LOBBY_VOICE_MIC_ICON[MICALL])
    SetBtnText(self, self.pWidgetRef.txtMic ,MICALL)
    CloseMicPanel(self, Collapsed)
    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("TAKE_EFFECT_IN_DUNGEON"))
end

local function OnClickMicTeam(self)
    if TeamSystem:IsInTeam() then
        if GVoiceSDKSystem.bJoinLobbyTeamRoomSucess then
            if not GVoiceSDKSystem:CheckMicEnable() then
                CloseMicPanel(self, Collapsed)
                return
            end
            GVoiceSDKSystem:EnableMic(true)
        else
            GVoiceSDKSystem:JoinLobbyTeamRoom()
        end
    else
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("TAKE_EFFECT_IN_TEAM"))
    end
    OnMicSelectEffect(self, MICTEAM)
    SetMicBtnBrush(self,  UIResourceDef.LOBBY_VOICE_MIC_ICON[MICTEAM])
    SetBtnText(self, self.pWidgetRef.txtMic ,MICTEAM)
    CloseMicPanel(self, Collapsed)
end

local function OnClickMicNo(self)
    OnMicSelectEffect(self, MICNO)
    SetMicBtnBrush(self,  UIResourceDef.LOBBY_VOICE_MIC_ICON[MICNO])
    SetBtnText(self, self.pWidgetRef.txtMic ,MICNO)
    CloseMicPanel(self, Collapsed)
    if GVoiceSDKSystem.bJoinLobbyTeamRoomSucess then
        GVoiceSDKSystem:EnableMic(false)
    end
end

local function OnClickPressAll(self)
    OnMicSelectEffect(self, PRESSALL)
    SetMicBtnBrush(self,  UIResourceDef.LOBBY_VOICE_MIC_ICON[PRESSALL])
    SetBtnText(self, self.pWidgetRef.txtMic ,PRESSALL)
    CloseMicPanel(self, Collapsed)
    GVoiceSDKSystem:EnableMic(false)
    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("TAKE_EFFECT_IN_DUNGEON"))
end

local function OnClickPressTeam(self)
    OnMicSelectEffect(self, PRESSTEAM)
    SetMicBtnBrush(self,  UIResourceDef.LOBBY_VOICE_MIC_ICON[PRESSTEAM])
    SetBtnText(self, self.pWidgetRef.txtMic ,PRESSTEAM)
    CloseMicPanel(self, Collapsed)
    GVoiceSDKSystem:EnableMic(false)
    if TeamSystem:IsInTeam() then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("TAKE_EFFECT_IN_DUNGEON"))
    else
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("TAKE_EFFECT_IN_TEAM"))
    end
end

local function OnClickSpeakerAll(self)
    GVoiceSDKSystem:EnableSpeaker(true)
    OnSpeakSelectEffect(self, SPEAKALL)
    SetSpeakerBtnBrush(self, UIResourceDef.LOBBY_VOICE_SPEAKER_ICON[SPEAKALL])
    SetBtnText(self, self.pWidgetRef.txtSpeaker ,SPEAKALL)
    CloseSpeakerPanel(self, Collapsed)
    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("TAKE_EFFECT_IN_DUNGEON"))
end

local function OnClickSpeakerTeam(self)
    if TeamSystem:IsInTeam() then
        if GVoiceSDKSystem.bJoinLobbyTeamRoomSucess then
            GVoiceSDKSystem:EnableSpeaker(true)
        else
            GVoiceSDKSystem:JoinLobbyTeamRoom()
        end
    else
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("TAKE_EFFECT_IN_TEAM"))
    end
    OnSpeakSelectEffect(self, SPEAKTEAM)
    SetSpeakerBtnBrush(self, UIResourceDef.LOBBY_VOICE_SPEAKER_ICON[SPEAKTEAM])
    SetBtnText(self, self.pWidgetRef.txtSpeaker ,SPEAKTEAM)
    CloseSpeakerPanel(self, Collapsed)
end

local function OnClickSpeakerNo(self)
    OnSpeakSelectEffect(self, SPEAKNO)
    SetSpeakerBtnBrush(self, UIResourceDef.LOBBY_VOICE_SPEAKER_ICON[SPEAKNO])
    SetBtnText(self, self.pWidgetRef.txtSpeaker ,SPEAKNO)
    CloseSpeakerPanel(self, Collapsed)
    if GVoiceSDKSystem.bJoinLobbyTeamRoomSucess then
        GVoiceSDKSystem:EnableSpeaker(false)
    end
end


local function InitDefaultOption(self)
    local nDefaultMicOption = GVoiceOpCtrlHelper.GetCurrentMicOp()
    self.nCurrentMicOp = nDefaultMicOption
    local nDefaultSpeakerOption = GVoiceOpCtrlHelper.GetCurrentSpeakerOp()
    self.nCurrentSpeakerOp = nDefaultSpeakerOption
    SetMicBtnBrush(self, UIResourceDef.LOBBY_VOICE_MIC_ICON[nDefaultMicOption])
    SetSpeakerBtnBrush(self, UIResourceDef.LOBBY_VOICE_SPEAKER_ICON[nDefaultSpeakerOption])
    SetBtnText(self, self.pWidgetRef.txtMic ,nDefaultMicOption)
    SetBtnText(self, self.pWidgetRef.txtSpeaker ,nDefaultSpeakerOption)
    OnMicSelectEffect(self, nDefaultMicOption)
    OnSpeakSelectEffect(self, nDefaultSpeakerOption)
end



function ULLobbyVoiceCtrl:OnLoad()
    local pWidgetRef = self.pWidgetRef
    MICPANNELOPEND = false
    SPEAKERPANNELOPEND = false
    self.tbSpeakerSelectEffect = {}
    self.tbMicSelectEffect = {}

    InitSpeakerSelectEffect(self, SPEAKALL,     CreateEffectWidgetTable(pWidgetRef.btnSpeakerAll, pWidgetRef.imgSpeakerAll, pWidgetRef.txtSpeakerAll))
    InitSpeakerSelectEffect(self, SPEAKTEAM,    CreateEffectWidgetTable(pWidgetRef.btnSpeakerTeam, pWidgetRef.imgSpeakerTeam, pWidgetRef.txtSpeakerTeam))
    InitSpeakerSelectEffect(self, SPEAKNO,      CreateEffectWidgetTable(pWidgetRef.btnSpeakerNo, pWidgetRef.imgSpeakerNo, pWidgetRef.txtSpeakerNo))
    
    InitMicSelectEffect(self, MICALL,       CreateEffectWidgetTable(pWidgetRef.btnMicAll, pWidgetRef.imgMicAll, pWidgetRef.txtMicAll))
    InitMicSelectEffect(self, MICTEAM,      CreateEffectWidgetTable(pWidgetRef.btnMicTeam, pWidgetRef.imgMicTeam, pWidgetRef.txtMicTeam))
    InitMicSelectEffect(self, MICNO,        CreateEffectWidgetTable(pWidgetRef.btnMicNo, pWidgetRef.imgMicNo, pWidgetRef.txtMicNo))
    InitMicSelectEffect(self, PRESSALL,     CreateEffectWidgetTable(pWidgetRef.btnPressAll, pWidgetRef.imgPressAll, pWidgetRef.txtPressAll))
    InitMicSelectEffect(self, PRESSTEAM,    CreateEffectWidgetTable(pWidgetRef.btnPressTeam, pWidgetRef.imgPressTeam, pWidgetRef.txtPressTeam))

    pWidgetRef.bdrSpeaker:SetVisibility(Collapsed)
    pWidgetRef.bdrMic:SetVisibility(Collapsed)
    pWidgetRef.bdrMicPress:SetVisibility(Collapsed)
    InitDefaultOption(self)
end

function ULLobbyVoiceCtrl:OnShow()

end

function ULLobbyVoiceCtrl:OnBindEvent(EventHelper)
    local Helper = self.EventHelper
    local pWidgetRef = self.pWidgetRef
    Helper:RegisterCppDelegate(pWidgetRef.btnSpeaker.OnClicked,     self, OnClickSpeakerPanel)
    Helper:RegisterCppDelegate(pWidgetRef.btnMic.OnClicked,         self, OnClickMicPanel)
    Helper:RegisterCppDelegate(pWidgetRef.btnMic.OnPressed,         self, OnVoiceMicPressed)
    Helper:RegisterCppDelegate(pWidgetRef.btnMic.OnReleased,        self, OnVoiceMicReleased)
    Helper:RegisterCppDelegate(pWidgetRef.btnMicAll.OnClicked,      self, OnClickMicAll)
    Helper:RegisterCppDelegate(pWidgetRef.btnMicTeam.OnClicked,     self, OnClickMicTeam)
    Helper:RegisterCppDelegate(pWidgetRef.btnMicNo.OnClicked,       self, OnClickMicNo)
    Helper:RegisterCppDelegate(pWidgetRef.btnPressAll.OnClicked,     self, OnClickPressAll)
    Helper:RegisterCppDelegate(pWidgetRef.btnPressTeam.OnClicked,    self, OnClickPressTeam)

    Helper:RegisterCppDelegate(pWidgetRef.btnSpeakerAll.OnClicked,  self, OnClickSpeakerAll)
    Helper:RegisterCppDelegate(pWidgetRef.btnSpeakerTeam.OnClicked, self, OnClickSpeakerTeam)
    Helper:RegisterCppDelegate(pWidgetRef.btnSpeakerNo.OnClicked,   self, OnClickSpeakerNo)

end

return ULLobbyVoiceCtrl