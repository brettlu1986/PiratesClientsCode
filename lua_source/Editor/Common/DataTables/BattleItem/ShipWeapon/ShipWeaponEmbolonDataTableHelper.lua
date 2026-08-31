local ShipWeaponEmbolonDataTableHelper = {}

local ShipWeaponDataTableHelper = require("ShipWeaponDataTableHelper")

function ShipWeaponEmbolonDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    ShipWeaponDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nFiringBuffId           = Parser:Get("firing_buff_id"           ,  -1, Parser.TypeInt)
    NewTemplate.nAttckStandardSpeed     = Parser:Get("attck_standard_speed"     ,   0, Parser.TypeFloat)
    NewTemplate.nDamageRatioDelta       = Parser:Get("damage_ratio_delta"       ,   0, Parser.TypeFloat)
    NewTemplate.nMaxDamageRatioAddition = Parser:Get("max_damage_ratio_addition",   0, Parser.TypeFloat)
    NewTemplate.szEffectDataRes         = Parser:Get("effect_data_res"          , nil, Parser.TypeString)
end

return ShipWeaponEmbolonDataTableHelper