-----------------------------------------------------
--File Name    : GuideActionLockCamera.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideActionFunctional = require("GuideActionFunctional")
local GuideActionLockCamera = luaclass("GuideActionLockCamera",GuideActionFunctional)


local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

function GuideActionLockCamera:DoAction(tbTemplate)
    GuideActionLockCamera.super.DoAction(self, tbTemplate)
    local SelfObj = GamePlayerSelfHelper:Get()
    local ShipActor = SelfObj:GetModelActor()
    if not ShipActor then
        return
    end
end

return GuideActionLockCamera
