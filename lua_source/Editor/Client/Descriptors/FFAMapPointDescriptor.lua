local FFAMapPointDescriptor = {}

function FFAMapPointDescriptor:ExportDungeonSceneData(tbData, tbSourceDescriptor, tbOutExportedDescriptor)
    if not tbSourceDescriptor.FFAMapPoint then
        return
    end 
    local FFAMapPoint = {}
    for k, v in pairs(tbSourceDescriptor.FFAMapPoint) do
        local tbPointData = FFAMapPoint[v.Name]
        if not tbPointData then
            tbPointData = {}
            tbPointData.X = v.Transform.X 
            tbPointData.Y = v.Transform.Y
            tbPointData.Z = v.Transform.Z
            FFAMapPoint[v.Name] = tbPointData
        else
            logerror("FFAMapPointDescriptor:ExportDungeonSceneData, duplicate Point, name= ", v.Name)
        end
    end
    tbOutExportedDescriptor.FFAMapPoint = FFAMapPoint
end

return FFAMapPointDescriptor