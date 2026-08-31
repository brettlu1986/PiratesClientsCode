-----------------------------------------------------
--File Name    : ULCreateRoleName.lua
--Author       : WuJizhou
--Create Time  : 4/23/2020, 8:39:05 PM
--Description  : ULCreateRoleName
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULCreateRoleName = luaclass("ULCreateRoleName", UILogicBase)

local L10N                      = require("L10N")
local PlayerNameIni             = require("PlayerNameIni")
local RandomNameTable           = require("RandomNameTable")
local UTF8NameValidatorHelper   = require("UTF8NameValidatorHelper")

local bNamedByUser = false


ULCreateRoleName.nGender = nil

local function GetRandomData(nSex, nMinLen, nMaxLen, bPostfix)
    local tbNameDatas = RandomNameTable:GetTemplate(nSex)
    local tbNames = {}
    for _,v in ipairs(tbNameDatas) do
        if bPostfix then
            if v.nPostfixLen > nMinLen and v.nPostfixLen <= nMaxLen then
                table.insert( tbNames, v )
            end
        else
            if v.nPrefixLen > nMinLen and v.nPrefixLen <= nMaxLen then
                table.insert( tbNames, v )
            end
        end
    end
    local nNameLen = #tbNames
    if nNameLen <= 0 then
        return nil
    end
    local nIndex = math.random(1, nNameLen)
    local szTemp = tbNames[nIndex]
    return szTemp
end

local function GetRandomName(nSex)
    local tbPrefix = GetRandomData(nSex, 0, PlayerNameIni.nMaxDisplayWidth, false)
    local nMinLen = (tbPrefix.nPrefixLen > PlayerNameIni.nMinDisplayWidth) and 0 or (PlayerNameIni.nMinDisplayWidth - tbPrefix.nPrefixLen)
    local tbPostfix = GetRandomData(nSex, nMinLen, PlayerNameIni.nMaxDisplayWidth - tbPrefix.nPrefixLen, true)

    if tbPostfix then
        return L10N:ToString(tbPrefix.l10nPrefix) .. L10N:ToString(tbPostfix.l10nPostfix)
    else
        return L10N:ToString(tbPrefix.l10nPrefix)
    end
end



local function RestrictMaxLength(self, szName)
    local tbNameValidator = self.tbNameValidator
    if not tbNameValidator then
        tbNameValidator = UTF8NameValidatorHelper:CreatePlayerNameValidator()
        self.tbNameValidator = tbNameValidator
    end
    local _, nIdx = tbNameValidator:GetLegalNameLength(szName, PlayerNameIni.nMaxDisplayWidth)
    return string.sub(szName, 1, nIdx)
end

local function OnUsernameCommit(self, l10nText)
    local szName = L10N:ToString(l10nText)
    local szText = RestrictMaxLength(self, szName)
    self.pWidgetRef.txtUserName:SetText(szText)
    bNamedByUser = true
end

local function OnTextChanged(self, l10nText)
    local szName = L10N:ToString(l10nText)
    local szText = RestrictMaxLength(self, szName)
    self.pWidgetRef.txtUserName:SetText(szText)
end

function ULCreateRoleName:RandomName()
    self.pWidgetRef.txtUserName:SetText(GetRandomName(self.nGender))
    bNamedByUser = false
end

function ULCreateRoleName:OnGenderChanged(nGender)
    self.nGender = nGender
    if not bNamedByUser then
        self:RandomName()
    end
end

function ULCreateRoleName:Init(nGender)
    self.nGender = nGender
    self:RandomName()
end


function ULCreateRoleName:GetName()
    return L10N:ToString(self.pWidgetRef.txtUserName:GetText())
end


----------life cycle----------
-- function ULCreateRoleName:OnCreate()
-- end

-- function ULCreateRoleName:OnDestroy()
-- end

-- function ULCreateRoleName:OnLoad()
-- end

-- function ULCreateRoleName:OnUnload()
-- end

-- function ULCreateRoleName:OnEnter()
-- end

-- function ULCreateRoleName:OnShow()
-- end

-- function ULCreateRoleName:OnHide()
-- end

-- function ULCreateRoleName:OnExit()
-- end

function ULCreateRoleName:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.txtUserName.OnTextChanged, self, OnTextChanged)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.txtUserName.OnTextCommitted, self, OnUsernameCommit)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnRandom.OnClicked, self, self.RandomName)
end

-- function ULCreateRoleName:OnUnbindEvent(EventHelper)
-- end

return ULCreateRoleName