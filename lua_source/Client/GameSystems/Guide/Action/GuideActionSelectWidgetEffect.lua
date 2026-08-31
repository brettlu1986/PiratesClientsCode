-----------------------------------------------------
--File Name    : GuideActionSelectWidgetEffect.lua
--Author       : Edward J
--Create Time  : 2019-09-02
--Description  : 没有点击效果的SelectWidget
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionSelectWidget       = require("GuideActionSelectWidget")
local GuideActionSelectWidgetEffect = luaclass("GuideActionSelectWidgetEffect", GuideActionSelectWidget)

-----------------------------------------------------

-----------------------------------------------------

function GuideActionSelectWidgetEffect:Begin()
    GuideActionSelectWidgetEffect.super.Begin(self)
end

function GuideActionSelectWidgetEffect:OnSelect()
    
end

function GuideActionSelectWidgetEffect:OnItemClick()
    
end


function GuideActionSelectWidgetEffect:OnDoubleClick()
       
end

return GuideActionSelectWidgetEffect
