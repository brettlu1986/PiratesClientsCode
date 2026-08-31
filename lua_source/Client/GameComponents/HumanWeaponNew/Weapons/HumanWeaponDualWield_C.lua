local luaclass = require("luaclass")
local HumanWeaponDualWield = require("HumanWeaponDualWield")
local HumanWeaponDualWield_C = luaclass("HumanWeaponDualWield_C", HumanWeaponDualWield)

local HumanWeaponType = require("HumanWeaponType")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local HumanWeaponHelper = require("HumanWeaponHelper")
local AutoBattleSystem = require("AutoBattleSystem")

HumanWeaponDualWield_C.bAutoClearReload = false
-- HumanWeaponDualWield_C.bNeedPlayAttackMontage = false
HumanWeaponDualWield_C.pRWeaponActor = nil 
HumanWeaponDualWield_C.bLeftWeapon = true
-- local szDefaultHoldedSocket = "L_Weapon01"
-- local szDefaultUnHoldedSocket = "Weapons_B2"

local szRWeaponHoldedSocket = "L_Weapon01"
local szRWeaponUnHoldedSocket = "Weapons_B2"

function HumanWeaponDualWield_C:GetWeaponBPType()
    return HumanWeaponType.ThrowWeapon
end 

-- function HumanWeaponDualWield_C:GetHoldSocketName()
--     return szDefaultHoldedSocket
-- end 

-- function HumanWeaponDualWield_C:GetUnholdSocketName()
--     return szDefaultUnHoldedSocket
-- end 



function HumanWeaponDualWield_C:UpdateRWeaponAttachState()
    if not self.pRWeaponActor then  
        return 
    end 
    local nState = self.nState
    local bNewAttachedToHand = nState ~= nil  and nState ~= HumanWeaponStateDef.UNHOLDED

    local szSocketName
    local pOwnerActor = self.pOwnerActor
    if(bNewAttachedToHand) then
        szSocketName = szRWeaponHoldedSocket
    else
        szSocketName = szRWeaponUnHoldedSocket
    end        
    self.pRWeaponActor:K2_AttachToComponent(pOwnerActor.Mesh, szSocketName, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, false)
end 

function HumanWeaponDualWield_C:UpdateAttachState(bForce)
    local bRet = HumanWeaponDualWield_C.super.UpdateAttachState(self, bForce)
    if bRet then 
        self:UpdateRWeaponAttachState() 
    end  
    return bRet
end

local function PreAttackInClient(self, tbAttackInfo, tbSubInfo)
    if(not self.bServer) then
        HumanWeaponHelper.SendDualWieldAttack(self.nInstanceId, self.bLeftWeapon)
    end
    self.bLeftWeapon = not self.bLeftWeapon
end 

local function PreAttackFinished(self, tbAttackInfo, bCancel, tbSubInfo)
    if bCancel then  
        -- self.OwnerComponent:StopCurrentMontage(szPreKey) 
        return 
    end
end 



function HumanWeaponDualWield_C:OnCreated(OwnerComponent, nInstanceId, nTemplateId, nSlot)
    HumanWeaponDualWield_C.super.OnCreated(self, OwnerComponent, nInstanceId, nTemplateId, nSlot)
    -- self.pWeaponActor:ReloadClient()
    local SaveWeaponActor = self.pWeaponActor
    if(nTemplateId ~= nil) then
        self:CreateWeaponActor()
        self.pRWeaponActor = self.pWeaponActor
        self.pWeaponActor = SaveWeaponActor
        self:UpdateRWeaponAttachState()
    end
    
    self.bAutoClearReload = false

    local tbPreSubAttackInfo = {
        OnActivate = PreAttackInClient,   -- 攻击，子类重载
        OnDeactivate = PreAttackFinished,
        nDuration = nil,                          -- 持续时间
        bCanDeactivateExternally = true,
    }
    -- local tbMidSubAttackInfo = {
    --     OnActivate = MidAttackInClient,   -- 攻击，子类重载
    --     OnDeactivate = MidOnAttackFinished,   -- 攻击结束
    --     nDuration = nil,                          -- 持续时间
    --     --bCanDeactivateExternally = false,
    -- }    
    -- local tbPostSubAttackInfo = {
    --     OnActivate = PostAttackInClient,   -- 攻击，子类重载
    --     nDuration = nil,                          -- 持续时间
    --     bCanDeactivateExternally = false,
    -- }    
    self.tbAttackInfo[1] = tbPreSubAttackInfo
    -- self.tbAttackInfo[2] = tbMidSubAttackInfo
    -- self.tbAttackInfo[3] = tbPostSubAttackInfo
    self.tbAttackInfo.nStateCount = 1
end

function HumanWeaponDualWield_C:OnRepDualWieldAttack(tbRepData)
    if(tbRepData == nil) then
        return
    end

    if(not self.bSelf or AutoBattleSystem:InAutoBattle()) then
        -- 自己已经播过了
        -- PlayAttackMontage(self)
        self.pWeaponActor:PlayAttackEffect()
    end
end 

return HumanWeaponDualWield_C