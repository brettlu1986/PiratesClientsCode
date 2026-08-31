-- local luaclass = require("luaclass")
-- local SelfAnimationHelper   = luaclass("SelfAnimationHelper")
local SelfAnimationHelper = {}
local AnimationResDataTable = require("AnimationResDataTableNew")
local PropName = require("PropName")
local AnimDef = require("AnimDef")
local ResourceManager = require("ResourceManager")
local ShipDataTable = require("ShipDataTable")

local DEFAULT_HUMAN_TEMPLATE_ID = 100000

SelfAnimationHelper.AnimDef = AnimDef

local function GetMovementState(tbPlayer)
    local HumanMovementStateComponent = tbPlayer.HumanMovementStateComponent
    if HumanMovementStateComponent == nil then
        return
    end

    return HumanMovementStateComponent:GetCurrentState()
end

local function GetCurWeaponProperty(tbPlayer)
    local nWeaponTemplateId
    local HumanWeaponComponent = tbPlayer.HumanWeaponComponent
    local nCategory = 0
    if HumanWeaponComponent then
        -- nWeaponTemplateId = HumanWeaponComponent.rCurrentWeaponTemplateId and HumanWeaponComponent.rCurrentWeaponTemplateId:Get()
        nWeaponTemplateId = HumanWeaponComponent:GetCurrentWeaponTemplateId()
        if nWeaponTemplateId and nWeaponTemplateId == 0 then
            nWeaponTemplateId = nil
        end
        nCategory = HumanWeaponComponent:GetCurrentWeaponCategory(nWeaponTemplateId)
    end
    return nWeaponTemplateId, nCategory
end

local function GetHumanArmorId(tbPlayer)
    local HumanBattlePropertyComponent = tbPlayer.HumanBattlePropertyComponent
    if HumanBattlePropertyComponent then  
        local nCurrentArmorTemplatedId = tbPlayer.HumanBattlePropertyComponent:GetProp(PropName.nCurrentArmorTemplateId)
        return nCurrentArmorTemplatedId
    end
end

local function PlayAnimMontage(Mesh, AnimMontage, InPlayRate, StartSectionName, bStopAllMontages)
    if not Mesh then
        return
    end
    if bStopAllMontages == nil then  
        bStopAllMontages = true
    end 
    local AnimInstance = Mesh:GetAnimInstance()
    if( AnimMontage and AnimInstance ) then
		local Duration = AnimInstance:Montage_Play(AnimMontage, InPlayRate, EMontagePlayReturnType.MontageLength, 0.0, bStopAllMontages)
		if (Duration > 0) then
			-- Start at a given Section.
			if( StartSectionName ) then
				AnimInstance:Montage_JumpToSection(StartSectionName, AnimMontage)
            end

			return Duration
        end
    end
	return 0
end

local function PlayAnimation(pMesh, pMontage, fPlayRate, bStopAllMontages)
    if not pMesh or not pMontage then
        return false
    end

    if not fPlayRate then  
        fPlayRate = 1.0
    end 
    -- local szAnimation = self:GetAnimationRes(nTemplateId, szAnimKey, nStateId, nWeaponId, nWeaponCategory, nArmorId)

    local nAnimTime = PlayAnimMontage(pMesh, pMontage, fPlayRate, nil, bStopAllMontages)
    return true, nAnimTime
end

function SelfAnimationHelper:GetCacheMontage(CacheOwner, szAnimation)
    if not CacheOwner then 
        local pMontage = szAnimation:load()
        return pMontage
    end 
    if not CacheOwner.tbCachedMontages then 
        CacheOwner.tbCachedMontages = {}
    end 
    local pMontage = CacheOwner.tbCachedMontages[szAnimation]
    if not pMontage then 
        pMontage = szAnimation:load()
        if not pMontage then 
            return nil
        end            
        ResourceManager:Hold(pMontage)
        CacheOwner.tbCachedMontages[szAnimation] = pMontage     
    end     
    return pMontage
end

function SelfAnimationHelper:GetAnimationRes(nTemplateId, szAnimKey)
    local tbParams = {}
    tbParams.nTemplateId = nTemplateId
    tbParams.szAnimKey = szAnimKey    
    local tbTemplate = AnimationResDataTable:GetTemplate(tbParams)
    if tbTemplate then  
        return tbTemplate.szAnimation
    end

    logerror("Can't Find Animation nTemplateId,", nTemplateId, "szAnimKey", szAnimKey)
end

function SelfAnimationHelper:GetHumanAnimation(tbPlayer, szAnimKey)
    if not tbPlayer or not tbPlayer:IsHuman() or not szAnimKey or string.len( szAnimKey ) <= 0 then
        return
    end
    local nStateId = GetMovementState(tbPlayer)
    local nWeaponTemplateId, nCategory = GetCurWeaponProperty(tbPlayer)
    local nArmorId = GetHumanArmorId(tbPlayer)
    local nTemplateId = tbPlayer:GetTemplateId()
    local tbParams = {}
    tbParams.nStateId = nStateId
    tbParams.nWeaponId = nWeaponTemplateId
    tbParams.nWeaponCategory = nCategory
    tbParams.nArmorId = nArmorId
    tbParams.nTemplateId = tbPlayer:GetTemplateId()
    tbParams.szAnimKey = szAnimKey
    tbParams.nDefaultTemplateId = DEFAULT_HUMAN_TEMPLATE_ID
    local tbTemplate = AnimationResDataTable:GetTemplate(tbParams)
    if tbTemplate then  
        -- logdebug("szAnimKey", szAnimKey, tbTemplate.szAnimation)
        return tbTemplate.szAnimation, tbTemplate
    end

    logerror("Can't Find Animation nTemplateId,", nTemplateId, "szAnimKey", szAnimKey, "nWeaponTemplateId", 
        nWeaponTemplateId, "nArmorId", nArmorId, "nStateId", nStateId, "nCategory", nCategory)
end

function SelfAnimationHelper:StopAnimMontage(Mesh, AnimMontage)
    if not Mesh then
        return
    end
    local AnimInstance = Mesh:GetAnimInstance()
    if not AnimInstance then 
        return
    end
	local MontageToStop = (AnimMontage) and AnimMontage or AnimInstance:GetCurrentActiveMontage()

    if (MontageToStop and not AnimInstance:Montage_GetIsStopped(MontageToStop) ) then
        AnimInstance:Montage_Stop(0, MontageToStop)
    end
end

function SelfAnimationHelper:StopHumanAnimation(tbPlayer, szAnimKey, CacheOwner)
    if not tbPlayer or not tbPlayer:IsHuman() or not szAnimKey or string.len( szAnimKey ) <= 0 or not tbPlayer.pUEActor then
        return false
    end
    local pMesh = tbPlayer.pUEActor.Mesh
    local nTemplateId = tbPlayer:GetTemplateId()
    if not pMesh or not szAnimKey or not nTemplateId then
        log("SelfAnimationHelper:StopHumanAnimation invalid pmesh or szAnimKey", pMesh, szAnimKey, nTemplateId)
        return false
    end
    local szAnimation = self:GetHumanAnimation(tbPlayer, szAnimKey)
    if not szAnimation then
        return false
    end

    local pAnimation = nil 
    if CacheOwner then 
        pAnimation = self:GetCacheMontage(CacheOwner, szAnimation)
    end

    return self:StopAnimMontage(pMesh, pAnimation)
end
function SelfAnimationHelper:JumpToMontageSection(pMesh, pMontage, szSection)
    if not pMesh then 
        return 
    end

    local AnimInstance = pMesh:GetAnimInstance()
    AnimInstance:Montage_JumpToSection(szSection, pMontage)
end

function SelfAnimationHelper:HumanJumpToMontageSection(tbPlayer, szSection, szAnimKey, CacheOwner)
    if not tbPlayer or not tbPlayer:IsHuman() then
        return
    end
    local pActor = tbPlayer.pUEActor
    local nTemplateId = tbPlayer:GetTemplateId()
    if not pActor then
        return false
    end
    local pMesh = pActor.Mesh

    if not pMesh then
        log("SelfAnimationHelper:JumpToMontageSection invalid pmesh or szAnimKey", pMesh, szAnimKey, nTemplateId)
        return false
    end

    local AnimInstance = pMesh:GetAnimInstance()

    if not szAnimKey or not nTemplateId then
        AnimInstance:Montage_JumpToSection(szSection, nil)
        return true
    end

    local szAnimation = self:GetHumanAnimation(tbPlayer, szAnimKey)
    if not szAnimation then
        return false
    end

    if CacheOwner then 
        local pMontage = self:GetCacheMontage(CacheOwner, szAnimation)
        AnimInstance:Montage_JumpToSection(szSection, pMontage)
    end 

    return true
end


function SelfAnimationHelper:PlayActorAnimation(pActor, nTemplateId, szAnimKey, CacheOwner)
    if not pActor then
        return false
    end
    local szAnimation = self:GetAnimationRes(nTemplateId, szAnimKey) 
    if not szAnimation then  
        return false
    end
    local pMontage = self:GetCacheMontage(CacheOwner, szAnimation)

    if not pMontage then 
        return false
    end   
    local bRet, nAnimTime = PlayAnimation(pActor.Mesh, pMontage)
    return bRet, nAnimTime, pMontage
end

function SelfAnimationHelper:PlayHumanAnimation(tbPlayer, szAnimKey, PlayRate, bStopAllMontages, CacheOwner)
    if not tbPlayer or not tbPlayer:IsHuman() or not szAnimKey or string.len( szAnimKey ) <= 0 or not tbPlayer.pUEActor then
        log("SelfAnimationHelper PlayHumanAnimation Invalid")
        return false
    end
    local szAnimation, szRootMotion = self:GetHumanAnimation(tbPlayer, szAnimKey)
    -- logdebug("the animation is :", szAnimation)
    if not szAnimation then  
        return false
    end
    local pMontage = self:GetCacheMontage(CacheOwner, szAnimation)

    if not pMontage then 
        return false
    end   

    local bRet, nAnimTime = PlayAnimation(tbPlayer.pUEActor.Mesh, pMontage, PlayRate, bStopAllMontages)
    return bRet, nAnimTime, pMontage, szRootMotion
end

local function GetShipResTemplateId(tbShip, nShipTemplateId)
    local nShipResId = -1
    local BattleShipSkinComponent = tbShip.BattleShipSkinComponent
    if BattleShipSkinComponent then -- 先看有没有皮肤
        nShipResId = BattleShipSkinComponent:GetShipResId(nShipTemplateId)
    end
    if nShipResId == -1 then -- 没有皮肤，则用船的TemplateId取默认皮肤
        local tbTemplate = ShipDataTable:GetResTemplate(nShipTemplateId)
        if tbTemplate then
            nShipResId = tbTemplate.nResId
        end
    end
    return nShipResId
end

function SelfAnimationHelper:PlayShipAnimation(tbShip, nTemplateId, szAnimKey, CacheOwner)
    if not tbShip or not tbShip:IsShip() or not szAnimKey or string.len( szAnimKey ) <= 0 then
        return false
    end

    nTemplateId = nTemplateId or tbShip:GetTemplateId()
    local nShipResId = GetShipResTemplateId(tbShip, nTemplateId)
    local pChildActor = tbShip.pUEActor.ShipModel.ChildActor
    local szAnimation = self:GetAnimationRes(nShipResId, szAnimKey)
    if not szAnimation then  
        return false
    end
    local pMontage = self:GetCacheMontage(CacheOwner, szAnimation)

    if not pMontage then 
        return false
    end   
    local bRet, nAnimTime = PlayAnimation(pChildActor.SKM_ShipMaster, pMontage)
    return bRet, nAnimTime, pMontage
end

function SelfAnimationHelper:ShipJumpToMontageSection(tbShip, szSection, szAnimKey)
    if not tbShip or not tbShip:IsShip() or not tbShip.pUEActor then
        return false
    end

    local pChildActor = tbShip.pUEActor.ShipModel.ChildActor
    local pMesh = pChildActor.SKM_ShipMaster
    local AnimInstance = pMesh:GetAnimInstance()

    if not szAnimKey or not tbShip:GetTemplateId() then
        AnimInstance:Montage_JumpToSection(szSection, nil)
        return false
    end

    local nShipResId = GetShipResTemplateId(tbShip, tbShip:GetTemplateId())
    local szAnimation = self:GetAnimationRes(nShipResId, szAnimKey)
    if not szAnimation then
        return false
    end

    AnimInstance:Montage_JumpToSection(szSection, szAnimation:load())
    
    return true
end

function SelfAnimationHelper:PlayNPCAnimation(tbNpc, szAnimKey)
    if not tbNpc or tbNpc:IsShip() or not szAnimKey or string.len( szAnimKey ) <= 0 then
        return false
	end
    return self:PlayActorAnimation(tbNpc.pUEActor, tbNpc.tbNpcTemplateData.nTypeID, szAnimKey)
end

function SelfAnimationHelper:ClearOwnerCache(CacheOwner)
    if not CacheOwner then  
        return 
    end 
    local tbCachedMontages = CacheOwner.tbCachedMontages

    if not tbCachedMontages then 
        return 
    end 

    for k, v in pairs(tbCachedMontages) do
        ResourceManager:Unhold(v)
    end
end

function SelfAnimationHelper:IsHumanMontagePlaying(tbPlayer, szAnimKey, CacheOwner)
    if not tbPlayer or not tbPlayer:IsHuman() or not szAnimKey or string.len( szAnimKey ) <= 0 or not tbPlayer.pUEActor then
        log("SelfAnimationHelper IsHumanMontagePlaying Invalid")
        return false
    end

    local szAnimation = self:GetHumanAnimation(tbPlayer, szAnimKey)
    if not szAnimation then  
        return false
    end
    local pMontage = self:GetCacheMontage(CacheOwner, szAnimation)

    if not pMontage then 
        return false
    end   

    local pMesh = tbPlayer.pUEActor.Mesh
    if not pMesh then
        return false
    end

    local AnimInstance = pMesh:GetAnimInstance()
    if not AnimInstance then
        return false
    end

    return AnimInstance:Montage_IsPlaying(pMontage)
end

--直接play anim sequence
function SelfAnimationHelper:PlayWeaponAnimSequence(pMesh, pAnim, bReverse)
	--要先set animation mode 否则 AnimInstance会是空
	pMesh:SetAnimationMode(EAnimationMode.AnimationSingleNode)
    local AnimInstance = pMesh:GetAnimInstance()
    if AnimInstance then
        pMesh:SetAnimation(pAnim)
        local nLenth = AnimInstance:GetLength()
        if not bReverse then
            AnimInstance:PlayAnim(false, 1, 0)
        else  
            AnimInstance:PlayAnim(false, -1, nLenth)
        end
        return true
    end
    return false
end

return SelfAnimationHelper