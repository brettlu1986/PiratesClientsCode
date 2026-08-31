-----------------------------------------------------
--File Name    : LobbyCaptainWeaponFashionRedDotOperator.lua
--Description  :
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbyCaptainWeaponFashionRedDotOperator = luaclass("LobbyCaptainWeaponFashionRedDotOperator")

local ClientEventDef = require("ClientEventDef")

local UILobbyCaptainHelper = require("UILobbyCaptainHelper")
local LobbyWeaponMiscDataTable = require("LobbyWeaponMiscDataTable")

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


local function RefreshRedDot(self)
    local tbCategoryTabHelper = GetCategoryTabBarHelper(self)
    local tbTemplates = LobbyWeaponMiscDataTable:GetAllTemplates()
    for nInstanceType, tbTemplate in pairs(tbTemplates) do
        if tbTemplate.bActive then
            local bRed = UILobbyCaptainHelper.HasNewHumanWeaponFashionByInstanceType(nInstanceType)
            tbCategoryTabHelper:SetTipIconVisible(nInstanceType, bRed)
        end
    end
end


function LobbyCaptainWeaponFashionRedDotOperator:Activate()
    local EventHelper = GetEventHelper(self)
    EventHelper:RegisterEvent(ClientEventDef.EV_NEW_ITEM_RECORD_STATE_CHANGED, self, RefreshRedDot)
    RefreshRedDot(self)
end

function LobbyCaptainWeaponFashionRedDotOperator:Deactivate()
    local EventHelper = GetEventHelper(self)
    EventHelper:UnregisterEvent(ClientEventDef.EV_NEW_ITEM_RECORD_STATE_CHANGED, self, RefreshRedDot)
end


function LobbyCaptainWeaponFashionRedDotOperator:Init(tbOwner)
    self.tbOwner = tbOwner
end

function LobbyCaptainWeaponFashionRedDotOperator:Uninit()
    self.tbOwner = nil
end


return LobbyCaptainWeaponFashionRedDotOperator