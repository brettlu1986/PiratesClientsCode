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
local LobbySubLevelDataTable = {}

LobbySubLevelDataTable.szFileName = "client/lobbysublevel/lobby_sublevel.tab"

-- [EXPORT BEGIN]
local tbAspectRatioCamera =
{
    [1] = 
    {
        AspectRatio = 16 / 9,
        tbCameraTag = "tbCameraTag",
    },
    [2] = 
    {
        AspectRatio = 2 / 1,
        tbCameraTag = "tbCameraTag2-1",
    },
    [3] = 
    {
        AspectRatio = 4 / 3,
        tbCameraTag = "tbCameraTag4-3",
    },
}
LobbySubLevelDataTable.tbAllDungeonPoint = {}
-- [EXPORT END]

function LobbySubLevelDataTable:OnEditorDefine(Parser)
    --Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("szWndName", "ui_wnd_name", "", Parser.TypeString)
    Parser:Define("szResPath", "sublevel_res", "", Parser.TypeString)
    Parser:Define("nBGMId", "bgm_id", -1, Parser.TypeInt, false)
    Parser:Define("tbCameraTag", "camera_tag", {}, Parser.TypeArrayString)
    Parser:Define("tbCameraTag2-1", "camera_tag_2-1", {}, Parser.TypeArrayString)
    Parser:Define("tbCameraTag4-3", "camera_tag_4-3", {}, Parser.TypeArrayString)
    Parser:Define("tbActorTag", "actor_tag", {}, Parser.TypeArrayString)
    Parser:Define("nLightChannel", "light_channel", -1, Parser.TypeInt)
end

function LobbySubLevelDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbSublevelTemplateMap = self.tbContainer[tbNewTemplate.nId]
    if not tbSublevelTemplateMap then
        tbSublevelTemplateMap = {}
        self.tbContainer[tbNewTemplate.nId] = tbSublevelTemplateMap
    end
    tbSublevelTemplateMap[tbNewTemplate.szWndName] = tbNewTemplate
    return true
end

-- [EXPORT BEGIN]
function LobbySubLevelDataTable:GetTemplate(nId, szWndName)
    local tbSublevelTemplateMap = self.tbContainer[nId] 
    if tbSublevelTemplateMap then
        return tbSublevelTemplateMap[szWndName]
    end
end

function LobbySubLevelDataTable:GetResPath(nId, szWndName)
    local tbSublevelTemplateMap = self.tbContainer[nId] 
    if tbSublevelTemplateMap then
        local tbTemplate = tbSublevelTemplateMap[szWndName]
        if tbTemplate then
            return tbTemplate.szResPath
        end
    end
end

function LobbySubLevelDataTable:GetAllTemplateById(nId)
    return self.tbContainer[nId]
end

function LobbySubLevelDataTable:GetLightChannelData(nId, szWndName)
    local tbSubLevelTemplate = self:GetTemplate(nId, szWndName)
    if not tbSubLevelTemplate then
        logerror("LobbySubLevelDataTable:GetLightChannelData, tbSubLevelTemplate is not found", nId, szWndName)
        return
    end

    local nLightChannel = tbSubLevelTemplate.nLightChannel

    local bChannel0 = nLightChannel == 0
    local bChannel1 = nLightChannel == 1
    local bChannel2 = nLightChannel == 2
    return {bChannel0, bChannel1, bChannel2}
end

function LobbySubLevelDataTable:GetCameraTagsByAspectRatio(nId, szWndName, nAspectRatio)
    local nAspectRatioDiff = 9
    local nSelectIndex = 1
    for k, v in ipairs(tbAspectRatioCamera) do
        local nCurrentAspectRatio = math.abs(nAspectRatio - v.AspectRatio)
        if nCurrentAspectRatio < nAspectRatioDiff then
            nSelectIndex = k
            nAspectRatioDiff = nCurrentAspectRatio
        end
    end
    
    local tbTemplate = self:GetTemplate(nId, szWndName)
    local tbCameraTag = tbTemplate[tbAspectRatioCamera[nSelectIndex].tbCameraTag]
    log("GetCameraTagsByAspectRatio",nSelectIndex, #tbCameraTag)
    if #tbCameraTag > 0 then
        return tbCameraTag
    end
    return tbTemplate.tbCameraTag
end

-- [EXPORT END]



return LobbySubLevelDataTable
