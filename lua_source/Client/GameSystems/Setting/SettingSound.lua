local luaclass = require("luaclass")
local SettingBase = require("SettingBase")
local SettingSound = luaclass("SettingSound", SettingBase)
local SettingKeyDef = require("SettingKeyDef")
local SoundManager = require("SoundManager")
local AudioUtilityHelper = require("AudioUtilityHelper")
local GVoiceSDKSystem = require("GVoiceSDKSystem")
local LocalKeys = SettingKeyDef.LocalKeys

local ToggleUISoundVolume = AudioUtilityHelper.ToggleUISoundVolume
local ToggleSFXSoundVolume = AudioUtilityHelper.ToggleSFXSoundVolume  

local ALLSOUNDS = {
    [LocalKeys.SFX_SOUND] = LocalKeys.SFX_SOUND_ACTIVATE,
    [LocalKeys.UI_SOUND] = LocalKeys.UI_SOUND_ACTIVATE,
    [LocalKeys.MUSIC] = LocalKeys.MUSIC_SOUND_ACTIVATE,
    [LocalKeys.MIC] = LocalKeys.MIC_VOLUME,
    [LocalKeys.HORN] = LocalKeys.HORN_VOLUME,
}

local SOUNDS = {
    ALLSOUNDS = {
        nKey = LocalKeys.ALL_SOUND 
    },
    SFXSOUNDS = {
        nKey = LocalKeys.SFX_SOUND,
        fnSet = function(nValue)
            log("[setting] set sound volume ", nValue)
            ToggleSFXSoundVolume(nValue, GWorld)
        end,
    },
    UISOUNDS = {
        nKey = LocalKeys.UI_SOUND,
        fnSet = function(nValue)
            log("[setting] set ui sound volume ", nValue)
            ToggleUISoundVolume(nValue, GWorld)
        end,
    },
    MUSIC = {
        nKey = LocalKeys.MUSIC,
        fnSet = function(nValue)
            log("[setting] set music volume ", nValue)
            SoundManager:SetBackgroundMusicVolume(nValue)
            SoundManager:SetPlayMusic(nValue > 0)
        end,
    },
    MIC = {
        bNoRelyOnAll = true,
        nKey = LocalKeys.MIC,
        fnSet = function(nValue)
            log("[setting] set mic volume ", nValue)
            GVoiceSDKSystem:SetMicVolume(nValue)
        end,
    },
    HORN = {
        bNoRelyOnAll = true,
        nKey = LocalKeys.HORN,
        fnSet = function(nValue)
            log("[setting] set horn volume ", nValue)
            GVoiceSDKSystem:SetSpeakerVolume(nValue)
        end,
    }
}

local function GetSetting(self, nKey)
    for k, v in pairs(SOUNDS) do
        if v.nKey == nKey then
            return v
        end
    end    
end

function SettingSound:LoadLocalSetting()
    local nAllSoundValue = self:Get(LocalKeys.ALL_SOUND)
    local bAllSoundActivate = self:GetActivate(LocalKeys.ALL_SOUND)

    for k, v in pairs(SOUNDS) do
        if v.fnSet ~= nil then
            local nKey = v.nKey
            local nValue = self:Get(nKey)
            local bActivate = self:GetActivate(nKey)
            if ALLSOUNDS[nKey] then
                if v.bNoRelyOnAll then
                    v.fnSet(bActivate and nValue or 0)
                else
                    v.fnSet(bAllSoundActivate and bActivate and nAllSoundValue * nValue or 0)
                end
            else
                v.fnSet(nValue)
            end
        end
    end 
end

function SettingSound:Set(nKey, nValue)
    local tbSetting = GetSetting(self, nKey)
    if tbSetting == nil then
        logwarning("SettingSound:Set failed: not find key", nKey)
        return
    end

    local bAllSoundActivate = self:GetActivate(LocalKeys.ALL_SOUND)

    if ALLSOUNDS[nKey] then
        if tbSetting.fnSet ~= nil then
            local nAllSoundValue = self:Get(LocalKeys.ALL_SOUND)
            local bSubSoundActivate = self:GetActivate(nKey)
            if tbSetting.bNoRelyOnAll then
                tbSetting.fnSet(bSubSoundActivate and nValue or 0)
            else
                tbSetting.fnSet(bAllSoundActivate and bSubSoundActivate and nValue * nAllSoundValue or 0)
            end
        end        
    elseif nKey == LocalKeys.ALL_SOUND then
        for k, v in pairs(SOUNDS) do
            local nTempKey = v.nKey
            if ALLSOUNDS[nTempKey] then
                local tbTempSetting = GetSetting(self, nTempKey)
                if tbTempSetting.fnSet ~= nil and not tbTempSetting.bNoRelyOnAll then
                    local nSubSoundValue = self:Get(nTempKey)
                    local bSubSoundActivate = self:GetActivate(nTempKey)
                    tbTempSetting.fnSet(bAllSoundActivate and bSubSoundActivate and nSubSoundValue * nValue or 0)
                end
            end
        end
    elseif tbSetting.fnSet ~= nil then
        tbSetting.fnSet(nValue)
    end
    
    nValue = math.floor(nValue * 100)
    SettingSound.super.Set(self, nKey, nValue)
end

function SettingSound:Get(nKey)
    local nValue = SettingSound.super.Get(self, nKey)
    nValue = nValue / 100
    return nValue
end

function SettingSound:SetActivate(nKey, bActivate)
    local tbSetting = GetSetting(self, nKey)
    if tbSetting == nil then
        logwarning("SettingSound:Set failed: not find key", nKey)
        return
    end

    local nAllSoundValue = self:Get(LocalKeys.ALL_SOUND)

    local nActivateKey
    if ALLSOUNDS[nKey] then
        nActivateKey = ALLSOUNDS[nKey]

        if tbSetting.fnSet ~= nil then
            local nSubSoundValue = self:Get(nKey)
            if tbSetting.bNoRelyOnAll then
                tbSetting.fnSet(bActivate and nSubSoundValue or 0)
            else
                local bAllSoundActivate = self:Get(LocalKeys.ALL_SOUND)
                tbSetting.fnSet(bAllSoundActivate and bActivate and nSubSoundValue * nAllSoundValue or 0)
            end
        end        
    elseif nKey == LocalKeys.ALL_SOUND then
        nActivateKey = LocalKeys.ALL_SOUND_ACTIVATE

        for k, v in pairs(SOUNDS) do
            local nTempKey = v.nKey
            if ALLSOUNDS[nTempKey] then
                local tbTempSetting = GetSetting(self, nTempKey)
                if tbTempSetting.fnSet ~= nil and not tbTempSetting.bNoRelyOnAll then
                    local nTempValue = self:Get(nTempKey)
                    local bTempActivate = self:GetActivate(nTempKey)
                    tbTempSetting.fnSet(bActivate and bTempActivate and nTempValue * nAllSoundValue or 0)
                end
            end
        end
    end
    if nActivateKey ~= nil then
        SettingSound.super.Set(self, nActivateKey, bActivate and 1 or 0)
    end
end

function SettingSound:GetActivate(nKey)
    local nActivateKey
    if ALLSOUNDS[nKey] then
        nActivateKey = ALLSOUNDS[nKey]
    elseif nKey == LocalKeys.ALL_SOUND then
        nActivateKey = LocalKeys.ALL_SOUND_ACTIVATE
    end
    local nValue = SettingSound.super.Get(self, nActivateKey)
    return nValue > 0 
end

return SettingSound