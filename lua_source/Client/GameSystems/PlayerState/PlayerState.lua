local luaclass              = require("luaclass")
local BaseState             = require("BaseState")
local PlayerState           = luaclass("PlayerState", BaseState)
local SelfAnimationHelper   = require("SelfAnimationHelper")

PlayerState.tbOwner             = nil
PlayerState.szAnimKey        = nil
PlayerState.fnAnimComplete      = nil
PlayerState.tbAnimationHelper   = nil

function PlayerState:Init(szName, tbParams)
    PlayerState.super.Init(self, szName, tbParams)

    self.szAnimKey       = tbParams.szAnimKey
    self.tbOwner            = tbParams.tbOwner
    self.fnAnimComplete     = tbParams.fnAnimComplete

    self.tbAnimationHelper  = SelfAnimationHelper()
    self.tbAnimationHelper:Init(self)
end

function PlayerState:Uninit()
    self.tbAnimationHelper:Uninit()
    self.tbAnimationHelper = nil
    self.tbOwner = nil
    PlayerState.super.Uninit(self)
end

function PlayerState:OnActive(tbParams)
    self:PlayAnimation()
    PlayerState.super.OnActive(self, tbParams)
end

function PlayerState:OnDeactive()
    PlayerState.super.OnDeactive(self)
end

function PlayerState:PlayAnimation()
    if not self.szAnimKey then
        return false
    end

    local tbOwner = self.tbOwner
    if not tbOwner then
        logerror("Player state can not find owner")
        return
    end

    local pUEActor = self.tbOwner.pUEActor
    if not pUEActor then
        logerror("Player state can not find UEActor")
        return false
    end

    return self.tbAnimationHelper:PlayAnimation(pUEActor.Mesh, tbOwner.nTemplateId, self.szAnimKey, self.fnAnimComplete)
end

return PlayerState