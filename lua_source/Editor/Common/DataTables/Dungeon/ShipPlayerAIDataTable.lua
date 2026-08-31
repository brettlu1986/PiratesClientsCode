local ShipPlayerAIDataTable = {}

local ShipCategory = require("ShipCategory")

ShipPlayerAIDataTable.szFileName = "common/dungeon/ship_player_ai.tab"


function ShipPlayerAIDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
end

function ShipPlayerAIDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    tbNewTemplate[ShipCategory.BattleShip] = Parser:Get("battle_ship", -1, Parser.TypeInt, true);
    tbNewTemplate[ShipCategory.Frigate] = Parser:Get("frigate", -1, Parser.TypeInt, true);
    tbNewTemplate[ShipCategory.Gunship] = Parser:Get("gun_ship", -1, Parser.TypeInt, true);
    return true;
end

-- [EXPORT BEGIN]
function ShipPlayerAIDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ShipPlayerAIDataTable:GetAIId(nID, nShipCategory)
    local tbTemplate = self.tbContainer[nID]
    if(tbTemplate) then
        return tbTemplate[nShipCategory]
    end
    return nil
end
-- [EXPORT END]

return ShipPlayerAIDataTable