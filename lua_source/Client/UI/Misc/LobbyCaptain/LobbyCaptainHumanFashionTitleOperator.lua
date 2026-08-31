-----------------------------------------------------
--File Name    : LobbyCaptainHumanFashionTitleOperator.lua
--Description  :
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbyCaptainTitleOperator = require("LobbyCaptainTitleOperator")
local LobbyCaptainHumanFashionTitleOperator = luaclass("LobbyCaptainHumanFashionTitleOperator", LobbyCaptainTitleOperator)

local HumanAvatarHelper = require("HumanAvatarHelper")
local HumanAvatarDef = require("HumanAvatarDef")
local UITextDef = require("UITextDef")
local DescKeyParser             = require("DescKeyParser")
local DescKeyParserMiscDef      = require("DescKeyParserMiscDef")

local FASHION_ARMOR_NAME = UITextDef.FASHION_ARMOR_NAME

local FashionType = HumanAvatarDef.FashionType

local DESC_KEYS =
{
    "lobby_general_desc",
    "lobby_special_desc",
    "lobby_reduce_desc",
}

local BASIC_FASHION_KEYS = 
{
    "general_desc"
}


local function RefreshDescription(self, nFashionType)
    local tbDesc = {}
    if nFashionType ~= FashionType.Basic then
        local nArmorType = HumanAvatarHelper.FashionTypeToArmorType[nFashionType]
        local tbInputData = {}
        tbInputData.nArmorType = nArmorType
        for _, szKey in ipairs(DESC_KEYS) do
            local tbOutData = DescKeyParser.GetParseData(DescKeyParserMiscDef.NAME_SPACE_HUMAN_ARMOR, szKey, tbInputData)
            if tbOutData.bList then
                for _, l10nData in ipairs(tbOutData.tbDatas) do
                    table.insert(tbDesc, {l10nData})
                end
            else
                table.insert(tbDesc, {tbOutData.l10nData})
            end
        end
    else
        for _, szKey in ipairs(BASIC_FASHION_KEYS) do
            local tbOutData = DescKeyParser.GetParseData(DescKeyParserMiscDef.NAME_SPACE_HUMAN_MISC, szKey, nil)
            if tbOutData.bList then
                for _, l10nData in ipairs(tbOutData.tbDatas) do
                    table.insert(tbDesc, {l10nData})
                end
            else
                table.insert(tbDesc, {tbOutData.l10nData})
            end
        end
    end
    self.ListHelper:SetData(tbDesc)
end

local function RefreshTitle(self, nFashionType)
    self:SetTipTitle(FASHION_ARMOR_NAME[nFashionType])
end

function LobbyCaptainHumanFashionTitleOperator:OnTitleInfoSet(tbTitleInfo)
    local nFashionType = tbTitleInfo.nFashionType
    if nFashionType == FashionType.Basic then
        self:SetTitleVisible(false)
    else
        self:SetTitleText(FASHION_ARMOR_NAME[nFashionType])
        self:SetTitleVisible(true)
    end
end

function LobbyCaptainHumanFashionTitleOperator:OnTipShow(tbTitleInfo)
    local nFashionType = tbTitleInfo.nFashionType
    if nFashionType ~= FashionType.Basic then
        RefreshDescription(self, nFashionType)
        RefreshTitle(self, nFashionType)
    end
end


return LobbyCaptainHumanFashionTitleOperator