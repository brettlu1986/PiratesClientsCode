local luaclass                  = require("luaclass")
local PlayerFishingCommonState  = require("PlayerFishingCommonState")
local PlayerFishingWaitState    = luaclass("PlayerFishingWaitState", PlayerFishingCommonState)
local PlayerAnimDef             = require("PlayerAnimDef")
local EventManager              = require("EventManager")
local ClientEventDef            = require("ClientEventDef")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")

PlayerFishingWaitState.tbOwner = nil
PlayerFishingWaitState.bStart  = false

local function OnEnterWait(self)
    if self:IsActived() then
        self.szAnimKey = PlayerAnimDef.PAN_FISHING_WAIT
        self:PlayAnimation()
        if self.bStart == false then
            local tbPlayer = GamePlayerSelfHelper:Get()
            if tbPlayer == self.tbOwner then
                self.bStart = true
                EventManager:OnFireEvent(ClientEventDef.EV_FISHING_STARTWAIT)
            end
        end
    end
end

local function OnWaitToBite(self)
    if self:IsActived() then
        self.szAnimKey = PlayerAnimDef.PAN_FISHING_BITE
        self:PlayAnimation()
    end
end

function PlayerFishingWaitState:Init(szName, tbParams)
    PlayerFishingWaitState.super.Init(self, szName, tbParams)
    self.OnChangeState = function(bFishBite)
        if bFishBite then
            OnWaitToBite(self)
        else
            OnEnterWait(self)
        end
    end

    EventManager:BindEvent(ClientEventDef.EV_FISHING_WAITSTATECHANGE, self.OnChangeState)

    self.szAnimKey   = PlayerAnimDef.PAN_FISHING_START
    self.fnAnimComplete = function() 
        OnEnterWait(self)
    end
end

function PlayerFishingWaitState:Uninit()
    EventManager:UnBindEvent(ClientEventDef.EV_FISHING_WAITSTATECHANGE, self.OnChangeState)
    PlayerFishingWaitState.super.Uninit(self)
end

function PlayerFishingWaitState:OnActive(tbParams)
    self.bStart = false
    if tbParams then
        if tbParams.bPlayInstantAnim ~= nil then
            self.szAnimKey = tbParams.bPlayInstantAnim and PlayerAnimDef.PAN_FISHING_START or PlayerAnimDef.PAN_FISHING_WAIT
        else
            self.szAnimKey = PlayerAnimDef.PAN_FISHING_START
        end
    else
        self.szAnimKey = PlayerAnimDef.PAN_FISHING_START
    end

    PlayerFishingWaitState.super.OnActive(self, tbParams)
end

return PlayerFishingWaitState