local luaclass = require("luaclass")
local SoundBase = require("SoundBase")
local BackgroundMusic = luaclass("BackgroundMusic", SoundBase)
local StringUtil = require("StringUtil")
local ResourceManager = require("ResourceManager")

local BackgroundMusicDataTable = require("BackgroundMusicDataTable")

BackgroundMusic.nAudioDeviceHandle = nil
BackgroundMusic.nAudioComponentID = nil

-- 如果有需求可以开出去，暂时写死
BackgroundMusic.fFadeDuration = 2.0
BackgroundMusic.fFadeVolumeLevel = 0.0
BackgroundMusic.fVolumeMultiplier = 1.0

BackgroundMusic.AsyncLoadHandle = nil


function BackgroundMusic:Play(fnRealPlayCallback)
    local DataTemplate = BackgroundMusicDataTable:GetTemplate(self.nID)
    if(DataTemplate == nil) then
        return false
    end
    if(StringUtil.IsEmptyString(DataTemplate.szResourcePath)) then
        logwarning("BackgroundMusic Play failed, szResourcePath is nil, nID = ", self.nID)
        return false
    end

    if self.nAudioDeviceHandle and self.nAudioComponentID then
        self:Stop()
    end

    if self.AsyncLoadHandle then
        ResourceManager:CancelLoadAsync(self.AsyncLoadHandle)
        self.AsyncLoadHandle = nil
    end

    local fnLoadAsyncCallback = function(szAssetName, pObject, nHandle)
        self.AsyncLoadHandle = nil
        local bRet = false
        bRet , self.nAudioDeviceHandle, self.nAudioComponentID, self.nDuration = 
            ClientShell.GetClient(GWorld):GetSoundShell():PlaySound2D(pObject, self.bOneShot, self.fFadeDuration, true)
            self:SetVolume(self.fVolumeMultiplier)
            if fnRealPlayCallback then
                fnRealPlayCallback()
            end
        if not bRet then
            log("try to play backgroud music " .. szAssetName .. " fail...")
        end
       
    end -- end fnCallback

    self.AsyncLoadHandle = ResourceManager:LoadAsync(DataTemplate.szResourcePath, fnLoadAsyncCallback, false)
    
    log("BackgroundMusic:Play", self.nID)
    return true
end

function BackgroundMusic:SetPaused(bPaused)
    if self.nAudioDeviceHandle and self.nAudioComponentID then
        ClientShell.GetClient(GWorld):GetSoundShell():SetPaused(self.nAudioDeviceHandle, self.nAudioComponentID, bPaused)
    end
end

function BackgroundMusic:Stop()
    if self.AsyncLoadHandle then
        ResourceManager:CancelLoadAsync(self.AsyncLoadHandle)
        self.AsyncLoadHandle = nil
    end
    if self.nAudioDeviceHandle and self.nAudioComponentID then
        ClientShell.GetClient(GWorld):GetSoundShell():StopSound2D(self.nAudioDeviceHandle, self.nAudioComponentID, self.fFadeDuration, self.fFadeVolumeLevel, true)
        self.nAudioDeviceHandle = nil
        self.nAudioComponentID = nil
        log("BackgroundMusic:Stop", self.nID)
    end
end

function BackgroundMusic:SetVolume(fVolumeMultiplier)
    self.fVolumeMultiplier = fVolumeMultiplier
    local Shell = ClientShell.GetClient(GWorld):GetSoundShell()
    if self.nAudioComponentID then
        local pAudioComponent = Shell:FindComponent(self.nAudioComponentID)
        if(pAudioComponent) then
            pAudioComponent:SetVolumeMultiplier(fVolumeMultiplier)
        end
    end
end

function BackgroundMusic:OnDestroy()
    if self.AsyncLoadHandle then
        ResourceManager:CancelLoadAsync(self.AsyncLoadHandle)
        self.AsyncLoadHandle = nil
    end
    if self.nAudioDeviceHandle and self.nAudioComponentID then
        ClientShell.GetClient(GWorld):GetSoundShell():StopSound2D(self.nAudioDeviceHandle, self.nAudioComponentID, 0, 0, true)
        self.nAudioDeviceHandle = nil
        self.nAudioComponentID = nil
    end
    BackgroundMusic.super.OnDestroy(self)
    log("BackgroundMusic:OnDestroy", self.nID)
end

return BackgroundMusic