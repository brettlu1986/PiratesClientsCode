-----------------------------------------------------
--File Name    : UPSeaAdventureTile.lua
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSeaAdventureTile = luaclass("UPSeaAdventureTile", PrefabBase)

local SeaAdventureHelper = require("SeaAdventureHelper")
local UIToolTipHelper = require("UIToolTipHelper")
local ItemDataTable = require("ItemDataTable")
local UISetUtils = require("UISetUtils")

UPSeaAdventureTile.nType = nil
UPSeaAdventureTile.nItemTemplateId = nil

local nTileTypeDef = SeaAdventureHelper.TILE_TYPE

local function OnItemButtonPressed(self)
    local pWidgetRef = self.pWidgetRef.btnItem
    if self.nItemTemplateId ~= nil then 
        local tbTipData = {}
        tbTipData.tbResTemplate = ItemDataTable:GetResTemplate(self.nItemTemplateId)
        tbTipData.tbTemplate =  ItemDataTable:GetTemplate(self.nItemTemplateId)
        UIToolTipHelper:ShowTipInAutoLayout(UIToolTipHelper.TipType.ITEM_TIP,tbTipData,pWidgetRef)
    elseif self.nType == nTileTypeDef.UNKNOWN then
        local tbTipData = {
            szTitle = UISetUtils.GetL10NTextByKey("SEAADVENTURE_UNKONWTILE_TITLE"),
            szDetail = UISetUtils.GetL10NTextByKey("SEAADVENTURE_UNKONWTILE_TIP"),
        }
        UIToolTipHelper:ShowTipInAutoLayout(UIToolTipHelper.TipType.TEXT_TIP, tbTipData, pWidgetRef)
    end
end

local function OnItemButtonReleased(self)
    UIToolTipHelper:HideTip()
end

function UPSeaAdventureTile:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnPressed, self, OnItemButtonPressed)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnReleased, self, OnItemButtonReleased)
end

function UPSeaAdventureTile:OnLoad()
end

function UPSeaAdventureTile:OnDestroy()
end

local function UpdateTileInfo(self)
    
    local pWidgetRef = self.pWidgetRef

    local VISIBLE, COLLAPSED = ESlateVisibility.SelfHitTestInvisible, ESlateVisibility.Collapsed
    pWidgetRef.imgGo:SetVisibility(self.nType == nTileTypeDef.START and VISIBLE or COLLAPSED)
    pWidgetRef.imgUnknown:SetVisibility(self.nType == nTileTypeDef.UNKNOWN and VISIBLE or COLLAPSED)
    
    local bShowItem = self.nType ~= nTileTypeDef.START and self.nType ~= nTileTypeDef.UNKNOWN
    pWidgetRef.imgItem:SetVisibility(bShowItem and VISIBLE or COLLAPSED)
    pWidgetRef.txtCount:SetVisibility(bShowItem and VISIBLE or COLLAPSED)
end

function UPSeaAdventureTile:SetSelect(bSelect)
    local VISIBLE, COLLAPSED = ESlateVisibility.SelfHitTestInvisible, ESlateVisibility.Hidden
    self.pWidgetRef.imgSelect:SetVisibility(bSelect and VISIBLE or COLLAPSED)
    
end

function UPSeaAdventureTile:PlayFinalSelectAnim()
    self:PlayAnimation("animSelect", 0, 1,  EUMGSequencePlayMode.Forward, 1)
end

function UPSeaAdventureTile:PlayNormalSelectAnim()
    self:PlayAnimation("animSelectParticles", 0, 1,  EUMGSequencePlayMode.Forward, 1)
end

function UPSeaAdventureTile:SetTileType(nType, nItemTemplateId)
    if self.nType ~= nType then  
        self.nType = nType
        UpdateTileInfo(self)
    end
end

function UPSeaAdventureTile:SetTileTemplateId(nItemTemplateId, nCount)
    self.nItemTemplateId = nItemTemplateId

    local pWidgetRef = self.pWidgetRef
    -- local nTileTypeDef = SeaAdventureHelper.TILE_TYPE
    local VISIBLE, COLLAPSED = ESlateVisibility.SelfHitTestInvisible, ESlateVisibility.Collapsed

    local bShowItem = self.nType ~= nTileTypeDef.START and self.nType ~= nTileTypeDef.UNKNOWN
    pWidgetRef.imgItem:SetVisibility(bShowItem and VISIBLE or COLLAPSED)
    if bShowItem and self.nItemTemplateId ~= nil then  
        local tbItemRes = ItemDataTable:GetResTemplate(self.nItemTemplateId)
        local szImgRes = tbItemRes.szIconPath
        UISetUtils.SetImageBrushRes(pWidgetRef.imgItem, szImgRes:load())
        pWidgetRef.txtCount:SetVisibility(nCount~= 0 and VISIBLE or COLLAPSED)
        if nCount ~= 0 then  
            pWidgetRef.txtCount:SetText(nCount)
        end
    end
end

return UPSeaAdventureTile