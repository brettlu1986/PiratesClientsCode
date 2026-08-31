-----------------------------------------------------
--File Name    : ShipThrownItemCarronadeDataTableHelper.lua
--Author       : Song Fuhao
--Create Time  : 2020-02-20
--Description  : 船投掷物（臼炮）配置读取
-----------------------------------------------------
local ShipThrownItemCarronadeDataTableHelper = {}

local ShipThrownItemDataTableHelper = require("ShipThrownItemDataTableHelper")

function ShipThrownItemCarronadeDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    ShipThrownItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nMaxPreThrownItem   = Parser:Get("max_pre_thrown_time"  , 0.0   , Parser.TypeFloat)
    NewTemplate.nGravityZ           = Parser:Get("gravity_z"            , 0.0   , Parser.TypeFloat) * 100
    NewTemplate.nEffectType         = Parser:Get("effect_type"          , -1    , Parser.TypeInt)
    NewTemplate.nEffectDuration     = Parser:Get("effect_duration"      , 0.0   , Parser.TypeFloat)
    NewTemplate.nEffectBuffId       = Parser:Get("effect_buff_id"       , -1    , Parser.TypeInt)
    NewTemplate.bCausingDamage      = Parser:Get("causing_damage"       , false , Parser.TypeBool)
end

return ShipThrownItemCarronadeDataTableHelper