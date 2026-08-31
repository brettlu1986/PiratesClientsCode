local UIResourceDef = require("UIResourceDef")
local BattleItemDataTable = require("BattleItemDataTable")

local BattleItemColorGradeHelper = { }

local tbCachedImage = {}

function BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
    local nColorGrade = BattleItemDataTable:GetColorGrade(nItemTemplateId)
    return UIResourceDef.ITEM_COLOR_GRADE_ICON[nColorGrade]
end

function BattleItemColorGradeHelper.GetCachedColorGradeImg(nItemTemplateId)
    local szImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
    if(szImg == nil) then
        return nil
    end

    local pRet = tbCachedImage[szImg]
    if(not isvalidhandle(pRet)) then
        pRet = szImg:load()
        tbCachedImage[szImg] = pRet
    end

    return pRet
end

return BattleItemColorGradeHelper