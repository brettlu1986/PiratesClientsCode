local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPScheduleTabBase = luaclass("UPScheduleTabBase", PrefabBase)

UPScheduleTabBase.nId = nil
UPScheduleTabBase.tbTemplate = nil
UPScheduleTabBase.bActivate = nil

function UPScheduleTabBase:Activate()
end

function UPScheduleTabBase:Deactivate()
end

function UPScheduleTabBase:OnLoad()
end

function UPScheduleTabBase:OnBindEvent(EventHelper)
end

function UPScheduleTabBase:SetTemplate(tbTemplate)
    self.nId = tbTemplate.nId
    self.tbTemplate = tbTemplate
end

function UPScheduleTabBase:Activate()
    self.bActivate = true
    self.pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
end

function UPScheduleTabBase:Deactivate()
    self.bActivate = false
    self.pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
end

return UPScheduleTabBase