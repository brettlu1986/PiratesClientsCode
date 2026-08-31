-----------------------------------------------------
--File Name    : UILogicBase.lua
--Author       : Song Fuhao
--Create Time  : 2018-01-16
--Description  : UI纯逻辑类基类
-----------------------------------------------------

local luaclass = require("luaclass")
local UILogicBase = luaclass("UILogicBase")
local SelfEventHelper = require("SelfEventHelper")

-- member variable
UILogicBase.EventHelper = nil
UILogicBase.PrefabHelper= nil
UILogicBase.TimerHelper = nil
UILogicBase.WidgetHelper= nil
UILogicBase.Owner       = nil
UILogicBase.bEventBinded = nil

-- public function
function UILogicBase:Create(Owner)
    self.Owner = Owner
    if Owner then
        self.pWidgetRef     = Owner.pWidgetRef
        self.EventHelper    = SelfEventHelper()
        self.PrefabHelper   = Owner.PrefabHelper
        self.TimerHelper    = Owner.TimerHelper
        self.WidgetHelper   = Owner.WidgetHelper
        self:OnCreate()
    else
        logerror("UILogicBase Create failed, Owner is nil")
    end
end

function UILogicBase:Destroy()
    self:OnDestroy()
    self.PrefabHelper = nil
    self.EventHelper = nil
    self.TimerHelper = nil
    self.WidgetHelper = nil

    self.pWidgetRef = nil
    self.tbTemplate = nil
end

function UILogicBase:OnCreate()
end

function UILogicBase:OnDestroy()
end

function UILogicBase:OnLoad()
end

function UILogicBase:OnUnload()
end

function UILogicBase:OnEnter()
end

function UILogicBase:OnShow()
end

function UILogicBase:OnHide()
end

function UILogicBase:OnExit()
end

function UILogicBase:OnPause()
end

function UILogicBase:OnResume()
end

function UILogicBase:BindEvent()
    if not self.bEventBinded then
        self.bEventBinded = true
        self:OnBindEvent(self.EventHelper)
    end
end

function UILogicBase:UnbindEvent()
    self:OnUnbindEvent(self.EventHelper)
    self.EventHelper:UnregisterAll()
    self.bEventBinded = false
end

function UILogicBase:OnBindEvent(EventHelper)
end

function UILogicBase:OnUnbindEvent(EventHelper)
end

return UILogicBase
