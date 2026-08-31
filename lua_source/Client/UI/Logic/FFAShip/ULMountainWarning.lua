
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULMountainWarning = luaclass("ULMountainWarning", UILogicBase)

local DungeonIni = require("DungeonIni")
local ShipUtilityExHelper = require("ShipUtilityExHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local ClientEventDef = require("ClientEventDef")

local TIMER_INTERVER = DungeonIni.tbUIConfig.nMountainCheckInterval
local MOUNTAIN_CHECK_DISTANCE = DungeonIni.tbUIConfig.nMountainCheckDistance

ULMountainWarning.bLastCheckResult = false
ULMountainWarning.tbTimerHandle = nil

local function CheckIsExistMountainInFront(self)
    local pUEActor = GamePlayerSelfHelper:GetUEActor()
    local bCheckResult, pCollisionType = ShipUtilityExHelper.CheckIsExistMountainInFront(pUEActor, MOUNTAIN_CHECK_DISTANCE, GlobalVariableSystem.bPrintActorInfoWhenCheckMountain, GWorld)
    if bCheckResult ~= self.bLastCheckResult then
        self.bLastCheckResult = bCheckResult
        if bCheckResult then
            self.Owner:StopAnimation("animHideMountainWarning")
            self.Owner:PlayAnimation("animShowMountainWarning", 0, 0, EUMGSequencePlayMode.Forward, 1)
        else
            self.Owner:StopAnimation("animShowMountainWarning")
            self.Owner:PlayAnimation("animHideMountainWarning", 0, 1, EUMGSequencePlayMode.Forward, 1)
        end
        self.EventHelper:FireEvent(ClientEventDef.EV_SHIP_MOUNTAIN_WARNING, bCheckResult, pCollisionType)
    end
end

local function Reset(self)
    self.bLastCheckResult = false
    self.pWidgetRef.vboxMountainWarning:SetVisibility(ESlateVisibility_Collapsed)
end

function ULMountainWarning:Activate()
    self.tbTimerHandle = self.TimerHelper:NewTimerMethod(self, CheckIsExistMountainInFront, TIMER_INTERVER, true)
end

function ULMountainWarning:Deactivate()
    if self.tbTimerHandle then
        self.TimerHelper:ClearTimer(self.tbTimerHandle)
        self.tbTimerHandle = nil
    end
    Reset(self)
end

return ULMountainWarning
