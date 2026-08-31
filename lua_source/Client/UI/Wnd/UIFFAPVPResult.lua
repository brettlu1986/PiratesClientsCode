-----------------------------------------------------
--File Name    : UIFFAPVPResult.lua
--Description  : FFA非吃雞战斗结算主界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIFFAPVPResult = luaclass("UIFFAPVPResult", WndBase)

local UISetUtils = require("UISetUtils")

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleResultDef = require("BattleResultDef")

local BACK_WAIT_TIME = 100

local function SetInfo(self)
    local tbInfo = self.tbOpenArgs
    if not tbInfo then
        return
    end
    local pWidgetRef = self.pWidgetRef
    if tbInfo.nRank == BattleResultDef.LOSE then
        local UE_Fail_01 = self.pWidgetRef.UE_Fail_01
        UE_Fail_01:SetVisibility(ESlateVisibility.HitTestInvisible)
        UE_Fail_01:PlayAnimation(UE_Fail_01.Anima_Fail, 0, 1, EUMGSequencePlayMode.Forward, 1)
    else
        local UE_Win_01 = self.pWidgetRef.UE_Win_01
        UE_Win_01:SetVisibility(ESlateVisibility.HitTestInvisible)
        UE_Win_01:PlayAnimation(UE_Win_01.Anima_Win, 0, 1, EUMGSequencePlayMode.Forward, 1)
    end
    local l10Back = UISetUtils.GetL10NTextByKey("FFA_RESULT_BUTTON_BACK")
    pWidgetRef.cdtxtBack:SetTimerStart(l10Back, false, GlobalVariableSystem:GetLocalTime() + BACK_WAIT_TIME)
end

local function OnBackClicked(self)
    BattleGameModeSystem:RequestQuitDungeon(BattleGameModeSystem.QUIT_REASON.QUIT_BUTTON)
end

function UIFFAPVPResult:OnLoad()
    self.pWidgetRef.bTopWindow = false
end

function UIFFAPVPResult:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBack.OnClicked, self, OnBackClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.cdtxtBack.OnCountDownFinished, self, OnBackClicked)
end

function UIFFAPVPResult:OnShow()
    SetInfo(self)
end

return UIFFAPVPResult