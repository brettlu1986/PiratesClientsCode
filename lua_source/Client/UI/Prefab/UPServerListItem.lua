local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPServerListItem = luaclass("UPServerListItem", ListItemBase)

UPServerListItem.tbServerData = nil
UPServerListItem.OnCheckedDelegate = nil
UPServerListItem.bRefreshingData = false
local OnCheckStateChanged = function(self)
    if self.bRefreshingData then
        return
    end
    local tbServerData = self.tbServerData
    if tbServerData.OnCheckedDelegate then
        tbServerData.OnCheckedDelegate:Fire(tbServerData)          
    end
end

function UPServerListItem:OnBindEvent(Helper)
    Helper:RegisterCppDelegate(self.pWidgetRef.chbChosen.OnCheckStateChanged, self, OnCheckStateChanged)
end

function UPServerListItem:OnRefresh(tbServerData)
    self.bRefreshingData = true
    self.tbServerData = tbServerData
    self.pWidgetRef.txtName:SetText(tbServerData.name)
    if tbServerData.nChosen then
        self.pWidgetRef.chbChosen:SetIsChecked(true)
        self.pWidgetRef.chbChosen:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        self.pWidgetRef.chbChosen:SetIsChecked(false)
        self.pWidgetRef.chbChosen:SetVisibility(ESlateVisibility.Visible)
    end
    self.bRefreshingData = false
end

function UPServerListItem:SetOnCheckedDelegate(tbDelegate)
    self.OnCheckedDelegate = tbDelegate
end

return UPServerListItem

