-----------------------------------------------------
--File Name    : GuideActionDragDir.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideActionFunctional = require("GuideActionFunctional")
local GuideActionDragDir    = luaclass("GuideActionDragDir",GuideActionFunctional)

--import
local CameraGameHelper      = require("CameraGameHelper")

function GuideActionDragDir:DoAction(tbTemplate)
    GuideActionDragDir.super.DoAction(self, tbTemplate)
    local bP1 = tonumber(tbTemplate.tbParam[1]) >= 1
    local bP2 = tonumber(tbTemplate.tbParam[2]) >= 1
    local bP3 = tonumber(tbTemplate.tbParam[3]) >= 1
    local bP4 = tonumber(tbTemplate.tbParam[4]) >= 1
    CameraGameHelper.SetLockUpScroll(bP1)
    CameraGameHelper.SetLockDownScroll(bP2)
    CameraGameHelper.SetLockLeftScroll(bP3)
    CameraGameHelper.SetLockRightScroll(bP4)
end

return GuideActionDragDir
