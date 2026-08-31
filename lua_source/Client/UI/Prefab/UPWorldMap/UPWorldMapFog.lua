-----------------------------------------------------
--File Name    : UPWorldMapFog.lua
--Author       : Ran Jie
--Create Time  : 2016-12-9
--Description  : 新版世界地图迷雾prefab
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPWorldMapFog = luaclass("UPWorldMapFog", PrefabBase)

-- import require
local WorldMapSystem = require("WorldMapSystem")
local ClientEventDef = require("ClientEventDef")
local OceanFogTable = require("OceanFogTable")
local OceanFogIni = require("OceanFogIni")

--local veraible
local DEBUG_TEST = true
local EnableNewFog = true

--member veriable
UPWorldMapFog.UIGridSize = nil
UPWorldMapFog.FogGridCount = nil



function UPWorldMapFog:OnLoad()
    
    
end

function UPWorldMapFog:OnShow()
    local pMap = self.pWidgetRef.kmfogMap
    if(not WorldMapSystem:IsFogActive())then
        pMap:SetVisibility(ESlateVisibility.Collapsed)
        return
    end
    local nFogGridCountX, nFogGridCountY = WorldMapSystem:GetFogGridCount()
    self.FogGridCountX = nFogGridCountX
    self.FogGridCountY = nFogGridCountY
    log("UPWorldMapFog:OnShow", nFogGridCountX, nFogGridCountY)

    if(EnableNewFog) then
        pMap:SetInfo(nFogGridCountX, nFogGridCountY)
    else
        pMap:EnableNewFogMap(false)
        pMap:SetGridCount(nFogGridCountX, nFogGridCountY)
    end   
    
    pMap:SetVisibility(ESlateVisibility.Visible)    
    --logwarning("OnShow self.FogGridCount,x="..tostring(self.FogGridCount.X).." Y="..self.FogGridCount.Y)
    
    if(DEBUG_TEST)then
        local gridcount = OceanFogTable:GetRegionCount()
        for i = 0, gridcount do
            self:OnUnlockFog(i)
        end
    else
        self:ShowFog()
    end
    
end

function UPWorldMapFog:OnBindEvent()
    self.EventHelper:RegisterEvent(ClientEventDef.EV_OCEAN_FOG_UNLOCK, self, self.OnUnlockFog)
end

function UPWorldMapFog:OnHide()
    
end

--public interface
function UPWorldMapFog:InitFog(tbMapResData)
    self.tbMapResData = tbMapResData
end

function UPWorldMapFog:ShowFog()
    local tbRegion = WorldMapSystem:GetFogRegions()
    for k, v in pairs(tbRegion)do
        if(v == true)then
            self:OnUnlockFog(k)
        end
    end
end

function UPWorldMapFog:OnUnlockFog(nRegionId)
    local TempList = OceanFogTable:GetTemplateList(nRegionId)
    if(TempList == nil)then
        logwarning("UPWorldMapFog:UnLockRegion,nRegionId="..tostring(nRegionId))
        return
    end
    log("OnUnlockFog", nRegionId)

    local pMap = self.pWidgetRef.kmfogMap

    --logwarning("UPWorldMapFog:UpdateFogState,nRegionId="..tostring(nRegionId))
    if(EnableNewFog) then
        if(#TempList == 1)then
            -- 没有格子的情况下的特殊处理
            local CurGrid = TempList[1]
            local nX = CurGrid.nGridX
            local nY = CurGrid.nGridY
            pMap:ActivateGrid(nX - 1, nY - 1)
            --logdebug("ActivateGrid1", nX-1, nY-1)
            pMap:ActivateGrid(nX, nY - 1)
            --logdebug("ActivateGrid1", nX, nY-1)
            pMap:ActivateGrid(nX - 1, nY)
            --logdebug("ActivateGrid1", nX-1, nY)
            pMap:ActivateGrid(nX, nY)
            --logdebug("ActivateGrid1", nX, nY)        
        else
            for k, v in pairs(TempList) do
                pMap:ActivateGrid(v.nGridX, v.nGridY)
                --logdebug("ActivateGrid2", v.nGridX, v.nGridY)
            end
        end
    else
        if(#TempList == 1)then
            local CurGrid = TempList[1]
            local tbGrid = {{nGridX = CurGrid.nGridX-1,nGridY = CurGrid.nGridY - 1},
                            {nGridX = CurGrid.nGridX,nGridY = CurGrid.nGridY - 1},
                            {nGridX = CurGrid.nGridX-1,nGridY = CurGrid.nGridY},
                            {nGridX = CurGrid.nGridX,nGridY = CurGrid.nGridY},
            }
            for k, v in pairs(tbGrid)do
                self.pWidgetRef.kmfogMap:SetGridValue(math.tointeger(v.nGridY * self.FogGridCountX + v.nGridX), 3, 4)          --当前区块的右下
                self.pWidgetRef.kmfogMap:SetGridValue(math.tointeger(v.nGridY*self.FogGridCountX + v.nGridX + 1), 1, 8)        --右边区块的左下
                self.pWidgetRef.kmfogMap:SetGridValue(math.tointeger((v.nGridY + 1) * self.FogGridCountX + v.nGridX), 2, 1)      --下面区块的右上
                self.pWidgetRef.kmfogMap:SetGridValue(math.tointeger((v.nGridY + 1) * self.FogGridCountX + v.nGridX + 1), 0, 2)    --下面右边区块的左上
            end
        else
            for k, v in pairs(TempList) do
                --logwarning("gridindex="..tostring(v.nGridY*self.FogGridCount.X + v.nGridX).." v.nGridY="..tostring(v.nGridY).." v.nGridX="..tostring(v.nGridX).." self.FogGridCount.X="..tostring(self.FogGridCount.X))
                self.pWidgetRef.kmfogMap:SetGridValue(math.tointeger(v.nGridY * self.FogGridCountX + v.nGridX), 3, 4)          --当前区块的右下
                self.pWidgetRef.kmfogMap:SetGridValue(math.tointeger(v.nGridY * self.FogGridCountX + v.nGridX+1), 1, 8)        --右边区块的左下
                self.pWidgetRef.kmfogMap:SetGridValue(math.tointeger((v.nGridY + 1) * self.FogGridCountX + v.nGridX), 2, 1)      --下面区块的右上
                self.pWidgetRef.kmfogMap:SetGridValue(math.tointeger((v.nGridY + 1) * self.FogGridCountX + v.nGridX+1), 0, 2)    --下面右边区块的左上
            end
        end
    end
end


function UPWorldMapFog:UpdateFogSize(FogSize)
    --logdebug("self.FogGridCount="..tostring(self.FogGridCount))
    if(self.FogGridCountX == nil)then 
        self.FogGridCountX, self.FogGridCountY = WorldMapSystem:GetFogGridCount()
    end    
    
    self.UIGridSizeX = (OceanFogIni.nUIGridWidth / self.tbMapResData.nUIMapSizeX) * FogSize.X
    self.UIGridSizeY = (OceanFogIni.nUIGridHeight / self.tbMapResData.nUIMapSizeY) * FogSize.Y

    -- self.UIGridSize.X = math.floor(FogSize.X/self.FogGridCount.X)
    -- self.UIGridSize.Y = math.floor(FogSize.Y/self.FogGridCount.Y)
    self.pWidgetRef.kmfogMap:SetGridSize(self.UIGridSizeX, self.UIGridSizeY)
    self.pWidgetRef.kmfogMap.Slot:SetSize(Vector2D{X = FogSize.X, Y = FogSize.Y} )
    
    --logdebug("self.UIGridSize,x="..self.UIGridSize.X.." Y="..self.UIGridSize.Y.." FogSize,X="..FogSize.X.." Y="..FogSize.Y)
end

return UPWorldMapFog
