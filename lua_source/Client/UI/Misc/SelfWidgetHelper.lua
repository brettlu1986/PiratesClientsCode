-----------------------------------------------------
--File Name    : SelfWidgetHelper.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-11
--Description  : SelfWidgetHelper
-----------------------------------------------------

local luaclass = require("luaclass")
local SelfWidgetHelper = luaclass("SelfWidgetHelper")

-- import
local UIManager = require("UIManager")

-- member variable
SelfWidgetHelper.tbWidgetMap = {}

-- 创建一个Widget
-- @param   pWidgetClass
-- @return  pWidget
function SelfWidgetHelper:CreateWidget( pWidgetClass )
    local pWidget = UIManager:CreateWidget(pWidgetClass)
    if pWidget then
        local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pWidget)
        self.tbWidgetMap[nUniqueID] = pWidget
    end
    return pWidget
end

function SelfWidgetHelper:DestroyWidget( pWidget )    
    local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pWidget)
    if self.tbWidgetMap[nUniqueID] then
        UIManager:DestroyWidget(pWidget)
        self.tbWidgetMap[nUniqueID] = nil
    end
end

function SelfWidgetHelper:DestroyAllWidget()
    for nUniqueID, v in pairs(self.tbWidgetMap) do
        UIManager:DestroyWidget(v)
    end
    self.tbWidgetMap = {}
end

return SelfWidgetHelper
