-----------------------------------------------------
--File Name    : ShipShowDescriptor.lua
--Author       : WuJizhou
--Create Time  : 2018-3-12 11:30:46
--Description  : ShipShowDescriptor
-----------------------------------------------------
local ShipShowDescriptor = {}

function ShipShowDescriptor:ExportWildSceneData(tbData, tbSourceDescriptor, tbOutExportedDescriptor)
    local tbAllShipShowData = tbSourceDescriptor.ShipShow
    if tbAllShipShowData == nil then
        return
    end
    
    local tbShipShowDatas = tbOutExportedDescriptor.tbShipShowDatas
    if tbShipShowDatas == nil then
        tbShipShowDatas = {}
        tbOutExportedDescriptor.tbShipShowDatas = tbShipShowDatas
    end

    for i, data in pairs(tbAllShipShowData) do
        local tbTransform = data.Transform
        local tbNewData = {}
        tbNewData.nX = tbTransform.X
        tbNewData.nY = tbTransform.Y
        tbNewData.nZ = tbTransform.Z
        tbNewData.nYaw = tbTransform.Yaw
        tbNewData.bIsRight = data.LeftOrRight
        tbNewData.bIsFront = data.FrontOrBack
        table.insert(tbShipShowDatas, tbNewData)

    end

end




return ShipShowDescriptor