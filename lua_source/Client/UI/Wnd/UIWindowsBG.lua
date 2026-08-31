-----------------------------------------------------
--File Name    : UIWindowsBG.lua
--Author       : Song Fuhao
--Create Time  : 2018-1-25
--Description  : 背景虚化窗口
-----------------------------------------------------

local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIWindowsBG = luaclass("UIWindowsBG", WndBase)

local UIDef = require("UIDef")
local UIManager = require("UIManager")
local UISetUtils = require("UISetUtils")
local WidgetAnimationHandle = require("WidgetAnimationHandle")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local BP_BG_BLUR_PATH = '/Game/UI/RenderTarget/BP_BlurBGActor.BP_BlurBGActor_C'

UIWindowsBG.pBlurBGActor = nil

local function OnAnimationFinished(self)
    local pWidgetRef = self.pWidgetRef
    if pWidgetRef:IsAnimationPlayingForward(pWidgetRef.animFadeIn) then
        KMUMGLibrary.SwitchRendering(false)
    else
        self:HideFinished()
    end
end

local function SetMainWndVisible(self, bVisible)
    local tbWnd = nil
    if GlobalVariableSystem:IsInDungeon() then
        tbWnd = UIManager:GetWnd(UIDef.UI_BATTLE_MAIN)
    else
        tbWnd = UIManager:GetWnd(UIDef.UI_MAIN)
    end
    if tbWnd then
        tbWnd:SetMainWndVisible(self, bVisible)
    end
end

function UIWindowsBG:OnLoad()
    self.pBlurBGActor = EngineExtActorShell.SpawnActorForScript(GWorld,BP_BG_BLUR_PATH:load(), Transform(), nil)
end

function UIWindowsBG:OnUnload()
    if isvalidhandle(self.pBlurBGActor) then
        self.pBlurBGActor:K2_DestroyActor()
    end
end

function UIWindowsBG:OnShow()
    if isvalidhandle(self.pBlurBGActor) then
        SetMainWndVisible(self, false)
        local pBlurredBG = self.pBlurBGActor:GetBlurredBG()
        UISetUtils.SetImageBrushRes(self.pWidgetRef.imgBG, pBlurredBG)
        self:PlayAnimation("animFadeIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
    end
end

function UIWindowsBG:OnHide()
    SetMainWndVisible(self, true)
    KMUMGLibrary.SwitchRendering(true)
    self:PlayAnimation("animFadeIn", 0, 1, EUMGSequencePlayMode.Reverse, 1)
    return false
end

function UIWindowsBG:OnBindEvent(EventHelper)
    EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(self.pWidgetRef, self.pWidgetRef.animFadeIn, OnAnimationFinished, self))
end

return UIWindowsBG
