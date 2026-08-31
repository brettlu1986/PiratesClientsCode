-----------------------------------------------------
--File Name    : AbilityEvent_HumanCurrentWeaponChanged.lua
--Author       : WuJizhou
--Create Time  : 3/25/2020, 6:52:15 PM
--Description  : AbilityEvent_HumanCurrentWeaponChanged
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBaseClass = require("AbilityEventBase")
local AbilityEvent_HumanCurrentWeaponChanged = luaclass("AbilityEvent_HumanCurrentWeaponChanged", AbilityEventBaseClass)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")



local function OnHumanCurrentWeaponChanged(self, nNewWeapon, nLastWeapon, nOwnerServerInstanceId)
    -- log("AbilityEvent_HumanCurrentWeaponChanged","OnHumanCurrentWeaponChanged", nNewWeapon, nLastWeapon, nOwnerServerInstanceId)
    if self.OwnerPawn:GetServerInstanceId() ~= nOwnerServerInstanceId then
        return
    end
    local tbParams = {}
    tbParams.nNewWeapon = nNewWeapon
    tbParams.nLastWeapon = nLastWeapon
    tbParams.nOwnerServerInstanceId = nOwnerServerInstanceId
    self:TriggerDo(tbParams)
end




function AbilityEvent_HumanCurrentWeaponChanged:OnActivate()
    EventManager:BindEventMethod(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, self, OnHumanCurrentWeaponChanged)
end

function AbilityEvent_HumanCurrentWeaponChanged:OnDeactivate()
    EventManager:UnBindEventMethod(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, self, OnHumanCurrentWeaponChanged)
end

return AbilityEvent_HumanCurrentWeaponChanged