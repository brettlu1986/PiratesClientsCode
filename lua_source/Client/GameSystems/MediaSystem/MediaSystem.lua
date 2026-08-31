-- local UIDef           = require("UIDef")
local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef  = require("ClientEventDef")
local EventManager    = require("EventManager")
local SoundManager    = require("SoundManager")
local UIManager       = require("UIManager")
local UEActorHelper   = require("UEActorHelper")
local MediaDataTable  = require("MediaDataTable")

local MediaSystem = {}

MediaSystem.tbEventHelper          = nil
MediaSystem.pUEMediaPlayer         = nil
MediaSystem.pUEMediaPlayerComp     = nil
MediaSystem.MediaPlayerEndDelegate = nil
MediaSystem.szPlayWndName          = nil

local szMediaPlayerClass = "/Game/Game/OtherObject/MediaPlayer/BP_MediaPlayer.BP_MediaPlayer_C"

local function DestroyMedia(self)
    if self.MediaPlayerEndDelegate then
        self.EventHelper:UnregisterCppDelegate(self.MediaPlayerEndDelegate)
        self.MediaPlayerEndDelegate = nil
    end
    if self.pUEMediaPlayer then
        UEActorHelper:DestroyActor(self.pUEMediaPlayer)
        self.pUEMediaPlayer = nil
        self.pUEMediaPlayerComp = nil
    end
end

function MediaSystem:Init()
    self.EventHelper = SelfEventHelper()
end

function MediaSystem:Uninit()
    DestroyMedia(self)
    self.EventHelper = nil
end

local function OnCloseMedia(self)
    log("call close media")
    self.pUEMediaPlayerComp:StopMedia()
    DestroyMedia(self)

    EventManager:OnFireEvent(ClientEventDef.EV_VIDEO_CLOSED)
    SoundManager:PauseBackgroundMusic(false)
    local szPlayWndName = self.szPlayWndName
    if szPlayWndName then
        UIManager:CloseWnd(szPlayWndName)
        self.szPlayWndName = nil
    end
end

function MediaSystem:PlayMedia(nId, szWndName)
    -- local PerformanceLevel = RenderExtendBlueprintFunctions.GetDevicePerformanceLevel()
    -- if PerformanceLevel <= 0 then
    --     logerror("Play media, but device performance level is not reach the minimum requirement")
    --     return false
    -- end

    local tbMediaData = MediaDataTable:GetTemplate(nId)
    if not tbMediaData or not tbMediaData.szVideoPath then
        logerror("Play media, can not find Media id:", nId)
        return false
    end

    local BPMediaPlayer = szMediaPlayerClass:load()
    if not BPMediaPlayer then
        logerror("play media, but bp load failed")
        return false
    end

    local SpawnTransform = Transform{
        Translation = Vector{X = 0, Y = 0, Z = 0}
    }

    log("play media: spawn actor: ", szMediaPlayerClass)
    local pUEMediaPlayer = EngineExtActorShell.SpawnActorForScript(GWorld, BPMediaPlayer, SpawnTransform, nil)
    if not pUEMediaPlayer then
        logerror("play media, but spawn actor failed")
        return false
    end

    local pMeidaPlayerComponent = pUEMediaPlayer.MediaPlayer
    if not pMeidaPlayerComponent:PlayMedia(tbMediaData.szVideoPath) then
        logerror("play media, but play failed", tbMediaData.szVideoPath)
        return false
    end

    self.pUEMediaPlayer      = pUEMediaPlayer
    self.pUEMediaPlayerComp  = pMeidaPlayerComponent
    self.MediaPlayerEndDelegate = self.EventHelper:RegisterCppDelegate(pMeidaPlayerComponent.MediaPlayer.OnEndReached, self, OnCloseMedia)
    if szWndName then
        self.szPlayWndName = szWndName
        UIManager:OpenWnd(szWndName, {nId = nId})
    end 
    SoundManager:PauseBackgroundMusic(true)

    return true
end

function MediaSystem:CloseMedia()
    if self.pUEMediaPlayer then
        OnCloseMedia(self)
    end
end

return MediaSystem