local EquipTipHelper = {}

local EquipmentEffectsDataTable = require("EquipmentEffectsDataTable")
local EquipmentSetDataTable = require("EquipmentSetDataTable")
local ItemSystemOld = require("ItemSystemOld")
local ItemEquipmentDataTable = require("ItemEquipmentDataTable")
local UITextDef = require("UITextDef")
local ShipDataTable = require("ShipDataTable")
local L10N = require("L10N")

local CR_STRING = '\n'
local FONT_SIZE_FORMAT = '<text size="%d">%s</>'
local COLOR_STRING_FORMAT = '<text color="%s">%s</>'
local SET_EQUIP_TITLE_FORMAT = '%s (%d/%d)'
local PLACE_HOLDER_FONT_SIZE = 5
local PLACE_HOLDER_STRING = string.format(FONT_SIZE_FORMAT, PLACE_HOLDER_FONT_SIZE, " ")
local INACTIVE_SET_EQUIP_COLOR = '#959595ff'
local ACTIVE_SET_EQUIP_COLOR = '#aeff00ff'
local SET_EQUIP_TITLE_COLOR = '#aeff00ff'
local NORMAL_COLOR = '#d1c0a5'

local SPECIAL_DESC_COUNT = 2
local SET_DESC_COUNT = 2


local function AppendString(sz1, sz2)
    return sz1..sz2
end

local function EndWithCR(szText)
    if not szText then
        return ""
    end
    if szText == "" then
        return szText
    end
    return AppendString(szText, CR_STRING)
end


local function ColorString(szText, szColor)
    return string.format(COLOR_STRING_FORMAT, szColor, szText)
end

local function MakeBasicDesc(tbEffectTemplate)
    local szDesc = ""
    local szTbList = {}
    table.insert(szTbList, L10N:ToString(tbEffectTemplate.l10nBaseDesc))

    for idx = 1, SPECIAL_DESC_COUNT do
        local szSpecialDesc = L10N:ToString(tbEffectTemplate["l10nSpecialDesc"..idx])
        if szSpecialDesc ~= "" then
            table.insert(szTbList, szSpecialDesc)
        end
    end
    --local nListCount = #szTbList
    szDesc = table.concat( szTbList, CR_STRING)
    -- if nListCount > 0 then
    --     for idx = 1, nListCount do
    --         if idx ~= nListCount then
    --             szDesc = AppendString(szDesc, EndWithCR(szTbList[idx]))
    --         else
    --             szDesc = AppendString(szDesc, szTbList[idx])
    --         end
    --     end
    -- end
    return szDesc
end

local function MakeShipDesc(tbEquipTemplate)
    local nGrade = tbEquipTemplate.nShipGrade
    if nGrade <= 0 then
        nGrade = 1
    end
    local szGrade = ShipDataTable:GetGradeNameByGrade(nGrade)
    local l10nGrade = L10N:Format(UITextDef.L10N_EQUIP_MATCH_GRADE,szGrade)
    szGrade = L10N:ToString(l10nGrade)
    szGrade = ColorString(szGrade, NORMAL_COLOR)
    return szGrade
end

local function MakeExtraDesc(tbEffectTemplate)
    local szDesc = L10N:ToString(tbEffectTemplate.l10nExtraDesc)

    return szDesc
end

--套装属性
local function MakeEquipSetDesc(tbEquipSetTemplate, nShipInstanceId, bSelected)
    if tbEquipSetTemplate == nil then
        return ""
    end

    --重组数据，方便下面判断
    local tbSelectedEquipMap = {}
    if nShipInstanceId ~= nil then
        local ItemComponentOld = ItemSystemOld:GetSelfItemComponent()
        local EquipRoom = ItemComponentOld:GetShipEquipmentRoom(nShipInstanceId)
        local tbSelectedEquips = EquipRoom:GetItemList()
        for i, Equip in ipairs(tbSelectedEquips) do
            tbSelectedEquipMap[Equip.tbTemplate.nDetailType] = Equip
        end
    end
    local tbSetEquipList = tbEquipSetTemplate.tbEquipments

    -- 套装分件名字是否激活的判定和字符生成
    local nTotalCount = #tbSetEquipList
    local nCount = 0
    local szSetDesc = ""
    for i, EquipInSet in ipairs(tbSetEquipList) do
        local tbEquipTemplate = ItemEquipmentDataTable:GetTemplate(EquipInSet.nGenre,EquipInSet.nDetailType,EquipInSet.nParticular)
        local szSetEquipName = L10N:ToString(tbEquipTemplate.l10nName)
        if (not bSelected) then
            szSetEquipName = ColorString(szSetEquipName, INACTIVE_SET_EQUIP_COLOR)
        else
            local nDetailType = EquipInSet.nDetailType
            local selectedEquip = tbSelectedEquipMap[nDetailType]
            if selectedEquip ~= nil then
                if selectedEquip.tbTemplate.nParticular == EquipInSet.nParticular then
                    nCount = nCount + 1
                    szSetEquipName = ColorString(szSetEquipName, ACTIVE_SET_EQUIP_COLOR)
                else
                    szSetEquipName = ColorString(szSetEquipName, INACTIVE_SET_EQUIP_COLOR)
                end
            else
                szSetEquipName = ColorString(szSetEquipName, INACTIVE_SET_EQUIP_COLOR)
            end
        end

        szSetDesc = AppendString(szSetDesc, EndWithCR(szSetEquipName))
    end
    -- 套装名及数量的字符生成
    local szTitle = string.format(SET_EQUIP_TITLE_FORMAT, L10N:ToString(tbEquipSetTemplate.l10nName), nCount,nTotalCount)
    szTitle = ColorString(szTitle, SET_EQUIP_TITLE_COLOR)

    -- 套装属性的字符生成
    local szSetAttriDesc = ""
    for idx = 1,SET_DESC_COUNT do
        local nCountMatch = tbEquipSetTemplate["nCount"..idx]
        if nCountMatch > 0 then
            local szCountMatchDesc = L10N:ToString(tbEquipSetTemplate["l10nCount"..idx.."Desc"])
            if not bSelected then
                szCountMatchDesc = ColorString(szCountMatchDesc, INACTIVE_SET_EQUIP_COLOR)
            elseif nCount >= nCountMatch then
                szCountMatchDesc = ColorString(szCountMatchDesc, ACTIVE_SET_EQUIP_COLOR)
            else
                szCountMatchDesc = ColorString(szCountMatchDesc, INACTIVE_SET_EQUIP_COLOR)
            end
            if idx ~= SET_DESC_COUNT then
                szSetAttriDesc = AppendString(szSetAttriDesc, EndWithCR(szCountMatchDesc))
            else
                szSetAttriDesc = AppendString(szSetAttriDesc, szCountMatchDesc)
            end
        end
    end

    szSetDesc = AppendString(EndWithCR(szTitle), szSetDesc)
    szSetDesc = AppendString(szSetDesc, szSetAttriDesc)

    return szSetDesc
end


local function MakeBackgroundDesc(tbEquipTemplate)
    local szDesc = L10N:ToString(tbEquipTemplate.l10nBackground)
    return szDesc
end


local function CheckAndMakeFinalDesc(tbDesc, szDesc, n)
    if szDesc ~= "" then
        table.insert(tbDesc,szDesc)
        local szPlaceHolder = AppendString(CR_STRING, EndWithCR(PLACE_HOLDER_STRING))
        table.insert(tbDesc, szPlaceHolder)
    end
end

function EquipTipHelper:GetDesc(tbTemplate, nShipInstanceId, bSelected)
    local nEffectId = tbTemplate.nEquipEffect
    local tbEffectTemplate = EquipmentEffectsDataTable:GetTemplate(nEffectId)
    local nSetId = tbTemplate.nSetId

    local szBasicDesc = MakeBasicDesc(tbEffectTemplate)
    local szShipDesc = MakeShipDesc(tbTemplate)
    local szExtraDesc = MakeExtraDesc(tbEffectTemplate)
    local tbEquipSetTemplate = EquipmentSetDataTable:GetTemplate(nSetId)
    local szSetDesc = MakeEquipSetDesc(tbEquipSetTemplate, nShipInstanceId, bSelected)
    local szBgDesc = MakeBackgroundDesc(tbTemplate)

    local tbDesc = {}

    CheckAndMakeFinalDesc(tbDesc, szBasicDesc,1)
    CheckAndMakeFinalDesc(tbDesc, szShipDesc,2)
    CheckAndMakeFinalDesc(tbDesc, szExtraDesc,3)
    CheckAndMakeFinalDesc(tbDesc, szSetDesc,4)
    CheckAndMakeFinalDesc(tbDesc, szBgDesc,5)

    local nCount = #tbDesc
    if tbDesc[nCount] == AppendString(CR_STRING, EndWithCR(PLACE_HOLDER_STRING)) then
        table.remove(tbDesc)
    end
    local szDesc = table.concat(tbDesc)

    return szDesc
end
return EquipTipHelper
