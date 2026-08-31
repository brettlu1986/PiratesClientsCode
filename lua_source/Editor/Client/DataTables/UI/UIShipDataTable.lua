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
local UIShipDataTable = {}

local StringUtil = require("StringUtil")
UIShipDataTable.szFileName = "client/ui/ui_ship.tab"

local FIELDS = {
    ["location"] ="tbLocation",
    ["yaw"] = "nYaw",
    ["scale"] = "nScale"
}

local function ParseKey(self, Parser)
    if self.tbKeys == nil then
        local tbCurrentKeys = Parser:GetCurrentKeys()
        local tbKeys = {}
        for szKeyName, nIndex in pairs(tbCurrentKeys) do
            tbKeys[nIndex] = szKeyName
        end
        self.tbKeys = tbKeys
    end
end

local function ParaseSubKey(szKey)
    local tbTempKey = StringUtil.Split(szKey, "_")
    if #tbTempKey == 2 and FIELDS[tbTempKey[2]] then
        return tbTempKey[1], FIELDS[tbTempKey[2]]
    end
end

function UIShipDataTable:OnEditorDefine(Parser)
    Parser:Define("nResId",    "res_id", -1, Parser.TypeInt)
    -- Parser:Define("szKey",  "key", "", Parser.TypeString)
    -- Parser:Define("tbLocation","location", {0,0,0}, Parser.TypeArrayInt)
    -- Parser:Define("nYaw",      "yaw", 1, Parser.TypeFloat)
    -- Parser:Define("nScale",    "scale", 1, Parser.TypeFloat)
end

function UIShipDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    ParseKey(self, Parser)

    local tbLineData = Parser:GetCurrentLineData()
    if #tbLineData ~= #self.tbKeys then
        logerror("UIShipDataTable parse count num is not equal", tbNewTemplate.nResId)
        return false
    end

    for i, v in ipairs(self.tbKeys) do
        local tbTemp
        if string.find(v, "location") then
            local tbData = StringUtil.Split(tbLineData[i], ",")
            local tbLocation
            if #tbData == 3 then
                tbLocation = {}
                for _, value in ipairs(tbData) do
                    table.insert(tbLocation, tonumber(value))
                end                
            else
                tbLocation = {0, 0, 0}
            end
            tbTemp = tbLocation
        elseif string.find(v, "yaw") or string.find(v, "scale") then
            local nValue = tonumber(tbLineData[i])
            tbTemp = nValue or 1
        end
        if tbTemp then
            local szKey, szFieldKey = ParaseSubKey(v)
            if szKey and szFieldKey then
                if tbNewTemplate[szKey] == nil then
                    tbNewTemplate[szKey] = {}
                end
                tbNewTemplate[szKey][szFieldKey] = tbTemp
            end
        end
    end

    tbContainer[tbNewTemplate.nResId] = tbNewTemplate
    return true
end

-- [EXPORT BEGIN]
function UIShipDataTable:GetTemplate(nResId, szKey)
    return self.tbContainer[nResId] and self.tbContainer[nResId][szKey]
end
-- [EXPORT END]

return UIShipDataTable
