local luaclass          = require("luaclass")
local NestedState       = require("NestedState")
local PlayerFishingState= luaclass("PlayerFishingState", NestedState)
local PlayerStateDef    = require("PlayerStateDef")
local PlayerAnimDef     = require("PlayerAnimDef")
local EventManager      = require("EventManager")
local ClientEventDef    = require("ClientEventDef")
-- local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local HumanResDataTable = require("HumanResDataTable")

PlayerFishingState.tbOwner = nil
PlayerFishingState.nWeaponId = nil

local function TryToStand(self, _tbFromState, _tbToState, tbParams)
    local nStateId = tbParams and tbParams.nStateId
    if nStateId then 
        return nStateId == PlayerStateDef.PS_FISHING_STAND
    end

    return false
end

local function TryToWait(self, tbFromState, _tbToState, tbParams)
    local nStateId = tbParams and tbParams.nStateId
    if nStateId then 
        return nStateId == PlayerStateDef.PS_FISHING_WAIT and tbFromState.szAnimKey == PlayerAnimDef.PAN_FISHING_STAND
    end

    return false
end

function PlayerFishingState:Init(szName, tbParams)
    self.tbOwner = tbParams.tbOwner
    PlayerFishingState.super.Init(self, szName, tbParams)
end

function PlayerFishingState:Uninit()
    self.nWeaponId = nil
    self.tbOwner = nil 
    PlayerFishingState.super.Uninit(self)
end

function PlayerFishingState:DefineAll()
    PlayerFishingState.super.DefineAll(self)

    local tbOwner      = self.tbOwner
    local nWeaponId    = nil

    local tbHumanResData = HumanResDataTable:GetTemplate(tbOwner.nTemplateId)
    if tbHumanResData then
        nWeaponId = tbHumanResData.nFishPoleId
    end

    local tbStandState = self:DefineInitState("PlayerFishingStandState", {tbOwner = tbOwner, nWeaponId = nWeaponId})
    local tbWaitState  = self:DefineState("PlayerFishingWaitState",  {tbOwner = tbOwner, nWeaponId = nWeaponId})

    self:Link(tbStandState,  tbWaitState,    TryToWait)
    self:Link(tbWaitState,   tbStandState,   TryToStand)
end

function PlayerFishingState:TryTransfer(tbParams)
    local bRet = PlayerFishingState.super.TryTransfer(self, tbParams)
    if not bRet then
        local tbCurrentState = self.tbStateMachine.tbCurrentState
        if tbCurrentState and tbCurrentState.TryTransfer then
            bRet = tbCurrentState:TryTransfer(tbParams)
        end
    end
    return bRet
end

function PlayerFishingState:OnActive(tbParams)
    local tbOwner = self.tbOwner
    local tbResData = tbOwner.HumanAvatarComponent:GetResData()
    local tbHumanResData = HumanResDataTable:GetTemplate(tbOwner.nTemplateId)
    if tbHumanResData then
        self.nWeaponId = tbResData.weapon 
        tbResData.weapon = tbHumanResData.nFishPoleId
        tbOwner.HumanAvatarComponent:UpdateResData(tbResData)
    end
    PlayerFishingState.super.OnActive(self, tbParams)
end

function PlayerFishingState:OnDeactive()
    log("PlayerFishingState:OnDeactive")
    EventManager:OnFireEvent(ClientEventDef.EV_FISHING_LEAVEANIMATION, self.tbOwner, self.nWeaponId)
    
    -- local tbOwner = self.tbOwner
    -- local pUEActor = tbOwner.pUEActor

    -- local fnPlayAnimation = function()
    --     DestroyTimer(self)
    --     local OnAnimationComplete = function()
    --         local HumanAvatarComponent = tbOwner.HumanAvatarComponent
    --         if  HumanAvatarComponent then
    --             local tbResData = HumanAvatarComponent:GetResData()
    --             tbResData.weapon = self.nWeaponId
    --             HumanAvatarComponent:UpdateResData(tbResData)
    --         end
    --         EventManager:OnFireEvent(ClientEventDef.EV_FISHING_LEAVE, tbOwner)
    --         pUEActor.Mesh:SetAnimationMode(EAnimationMode.AnimationBlueprint) 
    --     end 

    --     local tbAniHelper = self.tbAnimationHelper            
    --     tbAniHelper:PlayAnimation(pUEActor.Mesh, tbOwner.nTemplateId, PlayerAnimDef.PAN_FISHING_LEAVE, OnAnimationComplete)              
    --     local tbHumanResData = HumanResDataTable:GetTemplate(tbOwner.nTemplateId)
    --     if tbHumanResData then
    --         tbAniHelper:PlayHumanPartAnimation(pUEActor, "RightScabbard", tbHumanResData.nFishPoleId, PlayerAnimDef.PAN_FISHING_LEAVE)
    --     end
    -- end
    -- self.tbDelayTimer = DelayTimer:RunNextTick(fnPlayAnimation)
    PlayerFishingState.super.OnDeactive(self)
end

return PlayerFishingState