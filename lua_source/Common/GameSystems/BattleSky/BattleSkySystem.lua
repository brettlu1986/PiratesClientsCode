local luaclass = require("luaclass")
local BattleSkySystem = luaclass("BattleSkySystem")

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleSkyDataTable = require("BattleSkyDataTable")
local SelfEventHelper = require("SelfEventHelper")
local CommonEventDef = require("CommonEventDef")
local Timer = require("Timer")

local REFRESH_TIME_INTERVAL = 10

BattleSkySystem.EventHelper        = nil
BattleSkySystem.tbPauseSkyTimer    = nil
BattleSkySystem.tbRefreshTimeTimer = nil

BattleSkySystem.bSkyEnabled    = nil
BattleSkySystem.nSkyTime       = nil
BattleSkySystem.fSkySpeed      = nil
BattleSkySystem.nLeftSeconds   = 0
BattleSkySystem.bChangeSky     = false --false表示固定时间

--local function
local function UpdateSkyEnabled(self, bSkyEnabled)
    self.bSkyEnabled = bSkyEnabled

    local bGameStateSkyEnabled = BattleGameModeSystem:GetGameState().bGameStateSkyEnabled
    if bGameStateSkyEnabled then
        bGameStateSkyEnabled:Set(self.bSkyEnabled)
    end
end

local function UpdateSkyTime(self, nSkyTime)
    self.nSkyTime = nSkyTime

    local nGameStateCurrentSkyTime = BattleGameModeSystem:GetGameState().nGameStateCurrentSkyTime
    if nGameStateCurrentSkyTime then
        nGameStateCurrentSkyTime:Set(self.nSkyTime)
    end
end

local function UpdateSkySpeed(self, fSkySpeed)
    self.fSkySpeed = fSkySpeed

    local fGameStateSkySpeed = BattleGameModeSystem:GetGameState().fGameStateSkySpeed
    if fGameStateSkySpeed then
        fGameStateSkySpeed:Set(self.fSkySpeed)
    end
end

local function ClearAllTimer(self)
    if self.tbPauseSkyTimer then
        self.tbPauseSkyTimer:Clear()
        self.tbPauseSkyTimer = nil
    end

    if self.tbRefreshTimeTimer then
        self.tbRefreshTimeTimer:Clear()
        self.tbRefreshTimeTimer = nil
    end
end

local function OnFFAGameOver(self)
    self:PauseSky()
end

--public function
function BattleSkySystem:EnableSky(nConfigIndex)
    local tbInfo = BattleSkyDataTable:GetTemplate(nConfigIndex)
    if not tbInfo then
        logerror("BattleSkyDataTable GetTemplate return nil, nConfigId:", nConfigIndex)
        return
    end

    --先随机是固定时间还是昼夜变换
    local nSkyChangeWeight = tbInfo.nSkyChangeWeight
    self.bChangeSky = false

    if nSkyChangeWeight > 0 then
        local nRandomNum = math.random(1, 100)
        if nRandomNum <= nSkyChangeWeight then
            self.bChangeSky = true
        end
    end

    if self.bChangeSky then
        local nTotalWeight = 0
        for i = 1, #tbInfo.tbRandomWeight do
            nTotalWeight = nTotalWeight + tbInfo.tbRandomWeight[i]
        end

        local nRanomWeight = math.random( 1, nTotalWeight )
        local nRandomIndex = 0
        nTotalWeight = 0
        for i = 1, #tbInfo.tbRandomWeight do
            nTotalWeight = nTotalWeight + tbInfo.tbRandomWeight[i]
            if nRanomWeight <= nTotalWeight then
                nRandomIndex = i
                break
            end
        end

        local nStartIndex = (nRandomIndex - 1) * 4 + 1
        local nStartTimeHour   = tbInfo.tbRandomSkyTime[nStartIndex]
        local nStartTimeMinute = tbInfo.tbRandomSkyTime[nStartIndex + 1]
        local nEndTimeHour     = tbInfo.tbRandomSkyTime[nStartIndex + 2]
        local nEndTimeMinute   = tbInfo.tbRandomSkyTime[nStartIndex + 3]

        self:ResetStartEndTime(nStartTimeHour, nStartTimeMinute, nEndTimeHour, nEndTimeMinute)
    else
        --设置一个固定时间
        local nSkyTime = tbInfo.tbFixTimes[1] * 100 + tbInfo.tbFixTimes[2]

        UpdateSkyEnabled(self, false)
        UpdateSkyTime(self, nSkyTime)
        UpdateSkySpeed(self, 1)
    end
end

function BattleSkySystem:Clear()
    if self.EventHelper then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end

    ClearAllTimer(self)
end

function BattleSkySystem:Init()
    self.EventHelper = SelfEventHelper()

    --default value.
    self.bSkyEnabled = false
    self.nSkyTime    = 900
    self.fSkySpeed   = 1.0
    
    if(GlobalVariableSystem:IsServerLogic()) then
        self.EventHelper:RegisterEvent(CommonEventDef.EV_FFA_TEAM_WIN, self, OnFFAGameOver)
    end

    return true
end

function BattleSkySystem:Uninit()
    self:Clear()
end

function BattleSkySystem:PauseSky()
    if self.bChangeSky then
        UpdateSkyEnabled(self, false)

        if self.tbPauseSkyTimer and self.tbPauseSkyTimer:IsActive() then
            self.tbPauseSkyTimer:Pause()
        end
    end
end

function BattleSkySystem:ResumeSky()
    if self.bChangeSky then
        UpdateSkyEnabled(self, true)

        if self.tbPauseSkyTimer and self.tbPauseSkyTimer:IsPaused() then
            self.tbPauseSkyTimer:Resume()
        end
    end
end

function BattleSkySystem:TimeEndDisableSky()
    log("BattleSkySystem:TimeEndDisableSky")
    UpdateSkyEnabled(self, false)
end

function BattleSkySystem:RefreshTime()
    if self.bSkyEnabled then
        local nHour = math.floor(self.nSkyTime / 100)
        local nMinute = self.nSkyTime % 100

        self.nLeftSeconds = math.floor(REFRESH_TIME_INTERVAL * self.fSkySpeed) + self.nLeftSeconds

        local nAddMinutes = math.floor(self.nLeftSeconds / 60)
        self.nLeftSeconds = self.nLeftSeconds % 60
        local nAddHour = math.floor(nAddMinutes / 60)
        nAddMinutes = nAddMinutes % 60

        nMinute = nMinute + nAddMinutes
        nHour   = nHour + nAddHour

        if nMinute >= 60 then
            nMinute = nMinute - 60
            nHour = nHour + 1
        end

        if nHour >= 24 then
            nHour = nHour - 24
        end

        UpdateSkyTime(self, nHour * 100 + nMinute)
    end
end

function BattleSkySystem:ResetStartEndTime(nStartTimeHour, nStartTimeMinute, nEndTimeHour, nEndTimeMinute)
    local nTotalMinutes = 0
    if nEndTimeHour < nStartTimeHour then
        nEndTimeHour = nEndTimeHour + 24
    end

    nTotalMinutes = (nEndTimeHour * 60 + nEndTimeMinute) - (nStartTimeHour * 60 + nStartTimeMinute)

    local nSkyTime = nStartTimeHour * 100 + nStartTimeMinute
    local fSkySpeed = nTotalMinutes / 38.0
    local nEndSeconds = 40 * 60 --40分钟后暂停昼夜系统

    log("BattleSkySystem ResetStartEndTime:", nSkyTime, fSkySpeed, nEndSeconds)
    ClearAllTimer(self)
    self.tbPauseSkyTimer    = Timer.NewTimerMethod(self, self.TimeEndDisableSky, nEndSeconds, false)
    self.tbRefreshTimeTimer = Timer.NewTimerMethod(self, self.RefreshTime, REFRESH_TIME_INTERVAL, true)

    UpdateSkyTime(self, nSkyTime)
    UpdateSkySpeed(self, fSkySpeed)
    UpdateSkyEnabled(self, true)

    self.bChangeSky = true
end

return BattleSkySystem()