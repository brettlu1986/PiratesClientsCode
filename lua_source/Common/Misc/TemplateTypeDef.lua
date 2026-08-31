-----------------------------------------------------
--File Name    : TemplateTypeDef.lua
--Description  : 类型
-----------------------------------------------------

local TemplateTypeDef =
{
    INVALID                 = 0,
    SHIP                    = 1,        -- 船
    HUMAN                   = 1 << 1,   -- 人
    SHIPCOLLECTION          = 1 << 2,   -- 船采集物
    HUMANCOLLECTION         = 1 << 3,   -- 人采集物
}

TemplateTypeDef.CHARACTER = TemplateTypeDef.SHIP | TemplateTypeDef.HUMAN
TemplateTypeDef.COLLECTION = TemplateTypeDef.SHIPCOLLECTION | TemplateTypeDef.HUMANCOLLECTION
TemplateTypeDef.ALL = TemplateTypeDef.SHIP | TemplateTypeDef.HUMAN | TemplateTypeDef.SHIPCOLLECTION | TemplateTypeDef.HUMANCOLLECTION

return TemplateTypeDef