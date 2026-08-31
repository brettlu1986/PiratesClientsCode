-----------------------------------------------------
--File Name    : HomelandShipPositionDescriptor.lua
--Author       : WuJizhou
--Create Time  : 2010-5-17 15:44:58
--Description  : HomelandShipPositionDescriptor
-----------------------------------------------------
local HomelandShipPositionDescriptor = {}

function HomelandShipPositionDescriptor:ExportWildSceneData(tbSceneData, tbSourceDescriptor, tbOutExportedDescriptor)
    local tbAllTeleportPointData = tbSourceDescriptor.ShipPosition
    if tbAllTeleportPointData == nil then
        return
    end
    local tbTeleportPoints = tbOutExportedDescriptor.tbShipPosition
    if tbTeleportPoints == nil then
        tbTeleportPoints = {}
        tbOutExportedDescriptor.tbShipPosition = tbTeleportPoints
    end

    for _, tbData in ipairs(tbAllTeleportPointData) do
        table.insert(tbTeleportPoints, tbData)
    end
end

return HomelandShipPositionDescriptor