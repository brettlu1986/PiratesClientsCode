-----------------------------------------------------
--File Name    : LobbyCaptainHumanFashionRedDotOperator.lua
--Description  :
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbyCaptainHumanFashionRedDotOperator = luaclass("LobbyCaptainHumanFashionRedDotOperator")

local ClientEventDef = require("ClientEventDef")

local UILobbyCaptainHelper = require("UILobbyCaptainHelper")
local HumanAvatarDef = require("HumanAvatarDef")
local LobbyCaptainMiscDef = require("LobbyCaptainMiscDef")

local FashionSlotCategoryExtendToTabIndex = LobbyCaptainMiscDef.FashionSlotCategoryExtendToTabIndex
local FashionType = HumanAvatarDef.FashionType
local FashionSlotCategoryExtend = HumanAvatarDef.FashionSlotCategoryExtend

LobbyCaptainHumanFashionRedDotOperator.nFashionType = nil

local function GetOwnerPrefab(self)
    return self.tbOwner
end

local function GetEventHelper(self)
    local tbOwner = GetOwnerPrefab(self)
    return tbOwner.EventHelper
end


local function GetCategoryTabBarHelper(self)
    local tbOwner = GetOwnerPrefab(self)
    return tbOwner.tbCategoryTabHelper
end

local function GetSubCategoryTabBarHelper(self)
    local tbOwner = GetOwnerPrefab(self)
    return tbOwner.tbSubCategoryTabHelper
end

local function UpdateCategoryRedDot(self)
    local tbCategoryTabHelper = GetCategoryTabBarHelper(self)
    for _, nFashionType in pairs(FashionType) do
        local bRed = UILobbyCaptainHelper.HasNewHumanFashionByFashionType(nFashionType)
        tbCategoryTabHelper:SetTipIconVisible(nFashionType, bRed)
    end
end

local function UpdateSubCategoryRedDot(self, nFashionType)
    local tbSubCategoryTabHelper = GetSubCategoryTabBarHelper(self)
    for _, nSlotCategory in pairs(FashionSlotCategoryExtend) do
        local bHas
        if nSlotCategory == FashionSlotCategoryExtend.Suit then
            bHas = UILobbyCaptainHelper.HasNewHumanSuitByFashionType(nFashionType)
        else
            bHas = UILobbyCaptainHelper.HasNewHumanFashionByFashionAndSlotType(nFashionType, nSlotCategory)
        end
        tbSubCategoryTabHelper:SetTipIconVisible(FashionSlotCategoryExtendToTabIndex[nSlotCategory], bHas)
    end
end

local function RefreshRedDot(self)
    UpdateCategoryRedDot(self)
    UpdateSubCategoryRedDot(self, self.nFashionType)
end

function LobbyCaptainHumanFashionRedDotOperator:UpdateFashionType(nFashionType)
    self.nFashionType = nFashionType
    RefreshRedDot(self)
end

function LobbyCaptainHumanFashionRedDotOperator:Activate()
    local EventHelper = GetEventHelper(self)
    EventHelper:RegisterEvent(ClientEventDef.EV_NEW_ITEM_RECORD_STATE_CHANGED, self, RefreshRedDot)
end

function LobbyCaptainHumanFashionRedDotOperator:Deactivate()
    local EventHelper = GetEventHelper(self)
    EventHelper:UnregisterEvent(ClientEventDef.EV_NEW_ITEM_RECORD_STATE_CHANGED, self, RefreshRedDot)
end


function LobbyCaptainHumanFashionRedDotOperator:Init(tbOwner)
    self.tbOwner = tbOwner
end

function LobbyCaptainHumanFashionRedDotOperator:Uninit()
    self.tbOwner = nil
end


return LobbyCaptainHumanFashionRedDotOperator