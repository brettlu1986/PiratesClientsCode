-----------------------------------------------------
--File Name    : ShipWeaponTemplateDef.lua
--Author       : Song Fuhao
--Create Time  : 2018-08-13
--Description  : 船的武器参数模板类型定义
-----------------------------------------------------
local ShipWeaponTemplateDef = {
    CANNON          = 1,        -- 火炮
    POWDER_KEG      = 2,        -- 火药桶（鱼雷）
    CARRONADE       = 3,        -- 臼炮
    TORPEDO         = 4,        -- 水雷
    EMBOLON         = 5,        -- 撞角
    FLAMER          = 6,        -- 喷火器
    Max             = 6
}

local tbBpControlClassPaths = {
    [ShipWeaponTemplateDef.CANNON]      = "/Game/Game/ShipEx/Component/Weapon/BP_ShipCannonComponent.BP_ShipCannonComponent_C",
    [ShipWeaponTemplateDef.POWDER_KEG]  = "/Game/Game/ShipEx/Component/Weapon/BP_ShipPowderKegComponent.BP_ShipPowderKegComponent_C",
    [ShipWeaponTemplateDef.CARRONADE]   = "/Game/Game/ShipEx/Component/Weapon/BP_ShipCarronadeComponent.BP_ShipCarronadeComponent_C",
    [ShipWeaponTemplateDef.TORPEDO]     = "/Game/Game/ShipEx/Component/Weapon/BP_ShipTorpedoComponent.BP_ShipTorpedoComponent_C",
    [ShipWeaponTemplateDef.EMBOLON]     = "/Game/Game/ShipEx/Component/Weapon/BP_ShipEmbolonComponent.BP_ShipEmbolonComponent_C",
    [ShipWeaponTemplateDef.FLAMER]      = "/Game/Game/ShipEx/Component/Weapon/BP_ShipFlamerComponent.BP_ShipFlamerComponent_C"
}

function ShipWeaponTemplateDef.GetBPControlClassPath(nTemplateType)
    return tbBpControlClassPaths[nTemplateType]
end

return ShipWeaponTemplateDef