local luaclass = require("luaclass")
local SoundBase = require("SoundBase")
local Sound2D = luaclass("Sound2D", SoundBase)

local SoundEffectData = require("SoundEffectData")
local StringUtil = require("StringUtil")
local ResourceManager = require("ResourceManager")
local LuaDelegate = require("LuaDelegate")
local CppDelegate = require("CppDelegate")

Sound2D.pSoundComp = nil
Sound2D.nAsyncLoadHandle = nil
Sound2D.nPrePlayStartTime = nil
Sound2D.tbOnAudioFinished = nil
Sound2D.pOnAudioFinished = nil

local function LOG(self, ...)
    log("[Sound2D]", self:GetID(), ...)
end

local function ClearLoadHandle(self)
    LOG(self, "ClearLoadHandle")
    if self.nAsyncLoadHandle then
        ResourceManager:CancelLoadAsync(self.nAsyncLoadHandle)
        self.nAsyncLoadHandle = nil
    end
end

local function OnAudioFinished(self)
    LOG(self, "OnAudioFinished")
    if self.tbOnAudioFinished then
        self.tbOnAudioFinished:Fire()
    end
    if isvalidhandle(self.pSoundComp) and self.pSoundComp.bAutoDestroy then
        self:OnDestroy()
    end
end

local function TryToBindOnAudioFinished(self)
    if (not self.pOnAudioFinished) and isvalidhandle(self.pSoundComp) then
        LOG(self, "BindOnAudioFinished")
        local szInfo = "Sound2D OnAudioFinished Id=" .. self.nID
        self.pOnAudioFinished = CppDelegate:BindMethod(self.pSoundComp.OnAudioFinished, self, OnAudioFinished, szInfo)
    end
end

local function TryToUnbindOnAudioFinished(self)
    if self.pOnAudioFinished and isvalidhandle(self.pSoundComp) then
        LOG(self, "UnbindOnAudioFinished")
        self.pOnAudioFinished:Unbind()
        self.pOnAudioFinished = nil
    end
end

function Sound2D:OnCreate(...)
    Sound2D.super.OnCreate(self, ...)
    LOG(self, "OnCreate")
    local tbTemplate = SoundEffectData:GetTemplate(self.nID)
    if(tbTemplate == nil) then
        logerror("Sound2D create failed, cannot find nID", self.nID)
        return false
    end
    if(StringUtil.IsEmptyString(tbTemplate.szResourcePath)) then
        logerror("Sound2D create failed, szResourcePath is nil, nID = ", tbTemplate.nID)
        return false
    end
    local fnLoadAsyncCallback = function(szAssetName, pObject, nHandle)
        ClearLoadHandle(self)
        self.pSoundComp = GameplayStatics.CreateSound2D(GWorld, pObject, 1.0, 1.0, 0.0, nil, false, false)
        if self.tbOnAudioFinished or self.bOneShot then
            TryToBindOnAudioFinished(self)
        end
        if self.bOneShot then
            self:SetAutoDestroy(true)
        end
        if self.nPrePlayStartTime then
            self:Play(self.nPrePlayStartTime)
            self.nPrePlayStartTime = nil
        end
    end
    self.nAsyncLoadHandle = ResourceManager:LoadAsync(tbTemplate.szResourcePath, fnLoadAsyncCallback, false)
end

function Sound2D:OnDestroy(...)
    LOG(self, "OnDestroy")
    TryToUnbindOnAudioFinished(self)
    ClearLoadHandle(self)
    if isvalidhandle(self.pSoundComp) then
        if self.pSoundComp.bAutoDestroy and (self.pSoundComp:GetPlayState() == EAudioComponentPlayState.FadingOut) then
            LOG(self, "Delay destroy sound by self.")
        else
            LOG(self, "destroy sound.")
            self.pSoundComp:K2_DestroyComponent(self.pSoundComp)
        end
    end
    self.pSoundComp = nil
    Sound2D.super.OnDestroy(self, ...)
end

function Sound2D:Play(nStartTime)
    nStartTime = nStartTime or 0
    LOG(self, "Play", nStartTime)
    if isvalidhandle(self.pSoundComp) then
        LOG(self, "PlayInternal")
        self.pSoundComp:Play(nStartTime)
    elseif self.nAsyncLoadHandle then
        self.nPrePlayStartTime = nStartTime
    end
end

function Sound2D:Stop()
    LOG(self, "Stop")
    if isvalidhandle(self.pSoundComp) then
        self.pSoundComp:Stop()
    end
end

function Sound2D:FadeOut(nFadeOutDuration, nFadeVolumeLevel, pFadeCurve)
    LOG(self, "FadeOut", nFadeOutDuration, nFadeVolumeLevel, pFadeCurve)
    if isvalidhandle(self.pSoundComp) then
        nFadeOutDuration = nFadeOutDuration or 0
        nFadeVolumeLevel = nFadeVolumeLevel or 0
        pFadeCurve = pFadeCurve or EAudioFaderCurve.Linear
        self.pSoundComp:FadeOut(nFadeOutDuration, nFadeVolumeLevel, pFadeCurve)
    end
end

function Sound2D:SetAutoDestroy(bAutoDestroy)
    LOG(self, "SetAutoDestroy", bAutoDestroy)
    if isvalidhandle(self.pSoundComp) then
        self.pSoundComp.bAutoDestroy = bAutoDestroy
        TryToBindOnAudioFinished(self)
    end
end

function Sound2D:IsPlaying()
    if isvalidhandle(self.pSoundComp) then
        return self.pSoundComp:IsPlaying()
    end
    return false
end

function Sound2D:BindOnPlayingFinished(fnCallback, tbObject)
    if not self.tbOnAudioFinished then
        self.tbOnAudioFinished = LuaDelegate()
        TryToBindOnAudioFinished(self)
    end
    self.tbOnAudioFinished:Bind(fnCallback, tbObject)
end

function Sound2D:UnbindOnPlayingFinished(fnCallback, tbObject)
    if self.tbOnAudioFinished then
        self.tbOnAudioFinished:Unbind(fnCallback, tbObject)
    end
end

return Sound2D
