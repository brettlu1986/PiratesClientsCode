-----------------------------------------------------
--File Name    : SoundExperienceHelper.lua
--Author       : Song Fuhao
--Create Time  : 2020-09-15
--Description  : 增强音效体验的逻辑Helper
-----------------------------------------------------
local SoundExperienceHelper = {}

local Timer = require("Timer")
local SoundManager = require("SoundManager")
local SoundExperienceDataTable = require("SoundExperienceDataTable")
local BattleExperienceIni = require("BattleExperienceIni")

SoundExperienceHelper.tbSoundInstanceMap = nil
SoundExperienceHelper.tbSoundPlayTimeMap = nil
SoundExperienceHelper.tbSoundWaitList = nil
SoundExperienceHelper.tbCurrentSound = nil
SoundExperienceHelper.tbDelayTimer = nil

local SOUND_PLAYING_DELAY_TIME = BattleExperienceIni.tbSound.nPlayingDelayTime

local PlayHightPrioritySound = nil

local function LOG(...)
    log("[SoundExperienceHelper]", ...)
end

-- 音效播完回调
local function OnSoundPlayingFinished(self)
    LOG("OnSoundPlayingFinished", self.tbCurrentSound:GetID())
    self.tbCurrentSound:UnbindOnPlayingFinished(OnSoundPlayingFinished, self)
    self.tbCurrentSound = nil
    PlayHightPrioritySound(self)
end

-- 实际逻辑播放调用接口
local function PlaySoundInternal(self, tbTemplate)
    local nExpSoundId = tbTemplate.nId
    LOG("PlaySoundInternal", nExpSoundId)
    local tbSound = self.tbSoundInstanceMap[nExpSoundId]
    if not tbSound then
        tbSound = SoundManager:NewSound2D(tbTemplate.nSoundEffectId, false)
        self.tbSoundInstanceMap[nExpSoundId] = tbSound
    end
    tbSound:BindOnPlayingFinished(OnSoundPlayingFinished, self)
    self.tbSoundPlayTimeMap[nExpSoundId] = getseconds()
    self.tbCurrentSound = tbSound
    tbSound:Play()
end

-- 判断音效是否处于CD状态
local function IsSoundInCd(self, tbTemplate)
    local nSoundCd = tbTemplate.nSoundCd
    local nLastPlayTime = self.tbSoundPlayTimeMap[tbTemplate.nId]
    local nCurrentTime = getseconds()
    return nLastPlayTime and (nLastPlayTime + nSoundCd > nCurrentTime)
end

-- 播放高优先级的音效
PlayHightPrioritySound = function(self)
    if not self.tbSoundWaitList then
        return
    end
    if self.tbCurrentSound or self.tbDelayTimer then
        LOG("PlayHightPrioritySound wait...", self.tbCurrentSound, self.tbDelayTimer)
        return
    end
    LOG("PlayHightPrioritySound", t2s(self.tbSoundWaitList))
    local tbHightPriorityTemplate = nil
    for nExpSoundId, tbTemplate in pairs(self.tbSoundWaitList) do
        if not IsSoundInCd(self, tbTemplate) then
            if (not tbHightPriorityTemplate) or (tbTemplate.nPriority >= tbHightPriorityTemplate.nPriority) then
                tbHightPriorityTemplate = tbTemplate
            end
        end
    end
    LOG("self.tbSoundWaitList = nil")
    self.tbSoundWaitList = nil
    if tbHightPriorityTemplate then
        PlaySoundInternal(self, tbHightPriorityTemplate)
    else
        LOG("No sound to play, all in cd.")
    end
end

-- 延迟播放时间结束
local function OnDelayTimeEnd(self)
    LOG("OnDelayTimeEnd")
    self.tbDelayTimer = nil
    PlayHightPrioritySound(self)
end

local function DestroySoundInstance(self)
    for nExpSoundId,tbSound in pairs(self.tbSoundInstanceMap) do
        SoundManager:DeleteSound(tbSound)
    end
    self.tbSoundInstanceMap = nil
end

function SoundExperienceHelper:Init()
    LOG("SoundExperienceHelper:Init")
    self.tbSoundPlayTimeMap = {}
    self.tbSoundInstanceMap = {}
end

function SoundExperienceHelper:Uninit()
    LOG("SoundExperienceHelper:Uninit")
    if self.tbDelayTimer then
        self.tbDelayTimer:Clear()
        self.tbDelayTimer = nil
    end
    self.tbSoundPlayTimeMap = nil
    DestroySoundInstance(self)
end

function SoundExperienceHelper:PlaySound(nExpSoundId)
    local tbTemplate = SoundExperienceDataTable:GetTemplate(nExpSoundId)
    if not tbTemplate then
        logwarning("SoundExperienceHelper PlaySound failed, cannot find nExpSoundId", nExpSoundId)
        return
    end
    if not self.tbSoundWaitList then
        LOG("StartDelayTimer nTime=", SOUND_PLAYING_DELAY_TIME)
        LOG("self.tbSoundWaitList = {}")
        self.tbSoundWaitList = {}
        self.tbDelayTimer = Timer.NewTimerMethod(self, OnDelayTimeEnd, SOUND_PLAYING_DELAY_TIME, false)
    end
    self.tbSoundWaitList[nExpSoundId] = tbTemplate
    LOG("PlaySound", nExpSoundId)
end

return SoundExperienceHelper