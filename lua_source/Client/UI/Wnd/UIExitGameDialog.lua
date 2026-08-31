-----------------------------------------------------
--File Name    : UIExitGameDialog.lua
--Description  : 退出游戏对话框
-----------------------------------------------------

local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIExitGameDialog = luaclass("UIExitGameDialog", WndBase)

UIExitGameDialog.pbDialogFrame = nil

local function OnClickedPositiveButton(self)
    KismetSystemLibrary.QuitGame(GWorld, nil, EQuitPreference.Quit)
end

local function OnDialogCloseAnimEnd(self)
    self:CloseSelf()
end

function UIExitGameDialog:OnLoad()
    self.pbDialogFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbDialogFrame)
    self.pbDialogFrame:SetPositiveButtonCallback(OnClickedPositiveButton, self)
    self.pbDialogFrame:SetDialogClosedCallback(OnDialogCloseAnimEnd, self)
end

function UIExitGameDialog:OnShow()
    self.pbDialogFrame:ShowDialog()
end

return UIExitGameDialog
