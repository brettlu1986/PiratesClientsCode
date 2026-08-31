-----------------------------------------------------
--File Name    : UILobbyShip.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-20
--Description  : 船备战界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyShip = luaclass("UILobbyShip", WndBase)

local ItemCategoryDef = require("ItemCategoryDef")

local TAB_WIDGET_NAME = {
    "pbLobbyShipEquipping",
    "pbLobbyShipHandbook",
    "pbLobbyShipWeapon",
    "pbLobbyShipPart",
}
local TAB_INDEX_SHIP_WEAPON = 3
local TAB_INDEX_SAILOR_PART = 4

UILobbyShip.pbWindowFrame = nil

function UILobbyShip:OnLoad()
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:BindWidgetSwitcher(self.pWidgetRef.wsContent, TAB_WIDGET_NAME)
end

function UILobbyShip:OnShow()
    local nItemTemplateId = self.tbOpenArgs.nItemTemplateId
    if nItemTemplateId then
        local nItemCategory = self.tbOpenArgs.nItemCategory
        if nItemCategory == ItemCategoryDef.SHIP_WEAPON then
            self.pbWindowFrame:SetSelectedTab(TAB_INDEX_SHIP_WEAPON)
        elseif nItemCategory == ItemCategoryDef.SHIP_PART then
            self.pbWindowFrame:SetSelectedTab(TAB_INDEX_SAILOR_PART)
        end
        local pbActivatedTabPrefab = self.pbWindowFrame:GetActivatedTabPrefab()
        pbActivatedTabPrefab:SetSelectedItem(nItemTemplateId)
    end
end

return UILobbyShip