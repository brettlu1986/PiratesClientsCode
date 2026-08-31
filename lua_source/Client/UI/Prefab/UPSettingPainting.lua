local luaclass          = require ("luaclass")
local PrefabBase        = require("PrefabBase")
local UPSettingPainting = luaclass("UPSettingPainting", PrefabBase)
local SaveGameDef       = require("SaveGameDef")
local UISetUtils        = require("UISetUtils")
local UIResourceDef     = require("UIResourceDef")
local SettingSystem     = require("SettingSystem")

UPSettingPainting.nCurLevel = 1
UPSettingPainting.pSaveGameMgr = nil
UPSettingPainting.pRenderSettingManager = nil

local MAX_QUALITY_LEVEL = 5
local UNSELECT_BTN_RES = "PaperSprite'/Game/UI/Textures/UI_GameSet/Frames/Spr_SetNormal.Spr_SetNormal'"
local SELECT_BTN_RES = "PaperSprite'/Game/UI/Textures/UI_GameSet/Frames/Spr_SetPressed_02.Spr_SetPressed_02'"

local PAINTINGQUALITYSETTING = {
    -- 阴影效果
    [SaveGameDef.SETTING_SHADOWQUALITY] = "ShadowQuality",
    -- 特效质量
    [SaveGameDef.SETTING_EFFECTQUALITY] = "EffectQuality", 
    -- 植被密度
    [SaveGameDef.SETTING_FOLIAGEQUALITY] = "FoliageQuality",
    -- 背景虚化
    [SaveGameDef.SETTING_DEPTHOFFIELD] = "DepthOfField",
    -- 光晕
    [SaveGameDef.SETTING_BLOOM] = "Bloom",
    -- 加载距离
    [SaveGameDef.SETTING_VIEWDISTANCEQUALITY] = "ViewDistanceQuality",
}

local DEVICEDISABLED = {
    {
        [SaveGameDef.SETTING_DEPTHOFFIELD]=1,
        [SaveGameDef.SETTING_BLOOM]=1,
    },
}

local function SetCurLevel(self, nLevel, bSetting)
    self.nCurLevel = nLevel

    -- refresh button
    local pWidgetRef = self.pWidgetRef
    for i = 1, MAX_QUALITY_LEVEL do
        local btnSetting = pWidgetRef["btnSetting"..i]
        local szRes = nLevel == i and SELECT_BTN_RES or UNSELECT_BTN_RES
        UISetUtils.SetButtonBrushRes(btnSetting, szRes:load())
    end

    if bSetting then
        SettingSystem:SetPaintingQuality(self.pRenderSettingManager, self.pSaveGameMgr, nLevel) 
    end
end

local function SetSubSetting(self, szKey, value, bSetting)
    local szName = PAINTINGQUALITYSETTING[szKey]
    local nMaxQuality = SettingSystem:GetSubPaintingMaxQuality(szKey)
    local pWidgetRef = self.pWidgetRef
    if nMaxQuality ~= nil then
        for i = 1, nMaxQuality do
            local btnSubSetting = pWidgetRef["btn"..szName..i]
            local szRes = value == i and SELECT_BTN_RES or UNSELECT_BTN_RES
            UISetUtils.SetButtonBrushRes(btnSubSetting, szRes:load())    
            local txtSubSetting = pWidgetRef["txt"..szName..i]
            local color = value == i and UIResourceDef.COLOR.BLUE2.SLATE_COLOR or UIResourceDef.COLOR.WHITE.SLATE_COLOR   
            txtSubSetting:SetColorAndOpacity(color)     
        end
    else
        local cbSubSetting = pWidgetRef["cbn"..szName]
        cbSubSetting:SetCheckedState(value and ECheckBoxState.Checked or ECheckBoxState.Unchecked)
    end

    -- 判断是否切换为自定义
    if self.nCurLevel ~= MAX_QUALITY_LEVEL then
        local defaultvalue = SettingSystem:GetSubPaintingQuality(self.pRenderSettingManager, self.pSaveGameMgr, szKey, self.nCurLevel)
        if defaultvalue ~= nil and defaultvalue ~= value then
            SetCurLevel(self, MAX_QUALITY_LEVEL, true)
        end    
    end
    if bSetting then
        SettingSystem:SetSubPaintingQuality(self.pRenderSettingManager, self.pSaveGameMgr, szKey, value, self.nCurLevel, true)
    end
end

local function LoadDefaultSubSetting(self)
    local tbSubQuality = SettingSystem:LoadSubPaintingQuality(self.pRenderSettingManager, self.pSaveGameMgr, self.nCurLevel)
    for k, v in pairs(tbSubQuality) do
        SetSubSetting(self, k, v, false)
    end
end

local function LoadDefaultSetting(self)
    local nLevel = SettingSystem:LoadPaintingQuality(self.pRenderSettingManager, self.pSaveGameMgr)
    SetCurLevel(self, nLevel)
end

local function SetDisableFunc(self)
    local pWidgetRef = self.pWidgetRef
    local nQuality = self.pRenderSettingManager:GetDeviceDefualtQuality()
    local tbDeviceDisabled = DEVICEDISABLED[nQuality + 1]
    if tbDeviceDisabled ~= nil then
        for key, value in pairs(tbDeviceDisabled) do
            local szName = PAINTINGQUALITYSETTING[key]
            local nMaxQuality = SettingSystem:GetSubPaintingMaxQuality(key)
            if nMaxQuality ~= nil then
                for i = 1, nMaxQuality do
                    local btnSubSetting = pWidgetRef["btn"..szName..i]
                    btnSubSetting:SetIsEnabled(false)
                end
            else
                local cbSubSetting = pWidgetRef["cbn"..szName]
                cbSubSetting:SetIsEnabled(false)
            end    
        end
    end 
end

local function OnClickSetting(self, nIndex)
    SetCurLevel(self, nIndex, true)
    LoadDefaultSubSetting(self)
end

local function OnClickSubSetting(self, szKey, value)
    SetSubSetting(self, szKey, value, true)
end

function UPSettingPainting:OnCreate()
    self.pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    self.pRenderSettingManager = ClientShell.GetClient(GWorld):GetRenderSettingsManager()    
end

function UPSettingPainting:OnShow()
    LoadDefaultSetting(self)
    LoadDefaultSubSetting(self)
    SetDisableFunc(self)
end

function UPSettingPainting:OnDestroy()
    self.pSaveGameMgr:Save()
    self.pSaveGameMgr = nil    
    self.pRenderSettingManager = nil
end

function UPSettingPainting:OnLoad()
end

function UPSettingPainting:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef

    for i = 1, MAX_QUALITY_LEVEL do
        EventHelper:RegisterCppDelegate(pWidgetRef["btnSetting"..i].OnClicked, self, function() OnClickSetting(self, i) end) 
    end

    for k, v in pairs(PAINTINGQUALITYSETTING) do
        local nMaxQuality = SettingSystem:GetSubPaintingMaxQuality(k)
        if nMaxQuality ~= nil then
            for i = 1, nMaxQuality do
                local btnSubSetting = pWidgetRef["btn"..v..i]
                EventHelper:RegisterCppDelegate(btnSubSetting.OnClicked, self, function() OnClickSubSetting(self, k, i) end)                 
            end
        else
            local cbSubSetting = pWidgetRef["cbn"..v]
            EventHelper:RegisterCppDelegate(cbSubSetting.OnCheckStateChanged, self, function()
                OnClickSubSetting(self, k, cbSubSetting:IsChecked())
            end)                        
        end
    end    
end

return UPSettingPainting