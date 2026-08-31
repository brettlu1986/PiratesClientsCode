-----------------------------------------------------
--File Name    : SelfPolyMorphHelper.lua
--Author       : Zuo Kun
--Create Time  : 2017-11-10
--Description  : 变形
-----------------------------------------------------
local HumanDataTable = require("HumanDataTable")
local UEActorHelper =  require("UEActorHelper")

local SelfPolyMorphHelper = {}

function SelfPolyMorphHelper:HumanPolyMorph(nHumanID, pUEActor)
    if not pUEActor or not pUEActor.Mesh then 
        return 
    end 
    local tbTable = HumanDataTable:GetTemplate(nHumanID)
    if(tbTable ~= nil) then
        local _, RetActor = UEActorHelper:CreateActor(tbTable.tbResData.szPawnClassName)
        if RetActor then 
            -- -- RetActor.Mesh
            -- local tbMeshComponents = pUEActor:GetComponentsByClass(MeshComponent)
            -- for i,v in ipairs(tbMeshComponents) do
            --     v:SetVisibility()
            -- end
            pUEActor.Mesh:SetVisibility(false, true)
            pUEActor.Mesh:SetVisibility(true, false)
            pUEActor.Mesh:SetSkeletalMesh(RetActor.Mesh.SkeletalMesh, true)
            pUEActor.Mesh:SetAnimInstanceClass(RetActor.Mesh.AnimClass)
     
            UEActorHelper:DestroyActor(RetActor)     
        end 
    end    
end 

return SelfPolyMorphHelper
