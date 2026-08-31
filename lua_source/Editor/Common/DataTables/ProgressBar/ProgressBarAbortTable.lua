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

local ProgressBarAbortTable = {}

ProgressBarAbortTable.szFileName = "common/progress_bar/abort_condition.tab"

function ProgressBarAbortTable:OnEditorDefine(Parser)
    Parser:SetKey("nID")
    Parser:Define("nID", "id", -1, Parser.TypeInt)
    Parser:Define("bHumanDisplacement", "human_displacement", false, Parser.TypeBool)
    Parser:Define("bHumanInjured", "human_injured", false, Parser.TypeBool)
    Parser:Define("bShipInjured", "ship_injured", false, Parser.TypeBool)
    Parser:Define("bHumanMove", "human_move", false, Parser.TypeBool)
    Parser:Define("bShipMove", "ship_move", false, Parser.TypeBool)
    Parser:Define("bShipPostureChange", "ship_posture_change", false, Parser.TypeBool)
    Parser:Define("bShipRotate", "ship_rotate", false, Parser.TypeBool)
    Parser:Define("bHumanJump", "human_jump", false, Parser.TypeBool)
    -- Parser:Define("bHumanCrouch", "human_crouch", false, Parser.TypeBool)
    Parser:Define("bHumanCrawl", "human_crawl", false, Parser.TypeBool)
    Parser:Define("bHumanSwim", "human_swim", false, Parser.TypeBool)
    -- Parser:Define("bSeriousInjury", "serious_injury", false, Parser.TypeBool)
    -- Parser:Define("bHumanFire", "human_fire", false, Parser.TypeBool)
    Parser:Define("bShipAim", "ship_aim", false, Parser.TypeBool)
    Parser:Define("bShipFire", "ship_fire", false, Parser.TypeBool)
    Parser:Define("bHumanWeaponStateChange", "human_weapon_state_change", false, Parser.TypeBool)
    Parser:Define("bHumanWeaponSlotChange", "human_weapon_slot_change", false, Parser.TypeBool)
    Parser:Define("bShipWeaponSwitch", "ship_weapon_switch", false, Parser.TypeBool)
    Parser:Define("bHumanPickUp", "human_pick_up", false, Parser.TypeBool)
    Parser:Define("bShipPickUp", "ship_pick_up", false, Parser.TypeBool)
    Parser:Define("bShipBulletLoad", "ship_bullet_load", false, Parser.TypeBool)
    Parser:Define("bHumanDead", "human_dead", false, Parser.TypeBool)
    Parser:Define("bShipDead", "ship_dead", false, Parser.TypeBool)
    Parser:Define("bHumanBurn", "human_burn", false, Parser.TypeBool)
    Parser:Define("bShipBurn", "ship_burn", false, Parser.TypeBool)
    Parser:Define("bHumanDying", "human_dying", false, Parser.TypeBool)
    Parser:Define("bShipDying", "ship_dying", false, Parser.TypeBool)
    Parser:Define("bHumanSwitchDoor", "human_switch_door", false, Parser.TypeBool)
end

-- [EXPORT BEGIN]
function ProgressBarAbortTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return ProgressBarAbortTable
