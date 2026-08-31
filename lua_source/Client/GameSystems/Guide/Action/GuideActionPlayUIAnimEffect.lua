-----------------------------------------------------
--File Name    : GuideActionPlayUIAnimEffect.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionPlayUIAnim         = require("GuideActionPlayUIAnim")
local GuideActionPlayUIAnimEffect   = luaclass("GuideActionPlayUIAnimEffect", GuideActionPlayUIAnim)

----------------------------------------------------------

----------------------------------------------------------

function GuideActionPlayUIAnimEffect:Begin()
    self:DebugLog(" GuideActionPlayUIAnimEffect:Begin ")
    GuideActionPlayUIAnimEffect.super.Begin(self)
end

function GuideActionPlayUIAnimEffect:OnMoveTypeChange(nState)
    
end

function GuideActionPlayUIAnimEffect:OnSelect()
  
end    

return GuideActionPlayUIAnimEffect
