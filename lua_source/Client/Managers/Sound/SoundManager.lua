local SoundManager = {}

local DelayTimer = require("DelayTimer")

local tbSoundClass = {}
tbSoundClass["BackgroundMusic"] = require("BackgroundMusic")
tbSoundClass["SoundEffect"] = require("SoundEffect")
tbSoundClass["Sound2D"] = require("Sound2D")

SoundManager.tbSounds = nil
SoundManager.CurrentBackgroundMusic = nil
SoundManager.fBackgroundMusicVolumeMultiplier = 1.0
SoundManager.tbPlayTimerObject = nil
SoundManager.tbStopTimerObject = nil
SoundManager.bPlaySound = true
SoundManager.bPlayMusic = true
SoundManager.ZeroVolumeSound = nil

function SoundManager:Init()
    self.tbSounds = {}
    return true
end

function SoundManager:Uninit()
    log("SoundManager:Uninit")
    self:ClearTimer()
    local nCount = #self.tbSounds
    for i=1,nCount do
        self.tbSounds[i]:OnDestroy()
    end
    self.tbSounds = nil
    self.CurrentBackgroundMusic = nil
end

function SoundManager:StopAll()
    log("SoundManager:StopAll")
    self:ClearTimer()
    local nCount = #self.tbSounds
    for i=1,nCount do
        self.tbSounds[i]:Stop()
        self.tbSounds[i]:OnDestroy()
    end
    self.tbSounds = {}
end

local function NewSound(self, szClassType, nID, bOneShot, tbParams)
    local Class = tbSoundClass[szClassType]
    if(Class == nil) then
        return nil
    end

    local TempSound = Class()

    TempSound.Owner = self
    TempSound:OnCreate(nID, bOneShot, tbParams)
    if(not bOneShot) then
        table.insert(self.tbSounds, TempSound)
    end
    return TempSound
end

function SoundManager:DeleteSound(Sound)
    log("SoundManager: DeleteSound " .. Sound.nID)
    local tbSounds = self.tbSounds
    local nCount = #tbSounds
    for i=1, nCount do
        if(tbSounds[i] == Sound) then
            Sound:OnDestroy()
            table.remove(tbSounds, i)
            break
        end
    end
end

function SoundManager:PlayBackgroundMusic(nID)
    if not (nID and nID > 0) then
        return
    end

    log("[SoundManager] PlayBackgroundMusic ".. nID)
    local bNeedDelay = self.CurrentBackgroundMusic ~= nil and self.bPlayMusic
    self:StopBackgroundMusic()

    local NewMusic = NewSound(self, "BackgroundMusic", nID, false, nil)
    self.CurrentBackgroundMusic = NewMusic
    self:SetBackgroundMusicVolume(self.fBackgroundMusicVolumeMultiplier)

    local fnBackgroundRealStartPlay = function()
        self:ResetSound()
    end

    if(bNeedDelay) then
        local fnFunc = function()
            self.tbPlayTimerObject = nil
            -- 这么写防止在延迟时间内又有新的music进来，如果有则不播了
            if(NewMusic == self.CurrentBackgroundMusic) then
                self.CurrentBackgroundMusic:Play(fnBackgroundRealStartPlay)
            end
        end
        local fFadeDuration = NewMusic.fFadeDuration
        self.tbPlayTimerObject = DelayTimer:DelayRun(fnFunc, fFadeDuration)
    else
        self.CurrentBackgroundMusic:Play(fnBackgroundRealStartPlay)
    end
end

function SoundManager:NewSound2D(nID, bInOneShot)
    if(bInOneShot == nil) then
        bInOneShot = true
    end
    return NewSound(self, "Sound2D", nID, bInOneShot, nil)
end

function SoundManager:PlaySound2D(nID, bInOneShot, nStartTime)
    local Sound2D = self:NewSound2D(nID, bInOneShot)
    Sound2D:Play(nStartTime)
    return Sound2D
end

function SoundManager:PlaySoundEffect(nID, bInOneShot)
    if self.bPlaySound == false then
        log("[SoundManager] PlaySoundEffect, but sound is closed".. nID)
        return
    end

    if(bInOneShot == nil) then
        bInOneShot = true
    end
    local NewMusic = NewSound(self, "SoundEffect", nID, bInOneShot, nil)
    NewMusic:Play()
    return NewMusic
end

function SoundManager:StopBackgroundMusic()
    log("[SoundManager] StopBackgroundMusic ")
    self:ClearTimer()
    local Music = self.CurrentBackgroundMusic
    if(Music) then
        Music:Stop()
        self.CurrentBackgroundMusic = nil
        self:DeleteSound(Music)
    end
end

function SoundManager:PauseBackgroundMusic(bPaused)
    local Music = self.CurrentBackgroundMusic
    if(Music) then
        Music:SetPaused(bPaused)
    end
end

function SoundManager:ClearTimer()
    if(self.tbPlayTimerObject) then
        DelayTimer:ClearTimer(self.tbPlayTimerObject)
        self.tbPlayTimerObject = nil
    end
    if(self.tbStopTimerObject) then
        DelayTimer:ClearTimer(self.tbStopTimerObject)
        self.tbStopTimerObject = nil
    end
end

function SoundManager:ResetSound()
    self:SetPlayMusic(self.bPlayMusic)
    self:SetPlaySound(self.bPlaySound)
end

function SoundManager:SetPlaySound(bPlay)
    self.bPlaySound = bPlay
    if bPlay then
		if self.ZeroVolumeSound  then
			self.ZeroVolumeSound:Stop()
			self.ZeroVolumeSound = nil
		end
    else
        if not self.ZeroVolumeSound then
            local NewMusic = NewSound(self, "SoundEffect", 1000000, false, nil)
            if NewMusic then
                NewMusic:Play()
                self.ZeroVolumeSound = NewMusic
            else
                logerror("SoundManager stop all sound failed: not find zerovolume sound")
            end
        end
    end
end

function SoundManager:SetPlayMusic(bPlay)
    self.bPlayMusic = bPlay
    self:PauseBackgroundMusic(not bPlay)
end

function SoundManager:SetBackgroundMusicVolume(fVolumeMultiplier)
    self.fBackgroundMusicVolumeMultiplier = fVolumeMultiplier
    local Music = self.CurrentBackgroundMusic
    if(Music) then
        Music:SetVolume(fVolumeMultiplier)
    end
end

return SoundManager