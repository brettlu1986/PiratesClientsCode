-----------------------------------------------------
--File Name    : TeleportPointDescriptor.lua
--Author       : WuJizhou
--Create Time  : 2018-3-15 15:44:58
--Description  : TeleportPointDescriptor
-----------------------------------------------------
local TeleportPointDescriptor = {}

function TeleportPointDescriptor:ExportWildSceneData(tbSceneData, tbSourceDescriptor, tbOutExportedDescriptor)
    local tbAllTeleportPointData = tbSourceDescriptor.PlayerStarts
    if tbAllTeleportPointData == nil then
        return
    end
    local tbTeleportPoints = tbOutExportedDescriptor.tbPlayerStarts
    if tbTeleportPoints == nil then 
        tbTeleportPoints = {}
        tbOutExportedDescriptor.tbPlayerStarts = tbTeleportPoints
    end

    for _, tbData in ipairs(tbAllTeleportPointData) do
        table.insert(tbTeleportPoints, tbData)
    end
end

return TeleportPointDescriptor