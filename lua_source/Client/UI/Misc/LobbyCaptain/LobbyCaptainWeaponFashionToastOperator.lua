-----------------------------------------------------
--File Name    : LobbyCaptainWeaponFashionToastOperator.lua
--Description  :
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbyCaptainWeaponFashionToastOperator = luaclass("LobbyCaptainWeaponFashionToastOperator")

local UITextDef = require("UITextDef")
local ItemSystem = require("ItemSystem")
local UIUtils = require("UIUtils")
local ItemCategoryDef = require("ItemCategoryDef")


local function ShowToast(l10nText)
    UIUtils.ShowToast(l10nText)
end


local function TryToToastUnownedFashion(nItemTemplateId)
    local tbItems = ItemSystem:GetItemsByTemplateId(nItemTemplateId)
    local bOwned = #tbItems > 0
    if not bOwned then
        ShowToast(UITextDef.LOBBY_CAPTAIN_HINT_FITTING)
    end
end


function LobbyCaptainWeaponFashionToastOperator:OnPickItem(nItemTemplateId)
    local tbItemTemplate = ItemSystem:GetItemTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    if nCategory ~= ItemCategoryDef.HUMAN_WEAPON_FASHION then 
        return
    end

    TryToToastUnownedFashion(nItemTemplateId)
end


function LobbyCaptainWeaponFashionToastOperator:Init()
end

function LobbyCaptainWeaponFashionToastOperator:Uninit()
end


return LobbyCaptainWeaponFashionToastOperator