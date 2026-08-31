local SDCHelper = {}

local PropName = require("PropName")
local BaseUtil = require("BaseUtil")

local BURNING_BUFF_ID = 31001
local LEAKING_BUFF_ID = 31002

function SDCHelper.LOG(szFormat, ...)
    -- log("[ShipDamageInfo]", string.format(szFormat, ...))
end

-- 处理漏水
function SDCHelper.CheckLeaking(tbCauser, tbTaker, tbWeaponTemplate, tbArmorTemplate)
    local tbCauserPropCmpt = tbCauser.ShipBattlePropertyComponent
    local tbTakerPropCmpt = tbTaker.ShipBattlePropertyComponent
    local nWeaponId = tbWeaponTemplate.nId
    local nWeaponSubCategory = tbWeaponTemplate.nSubCategory

    -- logdebug("nWeaponId:", nWeaponId)
    -- 处理漏水
    local nLeakingProb = tbWeaponTemplate.nLeakingProb
    SDCHelper.LOG("[Leaking] 漏水判定开始，武器默认漏水率：%f", nLeakingProb)
    if nLeakingProb <= 0 then
        SDCHelper.LOG("[Leaking] 默认漏水率<=0，跳过判定")
        return false
    end
    nLeakingProb = nLeakingProb + (tbCauserPropCmpt:GetProp(PropName.nLeakingProb) - 1)
    local tbLeakingProbInfo = tbCauserPropCmpt:GetProp(PropName.tbLeakingProbInfo)
    if tbLeakingProbInfo then
        if BaseUtil:ContainsByValue(tbLeakingProbInfo.tbWeaponTypes, nWeaponSubCategory)
        or BaseUtil:ContainsByValue(tbLeakingProbInfo.tbWeaponIds, nWeaponId) then
            nLeakingProb = nLeakingProb + tbLeakingProbInfo.nValue
        end
    end
    SDCHelper.LOG("[Leaking] 加成后漏水率：%f", nLeakingProb)
    local nLeakingProofProb = tbArmorTemplate.nLeakingProofProb
    SDCHelper.LOG("[Leaking] 区块默认漏水抗性：%f", nLeakingProofProb)
    nLeakingProofProb = nLeakingProofProb + (tbTakerPropCmpt:GetProp(PropName.nLeakingProofProb) - 1)
    SDCHelper.LOG("[Leaking] 加成后漏水抗性：%f", nLeakingProofProb)
    local nFinalLeakingProb = nLeakingProb - nLeakingProofProb
    local nRandomLeakingProb = math.random()
    local bLeakingResult = nRandomLeakingProb < nFinalLeakingProb
    SDCHelper.LOG("[Leaking] 漏水判定结束，最终漏水概率：%f，本次随机结果：%f，是否漏水：%s", nFinalLeakingProb, nRandomLeakingProb, (bLeakingResult and "是" or "否"))
    if bLeakingResult then
        tbTaker.BuffComponentServer:AddBuffWithInstigator(tbCauser, LEAKING_BUFF_ID)
    end
    return bLeakingResult
end

-- 处理点火
function SDCHelper.CheckBurning(tbCauser, tbTaker, tbWeaponTemplate, tbArmorTemplate)
    local tbCauserPropCmpt = tbCauser.ShipBattlePropertyComponent
    local tbTakerPropCmpt = tbTaker.ShipBattlePropertyComponent
    local nWeaponId = tbWeaponTemplate.nId
    local nWeaponSubCategory = tbWeaponTemplate.nSubCategory

    local nBurningProb = tbWeaponTemplate.nBurningProb
    SDCHelper.LOG("[Burning] 点火判定开始，武器默认点火率：%f", nBurningProb)
    if nBurningProb <= 0 then
        SDCHelper.LOG("[Leaking] 默认点火率<=0，跳过判定")
        return false
    end
    nBurningProb = nBurningProb + (tbCauserPropCmpt:GetProp(PropName.nBurningProb) - 1)
    local tbBurningProbInfo = tbCauserPropCmpt:GetProp(PropName.tbBurningProbInfo)
    if tbBurningProbInfo then
        if BaseUtil:ContainsByValue(tbBurningProbInfo.tbWeaponTypes, nWeaponSubCategory)
        or BaseUtil:ContainsByValue(tbBurningProbInfo.tbWeaponIds, nWeaponId) then
            nBurningProb = nBurningProb + tbBurningProbInfo.nValue
        end
    end
    SDCHelper.LOG("[Burning] 加成后点火率：%f", nBurningProb)
    local nBurningProofProb = tbArmorTemplate.nBurningProofProb
    SDCHelper.LOG("[Burning] 区块默认点火抗性：%f", nBurningProofProb)
    nBurningProofProb = nBurningProofProb + (tbTakerPropCmpt:GetProp(PropName.nBurningProofProb) - 1)
    SDCHelper.LOG("[Burning] 加成后点火抗性：%f", nBurningProofProb)
    local nFinalBurningProb = nBurningProb - nBurningProofProb
    local nRandomBurningProb = math.random()
    local bBurningResult = nRandomBurningProb < nFinalBurningProb
    SDCHelper.LOG("[Burning] 点火判定结束，最终点火概率：%f，本次随机结果：%f，是否点火：%s", nFinalBurningProb, nRandomBurningProb, (bBurningResult and "是" or "否"))
    if bBurningResult then
        tbTaker.BuffComponentServer:AddBuffWithInstigator(tbCauser, BURNING_BUFF_ID)
    end
    return bBurningResult
end

return SDCHelper