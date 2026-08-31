local HumanArmorPropertyDescKeyParser = {}

local UITextDef                         = require("UITextDef")
local DescKeyParserMiscDef              = require("DescKeyParserMiscDef")

local NAME_SPACE_HUMAN_MISC = DescKeyParserMiscDef.NAME_SPACE_HUMAN_MISC


local function GetGeneralDesc(tbInputData)
    local tbOutData = {}
    tbOutData.bList = false
    tbOutData.l10nData = UITextDef.BASIC_FASHION_DESC
    return tbOutData
end


function HumanArmorPropertyDescKeyParser.Init(fnDefine)
    --人时装总体概述
    fnDefine(NAME_SPACE_HUMAN_MISC,   "general_desc",   GetGeneralDesc)
end

return HumanArmorPropertyDescKeyParser