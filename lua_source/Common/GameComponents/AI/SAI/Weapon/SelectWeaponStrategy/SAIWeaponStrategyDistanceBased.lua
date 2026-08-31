local luaclass = require("luaclass")
local SAIWeaponStrategyBase = require("SAIWeaponStrategyBase")
local SAIWeaponStrategyDistanceBased = luaclass("SAIWeaponStrategyDistanceBased", SAIWeaponStrategyBase)
local SAIService = require("SAIService")
local SAIMisc = require("SAIMisc")
local SAISystemDef = require("SAISystemDef")

local nM2CM = 100

local function LOG(...)
    log("CJ->SAIWeaponStrategyDistanceBased:", ...)
end

SAIWeaponStrategyDistanceBased.tbWeapons = nil
SAIWeaponStrategyDistanceBased.nTickIntarval = 1
SAIWeaponStrategyDistanceBased.tbService = nil
SAIWeaponStrategyDistanceBased.tbTreatSystem = nil
SAIWeaponStrategyDistanceBased.nSelectedSlot = 0

function SAIWeaponStrategyDistanceBased:Init(Owner)
    SAIWeaponStrategyDistanceBased.super.Init(self, Owner)
    self.tbWeapons = {}
end

function SAIWeaponStrategyDistanceBased:AddWeapon(nWeaponSlot, tbWeaponItem)
    local tbWeaponConfig = SAIMisc:GetWeaponConfig(self.tbOwner, tbWeaponItem:GetTemplateId())
    local tbWeapon = {
        Slot = nWeaponSlot,
        Weight =  tbWeaponConfig.nWeight,
        MaxDistance = tbWeaponConfig.nMaxDistance * nM2CM,
    }
    LOG("add weapon ", nWeaponSlot, tbWeapon.MaxDistance)
    table.insert(self.tbWeapons, tbWeapon)
end

function SAIWeaponStrategyDistanceBased:RemoveWeapon(nWeaponSlot)
    for i,v in ipairs(self.tbWeapons) do
        if v.Slot == nWeaponSlot then
            table.remove(self.tbWeapons, i)
            break
        end
    end
end

function SAIWeaponStrategyDistanceBased:ShouldReSelect(nDistance)
    local nSelected = 0
    local nNearestDistance = 10000000
    for i,v in ipairs(self.tbWeapons) do
        if v.MaxDistance >= nDistance and v.MaxDistance < nNearestDistance then
            nSelected = v.Slot
            nNearestDistance = v.MaxDistance
        end
    end
    return nSelected ~= self.nSelectedSlot
end


function SAIWeaponStrategyDistanceBased:SelectWeapon()
    if #self.tbWeapons > 0 then
        local nSelectedSlot = -1
        local tbTreatObject = self.tbTreatSystem:GetThreatObject()
        if tbTreatObject and not tbTreatObject:IsDead() then
            local nDistance = self.tbOwner.pUEActor:GetDistanceTo(tbTreatObject.pUEActor)
            if self:ShouldReSelect(nDistance) then
                local tbSlots = {}
                local tbPosibility = {}
                local nTotalPosib = 0
                for i,v in ipairs(self.tbWeapons) do
                    if nDistance <= v.MaxDistance then
                        table.insert(tbSlots, v.Slot)
                        table.insert(tbPosibility, v.Weight)
                        nTotalPosib = nTotalPosib + v.Weight
                    end
                end
                if nTotalPosib > 0 then
                    local nMaxPosib = 0
                    local nRand = math.random(1, nTotalPosib)
                    for i,v in ipairs(tbPosibility) do
                        nMaxPosib = nMaxPosib + v
                        if nMaxPosib >= nRand then
                            nSelectedSlot = tbSlots[i]
                            break
                        end
                    end
                end
            end
        end
        if nSelectedSlot > 0 and self.nSelectedSlot ~= nSelectedSlot then
            LOG("select weapon ", nSelectedSlot)
            self.nSelectedSlot = nSelectedSlot
            self:ChangeWeapon(nSelectedSlot)
        end
    end
end

function SAIWeaponStrategyDistanceBased:Start(tbAIWeapon)
    LOG("start")
    self.tbWeapons = {}
    self.nSelectedSlot = 0
    SAIWeaponStrategyDistanceBased.super.Start(self, tbAIWeapon)
end

function SAIWeaponStrategyDistanceBased:OnStart()
    self.tbService = SAIService()
    self.tbService:Init(self.nTickIntarval, self.SelectWeapon, self)
    self.tbService:Start()
    self.tbTreatSystem = self.tbOwner.SAIComponent:GetSystem(SAISystemDef.Threat)
end

function SAIWeaponStrategyDistanceBased:OnStop()
    if self.tbService then
        self.tbService:Stop()
        self.tbService = nil
    end
    self.tbTreatSystem = nil
end

return SAIWeaponStrategyDistanceBased