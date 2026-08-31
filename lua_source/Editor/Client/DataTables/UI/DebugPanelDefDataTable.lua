-----------------------------------------------------
--File Name    : DebugPanelDefDataTable.lua
--Author       : Song Fuhao
--Create Time  : 2018-04-19
--Description  : Debug面板配置
-----------------------------------------------------

local DebugPanelDefDataTable = {}

DebugPanelDefDataTable.szFileName = "client/ui/debug/debug_panel_def.tab"
DebugPanelDefDataTable.bEnableIterateKey = true

function DebugPanelDefDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nIndex")
    Parser:Define("nIndex"      , "index"       , -1, Parser.TypeInt)
    Parser:Define("szTitleName" , "title_name"  , "", Parser.TypeString)
    Parser:Define("szPrefabName", "prefab_name" , "", Parser.TypeString)
end

-- [EXPORT BEGIN]
function DebugPanelDefDataTable:GetTemplate(nIndex)
    return self.tbContainer[nIndex]
end
-- [EXPORT END]

return DebugPanelDefDataTable
