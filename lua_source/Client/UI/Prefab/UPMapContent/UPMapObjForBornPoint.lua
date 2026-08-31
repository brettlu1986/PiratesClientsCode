local luaclass = require ("luaclass")
local UPMapObj = require("UPMapObj")
local UPMapObjForBornPoint = luaclass("UPMapObjForBornPoint", UPMapObj)
local UISetUtils = require("UISetUtils")

UPMapObjForBornPoint.tbWorldPos = nil
UPMapObjForBornPoint.nPointId = nil

function UPMapObjForBornPoint:SetWorldPosition(nX, nY)
    self.tbWorldPos = {X = nX, Y = nY}
end

function UPMapObjForBornPoint:GetWorldPosition()
    return self.tbWorldPos
end

function UPMapObjForBornPoint:RefreshPosition(nUIPosX, nUIPosY)
    local pUIPos = Vector2D{X = nUIPosX, Y = nUIPosY}
    self.pWidgetRef.Slot:SetPosition(pUIPos)  
end

function UPMapObjForBornPoint:Refresh(MapOpObj)
    if self.nPointId ~= nil then
        MapOpObj:RemoveContentPoint(self.nPointId)
    end
    self.nPointId = MapOpObj:AddContentPoint(self.pWidgetRef, Vector{X = self.tbWorldPos.X, Y = self.tbWorldPos.Y, Z = 0})    
end

function UPMapObjForBornPoint:Clear(MapOpObj)
    if self.nPointId ~= nil then
        MapOpObj:RemoveContentPoint(self.nPointId)
    end    
end

function UPMapObjForBornPoint:PlaySelectAnimation()
end

function UPMapObjForBornPoint:SetColor(pSlateColor)
    UISetUtils.SetImageBrushTint(self.pWidgetRef.imgIcon, pSlateColor)
end

return UPMapObjForBornPoint
