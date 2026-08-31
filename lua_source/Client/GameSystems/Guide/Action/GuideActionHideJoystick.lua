-----------------------------------------------------
--File Name    : GuideActionHideJoystick.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideActionFunctional = require("GuideActionFunctional")
local GuideActionHideJoystick = luaclass("GuideActionHideJoystick", GuideActionFunctional)



--import
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

--member
GuideActionHideJoystick.Rotation = nil

function GuideActionHideJoystick:DoAction(tbTemplate)
    GuideActionHideJoystick.super.DoAction(self, tbTemplate)
    local SelfObj = GamePlayerSelfHelper:Get()
    if not SelfObj then
        self:EndAction()
        return
    end
    SelfObj.pUEActor.PlayerInputComponent:SetMoveEnabled(false)
    GameplayStatics.GetPlayerController(GWorld, 0):GetHUD():GetGestureHUDModule():SetVirtualJoystickEnable(false)
    local pCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    self.Rotation = pCameraManager:GetCameraRotation()
    self.TimerHelper:NewTimerMethod(self,self.OnTickTimerFunc, 0.5, true)
end

function GuideActionHideJoystick:OnTickTimerFunc()
    local pCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    local Rotation = pCameraManager:GetCameraRotation()
    if(Rotation.Yaw ~= self.Rotation.Yaw or Rotation.Pitch ~= self.Rotation.Pitch or Rotation.Roll ~= self.Rotation.Roll )then
        local SelfObj = GamePlayerSelfHelper:Get()
        if not SelfObj then
            self:EndAction()
            return
        end
        SelfObj.pUEActor.PlayerInputComponent:SetMoveEnabled(true)
        GameplayStatics.GetPlayerController(GWorld, 0):GetHUD():GetGestureHUDModule():SetVirtualJoystickEnable(true)
        self:EndAction()
    end
end

return GuideActionHideJoystick
