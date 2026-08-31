local HomelandDescriptor = {}

function HomelandDescriptor:ExportWildSceneData(tbData, tbSourceDescriptor, tbOutExportedDescriptor)
    if not tbSourceDescriptor.HomelandBlock then
        return
    end 
    local HomelandBlock = {}
    for k, v in pairs(tbSourceDescriptor.HomelandBlock) do
        HomelandBlock[v.BlockId] = v
    end
    tbOutExportedDescriptor.HomelandBlock = HomelandBlock
    -- for k, v in pairs(tbSourceDescriptor) do
    --     tbOutExportedDescriptor[k] = v
    -- end
end

return HomelandDescriptor