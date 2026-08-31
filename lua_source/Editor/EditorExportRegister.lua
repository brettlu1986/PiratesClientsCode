local EditorExportRegister = {}

function EditorExportRegister:Register(Manager)
    Manager:Register("IniExporter")
    Manager:Register("DataTableExporter")
    Manager:Register("CopyFileExporter")
    Manager:Register("OtherExporter")
end

return EditorExportRegister