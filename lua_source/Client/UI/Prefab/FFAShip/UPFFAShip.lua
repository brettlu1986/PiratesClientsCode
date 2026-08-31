-----------------------------------------------------
--File Name    : UPFFAShip.lua
--Author       : Song Fuhao
--Create Time  : 2018-09-05
--Description  : 船相关吃鸡UI
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPFFABase = require("UPFFABase")
local UPFFAShip = luaclass("UPFFAShip", UPFFABase)

UPFFAShip.pbSailControl         = nil
UPFFAShip.ulShipPosture         = nil
UPFFAShip.ulShipPartPanel       = nil
UPFFAShip.ulShipWeaponPanel     = nil
UPFFAShip.ulShipWeaponAim       = nil
UPFFAShip.ulMountainWarning     = nil
UPFFAShip.ulShipThrownItemPanel = nil

local function CallSubLogicFunction(self, szFunctionName)
    for _,v in pairs(self.UILogicHelper.tbUILogicList) do
        if v[szFunctionName] then
            v[szFunctionName](v)
        end
    end
    for _,v in pairs(self.PrefabHelper.tbPrefabList) do
        if v[szFunctionName] then
            v[szFunctionName](v)
        end
    end
end

function UPFFAShip:OnLoad()
    local PrefabHelper = self.PrefabHelper
    self.pbSailControl = PrefabHelper:BindPrefab(self.pWidgetRef.pbSailControl)

    local UILogicHelper = self.UILogicHelper
    self.ulShipPosture          = UILogicHelper:CreateUILogic("ULShipPosture")
    self.ulShipPartPanel        = UILogicHelper:CreateUILogic("ULShipPartPanel")
    self.ulShipWeaponPanel      = UILogicHelper:CreateUILogic("ULShipWeaponPanel")
    self.ulShipWeaponAim        = UILogicHelper:CreateUILogic("ULShipWeaponAim")
    self.ulShipLayout           = UILogicHelper:CreateUILogic("ULFFAShipLayout")
    self.ulMountainWarning      = UILogicHelper:CreateUILogic("ULMountainWarning")
    self.ulShipThrownItemPanel  = UILogicHelper:CreateUILogic("ULShipThrownItemPanel")
end

function UPFFAShip:Activate()
    CallSubLogicFunction(self, "Activate")
end

function UPFFAShip:Deactivate()
    CallSubLogicFunction(self, "Deactivate")
end

function UPFFAShip:RefreshLayout()
    self.ulShipLayout:RefreshLayout()
end

return UPFFAShip
