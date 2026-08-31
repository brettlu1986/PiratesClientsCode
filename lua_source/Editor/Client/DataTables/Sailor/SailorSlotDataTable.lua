local SailorSlotDataTable = {}

-- [EXPORT BEGIN]
local INVALID_ID = -1
SailorSlotDataTable.RECOMMENDED_SAILOR_SUIT_COUNT = 3
-- [EXPORT END]


SailorSlotDataTable.szFileName = "common/item2/sub/sailor/sailor_slot.tab"
SailorSlotDataTable.bEnableIterateKey = true

function SailorSlotDataTable:OnEditorParseBegin()
    self.tbContainer.tbPrices = {{},{},{}}
    self.tbContainer.tbUnlockGrades = {{},{},{}}
    self.tbContainer.tbRecommendedSailorIds = {}
    for i=0, SailorSlotDataTable.RECOMMENDED_SAILOR_SUIT_COUNT do
        self.tbContainer.tbRecommendedSailorIds[i] = {{},{},{}}
    end
end

function SailorSlotDataTable:OnEditorParseLine(Parser, tbContainer)
    local nCategory             = Parser:Get("category"             , 1         , Parser.TypeInt)
    local nSlotIndex            = Parser:Get("slot_index"           , 1         , Parser.TypeInt)
    local nUnlockGrade          = Parser:Get("unlock_grade"         , 1         , Parser.TypeInt)
    local nPrice                = Parser:Get("price"                , 1         , Parser.TypeInt)
    local nCurrencyId           = Parser:Get("currency_id"          , 1         , Parser.TypeInt)

    tbContainer.tbPrices[nCategory][nSlotIndex] = {nCurrencyId = nCurrencyId, nPrice = nPrice}
    tbContainer.tbUnlockGrades[nCategory][nSlotIndex] = nUnlockGrade
    for nSuitId=0, SailorSlotDataTable.RECOMMENDED_SAILOR_SUIT_COUNT do
        local nRecommendedSailorId  = Parser:Get("recommended_sailor_id_" .. nSuitId, INVALID_ID, Parser.TypeInt)
        tbContainer.tbRecommendedSailorIds[nSuitId][nCategory][nSlotIndex] = nRecommendedSailorId
    end
    return true
end

-- [EXPORT BEGIN]
-- 获取指定等级解锁的槽位列表
--[[
    {
        [SailorCategoryDef.Cannon] = {1, 2},
        [SailorCategoryDef.Deck] = {1, 2},
        [SailorCategoryDef.Logistics] = {1, 2}
    }
]]
function SailorSlotDataTable:GetUnlockedSlotInfoByGrade(nGrade)
    local tbUnlockedSlotList = {{},{},{}}
    for nCategory,v in ipairs(self.tbContainer.tbUnlockGrades) do
        for nSlotIndex,nUnlockGrade in ipairs(v) do
            if nUnlockGrade == nGrade then
                tbUnlockedSlotList[nCategory] = tbUnlockedSlotList[nCategory]
                table.insert(tbUnlockedSlotList[nCategory], nSlotIndex)
            end
        end
    end
    return tbUnlockedSlotList
end

-- 获取指定水手槽位解锁价格
function SailorSlotDataTable:GetSlotPrice(nCategory, nSlotIndex)
    return self.tbContainer.tbPrices[nCategory][nSlotIndex]
end

-- 获取指定槽位默认解锁等级
function SailorSlotDataTable:GetSlotUnlockGrade(nCategory, nSlotIndex)
    return self.tbContainer.tbUnlockGrades[nCategory][nSlotIndex]
end

-- 获取一键上阵时槽位推荐的水手id
function SailorSlotDataTable:GetRecommendedSailorId(nSuitId, nCategory, nSlotIndex)
    return self.tbContainer.tbRecommendedSailorIds[nSuitId][nCategory][nSlotIndex] or INVALID_ID
end
-- [EXPORT END]

return SailorSlotDataTable
