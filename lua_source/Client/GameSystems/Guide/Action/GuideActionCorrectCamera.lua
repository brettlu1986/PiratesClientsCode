-----------------------------------------------------
--File Name    : GuideActionCorrectCamera.lua
--Description  : 指引动作
--废弃 2020.8.31
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideAction = require("GuideAction")
local GuideActionCorrectCamera = luaclass("GuideActionCorrectCamera",GuideAction)

-- local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

-- local function OnBlendAnimEnd(self)
--     self:EndAction()

-- end

-- function GuideActionCorrectCamera:Begin()
--     GuideActionCorrectCamera.super.Begin(self)
--     local SelfObj = GamePlayerSelfHelper:Get()
--     local ShipActor = SelfObj:GetModelActor()
--     if(ShipActor == nil)then
--         return
--     end

--     -- local CameraControlManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
 

--     -- self.EventHelper:RegisterCppDelegate(CameraControlManager.CurrentActiveModeComponent.OnBlendAnimEnd, self, OnBlendAnimEnd)
--     -- CameraControlManager.CurrentActiveModeComponent:ResetToDefaultParam()
--     --self:EndAction()
-- end


return GuideActionCorrectCamera
