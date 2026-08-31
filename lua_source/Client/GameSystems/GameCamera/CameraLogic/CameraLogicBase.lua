

local luaclass = require("luaclass")
local CameraLogicBase = luaclass("CameraLogicBase")
local SelfEventHelper = require("SelfEventHelper")

-- member variable
CameraLogicBase.EventHelper = nil
CameraLogicBase.Owner       = nil

-- public function
function CameraLogicBase:Create(Owner)
    self.Owner = Owner
    self.EventHelper = SelfEventHelper()
    self:OnCreate()
end

function CameraLogicBase:Destroy()
    self:OnDestroy()
    self.EventHelper = nil
end

function CameraLogicBase:OnCreate()
end

function CameraLogicBase:OnDestroy()
end


function CameraLogicBase:BindEvent()
    self:OnBindEvent(self.EventHelper)
end

function CameraLogicBase:UnbindEvent()
    self:OnUnbindEvent(self.EventHelper)
    self.EventHelper:UnregisterAll()
end

function CameraLogicBase:OnBindEvent(EventHelper)
end

function CameraLogicBase:OnUnbindEvent(EventHelper)
end

return CameraLogicBase
