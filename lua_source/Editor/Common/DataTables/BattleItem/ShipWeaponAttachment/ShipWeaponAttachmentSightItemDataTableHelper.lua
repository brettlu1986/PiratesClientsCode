local ShipWeaponAttachmentSightItemDataTableHelper = {}

function ShipWeaponAttachmentSightItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nTelescopeScale = Parser:Get("telescope_scale", 0, Parser.TypeInt)
    NewTemplate.nCoreDetect = Parser:Get("core_detect", 0, Parser.TypeInt)
    NewTemplate.nCameraMoveScaleX = Parser:Get("camera_move_scale_x", 0, Parser.TypeFloat)
    NewTemplate.nCameraMoveScaleY = Parser:Get("camera_move_scale_y", 0, Parser.TypeFloat)
end

return ShipWeaponAttachmentSightItemDataTableHelper