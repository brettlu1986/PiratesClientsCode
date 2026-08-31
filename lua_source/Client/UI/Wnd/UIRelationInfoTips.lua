local luaclass              = require("luaclass")
local WndBase               = require("WndBase")
local UIRelationInfoTips         = luaclass("UIRelationInfoTips", WndBase)
local UISetUtils = require("UISetUtils")
function UIRelationInfoTips:OnLoad()
   
end

function UIRelationInfoTips:OnCreate()
    
end

function UIRelationInfoTips:OnShow()
    local l10nTitle = UISetUtils.GetL10NTextByKey("UI_RELATION_TIP_TITLE")
    local l10nMessage = UISetUtils.GetL10NTextByKey("UI_RELATION_TIP_CONTENT")
    self.pWidgetRef.txtTitle:SetText(l10nTitle)
    self.pWidgetRef.txtMessage:SetText(l10nMessage)
end

function UIRelationInfoTips:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClose.OnClicked, self, function()
        self:CloseSelf()
    end)
end

return UIRelationInfoTips
