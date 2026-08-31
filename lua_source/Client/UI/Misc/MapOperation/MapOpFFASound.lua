-----------------------------------------------------
--File Name    : MapOpFFASound.lua
--Author       : Ran Jie
--Create Time  : 2018-9-12
--Description  : MapOpFFASound
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpFFASound = luaclass("MapOpFFASound",MapOpBase)


--local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ClientEventDef = require("ClientEventDef")
local UIResourceDef = require("UIResourceDef")
local MapObjType = require("MapObjType")
local DelayTimer = require("DelayTimer")
local MapSoundIni = require("MapSoundIni")

local tbSoundIconRes =
{
    [0] = UIResourceDef.FFA_SOUND_SHIP_FIRE,
    [1] = UIResourceDef.FFA_SOUND_SHIP_BE_SHOOTED,
    [2] = UIResourceDef.FFA_SOUND_SHIP_HIT_MOUNTAIN,
    [3] = UIResourceDef.FFA_SOUND_HUMAN_FIRE,
    [4] = UIResourceDef.FFA_SOUND_CARRIER_NOISE,
    [5] = UIResourceDef.FFA_SOUND_FOOT_STEP,
}

local RADIUS = MapSoundIni.tbSoundIni.nShowRadius
local SHOW_TIME = MapSoundIni.tbSoundIni.nShowTime
local INTENSITY =
{
    [1] = SlateColor{ SpecifiedColor = LinearColor{ R = 1, G = 1, B = 1, A = MapSoundIni.tbSoundIni.tbIntensity[1] } },
    [2] = SlateColor{ SpecifiedColor = LinearColor{ R = 1, G = 1, B = 1, A = MapSoundIni.tbSoundIni.tbIntensity[2] } },
    [3] = SlateColor{ SpecifiedColor = LinearColor{ R = 1, G = 1, B = 1, A = MapSoundIni.tbSoundIni.tbIntensity[3] } },
}
local ANGLE_OFFSET = 15
local ANGLE_DIVIDE = 30
local ICON_SIZE = Vector2D{x = 74 * 1.15, Y = 46 * 1.15}
local ORIGIN = {X = 175, Y = 175}

MapOpFFASound.tbSoundObjByIndex = {}
MapOpFFASound.tbSoundObjByUniqueId = {}
MapOpFFASound.tbDelayTimerHandle = {}
MapOpFFASound.nObjIndex = 1
MapOpFFASound.tbTeamMembers = nil


local function HideDelayFunc(self, Obj)
    local nCurrentObjIndex = Obj.tbData.nObjIndex
    local nSoundSourceUniqueID = Obj.tbData.nSoundSourceUniqueID
    self.tbDelayTimerHandle[nCurrentObjIndex] = nil
    self.tbSoundObjByIndex[nCurrentObjIndex] = nil
    self.tbSoundObjByUniqueId[nSoundSourceUniqueID] = nil
    Obj:HideContent()
end

local function GetObjByAngle(self, nAngle, nSoundSourceUniqueID)
    local nObjIndex = math.floor(((nAngle + ANGLE_OFFSET - 1) % 360) / 30)
    --logdebug("GetObjByAngle,nSoundSourceUniqueID,nObjIndex=",nSoundSourceUniqueID,nObjIndex)
    local Obj = self.tbSoundObjByIndex[nObjIndex]
    if not Obj then
        Obj = self.tbSoundObjByUniqueId[nSoundSourceUniqueID]
        if not Obj then
            Obj = self:GetOneObj(MapObjType.OTHER, true)
        else
            local nOldObjIndex = Obj.tbData.nObjIndex
            local DelayTimerHandle = self.tbDelayTimerHandle[nOldObjIndex]
            --logdebug("nOldObjIndex,nObjIndex=",nOldObjIndex,nObjIndex)
            HideDelayFunc(self, Obj)
            if DelayTimerHandle then
                DelayTimer:ClearTimer(DelayTimerHandle)
            end
        end
    else
        local nOldObjIndex = Obj.tbData.nObjIndex
        local DelayTimerHandle = self.tbDelayTimerHandle[nOldObjIndex]
        --logdebug("DelayTimerHandle=",DelayTimerHandle)
        HideDelayFunc(self, Obj)
        if DelayTimerHandle then
            DelayTimer:ClearTimer(DelayTimerHandle)
        end
    end
    return Obj, nObjIndex
end

local function OnFFASound(self, nSoundType, nAngle, nIntensity, nSoundSourceUniqueID)
    log("MapOpFFASound:OnFFASound:nSoundType, nAngle, nIntensity, nSoundSourceUniqueID=",nSoundType, nAngle, nIntensity, nSoundSourceUniqueID)
    if not tbSoundIconRes[nSoundType] or not INTENSITY[nIntensity] then
        logerror("OnFFASound, can not find res!!!! nSoundType, nAngle, nIntensity=",nSoundType, nAngle, nIntensity)
        return
    end

    local UISelfPosX = ORIGIN.X
    local UISelfPosY = ORIGIN.Y
    local Obj, nObjIndex = GetObjByAngle(self, nAngle, nSoundSourceUniqueID)
    local tbData = {}
    tbData.szIcon = tbSoundIconRes[nSoundType]
    local nFixAngle = nObjIndex * ANGLE_DIVIDE
    tbData.UILocation = {X = UISelfPosX + RADIUS * math.cos(math.rad(nFixAngle)), Y = UISelfPosY + RADIUS * math.sin(math.rad(nFixAngle))}
    tbData.UIRotation = nFixAngle + 90
    tbData.SlateColor = INTENSITY[nIntensity]
    tbData.Dimension = ICON_SIZE
    tbData.UISize = {X = ICON_SIZE.X, Y = ICON_SIZE.Y}
    tbData.bMatchSize = false
    tbData.nSoundSourceUniqueID = nSoundSourceUniqueID
    tbData.nObjIndex = nObjIndex
    Obj:ShowContent(tbData)
    local TimerHandle = DelayTimer:DelayRun(function() HideDelayFunc(self, Obj) end, SHOW_TIME)
    self.tbSoundObjByIndex[nObjIndex] = Obj
    self.tbSoundObjByUniqueId[nSoundSourceUniqueID] = Obj
    self.tbDelayTimerHandle[nObjIndex] = TimerHandle
    self.EventHelper:FireEvent(ClientEventDef.EV_FFA_RADARMAP_ENEMY_SOUND, nSoundType)
end


function MapOpFFASound:Init(Parent)
    MapOpFFASound.super.Init(self, Parent)
    self.tbDelayTimerHandle = {}
    self.tbSoundObjByIndex = {}
    self.tbSoundObjByUniqueId = {}
    --self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_RADARMAP_SOUND, self, OnFFASound)
end


function MapOpFFASound:Uninit()
    --logdebug("MapOpFFASound:Uninit")
    MapOpFFASound.super.Uninit(self)
    for k, v in pairs(self.tbDelayTimerHandle) do
        DelayTimer:ClearTimer(v)
    end
    self.tbDelayTimerHandle = {}
    self.tbSoundObjByIndex = {}
    self.tbSoundObjByUniqueId = {}
end

function MapOpFFASound:BindEvent()
    MapOpFFASound.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_RADARMAP_SOUND, self, OnFFASound)
end

return MapOpFFASound
