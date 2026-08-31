local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSeasonAwardDesc = luaclass("UPSeasonAwardDesc", PrefabBase)
local ItemSystem = require("ItemSystem")
local LobbySystem = require("LobbySystem")
local ItemCategoryDef = require("ItemCategoryDef")
local Human3DItemShowDataHelper = require("Human3DItemShowDataHelper")
local LobbySubTypeDef = require("LobbySubTypeDef")

UPSeasonAwardDesc.tbSelectedData = nil

local function OnClickedInfo(self)
    if self.tbSelectedData == nil then
        return
    end
    local nItemTemplateId = self.tbSelectedData.nTemplateId
    local tbItemTemplate = ItemSystem:GetItemTemplate(nItemTemplateId)
    if tbItemTemplate == nil then
        return
    end

    local tbCurSub = LobbySystem:GetActiveSub()
    local tbExtend = {}
    for k, v in pairs(self.tbSelectedData) do
        tbExtend[k] = v
    end
    tbCurSub:SetRestoreContext({szUIName = self.Owner, tbOpenArgs = {nTabIndex = 1, tbExtendData = tbExtend}})

    local nCategory = tbItemTemplate.nCategory
    if nCategory == ItemCategoryDef.FASHION or nCategory == ItemCategoryDef.SUIT then
        local tbData = Human3DItemShowDataHelper.MakeHumanFashionShowData(nItemTemplateId)
        LobbySystem:ActivateNextSub(LobbySubTypeDef.SHOW, tbData)        
    elseif nCategory == ItemCategoryDef.HUMAN_WEAPON_FASHION then
        local tbData = Human3DItemShowDataHelper.MakeHumanWeaponFashionShowData(nItemTemplateId)
        LobbySystem:ActivateNextSub(LobbySubTypeDef.SHOW, tbData)    
    elseif nCategory == ItemCategoryDef.SHIP then
        local tbLobbyShip = LobbySystem:GetSub(LobbySubTypeDef.SHIP)
        LobbySystem:ActivateNextSub(LobbySubTypeDef.SHOW, {nCategory = ItemCategoryDef.SHIP, nShipTemplateId = nItemTemplateId, OwnerSub = tbLobbyShip})
    elseif nCategory == ItemCategoryDef.SHIP_SKIN then
        local tbLobbyShip = LobbySystem:GetSub(LobbySubTypeDef.SHIP)
        LobbySystem:ActivateNextSub(LobbySubTypeDef.SHOW, {nCategory = ItemCategoryDef.SHIP_SKIN, nShipTemplateId = tbItemTemplate.nShipItemId, nShipSkinTemplateId = nItemTemplateId, OwnerSub = tbLobbyShip })
    elseif nCategory == ItemCategoryDef.DECORATION then  
        LobbySystem:ActivateNextSub(LobbySubTypeDef.SHOW, {nCategory = ItemCategoryDef.DECORATION, nTemplateId = nItemTemplateId })
    elseif nCategory == ItemCategoryDef.SHIP_WEAPON then
        local tbLobbyShip = LobbySystem:GetSub(LobbySubTypeDef.SHIP)
        LobbySystem:ActivateNextSub(LobbySubTypeDef.SHOW, {nCategory = ItemCategoryDef.SHIP_WEAPON, nItemTemplateId = nItemTemplateId, OwnerSub = tbLobbyShip })
    elseif nCategory == ItemCategoryDef.SHIP_PART then
        local tbLobbyShip = LobbySystem:GetSub(LobbySubTypeDef.SHIP)
        LobbySystem:ActivateNextSub(LobbySubTypeDef.SHOW, {nCategory = ItemCategoryDef.SHIP_PART, nItemTemplateId = nItemTemplateId, OwnerSub = tbLobbyShip })
    end

end

function UPSeasonAwardDesc:OnRefresh(tbItemTemplate)
    local pWidgetRef = self.pWidgetRef
    if tbItemTemplate == nil then
        pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
    else
        pWidgetRef:SetVisibility(ESlateVisibility_Visible)
        pWidgetRef.txtName:SetText(tbItemTemplate.l10nName)
        pWidgetRef.kmtxtItemContent:SetText(ItemSystem:GetItemIntro(tbItemTemplate.nId))

        local nCategory = tbItemTemplate.nCategory
        if nCategory == ItemCategoryDef.FASHION or
            nCategory == ItemCategoryDef.SUIT or 
            nCategory == ItemCategoryDef.HUMAN_WEAPON_FASHION or
            nCategory == ItemCategoryDef.SHIP or
            nCategory == ItemCategoryDef.SHIP_SKIN or 
            nCategory == ItemCategoryDef.DECORATION or
            nCategory == ItemCategoryDef.SHIP_WEAPON or
            nCategory == ItemCategoryDef.SHIP_PART then
                pWidgetRef.imgInfo:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        else
            pWidgetRef.imgInfo:SetVisibility(ESlateVisibility_Collapsed)
        end
    end
end

function UPSeasonAwardDesc:OnLoad()
end

function UPSeasonAwardDesc:OnDestroy()
end

function UPSeasonAwardDesc:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnInfo.OnClicked,  self, OnClickedInfo)
end

function UPSeasonAwardDesc:SetSelectedData(tbData)
    self.tbSelectedData = tbData
end

return UPSeasonAwardDesc