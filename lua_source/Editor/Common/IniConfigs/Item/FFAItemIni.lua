--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local FFAItemIni = {}
FFAItemIni.szFileName = "common/ffa/item/item.ini"

function FFAItemIni:OnParse(Parser)
    local tbSceneItem = {}
    tbSceneItem.nLandMeshScale =  Parser:Get("scene_item", "land_mesh_scale", -1, Parser.TypeNumber)
    tbSceneItem.nOceanMeshScale =  Parser:Get("scene_item", "ocean_mesh_scale", -1, Parser.TypeNumber)
    tbSceneItem.nAirDropNormalMeshScale =  Parser:Get("scene_item", "airdrop_normal_mesh_scale", -1, Parser.TypeNumber)
    tbSceneItem.nAirDropOceanMeshScale =  Parser:Get("scene_item", "airdrop_ocean_mesh_scale", -1, Parser.TypeNumber)
    tbSceneItem.nAirDropLandMeshScale =  Parser:Get("scene_item", "airdrop_land_mesh_scale", -1, Parser.TypeNumber)
    tbSceneItem.bCheckItemPos =  Parser:Get("scene_item", "check_item_pos", false, Parser.TypeBool)
    tbSceneItem.nCheckItemTop =  Parser:Get("scene_item", "check_item_top", -1, Parser.TypeNumber)
    self.tbSceneItem = tbSceneItem

    local tbSceneItemPackage = {}
    tbSceneItemPackage.nPlayerDieHumanBoxTemplateId = Parser:Get("sceneitempackage", "player_die_human_box_id", -1, Parser.TypeNumber)
    tbSceneItemPackage.nPlayerDieShipBoxTemplateId = Parser:Get("sceneitempackage", "player_die_ship_box_id", -1, Parser.TypeNumber)
    self.tbSceneItemPackage = tbSceneItemPackage

    local tbInventory = {}
    tbInventory.nDefaultInventoryCapacity = Parser:Get("inventory", "default_inventory_capacity", -1, Parser.TypeNumber)
    tbInventory.nDefaultMaxInventorySlots = Parser:Get("inventory", "default_max_inventory_slots", -1, Parser.TypeNumber)
    self.tbInventory = tbInventory

    local tbMaterial = {}
    tbMaterial.nMaxMaterialStackCount = Parser:Get("material", "max_material_stack_count", -1, Parser.TypeNumber)
    tbMaterial.nMaxMaterialType = Parser:Get("material", "max_material_type", -1, Parser.TypeNumber)
    self.tbMaterial = tbMaterial

    local tbPositionOffset = {}
    tbPositionOffset.nOffsetMinLand = Parser:Get("position_offset", "offset_min_land", -1, Parser.TypeNumber)
    tbPositionOffset.nOffsetMaxLand = Parser:Get("position_offset", "offset_max_land", -1, Parser.TypeNumber)
    tbPositionOffset.nOffsetMinSea = Parser:Get("position_offset", "offset_min_sea", -1, Parser.TypeNumber)
    tbPositionOffset.nOffsetMaxSea = Parser:Get("position_offset", "offset_max_sea", -1, Parser.TypeNumber)
    self.tbPositionOffset = tbPositionOffset

    local tbAutoPickUp = {}
    tbAutoPickUp.tbIgnoreShipWeapons = Parser:Get("auto_pick_up", "ignore_ship_weapons", {}, Parser.TypeArrayNumber)
    self.tbAutoPickUp = tbAutoPickUp

    local tbBullet = {}
    tbBullet.bHumanBulletInfinite = Parser:Get("bullet", "human_bullet_infinite", false, Parser.TypeBool)
    tbBullet.bShipBulletInfinite = Parser:Get("bullet", "ship_bullet_infinite", false, Parser.TypeBool)
    self.tbBullet = tbBullet

    local tbShip = {}
    tbShip.nInitShipGrade = Parser:Get("ship", "init_ship_grade", 0, Parser.TypeNumber)
    self.tbShip = tbShip

    local tbShipPickupBox = {}
    tbShipPickupBox.nPosture = Parser:Get("ship_pick_up_box", "posture", 0, Parser.TypeNumber)
    self.tbShipPickupBox = tbShipPickupBox
end

return FFAItemIni
