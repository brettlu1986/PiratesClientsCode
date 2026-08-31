--------------------------------------------------------------------------
--
--                            L10N.lua
--
--------------------------------------------------------------------------
local L10N = {}

local FormatText = ExtendBlueprintFunctions.FormatText
local FormatTextByName = ExtendBlueprintFunctions.FormatTextByName
local Conv_TextToString = KismetTextLibrary.Conv_TextToString

L10N.NullString = {
    szNamespace = "",
    szKey = "",
    szSourceText = ""
}

-- 从 Hard code 文本生成 FText
-- 出于策划配置方便，已废弃此接口
function L10N:MakeText(szNamespace, szKey, szSourceText)
    local LocTextTable = {}
    LocTextTable.szNamespace = szNamespace
    LocTextTable.szKey = szKey
    LocTextTable.szSourceText = szSourceText
    return LocTextTable
end

-- 通过变量名占位格式化 FText 文本（推荐）
-- 使用 FormatNamedArguments 形式，使用 {name} {age} .. 等带语义name作为占位符
function L10N:FormatByName(l10nFormat, tbNames, tbArgs)
    if (not tbNames) or (not tbArgs) then
        logerror("L10N:FormatByName() error!")
        return L10N.NullString
    end
    if #tbNames ~= #tbArgs then
        logerror("L10N:FormatByName() error, param length is not equal!")
        return L10N.NullString
    end
    return FormatTextByName(l10nFormat, tbNames, tbArgs)
end

-- 通过数字占位格式化 FText 文本（不推荐）
-- 使用 FormatOrderedArguments 形式，使用 {0} {1} .. 等作为占位符，占位符中的数字对应参数顺序，从0开始
function L10N:Format(l10nFormat, ...)
    local tbArgs = {...}
    return self:FormatFromTable(l10nFormat, tbArgs)
end

-- 通过数字占位格式化 FText 文本（不推荐）
-- 使用 FormatOrderedArguments 形式，使用 {0} {1} .. 等作为占位符，占位符中的数字对应参数顺序，从0开始
-- 相较于L10N:Format，FormatFromTable传入的参数为直接的Table，仅此而已
function L10N:FormatFromTable(l10nFormat, tbArgs)
    if not tbArgs then
        logerror("L10N:FormatFromTable() error!")
        return L10N.NullString
    end
    return FormatText(l10nFormat, tbArgs)
end

function L10N:ToString(l10nText)
    return Conv_TextToString(l10nText)
end

return L10N

