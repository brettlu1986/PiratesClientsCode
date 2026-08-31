-----------------------------------------------------
--File Name    : CameraShotTriggerDescriptor.lua
--Author       : WuJizhou
--Create Time  : 2018-3-15 16:42:49
--Description  : CameraShotTriggerDescriptor
-----------------------------------------------------
local CameraShotTriggerDescriptor = {}

function CameraShotTriggerDescriptor:ExportWildSceneData(tbSceneData, tbSourceDescriptor, tbOutExportedDescriptor)
    local tbAllData = tbSourceDescriptor.CameraShotTriggers
    if tbAllData == nil then
        return
    end
    local tbCameraShotTrigger = tbOutExportedDescriptor.tbCameraShotTriggers
    if tbCameraShotTrigger == nil then 
        tbCameraShotTrigger = {}
        tbOutExportedDescriptor.tbCameraShotTriggers = tbCameraShotTrigger
    end

    for _, tbData in ipairs(tbAllData) do
        table.insert(tbCameraShotTrigger, tbData)
    end
end

return CameraShotTriggerDescriptor