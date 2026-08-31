-----------------------------------------------------
--File Name    : HumanWeaponAvatarComponentNew_C.lua
--Author       : WuJizhou
--Create Time  : 4/13/2020, 7:50:39 PM
--Description  : HumanWeaponAvatarComponentNew_C
-----------------------------------------------------
local luaclass                  = require("luaclass")
local HumanWeaponAvatarComponentNew   = require("HumanWeaponAvatarComponentNew")
local HumanWeaponAvatarComponentNew_C = luaclass("HumanWeaponAvatarComponentNew_C", HumanWeaponAvatarComponentNew)

local GamePlayerSelfHelper           = require("GamePlayerSelfHelper")
local HumanWeaponFashionDataTable    = require("HumanWeaponFashionDataTable")
local BattleItemDataTable            = require("BattleItemDataTable")
local BattleItemCategoryDef          = require("BattleItemCategoryDef")
local GameAvatarHelper               = require("GameAvatarHelper")
local HumanWeaponAvatarResPartDef    = require("HumanWeaponAvatarResPartDef")

local HumanAvatarSystem              = dynamic_require("HumanAvatarSystem")

HumanWeaponAvatarComponentNew_C.tbFashions = nil

local function OnHumanWeaponActorCreated(self, nInstanceId)
    local Weapon = self.Owner.HumanWeaponComponent:FindWeaponById(nInstanceId)
    local nWeaponTemplateId = Weapon.nTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nWeaponTemplateId)
    local nTrunkPartId = tbItemTemplate.nTrunkPartId --set to default

    local nCategory = tbItemTemplate.nCategory

    if nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        local nGrade = tbItemTemplate.nGrade
        local nSlotIndex = Weapon.nSlot

        local nFashionId
        if self.Owner:GetServerInstanceId() == GamePlayerSelfHelper:GetServerInstanceId() then
            local tbFashionData = HumanAvatarSystem:GetWeaponAvatarFashion()
            local nWeaponInstanceType = tbItemTemplate.nWeaponInstanceType
            nFashionId = tbFashionData[nWeaponInstanceType]
        else
            nFashionId = self.rtbFashionIdBySlot[nSlotIndex]:Get()
        end
        if nFashionId and nFashionId > 0 then
            local tbFashionTemplate = HumanWeaponFashionDataTable:GetFashionTemplate(nFashionId, nGrade)
            if tbFashionTemplate then
                nTrunkPartId = tbFashionTemplate.nTrunkPartId
                log("HumanWeaponAvatarComponentNew_C.OnHumanWeaponActorCreated",nTrunkPartId)
            end
        end
    end

    local tbPartData = {}
    tbPartData[HumanWeaponAvatarResPartDef.Trunk] = nTrunkPartId
    local pWeapon = Weapon.pWeaponActor
    GameAvatarHelper.UpdateWeaponAvatar(pWeapon.AvatarComponent, tbPartData)
end

function HumanWeaponAvatarComponentNew_C:UpdateWeaponFashion(tbInstanceId)
    if tbInstanceId then
        for _, nInstanceId in ipairs(tbInstanceId) do
            OnHumanWeaponActorCreated(self, nInstanceId)
        end
    end
end

-------base api from GameComponentBaseClass--------
function HumanWeaponAvatarComponentNew_C:OnCreate(Owner, tbParams)
    HumanWeaponAvatarComponentNew_C.super.OnCreate(self, Owner, tbParams)
    Owner.DelegateComponent.OnHumanWeaponActorCreated:Bind(OnHumanWeaponActorCreated, self)
    self.tbFashions = {}
    return true
end

function HumanWeaponAvatarComponentNew_C:OnDestroy()
    self.Owner.DelegateComponent.OnHumanWeaponActorCreated:Unbind(OnHumanWeaponActorCreated, self)
    HumanWeaponAvatarComponentNew_C.super.OnDestroy(self)
end

-- function HumanWeaponAvatarComponentNew_C:GetOwner()
--     return self.super.GetOwner(self)
-- end

-- function HumanWeaponAvatarComponentNew_C:OnActorPreCreated(pUEActor)
--     HumanWeaponAvatarComponentNew_C.super.OnActorPreCreated(self, pUEActor)
--     if self.Owner:IsHuman() then
--         local tbTemplate = HumanDataTable:GetTemplate(self.Owner:GetTemplateId())
--         local nHumanGender = tbTemplate.nGender
--         if nHumanGender == GenderTypeDefine.MALE then
--             pUEActor:SetGender(ENUM_HumanGender.Male)
--         else
--             pUEActor:SetGender(ENUM_HumanGender.Female)
--         end
--     end
-- end

-- function HumanWeaponAvatarComponentNew_C:OnActorCreated(pUEActor)
--     HumanWeaponAvatarComponentNew_C.super.OnActorCreated(self, pUEActor)
--     BindCommitDelegate(self)
--     if GlobalVariableSystem:IsInLobby() then
--         self:OnAvatarResDataChanged(nil, self.tbComponentData:GetPartDatas())
--     else
--         self:RefreshAvatar(self.rHumanAvatarData:Get())
--     end

-- end

-- function HumanWeaponAvatarComponentNew_C:OnActorDestroyed(...)
--     UnbindCommitDelegate(self)
--     HumanWeaponAvatarComponentNew.super.OnActorDestroyed(self, ...)
-- end

return HumanWeaponAvatarComponentNew_C