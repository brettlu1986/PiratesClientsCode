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
local FogDataTable = {}

FogDataTable.szFileName = "common/ffa/fog/fog.tab"
local MAX_CHANGE_COUNT = 3

function FogDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nFogId")
    Parser:Define("nFogId", "id", -1, Parser.TypeInt)
    Parser:Define("nSpeed", "speed", 0, Parser.TypeString)
    Parser:Define("nAccelation", "accelation", 0, Parser.TypeString)
    Parser:Define("nStopRate", "stop_rate", 0, Parser.TypeInt)
    Parser:Define("nStopTime", "stop_time", 0, Parser.TypeInt)
    Parser:Define("nTargetDensity1", "target_density1", -1, Parser.TypeFloat)
    Parser:Define("nChangeTime1", "change_time1", -1, Parser.TypeInt)
    Parser:Define("nElapseTime1", "elapse_time1", -1, Parser.TypeInt)
    Parser:Define("nTargetDensity2", "target_density2", -1, Parser.TypeFloat)
    Parser:Define("nChangeTime2", "change_time2", -1, Parser.TypeInt)
    Parser:Define("nElapseTime2", "elapse_time2", -1, Parser.TypeInt)
    Parser:Define("nTargetDensity3", "target_density3", -1, Parser.TypeFloat)
    Parser:Define("nChangeTime3", "change_time3", -1, Parser.TypeInt)
    Parser:Define("nElapseTime3", "elapse_time3", -1, Parser.TypeInt)
end

function FogDataTable:OnEditorParseFinished()
    for k, v in pairs(self.tbContainer) do
        if v.nTargetDensity1 == -1 then
            error(string.format("FogDataTable density is invalid: %d", v.nFogId))
        end
        local tbChange = {}
        v.tbChange = tbChange
        for i = 1, MAX_CHANGE_COUNT do
            if v["nTargetDensity"..i] ~= -1 and v["nChangeTime"..i] ~= -1 and v["nElapseTime"..i] ~= -1 then
                local tbChangeData = {nTargetDensity = v["nTargetDensity"..i],
                    nChangeTime = v["nChangeTime"..i],
                    nElapseTime = v["nElapseTime"..i]}
                table.insert(tbChange, tbChangeData)
            end
        end 
    end
end

-- [EXPORT BEGIN]
function FogDataTable:GetTemplate(nTemplateId)
    return self.tbContainer[nTemplateId]
end
-- [EXPORT END]

return FogDataTable
