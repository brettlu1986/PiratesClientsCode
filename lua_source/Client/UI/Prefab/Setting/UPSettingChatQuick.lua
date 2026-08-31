local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPSettingChatQuick = luaclass("UPSettingChatQuick", ListItemBase)

UPSettingChatQuick.tbData = nil
-- {nId = , bOpering = , szMsg = }

local function RefreshUI(self)
    local pWidgetRef = self.pWidgetRef
    local tbData = self.tbData
    pWidgetRef.btnRemove:SetVisibility(tbData.bOpering and tbData.szMsg and tbData.nId > 0 and ESlateVisibility.Visible or ESlateVisibility.Hidden)
    pWidgetRef.txtTitle:SetText(tbData.szMsg or "")
end

local function OnClickedRemove(self)
    local tbData = self.tbData
    if tbData.bOpering and tbData.nId > 0 then
        tbData.tbParent:OnRemove(self.nIndex)
    end
end

function UPSettingChatQuick:OnLoad()
end

function UPSettingChatQuick:OnCreate()
end

function UPSettingChatQuick:OnDestroy()
end

function UPSettingChatQuick:OnShow()
end

function UPSettingChatQuick:OnRefresh(tbData)
    self.tbData = tbData
    RefreshUI(self)
end

function UPSettingChatQuick:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnRemove.OnClicked, self, OnClickedRemove)
end

return UPSettingChatQuick