local luaclass = require("luaclass")
local ULLobbyHumanItemInfoBase = require("ULLobbyHumanItemInfoBase")

local ULLobbyHumanFashionItemInfo = luaclass("ULLobbyHumanFashionItemInfo", ULLobbyHumanItemInfoBase)

local ItemResDataTable = require("ItemResDataTable")
local ItemDataTable = require("ItemDataTable")



function ULLobbyHumanFashionItemInfo:MakeData(nTemplateId)
    local tbTemplate = ItemDataTable:GetTemplate(nTemplateId)
    local tbData = {}
    tbData.tbTemplate = tbTemplate
    tbData.nTemplateId = tbTemplate.nId
    tbData.bOwned = true
    local tbResTemplate = ItemResDataTable:GetTemplate(tbTemplate.nResId)

    tbData.szIcon = tbResTemplate.szIconPath
    tbData.nGrade = tbTemplate.nGrade
    tbData.l10nFirstName = tbTemplate.l10nName
    -- tbData.l10nSecondName = UITextDef.FASHION_ARMOR_NAME[self.nCurrentFashionType]
    -- tbData.l10nLastName = L10N:Format(UITextDef.LOBBY_CAPTAIN_AVATAR_DYNAMIC_SLOT[tbTemplate.nSubCategory], "")
    tbData.nFashionType = self.nCurrentFashionType
    tbData.nSlotType = self.nCurrentSlotType
    return tbData
end


return ULLobbyHumanFashionItemInfo