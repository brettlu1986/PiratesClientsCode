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
local TransporterDataTable = {}
local StringUtil = require("StringUtil")

TransporterDataTable.szFileName = "common/ffa/parachuting/transporter.tab"

local function ParseList(self, szIds)
    if not szIds or string.len( szIds ) <= 0 then 
        logerror("TransporterDataTable invalid data")
        return  nil 
    end
    local tbTemp = StringUtil.Split(szIds, ",")
    if #tbTemp <= 0 then 
        logerror("TransporterDataTable invalid split data")
        return nil
    end 

    local tbList = {}
    for _, v in ipairs(tbTemp) do
        table.insert(tbList, tonumber(v))
    end  

    return tbList    
end

function TransporterDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    -- Parser:Define("nDialogId", "dialog_id", -1, Parser.TypeInt)
    Parser:Define("nDummyId", "dummy_id", -1, Parser.TypeInt)
    Parser:Define("nStartDialogId", "start_dialog_id", -1, Parser.TypeInt)
    Parser:Define("nLaunchDialogId", "launch_dialog_id", -1, Parser.TypeInt)
    Parser:Define("nMatineeId", "matinee_id", -1, Parser.TypeInt)
    Parser:Define("nLaunchTime", "launch_time", -1, Parser.TypeInt)
    Parser:Define("nMidwayTime", "midway_time", -1, Parser.TypeInt)
    -- Parser:Define("nLaunchTime", "midway_dialog_id", -1, Parser.TypeInt)
end

function TransporterDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    tbNewTemplate.tbDialogIds = ParseList(self, Parser:Get("dialog_id", nil, Parser.TypeString, true)) 
    if tbNewTemplate.tbDialogIds == nil or #tbNewTemplate.tbDialogIds == 0 then
        error("TransporterDataTable dialog is null")
    end
    tbNewTemplate.tbMidwayDialogIds = ParseList(self, Parser:Get("midway_dialog_id", nil, Parser.TypeString, true)) 
    return true 
end

-- [EXPORT BEGIN]
function TransporterDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return TransporterDataTable
