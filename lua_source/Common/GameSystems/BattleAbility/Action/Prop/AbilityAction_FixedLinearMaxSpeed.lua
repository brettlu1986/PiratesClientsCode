-----------------------------------------------------
--File Name    : AbilityAction_FixedLinearMaxSpeed.lua
--Author       : Song Fuhao
--Create Time  : 2020-05-19
--Description  : 此Action的效果是根据预期固定值增益反推最
--               大直线速度的百分比再进行叠加，这么做是因为
--               目前的直线速度固定值叠加不能满足半帆时只叠
--               加一半速度，底层机制目前不太好改
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_FixedLinearMaxSpeed = luaclass("AbilityAction_FixedLinearMaxSpeed", AbilityActionPropBase)

local PropName = require("PropName")
local PropUtil = require("PropUtil")
local ShipDataTable = require("ShipDataTable")
local ShipMovementDef = require("ShipMovementDef")
local ShipGearDataTable = require("ShipGearDataTable")
local PropertyWrapperType = require("PropertyWrapperType")

function AbilityAction_FixedLinearMaxSpeed:GetValue(tbCharacter)
    local nShipTemplateId = tbCharacter:GetShipTemplateId()
    local tbShipTemplate = ShipDataTable:GetTemplate(nShipTemplateId)
    if tbShipTemplate then
        local nGearId = tbShipTemplate.nGearId
        local tbGearTemplate = ShipGearDataTable:GetGear(nGearId, ShipMovementDef.ShipPostureDef.FullSail, ShipMovementDef.ShipGearDef.FullSpeed)
        if tbGearTemplate and (tbGearTemplate.nMaxLinearSpeed ~= 0) then
            return self.tbInitParams.Value * 100 / tbGearTemplate.nMaxLinearSpeed
        else
            logerror("AbilityAction_FixedLinearMaxSpeed GetValue failed, cannot find gear template, or MaxLinearSpeed is zero, id =", nGearId)
        end
    -- else
        -- 因为Action依赖船ID，所以使用这个Action时需要注意一下添加时机，如果像饰品之类的功能添加，因为添加时机过早，会获取不到ID，可以结合ShipChanged的Event使用
        -- logerror("AbilityAction_FixedLinearMaxSpeed GetValue failed, cannot find ship template, id =", nShipTemplateId)
    end
    return 0
end

function AbilityAction_FixedLinearMaxSpeed:GetOverlapType()
    return PropertyWrapperType.TYPE_MULTIPLY
end

function AbilityAction_FixedLinearMaxSpeed:GetWrapperName()
    return PropName.nLinearMaxSpeedAddition
end

function AbilityAction_FixedLinearMaxSpeed:GetTargetType()
    return PropUtil.TARGET_TYPE.SHIP
end

function AbilityAction_FixedLinearMaxSpeed:OnDo(tbParams)
    self:OnUndo()
    AbilityAction_FixedLinearMaxSpeed.super.OnDo(self, tbParams)
end

return AbilityAction_FixedLinearMaxSpeed
