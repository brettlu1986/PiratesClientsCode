-----------------------------------------------------
--File Name    : GuideActionCameraGyroEnable.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideActionFunctional             = require("GuideActionFunctional")
local GuideActionCameraGyroEnable       = luaclass("GuideActionCameraGyroEnable", GuideActionFunctional)

local ClientEventDef                    = require("ClientEventDef")
local CameraGameHelper                  = require("CameraGameHelper")
--local 

function GuideActionCameraGyroEnable:DoAction(tbTemplate)
    GuideActionCameraGyroEnable.super.DoAction(self, tbTemplate)
    local bEnable = tbTemplate.bEnable
    CameraGameHelper.SetGyroEnable(bEnable)
    self.EventHelper:FireEvent(ClientEventDef.EV_SET_GYRO_CHECK_ENABLE, bEnable)
end

return GuideActionCameraGyroEnable
