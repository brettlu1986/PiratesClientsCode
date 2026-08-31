-----------------------------------------------------
--File Name    : LobbyItemUseHelper.lua
--Author       : zhiyuan
--Create Time  : 2019-03-29
--Description  : 道具在背包里使用的helper
-----------------------------------------------------
local LobbyItemUseHelper = {}

local ItemCategoryDef = require("ItemCategoryDef")
local UILobbyBackpackTips = require("UILobbyBackpackTips")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local ItemSystem = require("ItemSystem")
local UIUtils = require("UIUtils")
local ItemDataTable = require("ItemDataTable")

function LobbyItemUseHelper.UseItem(pbLobbyBackpackTips, Item)
    local nCategory = Item:GetCategory()
    if nCategory == ItemCategoryDef.SAILOR then
        UIManager:CloseWnd(UIDef.UI_LOBBY_BACKPACK)
        UIManager:OpenWnd(UIDef.UI_SAILOR_MAIN)
    elseif nCategory == ItemCategoryDef.UNLOCK_ITEM then
        local tbTemplate = Item:GetTemplate()
        local nRelatedItemTemplateId = tbTemplate.nRelatedItemTemplateId
        if nRelatedItemTemplateId ~= nil and nRelatedItemTemplateId > 0 then
            if ItemSystem:GetItemCount(nRelatedItemTemplateId) > 0 then
                --pbLobbyBackpackTips:SetData(UILobbyBackpackTips.Type.USE, Item)
                UIManager:OpenWnd(UIDef.UI_LOBBY_BACKPACK_TIPS, {nType = UILobbyBackpackTips.Type.USE, Item = Item})
            else
                local tbRelatedItemTemplate = ItemDataTable:GetTemplate(nRelatedItemTemplateId)
                UIUtils.ShowToastWithL10NFormat("LOBBY_UNLOCK_ITEM_CANNOT_USE", tbRelatedItemTemplate.l10nName, tbTemplate.l10nName)
            end
        else
            UIManager:OpenWnd(UIDef.UI_LOBBY_BACKPACK_TIPS, {nType = UILobbyBackpackTips.Type.USE, Item = Item})
            --pbLobbyBackpackTips:SetData(UILobbyBackpackTips.Type.USE, Item)
        end
    else
        UIManager:OpenWnd(UIDef.UI_LOBBY_BACKPACK_TIPS, {nType = UILobbyBackpackTips.Type.USE, Item = Item})
        --pbLobbyBackpackTips:SetData(UILobbyBackpackTips.Type.USE, Item)
    end
end

return LobbyItemUseHelper