-----------------------------------------------------
--File Name    : GuideActionGetShipAward.lua
--Author       : Edward J
--Create Time  : 2019-09-18
--Description  : 指引向前走
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFunctional                   = require("GuideActionFunctional")
local GuideActionGetShipAward       = luaclass("GuideActionGetShipAward", GuideActionFunctional)

local NoobAwardHelper               = require("NoobAwardHelper")
local Proto                         = require("ClientProtoNames")
local UIUtils                       = require("UIUtils")
-----------------------------------------------------

-----------------------------------------------------

local function GetShipAward(self)
    NoobAwardHelper.GetNoobAward(Proto.NoobAwardType.NOOB_SHIP)
end

function GuideActionGetShipAward:DoAction(tbTemplate)
    GuideActionGetShipAward.super.DoAction(self, tbTemplate)
    if not tbTemplate.tbParam then
        self:ForceEndCurrentGroup()
        return
    end
    local szTitle = self.tbTemplate.tbParam[1]
    local szContent = self.tbTemplate.tbParam[2]
	UIUtils.ShowConfirmDialog(szTitle, szContent, function()  GetShipAward(self) self:EndAction() end)
end

return GuideActionGetShipAward