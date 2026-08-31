-----------------------------------------------------
--File Name    : UPMapObjForPlayer.lua
--Author       : Ran Jie
--Create Time  : 2017-03-20
--Description  : UPMapObjForPlayer
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPMapObj = require("UPMapObj")
local UPMapObjForPlayer = luaclass("UPMapObjForPlayer", UPMapObj)

-- import require
local WorldMapUtil = require("WorldMapUtil")
local UIResourceDef = require("UIResourceDef")
local TemplateTypeDef = require("TemplateTypeDef")

local pDimension1 = Vector2D{X=35,Y=25}                     -- ship icon
local pDimension2 = Vector2D{X=22,Y=22}                     -- human icon

--member function
function UPMapObjForPlayer:ShowContent(tbData)
    self.bIsInUse = true
    self.tbData = tbData
    self.pWidgetRef.cvsPosPanel:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self.pWidgetRef.hboxCity:SetVisibility(ESlateVisibility.Collapsed)
    
    local szIcon = tbData.szRes
    local pDimension = nil
    local pSlateColor = UIResourceDef.COLOR.WHITE.SLATE_COLOR
    local tbRelation = WorldMapUtil.tbRelation
    local RelationFlag = tbData.RelationFlag
    if RelationFlag == tbRelation.Friend or RelationFlag == tbRelation.Team then
        self.pWidgetRef.Slot:SetZOrder(8)
        pSlateColor = UIResourceDef.COLOR.BLUE1.SLATE_COLOR
    elseif tbData.RelationFlag == tbRelation.Enemy then
        pSlateColor = UIResourceDef.COLOR.PINK.SLATE_COLOR
    else
        self.pWidgetRef.Slot:SetZOrder(8)
    end

    if not tbData.bAutoSize then
        if tbData.nTemplateType == TemplateTypeDef.SHIP then
            pDimension = pDimension1
        else
            pDimension = pDimension2
        end
    end
    
    self:SetIcon(szIcon, pDimension, pSlateColor, tbData.bAutoSize)
    self:SetName(nil)
end

return UPMapObjForPlayer
