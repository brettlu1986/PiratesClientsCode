local luaclass = require ("luaclass")
local WndBase = require("WndBase")

local UIQuestion = luaclass("UIQuestion", WndBase)

function UIQuestion:OnLoad()
    local UILogicHelper = self.UILogicHelper
    self.ulQuestion = UILogicHelper:CreateUILogic("ULQuestion")
end

function UIQuestion:OnShow()
    self.ulQuestion:Activate()
end

function UIQuestion:OnUnLoad()
    self.ulQuestion:Deactivate()
end

return UIQuestion
