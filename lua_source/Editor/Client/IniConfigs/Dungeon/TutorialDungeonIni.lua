--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local Ini = {}

local L10N = require("L10N")

Ini.szFileName = "client/dungeon/tutorial_dungeon.ini"

local function AddPreparation(self, tbPreparation)
    for _, v in ipairs(tbPreparation) do
        table.insert(self.tbPreparation, v)
    end
end

function Ini:OnParse(Parser)
    self.bEnabled = Parser:Get("dungeon", "enable", false, Parser.TypeBool)
    self.nDungeonId = Parser:Get("dungeon", "dungeon_id", -1, Parser.TypeNumber)
    self.l10nDisplayName = Parser:Get("dungeon", "player_display_name", L10N.NullString, Parser.TypeL10N)
    self.nHumanId = Parser:Get("dungeon", "human_id_when_born", -1, Parser.TypeNumber)
    local tbPreparationShip = Parser:Get("preparation", "ship", {}, Parser.TypeArrayNumber)
    local tbPreparationShipWeapon = Parser:Get("preparation", "ship_weapon", {}, Parser.TypeArrayNumber)
    local tbPreparationShipPart = Parser:Get("preparation", "ship_part", {}, Parser.TypeArrayNumber)
    self.tbPreparation = {}
    AddPreparation(self, tbPreparationShip)
    AddPreparation(self, tbPreparationShipWeapon)
    AddPreparation(self, tbPreparationShipPart)
    return true
end

return Ini
