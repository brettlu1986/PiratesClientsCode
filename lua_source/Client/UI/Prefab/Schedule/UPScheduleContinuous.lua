local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPScheduleContinuous = luaclass("UPScheduleContinuous", PrefabBase)
local ClientEventDef = require("ClientEventDef")
local ScheduleSystem = require("ScheduleSystem")
-- local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local ContinuousDataTable = require("ContinuousDataTable")
local AwardDataTable = require("AwardDataTable")
local ItemDataTable = require("ItemDataTable")
local UIToolTipHelper = require("UIToolTipHelper")
local L10N = require("L10N")
local UITextDef = require("UITextDef")

UPScheduleContinuous.nDay = nil
UPScheduleContinuous.nState = nil

-- local WIDGETS = {
--     "brStateUnGet",
--     "brStateGeted",
--     "brStateGet"
-- }
local BIG_ICON = 2

local ICONS = {
    {
        UNGET = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity10_Normal.Spr_LobbyActivity10_Normal'", 
        GET = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity10_Available.Spr_LobbyActivity10_Available'", 
        GETED = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity10_Received.Spr_LobbyActivity10_Received'",
    },
    {
        UNGET = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity11_Normal.Spr_LobbyActivity11_Normal'", 
        GET = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity11_Available.Spr_LobbyActivity11_Available'", 
        GETED = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity11_Received.Spr_LobbyActivity11_Received'",
    }
}

local BACKGROUNDS = 
{
    GET = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity08_Pressed.Spr_LobbyActivity08_Pressed'", 
    UNGET = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity08_Normal.Spr_LobbyActivity08_Normal'", 
    GETED = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity08_Display.Spr_LobbyActivity08_Display'",
}

local function Refresh(self)
    local Component = ScheduleSystem:GetComponent()
    local tbDatas = Component:GetContinuous()

    local pWidgetRef = self.pWidgetRef

    local nState = -1
    local szState = "UNGET"
    if tbDatas ~= nil then
        local nMaxDay = tbDatas.nDay
        nState = tbDatas.tbState[self.nDay].nState

        if nMaxDay < self.nDay then
            szState = "UNGET"
            nState = 2
        elseif nState > 0 then
            szState = "GETED"
        else
            szState = "GET"
        end         
    end

    local tbTemp = ContinuousDataTable:GetTemplate(self.nDay)
    -- local tbItems = AwardDataTable:GetAwardItem(tbTemp.nAwardId)
    -- if tbItems ~= nil and #tbItems > 0 then
    --     local tbItemResTemplate = ItemDataTable:GetResTemplate(tbItems[1].nItemId)
    --     local szIconPath = tbItemResTemplate.szIconPath
    -- end
    if ICONS[tbTemp.nIconType] ~= nil then
        UISetUtils.SetImageBrushRes(pWidgetRef.imgItem, ICONS[tbTemp.nIconType][szState]:load())
    end
    UISetUtils.SetBorderBrushRes(pWidgetRef.brItem, BACKGROUNDS[szState]:load())

    local fnCollapsedImg = function()
        pWidgetRef.imgSmall01:SetVisibility(ESlateVisibility_Collapsed)
        pWidgetRef.imgBig02:SetVisibility(ESlateVisibility_Collapsed)
        pWidgetRef.parSmallGlow01:SetVisibility(ESlateVisibility_Collapsed)
    end
    if tbTemp.nIconType == BIG_ICON then
        if nState == 0 then
            self:PlayAnimation("animBIG", 0, 0, EUMGSequencePlayMode.Forward, 1)
        else
            self:StopAnimation("animBIG")
            fnCollapsedImg()
            -- pWidgetRef.imgBig:SetVisibility(ESlateVisibility_Collapsed)
        end
    else
        if nState == 0 then
            self:PlayAnimation("animSmall", 0, 0, EUMGSequencePlayMode.Forward, 1)
        else
            self:StopAnimation("animSmall")
            fnCollapsedImg()
            -- pWidgetRef.imgSmall02:SetVisibility(ESlateVisibility_Collapsed)
        end
    end
    self.nState = nState
end

local function OnRefresh(self, nDay)
    if nDay == nil or nDay == self.nDay then
        Refresh(self)
    end
end

local function OnClickGet(self)
    if self.nState == 0 then
        ScheduleSystem:RequestReceiveContinuousAward(self.nDay)
    -- elseif self.nState > 1 then
    --     UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("CONTINUOUS_DAY_NOT_ENOUGH"))
    -- elseif self.nState == 1 or self.nState == - 1 then
    --     UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("CONTINUOUS_AWARD_RECEIVED"))
    end
end

local function OnPressedGet(self)
    local tbTemp = ContinuousDataTable:GetTemplate(self.nDay)
    local tbItems = AwardDataTable:GetAwardItem(tbTemp.nAwardId)
    if tbItems ~= nil and #tbItems > 0 then
        local pGeometry = self.pWidgetRef.btnGet:GetCachedGeometry()
        local pSize = SlateBlueprintLibrary.GetLocalSize(pGeometry)
        local pPosition = SlateBlueprintLibrary.LocalToAbsolute(pGeometry, KismetMathLibrary.MakeVector2D(0, 0))
    
        local tbTipData = {}
        local nItemTemplateId = tbItems[1].nItemId
        local nCount = tbItems[1].nCount
        tbTipData.tbResTemplate = ItemDataTable:GetResTemplate(nItemTemplateId)
        tbTipData.tbTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
        tbTipData.nCount = nCount
        tbTipData.bForceShowCount = true
        UIToolTipHelper:ShowTip(UIToolTipHelper.TipType.ITEM_TIP, tbTipData, pPosition, pSize)
    end
end

local function OnReleasedGet(self)
    UIToolTipHelper:HideTip()
end

function UPScheduleContinuous:Init(nDay)
    self.nDay = nDay
    self.pWidgetRef.txtDay:SetText(L10N:Format(UITextDef.DAY_NUM, nDay))
    Refresh(self)
end

function UPScheduleContinuous:OnLoad()
end

function UPScheduleContinuous:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnGet.OnPressed, self, OnPressedGet)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnGet.OnReleased, self, OnReleasedGet)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnGet.OnClicked, self, OnClickGet)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_CONTINUOUS_REFRESH, self, OnRefresh)
end

return UPScheduleContinuous