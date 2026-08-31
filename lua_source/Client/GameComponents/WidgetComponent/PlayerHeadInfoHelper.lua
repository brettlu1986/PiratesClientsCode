local PlayerHeadInfoHelper = {}

local HeadHpIni = require("HeadHpIni")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemDataTable = require("BattleItemDataTable")
local GameObjectTypeDef = require("GameObjectTypeDef")

function PlayerHeadInfoHelper.CanShowPlayerHp(tbPlayer)
    if not tbPlayer then  
        return false
    end
    if tbPlayer:IsHuman() and not HeadHpIni.bShowHumanHp then  
        return false
    end
    if tbPlayer:IsShip() and not HeadHpIni.bShowShipHp then  
        return false
    end
    return true
end

function PlayerHeadInfoHelper.CanShowPlayerDamageNum(tbPlayer)
    if not tbPlayer then  
        return false
    end
    if tbPlayer:GetObjectType() == GameObjectTypeDef.DestructibleObject then  
        return true
    end
    if tbPlayer:IsHuman() and not HeadHpIni.bShowHumanDamage then  
        return false
    end
    if tbPlayer:IsShip() and not HeadHpIni.bShowShipDamage then  
        return false
    end
    return true
end

function PlayerHeadInfoHelper.CanShowSelfShipDamageNum()
    return HeadHpIni.bShowSelfShipDamage
end

function PlayerHeadInfoHelper.GetDamageNumWorldStartLoc(tbPlayer)
    local pUEActor = tbPlayer.pUEActor
    local pActorLoc = pUEActor:K2_GetActorLocation()
    local bSelf = tbPlayer:GetObjectType() == GameObjectTypeDef.PlayerSelf
    if tbPlayer:GetObjectType() == GameObjectTypeDef.DestructibleObject then  
        return pActorLoc
    else 
        if tbPlayer:IsHuman() then  
            pActorLoc.Z = pActorLoc.Z + HeadHpIni.nDamageNumHumanHeight
        else   
            if bSelf then
                pActorLoc.Z = pActorLoc.Z + HeadHpIni.nDamageNumSelfShipHeight
            else 
                pActorLoc.Z = pActorLoc.Z + HeadHpIni.nDamageNumShipHeight
            end
        end
    end
    return pActorLoc
end

function PlayerHeadInfoHelper.GetNpcDamageNumWorldStartLoc(tbPlayer)
    local pUEActor = tbPlayer.pUEActor
    local pActorLoc = pUEActor:K2_GetActorLocation()
    if tbPlayer:IsHuman() then  
        pActorLoc.Z = pActorLoc.Z + HeadHpIni.nDamageNumNpcHumanHeight
    else   
        pActorLoc.Z = pActorLoc.Z + HeadHpIni.nDamageNumNpcShipHeight
    end
    return pActorLoc
end

function PlayerHeadInfoHelper.SetPlayerHeadInfoWorldPosition(tbPlayer, pWidgetComponent)
    if pWidgetComponent then 
        if tbPlayer:IsHuman() then
            pWidgetComponent:K2_SetRelativeLocation(Vector{X = 0, Y = 0, Z = HeadHpIni.nHpBarHumanHeight})
        elseif tbPlayer:IsShip() then 
            local pUEActor = tbPlayer.pUEActor
            local nHeadInfoZ = pUEActor.HeadInfo.RelativeLocation.Z
            pWidgetComponent:K2_SetRelativeLocation(Vector{X = 0, Y = 0, Z = nHeadInfoZ}) 
            --pWidgetComponent:K2_SetRelativeLocation(Vector{X = 0, Y = 0, Z = HeadHpIni.nHpBarShipHeight})
        end
    end
end

function PlayerHeadInfoHelper.SetNpcHeadInfoWorldPosition(tbPlayer, pWidgetComponent)
    if pWidgetComponent then 
        if tbPlayer:IsHuman() then
            pWidgetComponent:K2_SetRelativeLocation(Vector{X = 0, Y = 0, Z = HeadHpIni.nHpBarNpcHumanHeight})
        elseif tbPlayer:IsShip() then  
            local pUEActor = tbPlayer.pUEActor
            local nHeadInfoZ = pUEActor.HeadInfo.RelativeLocation.Z
            pWidgetComponent:K2_SetRelativeLocation(Vector{X = 0, Y = 0, Z = nHeadInfoZ})
            --pWidgetComponent:K2_SetRelativeLocation(Vector{X = 0, Y = 0, Z = HeadHpIni.nHpBarNpcShipHeight})
        end
    end
end

--HeadInfoWorld的 位置, 跟 HeadInfo的位置对齐
function PlayerHeadInfoHelper.ResetHeadInfoLocation(tbPlayer, pWidgetComponent)
    local pUEActor = tbPlayer.pUEActor
    if pUEActor then  
        local nHeadInfoZ = pUEActor.HeadInfo.RelativeLocation.Z
        pWidgetComponent:K2_SetRelativeLocation(Vector{X = 0, Y = 0, Z = nHeadInfoZ})
    end
end

function PlayerHeadInfoHelper.GetDamageRatio(nActualDamage, nWeaponTemplateId, nCount)
    local PlayerSelf = GamePlayerSelfHelper:Get()

    if nCount == 0 then 
        log("[DamageNum] calculate the damage ratio but count zero")
        nCount = 1
    end
    -- logdebug("the count is :", nActualDamage, nCount)
    if PlayerSelf:IsHuman() then  
        local tbTemplate = BattleItemDataTable:GetTemplate(nWeaponTemplateId)
        -- logdebug("weapon template id :", nWeaponTemplateId)
        if tbTemplate then
            local nBaseDamage = tbTemplate.nDamagePerBullet
            if not nBaseDamage then   
                nBaseDamage = tbTemplate.nDamage
            end
            
            if nBaseDamage then 
                local nTotalBaseDamage = nBaseDamage * nCount
                -- logdebug("human base damage is :", nActualDamage * 1.0 / nTotalBaseDamage, nBaseDamage, nTotalBaseDamage)
                return nActualDamage * 1.0 / nTotalBaseDamage
            end
        end 
    else  
        local tbTemplate = BattleItemDataTable:GetTemplate(nWeaponTemplateId)
        if tbTemplate then   
            local nTotalBaseDamage = tbTemplate.nBaseDamage * nCount
            -- logdebug("ship base damage :",nActualDamage * 1.0 / nTotalBaseDamage, tbTemplate.nBaseDamage, nTotalBaseDamage)
            return nActualDamage * 1.0 / nTotalBaseDamage
        end
    end
    return 1

  
end

function PlayerHeadInfoHelper.GetDamageColorStrAndFontSize(nRatio)
    if nRatio <= 0.5 then  
        return HeadHpIni.szDamgetNormalColor, HeadHpIni.nDamageNormalFontSize
    elseif nRatio > 0.5 and nRatio <= 1 then   
        return HeadHpIni.szDamgetAboveNormalColor, HeadHpIni.nDamageAboveNormalFontSize
    elseif nRatio > 1 and nRatio < 1.5 then 
        return HeadHpIni.szDamgetHeavyColor, HeadHpIni.nDamageHeavyFontSize
    else   
        return HeadHpIni.szDamgetCriticalColor, HeadHpIni.nDamageCriticalFontSize
    end
end

function PlayerHeadInfoHelper.IsTeammate(tbCharacter)
    local SelfObj = GamePlayerSelfHelper:Get()
    local nInstanceId = tbCharacter:GetServerInstanceId()
    local BattleTeamComponent = SelfObj.BattleTeamComponent
    
    return BattleTeamComponent:GetMemberInfo(nInstanceId) ~= nil or false
end


return PlayerHeadInfoHelper