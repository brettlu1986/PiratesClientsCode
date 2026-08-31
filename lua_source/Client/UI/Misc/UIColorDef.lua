-----------------------------------------------------
--File Name    : UIColorDef.lua
--Author       : Ran Jie
--Create Time  : 2020-09-21
--Description  : UI颜色值定义
-----------------------------------------------------
local UIColorDef = {}



--local GetLinearColorFunc = KMUMGLibrary.GetLinearColor
local GetLinearColorFromHexFunc = KMUMGLibrary.GetLinearColorFromHex
--local GetSlateColorFunc = KMUMGLibrary.GetSlateColor
local GetSlateColorFromHexFunc = KMUMGLibrary.GetSlateColorFromHex

------------------------------------颜色---------------------------------------
UIColorDef =
{
    WHITE =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("FFFFFFFF"),
        SLATE_COLOR = GetSlateColorFromHexFunc("FFFFFFFF"),
    },
    BLACK =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("000000FF"),
        LINEAR_COLOR_TRANSPARENT = GetLinearColorFromHexFunc("00000066"),
        SLATE_COLOR = GetSlateColorFromHexFunc("000000FF"),
        SLATE_COLOR_TRANSPARENT = GetSlateColorFromHexFunc("00000066"),
    },
    YELLOW =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("FFE972FF"),
        LINEAR_COLOR_TRANSPARENT = GetLinearColorFromHexFunc("FFE972CC"),
        SLATE_COLOR = GetSlateColorFromHexFunc("FFE972FF"),
        SLATE_COLOR_TRANSPARENT = GetSlateColorFromHexFunc("FFE972CC"),
    },
    YELLOW1 =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("D1C0A5FF"),
        SLATE_COLOR = GetSlateColorFromHexFunc("D1C0A5FF"),
    },
    ORANGE =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("AC8A00FF"),
        LINEAR_COLOR_TRANSPARENT = GetLinearColorFromHexFunc("AC8A00CC"),
        SLATE_COLOR = GetSlateColorFromHexFunc("AC8A00FF"),
        SLATE_COLOR_TRANSPARENT = GetSlateColorFromHexFunc("AC8A00CC"),
    },
    ORANGE1 =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("F39700FF"),
        LINEAR_COLOR_TRANSPARENT = GetLinearColorFromHexFunc("F39700CC"),
        SLATE_COLOR = GetSlateColorFromHexFunc("F39700FF"),
        SLATE_COLOR_TRANSPARENT = GetSlateColorFromHexFunc("F39700CC"),
    },
    GREEN =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("CLE732FF"),
        LINEAR_COLOR_TRANSPARENT = GetLinearColorFromHexFunc("CLE732CC"),
        SLATE_COLOR = GetSlateColorFromHexFunc("CLE732FF"),
        SLATE_COLOR_TRANSPARENT = GetSlateColorFromHexFunc("CLE732CC"),
    },   
    GREEN1 =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("00A000FF"),
        LINEAR_COLOR_TRANSPARENT = GetLinearColorFromHexFunc("00A000CC"),
        SLATE_COLOR = GetSlateColorFromHexFunc("00A000FF"),
        SLATE_COLOR_TRANSPARENT = GetSlateColorFromHexFunc("00A000CC"),
    },    
    BLUE =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("7ECEF4FF"),
        LINEAR_COLOR_TRANSPARENT = GetLinearColorFromHexFunc("7ECEF4CC"),
        SLATE_COLOR = GetSlateColorFromHexFunc("7ECEF4FF"),
        SLATE_COLOR_TRANSPARENT = GetSlateColorFromHexFunc("7ECEF4CC"),
    },  
    BLUE1 =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("00CCFFFF"),
        LINEAR_COLOR_TRANSPARENT = GetLinearColorFromHexFunc("00CCFFCC"),
        SLATE_COLOR = GetSlateColorFromHexFunc("00CCFFFF"),
        SLATE_COLOR_TRANSPARENT = GetSlateColorFromHexFunc("00CCFFCC"),
    },
    BLUE2 =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("152A44FF"),
        LINEAR_COLOR_TRANSPARENT = GetLinearColorFromHexFunc("152A44CC"),
        SLATE_COLOR = GetSlateColorFromHexFunc("152A44FF"),
        SLATE_COLOR_TRANSPARENT = GetSlateColorFromHexFunc("152A44CC"),
    },
    BLUE3 =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("0000FFFF"),
        LINEAR_COLOR_TRANSPARENT = GetLinearColorFromHexFunc("0000FFCC"),
        SLATE_COLOR = GetSlateColorFromHexFunc("0000FFFF"),
        SLATE_COLOR_TRANSPARENT = GetSlateColorFromHexFunc("0000FFCC"),
    },
    PURPLE =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("C981DDFF"),
        SLATE_COLOR = GetSlateColorFromHexFunc("C981DDFF"),
    },  
    RED =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("FF0000FF"),
        SLATE_COLOR = GetSlateColorFromHexFunc("FF0000FF"),
    },
    GREY =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("7C7C7CFF"),
        SLATE_COLOR = GetSlateColorFromHexFunc("7C7C7CFF"),
    },
    GREY1 =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("8E8E8EFF"),
        SLATE_COLOR = GetSlateColorFromHexFunc("8E8E8EFF"),
    },
    GREY2 =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("4A4A4AFF"),
        SLATE_COLOR = GetSlateColorFromHexFunc("4A4A4AFF"),
    },
    GREY3 =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("929292FF"),
        SLATE_COLOR = GetSlateColorFromHexFunc("929292FF"),
    },
    PINK =
    {
        LINEAR_COLOR = GetLinearColorFromHexFunc("FF7F46FF"),
        SLATE_COLOR = GetSlateColorFromHexFunc("FF7F46FF"),
    },
    TRANSPARENT = {
        LINEAR_COLOR = GetLinearColorFromHexFunc("FFFFFF00"),
        SLATE_COLOR = GetSlateColorFromHexFunc("FFFFFF00"),
    }
}

return UIColorDef
