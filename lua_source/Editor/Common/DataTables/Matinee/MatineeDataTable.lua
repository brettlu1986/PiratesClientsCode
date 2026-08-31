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
local StringUtil = require("StringUtil")

local MatineeDataTable = {}

MatineeDataTable.szFileName = "common/res/matinee_res.tab"

local function ParseBind(szParam)
    if StringUtil.IsEmptyString(szParam) then 
        return nil 
    end 
    local tbSplit = StringUtil.Split(szParam,",")
    if #tbSplit < 1 then 
        return nil
    end 
    local tbRet = {}
    for _,v in ipairs(tbSplit) do
        table.insert( tbRet, tonumber(v) )
    end
    return tbRet
end 

function MatineeDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nID")
    Parser:Define("nID", "id", -1, Parser.TypeInt)
    Parser:Define("szMaleRes", "male_res", nil, Parser.TypeString)
    Parser:Define("szFemaleRes", "female_res", nil, Parser.TypeString)
    Parser:Define("szLevelPath", "level", nil, Parser.TypeString)
    Parser:Define("szSubTitlePath", "sub_title", nil, Parser.TypeString)
    Parser:Define("bUseOcean", "use_ocean", false, Parser.TypeBool)
    Parser:Define("nWaveHeight", "wave_height", 0, Parser.TypeInt)
    Parser:Define("nWaveChoppy", "wave_choppy", 0, Parser.TypeInt)
    Parser:Define("nCinematicMode", "cinematic_mode", 0, Parser.TypeInt)
    Parser:Define("bPlayInServer", "play_in_server", false, Parser.TypeBool)
    Parser:Define("bShowActor", "show_actor", false, Parser.TypeBool)
    -- Parser:Define("szSubTitlePath", "sub_title", nil, Parser.TypeString)
    -- Parser:Define("szSubTitlePath", "sub_title", nil, Parser.TypeString)
end
 
function MatineeDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    tbNewTemplate.tbBindHuman = ParseBind(Parser:Get("bind_human", nil, Parser.TypeString, true))
    tbNewTemplate.tbBindShip = ParseBind(Parser:Get("bind_ship", nil, Parser.TypeString, true))

    if tbNewTemplate.bPlayInServer then
        local szRes = tbNewTemplate.szMaleRes
        local nTime = EditorExtendFunctions.GetMovieSceneLength(szRes:load())
        log("get matinee time ", tbNewTemplate.nID, nTime)
        tbNewTemplate.nTime = nTime
    end
    
    return true
end 

-- [EXPORT BEGIN]
function MatineeDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return MatineeDataTable
