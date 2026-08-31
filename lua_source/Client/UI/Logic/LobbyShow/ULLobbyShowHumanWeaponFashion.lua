local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULLobbyShowHumanWeaponFashion = luaclass("ULLobbyShowHumanWeaponFashion", UILogicBase)

local LobbyHumanWeapon3DOperator   = require("LobbyHumanWeapon3DOperator")

ULLobbyShowHumanWeaponFashion.LobbyHumanWeapon3DOperator = nil
ULLobbyShowHumanWeaponFashion.tbParam = nil


function ULLobbyShowHumanWeaponFashion:InitParams(tbParam)
    self.tbParam = tbParam
end

function ULLobbyShowHumanWeaponFashion:ActivateLevel(nLevel)
    self.LobbyHumanWeapon3DOperator:UpdateDisplayByLevel(nLevel)
end

function ULLobbyShowHumanWeaponFashion:OnLoad()
    self.LobbyHumanWeapon3DOperator = LobbyHumanWeapon3DOperator()
    local bdrWidget = self.pWidgetRef.kmbdrActor
    self.LobbyHumanWeapon3DOperator:Init({bdrWidget = bdrWidget})
end

function ULLobbyShowHumanWeaponFashion:OnUnload()
    self.LobbyHumanWeapon3DOperator:Uninit()
    self.LobbyHumanWeapon3DOperator = nil
end


function ULLobbyShowHumanWeaponFashion:OnShow()
    local tbParam = self.tbParam
    self.LobbyHumanWeapon3DOperator:Activate()
    local pActorLocation, pActorRotation = tbParam.fnGetLocationAndRotatorByTag(tbParam.szActorTag)
    self.LobbyHumanWeapon3DOperator:SetActorLocation(pActorLocation)
    self.LobbyHumanWeapon3DOperator:SetActorRotator(pActorRotation)
    self.LobbyHumanWeapon3DOperator:SetLightChannel(tbParam.tbLightChannel)
    self.LobbyHumanWeapon3DOperator:Display(tbParam.nWeaponInstanceType, tbParam.nItemTemplateId, tbParam.tbDisplayMiscData)
end

function ULLobbyShowHumanWeaponFashion:OnHide()
    self.LobbyHumanWeapon3DOperator:Deactivate()
end


return ULLobbyShowHumanWeaponFashion