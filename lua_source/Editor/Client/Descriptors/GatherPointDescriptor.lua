-----------------------------------------------------
--File Name    : GatherPointDescriptor.lua
--Author       : WuJizhou
--Create Time  : 2018-3-14 16:55:46
--Description  : GatherPointDescriptor
-----------------------------------------------------
local GatherPointDescriptor = {}

function GatherPointDescriptor:ExportWildSceneData(tbData, tbSourceDescriptor, tbOutExportedDescriptor)
    local tbAllGatherPointData = tbSourceDescriptor.GatherPoints
    if tbAllGatherPointData == nil then
        return
    end
    local tbGatherPoints = tbOutExportedDescriptor.tbGatherPoints
    if not tbGatherPoints then
        tbGatherPoints = {}
        tbOutExportedDescriptor.tbGatherPoints = tbGatherPoints
    end

    for _, tbPointData in ipairs(tbAllGatherPointData) do
        table.insert(tbGatherPoints, tbPointData)
    end


end

return GatherPointDescriptor