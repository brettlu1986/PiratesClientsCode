local luaclass          = require ("luaclass")
local PrefabBase        = require("PrefabBase")
local UPSettingBase     = luaclass("UPSettingBase", PrefabBase)
local SaveGameDef       = require("SaveGameDef")
local L10N              = require("L10N")
local UISetUtils        = require("UISetUtils")
local NetworkManager    = dynamic_require("NetworkManager")
local UIManager         = require("UIManager")
local UIDef             = require("UIDef")
local UIUtils           = require("UIUtils")
local SettingIni        = require("SettingIni")
local UIDialogQuitDungeonHelper = require("UIDialogQuitDungeonHelper")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local SettingSystem = require("SettingSystem")

local SaveValueToSldValue = nil

local BASESETTINGS = {
    [SaveGameDef.SETTING_MUSIC] = {
        fnSet = function(self, pSaveGameMgr, bValue)
            local Checked, Unchecked = ECheckBoxState.Checked, ECheckBoxState.Unchecked
            self.pWidgetRef.cbnMusic:SetCheckedState(bValue == true and Checked or Unchecked)
        end,
    },
    [SaveGameDef.SETTING_SOUND] = {
        fnSet = function(self, pSaveGameMgr, bValue)
            local Checked, Unchecked = ECheckBoxState.Checked, ECheckBoxState.Unchecked
            self.pWidgetRef.cbnSound:SetCheckedState(bValue == true and Checked or Unchecked)
        end,        
    },
    [SaveGameDef.SETTING_HEADINFO] = {
        fnSet = function(self, pSaveGameMgr, bValue)
            local Checked, Unchecked = ECheckBoxState.Checked, ECheckBoxState.Unchecked
            self.pWidgetRef.cbnHeadInfo:SetCheckedState(bValue == true and Checked or Unchecked)
        end,
    },
    [SaveGameDef.SETTING_COMMONINPUT] = {
        fnSet = function(self, pSaveGameMgr, nValue)
            local pWidgetRef = self.pWidgetRef
            local txtCommonInput = pWidgetRef.txtCommonInput
            local nTextValue = math.floor(nValue * 100)
            txtCommonInput:SetText(L10N:Format(UISetUtils.GetL10NTextByKey(txtCommonInput.Key), nTextValue))
            local nShowValue = SaveValueToSldValue(self, nValue, SaveGameDef.SETTING_AIMINPUT)
            pWidgetRef.prgCommonInput:SetPercent(nShowValue)
            pWidgetRef.sldCommonInput:SetValue(nShowValue)
        end,
        szWidgetName = "sldCommonInput",
        nMin = SettingIni.tbBase.nCommonInputScaleMin,
        nMax = SettingIni.tbBase.nCommonInputScaleMax,
        nStep= SettingIni.tbBase.nCommonInputScaleStep,      
        nStepSize = 0,  
    },
    [SaveGameDef.SETTING_AIMINPUT] = {
        fnSet = function(self, pSaveGameMgr, nValue)
            local pWidgetRef = self.pWidgetRef
            local txtAimInput = pWidgetRef.txtAimInput
            local nTextValue = math.floor(nValue * 100)
            txtAimInput:SetText(L10N:Format(UISetUtils.GetL10NTextByKey(txtAimInput.Key), nTextValue))
            local nShowValue = SaveValueToSldValue(self, nValue, SaveGameDef.SETTING_AIMINPUT)
            pWidgetRef.prgAimInput:SetPercent(nShowValue)
            pWidgetRef.sldAimInput:SetValue(nShowValue)
        end,
        szWidgetName = "sldAimInput",
        nMin = SettingIni.tbBase.nAimInputScaleMin,
        nMax = SettingIni.tbBase.nAimInputScaleMax,
        nStep= SettingIni.tbBase.nAimInputScaleStep,
        nStepSize = 0,
    }
}

UPSettingBase.pSaveGameMgr = nil

local function SldValueToSaveValue(self, nValue, szKey)
    local tbSetting = BASESETTINGS[szKey]
    return (tbSetting.nMax - tbSetting.nMin) * nValue + tbSetting.nMin
end

SaveValueToSldValue = function(self, nValue, szKey)
    local tbSetting = BASESETTINGS[szKey]   
    return (nValue - tbSetting.nMin) / (tbSetting.nMax - tbSetting.nMin)       
end

local function InitSldWidget(self)
    for k, v in pairs(BASESETTINGS) do
        if v.szWidgetName then
            local pWidgetRef = self.pWidgetRef[v.szWidgetName]
            local nStep = (v.nMax - v.nMin) / v.nStep
            local nStepSize = 1 / nStep
            v.nStepSize = tonumber(string.format("%.2f", nStepSize))
            pWidgetRef:SetStepSize(nStepSize)  

        end
    end    
end

local function InitInterface(self)
    InitSldWidget(self)

    local pSaveGameMgr = self.pSaveGameMgr
    local pWidgetRef = self.pWidgetRef
    for k, v in pairs(BASESETTINGS) do
        local value = SettingSystem:GetSubBaseSettingValue(pSaveGameMgr, k)
        v.fnSet(self, pSaveGameMgr, value)
    end

    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    if bIsInDungeon then
        pWidgetRef.txtQuit:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_BATTLE_QUIT"))
    else
        pWidgetRef.txtQuit:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_SETTING_RETURN"))
    end    
end

local function SetSubBaseSetting(self, szKey, value)
    local pSaveGameMgr = self.pSaveGameMgr
    SettingSystem:SetSubBaseSettingValue(pSaveGameMgr, szKey, value)
    BASESETTINGS[szKey].fnSet(self, pSaveGameMgr, value)
end

local function OnClickMusic(self)
    local bPlay = self.pWidgetRef.cbnMusic:IsChecked()
    SetSubBaseSetting(self, SaveGameDef.SETTING_MUSIC, bPlay)
end

local function OnClickSound(self)
    local bPlay = self.pWidgetRef.cbnSound:IsChecked()
    SetSubBaseSetting(self, SaveGameDef.SETTING_SOUND, bPlay)
end

local function OnClickHeadInfo(self)
    local bShow = self.pWidgetRef.cbnHeadInfo:IsChecked()
    SetSubBaseSetting(self, SaveGameDef.SETTING_HEADINFO, bShow)
end

local function SetInputScale(self, szKey, pWidgetRef, nValue)
    local tbSetting = BASESETTINGS[szKey]

    local nCurValue = pWidgetRef:GetValue()
    -- 四舍五入
    nCurValue  = math.floor(nCurValue * 100 + 0.5) / 100    
    if nValue ~= 0 then    
        nCurValue = nCurValue + nValue * tbSetting.nStepSize
        nCurValue = math.min(nCurValue, 1)
        nCurValue = math.max(nCurValue, 0)
        pWidgetRef:SetValue(nCurValue)
    end

    nCurValue = SldValueToSaveValue(self, nCurValue, szKey)
    SetSubBaseSetting(self, szKey, nCurValue)
end

local function OnClickCommonInput(self)
    SetInputScale(self, SaveGameDef.SETTING_COMMONINPUT, self.pWidgetRef.sldCommonInput, 0)
end

local function OnClickAimInput(self)
    SetInputScale(self, SaveGameDef.SETTING_AIMINPUT, self.pWidgetRef.sldAimInput, 0)
end

local function OnClickCommonInputLess(self)
    SetInputScale(self, SaveGameDef.SETTING_COMMONINPUT, self.pWidgetRef.sldCommonInput, -1)
end

local function OnClickCommonInputAdd(self)
    SetInputScale(self, SaveGameDef.SETTING_COMMONINPUT, self.pWidgetRef.sldCommonInput, 1)
end

local function OnClickAimInputLess(self)
    SetInputScale(self, SaveGameDef.SETTING_AIMINPUT, self.pWidgetRef.sldAimInput, -1)
end

local function OnClickAimInputAdd(self)
    SetInputScale(self, SaveGameDef.SETTING_AIMINPUT, self.pWidgetRef.sldAimInput, 1)
end

local function OnClickQuit(self)
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    if bIsInDungeon then
        local tbGameState = BattleGameModeSystem:GetGameState()
        local nQuitDungeonDialogType = tbGameState.rGameStateBaseInfo.nQuitDungeonType
        local bCanQuit = tbGameState.rGameStateBaseInfo.bCanQuit

        if bCanQuit then
            local szTitle = UIDialogQuitDungeonHelper:GetDungeonQuitDialogTitle(nQuitDungeonDialogType)
            local szMessage = UIDialogQuitDungeonHelper:GetDungeonQuitDialogMessage(nQuitDungeonDialogType)
            if szTitle ~= nil and szMessage ~= nil then
                local funQuit = function()
                    BattleGameModeSystem:RequestQuitDungeon(BattleGameModeSystem.QUIT_REASON.QUIT_BUTTON)
                end
                local funCancel = function()
                    UIManager:CloseWnd(UIDef.UI_DIALOG_BOARD)
                end
                UIUtils.ShowChoiceDialog(szTitle, szMessage, funQuit, funCancel)
            else
                logwarning("UIBattleSettings:OnClickedBtnExitDungeon failed. nQuitDungeonDialogType:", nQuitDungeonDialogType, ". szTitle:", szTitle, "; szMessage:", szMessage, ". Please override BattleGameMode:GetQuitDungeonDialogType function") 
            end        
        else
            local szLimitMessage = UIDialogQuitDungeonHelper:GetDungeonQuitDialogLimitMessage(nQuitDungeonDialogType)
            if szLimitMessage then
                UIUtils.ShowToast(szLimitMessage)
            else
                logwarning("UIBattleSettings:OnClickedBtnExitDungeon Cannot quit. But missing limit message. nQuitDungeonDialogType", nQuitDungeonDialogType) 
            end
        end        
    else
        local HubServerProxy = NetworkManager:GetHubServerProxy()
        HubServerProxy:Disconnect()	
    end    
end

function UPSettingBase:OnCreate()
    self.pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
end

function UPSettingBase:OnShow()
    InitInterface(self)    
end

function UPSettingBase:OnDestroy()
    self.pSaveGameMgr:Save()
    self.pSaveGameMgr = nil
end

function UPSettingBase:OnLoad()
    
end

function UPSettingBase:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.cbnMusic.OnCheckStateChanged,    self, OnClickMusic)
    EventHelper:RegisterCppDelegate(pWidgetRef.cbnSound.OnCheckStateChanged,    self, OnClickSound)
    EventHelper:RegisterCppDelegate(pWidgetRef.cbnHeadInfo.OnCheckStateChanged, self, OnClickHeadInfo)
    EventHelper:RegisterCppDelegate(pWidgetRef.sldCommonInput.OnValueChanged,   self, OnClickCommonInput)
    EventHelper:RegisterCppDelegate(pWidgetRef.sldAimInput.OnValueChanged,      self, OnClickAimInput)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnCommonInputLess.OnClicked,    self, OnClickCommonInputLess)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnCommonInputAdd.OnClicked,     self, OnClickCommonInputAdd)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAimInputLess.OnClicked,       self, OnClickAimInputLess)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAimInputAdd.OnClicked,        self, OnClickAimInputAdd)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnQuit.OnClicked,               self, OnClickQuit)
end

return UPSettingBase