--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    tbContainer: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT] 
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]
local DungeonAITargetingDataTable = {}

-- [EXPORT]
local ShipCategory = require("ShipCategory")

DungeonAITargetingDataTable.szFileName = "common/npc/dungeon/targeting_priority.tab"

-- Key 是tab里的列，value是蓝图中的key
-- [EXPORT BEGIN]
local tbAITargetingMap = {}
tbAITargetingMap["BattleShip"] = "TargetingPriorityBattleShip"
tbAITargetingMap["Frigate"] = "TargetingPriorityFrigate"
tbAITargetingMap["GunShip"] = "TargetingPriorityGunShip"
-- [EXPORT END]

-- 列转Category
-- [EXPORT BEGIN]
local tbCategoryMap = {}
tbCategoryMap["BattleShip"] = ShipCategory.BattleShip
tbCategoryMap["Frigate"] = ShipCategory.Frigate
tbCategoryMap["GunShip"] = ShipCategory.Gunship
-- [EXPORT END]


-- 转完后的tbcontainer key是nCategory，value则是个以TargetingXXX为key，float为value的table

function DungeonAITargetingDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)    
    local szShipType = Parser:Get("ShipType", "", Parser.TypeString, true);
    for szColumnName, nTargetEnum in pairs(tbAITargetingMap) do
        tbNewTemplate[tbAITargetingMap[szColumnName]] = Parser:Get(szColumnName, 0, Parser.TypeFloat, true);        
    end

    tbContainer[tbCategoryMap[szShipType]] = tbNewTemplate
    return true;
end

-- [EXPORT BEGIN]
function DungeonAITargetingDataTable:GetTemplate(nCategory)
    return self.tbContainer[nCategory]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function DungeonAITargetingDataTable:ConvertToAITargetingDesc(szShipType)
    return tbAITargetingMap[szShipType]
end
-- [EXPORT END]

return DungeonAITargetingDataTable
