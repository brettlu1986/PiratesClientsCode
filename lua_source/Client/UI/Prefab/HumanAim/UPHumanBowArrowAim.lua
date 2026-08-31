-----------------------------------------------------
--Author       : lzheng
--Description  : UPHumanBowArrowAim
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPHumanWeaponAim = require("UPHumanWeaponAim")
local UPHumanBowArrowAim = luaclass("UPHumanBowArrowAim", UPHumanWeaponAim)
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local FOCUS_SCALE = 0.7
local NORMAL_SCALE = 1
local TIMER_TICK = 0.1
local FOCUS_RECOVER_TIME = 0.2

UPHumanBowArrowAim.FocusTimer = nil
UPHumanBowArrowAim.nVarFocusTime = nil 
UPHumanBowArrowAim.nFocusTime = nil
UPHumanBowArrowAim.nOffsetScaleToGo = nil
UPHumanBowArrowAim.tbFocusInitSize = nil
UPHumanBowArrowAim.tbOriginSize = nil
UPHumanBowArrowAim.pFocusAimWidget = nil

local function FocusTimerFunc(self)
    self.nVarFocusTime = self.nVarFocusTime - TIMER_TICK

    if self.nVarFocusTime <= 0 then   
        self.nVarFocusTime = 0
        if self.FocusTimer then
            self.TimerHelper:ClearTimer(self.FocusTimer)
            self.FocusTimer = nil
        end
    end
    
    local nDurationPct = ( self.nFocusTime - self.nVarFocusTime ) / self.nFocusTime
    local nBlendPct = KismetMathLibrary.Lerp(0, 1, nDurationPct)

    local nScalePct = self.nOffsetScaleToGo * nBlendPct
    local nX = self.tbFocusInitSize.X + self.tbOriginSize.X * nScalePct
    local nY = self.tbFocusInitSize.Y + self.tbOriginSize.Y * nScalePct
    
    local NextSize = Vector2D{X = nX, Y = nY}
    self.pFocusAimWidget.Slot:SetSize(NextSize)
end


local function PlayFocusScaleAnim(self, bFocus, nAnimTime)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf and PlayerSelf.HumanWeaponComponent then
        if self.FocusTimer then
            self.TimerHelper:ClearTimer(self.FocusTimer)
            self.FocusTimer = nil
        end

        local bAim = PlayerSelf.HumanWeaponComponent:IsAiming()
        self.pFocusAimWidget = bAim and self.pWidgetRef.ovlAim or self.pWidgetRef.ovlNotAim

        self.tbOriginSize = bAim and self.tbAimInitSize or self.tbNotAimInitSize
        self.tbFocusInitSize = self.pFocusAimWidget.Slot:GetSize()
        
        local nTargetFocusScale = bFocus and FOCUS_SCALE or NORMAL_SCALE
        local nX = self.pFocusAimWidget.Slot:GetSize().X
        local nCurrentFocusScale = nX / self.tbOriginSize.X
        self.nVarFocusTime = nAnimTime
        self.nFocusTime = nAnimTime

        self.nOffsetScaleToGo = nTargetFocusScale - nCurrentFocusScale 
        self.FocusTimer = self.TimerHelper:NewTimerMethod(self, FocusTimerFunc, TIMER_TICK, true)
    end
end

local function OnAimFocusAnim(self, bFocus, PreAttackTime, nMaxAccumulateTime)
    local nAnimTime = FOCUS_RECOVER_TIME
    if bFocus then  
        nAnimTime = PreAttackTime + nMaxAccumulateTime
    end
    -- logdebug("the focus anim ", bFocus, nAnimTime)
    PlayFocusScaleAnim(self, bFocus, nAnimTime)
end

--member function
function UPHumanBowArrowAim:OnBindEvent(EventHelper)
    UPHumanBowArrowAim.super.OnBindEvent(self, EventHelper)

    EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_ACCUMULATE, self, OnAimFocusAnim)
end

function UPHumanBowArrowAim:OnLoad()
    UPHumanBowArrowAim.super.OnLoad(self)
end

function UPHumanBowArrowAim:ScaleToTargetSize(bReset, bFirstAttack)
    UPHumanBowArrowAim.super.ScaleToTargetSize(self, bReset, bFirstAttack)
end


return UPHumanBowArrowAim
