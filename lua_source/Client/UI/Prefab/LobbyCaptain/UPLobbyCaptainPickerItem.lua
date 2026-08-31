local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")

local UPLobbyCaptainPickerItem = luaclass("UPLobbyCaptainPickerItem", ListItemBase)

local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local ClientEventDef = require("ClientEventDef")


local GetTextByKey = UISetUtils.GetTextByKey
local TIMEFORMAT = {
    GetTextByKey("COMMON_TIME_DAY"),
    GetTextByKey("COMMON_TIME_HOUR"),
    GetTextByKey("COMMON_TIME_MINUTE"),
    GetTextByKey("COMMON_TIME_SECOND"),
}

local function OnClickedBtnSelect(self)
    self:ToogleSelectItem()
end

function UPLobbyCaptainPickerItem:SelectItem()
    UPLobbyCaptainPickerItem.super.SelectItem(self)
    self.EventHelper:FireEvent(ClientEventDef.EV_LOBBY_CAPTAIN_PICK_ITEM, self.nItemTemplateId)
end

function UPLobbyCaptainPickerItem:UnselectItem()
    UPLobbyCaptainPickerItem.super.UnselectItem(self)
    self.EventHelper:FireEvent(ClientEventDef.EV_LOBBY_CAPTAIN_UNPICK_ITEM, self.nItemTemplateId)
end

function UPLobbyCaptainPickerItem:Display(tbData)
    if not tbData then
        logerror("UPLobbyCaptainPickerItem, tbData is nil")
        return
    end
    self.nItemTemplateId = tbData.nTemplateId
    
    local pWidgetRef = self.pWidgetRef
    -- Display icon
    UISetUtils.SetImageBrushRes(pWidgetRef.imgItem, tbData.szIcon:load())
    pWidgetRef.imgItem:SetVisibility(ESlateVisibility.SelfHitTestInvisible)

    pWidgetRef.txtFirstName:SetText(tbData.l10nFirstName)
    pWidgetRef.txtSecondName:SetText(tbData.l10nSecondName)
    pWidgetRef.txtLastName:SetText(tbData.l10nLastName)
    local nGrade = tbData.nGrade
    pWidgetRef.txtFirstName:SetColorAndOpacity(UIResourceDef.FONT_GRADE_COLOR[nGrade])
    pWidgetRef.txtSecondName:SetColorAndOpacity(UIResourceDef.FONT_GRADE_COLOR[nGrade])
    pWidgetRef.txtLastName:SetColorAndOpacity(UIResourceDef.FONT_GRADE_COLOR[nGrade])
    if tbData.bOwned then
        -- pWidgetRef.txtFirstName:SetIsEnabled(true)
        -- pWidgetRef.txtSecondName:SetIsEnabled(true)
        -- pWidgetRef.txtLastName:SetIsEnabled(true)
        pWidgetRef.imgLock:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.imgItem:SetIsEnabled(true)
        if tbData.nRemainTime then
            pWidgetRef.hboxLimit:SetVisibility(ESlateVisibility.HitTestInvisible)
            -- set remaining time
            pWidgetRef.kmTimerText:SetPrecision(2)
            pWidgetRef.kmTimerText:StartTimer(tbData.nRemainTime, 1, TIMEFORMAT, EMinTimeUnit.Second)
        else
            pWidgetRef.hboxLimit:SetVisibility(ESlateVisibility.Collapsed)
        end
        
        if tbData.bEquiped then
            pWidgetRef.bdrUse:SetVisibility(ESlateVisibility.HitTestInvisible)
        else
            pWidgetRef.bdrUse:SetVisibility(ESlateVisibility.Collapsed)
        end
        
        -- Grade color
        pWidgetRef.imgBg:SetIsEnabled(true)
        local szGradeIcon = UIResourceDef.ITEM_INFO_GRADE_BG_V[tbData.nGrade]
        UISetUtils.SetImageBrushRes(pWidgetRef.imgBg, szGradeIcon:load())
    else
        local szGradeIcon = UIResourceDef.CAPTAIN_ITEM_INFO_DISABLE_BG
        UISetUtils.SetImageBrushRes(pWidgetRef.imgBg, szGradeIcon:load())
        pWidgetRef.bdrUse:SetVisibility(ESlateVisibility.Collapsed)
        -- pWidgetRef.txtFirstName:SetIsEnabled(false)
        -- pWidgetRef.txtSecondName:SetIsEnabled(false)
        -- pWidgetRef.txtLastName:SetIsEnabled(false)
        pWidgetRef.imgItem:SetIsEnabled(false)
        pWidgetRef.imgBg:SetIsEnabled(false)
        pWidgetRef.imgLock:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.hboxLimit:SetVisibility(ESlateVisibility.Collapsed)
    end


    if tbData.bRedDot then
        pWidgetRef.imgTip:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        pWidgetRef.imgTip:SetVisibility(ESlateVisibility.Collapsed)
    end

    if self:IsSelected() then
        pWidgetRef.imgSelect:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        pWidgetRef.imgSelect:SetVisibility(ESlateVisibility.Collapsed)
    end

    -- if tbData.IsSelected then
    --     if not self:IsSelected() then
    --         self:SelectItem()
    --     end
    -- else
    --     if self:IsSelected() then
    --         self:UnselectItem()
    --     end
    -- end
end


function UPLobbyCaptainPickerItem:OnRefresh(tbData)
    self:Display(tbData)
end


-- lifecycle callback

-- function UPLobbyCaptainPickerItem:OnCreate()
-- end

-- function UPLobbyCaptainPickerItem:OnDestroy()
-- end

-- function UPLobbyCaptainPickerItem:OnLoad()
-- end

-- function UPLobbyCaptainPickerItem:OnUnload()
-- end

-- function UPLobbyCaptainPickerItem:OnEnter()
-- end

-- function UPLobbyCaptainPickerItem:OnShow()
-- end

-- function UPLobbyCaptainPickerItem:OnHide()
-- end

-- function UPLobbyCaptainPickerItem:OnExit()
-- end

function UPLobbyCaptainPickerItem:OnBindEvent(EventHelper)
    self.CppDelegate = EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSelect.OnClicked, self, OnClickedBtnSelect)
end

function UPLobbyCaptainPickerItem:OnUnbindEvent(EventHelper)
    EventHelper:UnregisterCppDelegate(self.CppDelegate)
end


return UPLobbyCaptainPickerItem