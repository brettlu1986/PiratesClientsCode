local OtherExporterRegisterCommon = {}

function OtherExporterRegisterCommon:Register(Exporter)
    Exporter:Register("CopyFileWithSceneRedirection")
    Exporter:Register("ExportShipLuaTemplate")
    Exporter:Register("ExportAIDoor")
    Exporter:Register("ExportAIVehicle")
end

return OtherExporterRegisterCommon