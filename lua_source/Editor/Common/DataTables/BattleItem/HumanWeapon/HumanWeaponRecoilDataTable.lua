--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    tbContainer: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT]
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]

local HumanWeaponRecoilDataTable = {}

local HumanWeaponDef = require("HumanWeaponDef")
local RecoilProperty = HumanWeaponDef.RecoilProperty

HumanWeaponRecoilDataTable.szFileName = "common/ffa/item/human_weapon/weapon_recoil.tab"

local tbColumnFieldToPropertyField = {}

local function Define(Parser, szProperty, szColumn, defaultValue, valueType)
    Parser:Define(szProperty, szColumn, defaultValue, valueType)
    tbColumnFieldToPropertyField[szColumn] = szProperty
end

function HumanWeaponRecoilDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId"                         , "id"                              , -1  , Parser.TypeInt)
    Define(Parser, RecoilProperty.RecoilUpperAngle            , "recoil_upper_angle"              , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.RecoildLowerAngle           , "recoil_lower_angle"              , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.RecoildHUpperAngle          , "recoil_h_upper_angle"            , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.RecoilHorizontalMaxPercent  , "recoil_horizontal_max_percent"   , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.RecoilHorizontalMinPercent  , "recoil_horizontal_min_percent"   , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.RecoilDuration              , "recoil_duration"                 , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.RecoilRecoverMaxPercent     , "recoil_recover_max_percent"      , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.RecoilRecoverMinPercent     , "recoil_recover_min_percent"      , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.UseRecoverInVertical        , "use_recover_in_vertical"         , 0   , Parser.TypeInt)
    Define(Parser, RecoilProperty.RecoilMaxYaw                , "recoil_max_yaw"                  , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.RecoilMinYaw                , "recoil_min_yaw"                  , 0.0 , Parser.TypeFloat)

    Define(Parser, RecoilProperty.RecoilUpperAngleAim            , "recoil_upper_angle_aim"              , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.RecoildLowerAngleAim           , "recoil_lower_angle_aim"              , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.RecoildHUpperAngleAim          , "recoil_h_upper_angle_aim"            , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.RecoilHorizontalMaxPercentAim  , "recoil_horizontal_max_percent_aim"   , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.RecoilHorizontalMinPercentAim  , "recoil_horizontal_min_percent_aim"   , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.RecoilDurationAim              , "recoil_duration_aim"                 , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.RecoilRecoverMaxPercentAim     , "recoil_recover_max_percent_aim"      , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.RecoilRecoverMinPercentAim     , "recoil_recover_min_percent_aim"      , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.UseRecoverInVerticalAim        , "use_recover_in_vertical_aim"         , 0   , Parser.TypeInt)
    
    
    Define(Parser, RecoilProperty.RecoilMaxYawAim                , "recoil_max_yaw_aim"                  , 0.0 , Parser.TypeFloat)
    Define(Parser, RecoilProperty.RecoilMinYawAim                , "recoil_min_yaw_aim"                  , 0.0 , Parser.TypeFloat)
end

function HumanWeaponRecoilDataTable:GetPropertyField(szColumnFiled)
    local szProperName = tbColumnFieldToPropertyField[szColumnFiled]
    return szProperName
end
-- [EXPORT BEGIN]
function HumanWeaponRecoilDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

return HumanWeaponRecoilDataTable
