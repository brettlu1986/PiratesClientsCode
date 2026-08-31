-----------------------------------------------------
--File Name    : HomelandHQPlayerStartDescriptor.lua
--Author       : WuJizhou
--Create Time  : 2010-5-15 15:44:58
--Description  : HomelandHQPlayerStartDescriptor
-----------------------------------------------------
local HomelandHQPlayerStartDescriptor = {}

function HomelandHQPlayerStartDescriptor:ExportWildSceneData(tbSceneData, tbSourceDescriptor, tbOutExportedDescriptor)
    local tbAllTeleportPointData = tbSourceDescriptor.HQPlayerStarts
    if tbAllTeleportPointData == nil then
        return
    end
    local tbTeleportPoints = tbOutExportedDescriptor.tbHQPlayerStarts
    if tbTeleportPoints == nil then
        tbTeleportPoints = {}
        tbOutExportedDescriptor.tbHQPlayerStarts = tbTeleportPoints
    end

    for _, tbData in ipairs(tbAllTeleportPointData) do
        table.insert(tbTeleportPoints, tbData)
    end
end

return HomelandHQPlayerStartDescriptor