-----------------------------------------------------
--File Name    : UPLobbyMatchmakingMode.lua
--Author       : Ran Jie
--Create Time  : 2020-04-20
-----------------------------------------------------
local luaclass       = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbyMatchmakingMode  = luaclass("UPLobbyMatchmakingMode", ListItemBase)

local UISetUtils = require("UISetUtils")
local DungeonDataTable = require("DungeonDataTable")
local UIResourceDef = require("UIResourceDef")
local AwardDataTable = require("AwardDataTable")
local FirstBattleIni = require("FirstBattleIni")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local ItemDataTable = require("ItemDataTable")
local UIToolTipHelper = require("UIToolTipHelper")
local ClientEventDef = require("ClientEventDef")

UPLobbyMatchmakingMode.tbFirstBattleData = nil

--First Battle
local function RefreshFirstBattleTime(self)
    local pWidgetRef = self.pWidgetRef
    if self.tbData.nDungeonId ~= 100011 then 
        pWidgetRef.btnFirstBattle:SetVisibility(ESlateVisibility_Collapsed)
        return
    end
    pWidgetRef.btnFirstBattle:SetVisibility(ESlateVisibility_Visible)
    if self.tbFirstBattleData == nil then
        self.tbFirstBattleData = {}

        self.tbFirstBattleData.AwardId = FirstBattleIni.nAwardId
    end

    local PlayerSelf = GamePlayerSelfHelper:Get()
    local nBattleTime = 0
	if PlayerSelf and PlayerSelf.LobbyPropertyComponent then
        nBattleTime = PlayerSelf.LobbyPropertyComponent:GetFirstBattleTime()
    end

    self.tbFirstBattleData.BattleTime = nBattleTime
    local now = GlobalVariableSystem:GetServerTimeUtc()

    if now >= nBattleTime then
        self.pWidgetRef.txtFirstBattleTime:SetVisibility(ESlateVisibility.Collapsed)
        -- local pSlateColor = UIResourceDef.COLOR.YELLOW.SLATE_COLOR
        -- UISetUtils.SetImageBrushTint(self.pWidgetRef.imgFirstBattle, pSlateColor)
    else
        self.pWidgetRef.txtFirstBattleTime:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.pWidgetRef.txtFirstBattleTime:SetCountDownEndTime(nBattleTime)
        -- local pSlateColor = UIResourceDef.COLOR.WHITE.SLATE_COLOR
        -- UISetUtils.SetImageBrushTint(self.pWidgetRef.imgFirstBattle, pSlateColor)
    end
end


local function OnFirstBattleCDFinished(self)
    self.pWidgetRef.txtFirstBattleTime:SetVisibility(ESlateVisibility.Collapsed)
    local pSlateColor = UIResourceDef.COLOR.YELLOW.SLATE_COLOR
    UISetUtils.SetImageBrushTint(self.pWidgetRef.imgFirstBattle, pSlateColor)
end

local function OnFirstBattlePressed(self)
    local tbAward = AwardDataTable:GetAwardItem(self.tbFirstBattleData.AwardId)

    local tbTipData = {}
    local nItemTemplateId = tbAward[1].nItemId
    local pWidgetRef = self.pWidgetRef.btnFirstBattle
    local nCount = tbAward[1].nCount
    tbTipData.tbResTemplate = ItemDataTable:GetResTemplate(nItemTemplateId)
    tbTipData.tbTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    tbTipData.nCount = nCount
    tbTipData.bForceShowCount = true
    UIToolTipHelper:ShowTipInAutoLayout(UIToolTipHelper.TipType.ITEM_TIP,tbTipData,pWidgetRef)
end

local function OnFirstBattleReleased(self)
    UIToolTipHelper:HideTip()
end

local function OnSelectClicked(self)
    self:SelectItem()
end

function UPLobbyMatchmakingMode:OnRefresh(tbData)
    local pWidgetRef = self.pWidgetRef
    
    if not tbData then
        pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
        return
    end
    pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    local pResouceObject = nil
    if tbData.bNotOpen then
        pWidgetRef.txtNotOpen:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        pWidgetRef.txtDungeonName:SetVisibility(ESlateVisibility_Collapsed)
        pResouceObject = UIResourceDef.LOBBY_MATCHMAKING_NOT_OPEN_IMG:load()
    else
        local tbDungeonTemplate = DungeonDataTable:GetTemplate(tbData.nDungeonId)
        if tbDungeonTemplate then
            pWidgetRef.txtNotOpen:SetVisibility(ESlateVisibility_Collapsed)
            pWidgetRef.txtDungeonName:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
            pWidgetRef.txtDungeonName:SetText(tbDungeonTemplate.l10nName)
            if tbDungeonTemplate.szUIThumbnail and tbDungeonTemplate.szUIThumbnail ~= "" then
                pResouceObject = tbDungeonTemplate.szUIThumbnail:load()
            else
                logerror("UPLobbyMatchmakingMode:OnRefresh, tbDungeonTemplate.szUIThumbnail is nil", tbData.nDungeonId)
            end
        else
            logerror("UPLobbyMatchmakingMode:OnRefresh, tbDungeonTemplate is nil", tbData.nDungeonId)
        end
    end
    if pResouceObject then
        UISetUtils.SetButtonBrushRes(pWidgetRef.btnSelect, pResouceObject)
    end
    RefreshFirstBattleTime(self)
    if self:IsSelected() then
        pWidgetRef.imgSelect:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    else
        pWidgetRef.imgSelect:SetVisibility(ESlateVisibility_Collapsed)
    end
    if tbData.bNotOpen then
        pWidgetRef.btnSelect:SetVisibility(ESlateVisibility_HitTestInvisible)
    else
        pWidgetRef.btnSelect:SetVisibility(ESlateVisibility_Visible)
    end
end

function UPLobbyMatchmakingMode:OnBindEvent(EventHelper)
    --First Battle
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSelect.OnClicked, self, OnSelectClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnFirstBattle.OnPressed, self, OnFirstBattlePressed)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnFirstBattle.OnReleased, self, OnFirstBattleReleased)
    EventHelper:RegisterCppDelegate(pWidgetRef.txtFirstBattleTime.OnCountDownFinished, self, OnFirstBattleCDFinished)
    EventHelper:RegisterEvent(ClientEventDef.EV_FIRST_BATTLE_REFRESH_TIME, self, RefreshFirstBattleTime)
end

function UPLobbyMatchmakingMode:OnShow()
    self:PlayAnimation("animMatchmaking", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

return UPLobbyMatchmakingMode