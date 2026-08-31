-----------------------------------------------------
--File Name    : AtmospherePathNodeDescriptor.lua
--Author       : WuJizhou
--Create Time  : 2018-3-15 10:35:51
--Description  : AtmospherePathNodeDescriptor
-----------------------------------------------------
local AtmospherePathNodeDescriptor = {}

function AtmospherePathNodeDescriptor:ExportWildSceneData(tbSceneData, tbSourceDescriptor, tbOutExportedDescriptor)
    local tbAllPathNodeData = tbSourceDescriptor.PathNodes
    if tbAllPathNodeData == nil then
        return
    end
    local tbPathNodes = tbOutExportedDescriptor.tbPathNodes
    if tbPathNodes == nil then
        tbPathNodes = {}
        tbOutExportedDescriptor.tbPathNodes = tbPathNodes
    end

    for _, tbPathNodeData in ipairs(tbAllPathNodeData) do
        table.insert(tbPathNodes, tbPathNodeData)
    end

end
return AtmospherePathNodeDescriptor