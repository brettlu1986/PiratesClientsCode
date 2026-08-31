local luaclass = require ("luaclass")
local UPMapObj = require("UPMapObj")
local UPMapObjForTransporterPathNode = luaclass("UPMapObjForTransporterPathNode", UPMapObj)

UPMapObjForTransporterPathNode.tbWorldPos = nil

function UPMapObjForTransporterPathNode:RefreshPosition(nUIPosX, nUIPosY)
    local pUIPos = Vector2D{X = nUIPosX, Y = nUIPosY}
    self.pWidgetRef.Slot:SetPosition(pUIPos)  
end

function UPMapObjForTransporterPathNode:SetWorldPosition(nWorldX, nWorldY)
    self.tbWorldPos = {X = nWorldX, Y = nWorldY}
end

function UPMapObjForTransporterPathNode:GetWorldPosition()
    return self.tbWorldPos
end

return UPMapObjForTransporterPathNode
