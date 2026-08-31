--[[
    请注意，此处伤害类型被用于死亡时弹Toast中，请务必确认新类型需要配置其对应的图标。配置文件路径\client\text\ffatoast.tab
]]
-- DamageType修改时需要同步AI模块
local DamageTypeEx = {
    UNKNOWN                 = 0,        -- 未知伤害
    POISON_CIRCLE           = 101,      -- FFA毒圈
    FALLING                 = 102,      -- 跌落
    DYING_REDUCE            = 103,      -- 重伤下衰减
    KILL_SELF               = 104,      -- 自杀逻辑所受伤害
    DROWN                   = 105,      -- 溺水

    -- 不能随便在船的伤害类型区间里加类型，因为有些逻辑会根据区间去判断，然后取对应武器，所以区间内类型确认是由船武器造成
    SHIP_BEGIN              = 200,      -- 舰船伤害类型开始
    SHIP_WEAPON_BEGIN       = 201,      -- 舰船武器伤害类型开始
    SHIP_SMALL_CANNON       = 201,      -- 小钢炮           近射类
    SHIP_POWDER_KEG         = 202,      -- 火药桶（鱼雷）    爆桶类
    -- SHIP_CARRONADE          = 203,      -- 臼炮             臼炮类
    -- SHIP_TORPEDO            = 204,      -- 水雷             陷阱类
    SHIP_SAKER              = 205,      -- 霰弹炮           散射类
    SHIP_DARTLE             = 206,      -- 转轮炮           速射类
    SHIP_ASSAULT_GUN        = 207,      -- 加农炮           连射类
    SHIP_SNIPE_GUN          = 208,      -- 长管炮           远射类
    SHIP_EMBOLON            = 209,      -- 撞角             冲撞类
    SHIP_FLAMER             = 210,      -- 喷火器           近战喷火器类
    SHIP_STERN_CANNON       = 211,      -- 船尾炮           船尾炮类
    SHIP_WEAPON_END         = 211,      -- 舰船伤害类型结束

    SHIP_THROWN_ITEM_BEGIN  = 230,      -- 舰船投掷物类型开始
    SHIP_CARRONADE          = 231,      -- 臼炮
    SHIP_TORPEDO            = 232,      -- 水雷
    SHIP_THROWN_ITEM_END    = 232,      -- 舰船投掷物类型结束

    SHIP_FIRING             = 251,      -- 船造成的点燃伤害
    SHIP_LEAKING            = 252,      -- 船造成的漏水伤害
    SHIP_BUMPING            = 253,      -- 船撞人的伤害

    SHIP_DEFAULT_WEAPON     = 299,      -- 舰船默认船武器伤害
    SHIP_END                = 299,      -- 舰船伤害类型结束

    HUMAN_BEGIN             = 300,      -- 人伤害类型开始
    HUMAN_EMPTY_HAND        = 301,      -- 人空手伤害
    HUMAN_MELEE             = 302,      -- 人近战武器（刀）
    HUMAN_PISTOL            = 303,      -- 人-手枪
    HUMAN_FLINTLOCK         = 304,      -- 人-燧发枪
    HUMAN_MATCHLOCK         = 305,      -- 人-火绳枪
    HUMAN_CROSSBOW          = 306,      -- 人-弩
    HUMAN_BOW               = 307,      -- 人-弓

    HUMAN_GRENADE           = 308,      -- 手雷伤害
    HUMAN_FIREBOMB          = 309,      -- 燃烧弹燃烧buff伤害
    HUMAN_FLYINGKNIFE       = 310,      -- 飞刀
    HUMAN_MAGIC             = 311,      -- 魔法

    HUMAN_END               = 399,      -- 人伤害类型结束

}

function DamageTypeEx.IsCausedByShipWeapon(nType)
    return nType >= DamageTypeEx.SHIP_WEAPON_BEGIN and nType <= DamageTypeEx.SHIP_WEAPON_END
end

function DamageTypeEx.IsCausedByShip(nType)
    return nType >= DamageTypeEx.SHIP_BEGIN and nType <= DamageTypeEx.SHIP_END
end

function DamageTypeEx.IsCausedByHuman(nType)
    return nType >= DamageTypeEx.HUMAN_BEGIN and nType <= DamageTypeEx.HUMAN_END
end

return DamageTypeEx