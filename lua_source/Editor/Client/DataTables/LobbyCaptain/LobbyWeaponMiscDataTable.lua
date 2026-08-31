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
local LobbyWeaponMiscDataTable = {}

local L10N          = require("L10N")
local StringUtil    = require("StringUtil")


local DisplayKey =
{
    UICaptain = "ui_captain",
    UISeason  = "ui_season"
}

local DisplayMiscDataField =
{
    Location = "tbLocation",    -- field : {nX, nY, nZ}
    Rotation = "tbRotation",    -- field : {nX, nY, nZ}
    Scale    = "nScale",        -- field : nScale

}

-- [EXPORT]
LobbyWeaponMiscDataTable.DisplayKey = DisplayKey
-- [EXPORT]
LobbyWeaponMiscDataTable.DisplayMiscDataField = DisplayMiscDataField

local tbSubKeys = {}
tbSubKeys["location"] = function (Parser, szColumnName, tbOutData)
    local szLocation = Parser:Get(szColumnName, "", Parser.TypeString,  false)
    local tbData = StringUtil.Split(szLocation, ",")
    local tbLocation
    if #tbData == 3 then
        tbLocation = {}
        for _, szValue in ipairs(tbData) do
            local nValue = StringUtil.ToNumber(szValue)
            table.insert(tbLocation, nValue)
        end
        -- else
        --     tbLocation = {0, 0, 0}
    end
    tbOutData[DisplayMiscDataField.Location] = tbLocation
end

tbSubKeys["rotation"] = function (Parser, szColumnName, tbOutData)
    local szRotation = Parser:Get(szColumnName, "", Parser.TypeString,  false)
    local tbData = StringUtil.Split(szRotation, ",")
    local tbRotation
    if #tbData == 3 then
        tbRotation = {}
        for _, szValue in ipairs(tbData) do
            local nValue = StringUtil.ToNumber(szValue)
            table.insert(tbRotation, nValue)
        end
    else
        tbRotation = {0, 0, 0}
    end
    tbOutData[DisplayMiscDataField.Rotation] = tbRotation
end

tbSubKeys["scale"] = function (Parser, szColumnName, tbOutData)
    local nScale = Parser:Get(szColumnName, 1, Parser.TypeInt,  false)
    tbOutData[DisplayMiscDataField.Scale] = nScale
end

local tbAllKeys = nil

local function ParseKeys(self, Parser)
    if not tbAllKeys then
        local tbCurrentKeys = Parser:GetCurrentKeys()
        tbAllKeys = {}
        for szKeyName, nIndex in pairs(tbCurrentKeys) do
            tbAllKeys[nIndex] = szKeyName
        end
    end
end

LobbyWeaponMiscDataTable.szFileName = "client/lobbycaptain/lobby_weapon_misc.tab"

function LobbyWeaponMiscDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nWeaponInstanceType")
    Parser:Define("nWeaponInstanceType",    "weapon_instance_type",         -1,                 Parser.TypeInt)
    Parser:Define("szIcon",                 "icon",                         "",                 Parser.TypeString)
    Parser:Define("szSocketName",           "socket_name",                  "",                 Parser.TypeString)
    Parser:Define("szWeaponCenterSocket",   "weapon_center_socket_name",    "",                 Parser.TypeString)
    Parser:Define("szAnimKey",              "anim_key",                     "",                 Parser.TypeString)
    Parser:Define("l10nDesc",               "desc",                         L10N.NullString,    Parser.TypeL10N)
    Parser:Define("l10nGeneralDesc",        "lobby_general_desc",           L10N.NullString,    Parser.TypeL10N)
    Parser:Define("l10nSpecialDesc",        "lobby_special_desc",           L10N.NullString,    Parser.TypeL10N)
    Parser:Define("bActive",                "active",                       true,               Parser.TypeBool)
end

function LobbyWeaponMiscDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    ParseKeys(self, Parser)
    for _nIndex, szColumnName in pairs(tbAllKeys) do
        for _, szDisplayKey in pairs(DisplayKey) do
            if string.find(szColumnName, szDisplayKey) then
                local tbMiscDisplayData = tbNewTemplate[szDisplayKey]
                if not tbMiscDisplayData then
                    tbMiscDisplayData = {}
                    tbNewTemplate[szDisplayKey] = tbMiscDisplayData
                end
                for szSubkey, fnSubParser in pairs(tbSubKeys) do
                    if string.find(szColumnName, szSubkey) then
                        fnSubParser(Parser, szColumnName, tbMiscDisplayData)
                    end
                end
            end
        end
    end
    return true
end


-- [EXPORT BEGIN]


function LobbyWeaponMiscDataTable:GetTemplate(nWeaponInstanceType)
    return self.tbContainer[nWeaponInstanceType]
end


function LobbyWeaponMiscDataTable:GetDisplayMiscData(nWeaponInstanceType, szDisplayKey)
    return self.tbContainer[nWeaponInstanceType][szDisplayKey]
end

function LobbyWeaponMiscDataTable:GetAllTemplates()
    return self.tbContainer
end

-- [EXPORT END]

return LobbyWeaponMiscDataTable