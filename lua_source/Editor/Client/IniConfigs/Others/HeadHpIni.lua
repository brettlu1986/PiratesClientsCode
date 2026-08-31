--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local HeadHpIni = {}

HeadHpIni.szFileName = "client/ui/head_hp.ini"

function HeadHpIni:OnParse(Parser)

    self.bShowHumanHp = Parser:Get("control_flag"                            ,"show_human_hp"                     ,false   ,Parser.TypeBool)
    self.bShowShipHp = Parser:Get("control_flag"                             ,"show_ship_hp"                      ,false   ,Parser.TypeBool)
    self.bShowHumanDamage = Parser:Get("control_flag"                        ,"show_human_damge_num"              ,true    ,Parser.TypeBool)
    self.bShowShipDamage = Parser:Get("control_flag"                         ,"show_ship_damage_num"              ,true    ,Parser.TypeBool)
    self.bShowSelfShipDamage = Parser:Get("control_flag"                     ,"ship_self_damage_num"              ,true    ,Parser.TypeBool)

    self.nHeadHpMinTime =  Parser:Get("head_hp_bar"                          ,"head_hp_min_time"                  ,1      ,Parser.TypeNumber)
    self.nHeadHpDuration = Parser:Get("head_hp_bar"                          ,"head_hp_duration"                  ,1      ,Parser.TypeNumber)
    self.nHeadHpEmptyDuration = Parser:Get("head_hp_bar"                     ,"head_hp_empty_duration"            ,1      ,Parser.TypeNumber)

    

    self.nHpBarAnimTime = Parser:Get("head_hp_bar"                           ,"hp_bar_anim_time"                  ,1      ,Parser.TypeNumber)
    self.nHpBarTopAnimTime = Parser:Get("head_hp_bar"                        ,"hp_bar_top_anim_time"              ,1      ,Parser.TypeNumber)
    self.nHpBarMidWaitTime = Parser:Get("head_hp_bar"                        ,"hp_bar_mid_wait_time"              ,1      ,Parser.TypeNumber)

    self.nHpBarHumanHeight = Parser:Get("head_hp_bar"                        ,"hp_bar_human_height"               ,1      ,Parser.TypeNumber)
    --self.nHpBarShipHeight = Parser:Get("head_hp_bar"                         ,"hp_bar_ship_height"                ,1      ,Parser.TypeNumber)

    self.nHpBarNpcHumanHeight = Parser:Get("head_hp_bar"                     ,"hp_bar_npc_human_height"           ,1      ,Parser.TypeNumber)
    --self.nHpBarNpcShipHeight = Parser:Get("head_hp_bar"                      ,"hp_bar_npc_ship_height"            ,1      ,Parser.TypeNumber)

    self.nDamageNumHumanHeight = Parser:Get("damage_num"                     ,"damage_num_human_height"           ,1      ,Parser.TypeNumber)
    self.nDamageNumShipHeight = Parser:Get("damage_num"                      ,"damage_num_ship_height"            ,1      ,Parser.TypeNumber)
    self.nDamageNumSelfShipHeight = Parser:Get("damage_num"                  ,"damage_num_selfship_height"        ,1      ,Parser.TypeNumber)

    self.nDamageNumNpcHumanHeight = Parser:Get("damage_num"                  ,"damage_num_npc_human_height"       ,1      ,Parser.TypeNumber)
    self.nDamageNumNpcShipHeight = Parser:Get("damage_num"                   ,"damage_num_npc_ship_height"        ,1      ,Parser.TypeNumber)

    self.szDamgetNormalColor = Parser:Get("damage_num"                       ,"damage_normal_color"               ,1      ,Parser.TypeString)
    self.nDamageNormalFontSize = Parser:Get("damage_num"                     ,"damage_normal_font_size"           ,1      ,Parser.TypeNumber)

    self.szDamgetAboveNormalColor = Parser:Get("damage_num"                  ,"damage_above_normal_color"         ,1      ,Parser.TypeString)
    self.nDamageAboveNormalFontSize = Parser:Get("damage_num"                ,"damage_above_normal_font_size"     ,1      ,Parser.TypeNumber)

    self.szDamgetHeavyColor = Parser:Get("damage_num"                        ,"damage_heavy_color"                ,1      ,Parser.TypeString)
    self.nDamageHeavyFontSize = Parser:Get("damage_num"                      ,"damage_heavy_font_size"            ,1      ,Parser.TypeNumber)

    self.szDamgetCriticalColor = Parser:Get("damage_num"                     ,"damage_critical_color"             ,1      ,Parser.TypeString)
    self.nDamageCriticalFontSize = Parser:Get("damage_num"                   ,"damage_critical_font_size"         ,1      ,Parser.TypeNumber)
 
    self.nShipDamageFontSize = Parser:Get("damage_num"                        ,"ship_damage_font_size"            ,1      ,Parser.TypeNumber)
    local tbUiHpColors = {}
    tbUiHpColors.tbHpLevelPercents      = Parser:Get("ui_hp_bar_color"        ,"hp_level_percent"                 ,{}     ,Parser.TypeNumber)
    tbUiHpColors.tbHpLevelBgOpacities   = Parser:Get("ui_hp_bar_color"        ,"hp_level_bg_opacity"              ,{}     ,Parser.TypeNumber)
    tbUiHpColors.tbHpLevelColors        = Parser:Get("ui_hp_bar_color"        ,"hp_level_color"                   ,{}     ,Parser.TypeString)
    tbUiHpColors.nDyingHpBgOpacity      = Parser:Get("ui_hp_bar_color"        ,"dying_hp_bg_opacity"              ,1      ,Parser.TypeNumber)
    tbUiHpColors.szDyingHpColor         = Parser:Get("ui_hp_bar_color"        ,"dying_hp_color"                   ,nil    ,Parser.TypeString)
    self.tbUiHpColors = tbUiHpColors


    local tbHeadHpColors = {}
    tbHeadHpColors.tbHpLevelPercents      = Parser:Get("head_hp_bar_color"     ,"hp_level_percent"                ,{}     ,Parser.TypeNumber)
    tbHeadHpColors.tbHpLevelBgOpacities   = Parser:Get("head_hp_bar_color"     ,"hp_level_bg_opacity"             ,{}     ,Parser.TypeNumber)
    tbHeadHpColors.tbHpLevelColors        = Parser:Get("head_hp_bar_color"     ,"hp_level_color"                  ,{}     ,Parser.TypeString)
    tbHeadHpColors.nDyingHpBgOpacity      = Parser:Get("head_hp_bar_color"     ,"dying_hp_bg_opacity"             ,1      ,Parser.TypeNumber)
    tbHeadHpColors.szDyingHpColor         = Parser:Get("head_hp_bar_color"     ,"dying_hp_color"                  ,nil    ,Parser.TypeString)
    self.tbHeadHpColors = tbHeadHpColors
    
end

return HeadHpIni
