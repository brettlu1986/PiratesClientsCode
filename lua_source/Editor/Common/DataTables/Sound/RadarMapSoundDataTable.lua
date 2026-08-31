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
local RadarMapSoundDataTable = {}

RadarMapSoundDataTable.szFileName = "common/ffa/sound/radar_sound.tab"

function RadarMapSoundDataTable:OnEditorDefine(Parser)
    Parser:Define("nHumanState", "human_state", -1, Parser.TypeInt)
    Parser:Define("nHumanBuff", "human_buff", 0, Parser.TypeInt)
    Parser:Define("nVehicleId", "vehicle_id", -1, Parser.TypeInt)
    Parser:Define("nVehicleState", "vehicle_state", -1, Parser.TypeInt)
    Parser:Define("nWeaponTemplateId", "weapon_template_id", -1, Parser.TypeInt)
    Parser:Define("nSpreadDistance", "spread_distance", -1, Parser.TypeFloat)
end

function RadarMapSoundDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if tbNewTemplate.nHumanState > 0 then
        local tbHumanStateTemplates = tbContainer.tbHumanStates or { }
        tbContainer.tbHumanStates = tbHumanStateTemplates

        local tbHumanBuffs = tbHumanStateTemplates[tbNewTemplate.nHumanState] or {}
        tbHumanStateTemplates[tbNewTemplate.nHumanState] = tbHumanBuffs

        tbHumanBuffs[tbNewTemplate.nHumanBuff] = tbNewTemplate
    end
    if tbNewTemplate.nVehicleId > 0 then
        local tbVehiclesTemplates = tbContainer.tbVehicles or { }
        local tbVehiclesStateTemplates = tbVehiclesTemplates[tbNewTemplate.nVehicleId] or { }
        tbVehiclesStateTemplates[tbNewTemplate.nVehicleState] = tbNewTemplate
        tbVehiclesTemplates[tbNewTemplate.nVehicleId] = tbVehiclesStateTemplates
        tbContainer.tbVehicles = tbVehiclesTemplates
    end
    if tbNewTemplate.nWeaponTemplateId > 0 then
        local tbWeaponTemplates = tbContainer.tbWeapons or { }
        tbContainer.tbWeapons = tbWeaponTemplates

        local tbHumanBuffs = tbWeaponTemplates[tbNewTemplate.nWeaponTemplateId] or {}
        tbWeaponTemplates[tbNewTemplate.nWeaponTemplateId] = tbHumanBuffs

        tbHumanBuffs[tbNewTemplate.nHumanBuff] = tbNewTemplate
    end
    return true
end


-- [EXPORT BEGIN]
function RadarMapSoundDataTable:GetHumanStateRadius(nHumanState, nBuffId)
    local tbHumanStateTemplates = self.tbContainer.tbHumanStates
    if tbHumanStateTemplates and tbHumanStateTemplates[nHumanState] then
        local tbBuffs = tbHumanStateTemplates[nHumanState]
        local tbRet = tbBuffs[0]
        if nBuffId and tbBuffs[nBuffId] then
            tbRet = tbBuffs[nBuffId]
        end

        if tbRet then
            return tbRet.nSpreadDistance
        end
    end
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function RadarMapSoundDataTable:GetVehicleStateRadius(nVehicleId, nVehicleState)
    local tbVehiclesTemplates = self.tbContainer.tbVehicles
    if tbVehiclesTemplates then
        local tbVehiclesStateTemplates = tbVehiclesTemplates[nVehicleId]
        if tbVehiclesStateTemplates and tbVehiclesStateTemplates[nVehicleState] then
            return tbVehiclesStateTemplates[nVehicleState].nSpreadDistance
        end
    end
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function RadarMapSoundDataTable:GetWeaponRadius(nWeaponTemplateId, nBuffId)
    local tbWeaponTemplates = self.tbContainer.tbWeapons
    if tbWeaponTemplates and tbWeaponTemplates[nWeaponTemplateId] then
        local tbBuffs = tbWeaponTemplates[nWeaponTemplateId]
        local tbRet = tbBuffs[0]
        if nBuffId and tbBuffs[nBuffId] then
            tbRet = tbBuffs[nBuffId]
        end

        if tbRet then
            return tbRet.nSpreadDistance
        end
    end
end
-- [EXPORT END]

return RadarMapSoundDataTable
