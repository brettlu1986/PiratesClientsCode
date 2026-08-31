-----------------------------------------------------
--File Name    : ItemRoom.lua
--Description  : Item 容器
-----------------------------------------------------

local luaclass = require("luaclass")
local ItemRoom = luaclass("ItemRoom")
local ItemRoomDef = require("ItemRoomDefine")
local BackpackDataTableOld = require("BackpackDataTableOld")
local DockSystem = require("DockSystem")
local ItemTypeDataTable = require("ItemTypeDataTable")
-- Room类型，默认为背包类型
ItemRoom.Type = ItemRoomDef.BACKPACK
ItemRoom.nRoomId = 0
-- 物品列表，是个List
ItemRoom.tbItemList = nil

local function Sort(self)
    local fnSortImpl =  function(ItemA, ItemB)
        local tbItemTemplateA = ItemA:GetTemplate()
        local tbItemTemplateB = ItemB:GetTemplate()

        local nGenreA = tbItemTemplateA.nGenre
        local nDetailTypeA = tbItemTemplateA.nDetailType
        local nParticularA = tbItemTemplateA.nParticular

        local nGenreB = tbItemTemplateB.nGenre
        local nDetailTypeB = tbItemTemplateB.nDetailType
        local nParticularB = tbItemTemplateB.nParticular

        local nSortValueA = ItemTypeDataTable:GetItemTypeSortValue(nGenreA, nDetailTypeA)
        local nSortValueB = ItemTypeDataTable:GetItemTypeSortValue(nGenreB, nDetailTypeB)

        if nSortValueA ~= nSortValueB then
            --logdebug("nSortValue", nSortValueA, nSortValueB, nSortValueA > nSortValueB)
            return nSortValueA > nSortValueB
        end

        local nGradeA = tbItemTemplateA.nGrade
        local nGradeB = tbItemTemplateB.nGrade
        if nGradeA ~= nGradeB then
            --logdebug("nGrade", nGradeA, nGradeB, nGradeA > nGradeB)
            return nGradeA > nGradeB
        end

        if nGenreA ~= nGenreB then
            --logdebug("nGenre", nGenreA, nGenreB, nGenreA < nGenreB)
            return nGenreA < nGenreB
        end

        if nDetailTypeA ~= nDetailTypeB then
            --logdebug("nDetailType", nDetailTypeA, nDetailTypeB, nDetailTypeA < nDetailTypeB)
            return nDetailTypeA < nDetailTypeB
        end

        if nParticularA ~= nParticularB then
            --logdebug("nParticular", nParticularA, nParticularB, nParticularA < nParticularB)
            return nParticularA < nParticularB
        end

        local nCountA = ItemA:GetStackCount()
        local nCountB = ItemB:GetStackCount()

        --logdebug("nCount", nCountA, nCountB, nCountA < nCountB )
        return nCountA > nCountB 
    end
    table.sort(self.tbItemList, fnSortImpl)
end

local function FindPos(self, nItemId)
    local nPos = 1
    local bFind = false
    for i, Item in ipairs(self.tbItemList) do  
          if Item:GetInstanceId() == nItemId then
            bFind = true
            nPos = i
            break
          end
    end
    return bFind, nPos
end

-- 容器容量
-- return bool
function ItemRoom:GetRemainRoomCount()
    if self.Type == ItemRoomDef.BACKPACK then 
        local nCapacity = BackpackDataTableOld:GetCapacity(self.nRoomId)
        return nCapacity - #self.tbItemList
    elseif self.Type == ItemRoomDef.SHIP_CABIN then
        local nTotalStackCount = 0
        for i, v in ipairs(self.tbItemList) do
            nTotalStackCount = nTotalStackCount + v:GetStackCount() 
        end
        local nMaxCargoCapacity = DockSystem:GetCabinCapacity(self.nRoomId)

        return nMaxCargoCapacity - nTotalStackCount
    end
    return 0
end


-- 容器是否满
-- return bool
function ItemRoom:IsContainerFull()
    if self.Type == ItemRoomDef.BACKPACK then 
        local nCapacity = BackpackDataTableOld:GetCapacity(self.nRoomId)
        return #self.tbItemList >= nCapacity
    elseif self.Type == ItemRoomDef.SHIP_CABIN then
        local nTotalStackCount = 0
        for i, v in ipairs(self.tbItemList) do
            nTotalStackCount = nTotalStackCount + v:GetStackCount() 
        end
        local nMaxCargoCapacity = DockSystem:GetCabinCapacity(self.nRoomId)

        return nTotalStackCount >= nMaxCargoCapacity
    end
    return false
end

function ItemRoom:GetCabinStackCount()
    if self.Type ~= ItemRoomDef.SHIP_CABIN then
        logerror("ItemRoom:GetCabinStackCount error! this item room is not a cabin!")
    end
    local nTotalStackCount = 0
    for i, v in ipairs(self.tbItemList) do
        nTotalStackCount = nTotalStackCount + v:GetStackCount() 
    end
    return nTotalStackCount
end

function ItemRoom:construct()
    self.tbItemList = {}
end

function ItemRoom:GetItemList()
    return self.tbItemList
end

function ItemRoom:GetItemCount()
    return #(self.tbItemList)
end

function ItemRoom:AddItem(Item)
    local bFind, nPos =  FindPos(self, Item:GetInstanceId())
    if bFind == true then
        logerror("ItemRoom:AddItem(), item already exist !")
        return false
    end

    table.insert( self.tbItemList, nPos, Item )

    return true
end

function ItemRoom:UpdateItemStackCount(nItemId, nNewStackCount)
    local bFind, nPos = FindPos(self, nItemId)
    if bFind == true then
        self.tbItemList[nPos]:SetStackCount(nNewStackCount)
    end
    return bFind
end

function ItemRoom:UpdateItemDurability(nItemId, nDurability)
    local bFind, nPos = FindPos(self, nItemId)
    if bFind == true then
        self.tbItemList[nPos]:SetDurablity(nDurability)
    end
    return bFind
end

function ItemRoom:UpdateItemFirstUseTime(nItemId, nFirstUseTime)
    local bFind, nPos = FindPos(self, nItemId)
    if bFind == true then
        self.tbItemList[nPos]:SetFirstUseTime(nFirstUseTime)
    end
    return bFind
end

function ItemRoom:UpdateItemProperties(nItemId, tbProperties)
    local bFind, nPos = FindPos(self, nItemId)
    if bFind == true then
        self.tbItemList[nPos]:SetProperties(tbProperties)
    end
    return bFind
end

function ItemRoom:RemoveItem(nItemId)
    local bFind, nPos = FindPos(self, nItemId)
    if bFind == true then
        table.remove(self.tbItemList, nPos)
    end
    return bFind
end

function ItemRoom:Sort()
    Sort(self)
end

function ItemRoom:GetCount(nGenre, nDetailType, nParticular)
    local nCount = 0
    for nPos, Item in ipairs(self.tbItemList) do
        local tbTemplate = Item:GetTemplate()
        if tbTemplate.nGenre == nGenre and tbTemplate.nDetailType == nDetailType and tbTemplate.nParticular == nParticular then
            nCount = nCount + Item:GetStackCount()
        end
    end
    return nCount
end

function ItemRoom:GetItemsByType(nGenre, nDetailType, nParticular)
    local tbItems = {}
    for nPos, Item in ipairs(self.tbItemList) do
        local tbTemplate = Item:GetTemplate()
        if tbTemplate.nGenre == nGenre and tbTemplate.nDetailType == nDetailType and tbTemplate.nParticular == nParticular then
            table.insert(tbItems, Item)
        end
    end
    return tbItems
end

function ItemRoom:GetItem(nItemId)
    local bFind, nPos = FindPos(self, nItemId)
    if bFind == true then
        return self.tbItemList[nPos]
    end
    return nil
end

function ItemRoom:GetAndRemoveItem(nItemId)
    local bFind, nPos = FindPos(self, nItemId)
    local tbItem = nil
    if bFind == true then
        tbItem = self.tbItemList[nPos]
        table.remove(self.tbItemList, nPos)
    end
    return tbItem
end

return ItemRoom
