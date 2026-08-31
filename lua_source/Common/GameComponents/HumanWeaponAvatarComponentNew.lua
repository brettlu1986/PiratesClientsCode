-----------------------------------------------------
--File Name    : HumanWeaponAvatarComponentNew.lua
--Author       : WuJizhou
--Create Time  : 10/18/2018, 8:56:22 PM
--Description  : HumanWeaponAvatarComponentNew
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local HumanWeaponAvatarComponentNew = luaclass("HumanWeaponAvatarComponentNew", GameComponentBaseClass)
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local HumanAvatarHelper = require("HumanAvatarHelper")


--nWeaponGroup: nFashionId
HumanWeaponAvatarComponentNew.tbFashionData = nil

HumanWeaponAvatarComponentNew.rtbFashionIdBySlot = nil


function HumanWeaponAvatarComponentNew:OnWeaponEquip(nSlotIndex, nWeaponInstanceType)
    local rtbFashionIdBySlot = self.rtbFashionIdBySlot
    if rtbFashionIdBySlot then
        local rtbFashionId = rtbFashionIdBySlot[nSlotIndex]
        if rtbFashionId then
            local nFashionId = self.tbFashionData[nWeaponInstanceType]
            nFashionId = nFashionId == nil and 0 or nFashionId
            rtbFashionId:Set(nFashionId)
        end
    end
end


-------base api from GameComponentBaseClass--------
function HumanWeaponAvatarComponentNew:OnCreate(Owner, tbHumanWeaponFashionItemTemplateIds)
    HumanWeaponAvatarComponentNew.super.OnCreate(self, Owner, tbHumanWeaponFashionItemTemplateIds)
    if GlobalVariableSystem:IsServerLogic() then
        self.tbFashionData = HumanAvatarHelper.ParseToHumanWeaponFashionDataFromFashionTemplateIds(tbHumanWeaponFashionItemTemplateIds)
    end

    return true
end

-- function HumanWeaponAvatarComponentNew:OnDestroy()
-- end

-- function HumanWeaponAvatarComponentNew:GetOwner()
--     return HumanWeaponAvatarComponentNew.super.GetOwner(self)
-- end

function HumanWeaponAvatarComponentNew:OnActorCreated()
    self.rtbFashionIdBySlot = self:GetOwner().HumanWeaponComponent.rtbFashionIdBySlot
end


-- function HumanWeaponAvatarComponentNew:OnActorDestroyed(pUEActor)
-- end

return HumanWeaponAvatarComponentNew