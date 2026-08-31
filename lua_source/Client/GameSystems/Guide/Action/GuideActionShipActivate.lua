-----------------------------------------------------
--File Name    : GuideActionShipActivate.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFunctional     = require("GuideActionFunctional")
local GuideActionShipActivate   = luaclass("GuideActionShipActivate",GuideActionFunctional)


local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local UIManager             = require("UIManager")
local UIDef                 = require("UIDef")


function GuideActionShipActivate:DoAction(tbTemplate)
    GuideActionShipActivate.super.DoAction(self, tbTemplate)
    local SelfObj = GamePlayerSelfHelper:Get()
    local ShipActor = SelfObj:GetModelActor()
    if not ShipActor then
        return
    end
    if tbTemplate.bEnable then
        ShipActor.ShipMovementComponent:Activate()
    else
        if tbTemplate.bDoubleClick then
            local MainWnd = UIManager:GetWnd(UIDef.UI_BATTLE_MAIN)
            if MainWnd ~= nil and UIManager:IsWndOpen(UIDef.UI_BATTLE_MAIN) then
                --船档位降到0
                ShipActor.ShipMovementComponent:StopMovementImmediately()
            end
        end
        ShipActor.ShipMovementComponent:Deactivate()
    end
end

return GuideActionShipActivate
