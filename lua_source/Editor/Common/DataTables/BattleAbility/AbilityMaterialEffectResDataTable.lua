-----------------------------------------------------
--File Name    : AbilityMaterialEffectResDataTable.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-21
--Description  : 材质效果资源配置表
-----------------------------------------------------

local AbilityMaterialEffectResDataTable = {}

local MaterialEffectTypeDef = require("MaterialEffectTypeDef")

AbilityMaterialEffectResDataTable.szFileName = "common/res/ability_material_effect_res.tab"

function AbilityMaterialEffectResDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nShipId")
    Parser:Define("nShipId"                 , "ship_id"                     , -1    , Parser.TypeInt)
    Parser:Define("szFrozenMateria0"        , "frozen_material_0"           , ""    , Parser.TypeString)
    Parser:Define("szFrozenMateria1"        , "frozen_material_1"           , ""    , Parser.TypeString)
    Parser:Define("szFrozenMateria2"        , "frozen_material_2"           , ""    , Parser.TypeString)
    Parser:Define("szFrozenMateria3"        , "frozen_material_3"           , ""    , Parser.TypeString)
    Parser:Define("szFrozenMateria4"        , "frozen_material_4"           , ""    , Parser.TypeString)
    Parser:Define("szFrozenMateria5"        , "frozen_material_5"           , ""    , Parser.TypeString)
    Parser:Define("szFrozenParameterName"   , "frozen_parameter_name"       , nil   , Parser.TypeString)
    Parser:Define("nFrozenBeginAnimDuration", "frozen_begin_anim_duration"  , 0.0   , Parser.TypeFloat)
    Parser:Define("nFrozenEndAnimDuration"  , "frozen_end_anim_duration"    , 0.0   , Parser.TypeFloat)
end

function AbilityMaterialEffectResDataTable:OnEditorParseLine(Parser, tbContainer, tbTemplate)
    tbTemplate.tbEffects = {
        [MaterialEffectTypeDef.Frozen] = {
            tbMateriaList       = {
                tbTemplate.szFrozenMateria0,
                tbTemplate.szFrozenMateria1,
                tbTemplate.szFrozenMateria2,
                tbTemplate.szFrozenMateria3,
                tbTemplate.szFrozenMateria4,
                tbTemplate.szFrozenMateria5
            },
            szParameterName     = tbTemplate.szFrozenParameterName,
            nBeginAnimDuration  = tbTemplate.nFrozenBeginAnimDuration,
            nEndAnimDuration    = tbTemplate.nFrozenEndAnimDuration,
        }
    }
    tbTemplate.szFrozenMateria0 = nil
    tbTemplate.szFrozenMateria1 = nil
    tbTemplate.szFrozenMateria2 = nil
    tbTemplate.szFrozenMateria3 = nil
    tbTemplate.szFrozenMateria4 = nil
    tbTemplate.szFrozenMateria5 = nil
    tbTemplate.szFrozenParamete = nil
    tbTemplate.nFrozenBeginAnimDuration = nil
    tbTemplate.nFrozenEndAnimDuration = nil
    tbTemplate.tbFrozenMateriaList = nil
    return true
end

-- [EXPORT BEGIN]
function AbilityMaterialEffectResDataTable:GetMaterialEffectInfoByType(nShipId, nMaterialEffectType)
    assert(nShipId and nMaterialEffectType)
    local tbTemplate = self.tbContainer[nShipId]
    if tbTemplate then
        return tbTemplate.tbEffects[nMaterialEffectType]
    else
        logerror(string.format("cannot find material effect template, ship_id = %d, effect_type = %d", nShipId, nMaterialEffectType))
        return {}
    end
end
-- [EXPORT END]

return AbilityMaterialEffectResDataTable
