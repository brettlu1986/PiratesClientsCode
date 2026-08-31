local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPScheduleNoobLogin2 = luaclass("UPScheduleNoobLogin2", ListItemBase)
local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local ScheduleSystem = require("ScheduleSystem")
local NoobLoginDataTable = require("NoobLoginDataTable")
local AwardDataTable = require("AwardDataTable")
local ItemDataTable = require("ItemDataTable")
local UIResourceDef = require("UIResourceDef")

UPScheduleNoobLogin2.pItem = nil
UPScheduleNoobLogin2.tbData = nil

local NOOBLOGINSTATE = {
    UNREACH = -1,
    UNGET = 0,
    GETED = 1
}

-- local UNGET_COLOR = KMUMGLibrary.GetLinearColorFromHex("C09064FF")
-- local GETED_COLOR = KMUMGLibrary.GetLinearColorFromHex("000000FF")

local function OnClickGet(self)
    local tbData = self.tbData
    if tbData.nState == NOOBLOGINSTATE.UNGET then
        ScheduleSystem:RequestGetNoobLoginAward(tbData.nDay)
    elseif tbData.nState == NOOBLOGINSTATE.GETED then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOGIN_AWARD_GETED"))
    else
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOGIN_AWARD_NOT_REACH"))
    end
end

local function OnClickAwardGet(self)
    local tbData = self.tbData
    if tbData.nState == NOOBLOGINSTATE.UNGET then
        ScheduleSystem:RequestGetNoobLoginAward(tbData.nDay)
    end
end

local function RefreshDay(self, nDay)
    local pWidgetRef = self.pWidgetRef
    
    -- local szDay = string.format('<text color=\"#FFFF00FF\">%d</>', nDay)
    -- pWidgetRef.txtDay:SetText(L10N:Format(UITextDef.DAY_NUM, szDay))
    pWidgetRef.txtDay:SetText(nDay)

    -- local Component = ScheduleSystem:GetComponent()
    -- local tbNoobLogin = Component:GetNoobLogin()
    -- local nMaxDay = NoobLoginDataTable:GetCount()
    -- if tbNoobLogin ~= nil then
    --     nMaxDay = #tbNoobLogin
    -- end
    -- pWidgetRef.olSelect:SetVisibility(nDay == nMaxDay and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Hidden)    
end

function UPScheduleNoobLogin2:OnRefresh(tbData)
    self.tbData = tbData
    local Collapsed, SelfHitTestInvisible, Visible = 
        ESlateVisibility_Collapsed, ESlateVisibility_SelfHitTestInvisible, ESlateVisibility_Visible
    local pWidgetRef = self.pWidgetRef
    if tbData.nState == NOOBLOGINSTATE.UNGET then
        -- pWidgetRef.imgBg:SetColorAndOpacity(UNGET_COLOR)
        pWidgetRef.imgBlack:SetVisibility(Collapsed)
        pWidgetRef.imgSelect:SetVisibility(SelfHitTestInvisible)
        pWidgetRef.btnGet:SetVisibility(Visible)
        pWidgetRef.imgGet:SetVisibility(Collapsed)
        pWidgetRef.imgUnGet:SetVisibility(SelfHitTestInvisible)
        self:PlayAnimation("anim_GetLoop", 0, 0, EUMGSequencePlayMode.Forward, 1)        
    elseif tbData.nState == NOOBLOGINSTATE.GETED then
        -- pWidgetRef.imgBg:SetColorAndOpacity(GETED_COLOR)
        pWidgetRef.imgBlack:SetVisibility(SelfHitTestInvisible)
        pWidgetRef.imgSelect:SetVisibility(Collapsed)
        pWidgetRef.btnGet:SetVisibility(Collapsed)
        pWidgetRef.imgGet:SetVisibility(SelfHitTestInvisible)
        pWidgetRef.imgUnGet:SetVisibility(Collapsed)
        self:StopAnimation("anim_GetLoop")        
    else
        -- pWidgetRef.imgBg:SetColorAndOpacity(GETED_COLOR)
        pWidgetRef.imgBlack:SetVisibility(Collapsed)
        pWidgetRef.imgSelect:SetVisibility(Collapsed)
        pWidgetRef.btnGet:SetVisibility(Collapsed)
        pWidgetRef.imgGet:SetVisibility(Collapsed)
        pWidgetRef.imgUnGet:SetVisibility(Collapsed)
        self:StopAnimation("anim_GetLoop")        
    end
    RefreshDay(self, tbData.nDay)

    local tbTemplate = NoobLoginDataTable:GetTemplate(tbData.nDay)
    if tbTemplate == nil then
        logwarning("UPScheduleNoobLogin2:OnRefresh not nooblogin data ", tbData.nDay)
        return
    end
    local tbAwards = AwardDataTable:GetAwardItem(tbTemplate.nAwardId)
    if tbAwards == nil or #tbAwards == 0 then
        logwarning("UPScheduleNoobLogin2:OnRefresh not award", tbTemplate.nAwardId)
        return
    end
    local tbItemTemplate = ItemDataTable:GetTemplate(tbAwards[1].nItemId) 
    if tbItemTemplate == nil then
        logwarning("UPScheduleNoobLogin2:OnRefresh not find item", tbAwards[1].nItemId)
        pWidgetRef.txtName:SetText("")
    else
        pWidgetRef.txtName:SetText(tbItemTemplate.l10nName)
        self.pItem:SetDisplayItemData(tbAwards[1].nItemId, tbAwards[1].nCount, true)
        local szGradeIcon = UIResourceDef.SCHEDULE_ITEM_COLOR_GRADE_BG[tbItemTemplate.nGrade]
        UISetUtils.SetImageBrushRes(self.pItem.pWidgetRef.imgPackItemBg, szGradeIcon:load())
    end
end

function UPScheduleNoobLogin2:OnLoad()
    self.pItem = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyItem, UIDef.UP_LOBBY_DISPLAY_ITEM)
end

function UPScheduleNoobLogin2:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnGet.OnClicked, self, OnClickGet)
    EventHelper:RegisterCppDelegate(pWidgetRef.pbLobbyItem.btnItem.OnClicked, self, OnClickAwardGet)
end

return UPScheduleNoobLogin2