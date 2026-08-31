-----------------------------------------------------
--File Name    : HDC_ShipIncendiary.lua
--Author       : Song Fuhao
--Create Time  : 2019-01-21
--Description  : 用于处理臼炮燃烧弹伤害（对人）
-----------------------------------------------------
local GameObjectSystem = dynamic_require("GameObjectSystem")
local RelationshipSystem = require("RelationshipSystem")

local INCENDIARY_BUFF_ID = 80004

local function GetCauser(pDamageCauser)
    local pInstigator = pDamageCauser:GetInstigator()
    if isvalidhandle(pInstigator) then
        return GameObjectSystem:FindByUEActor(pInstigator)
    end
    return nil
end

return function(tbTaker, nActualDamage, pDamageCauser, pHitResult)
    pDamageCauser:PlayHitSoundAndFx(Enum_HitEffectType.Default)

    -- 免疫找不到Causer或队友的伤害
    local tbCauser = GetCauser(pDamageCauser)
    if (not tbCauser) or RelationshipSystem:IsFriendRelation(tbTaker, tbCauser) then
        return
    end

    tbTaker.BuffComponentServer:AddBuffWithInstigator(tbCauser, INCENDIARY_BUFF_ID)
end