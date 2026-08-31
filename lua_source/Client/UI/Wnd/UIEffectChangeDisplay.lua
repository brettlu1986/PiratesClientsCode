local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIEffectChangeDisplay = luaclass("UIEffectChangeDisplay", WndBase)
local PlayerSelfHelper = require("GamePlayerSelfHelper")
-- local SelfAnimationHelper = require("SelfAnimationHelper")
-- local UEActorHelper = require("UEActorHelper")
-- local DelayTimer = require("DelayTimer")
local ClientEventDef = require("ClientEventDef")

-- local SHIP_TO_HUMAN_ACTOR = "'/Game/Game/OtherObject/AttachedBP/BP_AttachedsShipToHuman.BP_AttachedsShipToHuman_C'"

UIEffectChangeDisplay.pAttachedActor = nil
UIEffectChangeDisplay.tbDelayTimer = nil
UIEffectChangeDisplay.bReadyPlayAni = nil

-- local function ClearTimer(self)
--     if self.tbDelayTimer ~= nil then  
--         DelayTimer:ClearTimer(self.tbDelayTimer)
--         self.tbDelayTimer = nil 
--     end 
-- end

-- local function DetachFromAnimation(self)
--     if self.pAttachedActor ~= nil then
--         self.pAttachedActor:OnDetached()
--         self.pAttachedActor = nil
--     end
-- end

-- local function AttachToAnimation(self, tbPlayer)
--     local _, pActor = UEActorHelper:CreateActor(SHIP_TO_HUMAN_ACTOR)
--     if pActor ~= nil then
--         pActor:OnAttached(nil, tbPlayer.pUEActor.Mesh)

--         DetachFromAnimation(self)
--         self.pAttachedActor = pActor
--     end
-- end

local function VerifyPlayAnimation(self)
    if not self.bReadyPlayAni then
        return
    end
    local SelfPlayer = PlayerSelfHelper:Get()
    if SelfPlayer ~= nil and SelfPlayer:IsHuman() then
        if isvalidhandle(SelfPlayer.pUEActor) then
            self.EventHelper:FireEvent(ClientEventDef.EV_PLAY_SHIP_TO_HUMAN_ANI)
            self:CloseSelf()
            -- SelfAnimationHelper:PlayHumanAnimation(SelfPlayer, SelfAnimationHelper.AnimDef.SHIP_TO_HUMAN)
            -- AttachToAnimation(self, SelfPlayer)
            -- self.tbDelayTimer = DelayTimer:DelayRun(function() 
            --     ClearTimer(self)
            --     self:CloseSelf() 
            -- end, 1)
        end
    else
        self:CloseSelf()
    end
end

local function OnPlayerSelfReady(self)
    VerifyPlayAnimation(self)
end

function UIEffectChangeDisplay:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_BINDREPLICATE_UEACTOR, self, OnPlayerSelfReady)
end

function UIEffectChangeDisplay:OnShow()
    self:PlayAnimation("anim_ChangeRoleShip_Part01", 0, 1, EUMGSequencePlayMode.Forward, 1, function()
            self.bReadyPlayAni = true
            VerifyPlayAnimation(self)
        end)
end

function UIEffectChangeDisplay:OnDestroy()
    -- ClearTimer(self)
    -- DetachFromAnimation(self)
end

return UIEffectChangeDisplay