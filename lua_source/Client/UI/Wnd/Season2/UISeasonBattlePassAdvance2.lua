-----------------------------------------------------
--File Name    : UISeasonBattlePassAdvance2.lua
--Description  : 赛季通行证界面进阶界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UISeasonBattlePassAdvance2 = luaclass("UISeasonBattlePassAdvance2", WndBase)
local SeasonSystem = require("SeasonSystem")
local SeasonDataTable = require("SeasonDataTable")
local ItemSystem = require("ItemSystem")
local ItemDataTable = require("ItemDataTable")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local TimeUtil = require("TimeUtil")
local UIDef = require("UIDef")
local BattlePassRewardDataTable = require("BattlePassRewardDataTable")
local UIUtils = require("UIUtils")

UISeasonBattlePassAdvance2.tbSeasonData = nil

local COL_COUNT = 2

local function CreateAwardWidgetRef(self, szIcon, l10nDesc, nIndex)
    local pbAward = self.PrefabHelper:CreatePrefab(UIDef.UP_SEASON_BATTLE_PASS_AWARD)
    local pGridSlot = self.pWidgetRef.gpAwards:AddChildToGrid(pbAward.pWidgetRef, 0, 0)
    local nRow, nColumn = math.floor(nIndex / COL_COUNT), nIndex % COL_COUNT
    pGridSlot:SetRow(nRow)
    pGridSlot:SetColumn(nColumn)
    pbAward:OnRefresh(szIcon, l10nDesc)
end

local function CreateAwardGrid(self, nTier)
    local tbDatas = BattlePassRewardDataTable:GetContainer()
    local nCount = 0

    for i, v in ipairs(tbDatas) do
        CreateAwardWidgetRef(self, v.szRewardIcon, v.l10nDesc, nCount)
        nCount = nCount + 1
    end
end

local function RefreshUI(self)
    local Component = SeasonSystem:GetComponent()
    local nSeasonId = Component:GetSeasonId()
    local tbSeasonData = SeasonDataTable:GetTemplate(nSeasonId)
    if tbSeasonData == nil then
        logerror("UISeasonBattlePassAdvance2 invalid season ", nSeasonId)
        return
    end
    local pWidgetRef = self.pWidgetRef

    -- name
    pWidgetRef.txtName:SetText(tbSeasonData.l10nName)
    -- time
    local nSeasonStartTime = Component:GetStartTime()
    local nSeasonEndTime = tbSeasonData.nDurationDay *24 * 60 * 60 + nSeasonStartTime
    local nStartYear = tonumber(os.date("%Y", nSeasonStartTime))
    local nEndYear = tonumber(os.date("%Y", nSeasonEndTime))
    local szTimeFormat = L10N:ToString(UISetUtils.GetL10NTextByKey("L10N_YMDTIME_FORMAT1"))
    local szStartTime = TimeUtil.GetTimeFormatString(nSeasonStartTime, szTimeFormat)
    local szEndTime = ""
    if nEndYear ~= nStartYear then
        szEndTime = TimeUtil.GetTimeFormatString(nSeasonEndTime, szTimeFormat)
    else
        szEndTime = os.date("%m", nSeasonEndTime)
    end
    local l10nTime = L10N:Format(UISetUtils.GetL10NTextByKey("YMDTIME_TO_YMDTIME"), szStartTime, szEndTime)
    l10nTime = L10N:Format(UISetUtils.GetL10NTextByKey("UI_SEASON_TIME"), l10nTime)
    pWidgetRef.txtTime:SetText(l10nTime)
    -- cost
    local tbItemData = ItemSystem:GetItemTemplate(tbSeasonData.nCurrencyId)
    if tbItemData ~= nil then
        local tbItemResTemplate = ItemDataTable:GetResTemplate(tbSeasonData.nCurrencyId)
        local szIconPath = tbItemResTemplate.szIconPath

        UISetUtils.SetImageBrushRes(pWidgetRef.imgCostMoney, szIconPath:load())
    end
    pWidgetRef.txtNeedCost:SetText(tbSeasonData.nCurrencyCost)
    -- award
    local tbBattlePass = Component:GetBattlePass()
    CreateAwardGrid(self, tbBattlePass.battle_tier)

    self.tbSeasonData = tbSeasonData
end

local function OnClickedBuy(self)
    SeasonSystem:RequestBuyBattlePass()
end

local function OnClickedClose(self)
    self:CloseSelf()
end
-------------------------------------------------------------------------------------------------------

function UISeasonBattlePassAdvance2:OnLoad()
end

function UISeasonBattlePassAdvance2:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnBuy.OnClicked,  self, OnClickedBuy)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClose.OnClicked,  self, OnClickedClose)
end

function UISeasonBattlePassAdvance2:OnShow()
    UIUtils.BottomMenuHide(true)

    self:PlayAnimation("anim_SeasonBattlePassAdvanceIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
    RefreshUI(self)
end

function UISeasonBattlePassAdvance2:OnHide()
    UIUtils.BottomMenuHide(false)
end

function UISeasonBattlePassAdvance2:OnDestroy()
    self.tbSeasonData = nil
end

return UISeasonBattlePassAdvance2