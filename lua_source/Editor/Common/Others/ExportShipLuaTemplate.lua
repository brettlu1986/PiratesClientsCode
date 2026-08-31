local ExportShipLuaTemplate = {}

local EditorExportModeDefine = require("EditorExportModeDefine")

ExportShipLuaTemplate.bNeedSaveTable = false

function ExportShipLuaTemplate:Export(nMode)
    ShipExporter.Export(true, nMode == EditorExportModeDefine.Full)
end

return ExportShipLuaTemplate