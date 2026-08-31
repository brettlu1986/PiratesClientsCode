-----------------------------------------------------
--File Name    : AbilityAction_MakeAirDropVisibleOnMap.lua
--Author       : WuJizhou
--Create Time  : 2019-2-25
--Description  : 增加船材料上限数量比例
-----------------------------------------------------
local PropName                       = require("PropName")
local PropUtil      = require("PropUtil")

local luaclass = require("luaclass")
local PropertyWrapperType = require("PropertyWrapperType")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_MakeAirDropVisibleOnMap = luaclass("AbilityAction_MakeAirDropVisibleOnMap", AbilityActionPropBase)


function AbilityAction_MakeAirDropVisibleOnMap:GetWrapperName()
    return PropName.bCanSeeAirDropOnMap
end

function AbilityAction_MakeAirDropVisibleOnMap:GetTargetType()
    return PropUtil.TARGET_TYPE.HUMAN
end

function AbilityAction_MakeAirDropVisibleOnMap:GetOverlapType()
    return PropertyWrapperType.TYPE_OVERRIDE
end

function AbilityAction_MakeAirDropVisibleOnMap:GetValue(tbCharacter)
    return true
end

function AbilityAction_MakeAirDropVisibleOnMap:OnDo(tbParams)
    AbilityAction_MakeAirDropVisibleOnMap.super.OnDo(self, tbParams)
    -- self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
    --     -- local d2c_SyncAirDropVisibility = {}
    --     -- d2c_SyncAirDropVisibility.is_visible = self:GetValue(tbCharacter)
    --     -- NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_SyncAirDropVisibility, d2c_SyncAirDropVisibility)
    -- end, tbParams)
end


return AbilityAction_MakeAirDropVisibleOnMap
