-----------------------------------------------------
--File Name    : UPWorldMapObj.lua
--Author       : Fenglei
--Create Time  : 2017-05-09
--Description  : UPWorldMapObj
-----------------------------------------------------

local luaclass          = require ("luaclass")
local UPMapObj          = require("UPMapObj")
local UPWorldMapObjNew     = luaclass("UPWorldMapObjNew", UPMapObj)

-- import require
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local UIResourceDef         = require("UIResourceDef")
local UIManager             = require("UIManager")
local UIDef                 = require("UIDef")
local WorldMapUtil          = require("WorldMapUtil")
local KVP                   = require("KVP")
local GameWorldSystem       = require("GameWorldSystem")
local EventManager          = require("EventManager")
local ClientEventDef        = require("ClientEventDef")
local QuestSystem           = require("QuestSystem")
local UIMapIni              = require("UIMapIni")
local PlayerPropertySystem  = require("PlayerPropertySystem")


function UPWorldMapObjNew:OnClickedImgIcon()
    local tbData = self.tbData
    if tbData.bSilent then
        return WidgetBlueprintLibrary.Unhandled()
    end
    local Location = tbData.Location
    if tbData.nTipType == WorldMapUtil.tbMapTipType.NoTip and tbData.nSceneID == GameWorldSystem:GetWorld().nSceneId then
        EventManager:OnFireEvent(ClientEventDef.EV_NAVIGATION_CLICK, Location.X, Location.Y, Location.Z)
    elseif(PlayerPropertySystem:GetPlayerLevel() >= UIMapIni.tbMMap.nNavOtherSceneLv)then
        local nCoordinateX, nCoordinateY = self.Owner:GetDisplayCoordinate(Location)
        tbData.DisplayCoordinateX = nCoordinateX
        tbData.DisplayCoordinateY = nCoordinateY
        UIManager:OpenWnd(UIDef.UI_MAP_TIP, self.tbData)
    end
    
    return WidgetBlueprintLibrary.Handled()
end

--member function
function UPWorldMapObjNew:ShowContent(tbData)
    UPWorldMapObjNew.super.ShowContent(self, tbData)

    self.tbData = tbData
    -- self.pWidgetRef.imgTrade:SetVisibility(ESlateVisibility.Collapsed)
    -- self.pWidgetRef.hboxFlag:SetVisibility(ESlateVisibility.Collapsed)

    if tbData.nTipType == WorldMapUtil.tbMapTipType.AutoCruise_Port then

        -- if TradeSystem:IsShowMapTradeFlag(tbData.nSceneID) then
        --     self.pWidgetRef.imgTrade:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        --     self.pWidgetRef.hboxFlag:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        -- end

        local nCount = 1
        local ImgWidget = nil
        local nSceneID = tbData.nSceneID
        local tbScarceTrade = KVP.ScarceTrade
        local PlayerSelf = GamePlayerSelfHelper:Get()
        local KVPComponent = PlayerSelf.KVPComponent
        local tbGroup = KVPComponent:GetGroup(KVP.GroupId.SCARCE_TRADE)
        if tbGroup and tbGroup[tbScarceTrade.DESTINATION_ID] == nSceneID and tbGroup[tbScarceTrade.IS_ACTIVATE] > 0 then
            ImgWidget = self.pWidgetRef["img" .. nCount]
            ImgWidget:SetVisibility(ESlateVisibility.Visible)
            ImgWidget:LoadTextureResourceByPath(UIResourceDef.EMERGENCY_DELIVERY)

            nCount = nCount + 1
        end

        local FactionComponent = PlayerSelf.FactionComponent
        local WorkshopComponent = PlayerSelf.WorkshopComponent
        local nCurrentFaction = FactionComponent:GetCurrentFactionID()
        nSceneID = GameWorldSystem:GetBigPortSceneIDByFaction(nCurrentFaction)
        if nSceneID ~= -1 and tbData.nSceneID == nSceneID and WorkshopComponent:HasCompletedWorkshop() then
            ImgWidget = self.pWidgetRef["img" .. nCount]
            ImgWidget:SetVisibility(ESlateVisibility.Visible)
            ImgWidget:LoadTextureResourceByPath(UIResourceDef.COMPLETED_WORKSHOP)

            nCount = nCount + 1
        end

        --问号
        local tbCompleteQuest = QuestSystem:GetCanCompleteQuestNpcList(tbData.nSceneID)
        if #tbCompleteQuest > 0  then
            ImgWidget = self.pWidgetRef["img" .. nCount]
            ImgWidget:SetVisibility(ESlateVisibility.Visible)
            ImgWidget:LoadTextureResourceByPath(UIResourceDef.QUEST_POINT_TAG_UNFINISHED)
            nCount = nCount + 1
        else
            --叹号
            local tbAcceptQuest = QuestSystem:GetCanAcceptQuestNpcList(tbData.nSceneID)
            if #tbAcceptQuest > 0 then
                ImgWidget = self.pWidgetRef["img" .. nCount]
                ImgWidget:SetVisibility(ESlateVisibility.Visible)
                ImgWidget:LoadTextureResourceByPath(UIResourceDef.QUEST_POINT_TAG_FINISHED)
                nCount = nCount + 1
            end 
        end

        -- if nCount > 1 then
        --     self.pWidgetRef.hboxFlag:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        -- end
    elseif tbData.nTipType == WorldMapUtil.tbMapTipType.AutoCruise_TransferPoint then
        self.pWidgetRef.hboxCity:SetVisibility(ESlateVisibility.Collapsed)
    end
    -- local Helper = self.EventHelper
    -- Helper:RegisterCppDelegate(self.pWidgetRef.imgIcon.OnMouseButtonDownEvent, self, self.OnClickedImgIcon)
end


return UPWorldMapObjNew

