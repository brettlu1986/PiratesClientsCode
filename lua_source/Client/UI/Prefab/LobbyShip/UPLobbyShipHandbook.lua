-----------------------------------------------------
--File Name    : UPLobbyShipHandbook.lua
--Author       : Song Fuhao
--Create Time  : 2019-11-19
--Description  : 舰船图鉴
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyShipHandbook = luaclass("UPLobbyShipHandbook", PrefabBase)

local UIDef = require("UIDef")
local ItemSystem = require("ItemSystem")
local ItemCategoryDef = require("ItemCategoryDef")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local START_GRADE = 1
local MAX_GRADE = 3
local CATEGORY_COUNT = 3

UPLobbyShipHandbook.tbHandbookItemMap = nil

-- 添加ShipItem到表格中
-- @param nRow      从0开始
-- @param nColumn   由Category决定，从1开始
local function AddShipToGrid(self, tbTemplate, nRow, nColumn)
    local pbHandbookItem = self.PrefabHelper:CreatePrefab(UIDef.UP_LOBBY_SHIP_HANDBOOK_ITEM)
    local pSlot = self.pWidgetRef.gridItems:AddChild(pbHandbookItem.pWidgetRef)
    pSlot:SetRow(nRow)
    pSlot:SetColumn(nColumn)
    pSlot:SetHorizontalAlignment(EHorizontalAlignment.HAlign_Center)
    pSlot:SetVerticalAlignment(EVerticalAlignment.VAlign_Center)
    pbHandbookItem:SetShipItemTemplate(tbTemplate)
    self.tbHandbookItemMap[tbTemplate.nId] = pbHandbookItem
end

-- 构建Ship表格
local function BuildShipGrid(self, tbShipGraphData)
    local nStartRow = 0
    local nLastMaxCount = 0 -- 上一个等级终一个分类下的最大个数
    for nGrade = START_GRADE, MAX_GRADE do
        nStartRow = nStartRow + nLastMaxCount
        local nIndexStart = nGrade * CATEGORY_COUNT
        for nCategory = 1, CATEGORY_COUNT do
            local tbTemplates = tbShipGraphData[nIndexStart + nCategory]
            if tbTemplates then
                nLastMaxCount = math.max(nLastMaxCount, #tbTemplates)
                local nGradeStartRow = nStartRow
                for i, tbTemplate in ipairs(tbTemplates) do
                    AddShipToGrid(self, tbTemplate, nGradeStartRow, nCategory)
                    nGradeStartRow = nGradeStartRow + 1
                end
            end
        end
        self.pWidgetRef["cvsGrade_"..nGrade].Slot:SetRow(nStartRow)
        self.pWidgetRef["cvsGrade_"..nGrade].Slot:SetRowSpan(nLastMaxCount)
    end
end

local function OnAddItem(self, Item)
    local nCategory = Item:GetCategory()
    if nCategory ~= ItemCategoryDef.SHIP then
        return
    end
    local nItemTemplateId = Item:GetTemplateId()
    self.tbHandbookItemMap[nItemTemplateId]:UnlockShip()
end

local function OnItemChangeExpiredAt(self, nItemInstanceId, bPermanent)
    if not bPermanent then
        return
    end
    local Item = ItemSystem:GetItem(nItemInstanceId)
    OnAddItem(self, Item)
end

local function OnReceiveShipSkinChanged(self, nTemplateId, nShipSkinId)
    self.tbHandbookItemMap[nTemplateId]:UpdateShipSkin(nShipSkinId)
end

-- 初始化Ship图标数据
local function InitShipGraphData(self)
    local tbShipGraphData = {}
    local tbShipTemplates = GamePlayerSelfHelper:Get().ShipPreparationComponent:GetSortedShipTemplates()
    for _, tbTemplate in ipairs(tbShipTemplates) do
        local nIndex = (tbTemplate.nGrade) * CATEGORY_COUNT + tbTemplate.nSubCategory
        tbShipGraphData[nIndex] = tbShipGraphData[nIndex] or {}
        table.insert(tbShipGraphData[nIndex], tbTemplate)
    end
    return tbShipGraphData
end

function UPLobbyShipHandbook:OnLoad()
    self.tbHandbookItemMap = {}
    local tbShipGraphData = InitShipGraphData(self)
    BuildShipGrid(self, tbShipGraphData)
end

function UPLobbyShipHandbook:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SHIP_SKIN_CHANGED, self, OnReceiveShipSkinChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_ADD_LOBBY_ITEM, self, OnAddItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_LOBBY_ITEM_EXPIRED_AT, self, OnItemChangeExpiredAt)
end

return UPLobbyShipHandbook