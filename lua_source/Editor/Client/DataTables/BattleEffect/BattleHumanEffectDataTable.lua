--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT] 
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]
local BattleHumanEffectDataTable = {}
BattleHumanEffectDataTable.szFileName = "client/battle/battle_player_hit_effect.tab"

function BattleHumanEffectDataTable:OnEditorDefine(Parser)
    Parser:Define("nArmorId",          "armor_id",           -1,    Parser.TypeInt)
    Parser:Define("tbWeaponTemplates", "weapon_templateids", nil,   Parser.TypeArrayInt)
    Parser:Define("nBodyPart",         "body_part",          -1,    Parser.TypeInt)
    Parser:Define("nThump",            "thump",              -1,    Parser.TypeInt)
    Parser:Define("nEmitterId",        "emitter_id",         -1,    Parser.TypeInt)
    Parser:Define("nSoundId",          "sound_id",           -1,    Parser.TypeInt)
    Parser:Define("fSelfTakerVolume",  "self_taker_volume",   1,    Parser.TypeFloat)
    Parser:Define("fOtherTakerVolume", "other_taker_volume",  1,    Parser.TypeFloat)
end

function BattleHumanEffectDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbHumanArmors = tbContainer[tbNewTemplate.nArmorId] or {}
    tbContainer[tbNewTemplate.nArmorId] = tbHumanArmors

    for _, nWeaponTemplateId in pairs(tbNewTemplate.tbWeaponTemplates) do
        local key = string.format( "%d_%d_%d", nWeaponTemplateId, tbNewTemplate.nBodyPart, tbNewTemplate.nThump)
        tbHumanArmors[key] = tbNewTemplate
    end
    
    return true
end

-- [EXPORT BEGIN]
function BattleHumanEffectDataTable:GetEffectId(nArmorId, nWeaponTemplateId, nBodyPart, bThump, bSelfIsTaker)
    local tbArmorIds = {nArmorId, -1}

    for _, nCurArmorId in pairs(tbArmorIds) do
        local tbHumanArmors = self.tbContainer[nCurArmorId]
        if tbHumanArmors then
            local tbWeaponTemplateIds = {nWeaponTemplateId, -1}
            for _, nCurWeaponTemplateId in pairs(tbWeaponTemplateIds) do
                local tbBodyParts = {nBodyPart, -1}
                for _, nCurBodyPart in pairs(tbBodyParts) do
                    local tbThump = {-1}
                    if bThump then
                        tbThump = {1, -1}
                    end

                    for _, nCurThump in pairs(tbThump) do
                        local key = string.format( "%d_%d_%d", nCurWeaponTemplateId, nCurBodyPart, nCurThump)

                        if tbHumanArmors[key] then
                            return tbHumanArmors[key].nEmitterId, tbHumanArmors[key].nSoundId, 
                                   bSelfIsTaker and tbHumanArmors[key].fSelfTakerVolume or tbHumanArmors[key].fOtherTakerVolume
                        end
                    end
                end
            end
        end
    end

    return -1, -1, 1
end
-- [EXPORT END]

return BattleHumanEffectDataTable