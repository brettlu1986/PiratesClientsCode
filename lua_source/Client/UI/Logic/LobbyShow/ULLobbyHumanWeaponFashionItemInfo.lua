local luaclass = require("luaclass")
local ULLobbyHumanItemInfoBase = require("ULLobbyHumanItemInfoBase")

local ULLobbyHumanWeaponFashionItemInfo = luaclass("ULLobbyHumanWeaponFashionItemInfo", ULLobbyHumanItemInfoBase)

local ItemDataTable = require("ItemDataTable")
local LobbyWeaponMiscDataTable = require("LobbyWeaponMiscDataTable")
local ItemResDataTable = require("ItemResDataTable")

function ULLobbyHumanWeaponFashionItemInfo:MakeData(nTemplateId)
    local tbTemplate = ItemDataTable:GetTemplate(nTemplateId)
    local tbData = {}
    local nWeaponInstanceType = tbTemplate.nSubCategory
    local tbMiscDataTemplate = LobbyWeaponMiscDataTable:GetTemplate(nWeaponInstanceType)
    tbData.tbTemplate = tbTemplate
    tbData.nTemplateId = tbTemplate.nId
    tbData.bOwned = true
    local tbResTemplate = ItemResDataTable:GetTemplate(tbTemplate.nResId)
    tbData.szIcon = tbResTemplate.szIconPath
    tbData.nGrade = tbTemplate.nGrade
    tbData.l10nFirstName = tbTemplate.l10nName
    tbData.l10nLastName = tbMiscDataTemplate.l10nName
    tbData.nWeaponInstanceType = nWeaponInstanceType
    return tbData
end



return ULLobbyHumanWeaponFashionItemInfo