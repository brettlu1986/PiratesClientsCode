-----------------------------------------------------
--File Name    : GuideActionCentralGuide.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideActionSelectWidget           = require("GuideActionSelectWidget")
local GuideActionSelectDialogWidget     = luaclass("GuideActionSelectDialogWidget", GuideActionSelectWidget)

-- local UIUtils           = require("UIUtils")
----------------------------------------------------------

-- local function GetDialogWidget()
--     local DialogFrameScript = UIUtils:GetCurrentDialog()
--     return DialogFrameScript
-- end

-- local function GetDialogContentWidget()
--     local DialogFrameScript = GetDialogWidget()
--     if not DialogFrameScript then
--         return nil
--     end
--     local ContentWidget = DialogFrameScript:GetView()
--     if not ContentWidget then
--         return nil
--     end
--     return ContentWidget
-- end

-- function GuideActionSelectDialogWidget:GetSelectWidgets()
--     local tbSelectWidgets = {}
--     local tbTemplate = self.tbTemplate
--     local pWidgetScript = GetDialogWidget()
--     local pWidgetRef = pWidgetScript.pWidgetRef
--     if not pWidgetRef then
--         return tbSelectWidgets
--     end
--     for k, v in ipairs(tbTemplate.tbWidgetName)do
--         local pSelectWidget = pWidgetRef[v]
--         self:DebugLog("111GuideActionSelectDialogWidget:GetSelectWidgets WidgetName = ", v)
--         if pSelectWidget then
--             table.insert(tbSelectWidgets, pSelectWidget)
--         else
--             self:LogError("GuideAction:GetSelectWidgets,can't find widgeht,name=", v)
--         end
--     end
--     self:DebugLog("111GuideActionSelectDialogWidget:GetSelectWidgets, SelectWidgets Count =", #tbSelectWidgets)
--     pWidgetRef = GetDialogContentWidget()
--     if not pWidgetRef then
--         return tbSelectWidgets
--     end
--     for k, v in ipairs(tbTemplate.tbDialogcontentName)do
--         self:DebugLog("222GuideActionSelectDialogWidget:GetSelectWidgets WidgetName = ", v)
--         local pSelectWidget = pWidgetRef[v]
--         if pSelectWidget then
--             table.insert(tbSelectWidgets, pSelectWidget)
--         else
--             self:LogError("GuideAction:GetSelectWidgets,can't find widgeht,name=", v)
--         end
--     end
--     self:DebugLog("222GuideActionSelectDialogWidget:GetSelectWidgets, SelectWidgets Count =", #tbSelectWidgets)
--     return tbSelectWidgets
-- end

-- function GuideActionSelectDialogWidget:Begin()
--     GuideActionSelectDialogWidget.super.Begin(self)  
-- end

return GuideActionSelectDialogWidget