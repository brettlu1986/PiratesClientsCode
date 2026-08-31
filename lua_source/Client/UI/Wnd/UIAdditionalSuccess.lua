-----------------------------------------------------
--File Name    : UIAdditionalSuccess.lua
--Description  : 额外胜利选择界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIAdditionalSuccess = luaclass("UIAdditionalSuccess", WndBase)

local Timer = require("Timer")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonCommonProtoNames")
local WidgetAnimationHandle = require("WidgetAnimationHandle")
--local UISetUtils = require("UISetUtils")
--local NpcHeadIconRes = require("NpcHeadIconRes")

UIAdditionalSuccess.nCDTime   = 0
UIAdditionalSuccess.nSumTime  = 0
UIAdditionalSuccess.tbRefreshTimer = nil
UIAdditionalSuccess.AnimDelegate = nil
UIAdditionalSuccess.pbMainTips = nil
UIAdditionalSuccess.bDialogIngoreEvent = true
UIAdditionalSuccess.bExiting = nil

--local nICON_ID = 1000

local function DestroyTimer(self)
    if self.tbRefreshTimer then
        self.tbRefreshTimer:Clear()
        self.tbRefreshTimer = nil
    end    
end

local function HideDialog(self)
    if self.bExiting then
        return
    else
        self.bExiting = true
    end

    DestroyTimer(self)
    local pValidWidgetRef = self.pWidgetRef.pbMainTips
    local OnAnimationComplete = function()
        if self.AnimDelegate then
            self.EventHelper:UnRegisterHandle(self.AnimDelegate)
            self.AnimDelegate = nil
            self:CloseSelf()
        end
    end

    pValidWidgetRef:PlayAnimation(pValidWidgetRef.animMisson, 0, 1, EUMGSequencePlayMode.Reverse, 1)

    self.AnimDelegate = self.EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(pValidWidgetRef, pValidWidgetRef.animMisson, OnAnimationComplete))
end

local function OnClickFighting(self)
    HideDialog(self)

    local tbPacket = {
        nASResult = Proto.c2d_AdditionalSuccessChoice_EASResultType.FIGHTING,
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_AdditionalSuccessChoice, tbPacket)
end

local function OnClickExit(self)
    HideDialog(self)

    local tbPacket = {
        nASResult = Proto.c2d_AdditionalSuccessChoice_EASResultType.EXIST_BATTLE,
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_AdditionalSuccessChoice, tbPacket)
end

local function OnTick(self)
    self.nSumTime = self.nSumTime + 1
    local pValidWidgetRef = self.pWidgetRef.pbMainTips

    local nTime = self.nCDTime - self.nSumTime
    if nTime < 0 then
        nTime = 0
    end
    pValidWidgetRef.KMTimerTextBlock_0:SetText(nTime)
    
    if self.nSumTime >= self.nCDTime then
        HideDialog(self)
    end
end

local function ShowDialog(self, tbPacket)
    self.bExiting = false
    DestroyTimer(self)
    local pValidWidgetRef = self.pWidgetRef.pbMainTips
    pValidWidgetRef.KMTimerTextBlock_0:SetText(tbPacket.nCDTime)

   -- local tbIconRes = NpcHeadIconRes:GetTemplate(nICON_ID)
    --UISetUtils.SetImageBrushRes(pValidWidgetRef.imgBiginHead, tbIconRes.szHeadIcon:load())
    pValidWidgetRef:PlayAnimation(pValidWidgetRef.animMisson, 0, 1, EUMGSequencePlayMode.Forward, 1)
    self.nCDTime = tbPacket.nCDTime
    self.nSumTime = 0
    
    if self.tbRefreshTimer == nil then 
        self.tbRefreshTimer = Timer.NewTimerMethod(self, OnTick, 1 , true)
    end
end

function UIAdditionalSuccess:OnLoad()
    self.pbMainTips = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbMainTips)
end

function UIAdditionalSuccess:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.pbMainTips.btnSummon1.OnClicked, self, OnClickFighting)
    EventHelper:RegisterCppDelegate(pWidgetRef.pbMainTips.btnSummon10.OnClicked, self, OnClickExit)
end

function UIAdditionalSuccess:OnShow()
    ShowDialog(self,self.tbOpenArgs)
end

function UIAdditionalSuccess:OnExit()
    HideDialog(self)
end

return UIAdditionalSuccess