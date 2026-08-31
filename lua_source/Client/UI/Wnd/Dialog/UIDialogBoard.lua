-----------------------------------------------------
--File Name    : UIDialogBoard.lua
--Author       : Song Fuhao
--Create Time  : 2019-02-27
--Description  : 简单的文字提示Dialog
-----------------------------------------------------

local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIDialogBoard = luaclass("UIDialogBoard", WndBase)

local UIDef = require("UIDef")

UIDialogBoard.tbDialogMap = nil
UIDialogBoard.CurrentDialog = nil

local function AcquireDialog(self)
    local Dialog = self.PrefabHelper:CreatePrefab(UIDef.UP_DIALOG_FRAME)
    Dialog:SetDialogClosedCallback(function()
        Dialog.pWidgetRef:RemoveFromParent()
        self.PrefabHelper:UnbindPrefab(Dialog)
        self.tbDialogMap[Dialog] = nil
        self.CurrentDialog = nil
        if not next(self.tbDialogMap) then
            self:CloseSelf()
        end
    end)
    local pSlot = self.pWidgetRef.ovlContent:AddChild(Dialog.pWidgetRef)
    pSlot:SetHorizontalAlignment(EHorizontalAlignment.HAlign_Fill)
    pSlot:SetVerticalAlignment(EVerticalAlignment.VAlign_Fill)
    self.tbDialogMap[Dialog] = Dialog
    self.CurrentDialog = Dialog
    return Dialog
end

function UIDialogBoard:OnLoad()
    self.tbDialogMap = {}
end

function UIDialogBoard:CreateDialog(l10nTitle, l10nMessage)
    local Dialog = AcquireDialog(self)
    if l10nTitle then
        Dialog:SetTitle(l10nTitle)
    end
    if l10nMessage then
        Dialog:SetMessage(l10nMessage)
    end
    return Dialog
end

function UIDialogBoard:IsDialogExist(Dialog)
    return self.tbDialogMap[Dialog] ~= nil
end

function UIDialogBoard:GetCurrentDialog()
    return self.CurrentDialog
end

return UIDialogBoard
