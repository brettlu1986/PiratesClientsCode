local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULLobbyShowHumanFashion = luaclass("ULLobbyShowHumanFashion", UILogicBase)

local LobbyHumanFashion3DOperator   = require("LobbyHumanFashion3DOperator")

ULLobbyShowHumanFashion.LobbyHumanFashion3DOperator = nil
ULLobbyShowHumanFashion.tbParam = nil


function ULLobbyShowHumanFashion:InitParams(tbParam)
    self.tbParam = tbParam
end

function ULLobbyShowHumanFashion:ActivateArmorLevel(nArmorLevel)
    self.LobbyHumanFashion3DOperator:UpdateDisplayByArmorLevel(nArmorLevel)
end

function ULLobbyShowHumanFashion:OnLoad()
    self.LobbyHumanFashion3DOperator = LobbyHumanFashion3DOperator()
    local bdrWidget = self.pWidgetRef.kmbdrActor
    self.LobbyHumanFashion3DOperator:Init({bdrWidget = bdrWidget})
end

function ULLobbyShowHumanFashion:OnUnload()
    self.LobbyHumanFashion3DOperator:Uninit()
    self.LobbyHumanFashion3DOperator = nil
end


function ULLobbyShowHumanFashion:OnShow()
    local tbParam = self.tbParam
    self.LobbyHumanFashion3DOperator:Activate()
    local pActorLocation, pActorRotation = tbParam.fnGetLocationAndRotatorByTag(tbParam.szActorTag)
    self.LobbyHumanFashion3DOperator:SetActorLocation(pActorLocation)
    self.LobbyHumanFashion3DOperator:SetActorRotator(pActorRotation)
    self.LobbyHumanFashion3DOperator:SetAnimation(tbParam.szAnim)
    self.LobbyHumanFashion3DOperator:SetArmorTypeAndLevel(tbParam.nArmorType, tbParam.nArmorLevel)
    self.LobbyHumanFashion3DOperator:Display(tbParam.nAvatarId, tbParam.tbFashionTemplateIds, tbParam.tbAppearanceIds)
end

function ULLobbyShowHumanFashion:OnHide()
    self.LobbyHumanFashion3DOperator:Deactivate()
end


return ULLobbyShowHumanFashion