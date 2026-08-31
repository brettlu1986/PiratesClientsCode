-----------------------------------------------------
--File Name    : UIFFABattleShare.lua
--Description  : FFA战斗结算分享界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIFFABattleShare = luaclass("UIFFABattleShare", WndBase)

local UISetUtils = require("UISetUtils")
local UIUtils = require("UIUtils")


local L10N_SAVE_PICTURE = UISetUtils.GetL10NTextByKey("UICAMERASHOTRESULT_L10N_SAVE_PICTURE")

local function SetInfo(self)
    local pWidgetRef = self.pWidgetRef
    local tbOpenArgs = self.tbOpenArgs
    local pBrush = pWidgetRef.imgShotResult.Brush
    pBrush.ResourceObject = tbOpenArgs.ShotTexture
    local fViewportScale = WidgetLayoutLibrary.GetViewportScale(GWorld)
    fViewportScale = fViewportScale * 1.15
    pBrush.ImageSize = Vector2D{X=tbOpenArgs.Width/fViewportScale, Y=tbOpenArgs.Height/fViewportScale}
    pWidgetRef.imgShotResult:SetBrush(pBrush)

    self:PlayAnimation("animIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
    --EventManager:OnFireEvent(ClientEventDef.EV_SHOT_CAMERA_SHOT_BEFORE_FINISH)
end

local function OnSaveClicked(self)
    ClientShell.GetClient(GWorld):GetCameraShotShell():SaveScreenShot()
    UIUtils.ShowToast(L10N_SAVE_PICTURE, 1)
    self:CloseSelf()
end

local function OnCloseClicked(self)
    self:CloseSelf()
end

function UIFFABattleShare:OnLoad()
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
end

function UIFFABattleShare:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSave.OnClicked, self, OnSaveClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked, self, OnCloseClicked)
end

function UIFFABattleShare:OnEnter()
    SetInfo(self)
end

return UIFFABattleShare