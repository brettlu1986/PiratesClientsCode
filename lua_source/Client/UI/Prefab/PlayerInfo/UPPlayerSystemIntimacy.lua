local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPPlayerSystemIntimacy = luaclass("UPPlayerSystemIntimacy", PrefabBase)

function UPPlayerSystemIntimacy:Activate()
    local nPlayerId = self.Owner.ulPlayerInfo:GetTargetPlayerId()
    self.ulRelations:Activate(self.pWidgetRef.kRelationList, true, nPlayerId)
end

function UPPlayerSystemIntimacy:Deactivate()
    self.ulRelations:Deactivate()
end

function UPPlayerSystemIntimacy:OnLoad()
    local UILogicHelper = self.UILogicHelper
    self.ulRelations = UILogicHelper:CreateUILogic("ULLobbyFriendRelations")
end

function UPPlayerSystemIntimacy:OnUnload()
end

function UPPlayerSystemIntimacy:OnBindEvent(EventHelper)
end

return UPPlayerSystemIntimacy