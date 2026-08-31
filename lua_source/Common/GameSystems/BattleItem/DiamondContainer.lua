-----------------------------------------------------
--File Name    : DiamondContainer.lua
--Author       : zhiyuan
--Create Time  : 2020-05-19
--Description  : 管理宝石位置
-----------------------------------------------------

local DiamondContainer = {}

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

DiamondContainer.tbDiamondDatas = nil

DiamondContainer.tbDiamondGridDatas = nil

DiamondContainer.nGamePlayWidth = 0
DiamondContainer.nGamePlayHeight = 0
DiamondContainer.nCountX = 0
DiamondContainer.nCountY = 0

local DIAMOND_TEMPLATE_ID = 11010004
local UNIT_LENGTH = 100000

local BattleItemSystemServer = nil

local function CalIndex(self, i, j)
    return i * self.nCountX + j
end

local function GetGridIndex(self, x, y)
    local i = math.ceil((self.nGamePlayWidth / 2 + x) / UNIT_LENGTH) - 1
    local j = math.ceil((self.nGamePlayHeight / 2 - y) / UNIT_LENGTH) - 1
    local nIndex = CalIndex(self, i, j)
    --log("[DiamondContainer]GetGridIndex", x, y, i, j, nIndex)
    return nIndex, i, j
end

local function GetGridData(self, nGridIndex)
    return self.tbDiamondGridDatas[nGridIndex]
end

local function AddToGrid(self, nGridIndex, nInstanceId)
    local tbGridData = self.tbDiamondGridDatas[nGridIndex]
    if tbGridData == nil then
        error("Cannot find grid " .. nGridIndex)
    end
    tbGridData[nInstanceId] = true
    --log("[DiamondContainer]AddToGrid", nGridIndex, nInstanceId)
end

local function DeleteFromGrid(self, nGridIndex, nInstanceId)
    local tbGridData = self.tbDiamondGridDatas[nGridIndex]
    if tbGridData == nil then
        error("Cannot find grid " .. nGridIndex)
    end
    tbGridData[nInstanceId] = nil
    --log("[DiamondContainer]DeleteFromGrid", nGridIndex, nInstanceId)
end

local function IsValidGrid(self, nGridIndex)
    local tbGridData = self.tbDiamondGridDatas[nGridIndex]
    if tbGridData == nil then
        return false
    end
    return true
end

local function InitGridDatas(self)
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbMapSize = tbGameMode.tbJsonTableFile.tbContainer.MapSize[1]

    self.nGamePlayWidth = tbMapSize.GamePlayWidth
    self.nGamePlayHeight = tbMapSize.GamePlayHeight

    self.nCountX = math.ceil(self.nGamePlayWidth / UNIT_LENGTH)
    self.nCountY = math.ceil(self.nGamePlayHeight / UNIT_LENGTH)

    for i = 0, self.nCountX - 1 do
        for j = 0, self.nCountY - 1 do
            local nIndex = CalIndex(self, i, j)
            self.tbDiamondGridDatas[nIndex] = {}
        end
    end
end


local function GetDiamonds(self, i, j, nDelta)
    local tbIndexes = {}
    local tbDiamonds = nil
    if nDelta == 0 then
        local nIndex = CalIndex(self, i, j)
        tbIndexes[nIndex] = true
    else
        local nMinI = math.max(0, i - nDelta)
        local nMaxI = math.min(self.nCountX - 1, i + nDelta)

        local nMinJ = math.max(0, j - nDelta)
        local nMaxJ = math.min(self.nCountY - 1, j + nDelta)

        if nMinJ == j - nDelta then
            for nI = nMinI, nMaxI do
                local nIndex = CalIndex(self, nI, nMinJ)
                tbIndexes[nIndex] = true
            end
        end

        if nMaxJ == j + nDelta then
            for nI = nMinI, nMaxI do
                local nIndex = CalIndex(self, nI, nMaxJ)
                tbIndexes[nIndex] = true
            end
        end

        if nMinI == i - nDelta then
            for nJ = nMinJ, nMaxJ do
                local nIndex = CalIndex(self, nMinI, nJ)
                tbIndexes[nIndex] = true
            end
        end

        if nMaxI == i + nDelta then
            for nJ = nMinJ, nMaxJ do
                local nIndex = CalIndex(self, nMaxI, nJ)
                tbIndexes[nIndex] = true
            end
        end
    end

    for nIndex, _ in pairs(tbIndexes) do
        local tbGridDatas = GetGridData(self, nIndex)
        if tbGridDatas then
            for nInstanceId, _ in pairs(tbGridDatas) do
                if not tbDiamonds then
                    tbDiamonds = {}
                end
                local tbDiamondData = self.tbDiamondDatas[nInstanceId]
                table.insert(tbDiamonds, tbDiamondData)
            end
        end
    end

    return tbDiamonds
end

local function GetSquaredDistance(nX1, nY1, nX2, nY2)
    return (nX1 - nX2)^2 + (nY1 - nY2)^2
end

local function GetNearestDiamondXYZ(nX, nY, tbDiamonds)
    local nNearestDistance = nil
    local nNearestX = nil
    local nNearestY = nil
    local nNearestZ = nil
    for _, v in ipairs(tbDiamonds) do
        --logdebug("GetNearestDiamondXYZ", t2s(v))
        local nDistance = GetSquaredDistance(nX, nY, v.nX, v.nY)
        if not nNearestDistance or nDistance < nNearestDistance then
            nNearestDistance = nDistance
            nNearestX = v.nX
            nNearestY = v.nY
            nNearestZ = v.nZ
        end
    end
    return nNearestX, nNearestY, nNearestZ
end

local function FillBattleItemSystemServer()
    if not BattleItemSystemServer then
        BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    end
end

local function IsDiamond(tbItemTemplate)
    if tbItemTemplate.nId == DIAMOND_TEMPLATE_ID then
        return true
    elseif (tbItemTemplate.nCategory == BattleItemCategoryDef.CONVERTIBLE_ITEM and tbItemTemplate.nConvertItemTemplateId == DIAMOND_TEMPLATE_ID) then
        return true
    end
    return false
end

local function OnSceneItemAdd(self, Item, nX, nY, nZ)
    local tbItemTemplate = Item:GetTemplate()
    if IsDiamond(tbItemTemplate) then
        log("[DiamondContainer]OnSceneItemAdd", Item:GetInstanceId(), Item:GetTemplateId(), nX, nY, nZ)
        self:AddDiamond(Item:GetInstanceId(), nX, nY, nZ)
    end
end

local function OnSceneItemAddDieBox(self, tbItemInstanceIds, nX, nY, nZ)
    for _, v in pairs(tbItemInstanceIds) do
        local Item = BattleItemSystemServer:GetItem(v)
        if Item then
            OnSceneItemAdd(self, Item, nX, nY, nZ)
        end
    end
end

local function OnSceneItemAddBox(self, tbItems, nX, nY, nZ)
    for _, v in pairs(tbItems) do
        OnSceneItemAdd(self, v, nX, nY, nZ)
    end
end

local function OnSceneItemRemove(self, nInstanceId, nItemTemplateId)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if IsDiamond(tbItemTemplate) then
        log("[DiamondContainer]OnSceneItemRemove", nInstanceId, nItemTemplateId)
        self:RemoveDiamond(nInstanceId)
    end
end

local function BindEvent(self)
    EventManager:BindEventMethod(CommonEventDef.EV_SCENE_ITEM_ADD, self, OnSceneItemAdd)
    EventManager:BindEventMethod(CommonEventDef.EV_SCENE_ITEM_ADD_DIE_BOX, self, OnSceneItemAddDieBox)
    EventManager:BindEventMethod(CommonEventDef.EV_SCENE_ITEM_ADD_BOX, self, OnSceneItemAddBox)
    EventManager:BindEventMethod(CommonEventDef.EV_SCENE_ITEM_REMOVE, self, OnSceneItemRemove)
end

local function UnbindEvent(self)
    EventManager:UnBindEventMethod(CommonEventDef.EV_SCENE_ITEM_ADD, self, OnSceneItemAdd)
    EventManager:UnBindEventMethod(CommonEventDef.EV_SCENE_ITEM_ADD_DIE_BOX, self, OnSceneItemAddDieBox)
    EventManager:UnBindEventMethod(CommonEventDef.EV_SCENE_ITEM_ADD_BOX, self, OnSceneItemAddBox)
    EventManager:UnBindEventMethod(CommonEventDef.EV_SCENE_ITEM_REMOVE, self, OnSceneItemRemove)
end

-- local function CheckResult(self, nX, nY, nResultX, nResultY)
--     local nDistance = GetSquaredDistance(nX, nY, nResultX, nResultY)

--     local num = 0
--     for _, v in pairs(self.tbDiamondDatas) do
--         if v.nX ~= nResultX or v.nY ~= nResultY then
--             num = num + 1
--             local nDis = GetSquaredDistance(nX, nY, v.nX, v.nY)
--             if nDis < nDistance then
--                 logerror("error!!!!!!!", t2s(v), nX, nY, nResultX, nResultY)
--             end
--         end
--     end
--     logdebug("ok!", num)
-- end

function DiamondContainer:Init()
    self.tbDiamondDatas = {}
    self.tbDiamondGridDatas = {}
    FillBattleItemSystemServer()
    InitGridDatas(self)
    BindEvent(self)
end

function DiamondContainer:Uninit()
    self.tbDiamondDatas = {}
    self.tbDiamondGridDatas = {}
    UnbindEvent(self)
end

function DiamondContainer:AddDiamond(nInstanceId, nX, nY, nZ)
    local nGridIndex, _, _ = GetGridIndex(self, nX, nY)
    if not IsValidGrid(self, nGridIndex) then
        -- 如果找不到可能是在集合区
        return
    end
    local tbDiamondData = {nX = nX, nY = nY, nZ = nZ, nGridIndex = nGridIndex}
    self.tbDiamondDatas[nInstanceId] = tbDiamondData
    AddToGrid(self, nGridIndex, nInstanceId)
end

function DiamondContainer:RemoveDiamond(nInstanceId)
    local tbDiamondData = self.tbDiamondDatas[nInstanceId]
    if not tbDiamondData then
        return
    end
    local nGridIndex = tbDiamondData.nGridIndex
    if not IsValidGrid(self, nGridIndex) then
        -- 如果找不到可能是在集合区
        return
    end
    DeleteFromGrid(self, nGridIndex, nInstanceId)
    self.tbDiamondDatas[nInstanceId] = nil
end

function DiamondContainer:FindNearbyDiamondXYZ(nX, nY)
    local _, i, j = GetGridIndex(self, nX, nY)

    local nMaxDeltaX = math.max(i, self.nCountX - 1 - i)
    local nMaxDeltaY = math.max(j, self.nCountY - 1 - j)
    local nMaxDelta = math.max(nMaxDeltaX, nMaxDeltaY)
    local tbSameGridDiamonds = GetDiamonds(self, i, j, 0)
    for nDelta = 1, nMaxDelta do
        local tbDiamonds = GetDiamonds(self, i, j, nDelta)
        if nDelta == 1 and tbSameGridDiamonds and #tbSameGridDiamonds > 0 then
            if not tbDiamonds then
                tbDiamonds = {}
            end
            for _, v in pairs(tbSameGridDiamonds) do
                table.insert(tbDiamonds, v)
            end
        end
        if tbDiamonds then
            return true, GetNearestDiamondXYZ(nX, nY, tbDiamonds)
        end
    end

    return false, 0, 0, 0
end

function DiamondContainer:FindPlayerNearbyDiamondXYZ(tbPlayer)
    log("[DiamondContainer]FindPlayerNearbyDiamondXYZ begin")
    local x, y, _ = tbPlayer:GetLocationXYZ()
    local bFound, nNearByX, nNearByY, nNearByZ = self:FindNearbyDiamondXYZ(x, y)
    log("[DiamondContainer]FindPlayerNearbyDiamondXYZ", bFound, nNearByX, nNearByY, nNearByZ)
    -- if bFound then
    --     CheckResult(self, x, y, nNearByX, nNearByY)
    -- end
    return bFound, nNearByX, nNearByY, nNearByZ
end

return DiamondContainer
