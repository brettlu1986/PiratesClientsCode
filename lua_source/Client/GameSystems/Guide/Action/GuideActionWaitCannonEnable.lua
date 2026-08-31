-----------------------------------------------------
--File Name    : GuideActionWaitCannonEnable.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionBase               = require("GuideActionBase")
local GuideActionWaitCannonEnable   = luaclass("GuideActionWaitCannonEnable",GuideActionBase)

--import
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local L10N                  = require("L10N")

--local Variable 
GuideActionWaitCannonEnable.TimerHelper = nil
GuideActionWaitCannonEnable.bIsStop = false

function GuideActionWaitCannonEnable:Begin()
    GuideActionWaitCannonEnable.super.Begin(self)
    self.bIsStop = false
end


function GuideActionWaitCannonEnable:DoAction(tbTemplate)
    GuideActionWaitCannonEnable.super.DoAction(self, tbTemplate)
    self:CallSetCentralGuide(L10N:ToString(tbTemplate.l10nGuideText), self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, self)
    self.TimerHelper:NewTimerMethod(self,self.OnTickTimerFunc, 0.5, true)
end

function GuideActionWaitCannonEnable:OnTickTimerFunc()
    local SelfActor = GamePlayerSelfHelper:Get():GetModelActor()
    if not SelfActor then
        return
    end
    local bHasAnyCannonAllowFire = SelfActor.ShipCannonSystemComponent:HasAnyCannonAllowFire()
    if bHasAnyCannonAllowFire and not self.bIsStop then
        self.bIsStop = true
        self:EndAction()
    end
end

return GuideActionWaitCannonEnable
