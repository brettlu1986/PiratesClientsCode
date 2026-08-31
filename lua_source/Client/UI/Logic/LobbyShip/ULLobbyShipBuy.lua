-----------------------------------------------------
--File Name    : ULLobbyShipBuy.lua
--Author       : chenyixin
--Description  : 舰船界面购买逻辑
-----------------------------------------------------

local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyShipBuy = luaclass("ULLobbyShipBuy", UILogicBase)

local ItemSourceDataTable = require("ItemSourceDataTable")
local ItemCategoryDef = require("ItemCategoryDef")
local UISetUtils = require("UISetUtils")

ULLobbyShipBuy.tbItemTemplate = nil
ULLobbyShipBuy.bIsActiveBtn = false

-- local BUY_BTN_NORMAL_RES = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_ButtonMYellow_Normal.Spr_ButtonMYellow_Normal'"
-- local BUY_BTN_ACTIVE_RES = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_ButtonM_Normal.Spr_ButtonM_Normal'"

local BUY_DESCRIBE_TEXT_KEY = {
    [ItemCategoryDef.SHIP_SKIN] = "UI_STATIC_UNLOCK_SHIP_SKIN",
    [ItemCategoryDef.SHIP] = "UI_STATIC_UNLOCK_SHIP",
    [ItemCategoryDef.SHIP_WEAPON] = "UI_STATIC_ACCESSOROYSHIP_UNLOCK",
}

local UNLOCK_CONDITION_POS = {
    [ItemCategoryDef.SHIP_SKIN] = Vector2D{X = -200, Y = -13},
    [ItemCategoryDef.SHIP] = Vector2D{X = 340, Y = -92}
}

local SOURCE_TYPE_DEFAULT_OWNED = 0

---------------------------------------
-- Widget事件
---------------------------------------
local function Buy(self)
    if not self.tbItemTemplate then
        return
    end
    local nCategory = self.tbItemTemplate.nCategory
    local OwnerSub = self.OwnerSub
    local tbItemTemplate = self.tbItemTemplate
    if nCategory == ItemCategoryDef.SHIP_SKIN then
        OwnerSub:RequestGetItem(tbItemTemplate, self.Owner.bReturnWhenWear)
    elseif nCategory == ItemCategoryDef.SHIP then
        OwnerSub:RequestGetItem(tbItemTemplate)
    elseif nCategory == ItemCategoryDef.SHIP_WEAPON then
        OwnerSub:RequestGetItem(tbItemTemplate)
    end
end

local function Active(self)
    local tbItemTemplate = self.tbItemTemplate
    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    if tbItemTemplate.nCategory == ItemCategoryDef.SHIP_WEAPON then
        ShipPreparationComponent:RequestActivateWeapon(tbItemTemplate.nId)
    end
end

local function OnBuyBtnClicked(self)
    if self.Owner.SetDetailVisible then
        self.Owner:SetDetailVisible(false, false)
    end
    if self.bIsActiveBtn then
        Active(self)
    else
        Buy(self)
    end
    local pWidgetRef = self.pWidgetRef
    if pWidgetRef.imgBuyGlow then
        self.Owner:StopAnimation("animBuyShipGlow", 0, 0, EUMGSequencePlayMode.Forward, 1)
        pWidgetRef.imgBuyGlow:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.imgBuyGlow01:SetVisibility(ESlateVisibility.Collapsed)
    end
end

---------------------------------------
-- life cycle
---------------------------------------
function ULLobbyShipBuy:OnLoad()
    self.OwnerSub = self.Owner.OwnerSub
end

function ULLobbyShipBuy:OnShow()
end

function ULLobbyShipBuy:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    if pWidgetRef.btnBuy then
        EventHelper:RegisterCppDelegate(pWidgetRef.btnBuy.OnClicked, self, OnBuyBtnClicked)
    end
    if pWidgetRef.btnBuyShip then
        EventHelper:RegisterCppDelegate(pWidgetRef.btnBuyShip.OnClicked, self, OnBuyBtnClicked)
    end
end

---------------------------------------
-- 接口
---------------------------------------
function ULLobbyShipBuy:Update(tbItemTemplate)
    self.tbItemTemplate = tbItemTemplate
    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    local pWidgetRef = self.pWidgetRef
    local szBuyDesc = nil
    local szSourceDesc = nil
    if tbItemTemplate and (not ShipPreparationComponent:IsItemUnlocked(tbItemTemplate.nId)) then
        if ItemSourceDataTable:IfShowBuyButton(tbItemTemplate.nSourceType) then
            local szKey = BUY_DESCRIBE_TEXT_KEY[tbItemTemplate.nCategory]
            if szKey then
                szBuyDesc = UISetUtils.GetL10NTextByKey(szKey)
            end
        elseif tbItemTemplate.nSourceType ~= SOURCE_TYPE_DEFAULT_OWNED then
            szSourceDesc = ItemSourceDataTable:GetSourceDesc(tbItemTemplate.nSourceType)
        end
    end

    if szBuyDesc and tbItemTemplate.nCategory ~= ItemCategoryDef.SHIP then
        self.bIsActiveBtn = false
        -- UISetUtils.SetButtonBrushRes(pWidgetRef.BtnBuy, BUY_BTN_NORMAL_RES:load())
        pWidgetRef.btnBuy:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.txtBuy:SetText(szBuyDesc)
    else
        pWidgetRef.btnBuy:SetVisibility(ESlateVisibility.Collapsed)
    end

    if szSourceDesc then
        pWidgetRef.bdrUnlockCondition:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.txtUnlockCondition:SetText(szSourceDesc)
        local pPos = UNLOCK_CONDITION_POS[tbItemTemplate.nCategory]
        if pPos then
            pWidgetRef.bdrUnlockCondition.Slot:SetPosition(pPos)
        end
    else
        pWidgetRef.bdrUnlockCondition:SetVisibility(ESlateVisibility.Collapsed)
    end

    if not pWidgetRef.btnBuyShip then
        return 
    end
    if szBuyDesc and tbItemTemplate.nCategory == ItemCategoryDef.SHIP then
        pWidgetRef.btnBuyShip:SetVisibility(ESlateVisibility.Visible)
        if pWidgetRef.imgBuyGlow then
            pWidgetRef.imgBuyGlow:SetVisibility(ESlateVisibility.HitTestInvisible)
            pWidgetRef.imgBuyGlow01:SetVisibility(ESlateVisibility.HitTestInvisible)
            self.Owner:PlayAnimation("animBuyShipGlow", 0, 0, EUMGSequencePlayMode.Forward, 1)
        end
    else
        pWidgetRef.btnBuyShip:SetVisibility(ESlateVisibility.Collapsed)
        if pWidgetRef.imgBuyGlow then
            self.Owner:StopAnimation("animBuyShipGlow", 0, 0, EUMGSequencePlayMode.Forward, 1)
            pWidgetRef.imgBuyGlow:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.imgBuyGlow01:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

function ULLobbyShipBuy:UpdateActiveState(tbItemTemplate)
    if not tbItemTemplate then
        return
    end
    
    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    if not ShipPreparationComponent:IsItemUnlocked(tbItemTemplate.nId) then
        return
    end

    local szBuyDesc = nil
    local nActiveId = nil
    if tbItemTemplate.nCategory == ItemCategoryDef.SHIP_WEAPON then
        nActiveId = ShipPreparationComponent:GetActiveWeaponId(tbItemTemplate.nSubCategory)
    end
    if not nActiveId then
        return
    end
    local pWidgetRef = self.pWidgetRef
    if nActiveId ~= tbItemTemplate.nId then
        szBuyDesc = UISetUtils.GetL10NTextByKey("UI_STATIC_ACTIVATE")
        pWidgetRef.btnBuy:SetVisibility(ESlateVisibility.Visible)
        self.bIsActiveBtn = true
    else
        -- szBuyDesc = UISetUtils.GetL10NTextByKey("UI_STATIC_ACTIVATED")
        pWidgetRef.btnBuy:SetVisibility(ESlateVisibility.Collapsed)
    end
    
    -- UISetUtils.SetButtonBrushRes(pWidgetRef.BtnBuy, BUY_BTN_ACTIVE_RES:load())
    pWidgetRef.txtBuy:SetText(szBuyDesc)
end

return ULLobbyShipBuy