-----------------------------------------------------
--File Name    : UPLobbyShipTitle.lua
--Author       : chenyixin
--Description  : 船战图鉴界面名称up
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyShipTitle = luaclass("UPLobbyShipTitle", PrefabBase)

local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local UITextDef = require("UITextDef")
-- local UIResourceDef= require("UIResourceDef")

local LobbyShipDef = require("LobbyShipDef")
local ShipOwningStateDef = LobbyShipDef.OwningStateDef

-- local LOCKED_OPACITY = 0.5
-- local LOCKED_COLOR = KMUMGLibrary.GetSlateColor(1.0, 1.0, 1.0, 1.0, LOCKED_OPACITY)
-- local NORMAL_OPACITY = 1
-- local NORMAL_COLOR = UIResourceDef.COLOR.WHITE.SLATE_COLOR
-- local LOCKED_SHADOW_COLOR = KMUMGLibrary.GetLinearColor(0.0, 0.0, 0.0, LOCKED_OPACITY)
-- local SHADOW_COLOR = UIResourceDef.COLOR.BLACK.LINEAR_COLOR

UPLobbyShipTitle.fnOnExpirationTimeEnd = nil
UPLobbyShipTitle.fnOnTitleClicked = nil

local function OnExpirationTimeEnd(self)
    -- if self.fnOnExpirationTimeEnd then
    --     self.fnOnExpirationTimeEnd()
    -- end
end

local function OnBdrTitleClicked(self, pGeometry, pMouseEvent)
    if self.fnOnTitleClicked then
        self.fnOnTitleClicked()
    end
    return WidgetBlueprintLibrary.Handled()
end

function UPLobbyShipTitle:OnLoad()
    self.OwnerSub = self.Owner.OwnerSub
end

function UPLobbyShipTitle:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.txtOwningState.OnCompleteTimer, self, OnExpirationTimeEnd)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrShipTitle.OnMouseButtonDownEvent, self, OnBdrTitleClicked)
end


function UPLobbyShipTitle:SetData(tbShipHandbookItemData)
    local pWidgetRef = self.pWidgetRef
    local tbTemplate = tbShipHandbookItemData.tbTemplate
    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    
    -- 等级/皮肤名称
    if tbShipHandbookItemData.tbSkinTemplate then
        local tbSkinTemplate = tbShipHandbookItemData.tbSkinTemplate
        pWidgetRef.txtShipLevel:SetText(tbSkinTemplate.l10nPrefixName)
        pWidgetRef.txtShipLevel:SetColorAndOpacity(KMUMGLibrary.GetSlateColorFromHex(L10N:ToString(UITextDef.ITEM_GRADE_COLOR_TEXT[tbSkinTemplate.nGrade])))
    else
        local szShipDescFormat = UISetUtils.GetL10NTextByKey("SHIP_DESC_FORMAT")
        local szShipDesc = L10N:Format(szShipDescFormat, UITextDef.SHIP_GRADE_TEXT[tbShipHandbookItemData.nLevel])
        pWidgetRef.txtShipLevel:SetText(szShipDesc)
    end

    -- 名称
    pWidgetRef.txtShipName:SetText(tbTemplate.l10nName)

    -- 解锁状态
    local bShowImgLocked = false
    local nExpirationTime = ShipPreparationComponent:GetItemExpirationTime(tbShipHandbookItemData.nShipItemId)
    local nShipOwningState = tbShipHandbookItemData.nShipOwningState
    if nShipOwningState == ShipOwningStateDef.Experience and nExpirationTime > 0 then
        pWidgetRef.txtOwningState:StartTimer(nExpirationTime, 1, UITextDef.TIMER_TEXT_BLOCK_FORMAT_FULL, EMinTimeUnit.Second)
    else
        pWidgetRef.txtOwningState:StopTimer()

        local l10nText =  UISetUtils.GetL10NTextByKey("UI_LOBBY_SHIP_OWNED")
        if tbTemplate.bDefaultEquipped then
            l10nText =  UISetUtils.GetL10NTextByKey("UI_LOBBY_SHIP_DEFAULT_EQUIPPED")
        elseif nShipOwningState == ShipOwningStateDef.Locked then
            bShowImgLocked = true
            l10nText =  UISetUtils.GetL10NTextByKey("RETURN_CODE_SHIP_SLOT_LOCKED")
        end

        pWidgetRef.txtOwningState:SetText(l10nText)
    end

    if tbShipHandbookItemData.bShowWnd then
        return
    end

    pWidgetRef.imgLocked:SetVisibility(bShowImgLocked and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)

    -- local pColor = bShowImgLocked and LOCKED_COLOR or NORMAL_COLOR
    -- local pShadowColor = bShowImgLocked and LOCKED_SHADOW_COLOR or SHADOW_COLOR
    -- local nOpacity = bShowImgLocked and LOCKED_OPACITY or NORMAL_OPACITY
    -- pWidgetRef.txtShipLevel:SetColorAndOpacity(pColor)
    -- pWidgetRef.txtShipLevel:SetOpacity(nOpacity)
    -- pWidgetRef.txtShipLevel:SetShadowColorAndOpacity(pShadowColor)
    -- pWidgetRef.txtShipName:SetColorAndOpacity(pColor)
    -- pWidgetRef.txtShipName:SetOpacity(nOpacity)
    -- pWidgetRef.txtShipName:SetShadowColorAndOpacity(pShadowColor)
end

function UPLobbyShipTitle:BindCallbacks(fnOnExpirationTimeEnd, fnOnTitleClicked)
    self.fnOnExpirationTimeEnd = fnOnExpirationTimeEnd
    self.fnOnTitleClicked = fnOnTitleClicked
end

return UPLobbyShipTitle