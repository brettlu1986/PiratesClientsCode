local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local HeadlessStatsComponent = luaclass("HeadlessStatsComponent", GameComponentBaseClass)
local StringUtil = require("StringUtil")
local SelfTimerHelperClass = require("SelfTimerHelper")

local START_SECOND = 60
local STOP_SECOND = 60

local START_COLLECTION_STATS = 300  -- 3分钟后，开始集合场景的stats
local END_COLLECTION_STATS   = 60   -- 4分钟后，结束集合场景的stats

local START_BATTLE_STATS     = 120  -- 6分钟后，开始战斗场景的stats
local END_BATTLE_STATS       = 60   -- 7分钟后，结束战斗场景的stats


HeadlessStatsComponent.TimerHelper = nil

------------------------------------------------------------------------------------------------------
-- stats
------------------------------------------------------------------------------------------------------

local function OnStopFile(self)
    local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
    KismetSystemLibrary.ExecuteConsoleCommand(pPlayerController, "stat stopfile", pPlayerController)
end

local function OnStartFile(self)
    local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
    KismetSystemLibrary.ExecuteConsoleCommand(pPlayerController, "stat startfile", pPlayerController)
    self.TimerHelper:NewTimerMethod(self, OnStopFile, STOP_SECOND, false)
end

local function DoStats(self)
    self.TimerHelper:NewTimerMethod(self, OnStartFile, START_SECOND, false)
end

------------------------------------------------------------------------------------------------------
-- control
------------------------------------------------------------------------------------------------------

local function OnEndBattelStats(self)
    -- gm 结束stats
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "dm stopfile", nil)
end

local function OnStartBattleStats(self)
    -- gm 开始stats
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "dm startfile", nil)
    self.TimerHelper:NewTimerMethod(self, OnEndBattelStats, END_BATTLE_STATS, false)
end

local function OnInBattleScene(self)
    -- gm 进入战斗场景
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "dm setboolvalue SkipFFAWaitTime true", nil)
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "dm setboolvalue SkipFFASelectionPoint true", nil)
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "dm invincibletopoisoncircle 1", nil)

    self.TimerHelper:NewTimerMethod(self, OnStartBattleStats, START_BATTLE_STATS, false)
end

local function OnEndCollectionStats(self)
    -- gm 结束stats
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "dm stopfile", nil)
    OnInBattleScene(self)
end

local function OnStartCollectionStats(self)
    -- gm 开始stats
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "dm startfile", nil)
    self.TimerHelper:NewTimerMethod(self, OnEndCollectionStats, END_COLLECTION_STATS, false)
end

local function OnWaitCollectionScene(self)
    self.TimerHelper:NewTimerMethod(self, OnStartCollectionStats, START_COLLECTION_STATS, false)
end

local function Control(self)
    OnWaitCollectionScene(self)
end

------------------------------------------------------------------------------------------------------

function HeadlessStatsComponent:OnCreate(...)
    HeadlessStatsComponent.super.OnCreate(self, ...)
    self.TimerHelper = SelfTimerHelperClass()

    local szCmdLineStr = KismetSystemLibrary.GetCommandLine()
    local tbCmdArgs = StringUtil.Split(szCmdLineStr, ' ')
    for i=1,#tbCmdArgs do
        if tbCmdArgs[i] == "-headlessstats" then
            DoStats(self)
        end

        if tbCmdArgs[i] == "-headlessscontrol" then
            Control(self)
        end
    end
end

function HeadlessStatsComponent:OnDestroy(...)
    HeadlessStatsComponent.super.OnDestroy(self, ...)
    if self.TimerHelper~= nil then
        self.TimerHelper:ClearAllTimer()
        self.TimerHelper = nil
    end
end

return HeadlessStatsComponent
