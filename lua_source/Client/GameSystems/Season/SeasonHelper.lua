local UIResourceDef = require("UIResourceDef")

local SeasonHelper = {}

local RANK_SUB_IMAGE = {
    UIResourceDef.RANK_SUB_IMAGES1,
    UIResourceDef.RANK_SUB_IMAGES2,
    UIResourceDef.RANK_SUB_IMAGES1,
    UIResourceDef.RANK_SUB_IMAGES2,
    UIResourceDef.RANK_SUB_IMAGES2,
    UIResourceDef.RANK_SUB_IMAGES1,
    UIResourceDef.RANK_SUB_IMAGES1
}

local RANK_SUB_ICON = {
    UIResourceDef.RANK_SUB_ICON1,
    UIResourceDef.RANK_SUB_ICON2,
    UIResourceDef.RANK_SUB_ICON1,
    UIResourceDef.RANK_SUB_ICON2,
    UIResourceDef.RANK_SUB_ICON2,
    UIResourceDef.RANK_SUB_ICON1,
    UIResourceDef.RANK_SUB_ICON1
}

local RANK_SUB_MAX = 5

local function TransformationSubRank(nSubRank)
    if nSubRank == 0 then
        return nSubRank
    else
        return RANK_SUB_MAX - nSubRank + 1
    end
end

local function GetSubAndMainRank(nRank)
    local nSubRank = math.fmod(nRank, 10)
    nSubRank = TransformationSubRank(nSubRank)
    nSubRank = math.min(nSubRank, RANK_SUB_MAX)
    local nMainRank = math.modf(nRank / 10)
    return nSubRank, nMainRank
end

function SeasonHelper.GetImage(nRank)
    local nSubRank, nMainRank = GetSubAndMainRank(nRank)

    local szSubImage
    if nSubRank > 0 then
        if RANK_SUB_IMAGE[nMainRank] ~= nil then
            szSubImage = RANK_SUB_IMAGE[nMainRank][nSubRank]
        else
            logerror("SeasonHelper.GetImage ", nRank, nMainRank)
        end
    end
    return UIResourceDef.RANK_IMAGES[nMainRank], UIResourceDef.RANK_BG_IMAGES[nMainRank], szSubImage
end

function SeasonHelper.GetIcon(nRank)
    local nSubRank, nMainRank = GetSubAndMainRank(nRank)
    local szSubIcon
    if nSubRank > 0 then
        if RANK_SUB_ICON[nMainRank] ~= nil then
            szSubIcon = RANK_SUB_ICON[nMainRank][nSubRank]
        else
            logerror("SeasonHelper.GetIcon ", nRank, nMainRank)
        end
    end
    return UIResourceDef.RANK_ICONS[nMainRank], szSubIcon
end

function SeasonHelper:GetRank(nRank)
    return GetSubAndMainRank(nRank)
end

return SeasonHelper