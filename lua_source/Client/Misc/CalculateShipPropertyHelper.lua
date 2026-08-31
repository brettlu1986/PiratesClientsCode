-- Purpose: Provide identical method to get property in Wildworld and BattleWorld
local CalculateShipPropertyHelper = {}

local ShipCategory = require("ShipCategory")

local VALUE_MAX = 1000

-- 获得最大值
function CalculateShipPropertyHelper:GetValueMax()
    return VALUE_MAX
end

local function NormalizePerformanceValue(nValue)
    --("nValue before", nValue)
    if nValue < 0 then
        nValue = 0
    end
    if nValue > VALUE_MAX then
        nValue = VALUE_MAX
    end
    nValue = math.floor(nValue)
    --logdebug("nValue after", nValue)
    return nValue
end

-- 计算战列舰生存
local function CalSurvivalBattleShip(self, tbParam)
    local hp = tbParam.hp                                                 -- 船只血量
    local mastHp = tbParam.mastHp                                         -- 船帆血量
    local helmHp = tbParam.helmHp                                         -- 船舵血量
    return (hp*0.8+mastHp*0.1+helmHp*0.1)/60
end

-- 计算护卫舰生存
local function CalSurvivalFrigate(self, tbParam)
    local hp = tbParam.hp                                                 -- 船只血量
    local mastHp = tbParam.mastHp                                         -- 船帆血量
    local helmHp = tbParam.helmHp                                         -- 船舵血量
    return (hp*0.8+mastHp*0.1+helmHp*0.1)/45
end

-- 计算炮艇生存
local function CalSurvivalGunship(self, tbParam)
    local hp = tbParam.hp                                                 -- 船只血量
    local mastHp = tbParam.mastHp                                         -- 船帆血量
    local helmHp = tbParam.helmHp                                         -- 船舵血量
    return (hp*0.8+mastHp*0.1+helmHp*0.1)/30
end

-- tbParam
--{
--    category = nil,                               -- 舰船类型
--    hp = nil,                                     -- 船只血量
--    mastHp = nil,                                 -- 船帆血量
--    helmHp = nil                                  -- 船舵血量
--}
-- 计算生存
function CalculateShipPropertyHelper:CalSurvival(tbParam)
    --logdebug("CalSurvival")
    --local json = require("dkjson")
    --logdebug("tbParam", json.encode(tbParam))
    local nValue = 0
    if tbParam.category == ShipCategory.BattleShip then       -- 战列舰
        nValue = CalSurvivalBattleShip(self, tbParam)
    elseif tbParam.category == ShipCategory.Frigate then      -- 护卫舰
        nValue = CalSurvivalFrigate(self, tbParam)
    elseif tbParam.category == ShipCategory.Gunship then      -- 炮艇
        nValue = CalSurvivalGunship(self, tbParam)
    end
    return NormalizePerformanceValue(nValue)
end

-- 计算战列舰防护
local function CalArmorBattleShip(self, tbParam)
    local grade = tbParam.grade
    local thickness1 = tbParam.thickness1                                 -- 护甲1区域的装甲厚度
    local thickness2 = tbParam.thickness2                                 -- 护甲2区域的装甲厚度
    local thickness3 = tbParam.thickness3                                 -- 护甲3区域的装甲厚度
    local thickness4 = tbParam.thickness4                                 -- 护甲4区域的装甲厚度
    local hardness = tbParam.hardness                                     -- 装甲硬度
    local gun_damage_reduction = tbParam.gun_damage_reduction             -- 炮弹减伤
    local torpedo_damage_reduction = tbParam.torpedo_damage_reduction     -- 火药桶减伤
    local fireproof_prop = tbParam.fireproof_prop                         -- 防起火率
    local burn_resistance = tbParam.burn_resistance                       -- 燃烧伤害抗性
    local burn_duration = tbParam.burn_duration                           -- 燃烧持续时间
    local leakproof_prob = tbParam.leakproof_prob                         -- 防进水率
    local drown_resistance = tbParam.drown_resistance                     -- 进水伤害抗性
    local drown_duration = tbParam.drown_duration                         -- 进水持续时间
    return (thickness1+thickness2+thickness3+thickness4)*hardness/100/(1-gun_damage_reduction)/(1-torpedo_damage_reduction)/(1-fireproof_prop*burn_resistance*3*(30-burn_duration)/30)/(1-leakproof_prob*drown_resistance*3*(15-drown_duration)/15)*(grade*grade*0.2+grade*2.5+20)
end

-- 计算护卫舰防护
local function CalArmorFrigate(self, tbParam)
    local grade = tbParam.grade
    local thickness1 = tbParam.thickness1                                 -- 护甲1区域的装甲厚度
    local thickness2 = tbParam.thickness2                                 -- 护甲2区域的装甲厚度
    local thickness3 = tbParam.thickness3                                 -- 护甲3区域的装甲厚度
    local thickness4 = tbParam.thickness4                                 -- 护甲4区域的装甲厚度
    local hardness = tbParam.hardness                                     -- 装甲硬度
    local gun_damage_reduction = tbParam.gun_damage_reduction             -- 炮弹减伤
    local torpedo_damage_reduction = tbParam.torpedo_damage_reduction     -- 火药桶减伤
    local fireproof_prop = tbParam.fireproof_prop                         -- 防起火率
    local burn_resistance = tbParam.burn_resistance                       -- 燃烧伤害抗性
    local burn_duration = tbParam.burn_duration                           -- 燃烧持续时间
    local leakproof_prob = tbParam.leakproof_prob                         -- 防进水率
    local drown_resistance = tbParam.drown_resistance                     -- 进水伤害抗性
    local drown_duration = tbParam.drown_duration                         -- 进水持续时间
    return (thickness1+thickness2+thickness3+thickness4)*hardness/100/(1-gun_damage_reduction)/(1-torpedo_damage_reduction)/(1-fireproof_prop*burn_resistance*3*(30-burn_duration)/30)/(1-leakproof_prob*drown_resistance*3*(15-drown_duration)/15)*(grade*grade+grade*0.7+46)
end

-- 计算炮艇防护
local function CalArmorGunship(self, tbParam)
    local grade = tbParam.grade
    local thickness1 = tbParam.thickness1                                 -- 护甲1区域的装甲厚度
    local thickness2 = tbParam.thickness2                                 -- 护甲2区域的装甲厚度
    local thickness3 = tbParam.thickness3                                 -- 护甲3区域的装甲厚度
    local thickness4 = tbParam.thickness4                                 -- 护甲4区域的装甲厚度
    local hardness = tbParam.hardness                                     -- 装甲硬度
    local gun_damage_reduction = tbParam.gun_damage_reduction             -- 炮弹减伤
    local torpedo_damage_reduction = tbParam.torpedo_damage_reduction     -- 火药桶减伤
    local fireproof_prop = tbParam.fireproof_prop                         -- 防起火率
    local burn_resistance = tbParam.burn_resistance                       -- 燃烧伤害抗性
    local burn_duration = tbParam.burn_duration                           -- 燃烧持续时间
    local leakproof_prob = tbParam.leakproof_prob                         -- 防进水率
    local drown_resistance = tbParam.drown_resistance                     -- 进水伤害抗性
    local drown_duration = tbParam.drown_duration                         -- 进水持续时间
    return (thickness1+thickness2+thickness3+thickness4)*hardness/100/(1-gun_damage_reduction)/(1-torpedo_damage_reduction)/(1-fireproof_prop*burn_resistance*3*(30-burn_duration)/30)/(1-leakproof_prob*drown_resistance*3*(15-drown_duration)/15)*(grade*grade*0.3+41)
end

-- tbParam = 
--{
--    category = nil,                     -- 舰船类型
--    grade = nil,                        -- 舰船级别
--    thickness1 = nil,                   -- 护甲1区域的装甲厚度
--    thickness2 = nil,                   -- 护甲2区域的装甲厚度
--    thickness3 = nil,                   -- 护甲3区域的装甲厚度
--    thickness4 = nil,                   -- 护甲4区域的装甲厚度
--    hardness    = nil,                  -- 装甲硬度
--    gun_damage_reduction = nil,         -- 炮弹减伤
--    torpedo_damage_reduction = nil,     -- 火药桶减伤
--    fireproof_prop = nil,               -- 防起火率
--    burn_resistance = nil,              -- 燃烧伤害抗性
--    burn_duration = nil,                -- 燃烧持续时间
--    leakproof_prob = nil,               -- 防进水率
--    drown_resistance = nil,             -- 进水伤害抗性
--    drown_duration = nil                -- 进水持续时间
--}
-- 计算防护
function CalculateShipPropertyHelper:CalArmor(tbParam)
    --logdebug("CalArmor")
    --local json = require("dkjson")
    --logdebug("tbParam", json.encode(tbParam))
    local nValue = 0
    if tbParam.category == ShipCategory.BattleShip then       -- 战列舰
        nValue = CalArmorBattleShip(self, tbParam)
    elseif tbParam.category == ShipCategory.Frigate then      -- 护卫舰
        nValue = CalArmorFrigate(self, tbParam)
    elseif tbParam.category == ShipCategory.Gunship then      -- 炮艇
        nValue = CalArmorGunship(self, tbParam)
    end
    return NormalizePerformanceValue(nValue)
end

-- 计算战列舰火炮
local function CalGunBattleShip(self, tbParam)
    local max_damage = tbParam.max_damage                         -- 主炮火炮伤害
    local loading_time = tbParam.loading_time                     -- 主炮装填时间
    local max_range = tbParam.max_range                           -- 主炮射程
    local gun_count_per_group = tbParam.gun_count_per_group       -- 主炮每组炮数
    local group_count = tbParam.group_count                       -- 主炮组数
    local burn_prob = tbParam.burn_prob                           -- 点火概率
    local burn_damage = tbParam.burn_damage                       -- 点火伤害
    local hardness = tbParam.hardness                             -- 炮弹硬度
    local caliber = tbParam.caliber                               -- 炮弹口径
    local deviation = tbParam.deviation                           -- 炮弹标准偏差
    --local grade = tbParam.grade                                   -- 舰船级别
    return (max_damage*0.3*gun_count_per_group*group_count*0.5*0.25*100/loading_time/(1-burn_prob*burn_damage*30*3)+caliber*hardness+max_range+1/(deviation*deviation))/100*1.67
end

-- 计算护卫舰火炮
local function CalGunFrigate(self, tbParam)
    local max_damage = tbParam.max_damage                         -- 主炮火炮伤害
    local loading_time = tbParam.loading_time                     -- 主炮装填时间
    local max_range = tbParam.max_range                           -- 主炮射程
    local gun_count_per_group = tbParam.gun_count_per_group       -- 主炮每组炮数
    local group_count = tbParam.group_count                       -- 主炮组数
    local burn_prob = tbParam.burn_prob                           -- 点火概率
    local burn_damage = tbParam.burn_damage                       -- 点火伤害
    local hardness = tbParam.hardness                             -- 炮弹硬度
    local caliber = tbParam.caliber                               -- 炮弹口径
    local deviation = tbParam.deviation                           -- 炮弹标准偏差
    local grade = tbParam.grade                                   -- 舰船级别
    return (max_damage*0.25*gun_count_per_group*group_count*0.5*0.3*100/loading_time/(1-burn_prob*burn_damage*30*3)+caliber*hardness+max_range+1/(deviation))/100*(grade*grade*(-0.016)+grade*0.375+2.12)
end

-- 计算炮艇火炮
local function CalGunGunship(self, tbParam)
    local max_damage = tbParam.max_damage                         -- 主炮火炮伤害
    local loading_time = tbParam.loading_time                     -- 主炮装填时间
    local max_range = tbParam.max_range                           -- 主炮射程
    local gun_count_per_group = tbParam.gun_count_per_group       -- 主炮每组炮数
    local group_count = tbParam.group_count                       -- 主炮组数
    local burn_prob = tbParam.burn_prob                           -- 点火概率
    local burn_damage = tbParam.burn_damage                       -- 点火伤害
    local hardness = tbParam.hardness                             -- 炮弹硬度
    local caliber = tbParam.caliber                               -- 炮弹口径
    local deviation = tbParam.deviation                           -- 炮弹标准偏差
    local grade = tbParam.grade                                   -- 舰船级别
    return (max_damage*0.215*gun_count_per_group*group_count*0.5*0.4*100/loading_time/(1-burn_prob*burn_damage*30*3)+caliber*hardness+max_range+1/(deviation))/100*(grade*grade*(-0.025)+grade*0.45+1.7)
end

-- tbParam
--{
--    category = nil,                     -- 舰船类型
--    max_damage = nil,                   -- 主炮火炮伤害
--    loading_time = nil,                 -- 主炮装填时间
--    max_range = nil,                    -- 主炮射程
--    gun_count_per_group = nil,          -- 主炮每组炮数
--    group_count = nil,                  -- 主炮组数
--    burn_prob = nil,                    -- 点火概率
--    burn_damage = nil,                  -- 点火伤害
--    hardness = nil,                     -- 炮弹硬度
--    caliber = nil,                      -- 炮弹口径
--    deviation = nil,                    -- 炮弹标准偏差
--    grade = nil,                        -- 舰船级别
--}
-- 计算火炮
function CalculateShipPropertyHelper:CalGun(tbParam)
    --logdebug("CalGun")
    --local json = require("dkjson")
    --logdebug("tbParam", json.encode(tbParam))
    local nValue = 0
    if tbParam.category == ShipCategory.BattleShip then       -- 战列舰
        nValue = CalGunBattleShip(self, tbParam)
    elseif tbParam.category == ShipCategory.Frigate then      -- 护卫舰
        nValue = CalGunFrigate(self, tbParam)
    elseif tbParam.category == ShipCategory.Gunship then      -- 炮艇
        nValue = CalGunGunship(self, tbParam)
    end
    return NormalizePerformanceValue(nValue)
end

-- 计算战列舰副炮
local function CalSecondaryGunBattleShip(self, tbParam)
    local max_damage = tbParam.max_damage                         -- 副炮火炮伤害
    local loading_time = tbParam.loading_time                     -- 副炮装填时间
    local max_range = tbParam.max_range                           -- 副炮射程
    local gun_count_per_group = tbParam.gun_count_per_group       -- 副炮每组炮数
    local group_count = tbParam.group_count                       -- 副炮组数
    local hit_rate_min = tbParam.hit_rate_min                     -- 最小命中率
    local hit_rate_max = tbParam.hit_rate_max                     -- 最大命中率
    return gun_count_per_group*group_count*0.5*max_damage*0.2/loading_time*(hit_rate_min+hit_rate_max)/2*max_range/100*0.5
end

-- 计算护卫舰副炮
local function CalSecondaryGunFrigate(self, tbParam)
    local max_damage = tbParam.max_damage                         -- 副炮火炮伤害
    local loading_time = tbParam.loading_time                     -- 副炮装填时间
    local max_range = tbParam.max_range                           -- 副炮射程
    local gun_count_per_group = tbParam.gun_count_per_group       -- 副炮每组炮数
    local group_count = tbParam.group_count                       -- 副炮组数
    local hit_rate_min = tbParam.hit_rate_min                     -- 最小命中率
    local hit_rate_max = tbParam.hit_rate_max                     -- 最大命中率
    return gun_count_per_group*group_count*0.5*max_damage*0.2/loading_time*(hit_rate_min+hit_rate_max)/2*max_range/100*5
end

-- tbParam
--{
--    category = nil,                     -- 舰船类型
--    max_damage = nil,                   -- 副炮火炮伤害
--    loading_time = nil,                 -- 副炮装填时间
--    max_range = nil,                    -- 副炮射程
--    gun_count_per_group = nil,          -- 副炮组数
--    group_count = nil,                  -- 副炮每组炮数
--    hit_rate_min = nil,                 -- 最小命中率
--    hit_rate_max = nil,                 -- 最大命中率
--}
-- 计算副炮
function CalculateShipPropertyHelper:CalSecondaryGun(tbParam)
    --logdebug("CalSecondaryGun")
    --local json = require("dkjson")
    --logdebug("tbParam", json.encode(tbParam))
    local nValue = 0
    if tbParam.category == ShipCategory.BattleShip then       -- 战列舰
        nValue = CalSecondaryGunBattleShip(self, tbParam)
    elseif tbParam.category == ShipCategory.Frigate then      -- 护卫舰
        nValue = CalSecondaryGunFrigate(self, tbParam)
    end
    return NormalizePerformanceValue(nValue)
end

-- tbParam
--{
--    max_damage = nil,                   -- 最大伤害
--    loading_time = nil,                 -- 装填时间
--    torpedo_count_per_group = nil,      -- 每组火药桶数
--    group_count = nil,                  -- 组数
--    hit_leak_prob = nil,                -- 命中进水概率
--    leak_damage = nil,                  -- 进水每秒伤害
--    torpedo_speed = nil,                -- 火药桶移动速度
--    max_range = nil,                    -- 最大射程
--    distance_of_found = nil             -- 被发现距离
--}
-- 计算炸药
function CalculateShipPropertyHelper:CalTorpedo(tbParam)
    --logdebug("CalTorpedo")
    --local json = require("dkjson")
    --logdebug("tbParam", json.encode(tbParam))
    local max_damage = tbParam.max_damage                                -- 最大伤害
    local loading_time = tbParam.loading_time                            -- 装填时间
    local torpedo_count_per_group = tbParam.torpedo_count_per_group      -- 每组火药桶数
    local group_count = tbParam.group_count                              -- 组数
    local hit_leak_prob = tbParam.hit_leak_prob                          -- 命中进水概率
    local leak_damage = tbParam.leak_damage                              -- 进水每秒伤害
    local torpedo_speed = tbParam.torpedo_speed                          -- 火药桶移动速度
    local max_range = tbParam.max_range                                  -- 最大射程
    local distance_of_found = tbParam.distance_of_found                  -- 被发现距离
    local nValue = (max_damage/5+group_count*torpedo_count_per_group*0.5*100/loading_time/(1-hit_leak_prob*leak_damage*15*3)*torpedo_speed*max_range/distance_of_found/2)/7.5
    return NormalizePerformanceValue(nValue)
end

-- 计算战列舰隐蔽
local function CalHideBattleShip(self, tbParam)
    local hide_range = tbParam.hide_range                         -- 被发现距离
    local real_view_range = tbParam.real_view_range               -- 发现目标的绝对范围
    local grade = tbParam.grade                                   -- 舰船级别
    local fire_punishment_ratio = tbParam.fire_punishment_ratio   -- 开火惩罚
    local fire_punishment_time = tbParam.fire_punishment_time     -- 惩罚时间
    return (20*grade+100)*5*real_view_range/(hide_range+fire_punishment_ratio+fire_punishment_time)
end

-- 计算护卫舰隐蔽
local function CalHideFrigate(self, tbParam)
    local hide_range = tbParam.hide_range                         -- 被发现距离
    local real_view_range = tbParam.real_view_range               -- 发现目标的绝对范围
    local grade = tbParam.grade                                   -- 舰船级别
    local fire_punishment_ratio = tbParam.fire_punishment_ratio   -- 开火惩罚
    local fire_punishment_time = tbParam.fire_punishment_time     -- 惩罚时间
    return (5*grade*grade+20*grade+300)*4*real_view_range/(hide_range+fire_punishment_ratio+fire_punishment_time)
end

-- 计算炮艇隐蔽
local function CalHideGunship(self, tbParam)
    local hide_range = tbParam.hide_range                         -- 被发现距离
    local real_view_range = tbParam.real_view_range               -- 发现目标的绝对范围
    local grade = tbParam.grade                                   -- 舰船级别
    local fire_punishment_ratio = tbParam.fire_punishment_ratio   -- 开火惩罚
    local fire_punishment_time = tbParam.fire_punishment_time     -- 惩罚时间
    return (9*grade*grade+10*grade+425)*3*real_view_range/(hide_range*1.1+fire_punishment_ratio+fire_punishment_time)
end

--tbParam = 
--{
--    category = nil,                      -- 舰船类型
--    grade = nil,                         -- 舰船级别
--    hide_range = nil,                    -- 被发现距离
--    real_view_range = nil,               -- 发现目标的绝对范围
--    fire_punishment_ratio = nil,         -- 开火惩罚
--    fire_punishment_time = nil           -- 惩罚时间
--}
-- 计算隐蔽
function CalculateShipPropertyHelper:CalHide(tbParam)
    --logdebug("CalHide")
    --local json = require("dkjson")
    --logdebug("tbParam", json.encode(tbParam))
    local nValue = 0
    if tbParam.category == ShipCategory.BattleShip then       -- 战列舰
        nValue = CalHideBattleShip(self, tbParam)
    elseif tbParam.category == ShipCategory.Frigate then      -- 护卫舰
        nValue = CalHideFrigate(self, tbParam)
    elseif tbParam.category == ShipCategory.Gunship then      -- 炮艇
        nValue = CalHideGunship(self, tbParam)
    end
    return NormalizePerformanceValue(nValue)
end

-- 计算战列舰机动
local function CalMovementBattleShip(self, tbParam)
    local max_linear_speed = tbParam.max_linear_speed             -- 最高线速度
    local max_angular_speed = tbParam.max_angular_speed           -- 角速度
    local linear_acceleration = tbParam.linear_acceleration       -- 加速度
    local linear_deceleration = tbParam.linear_deceleration       -- 减速度
    local angular_acceleration = tbParam.angular_acceleration     -- 角加速度
    local angular_deceleration = tbParam.angular_deceleration     -- 角减速度
    local grade = tbParam.grade                                   -- 舰船级别
    return (max_linear_speed*5+linear_acceleration+linear_deceleration+max_angular_speed*5+angular_acceleration+angular_deceleration)*(grade*grade*0.22/32+0.12*grade+1.4525)
end

-- 计算护卫舰机动
local function CalMovementFrigate(self, tbParam)
    local max_linear_speed = tbParam.max_linear_speed             -- 最高线速度
    local max_angular_speed = tbParam.max_angular_speed           -- 角速度
    local linear_acceleration = tbParam.linear_acceleration       -- 加速度
    local linear_deceleration = tbParam.linear_deceleration       -- 减速度
    local angular_acceleration = tbParam.angular_acceleration     -- 角加速度
    local angular_deceleration = tbParam.angular_deceleration     -- 角减速度
    local grade = tbParam.grade                                   -- 舰船级别
    return (max_linear_speed*5+linear_acceleration+linear_deceleration+max_angular_speed*5+angular_acceleration+angular_deceleration)*(grade*grade*0.022+0.04*grade+2.2)
end

-- 计算炮艇机动
local function CalMovementGunship(self, tbParam)
    local max_linear_speed = tbParam.max_linear_speed             -- 最高线速度
    local max_angular_speed = tbParam.max_angular_speed           -- 角速度
    local linear_acceleration = tbParam.linear_acceleration       -- 加速度
    local linear_deceleration = tbParam.linear_deceleration       -- 减速度
    local angular_acceleration = tbParam.angular_acceleration     -- 角加速度
    local angular_deceleration = tbParam.angular_deceleration     -- 角减速度
    local grade = tbParam.grade                                   -- 舰船级别
    return (max_linear_speed*5+linear_acceleration+linear_deceleration+max_angular_speed*5+angular_acceleration+angular_deceleration)*(grade*grade*0.02+0.065*grade+1.84)
end

-- tbParam
--{
--    category = nil,                     -- 舰船类型
--    max_linear_speed = nil,             -- 最高线速度
--    max_angular_speed = nil,            -- 角速度
--    linear_acceleration = nil,          -- 加速度
--    linear_deceleration = nil,          -- 减速度
--    angular_acceleration = nil,         -- 角加速度
--    angular_deceleration = nil,         -- 角减速度
--    grade = nil,                        -- 舰船级别
--}
-- 计算机动
function CalculateShipPropertyHelper:CalMovement(tbParam)
    --logdebug("CalMovement")
    --local json = require("dkjson")
    --logdebug("tbParam", json.encode(tbParam))
    local nValue = 0
    if tbParam.category == ShipCategory.BattleShip then       -- 战列舰
        nValue = CalMovementBattleShip(self, tbParam)
    elseif tbParam.category == ShipCategory.Frigate then      -- 护卫舰
        nValue = CalMovementFrigate(self, tbParam)
    elseif tbParam.category == ShipCategory.Gunship then      -- 炮艇
        nValue = CalMovementGunship(self, tbParam)
    end
    return NormalizePerformanceValue(nValue)
end

return CalculateShipPropertyHelper;
