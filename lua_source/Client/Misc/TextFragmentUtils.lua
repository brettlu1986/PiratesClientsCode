local TextFragmentUtils = {}
local L10N = require("L10N")
local ClientProtoNames = require("ClientProtoNames")
local Type = ClientProtoNames.TextFragment_Type

local SceneDataTable = require("SceneDataTable")
local NpcDataTable = require("NPCDataTable")
local QuestInfoDataTable = require("QuestInfoDataTable")
local ItemSystemOld = require("ItemSystemOld")
local DialogTextDataTable = require("DialogTextDataTable")
local ToastTextDataTable = require("ToastTextDataTable")
local MiscTextDataTable = require("MiscTextDataTable")
local ShipDataTable = require("ShipDataTable")
local CameraShotSystem = require("CameraShotSystem")

local function ParseTypeRaw( TextFragment )
    return L10N:MakeText("", "", TextFragment.raw_text)
end

local function ParseTypeScene( TextFragment )
    local tbTemplate = SceneDataTable:GetTemplate(TextFragment.id)
    if tbTemplate then
        return L10N:ToString(tbTemplate.l10nName)
    end
    return L10N.NullString
end

local function ParseTypeNpc( TextFragment )
    local tbTemplate = NpcDataTable:GetTemplate(TextFragment.id)
    if tbTemplate then
        return L10N:ToString(tbTemplate.l10nName)
    end
    return L10N.NullString
end

local function ParseTypeQuestInfoTitle( TextFragment )
    local tbTemplate = QuestInfoDataTable:GetTemplate(TextFragment.id)
    if tbTemplate then
        return tbTemplate.szQuestTitle
    end
    return L10N.NullString
end

local function ParseTypeSubQuestTitle( TextFragment )
    local tbTemplate = QuestInfoDataTable:GetTemplate(TextFragment.id)
    if tbTemplate then
        return tbTemplate.szSubQuestTitle
    end
    return L10N.NullString
end

local function ParseTypeSubQuestDesc( TextFragment )
    local tbTemplate = QuestInfoDataTable:GetTemplate(TextFragment.id)
    if tbTemplate then
        return tbTemplate.szSubQuestDesc
    end
    return L10N.NullString
end

local function ParseTypeItem( TextFragment )
    local nGenre = TextFragment.id & 0xFF
    local nDetailType = (TextFragment.id & 0xFF00) >> 8
    local nParticular = (TextFragment.id & 0xFFFF0000) >> 16
    local tbItem = ItemSystemOld:GetItemTemplate(nGenre, nDetailType, nParticular)
    if tbItem ~= nil then
        return tbItem.l10nName
    end
    log.warning("ITEM NOT FOUND "..nGenre..", "..nDetailType..", "..nParticular)
    return L10N.NullString
end

local function ParseDialog( TextFragment )
    return DialogTextDataTable:GetText(TextFragment.id)
end

local function ParseToast( TextFragment )
    return ToastTextDataTable:GetText(TextFragment.id)
end

local function ParseMisc( TextFragment )
    return MiscTextDataTable:GetText(TextFragment.id)
end

local function ParseInteger( TextFragment )
    return TextFragment.id
end

local function ParseShip( TextFragment )
    local tbTemplate = ShipDataTable:GetTemplate(TextFragment.id)
    if tbTemplate then
        return tbTemplate.l10nName
    end
    return L10N.NullString
end

local function ParseCameraTarget( TextFragment )
    local nTargetId = TextFragment.id
    local nTargetSceneId = nTargetId & 0x1FFFF
    local nRealTargetId = nTargetId >> 17
    local szTargetName = CameraShotSystem:GetTargetName(nTargetSceneId, nRealTargetId)
    if szTargetName then
        return L10N:MakeText("CameraShot", tostring(nRealTargetId), szTargetName)
    else
        return L10N.NullString
    end
end

local Converter = {
    [Type.RAW] = ParseTypeRaw,
    [Type.SCENE] = ParseTypeScene,
    [Type.NPC] = ParseTypeNpc,
    [Type.QUEST_INFO_TITLE] = ParseTypeQuestInfoTitle,
    [Type.SUB_QUEST_TITLE] = ParseTypeSubQuestTitle,
    [Type.SUB_QUEST_DESC] = ParseTypeSubQuestDesc,
    [Type.ITEM] = ParseTypeItem,
    [Type.DIALOG] = ParseDialog,
    [Type.TOAST] = ParseToast,
    [Type.MISC] = ParseMisc,
    [Type.INTEGER] = ParseInteger,
    [Type.SHIP] = ParseShip,
    [Type.CAMERA_TARGET] = ParseCameraTarget,
}

function TextFragmentUtils:ParseTextFragment( TextFragment )
    local fnConverter = Converter[TextFragment.type]
    if fnConverter then
        return fnConverter(TextFragment)
    end
    return L10N.NullString
end

function TextFragmentUtils:ParseText( Text )
    local l10nFormat = self:ParseTextFragment(Text.format)
    local tbArgs = {}
    for i,v in ipairs(Text.args) do
        tbArgs[i] = self:ParseTextFragment(v)
    end

    return L10N:FormatFromTable(l10nFormat, tbArgs)
end

function TextFragmentUtils:ParseFormatText(l10nFormat, tbTextArgs)
    if not tbTextArgs then
        return l10nFormat
    end

    local tbArgs = {}
    for i,v in ipairs(tbTextArgs) do
        tbArgs[i] = self:ParseText(v)
    end

    return L10N:FormatFromTable(l10nFormat, tbArgs)
end

return TextFragmentUtils
