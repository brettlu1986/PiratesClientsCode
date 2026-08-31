
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULBotMountainWarning = luaclass("ULBotMountainWarning", UILogicBase)

local DungeonIni = require("DungeonIni")
local ShipUtilityExHelper = require("ShipUtilityExHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local TIMER_INTERVER = DungeonIni.tbUIConfig.nMountainCheckInterval
local MOUNTAIN_CHECK_DISTANCE = DungeonIni.tbUIConfig.nMountainCheckDistance

ULBotMountainWarning.bLastCheckResult = false
ULBotMountainWarning.tbTimerHandle = nil

local function CheckIsExistMountainInFront(self)
    local pUEActor = self.Owner.tbCurrrentWatchObj.pUEActor
    local bShip = self.Owner.tbCurrrentWatchObj:IsShip() 
    if not bShip then
        return
    end
    local bCheckResult = ShipUtilityExHelper.CheckIsExistMountainInFront(pUEActor, MOUNTAIN_CHECK_DISTANCE, GlobalVariableSystem.bPrintActorInfoWhenCheckMountain, GWorld)
    if bCheckResult ~= self.bLastCheckResult then
        self.bLastCheckResult = bCheckResult
        if bCheckResult then
            self.Owner:PlayAnimation("animShowMountainWarning", 0, 0, EUMGSequencePlayMode.Forward, 1)
        else
            self.Owner:PlayAnimation("animHideMountainWarning", 0, 1, EUMGSequencePlayMode.Forward, 1)
        end
    end
end

local function Reset(self)
    self.bLastCheckResult = false
    self.pWidgetRef.vboxMountainWarning:SetVisibility(ESlateVisibility_Collapsed)
end

function ULBotMountainWarning:Activate()
    self.tbTimerHandle = self.TimerHelper:NewTimerMethod(self, CheckIsExistMountainInFront, TIMER_INTERVER, true)
end

function ULBotMountainWarning:Deactivate()
    if self.tbTimerHandle then
        self.TimerHelper:ClearTimer(self.tbTimerHandle)
        self.tbTimerHandle = nil
    end
    Reset(self)
end

return ULBotMountainWarning
