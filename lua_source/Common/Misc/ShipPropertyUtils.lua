local ShipPropertyUtils = {}

function ShipPropertyUtils.GetShipProperty(tbShip, szPropertyName, varDefaultValue)
    local tbHelper = tbShip:GetPropertyHelper()
    local tbShipCollection = tbHelper:GetShipPropertyCollection()
    local varRet = tbShipCollection:GetProperty(szPropertyName)
    return varRet and varRet or varDefaultValue
end

function ShipPropertyUtils.GetFightProperty(tbShip, szPropertyName, varDefaultValue)
    local tbHelper = tbShip:GetPropertyHelper()
    local tbFightCollection = tbHelper:GetFightPropertyCollection()
    local varRet = tbFightCollection:GetProperty(szPropertyName)
    return varRet and varRet or varDefaultValue
end

function ShipPropertyUtils.GetGunSolutionProperty(tbShip, nGunType, szPropertyName, varDefaultValue)
    local tbHelper = tbShip:GetPropertyHelper()
    local tbGunCollection = tbHelper:GetGunPropertyCollection()
    local varRet = tbGunCollection:GetGunSolutionProperty(nGunType, szPropertyName)
    return varRet and varRet or varDefaultValue
end

function ShipPropertyUtils.GetGunProperty(tbShip, nGunType, szPropertyName, varDefaultValue)
    local tbHelper = tbShip:GetPropertyHelper()
    local tbGunCollection = tbHelper:GetGunPropertyCollection()
    local varRet = tbGunCollection:GetGunProperty(nGunType, szPropertyName)
    return varRet and varRet or varDefaultValue
end

function ShipPropertyUtils.GetGunBulletProperty(tbShip, nGunType, nBulletId, szPropertyName, varDefaultValue)
    local tbHelper = tbShip:GetPropertyHelper()
    local tbGunCollection = tbHelper:GetGunPropertyCollection()
    local varRet = tbGunCollection:GetGunBulletProperty(nGunType, nBulletId, szPropertyName)
    return varRet and varRet or varDefaultValue
end

function ShipPropertyUtils.GetArmorProperty(tbShip, nPartId, szPropertyName, varDefaultValue)
    local tbHelper = tbShip:GetPropertyHelper()
    local tbArmorCollection = tbHelper:GetArmorPropertyCollection()
    local varRet = tbArmorCollection:GetProperty(nPartId, szPropertyName)
    return varRet and varRet or varDefaultValue
end

function ShipPropertyUtils.GetTorpedoSolutionProperty(tbShip, szPropertyName, varDefaultValue)
    local tbHelper = tbShip:GetPropertyHelper()
    local tbTorpedoCollection = tbHelper:GetTorpedoPropertyCollection()
    local varRet = tbTorpedoCollection:GetTorpedoSolutionProperty(szPropertyName)
    return varRet and varRet or varDefaultValue
end

function ShipPropertyUtils.GetTorpedoProperty(tbShip, szPropertyName, varDefaultValue)
    local tbHelper = tbShip:GetPropertyHelper()
    local tbTorpedoCollection = tbHelper:GetTorpedoPropertyCollection()
    local varRet = tbTorpedoCollection:GetTorpedoProperty(szPropertyName)
    return varRet and varRet or varDefaultValue
end

return ShipPropertyUtils
