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
local ShipMovingSoundDataTable = {}

local StringUtil = require("StringUtil")

ShipMovingSoundDataTable.szFileName = "client/sound/ship_moving_sound.tab"

function ShipMovingSoundDataTable:OnEditorDefine(Parser)
    Parser:Define("nShipCategory"   , "ship_category"       , 1 , Parser.TypeInt)
    Parser:Define("nSoundType"      , "sound_type"          , 1 , Parser.TypeInt)
    Parser:Define("szSoundPath"     , "sound_path"          , "", Parser.TypeString)
    Parser:Define("nFadeInDuration" , "fade_in_duration"    , 0 , Parser.TypeFloat)
    Parser:Define("nFadeOutDuration", "fade_out_duration"   , 0 , Parser.TypeFloat)
end

function ShipMovingSoundDataTable:OnEditorParseLine(_Parser, tbContainer, tbNewTemplate)
    local tbTemplates = tbContainer[tbNewTemplate.nShipCategory]
    tbTemplates = tbTemplates or {}
    tbTemplates[tbNewTemplate.nSoundType] = tbNewTemplate
    tbContainer[tbNewTemplate.nShipCategory] = tbTemplates

    if StringUtil.IsEmptyString(tbNewTemplate.szSoundPath) then
        logerror("sound_path is empty, nShipCategory, nSoundType =", tbNewTemplate.nShipCategory, tbNewTemplate.nSoundType)
        return false
    end

    return true
end

-- [EXPORT BEGIN]
function ShipMovingSoundDataTable:GetSoundResMap(nShipCategory)
    return self.tbContainer[nShipCategory]
end
-- [EXPORT END]

return ShipMovingSoundDataTable
