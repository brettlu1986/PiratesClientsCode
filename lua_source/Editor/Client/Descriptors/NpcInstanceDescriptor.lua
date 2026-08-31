local NpcInstanceDescriptor = {}

function NpcInstanceDescriptor:ExportWildSceneData(tbData, tbSourceDescriptor, tbOutExportedDescriptor)
    local tbAllNpcData = tbSourceDescriptor.Npcs
    if(tbAllNpcData == nil) then
        return
    end

    local tbNpcs = tbOutExportedDescriptor.tbNpcs
    if(tbNpcs == nil) then
        tbNpcs = {}
        tbOutExportedDescriptor.tbNpcs = tbNpcs
    end

    local tbTrans, tbNewData
    for _, tbNpcData in ipairs(tbAllNpcData) do
        tbTrans = tbNpcData.Transform
        tbNewData = {}
        tbNewData.nId = tbNpcData.TemplateId
        tbNewData.nX = tbTrans.X
        tbNewData.nY = tbTrans.Y
        tbNewData.nZ = tbTrans.Z
        table.insert(tbNpcs, tbNewData)
    end
end

return NpcInstanceDescriptor