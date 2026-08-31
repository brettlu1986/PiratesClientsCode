-----------------------------------------------------
--File Name    : PartnerItemDataTableHelper.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-19
--Description  :伙伴的配置表读取helper
-----------------------------------------------------
local PartnerItemDataTableHelper = {}

function PartnerItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nPersonality            = Parser:Get("personality"              , -1    , Parser.TypeInt)
    NewTemplate.nSpeciality             = Parser:Get("speciality"               , -1    , Parser.TypeInt)
    NewTemplate.tbHpList                = Parser:Get("hp_list"                  , {}    , Parser.TypeArrayInt)
    NewTemplate.tbWeaponList1           = Parser:Get("weapon_list_1"            , nil   , Parser.TypeArrayInt)
    NewTemplate.tbWeaponList2           = Parser:Get("weapon_list_2"            , nil   , Parser.TypeArrayInt)
    NewTemplate.tbWeaponList3           = Parser:Get("weapon_list_3"            , nil   , Parser.TypeArrayInt)
    NewTemplate.tbSkillList             = Parser:Get("skill_list"               , {}    , Parser.TypeArrayInt)
    NewTemplate.szDefaultSkinPosterRes  = Parser:Get("default_skin_poster_res"  , nil   , Parser.TypeString)
end

return PartnerItemDataTableHelper