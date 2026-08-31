local luaclass = require("luaclass")
local SettingBase = require("SettingBase")
local SettingLayout = luaclass("SettingLayout", SettingBase)

--local SettingKeyDef = require("SettingKeyDef")
local SettingLayoutDefaultDataTable = require("SettingLayoutDefaultDataTable")
local SettingLayoutDataTable = require("SettingLayoutDataTable")
local SettingIni = require("SettingIni")
local SettingLayoutFromDef = require("SettingLayoutFromDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local ClientEventDef = require("ClientEventDef")
local UISetUtils = require("UISetUtils")
local UIUtils = require("UIUtils")
local BaseUtil = require("BaseUtil")
local ScreenShapeHelper = require("ScreenShapeHelper")

--local RemoteKeys = SettingKeyDef.RemoteKeys

local X_BIT_OFFSET = 23
local Y_BIT_OFFSET = 22
local SCALE_BIT_OFFSET = 5
local ALPHA_BIT_OFFSET = 4
local LAYOUT_KEY_START = 1000
local LAYOUT_COMMON_KEY_START_OFFSET = 500
local LAYOUT_KEY_FROM_LENGTH = 100

local ALPHA_MAX = SettingIni.tbLayout.nAlphaMax
local ALPHA_MIN = SettingIni.tbLayout.nAlphaMin
local SCALE_MAX = SettingIni.tbLayout.nScaleMax
local SCALE_MIN = SettingIni.tbLayout.nScaleMin

local MAX_STYLE = 2
local LAYOUT_SAVE_SUCCESSED = UISetUtils.GetL10NTextByKey("LAYOUT_SAVE_SUCCESSED")
local LAYOUT_RESET_SUCCESSED = UISetUtils.GetL10NTextByKey("LAYOUT_RESET_SUCCESSED")

SettingLayout.tbAllLayout = {}
SettingLayout.tbAllDefaultLayout = {}
SettingLayout.nXMask = nil
SettingLayout.nYMask = nil
SettingLayout.nScaleMask = nil
SettingLayout.nAlphaMask = nil

local function GetMask(nBit)
    local nMask = 1
    local nCurrentMask = 1
    for i = 1, nBit do
        nMask = nCurrentMask | 1
        nCurrentMask = nMask << 1
    end
    return nMask
end

local function GetRoundInteger(nNumber)
    local nIntegralPart, nFractionalPart = math.modf(nNumber)
    local nSymbol = nNumber >= 0.0 and 1 or -1
    return math.abs(nFractionalPart) >= 0.5 and (nIntegralPart + 1 * nSymbol) or nIntegralPart
end

local function GetLayoutFromByRemoteId(self, nStyle, nRemoteId)
    local nLocalId = nRemoteId - nStyle * LAYOUT_KEY_START
    local nFrom = nil
    if nLocalId > LAYOUT_COMMON_KEY_START_OFFSET then
        nFrom = math.floor((nLocalId - LAYOUT_COMMON_KEY_START_OFFSET) / LAYOUT_KEY_FROM_LENGTH)
    elseif nLocalId >= 100 then
        nFrom = math.floor(nLocalId / LAYOUT_KEY_FROM_LENGTH)
    end
    return nFrom
end

local function CommonLocalIdToRemoteId(nStyle, nFrom, nLocalId)
    return nStyle * LAYOUT_KEY_START + LAYOUT_COMMON_KEY_START_OFFSET + nFrom * LAYOUT_KEY_FROM_LENGTH + nLocalId
end

local function CommonRemoteIdToLocalId(nStyle, nFrom, nRemoteId)
     return (nRemoteId - nStyle * LAYOUT_KEY_START - LAYOUT_COMMON_KEY_START_OFFSET) - nFrom * LAYOUT_KEY_FROM_LENGTH
end

local function CreateLayoutData(nX, nY, nAlpha, nScale, nFrom, tbTemplate)
    local tbLayoutData = {}
    tbLayoutData.nX = nX
    tbLayoutData.nY = nY
    tbLayoutData.nAlpha = nAlpha
    tbLayoutData.nScale = nScale
    tbLayoutData.nFrom = nFrom
    tbLayoutData.tbTemplate = tbTemplate
    return tbLayoutData
end

local function ParseRemoteData(self, nValue)
    --alpha
    local nAlpha = math.min(ALPHA_MAX, math.max(ALPHA_MIN, (nValue & self.nAlphaMask) / 10))
    nValue = nValue >> ALPHA_BIT_OFFSET
    --scale
    local nScale = math.min(SCALE_MAX, math.max(SCALE_MIN, (nValue & self.nScaleMask) / 10))
    nValue = nValue >> SCALE_BIT_OFFSET
    --y
    local nSymbol = (nValue >> (Y_BIT_OFFSET - 1)) & 1
    nSymbol = nSymbol == 0 and 1 or -1
    local nY = (nValue & self.nYMask) * nSymbol
    --x
    nValue = nValue >> Y_BIT_OFFSET
    nSymbol = (nValue >> (X_BIT_OFFSET - 1)) & 1
    nSymbol = nSymbol == 0 and 1 or -1
    local nX = (nValue & self.nXMask) * nSymbol

    return nX, nY, nAlpha, nScale
end

local function MakeValue(self, nX, nY, nScale, nAlpha)
    local nValue = 0
    --x
    local nSymbol = nX >= 0.0 and 0 or 1
    nSymbol = nSymbol << (X_BIT_OFFSET - 1)
    nValue = (math.abs(nX) | nSymbol) << (Y_BIT_OFFSET + SCALE_BIT_OFFSET + ALPHA_BIT_OFFSET)
    --y
    nSymbol = nY >= 0.0 and 0 or 1
    nSymbol = nSymbol << (Y_BIT_OFFSET - 1)
    nValue = nValue | ((math.abs(nY) | nSymbol) << (SCALE_BIT_OFFSET + ALPHA_BIT_OFFSET))
    --scale
    nValue = nValue | (GetRoundInteger(nScale * 10) << ALPHA_BIT_OFFSET)
    --alpha
    nValue = nValue | GetRoundInteger(nAlpha * 10)
    return nValue
end

local function LoadRemoteSettingFrom(self, nStyle, nFrom)
    local Owner = self.Owner
    local tbLayoutStyle = self.tbAllLayout[nStyle]
    local nStyleLayoutKeyStart = nStyle * LAYOUT_KEY_START
    local nStyleCommonLayoutKeyStart = nStyle * LAYOUT_KEY_START + LAYOUT_COMMON_KEY_START_OFFSET + nFrom * LAYOUT_KEY_FROM_LENGTH
    local tbLayoutTemplates = SettingLayoutDataTable:GetLayoutDataFrom(nFrom)
    local tbLayoutCommonTemplates = SettingLayoutDataTable:GetLayoutDataFrom(SettingLayoutFromDef.COMMON)
    table.move(tbLayoutCommonTemplates, 1, #tbLayoutCommonTemplates, #tbLayoutTemplates + 1, tbLayoutTemplates)
    --local tbLayoutCommonTemplates = SettingLayoutDataTable:GetLayoutDataFrom(SettingLayoutFromDef.COMMON)
    for k, v in pairs(tbLayoutTemplates) do
        local nRemoteId = nStyleLayoutKeyStart + v.nId
        if v.nFrom == SettingLayoutFromDef.COMMON then
            nRemoteId = nStyleCommonLayoutKeyStart + v.nId
        end

        local nValue = Owner:Get(nRemoteId)
        --logdebug("LoadRemoteSettingFrom:nRemoteId,nValue=",nRemoteId, nValue)
        if nValue and nValue ~= -1 then
            local nX, nY, nAlpha, nScale = ParseRemoteData(self, nValue)
            local tbLayoutData = CreateLayoutData(nX, nY, nAlpha, nScale, v.nFrom, v)
            tbLayoutData.nLocalId = v.nId
            tbLayoutData.nRemoteId = nRemoteId
            tbLayoutStyle[nRemoteId] = tbLayoutData
            --log("SettingLayout:LoadRemoteSettingFrom, nId, nRemoteId, nX, nY, nScale, nAlpha=",v.nId, nRemoteId, nX, nY, nScale, nAlpha)
        end
    end
end

local function LoadDefaultSettingFrom(self, nStyle, nFrom)
    local tbLayoutStyle = self.tbAllDefaultLayout[nStyle]
    local tbLayoutTemplates = SettingLayoutDataTable:GetLayoutDataFrom(nFrom)
    local tbLayoutCommonTemplates = SettingLayoutDataTable:GetLayoutDataFrom(SettingLayoutFromDef.COMMON)
    table.move(tbLayoutCommonTemplates, 1, #tbLayoutCommonTemplates, #tbLayoutTemplates + 1, tbLayoutTemplates)
    --logdebug("LoadDefaultSettingFrom,nStyle, nFrom=",nStyle, nFrom)
    local nX = 0
    local nY = 0
    local nAlpha = 1
    local nScale = 1
    local nStyleLayoutKeyStart = nStyle * LAYOUT_KEY_START
    local nStyleCommonLayoutKeyStart = nStyle * LAYOUT_KEY_START + LAYOUT_COMMON_KEY_START_OFFSET + nFrom * LAYOUT_KEY_FROM_LENGTH
    for k, v in pairs(tbLayoutTemplates) do
        local nRemoteId = nStyleLayoutKeyStart + v.nId
        if v.nFrom == SettingLayoutFromDef.COMMON then
            nRemoteId = nStyleCommonLayoutKeyStart + v.nId
        end
        nAlpha = SettingIni.tbLayout.nAlphaDefault
        nScale = SettingIni.tbLayout.nScaleDefault
        local tbDefault = SettingLayoutDefaultDataTable:GetTemplate(v.szMovableWidgetName)
        if tbDefault then
            nX = tbDefault.nX
            nY = tbDefault.nY
            if BaseUtil:ContainsByValue(SettingIni.tbLayout.tbBottomMarginWidgets, v.szMovableWidgetName) then
                nY = nY - ScreenShapeHelper.GetSafeZoneMarginBottom()
            end
        else
            logerror("SettingLayout: can't find default data, id, movable widget name=", v.nId, v.szMovableWidgetName)
        end
        local tbDefaultLayout = CreateLayoutData(nX, nY, nAlpha, nScale, v.nFrom, v)
        tbDefaultLayout.nLocalId = v.nId
        tbDefaultLayout.nRemoteId = nRemoteId
        tbLayoutStyle[nRemoteId] = tbDefaultLayout
        --logdebug("LoadDefaultSettingFrom,nRemoteId=",nRemoteId)
    end
end

local function LoadDefaultSetting(self)
    local tbFroms = {SettingLayoutFromDef.HUMAN, SettingLayoutFromDef.SHIP, SettingLayoutFromDef.VEHICLE}
    for i = 1, MAX_STYLE do
        local tbLayoutStyle = self.tbAllDefaultLayout[i]
        if not tbLayoutStyle then
            tbLayoutStyle = {}
            self.tbAllDefaultLayout[i] = tbLayoutStyle
        end
        for k, nFrom in pairs(tbFroms) do
            --logdebug("SettingLayout:LoadLocalSetting,nFrom=",nFrom)
            --LoadDefaultSettingFrom(self, i, SettingLayoutFromDef.COMMON)
            LoadDefaultSettingFrom(self, i, nFrom)
        end
    end
end

local function GetRemoteLayout(self, nFrom, nKey)
    local nStyle = self:GetLayoutStyle(nFrom)
    local tbAllLayout = self.tbAllLayout[nStyle]
    if not tbAllLayout then
        tbAllLayout = {}
        self.tbAllLayout[nStyle] = {}
    end
    local tbLayoutData = tbAllLayout[nKey]
    if not tbLayoutData then
        tbLayoutData = {}
        local tbDefaultLayout = self.tbAllDefaultLayout[nStyle][nKey]
        for k, v in pairs(tbDefaultLayout) do
            tbLayoutData[k] = v
        end
        tbAllLayout[nKey] = tbLayoutData
    end
    return tbLayoutData
end

--override
function SettingLayout:Init(Owner)
    SettingLayout.super.Init(self, Owner)
    self.nXMask = GetMask(X_BIT_OFFSET - 1)
    self.nYMask = GetMask(Y_BIT_OFFSET - 1)
    self.nScaleMask = GetMask(SCALE_BIT_OFFSET)
    self.nAlphaMask = GetMask(ALPHA_BIT_OFFSET)
    LoadDefaultSetting(self)
    --logdebug("self.nXMask, self.nYMask, self.nScaleMask, self.nAlphaMask=",self.nXMask, self.nYMask, self.nScaleMask, self.nAlphaMask)
end

function SettingLayout:GetLayout(nFrom, nKey)
    local nStyle = self:GetLayoutStyle(nFrom)
    local tbAllLayout = self.tbAllLayout[nStyle]
    if not tbAllLayout or not next(tbAllLayout) or not tbAllLayout[nKey] then
        tbAllLayout = self.tbAllDefaultLayout[nStyle]
        if not tbAllLayout then
            return
        end
        local tbDefaultLayout = tbAllLayout[nKey]
        if not tbDefaultLayout then
            error("tbDefaultLayout is nil, data is error,nKey="..nKey)
        end
        local tbLayoutData = {}
        for k, v in pairs(tbDefaultLayout)do
            tbLayoutData[k] = v
        end
        return tbLayoutData
        -- local BaseUtil = require("BaseUtil")
        -- BaseUtil:PrintTable(tbAllLayout, 2)
    end
    return tbAllLayout[nKey]
end

function SettingLayout:ConvertToCurrentStyleRemoteId(nFrom, nLocalId)
    local nStyle = self:GetLayoutStyle(nFrom)
    local tbLayoutTemplate = SettingLayoutDataTable:GetTemplate(nLocalId)
    if not tbLayoutTemplate then
        return
    end
    if tbLayoutTemplate.nFrom == SettingLayoutFromDef.COMMON then
        return CommonLocalIdToRemoteId(nStyle, nFrom, nLocalId)
    end
    return nStyle * LAYOUT_KEY_START + nLocalId
end

function SettingLayout:GetCurrentLayoutFrom(nFrom)
    local nStyle = self:GetLayoutStyle(nFrom)
    local tbAllDefaultLayout = self.tbAllDefaultLayout[nStyle]
    local tbLayoutDataList = {}
    for k, v in pairs(tbAllDefaultLayout)do
        if v.nFrom == nFrom or (v.nFrom == SettingLayoutFromDef.COMMON and GetLayoutFromByRemoteId(self, nStyle, k) == nFrom)then
            local tbLayoutData = self:GetLayout(nFrom, k)
            table.insert(tbLayoutDataList, tbLayoutData)
        end
    end
    return tbLayoutDataList
end

function SettingLayout:SetPosition(nFrom, nKey, nX, nY)
    local tbLayoutData = GetRemoteLayout(self, nFrom, nKey)
    tbLayoutData.nX = GetRoundInteger(nX)
    tbLayoutData.nY = GetRoundInteger(nY)
    -- logdebug("SettingLayout:SetPosition,x,y=",tbLayoutData.nX, tbLayoutData.nY)
    -- local nValue = MakeValue(self, tbLayoutData.nX, tbLayoutData.nY, tbLayoutData.nScale, tbLayoutData.nAlpha)
    -- logdebug("decode nValue=",nValue)
    -- logdebug("parse nValue=",ParseRemoteData(self, nValue))
end

function SettingLayout:GetPosition(nFrom, nKey)
    local tbLayoutData = self:GetLayout(nFrom, nKey)
    return tbLayoutData.nX, tbLayoutData.nY
end

function SettingLayout:SetAlpha(nFrom, nKey, nAlpha)
    local tbLayoutData = GetRemoteLayout(self, nFrom, nKey)
    tbLayoutData.nAlpha = nAlpha
end

function SettingLayout:GetAlpha(nFrom, nKey)
    local tbLayoutData = self:GetLayout(nFrom, nKey)
    return tbLayoutData.nAlpha
end

function SettingLayout:SetSizeScale(nFrom, nKey, nScale)
    local tbLayoutData = GetRemoteLayout(self, nFrom, nKey)
    tbLayoutData.nScale = nScale
end

function SettingLayout:GetSizeScale(nFrom, nKey)
    local tbLayoutData = self:GetLayout(nFrom, nKey)
    return tbLayoutData.nScale
end

--设置当前布局风格：1，2
function SettingLayout:SetLayoutStyle(nFrom, nStyle)
    self.Owner:Set(LAYOUT_KEY_START + nFrom, nStyle)
    self.Owner:SaveRemoveData()
    self:LoadRemoteSetting()
    self.Owner.EventHelper:FireEvent(ClientEventDef.EV_LAYOUT_STYLE_CHANGED, nFrom, nStyle)
end

--获取当前布局的风格，nFrom = SettingLayoutFromDef.HUMAN, SettingLayoutFromDef.SHIP, SettingLayoutFromDef.VEHICLE
function SettingLayout:GetLayoutStyle(nFrom)
    local nStyle = self.Owner:Get(LAYOUT_KEY_START + nFrom)
    if not nStyle or nStyle == -1 then
        nStyle = 1
    end
    return nStyle
end

function SettingLayout:LoadRemoteSetting()
    self.tbAllLayout = {}
    local tbFroms = {SettingLayoutFromDef.HUMAN, SettingLayoutFromDef.SHIP, SettingLayoutFromDef.VEHICLE}
    for i = 1, MAX_STYLE do
        local tbLayoutStyle = self.tbAllLayout[i]
        if not tbLayoutStyle then
            tbLayoutStyle = {}
            self.tbAllLayout[i] = tbLayoutStyle
        end
        for k, nFrom in pairs(tbFroms) do
            --LoadRemoteSettingFrom(self, i, SettingLayoutFromDef.COMMON)
            LoadRemoteSettingFrom(self, i, nFrom)
        end
    end

end


-- function SettingLayout:LoadLocalSetting()
--     --logdebug("SettingLayout:LoadLocalSetting....")
--     local tbFroms = {SettingLayoutFromDef.HUMAN, SettingLayoutFromDef.SHIP, SettingLayoutFromDef.VEHICLE}
--     for i = 1, MAX_STYLE do
--         local tbLayoutStyle = self.tbAllDefaultLayout[i]
--         if not tbLayoutStyle then
--             tbLayoutStyle = {}
--             self.tbAllDefaultLayout[i] = tbLayoutStyle
--         end
--         for k, nFrom in pairs(tbFroms) do
--             --logdebug("SettingLayout:LoadLocalSetting,nFrom=",nFrom)
--             LoadDefaultSettingFrom(self, i, SettingLayoutFromDef.COMMON)
--             LoadDefaultSettingFrom(self, i, nFrom)
--         end
--     end

-- end


--保存修改
function SettingLayout:SaveAll(nFrom, bSyncCommonLayout)
    local tbFroms = {SettingLayoutFromDef.HUMAN, SettingLayoutFromDef.SHIP, SettingLayoutFromDef.VEHICLE}
    local Owner = self.Owner
    local nStyle = self:GetLayoutStyle(nFrom)
    local tbLayoutStyle = self.tbAllLayout[nStyle]
    local nValue = 0
    for k, v in pairs(tbLayoutStyle) do
        if v.nFrom == nFrom or (v.nFrom == SettingLayoutFromDef.COMMON and GetLayoutFromByRemoteId(self, nStyle, k) == nFrom) then
            nValue = MakeValue(self, v.nX, v.nY, v.nScale, v.nAlpha)
            if v.nFrom == SettingLayoutFromDef.COMMON and bSyncCommonLayout then
                local nCommonLayoutFrom = GetLayoutFromByRemoteId(self, nStyle, k)
                local nLocalId = CommonRemoteIdToLocalId(nStyle, nCommonLayoutFrom, k)
                for k1, v1 in ipairs(tbFroms) do
                    if v1 ~= nFrom then
                        local nRemoteId = CommonLocalIdToRemoteId(nStyle, v1, nLocalId)
                        local tbLayoutData = GetRemoteLayout(self, nFrom, nRemoteId)
                        tbLayoutData.nX = v.nX
                        tbLayoutData.nY = v.nY
                        tbLayoutData.nScale = v.nScale
                        tbLayoutData.nAlpha = v.nAlpha
                        Owner:Set(nRemoteId, nValue)
                    end
                end
            end
            Owner:Set(k, nValue)
        end
    end
    Owner:SaveRemoveData()
    Owner.EventHelper:FireEvent(ClientEventDef.EV_LAYOUT_CHANGED)
    UIUtils.ShowToast(LAYOUT_SAVE_SUCCESSED)
end


--重置
function SettingLayout:ResetToDefault(nFrom)
    local nStyle = self:GetLayoutStyle(nFrom)
    local tbAllLayout = self.tbAllLayout[nStyle]
    if not tbAllLayout then
        tbAllLayout = {}
        self.tbAllLayout[nStyle] = tbAllLayout
    end
    local tbAllDefaultLayout = self.tbAllDefaultLayout[nStyle]

    for k, v in pairs(tbAllDefaultLayout) do
        if v.nFrom == nFrom or (v.nFrom == SettingLayoutFromDef.COMMON and GetLayoutFromByRemoteId(self, nStyle, k) == nFrom)then
            local tbLayoutData = {}
            for k1, nValue in pairs(v) do
                tbLayoutData[k1] = nValue
            end
            tbAllLayout[k] = tbLayoutData
        end
    end
    UIUtils.ShowToast(LAYOUT_RESET_SUCCESSED)
end

--nFrom:SettingLayoutFromDef.HUMAN, SettingLayoutFromDef.SHIP, SettingLayoutFromDef.VEHICLE
function SettingLayout:EnterLayout(nFrom)
    self:LoadRemoteSetting()

    --self.tbAllLayout = {}
    -- local nStyle = self:GetLayoutStyle(nFrom)
    -- local tbLayoutStyle = self.tbAllLayout[nStyle]
    -- if not tbLayoutStyle then
    --     tbLayoutStyle = {}
    --     self.tbAllLayout[nStyle] = tbLayoutStyle
    -- end
    -- LoadRemoteSettingFrom(self, nStyle, SettingLayoutFromDef.COMMON) --通用
    -- LoadRemoteSettingFrom(self, nStyle, nFrom)
    local tbParam = {}
    tbParam.nOpenFrom = nFrom
    UIManager:OpenWnd(UIDef.UI_SETTING_LAYOUT, tbParam)
end

function SettingLayout:GetMaxStyleCount()
    return MAX_STYLE
end

return SettingLayout