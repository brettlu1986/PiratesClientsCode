-----------------------------------------------------
--File Name    : UPMapObjForAINPC.lua
--Author       : Ran Jie
--Create Time  : 2017-03-20
--Description  : UPMapObjForAINPC
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPMapObj = require("UPMapObj")
local UPMapObjForAINPC = luaclass("UPMapObjForAINPC", UPMapObj)

-- import require
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local WorldMapUtil = require("WorldMapUtil")


local pDimension1 = Vector2D{X=42,Y=30}             -- Boss icon
local pDimension2 = Vector2D{X=35,Y=25}             -- ship icon

function UPMapObjForAINPC:ShowContent(tbData)
    self.bIsInUse = true
    self.tbData = tbData
    self.pWidgetRef.cvsPosPanel:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local szIcon = tbData.szRes
    local pDimension = nil
    local pSlateColor = UIResourceDef.COLOR.WHITE.SLATE_COLOR
    local tbRelation = WorldMapUtil.tbRelation
    local RelationFlag = tbData.RelationFlag

    if tbData.bBoss then
        pDimension = pDimension1
        szIcon = UIResourceDef.BOSS_FLAG_BORDER
    elseif not tbData.bAutoSize then
        pDimension = pDimension2
    end

    if RelationFlag == tbRelation.Friend then
        pSlateColor = UIResourceDef.COLOR.BLUE1.SLATE_COLOR
    elseif RelationFlag == tbRelation.Enemy then
        if tbData.bAlerted then
            pSlateColor = UIResourceDef.COLOR.PINK.SLATE_COLOR
        else
            pSlateColor = UIResourceDef.COLOR.YELLOW.SLATE_COLOR
        end
    end

    self:SetIcon(szIcon, pDimension, pSlateColor, tbData.bAutoSize)
    self:SetName(tbData.szName)

    if tbData.UILocation then
        local UIPos = Vector2D{X = tbData.UILocation.X, Y = tbData.UILocation.Y}
        self.pWidgetRef.Slot:SetPosition(UIPos)
    end
end

function UPMapObjForAINPC:SetImageBrushTint(bAlerted)
    local tbData = self.tbData
    if tbData and tbData.RelationFlag == WorldMapUtil.tbRelation.Enemy then
        local pSlateColor = nil
        if bAlerted then
            pSlateColor = UIResourceDef.COLOR.PINK.SLATE_COLOR
        else
            pSlateColor = UIResourceDef.COLOR.YELLOW.SLATE_COLOR
        end
        UISetUtils.SetImageBrushTint(self.pWidgetRef.imgIcon, pSlateColor)
    end
end


return UPMapObjForAINPC

