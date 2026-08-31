-----------------------------------------------------
--File Name    : GuideActionPlayerMoveable.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFunctional     = require("GuideActionFunctional")
local GuideActionPlayerMoveable = luaclass("GuideActionPlayerMoveable",GuideActionFunctional)


local GamePlayerSelfHelper = require("GamePlayerSelfHelper")


function GuideActionPlayerMoveable:Begin()
    GuideActionPlayerMoveable.super.Begin(self)
    local SelfObj = GamePlayerSelfHelper:Get()
    local bisHuman = SelfObj:IsHuman()
    if not bisHuman then
        return
    end
    local PlayerActor = SelfObj:GetModelActor()
    if PlayerActor then
        local PlayerInputComponent = PlayerActor.PlayerInputComponent
        if PlayerInputComponent then
            PlayerInputComponent:SetMoveEnabled(self.tbTemplate.bEnable)
        end
    end
end

return GuideActionPlayerMoveable
