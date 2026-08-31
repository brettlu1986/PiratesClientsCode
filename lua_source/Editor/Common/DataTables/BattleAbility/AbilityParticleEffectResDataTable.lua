-----------------------------------------------------
--File Name    : AbilityParticleEffectResDataTable.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-21
--Description  : 粒子效果资源配置表
-----------------------------------------------------

local AbilityParticleEffectResDataTable = {}

AbilityParticleEffectResDataTable.szFileName = "common/res/ability_particle_effect_res.tab"

function AbilityParticleEffectResDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId"                     , "id"                      , -1    , Parser.TypeInt)
    Parser:Define("szFxRes"                 , "fx_res"                  , nil   , Parser.TypeString)
    Parser:Define("nDuration"               , "duration"                , -1    , Parser.TypeFloat)
    Parser:Define("nBaseScale"              , "base_scale"              , 1     , Parser.TypeFloat)
    Parser:Define("bFxAutoScale"            , "auto_scale"              , true  , Parser.TypeBool)
    Parser:Define("bDestroyOnStop"          , "destroy_on_stop"         , true  , Parser.TypeBool)
    Parser:Define("bAttachToCharacter"      , "attach_to_character"     , true  , Parser.TypeBool)
    Parser:Define("bAbsoluteRotation"       , "absolute_rotation"       , false , Parser.TypeBool)
    Parser:Define("szAttachedFxSocketName"  , "attached_socket_name"    , nil   , Parser.TypeString)
    Parser:Define("szAttachedComponentName" , "attached_component_name" , nil   , Parser.TypeString)
end

-- [EXPORT BEGIN]
function AbilityParticleEffectResDataTable:GetTemplate( nTemplateId )
    return self.tbContainer[nTemplateId]
end
-- [EXPORT END]

return AbilityParticleEffectResDataTable
