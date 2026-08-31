-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideTriggerEnterPickUp           = require("GuideTriggerEnterPickUp")
local GuideTriggerPickUpBtnClose        = luaclass("GuideTriggerPickUpBtnClose", GuideTriggerEnterPickUp)

local BattlePickupSystem    = require("BattlePickupSystem")
-----------------------------------------------------

function GuideTriggerPickUpBtnClose:Execute()
    self:DebugLog("GuideTriggerPickUpBtnClose:IsPickUpBtnClose")
    local bPickupItemOpen = BattlePickupSystem:IsItemAutoOpen()
    if not bPickupItemOpen then
        self:Trigger()
    else
        self:Break()
    end
end

--override
function GuideTriggerPickUpBtnClose:Begin()
    GuideTriggerPickUpBtnClose.super.Begin(self)
end

return GuideTriggerPickUpBtnClose
