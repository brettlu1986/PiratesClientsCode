local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIFirstPrize = luaclass("UIFirstPrize", WndBase)
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local IAPSystem = require("IAPSystem")
local UISetUtils = require("UISetUtils")
local UIUtils = require("UIUtils")
local ClientEventDef = require("ClientEventDef")
local Proto = require("ClientProtoNames")
local IapIni = require("IapIni")

local PURCHASE_IMG = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAEffect/Frames/Spr_Effect_13.Spr_Effect_13'"
local GET_IMG = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAEffect/Frames/Spr_Effect_12.Spr_Effect_12'"

local function RefreshUI(self)
    local pWidgetRef = self.pWidgetRef

    local imgTitle = pWidgetRef.imgTitle
    local nState = IAPSystem:GetFirstPurchaseState()
    local tbState = Proto.FirstPurchaseState
    if nState == tbState.NONE then
        UISetUtils.SetImageBrushRes(imgTitle, PURCHASE_IMG:load())
    else
        UISetUtils.SetImageBrushRes(imgTitle, GET_IMG:load())
    end
end

local function OnClickClose(self)
    self:CloseSelf()
end

local function OnClickDetail(self)
    UIManager:OpenWnd(UIDef.UI_LOBBY_SHIP_DETAIL, {nShipTemplateId = IapIni.tbFirstPurchase.nItemId})
end

local function OnClickFirstPrize(self)
    local nState = IAPSystem:GetFirstPurchaseState()
    local tbState = Proto.FirstPurchaseState
    if nState == tbState.NONE then
        UIManager:OpenWnd(UIDef.UI_LOBBY_IAP)
    elseif nState == tbState.DEBT then
        IAPSystem:RequestApplyFirstPurchaseReward()
        self:CloseSelf()
    else
        UIUtils.ShowToastWithKey("FIRST_PURCHASE_GETED")
    end
end

function UIFirstPrize:OnLoad()
end

function UIFirstPrize:OnUnload()
end

function UIFirstPrize:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked, self, OnClickClose)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDetail.OnClicked, self, OnClickDetail)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnFirstPrize.OnClicked, self, OnClickFirstPrize)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_FRESH_FIRST_PURCHASE, self, RefreshUI)
end

function UIFirstPrize:OnShow()
    local fnComplete = function()
        self:PlayAnimation("animaShip", 0, 0, EUMGSequencePlayMode.Forward, 1)        
    end
    self:PlayAnimation("animStart", 0, 1, EUMGSequencePlayMode.Forward, 1, fnComplete)
    RefreshUI(self)
end

return UIFirstPrize
