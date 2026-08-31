-----------------------------------------------------
--File Name    : UISetUtils.lua
--Author       : Song Fuhao
--Create Time  : 2016-08-16
--Description  : UMG相关设置工具类方法
-----------------------------------------------------

local UISetUtils = {}
local TextDataTable = require("TextDataTable")

local fnSetImageBrushRes = KMUMGLibrary.SetImageBrushRes
local fnSetImageBrushMirroring = KMUMGLibrary.SetImageBrushMirroring
local fnSetImageBrushTint = KMUMGLibrary.SetImageBrushTint
local fnSetBorderBrushRes = KMUMGLibrary.SetBorderBrushRes
local fnSetBorderBrushMirroring = KMUMGLibrary.SetBorderBrushMirroring
local fnSetBorderBrushTint = KMUMGLibrary.SetBorderBrushTint
local fnSetButtonBrushRes = KMUMGLibrary.SetButtonBrushRes
local fnSetButtonNormalBrushRes = KMUMGLibrary.SetButtonNormalBrushRes
local fnSetButtonHoveredBrushRes = KMUMGLibrary.SetButtonHoveredBrushRes
local fnSetButtonPressedBrushRes = KMUMGLibrary.SetButtonPressedBrushRes
local fnSetButtonDisabledBrushRes = KMUMGLibrary.SetButtonDisabledBrushRes
local fnSetButtonBrushTint = KMUMGLibrary.SetButtonBrushTint
local fnSetCheckBoxCheckedBrushRes = KMUMGLibrary.SetCheckBoxCheckedBrushRes
local fnSetCheckBoxUncheckedBrushRes = KMUMGLibrary.SetCheckBoxUncheckedBrushRes
local fnSetTextblockFont = KMUMGLibrary.SetTextblockFont
local fnSetTextblockFontSize = KMUMGLibrary.SetTextblockFontSize

--[[
    Image
]]
function UISetUtils.SetImageBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    if pWidget and pResouceObject then
        bMatchSize = bMatchSize or false
        bCustomSize = bCustomSize or false
        nX = nX or 0
        nY = nY or 0
        fnSetImageBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    else
        logerror('SetImageBrushRes failed.', pWidget, pResouceObject, debug.traceback())
    end
end

function UISetUtils.SetImageBrushMirroring(pWidget, pMirroring)
    if pWidget and pMirroring then
        fnSetImageBrushMirroring(pWidget, pMirroring)
    else
        logerror('SetImageBrushMirroring failed.', pWidget, pMirroring, debug.traceback())
    end
end

function UISetUtils.SetImageBrushTint(pWidget, pSlateColor)
    if pWidget and pSlateColor then
        fnSetImageBrushTint(pWidget, pSlateColor)
    else
        logerror('SetImageBrushTint failed.', pWidget, pSlateColor, debug.traceback())
    end
end

--@Param tbColor:UIResourceDef.COLOR.WHITE,UIResourceDef.COLOR.RED ...
function UISetUtils.SetImageBrushColor(pWidget, tbColor)
    if pWidget and tbColor and tbColor.SLATE_COLOR then
        fnSetImageBrushTint(pWidget, tbColor.SLATE_COLOR)
    else
        logerror('SetImageBrushColor failed.', pWidget, tbColor, debug.traceback())
    end
end

function UISetUtils.SetAsyncImageBrushFromSprite(pWidget, szImgRes, pDimension, bMatchSize)
    if pWidget then
        bMatchSize = bMatchSize or false
        pWidget:LoadTextureResourceByPath(szImgRes, true, bMatchSize)
        local pBrush = pWidget.Brush
        if pDimension then
            pBrush.ImageSize = pDimension
        end
        pWidget:SetBrush(pBrush)
    else
        logerror('SetAsyncImageBrushFromSprite failed.', pWidget, szImgRes, debug.traceback())
    end
end

--[[
    Border
]]
function UISetUtils.SetBorderBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    if pWidget and pResouceObject then
        bMatchSize = bMatchSize or false
        bCustomSize = bCustomSize or false
        nX = nX or 0
        nY = nY or 0
        fnSetBorderBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    else
        logerror('SetBorderBrushRes failed.', pWidget, pResouceObject, debug.traceback())
    end
end

function UISetUtils.SetBorderBrushMirroring(pWidget, pMirroring)
    if pWidget and pMirroring then
        fnSetBorderBrushMirroring(pWidget, pMirroring)
    else
        logerror('SetBorderBrushMirroring failed.', pWidget, pMirroring, debug.traceback())
    end
end

function UISetUtils.SetBorderBrushTint(pWidget, pSlateColor)
    if pWidget and pSlateColor then
        fnSetBorderBrushTint(pWidget, pSlateColor)
    else
        logerror('SetBorderBrushTint failed.', pWidget, pSlateColor, debug.traceback())
    end
end

--@Param tbColor:UIResourceDef.COLOR.WHITE,UIResourceDef.COLOR.RED ...
function UISetUtils.SetBorderBrushColor(pWidget, tbColor)
    if pWidget and tbColor and tbColor.SLATE_COLOR then
        fnSetBorderBrushTint(pWidget, tbColor.SLATE_COLOR)
    else
        logerror('SetBorderBrushColor failed.', pWidget, tbColor, debug.traceback())
    end
end

--[[
    Button
]]
function UISetUtils.SetButtonBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    if pWidget and pResouceObject then
        bMatchSize = bMatchSize or false
        bCustomSize = bCustomSize or false
        nX = nX or 0
        nY = nY or 0
        fnSetButtonBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    else
        logerror('SetButtonBrushRes failed.', pWidget, pResouceObject, debug.traceback())
    end
end

function UISetUtils.SetButtonNormalBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    if pWidget and pResouceObject then
        bMatchSize = bMatchSize or false
        bCustomSize = bCustomSize or false
        nX = nX or 0
        nY = nY or 0
        fnSetButtonNormalBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    else
        logerror('SetButtonNormalBrushRes failed.', pWidget, pResouceObject, debug.traceback())
    end
end

function UISetUtils.SetButtonHoveredBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    if pWidget and pResouceObject then
        bMatchSize = bMatchSize or false
        bCustomSize = bCustomSize or false
        nX = nX or 0
        nY = nY or 0
        fnSetButtonHoveredBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    else
        logerror('SetButtonHoveredBrushRes failed.', pWidget, pResouceObject, debug.traceback())
    end
end

function UISetUtils.SetButtonPressedBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    if pWidget and pResouceObject then
        bMatchSize = bMatchSize or false
        bCustomSize = bCustomSize or false
        nX = nX or 0
        nY = nY or 0
        fnSetButtonPressedBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    else
        logerror('SetButtonPressedBrushRes failed.', pWidget, pResouceObject, debug.traceback())
    end
end

function UISetUtils.SetButtonDisabledBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    if pWidget and pResouceObject then
        bMatchSize = bMatchSize or false
        bCustomSize = bCustomSize or false
        nX = nX or 0
        nY = nY or 0
        fnSetButtonDisabledBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    else
        logerror('SetButtonDisabledBrushRes failed.', pWidget, pResouceObject, debug.traceback())
    end
end

function UISetUtils.SetButtonBrushTint(pWidget, pSlateColor)
    if pWidget and pSlateColor then
        fnSetButtonBrushTint(pWidget, pSlateColor)
    else
        logerror('SetImageBrushTint failed.', pWidget, pSlateColor, debug.traceback())
    end
end

--@Param tbColor:UIResourceDef.COLOR.WHITE,UIResourceDef.COLOR.RED ...
function UISetUtils.SetButtonBrushColor(pWidget, tbColor)
    if pWidget and tbColor and tbColor.SLATE_COLOR then
        fnSetButtonBrushTint(pWidget, tbColor.SLATE_COLOR)
    else
        logerror('SetButtonBrushColor failed.', pWidget, tbColor, debug.traceback())
    end
end

function UISetUtils.BindButtonClickAnim(UIScript, pButtonRef, pAnimation)
    UIScript.EventHelper:RegisterCppDelegateFunc(
        pButtonRef.OnPressed,
        function()
            UIScript.pWidgetRef:PlayAnimation(pAnimation, 0, 1, EUMGSequencePlayMode.Forward, 1)
        end
    )
    UIScript.EventHelper:RegisterCppDelegateFunc(
        pButtonRef.OnReleased,
        function()
            UIScript.pWidgetRef:PlayAnimation(pAnimation, 0, 1, EUMGSequencePlayMode.Reverse, 1)
        end
    )
end

--[[
    CheckBox
]]
function UISetUtils.SetCheckBoxCheckedBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    if pWidget and pResouceObject then
        bMatchSize = bMatchSize or false
        bCustomSize = bCustomSize or false
        nX = nX or 0
        nY = nY or 0
        fnSetCheckBoxCheckedBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    else
        logerror('SetCheckBoxCheckedBrushRes failed.', pWidget, pResouceObject, debug.traceback())
    end
end

function UISetUtils.SetCheckBoxUncheckedBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    if pWidget and pResouceObject then
        bMatchSize = bMatchSize or false
        bCustomSize = bCustomSize or false
        nX = nX or 0
        nY = nY or 0
        fnSetCheckBoxUncheckedBrushRes(pWidget, pResouceObject, bMatchSize, bCustomSize, nX, nY)
    else
        logerror('SetCheckBoxUncheckedBrushRes failed.', pWidget, pResouceObject, debug.traceback())
    end
end

--[[
    TextBlock
]]
function UISetUtils.SetTextblockFont(pWidget, pFontObject, szTypefaceFontName)
    if pWidget and pFontObject then
        szTypefaceFontName = szTypefaceFontName or ""
        fnSetTextblockFont(pWidget, pFontObject, szTypefaceFontName)
    else
        logerror('SetTextblockFont failed.', pWidget, pFontObject, debug.traceback())
    end
end

function UISetUtils.SetTextblockFontSize(pWidget, nFontSize)
    if pWidget and nFontSize > 0 then
        fnSetTextblockFontSize(pWidget, nFontSize)
    else
        logerror('SetTextblockFontSize failed.', pWidget, nFontSize)
    end
end

--@Param tbColor:UIResourceDef.COLOR.WHITE,UIResourceDef.COLOR.RED ...
function UISetUtils.SetTextblockColor(pWidget, tbColor)
    if pWidget and tbColor and tbColor.SLATE_COLOR then
        pWidget:SetColorAndOpacity(tbColor.SLATE_COLOR)
    else
        logerror('SetTextblockColor failed.', pWidget, tbColor, debug.traceback())
    end
end


-- 使用时注意GetTextByKey/GetL10NTextByKey的区别
function UISetUtils.GetTextByKey(szKey)
    if szKey == "" then
        return ""
    end

    local szText = TextDataTable:GetText(szKey)
    if szText == nil then
        logerror("UISetUtils.GetTextByKey no text", szKey)
        return ""
    end
    return szText
end

function UISetUtils.GetL10NTextByKey(szKey)
    if szKey == "" then
        return nil
    end
    local l10nText = TextDataTable:GetL10NText(szKey)
    if l10nText == nil then
        logerror("UISetUtils.Getl10nTextByKey no text", szKey, debug.traceback(  ))
        return nil
    end
    return l10nText
end

function UISetUtils.UpdateByTextSelfKey(pWidgetRef)
    if pWidgetRef == nil then
        return
    end
    local szKey = pWidgetRef.Key
    if szKey == nil or szKey == "" then
        return
    end

    local l10nText = UISetUtils.GetL10NTextByKey(szKey)
    pWidgetRef:SetText(l10nText)
end


return UISetUtils
