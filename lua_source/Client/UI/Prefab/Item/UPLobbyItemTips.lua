-----------------------------------------------------
--File Name    : UPLobbyItemTips.lua
--Author       : Edward J
--Create Time  : 2018-03-12
--Description  : UPLobbyItemTips
-----------------------------------------------------
local luaclass          = require ("luaclass")
local UPTipBase         = require("UPTipBase")
local UPLobbyItemTips   = luaclass("UPLobbyItemTips", UPTipBase)

local ItemDataTable     = require("ItemDataTable")
local UIDef             = require("UIDef")
local ItemSystem        = require("ItemSystem")
local LobbyItemUiHelper = require("LobbyItemUiHelper")

UPLobbyItemTips.pbLobbyDisplayItem = nil

local function SetName(self, l10nName)
    self.pWidgetRef.txtName:SetText(l10nName)
end

local function SetDesc(self, l10nDesc)
    self.pWidgetRef.kmtxtDesc:SetText(l10nDesc)
end

local function SetSizeText(self, tbItemTemplate)
    self.pWidgetRef.kmtxtSize:SetText(LobbyItemUiHelper.GetBuildingSizeDesc(tbItemTemplate))
end

local function SetCount(self, nCount)
    nCount = (nCount == nil) and 0 or nCount
    if nCount > 0 then
        self.pWidgetRef.pbLobbyItem.TxtCount:SetText(nCount)
    else
        self.pWidgetRef.pbLobbyItem.TxtCount:SetText("")
    end
end

local function SetData(self, nItemTemplateId)
    self.pbLobbyDisplayItem:SetDisplayItemData(nItemTemplateId, nil, false)

    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    SetName(self, tbItemTemplate.l10nName)
    SetDesc(self, ItemSystem:GetItemIntro(nItemTemplateId))
    SetSizeText(self, tbItemTemplate)
    SetCount(self,0)
end

--tbTipdata的必要数据1.tbTemplate  2.nCount
local function Init(self)
    local tbTipData = self.tbTipData
    if (tbTipData == nil) or (tbTipData.tbTemplate == nil) then
        return
    end

    SetData(self, tbTipData.tbTemplate.nId)
    if tbTipData.bForceShowCount then
        SetCount(self,tbTipData.nCount)
    end
end

function UPLobbyItemTips:OnLoad()
    self.pbLobbyDisplayItem = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyItem, UIDef.UP_LOBBY_DISPLAY_ITEM)
end

function UPLobbyItemTips:OnShow()
    Init(self)
end

return UPLobbyItemTips
