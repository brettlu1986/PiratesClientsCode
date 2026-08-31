-----------------------------------------------------
--File Name    : AvatarColorDataTable.lua
--Author       : WuJizhou
--Create Time  : 4/1/2020, 8:57:33 PM
--Description  : AvatarColorDataTable
-----------------------------------------------------
local AvatarColorDataTable = {}


AvatarColorDataTable.szFileName = "common/avatar/avatar_colors.tab"


function AvatarColorDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId",          "id",          -1,  Parser.TypeInt)
    Parser:Define("nRed",         "red",          1,  Parser.TypeFloat)
    Parser:Define("nGreen",       "green",        1,  Parser.TypeFloat)
    Parser:Define("nBlue",        "blue",         1,  Parser.TypeFloat)
end


-- [EXPORT BEGIN]
--return list
function AvatarColorDataTable:GetTemplate(nId)
    local tbTemplate = self.tbContainer[nId]
    return tbTemplate
end
-- [EXPORT END]

return AvatarColorDataTable