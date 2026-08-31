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

local HumanWeaponCategoryPropertyDataTable = {}

local L10N = require("L10N")

HumanWeaponCategoryPropertyDataTable.szFileName = "common/ffa/item/human_weapon/weapon_category_property.tab"

function HumanWeaponCategoryPropertyDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId"                  , "id"                      , -1  , Parser.TypeInt)
    Parser:Define("l10nName"             , "name"                    , L10N.NullString, Parser.TypeL10N)
    Parser:Define("nHeadDamageFactor"    , "head_damage_factor"      , 0.0 , Parser.TypeFloat)
    Parser:Define("nBodyDamageFactor"    , "body_damage_factor"      , 0.0 , Parser.TypeFloat)
    Parser:Define("nAllFoursDamageFactor", "all_fours_damage_factor" , 0.0 , Parser.TypeFloat)
    Parser:Define("nSpeedFactorWhenCarry", "speed_factor_when_carry" , 0.0 , Parser.TypeFloat)
    Parser:Define("nSpeedFactorWhenHold" , "speed_factor_when_hold"  , 0.0 , Parser.TypeFloat)
    Parser:Define("nSpeedFactorWhenAim"  , "speed_factor_when_aim"   , 0.0 , Parser.TypeFloat)
    Parser:Define("nSpeedFactorWhenFire" , "speed_factor_when_fire"  , 0.0 , Parser.TypeFloat)
    Parser:Define("nSpeedFactorWhenLoad" , "speed_factor_when_load"  , 0.0 , Parser.TypeFloat)

end


-- [EXPORT BEGIN]
function HumanWeaponCategoryPropertyDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

return HumanWeaponCategoryPropertyDataTable
