local DungeonDescriptor = {}

function DungeonDescriptor:ExportDungeonSceneData(tbData, tbSourceDescriptor, tbOutExportedDescriptor)
    -- 副本的全导
    for k, v in pairs(tbSourceDescriptor) do
        tbOutExportedDescriptor[k] = v
    end
end

return DungeonDescriptor