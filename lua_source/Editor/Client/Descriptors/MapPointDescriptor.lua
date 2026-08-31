local MapPointDescriptor = {}

function MapPointDescriptor:ExportWildSceneData(tbData, tbSourceDescriptor, tbOutExportedDescriptor)
    if not tbSourceDescriptor.MapPoint then
        return
    end 
    local MapPoint = {}
    for k, v in pairs(tbSourceDescriptor.MapPoint) do
        local tbPointData = MapPoint[v.Name]
        if not tbPointData then
            tbPointData = {}
            tbPointData.X = v.Transform.X 
            tbPointData.Y = v.Transform.Y
            tbPointData.Z = v.Transform.Z
            MapPoint[v.Name] = tbPointData
        else
            logerror("MapPointDescriptor:ExportWildSceneData, duplicate Point, name= ", v.Name)
        end
    end
    tbOutExportedDescriptor.MapPoint = MapPoint
end

return MapPointDescriptor