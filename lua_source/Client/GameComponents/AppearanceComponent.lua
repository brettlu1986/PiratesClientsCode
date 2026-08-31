-----------------------------------------------------
--File Name    : AppearanceComponent.lua
--Author       : WuJizhou
--Create Time  : 5/11/2020, 3:17:27 PM
--Description  : AppearanceComponent
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local AppearanceComponent = luaclass("AppearanceComponent", GameComponentBaseClass)

local DefaultAppearanceDataTable = require("DefaultAppearanceDataTable")
local CreateRoleUIDef = require("CreateRoleUIDef")

AppearanceComponent.tbAppearance = nil


function AppearanceComponent:GetAppearanceIds()
    return self.tbAppearance
end

function AppearanceComponent:GetFashionAppearanceId()
    for _, nAppearanceId in ipairs(self.tbAppearance) do
        local tbTemplate = DefaultAppearanceDataTable:GetData(nAppearanceId)
        if tbTemplate.nType == CreateRoleUIDef.SlotType.Costume then
            return nAppearanceId
        end
    end
end

-------base api from GameComponentBaseClass--------
function AppearanceComponent:OnCreate(Owner, tbParams)
    self.super.OnCreate(self, Owner, tbParams)
    self.tbAppearance = tbParams.template_id
    return true
end

-- function AppearanceComponent:OnDestroy()
-- end

-- function AppearanceComponent:GetOwner()
--     return self.super.GetOwner(self)
-- end

-- function AppearanceComponent:OnActorPreCreated()
-- end

-- function AppearanceComponent:OnActorCreated(pUEActor)
-- end

-- function AppearanceComponent:OnActorDestroyed(pUEActor)
-- end


return AppearanceComponent