local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPAVGSub = luaclass("UPAVGSub", ListItemBase)

local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")

local AVOID_ACTIVE_TEXT = "功能暂没开放"
local LOCK_TEXT = "未解锁"

local PASS_IMAGE = "PaperSprite'/Game/UI/FFA/Textures/UI_Interface/Frames/Spr_Story03_Pressed.Spr_Story03_Pressed'"

UPAVGSub.tbAVGData = nil

function UPAVGSub:OnCreate()
end

function UPAVGSub:OnLoad()
end

function UPAVGSub:OnBindEvent()
    self.EventHelper:RegisterCppDelegate(self.pWidgetRef.Button_0.OnClicked, self, self.OnClicked)
end

function UPAVGSub:OnDestroy()
end

function UPAVGSub:OnRefresh(tbData)
    self.tbAVGData = tbData
    self.pWidgetRef.TextBlock_0:SetText(tbData.szName)
    self.pWidgetRef.Button_0:SetVisibility(ESlateVisibility.Visible)

    if tbData.bCanEnter then
        if tbData.bHasPass then
            self.pWidgetRef.imgBg:SetVisibility(ESlateVisibility.Visible)
            self.pWidgetRef.imgBgUp:SetVisibility(ESlateVisibility.Collapsed)

            local IconObj = PASS_IMAGE:load()
            if IconObj then
                UISetUtils.SetImageBrushRes(self.pWidgetRef.imgBg, IconObj, true)
            end
        else
            self.pWidgetRef.imgBg:SetVisibility(ESlateVisibility.Visible)
            self.pWidgetRef.imgBgUp:SetVisibility(ESlateVisibility.Collapsed)
        end
    else
        self.pWidgetRef.imgBg:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.imgBgUp:SetVisibility(ESlateVisibility.Visible)
    end
end

function UPAVGSub:OnClicked()
    if self.pWidgetRef.imgBgUp:GetVisibility() == ESlateVisibility.Visible then
        UIUtils.ShowToast(LOCK_TEXT, 0.2)
    else
        UIUtils.ShowToast(AVOID_ACTIVE_TEXT, 0.2)
    end
end

return UPAVGSub
