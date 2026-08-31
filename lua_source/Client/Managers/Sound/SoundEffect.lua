local luaclass = require("luaclass")
local SoundBase = require("SoundBase")
local SoundEffect = luaclass("SoundEffect", SoundBase)

local SoundEffectData = require("SoundEffectData")
local StringUtil = require("StringUtil")

local ResourceManager = require("ResourceManager")

SoundEffect.nAudioDeviceHandle = nil
SoundEffect.nAudioComponentID = nil

-- 如果有需求可以开出去，暂时写死
SoundEffect.fFadeDuration = 0
SoundEffect.fFadeVolumeLevel = 0.0

SoundEffect.AsyncLoadHandle = nil

local function ClearLoadHandle(self)
    if self.AsyncLoadHandle then
        ResourceManager:CancelLoadAsync(self.AsyncLoadHandle)
        self.AsyncLoadHandle = nil
    end
end

function SoundEffect:Play()
    local DataTemplate = SoundEffectData:GetTemplate(self.nID)
    if(DataTemplate == nil) then
        logerror("SoundEffect create failed, cannot find nID", self.nID)
        return false
    end
    if(StringUtil.IsEmptyString(DataTemplate.szResourcePath)) then
        logwarning("SoundEffect Play failed, szResourcePath is nil, nID = ", DataTemplate.nID)
        return false
    end

    local fnLoadAsyncCallback = function(szAssetName, pObject, nHandle)
        ClearLoadHandle(self)

        local bRet = false
        bRet , self.nAudioDeviceHandle, self.nAudioComponentID, self.nDuration = 
            ClientShell.GetClient(GWorld):GetSoundShell():PlaySound2D(pObject, self.bOneShot, self.fFadeDuration, true)
        if not bRet then
            log("try to play sound effect " .. szAssetName .. " fail...")
        end
    end -- end fnCallback

    self.AsyncLoadHandle = ResourceManager:LoadAsync(DataTemplate.szResourcePath, fnLoadAsyncCallback, false)
    
    log("SoundEffect:Play", self.nID)
    return true
end

function SoundEffect:Stop()
    ClearLoadHandle(self)
    --self:UnbindStopEvent()
    if self.nAudioDeviceHandle and self.nAudioComponentID then
        ClientShell.GetClient(GWorld):GetSoundShell():StopSound2D(self.nAudioDeviceHandle, self.nAudioComponentID, self.fFadeDuration, self.fFadeVolumeLevel, true)
        log("SoundEffect:Stop", self.nID)
    end
end

function SoundEffect:OnDestroy()
    ClearLoadHandle(self)

    if self.nAudioDeviceHandle and self.nAudioComponentID then
        ClientShell.GetClient(GWorld):GetSoundShell():StopSound2D(self.nAudioDeviceHandle, self.nAudioComponentID, 0, 0, true)
        self.nAudioDeviceHandle = nil
        self.nAudioComponentID = nil
    end

    SoundEffect.super.OnDestroy(self)
    log("SoundEffect:OnDestroy", self.nID)
end

return SoundEffect
