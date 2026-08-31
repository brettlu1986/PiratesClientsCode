-----------------------------------------------------
--File Name    : HumanWeaponFashionDataTable.lua
--Author       : WuJizhou
--Create Time  : 5/14/2020, 8:57:33 PM
--Description  : HumanWeaponFashionDataTable
-----------------------------------------------------
local HumanWeaponFashionDataTable = {}


HumanWeaponFashionDataTable.szFileName = "common/item2/sub/fashion/human_weapon_fashions.tab"


function HumanWeaponFashionDataTable:OnEditorDefine(Parser)
    Parser:Define("nFashionId",       "fashion_id",         -1,  Parser.TypeInt)
    Parser:Define("nLevel",           "level",              "",  Parser.TypeInt)
    Parser:Define("nTrunkPartId",     "trunk_part_id",      "",  Parser.TypeInt)
    Parser:Define("szIcon",           "icon",               "",  Parser.TypeString)
end

function HumanWeaponFashionDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nFashionId = tbNewTemplate.nFashionId
    local tbLevelMap = tbContainer[nFashionId]
    if not tbLevelMap then
        tbLevelMap = {}
        tbContainer[nFashionId] = tbLevelMap
    end
    local nLevel = tbNewTemplate.nLevel
    if tbLevelMap[nLevel] then
        error(string.format("level already exist! the fashion id is %d, level is %d", nFashionId, nLevel))
        return
    end
    tbLevelMap[nLevel] = tbNewTemplate
    return true
end

-- [EXPORT BEGIN]
--返回指定id的指定等级的template，如果该等级不存在，则返回最接近等级的配置
function HumanWeaponFashionDataTable:GetFashionTemplate(nFashionId, nLevelIfExist)
    local tbLevelMap = self.tbContainer[nFashionId]
    local tbResult
    if tbLevelMap and nLevelIfExist then
        while nLevelIfExist > 0 do
            tbResult = tbLevelMap[nLevelIfExist]
            if tbResult then
                return tbResult
            end
            nLevelIfExist = nLevelIfExist - 1
        end
    end
    return {}
end

-- [EXPORT END]

return HumanWeaponFashionDataTable