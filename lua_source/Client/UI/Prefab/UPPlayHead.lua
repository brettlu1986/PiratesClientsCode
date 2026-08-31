-----------------------------------------------------
--File Name    : UPPlayHead.lua
--Author       : Chang nan
--Create Time  : 2017-07-14
--Description  : 通用玩家头像按钮
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPPlayHead = luaclass("UPPlayHead", PrefabBase)

local UISetUtils = require("UISetUtils")
local HeadIconHelper = require("HeadIconHelper")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local GMOpenModeDef = require("GMOpenModeDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GMIni = require("GMIni")
local UIResourceDef = require("UIResourceDef")

UPPlayHead.nPlayerId = nil
UPPlayHead.tbHeadBtnClicked = nil
UPPlayHead.bUseDefault = true

local function InitPlayerAvatar( self, nAvatarId, nLevel)
    local szImg = HeadIconHelper:GetPlayerHeadIconResByAvatar(nAvatarId)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgHead, szImg:load())
    if nLevel ~= nil then
        self.pWidgetRef.txtLevel:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        self.pWidgetRef.txtLevel:SetText(tostring(nLevel))
    else
        self.pWidgetRef.txtLevel:SetVisibility(ESlateVisibility_Collapsed)
    end
end

local function OnHeadBtnClicked(self)
    if self.bUseDefault then
        if not self.nPlayerId then
            log("UPPlayHead, nPlayerId is nil")
        else
            UIManager:OpenWnd(UIDef.UI_PLAYER_INFO, {nPlayerId = self.nPlayerId})
        end
    else
        local tbHeadBtnClicked = self.tbHeadBtnClicked
        if tbHeadBtnClicked then
            local fnOnClicked = tbHeadBtnClicked[1]
            local tbParams = tbHeadBtnClicked[2]
            fnOnClicked(tbParams)
            return
        end
    end
end

local function OnHeadDoubleClicked(self)
    UIManager:OpenWnd(UIDef.UI_DEBUG_WIDGET)
end

local function OnHeadLongPressed(self)
    UIManager:OpenWnd(UIDef.UI_DEBUG_WIDGET)
end

function UPPlayHead:SetPlayerHead(nAvatarId, nLevel)
    InitPlayerAvatar(self, nAvatarId, nLevel)
end

function UPPlayHead:SetPlayerId(nPlayerId)
    self.nPlayerId = nPlayerId
end

function UPPlayHead:BindHeadBtnOnClicked(fnOnClicked, tbParams)
    self.bUseDefault = false
    self.tbHeadBtnClicked = {fnOnClicked, tbParams}
end

function UPPlayHead:EnableClickHeadDefaultAction(bEnable)
    self.bUseDefault = bEnable
end

function UPPlayHead:SetOfflineAppearance(bOffline)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtLevel:SetIsEnabled(not bOffline)
    pWidgetRef.imgHead:SetColorAndOpacity(bOffline and UIResourceDef.COLOR.GREY.LINEAR_COLOR or UIResourceDef.COLOR.WHITE.LINEAR_COLOR)
end

function UPPlayHead:OnBindEvent(EventHelper)
    local btnSelect = self.pWidgetRef.btnSelect
    EventHelper:RegisterCppDelegate(btnSelect.OnClicked, self, OnHeadBtnClicked)

    btnSelect.bDoubleClickEnabled = false
    btnSelect.bLongPressedEnabled = false
    if GlobalVariableSystem:IsDevMode() then
        local nGMOpenMode = GlobalVariableSystem:GetGMOpenMode()
        if nGMOpenMode == GMOpenModeDef.DOUBLE_CLICK then
            btnSelect.DoubleClickInterval = GMIni.nDoubleClickInterval
            btnSelect.bDoubleClickEnabled = true
            EventHelper:RegisterCppDelegate(btnSelect.OnDoubleClicked, self, OnHeadDoubleClicked)
            log("[UPPlayHead] Enable GM Panel, OpenMode : DoubleClick, DoubleClickInterval =", GMIni.nDoubleClickInterval)
        elseif nGMOpenMode == GMOpenModeDef.LONG_PRESS then
            btnSelect.LongPressedInterval = GMIni.nLongPressedInterval
            btnSelect.bLongPressedEnabled = true
            EventHelper:RegisterCppDelegate(btnSelect.OnLongPressed, self, OnHeadLongPressed)
            log("[UPPlayHead] Enable GM Panel, OpenMode : LongPress, LongPressedInterval =", GMIni.nLongPressedInterval)
        end
    end
end

return UPPlayHead