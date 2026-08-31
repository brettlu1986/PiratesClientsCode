-----------------------------------------------------
--File Name    : ShipThrownItemDataTableHelper.lua
--Author       : Song Fuhao
--Create Time  : 2020-02-20
--Description  : 船投掷物配置读取
-----------------------------------------------------
local ShipThrownItemDataTableHelper = {}

local ShipWeaponDataTableHelper = require("ShipWeaponDataTableHelper")

function ShipThrownItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    ShipWeaponDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nThrownIterval      = Parser:Get("thrown_interval"  , 0     , Parser.TypeInt)
    NewTemplate.szFireNormalRes     = Parser:Get("fire_normal_res"  , nil   , Parser.TypeString)
    NewTemplate.szFirePressedRes    = Parser:Get("fire_pressed_res" , nil   , Parser.TypeString)
end

return ShipThrownItemDataTableHelper