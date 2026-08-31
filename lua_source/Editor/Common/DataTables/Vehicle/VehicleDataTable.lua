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
local VehicleDataTable = {}

VehicleDataTable.szFileName = "common/ffa/vehicle/vehicle.tab"

function VehicleDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nVehicleId")
    Parser:Define("nVehicleId", "vehicle_id", -1, Parser.TypeInt)
    Parser:Define("nSpeed", "speed", -1, Parser.TypeFloat)
    Parser:Define("nRunSpeed", "run_speed", -1, Parser.TypeFloat)
    Parser:Define("nLeftRightSpeed", "left_right_speed", -1, Parser.TypeFloat)
    Parser:Define("nBackSpeed", "back_speed", -1, Parser.TypeFloat)
    Parser:Define("nRunAwaySpeed", "ran_away_speed", -1, Parser.TypeFloat)
    Parser:Define("nMaxHp", "max_hp", -1, Parser.TypeInt)
    Parser:Define("nMaxPassengerCount", "max_passenger_count", -1, Parser.TypeInt)
    Parser:Define("nIngoreFallingDamageHeight", "ingore_falling_damage_height", -1, Parser.TypeFloat)
    Parser:Define("nFallingDamageFactor", "falling_damage_factor", -1, Parser.TypeFloat)
    Parser:Define("nIngoreLeaveDamageSpeed", "ingore_leave_damage_speed", -1, Parser.TypeFloat)
    Parser:Define("nLeaveDamageFactor", "leave_damage_factor", -1, Parser.TypeFloat)
    Parser:Define("nRedId", "res_id", -1, Parser.TypeInt)
    Parser:Define("nForwardRotVel", "forward_rot_speed", -1, Parser.TypeFloat)
    Parser:Define("nBackRotVel", "back_rot_speed", -1, Parser.TypeFloat)
    Parser:Define("nStandRotVel", "stand_rot_speed", -1, Parser.TypeFloat)
    Parser:Define("nRotAccelaration", "rot_acceleration", -1, Parser.TypeFloat)
    Parser:Define("nRotDeceleration", "rot_deceleration", -1, Parser.TypeFloat)
    Parser:Define("nRotDecelerationMinVel", "rot_deceleration_minspeed", -1, Parser.TypeFloat)
    Parser:Define("nRunAwayTimeWithDriver", "run_awar_time_with_driver", 0, Parser.TypeFloat)
    Parser:Define("nRunAwayTime", "run_away_time", 0, Parser.TypeFloat)
    Parser:Define("nRunAwayRotationTimeMin", "run_away_rotation_time_min", 0, Parser.TypeFloat)
    Parser:Define("nRunAwayRotationTimeMax", "run_away_rotation_time_max", 0, Parser.TypeFloat)
    Parser:Define("nBattleStimulationDistance", "battle_stimulation_distance", 0, Parser.TypeFloat)
    Parser:Define("nVehicleStimulationDistance", "vehicle_stimulation_distance", 0, Parser.TypeFloat)
    Parser:Define("nWalkSpeed", "walk_speed", 0, Parser.TypeFloat)
    Parser:Define("nRunSpeed", "run_speed", 0, Parser.TypeFloat)
    Parser:Define("bInvincibleToPoisonCricle", "invincible_to_poison_circle", true, Parser.TypeBool)
end



-- [EXPORT BEGIN]
function VehicleDataTable:GetTemplate(nVehicleId)
    return self.tbContainer[nVehicleId]
end

function VehicleDataTable:OnGameRequired()
    local VehicleResTable = require("VehicleResTable")
    local tbContainer = self.tbContainer
    for k,v in pairs(tbContainer) do
        v.tbResData = VehicleResTable:GetTemplate(v.nRedId)
        if(v.tbResData == nil) then
            error("VehicleDataTable find res data failed: ".. v.nResId)
        end
    end
end

-- [EXPORT END]

return VehicleDataTable
