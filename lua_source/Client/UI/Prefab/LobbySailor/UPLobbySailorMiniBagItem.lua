
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbySailorMiniBagItem = luaclass("UPLobbySailorMiniBagItem", ListItemBase)

local LobbySailorHelper = require("LobbySailorHelper")
local UIResourceDef = require("UIResourceDef")
local ClientEventDef = require("ClientEventDef")
local LobbyItemUiHelper = require("LobbyItemUiHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local szValueColor = "86cc08ff"

local function GetSailorComponent()
    return GamePlayerSelfHelper:Get().SailorComponent
end

local function OnClickedListItem(self)
    if not self:IsSelected() then
        self:SelectItem()
        -- self:PlayAnimation("animSelected", 0 , 1, EUMGSequencePlayMode.Forward, 1)
    end

    if self.tbData.bCanLevelUp or  self.tbData.bCanReset then  
        self.EventHelper:FireEvent(ClientEventDef.EV_LOBBYSAILOR_LEVELUP_SAILOR, self.tbData)
    end
end

-- local function OnClickedLvUp(self)
--     self.EventHelper:FireEvent(ClientEventDef.EV_LOBBYSAILOR_LEVELUP_SAILOR, self.tbData)
-- end

function UPLobbySailorMiniBagItem:OnRefresh(tbData)
    local tbTemplate = tbData.tbTemplate
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtName:SetText(tbTemplate.l10nName)
    LobbySailorHelper.RefreshSailorItemResState(pWidgetRef.imgIcon, pWidgetRef.imgPattern, true, tbData.nSailorId)
    -- UISetUtils.SetImageBrushRes(self.pWidgetRef.imgGrade, UIResourceDef.SAILOR_GRADE_ICONS[tbTemplate.nGrade + 1]:load())

    LobbyItemUiHelper.SetGradeHalfColorImage(UIResourceDef.SAILOR_GRADE_HALFBG, pWidgetRef, tbTemplate.nGrade)
    if tbData.bCanLevelUp then 
        pWidgetRef.hbLevelUp:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.txtCount:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.btnLvUp:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.textReset:SetVisibility(ESlateVisibility.Collapsed)
        self:PlayAnimation("animLevelUpFx", 0 , 0, EUMGSequencePlayMode.Forward, 1)
    elseif tbData.bCanReset then  
        pWidgetRef.hbLevelUp:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtCount:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.btnLvUp:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.textReset:SetVisibility(ESlateVisibility.HitTestInvisible)
        self:StopAnimation("animLevelUpFx")
    else  
        pWidgetRef.hbLevelUp:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtCount:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.btnLvUp:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.textReset:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtCount:SetText("x"..tbData.nCount)
        self:StopAnimation("animLevelUpFx")
    end
    if self:IsSelected() then
        pWidgetRef.imgSelect:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        pWidgetRef.imgSelect:SetVisibility(ESlateVisibility.Collapsed)
    end

    local szIntroduce = GetSailorComponent():GetSailorIntroduceWithColor(tbData.nSailorId, szValueColor)
    self.pWidgetRef.txtProperties:SetText(szIntroduce)
end

function UPLobbySailorMiniBagItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnListItem.OnClicked, self, OnClickedListItem)
    -- EventHelper:RegisterCppDelegate(self.pWidgetRef.btnLvUp.OnClicked, self, OnClickedLvUp)

end

return UPLobbySailorMiniBagItem