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
local HumanWeaponAnimationDataTable = {}

HumanWeaponAnimationDataTable.szFileName = "client/human/human_weapon_animation.tab"

function HumanWeaponAnimationDataTable:OnEditorDefine(Parser)
    Parser:Define("nWeaponId", "weapon_id", -1, Parser.TypeInt)
    Parser:Define("nEquipId", "equip_id", 0, Parser.TypeInt)
    Parser:Define("szAnimKey", "anim_key", 0, Parser.TypeString)
end

function HumanWeaponAnimationDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if not tbContainer[tbNewTemplate.nWeaponId] then  
        tbContainer[tbNewTemplate.nWeaponId] = {}
    end 
    tbContainer[tbNewTemplate.nWeaponId][tbNewTemplate.nEquipId] = tbNewTemplate

    return true;
end

-- [EXPORT BEGIN]
function HumanWeaponAnimationDataTable:GetWeaponAnim(nWeaponId, nEquipId)
    local tbWeapon = self.tbContainer[nWeaponId]
    if not tbWeapon then  
        return nil
    end 
    local bDefaultEquip = false
    if not nEquipId then  
        nEquipId = 0
        bDefaultEquip = true
    end
    if not tbWeapon[nEquipId] and not bDefaultEquip then 
        nEquipId = 0
    end 
    return tbWeapon[nEquipId].szAnimKey
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function HumanWeaponAnimationDataTable:GetContainer()
    return self.tbContainer
end
-- [EXPORT END]

return HumanWeaponAnimationDataTable
