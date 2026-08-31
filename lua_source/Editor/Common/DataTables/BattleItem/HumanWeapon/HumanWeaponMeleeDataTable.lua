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
local AnimationResDataTableNew = require("AnimationResDataTableNew")
local HumanWeaponMeleeDataTable = {}

local DEFAULT_HUMAN_TEMPLATE_ID = 100000

local tbAnimParams = {
    nTemplateId = DEFAULT_HUMAN_TEMPLATE_ID,
}

-- [EXPORT BEGIN]
local DEFAULT_EQUIP_ID = 1
-- [EXPORT END]

HumanWeaponMeleeDataTable.szFileName = "common/ffa/item/human_weapon/human_weapon_melee.tab"

function HumanWeaponMeleeDataTable:OnEditorDefine(Parser)
    -- Parser:SetKey("nWeaponId")
    Parser:Define("nWeaponId", "weapon_id", -1, Parser.TypeInt)
    Parser:Define("nEquipId", "equip_id", DEFAULT_EQUIP_ID, Parser.TypeInt)
    Parser:Define("IsRootmotion", "is_rootmotion", false, Parser.TypeBool)
    Parser:Define("IsRandom", "is_random", true, Parser.TypeBool)
    Parser:Define("nComboTime", "combo_time", 0, Parser.TypeFloat)
    Parser:Define("nAnimCount", "anim_count", 1, Parser.TypeInt)
    Parser:Define("tbSectorAngles", "sector_angle", 0, Parser.TypeArrayFloat)
    Parser:Define("tbDamageFactor", "damage_factor", 0, Parser.TypeArrayFloat)
    Parser:Define("szAnimKey", "anim_key", 0, Parser.TypeString)
    
    Parser:Define("szJumpAnimKey", "jump_anim_key", 0, Parser.TypeString)
    Parser:Define("nJumpSectorAngle", "jump_sector_angle", 0, Parser.TypeFloat)
    Parser:Define("nJumpDamageFactor", "jump_damage_factor", 0, Parser.TypeFloat)
end

function HumanWeaponMeleeDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)

    -- tbNewTemplate.tbAttackMontages = {}
    -- tbNewTemplate.tbJumpAttackMontages = {}
    -- local nAttackCount = 4
    -- for i = 1, nAttackCount do
    --     local attack_montage = Parser:Get("attack_montage_" .. i, nil, Parser.TypeString)
    --     local attack_montage_time = Parser:Get("attack_time_" .. i, 0, Parser.TypeFloat)
    --     local sector_angle = Parser:Get("sector_angle_" .. i, 0, Parser.TypeFloat)
    --     local damage_factor = Parser:Get("damage_factor" .. i, 1, Parser.TypeFloat)
    --     if attack_montage then 
    --         table.insert( tbNewTemplate.tbAttackMontages, { ["szMontage"] = attack_montage, ["nTime"] = attack_montage_time, 
    --         ["nSectorAngle"] = sector_angle, ["nDamageFactor"] = damage_factor} )
    --     end
    -- end

    -- local nJumpAttackCount = 4
    -- for i = 1, nJumpAttackCount do
    --     local attack_montage = Parser:Get("jump_attack_montage_" .. i, nil, Parser.TypeString)
    --     local attack_montage_time = Parser:Get("jump_attack_time_" .. i, 0, Parser.TypeFloat)
    --     local sector_angle = Parser:Get("jump_sector_angle_" .. i, 0, Parser.TypeFloat)
    --     local damage_factor = Parser:Get("jump_damage_factor" .. i, 1, Parser.TypeFloat)
    --     if attack_montage then 
    --         table.insert( tbNewTemplate.tbJumpAttackMontages, { ["szMontage"] = attack_montage, ["nTime"] = attack_montage_time, 
    --         ["nSectorAngle"] = sector_angle, ["nDamageFactor"] = damage_factor} )
    --     end
    -- end

    tbAnimParams.szAnimKey = tbNewTemplate.szJumpAnimKey    
    tbAnimParams.nArmorId = tbNewTemplate.nEquipId
    tbAnimParams.nWeaponId = tbNewTemplate.nWeaponId
    local tbTemplate = AnimationResDataTableNew:GetTemplate(tbAnimParams)
    if not tbTemplate then 
        error("Can't Find MeleeAttackMontage " .. tbAnimParams.szAnimKey .. " nWeaponId " .. tbNewTemplate.nWeaponId .. " ArmorId " .. tbNewTemplate.nEquipId)
        return 
    end 

    for i=1,tbNewTemplate.nAnimCount do
        local szAnimKey = tbNewTemplate.szAnimKey.."_0" .. i
        tbAnimParams.szAnimKey = szAnimKey
        tbTemplate = AnimationResDataTableNew:GetTemplate(tbAnimParams)
        if not tbTemplate then 
            error("Can't Find MeleeAttackMontage " .. tbAnimParams.szAnimKey .. " nWeaponId " .. tbNewTemplate.nWeaponId .. " ArmorId " .. tbNewTemplate.nEquipId)
            return 
        end 
    end

    local szKey = tbNewTemplate.nWeaponId .. tbNewTemplate.nEquipId
    tbContainer[szKey] = tbNewTemplate
    return true;
end

-- [EXPORT BEGIN]
function HumanWeaponMeleeDataTable:GetTemplate(nID, nEquipId)
    local bDefaultEquip = false 
    if not nEquipId then  
        nEquipId = DEFAULT_EQUIP_ID
        bDefaultEquip = true
    end 
    local szKey = nID .. nEquipId
    local tbRet = self.tbContainer[szKey]

    if not tbRet and not bDefaultEquip then 
        nEquipId = DEFAULT_EQUIP_ID
        szKey = nID .. nEquipId
        tbRet = self.tbContainer[szKey]        
    end 
    return tbRet
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function HumanWeaponMeleeDataTable:GetContainer()
    return self.tbContainer
end
-- [EXPORT END]

return HumanWeaponMeleeDataTable
