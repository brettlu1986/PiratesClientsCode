-----------------------------------------------------
--File Name    : UEClientActorHelper.lua
--Author       : Zuo Kun
--Create Time  : 2017-03-16
--Description  : Client Actor 
-----------------------------------------------------

local UEClientActorHelper = {}

local UEActorHelper = require("UEActorHelper")
local GameObjectSystem = require("GameObjectSystem_C")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BitHelper = require("BitHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")

local szEffectRenderActorClassPath = "/Game/UI/RenderTarget/BP_EffectRenderActor.BP_EffectRenderActor_C"

UEClientActorHelper.nMaxFactor = 1
UEClientActorHelper.tbObjectVisibleFactors = {
	[GameObjectTypeDef.PlayerSelf] = 0,
	[GameObjectTypeDef.PlayerOther] = 0,
	[GameObjectTypeDef.Trigger] = 0,    
    [GameObjectTypeDef.Dummy] = 0,
	[GameObjectTypeDef.Npc] = 0,
	[GameObjectTypeDef.AtmoSphereNpc] = 0           
}

local function ActiveComponent(pUEActor)
    if not pUEActor then 
        return 
    end 
    local tbParticleComponents = pUEActor:GetComponentsByClass(ParticleSystemComponent)
    for _, ParticleComponent in ipairs(tbParticleComponents) do
        ParticleComponent:Activate(true)
    end
end 
-- function UEClientActorHelper:SetPlayerVisible(tbTypes, bVisible)
--     local tbGameObjs = GameObjectSystem:GetAllGameObjects()
--     for i,v in pairs(tbGameObjs) do
--         if v.bValid and v.pUEActor then 
--             if tbTypes[v.ObjectType] then 
--                 v.pUEActor:SetActorHiddenInGame(not bVisible)
--                 -- v.pUEActor.RootComponent:SetVisibility(bVisible, false)
--                 -- v.pUEActor:K2_GetRootComponent():SetVisibility(bVisible, true)
--                 if bVisible and v.ObjectType == GameObjectTypeDef.Trigger then 
--                     ActiveComponent(v.pUEActor)
--                     -- ActiveComponent(v.pUEActor.ChildActor.ChildActor)
--                     -- ActiveComponent(v.pUEActor.ChildActor1.ChildActor)
--                 end 
--                 v.bVisible = bVisible
--                 if v.HeadInfoComponent then 
--                     v.HeadInfoComponent:SetVisibility(bVisible)
--                 end 
--             end             
--         end 
--     end
-- end

function UEClientActorHelper:SetAllObjectVisibilityFactor(nFactor, tbTypes, bVisible)
    local tbObjectVisibleFactors = self.tbObjectVisibleFactors
    if not bVisible then
        for k, v in pairs(tbTypes) do
            tbObjectVisibleFactors[k] = BitHelper:SetBitValue(tbObjectVisibleFactors[k], nFactor)
        end
    else
        for k, v in pairs(tbTypes) do
            tbObjectVisibleFactors[k] = BitHelper:SetBitZero(tbObjectVisibleFactors[k], nFactor)
        end    
    end

    local tbGameObjs = GameObjectSystem:GetAllGameObjects()
    for i, v in pairs(tbGameObjs) do
        if v.bValid and isvalidhandle(v.pUEActor) then 
            if tbTypes[v.ObjectType] then 
                local bObjVisible = tbObjectVisibleFactors[v.ObjectType] == 0
                -- if v.ObjectType == GameObjectTypeDef.PlayerSelf then
                --     log("SetAllObjectVisibilityFactor", v.szName, bVisible, bObjVisible, debug.traceback( ))
                -- end
                local pUEActor = v.pUEActor
                pUEActor:SetActorHiddenInGame(not bObjVisible)
                local ChildActors = pUEActor:GetAttachedActors()
                for _, Child in ipairs(ChildActors) do
                    Child:SetActorHiddenInGame(not bObjVisible)
                end
                if bObjVisible and v.ObjectType == GameObjectTypeDef.Trigger then 
                    ActiveComponent(v.pUEActor)
                end 
                v.bVisible = bObjVisible
                if v.HeadInfoComponent then 
                    v.HeadInfoComponent:SetVisibility(bObjVisible)
                end 
            end             
        end 
    end    
end

function UEClientActorHelper:AllocateObjectVisiblityFactor()
    assert(self.nMaxFactor <= 31)
    local nFactor = self.nMaxFactor
    self.nMaxFactor = nFactor + 1
    return nFactor
end

function UEClientActorHelper:ClearAllObjectVisibleFactors()
    self.nMaxFactor = 1
    for k, v in pairs(self.tbObjectVisibleFactors) do
        self.tbObjectVisibleFactors[k] = 0
    end
end

function UEClientActorHelper:CreateEffectRenderTargetActor(pRenderTargetImgRef, szPSPath, pInLocation, pInRotation, pInScale)
    if not pRenderTargetImgRef then 
        return
    end
    
    local _,pRenderActor = UEActorHelper:CreateActor(szEffectRenderActorClassPath, Vector{X=10000, Y=10000, Z=-10000})
    if not pRenderActor then 
        return
    end

    local pPSTemplate = szPSPath:load()
    if not pPSTemplate then 
        UEActorHelper:DestroyActor(pRenderActor)
        return
    end    

    local pLocation = (pInLocation == nil) and self.pDefualtLocation or pInLocation
    local pRotation = (pInRotation == nil) and self.pDefualtRotation or pInRotation
    local pScale = (pInScale == nil) and self.pDefualtScale or pInScale    
    local pTransform = KismetMathLibrary.MakeTransform(pLocation, pRotation, pScale)
    pRenderActor:SetPSTemplate(pPSTemplate,pTransform)
    pRenderTargetImgRef:SetBrushFromMaterial(pRenderActor.RenderMaterial)


    return pRenderActor
end 

-- 面向角色
function UEClientActorHelper:FaceToPlayer(pActor)
    local pPlayer = GamePlayerSelfHelper:Get().pUEActor
    local pTargetRotation = KismetMathLibrary.FindLookAtRotation(pActor:K2_GetActorLocation(), pPlayer:K2_GetActorLocation())
    pActor:K2_SetActorRotation(pTargetRotation, false)    
end

return UEClientActorHelper
