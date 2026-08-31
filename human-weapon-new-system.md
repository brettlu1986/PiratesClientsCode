# 新人物武器系统介绍

## 说明

- GlobalVariableSystem.bEnableNewHumanWeapon 开成true启动游戏即可使用新流程

- 所有的新增文件都放到了HumanWeaponNew文件夹下（Component和System分着放，但文件夹名一样）

- 注意：新流程服务器端没有状态机！

- 所有人物武器相关的包以及rep属性proto 请都放到 battlehumanweapon.proto 中


## 大类

- BattleHumanWeaponSystemNew : 服务器外部接口以及处理包逻辑，以前自动拿起武器，自动装填等操作现在都挪到了这里，component尽量不处理复杂逻辑

- BattleHumanWeaponSystemNew_C : 客户端外部接口（比如UI） 以及处理服务器包逻辑

- HumanWeaponComponentNew : 负责维护管理所有weapon，状态切换，逻辑尽量简单，如果是外部事件触发的行为，尽量放到system中处理

- HumanWeaponXXX : 所有武器，带_C版，HumanWeaponBase是基类

- HumanWeaponMisc : 定义各种武器type，slot等

- HumanWeaponHelper : 提供给Component以及Weapon使用的外部接口。因不想让weapon以及component直接调用xxxsystem或者WeaponSystem，所以单独弄了个helper。都是静态方法，不存状态

- HumanWeaponRepHelper : 负责处理rep属性的绑定以及到客户端的转发。因新流程会将rep属性直接转发到武器上，并且rep属性可能会经常修改，所以单抽出来个类搞rep相关的逻辑，这样component也不需要太关系具体的武器。客户端的属性在Rep会保证时序

- BattleHumanWeaponProcessorNew : 带_C，处理包

- HumanWeaponAttackHelper : 负责以前AttackInfo那块逻辑，现在HumanWeaponComponentNew创建时会创一个helper

- HumanWeaponStateLocalHelper ：以前状态机逻辑，新流程大幅弱化状态机。


## 武器类

### Instant：直接命中的枪
    HumanWeaponInstant -> HumanWeaponGunBase -> HumanWeaponBase

- 攻击流程：

客户端：

    ->UI 攻击按钮按下
    --> BattleHumanWeaponSystemNew_C:RequestStartAttack()，转调到BattleHumanWeaponSystemNew_C，切状态
    ---> LocalStateHelper开始工作，切Attack状态
    ----> HumanWeaponAttackHelper开始工作，触发当前Weapon(HumanWeaponInstant_C)的GenerateAttackInfo
    -----> AttackInfo开始工作触发HumanWeaponInstant_C:AttackInClient(已在AttackInfo中注册)
    ------> 假设是单发武器，那么会走AttackOnce，AttackOnce中会先自己做一次射击(pWeaponActor:CalculateHit()), 如果未命中，直接将未命中信息发给服务器；如果命中则把命中信息发上去

服务器：

    -> 如果收到未命中包，那么经过processor以及system的转发，最终调到RouteAttack，服务器扣完子弹直接修改rep属性(rHumanGunAttackRoute)，转给其他客户端，这个rep属性不同步给玩家自己
    -> 如果收到命中包，那么最后调用HumanWeaponGunBase:AttackOnceInServer
    --> 服务器上来会扣子弹，然后会进行粗校验（HumanWeaponGunBase:CheckAttackHited），如果客户端发上来的的确命中，那么扣伤害，填伤害者是谁，如果没命中，则直接把result包(rHumanGunAttackOnceResult)填好rep给所有玩家

其他客户端（或者自己客户端）：

    -> 通过HumanWeaponRepHelper收到rep包（rHumanGunAttackRoute或者rHumanGunAttackOnceResult，取决于是否纯转发），然后转调回对应的回调（OnRepAttackRoute, OnRepAttackOnceResult）
    --> 触发HumanWeaponGunBase_C:OnHitNotifies，播击中特效。

多发武器流程类似，只不过会走AttackMulti相关的接口

### Melee：近战（包含空手）
    HumanWeaponMelee -> HumanWeaponBase

- 攻击流程：

客户端：

    -> UI 攻击按钮按下
    --> 同枪械攻击一样，Component切Attack状态，生成武器的AttackInfo，然后AttackInfo开始工作
    ---> HumanWeaponMelee_C的AttackInfo分为四步：
        OnPreAttackActivate： 随机play攻击动作，然后将攻击动作索引发给服务器（SendMeleeAttackRoute），服务器转发给其他人
        OnPreAttackDeactivate： pUEActor.bEmptyHandAttacking = false
        OnPostAttackActivate： 攻击判定，如果命中目标，则发给服务器校验（SendMeleeAttackRequest）
        OnPostAttackDeactivate： 收回胳膊，然后pUEActor.bEmptyHandAttacking = false

服务器：

    -> 先收到MeleeAttackRoute包，直接转发给其他人，同时根据上传的montage信息起个timer，通过timer的存在与否来判断整个攻击状态
    -> 如果客户端命中，服务器收到MeleeAttackRequest，上来会先判断是否在攻击状态（上面步骤的timer），然后CheckAttackHited
    --> 如果命中则扣血，然后发送rHumanMeleeAttackHits，未命中则什么都不做

客户端：

    -> 通过repHelper转调到OnRepAttackRoute，播攻击动作
    -> 如果服务器命中则所有客户端都会收到OnRepAttackHits，播击中特效


### Projectile: 导弹类枪械
    HumanWeaponProjectile -> HumanWeaponGunBase -> HumanWeaponBase


### Throw: 投掷物（手雷，飞刀等）
    HumanWeaponThrow -> HumanWeaponBase

