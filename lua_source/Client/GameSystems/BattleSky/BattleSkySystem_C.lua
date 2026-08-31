local luaclass = require("luaclass")
local BattleSkySystem = require("BattleSkySystem")
local BattleSkySystem_C = luaclass("BattleSkySystem_C", BattleSkySystem)

local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GameplayUtilityHelper = require("GameplayUtilityHelper")
local CommonEventDef = require("CommonEventDef")
local PropName = require("PropName")

BattleSkySystem_C.SkyMainUEActor = nil

--是否忽略服务器数据
BattleSkySystem_C.bStopUpdateDataFromServer = nil

local MAX_DELTA_MINUTES = 10 --最大误差不能超过10分钟

local function IsSkyMainActorValid(self)
    if self.SkyMainUEActor and isvalidhandle(self.SkyMainUEActor) then
        return true
    end

    return false
end

local function BindCallback(self)
    BattleGameModeSystem:GetGameStatePropertyBinder():Bind(PropName.bGameStateSkyEnabled,     self, self.OnSkyEnabledChanged, true)
    BattleGameModeSystem:GetGameStatePropertyBinder():Bind(PropName.nGameStateCurrentSkyTime, self, self.OnSkyTimeChanged,    true)
    BattleGameModeSystem:GetGameStatePropertyBinder():Bind(PropName.fGameStateSkySpeed,       self, self.OnSkySpeedChanged,   true)
end

local function OnLevelAddedToWorld(self, pLevelActor, szLevelName, nIsPersistent)
    if not IsSkyMainActorValid(self) then
        self.SkyMainUEActor = GameplayUtilityHelper.GetSkyMainActor(GWorld, GWorld)
        if IsSkyMainActorValid(self) then
            BindCallback(self)
        end
    end
end

local function ShouldSetTime(self, nNewHour, nNewMinute)
    return math.abs((self.SkyMainUEActor.Hour * 60 + self.SkyMainUEActor.Minute) - (nNewHour * 60 + nNewMinute) ) > MAX_DELTA_MINUTES 
end


function BattleSkySystem_C:Init()
    BattleSkySystem_C.super.Init(self)

    self.EventHelper:RegisterEvent(CommonEventDef.EV_LEVEL_ADDED_TO_WORLD, self, OnLevelAddedToWorld)

    return true
end

function BattleSkySystem_C:Uninit()
    BattleSkySystem_C.super.Uninit(self)
end

function BattleSkySystem_C:OnSkyEnabledChanged(bSkyEnabled)
    log("BattleSkySystem_C:OnSkyEnabledChanged:", bSkyEnabled)
    if not self.bStopUpdateDataFromServer and IsSkyMainActorValid(self) then
        log("BattleSkySystem_C:Set TimeStart:", bSkyEnabled)
        self.SkyMainUEActor.TimeStart = bSkyEnabled
    end
end

function BattleSkySystem_C:OnSkyTimeChanged(nTime)
    local nHour = math.floor(nTime / 100)
    local nMinute = nTime % 100

    log("BattleSkySystem_C:OnSkyTimeChanged", nTime, nHour, nMinute)
    if not self.bStopUpdateDataFromServer and IsSkyMainActorValid(self) and ShouldSetTime(self, nHour, nMinute) then
        log("BattleSkySystem_C:SetStartTime", nTime, nHour, nMinute)
        self.SkyMainUEActor:SetTime(nHour, nMinute)
        self.SkyMainUEActor:SetStartTime(nHour, nMinute)
    end
end

function BattleSkySystem_C:OnSkySpeedChanged(fSkySpeed)
    log("BattleSkySystem_C:OnSkySpeedChanged:", fSkySpeed)
    if not self.bStopUpdateDataFromServer and IsSkyMainActorValid(self) then
        log("BattleSkySystem_C:SetTimeSpeed:", fSkySpeed)
        self.SkyMainUEActor:SetTimeSpeed(fSkySpeed)
    end
end

function BattleSkySystem_C:ForceSetClientFixSkyTime(nHour, nMinute)
    self.bStopUpdateDataFromServer = true

    if IsSkyMainActorValid(self) then
        self.SkyMainUEActor.TimeStart = false
        self.SkyMainUEActor:SetTime(nHour, nMinute)
        self.SkyMainUEActor:SetStartTime(nHour, nMinute)
    end
end

return BattleSkySystem_C()