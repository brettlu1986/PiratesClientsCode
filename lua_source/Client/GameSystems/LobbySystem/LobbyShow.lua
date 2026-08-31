-----------------------------------------------------
--File Name    : LobbyShow.lua
--Author       : lzheng
--Description  : 大厅物品展示界面
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbySubBase = require("LobbySubBase")
local LobbyShow = luaclass("LobbyShip", LobbySubBase)

local UIDef = require("UIDef")
local UIManager = require("UIManager")
local ItemCategoryDef = require("ItemCategoryDef")
local UIUtils = require("UIUtils")

LobbyShow.nCurrentCategory = nil
LobbyShow.tbShowInfo = nil

local tbShowItem = 
{
    [ItemCategoryDef.DECORATION]            = { szUiName = UIDef.UI_LOBBY_DECORATION_SHOW,    nCamera = 1},
    [ItemCategoryDef.SHIP]                  = { szUiName = UIDef.UI_LOBBY_SHOW_SHIP,          nCamera = 1},
    [ItemCategoryDef.SHIP_SKIN]             = { szUiName = UIDef.UI_LOBBY_SHOW_SHIP,          nCamera = 1},
    [ItemCategoryDef.SHIP_WEAPON]           = { szUiName = UIDef.UI_LOBBY_SHOW_SHIP_WEAPON,   nCamera = 1},
    [ItemCategoryDef.FASHION]               = { szUiName = UIDef.UI_LOBBY_HUMAN_FASHION_SHOW, nCamera = 1},
    [ItemCategoryDef.HUMAN_WEAPON_FASHION]  = { szUiName = UIDef.UI_LOBBY_HUMAN_WEAPON_SHOW,  nCamera = 1},
    [ItemCategoryDef.SHIP_PART]             = { szUiName = UIDef.UI_LOBBY_SHOW_SHIP_PART,     nCamera = 1},
}

local function ShowLevel(self)
    if self.nCurrentCategory == nil then return end
    local tbShow = tbShowItem[self.nCurrentCategory]
    self:SetShouldBeVisible(tbShow.szUiName, true)
    self:SetCamera(tbShow.szUiName, tbShow.nCamera)
end  


local function ShowUi(self)
    if self.nCurrentCategory == nil then return end
    local tbShow = tbShowItem[self.nCurrentCategory]
    UIManager:OpenWnd(tbShow.szUiName, self.tbShowInfo)
end

local function DeactivateAll(self)
    if self.nCurrentCategory == nil then return end
    local tbShow = tbShowItem[self.nCurrentCategory]
    self:SetShouldBeVisible(tbShow.szUiName, false)
    UIManager:CloseWnd(tbShow.szUiName)
    UIUtils.BottomMenuHide(false)
    UIUtils.BottomMenuUnselectAll()
end

function LobbyShow:Init(Owner, nSubType)
    LobbyShow.super.Init(self, Owner, nSubType)
    return true
end

function LobbyShow:Uninit()
    LobbyShow.super.Uninit(self)
end

function LobbyShow:Activate(tbParam)
    LobbyShow.super.Activate(self, tbParam)

    if not tbParam then
        return
    end

    self.nCurrentCategory = tbParam.nCategory
    self.tbShowInfo = tbParam
    UIUtils.BottomMenuHide(true)
    ShowLevel(self)
    ShowUi(self)
end

function LobbyShow:Deactivate()
    LobbyShow.super.Deactivate(self)
    DeactivateAll(self)
end

return LobbyShow