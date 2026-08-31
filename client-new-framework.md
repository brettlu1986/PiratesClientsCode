# 客户端框架简介

<!-- TOC depthFrom:2 depthTo:6 insertAnchor:false orderedList:false updateOnSave:true withLinks:true -->

- [Lua、蓝图、C++的层次关系](#lua蓝图c的层次关系)
- [Lua层](#lua层)
    - [主要概念](#主要概念)
    - [关键类介绍](#关键类介绍)
    - [运行时调用关系](#运行时调用关系)
- [C++层](#c层)
    - [原则](#原则)
    - [模块](#模块)
    - [主要概念](#主要概念-1)
- [蓝图层](#蓝图层)

<!-- /TOC -->

## Lua、蓝图、C++的层次关系

- Lua作为主逻辑层，驱动游戏进行，各种逻辑系统、UI都在Lua层实现
- 战斗、技能模块用蓝图实现，尽可能利用虚幻原生机制
- C++层则作为粘合剂以及底层支持存在于游戏中

## Lua层

### 主要概念
    
这里之所以强调以下概念，一是统一叫法，以往项目的Manager、System乱七八糟的随便叫，理解起来很容易混乱；
更重要的是想要约束系统或者功能的位置以及范围，为写策划逻辑的人提供写逻辑的地方，其他地方不要入侵，在保证整体框架稳定的基础上提供逻辑扩展的便利性。
 
- Base、Client、Common、BattleServer模块

    - Base是最底层，大多是一些基础工具类，留下它有一定的历史原因。
    - Common继承Base，Common会在客户端和服务器都运行，其中包含了大部分框架基类，除此外还有一部分需要同时跑在客户端和副本服务器的代码（比如战斗相关或者一些两边都有的System）
    - Client继承Common，只会在客户端运行，UI，Procedure都在此模块
    - BattleServer只是副本服务器会用到，大多是服务器专有逻辑
    

- Manager
    
    游戏内各种管理器，原则上与策划逻辑关系不是很紧密，主要负责管理游戏内各种物体或者系统。举例：
    
    - DataTableManager 读表
    - MessageProcessorManager 管理Processer
    - EventManager 事件收发
    - GameSystemManager 管理各种游戏逻辑系统
    - ProcedureManager 管理游戏进行的状态
    - ClientNetworkManager 管理客户端网络
    - SoundManager 音乐音效
    - UIManager UI管理器
    - GameObjectManager 野外物体管理器
    - GameSceneManager 野外场景管理器
    - BattleActorManager 战斗种物体管理
    - BattleWorldManager 战斗世界管理
    - 等等...

    所有的Manager随着研发推进，理论上应该慢慢稳定下来，如果到最后还是在频繁修改，那么应该考虑挪到System里。
    

- GameSystem

    游戏各个逻辑系统，跟策划密切相关的系统，可随着策划案修改而修改。
    原则上System负责比较复杂的操作，数据则存储在Component里。
    每个System都是单例。举例：

    - ArenaSystem 竞技场系统
    - ChatSystem 聊天系统
    - CurrencySystem 货币系统
    - DorkSystem 船坞系统
    - GMSystem GM系统
    - ItemSystem 道具系统
    - LoadingSystem 负责管理Loading过程
    - NPCSystem 管理NPC创建销毁等
    - TradeSystem 交易
    - TeamSystem 组队
    - 等等...

    所有跟策划密切相关或者需求频繁改动的系统都应该归属于System下

- GameComponent

    游戏内数据以及轻量操作的载体，挂在逻辑对象上（GameObject or BattleActor），每个逻辑对象都会有很多个不同功能的Component，即可以System配套使用，也可以单独使用。举例：

    - ArenaComponent 竞技场存储数据，挂在主角身上，跟ArenaSystem配套使用，
    - CameraComponent 摄像机操作代理，挂在主角身上
    - DockComponent 船坞数据，跟DorkSystem配套使用
    - ShipPropertyComponent 船属性集合，挂在所有船身上
    - ShipMovementHubModeComponent 负责野外移动时船操控，挂在船身上
    - ShipSkillComponent 船的技能
    - 等等...

- Processor

    Lua层与C++或者网络的接口，粘合游戏逻辑，主要分为两种：

    - PacketProcessor 接收网络包协议，将协议转成逻辑数据，然后分发给各个模块，例如：

        - GlobalPacketProcessor 处理与HubServer的连接与断开
        - ArenaPacketProcessor 处理竞技场协议
        - ChatPacketProcessor 处理聊天协议
        - ItemPacketProcessor 处理道具协议
        - UIPacketProcessor 处理一些直接跟ui打交道的协议，比如对话时弹哪些选项什么的
        - WildWorldPacketProcessor 处理野外大世界创建销毁玩家协议、进入副本协议等
        - BattlePacketProcessor 处理退出副本协议
        - 等等...

    - DelegateProcessor 接收跟C++层或者蓝图的Delegate调用，然后调用相关模块，例如：

        - GameModeCppDelegateProcessor GameMode的Delegate处理
        - LevelCppDelegateProcessor 跟Level相关的Delegate处理
        - 等等...

- Event

    EventManager处理Lua层的事件，任何地方可以发送事件，也可以绑定某个事件的处理函数，收到事件后进行处理。

- UI

    使用虚幻的UMG，界面逻辑则在lua里编写，具体请阅读目录里UI的相关文档
    
    Processor接收数据转发，GameSystem修改数据，GameComponent存储数据，EventManager发送处理事件，UI处理交互逻辑。有了这几样东西，基本上一个策划需求的功能系统就可以跑通了。          

- Procedure
    
    运行时游戏内的各种状态（更新、登录、公海、战斗等），控制整个游戏的进行。

- GameObject

    公海上的物体统称，对虚幻的Actor进行了一系列封装，是Component的载体，控制Component的创建销毁

- BattleActor

    战斗里的物体统称，对虚幻的Actor进行了一系列封装，是Component的载体，控制Component的创建销毁

    在最开始设计时由于项目需求不是很清晰，再加上需要快速开发，所以当时的决定是物体管理公海走一套，战斗走另一套，两边各自独立，这样两边谁都不影响谁，所以形成了GameObject和BattleActor共存的现状。
    但经过一两个版本的迭代后，现在两套物体管理的机制导致外部系统在使用时必须考虑两种情况（战斗与非战斗），写起来很累而且很容易出问题。
    所以在对战斗物体的需求以及整个战斗的开发流程有了一定的认识后，考虑这两套系统能否合并成一套，就算不能也要把两套系统对外部的差异性尽量去掉，方便外部系统使用。
    公海的物体管理(GameObject)很简单，收到协议创建销毁GameObject，GameObject内部逻辑也比较简单；
    但战斗Actor相对来讲就复杂了一些，其创建销毁都要依赖虚幻的Actor同步机制，很多Actor用到的方法也必须开到lua里，然后lua里处理完在返回c++，流程上相互交互的点比较多，时序也比较复杂，所以后面主要还是得看战斗内的流程是否能优化。

- DataTable

    数据表

- Register

    各种东西的注册器，现在游戏中有下面几种:
    - ManagerRegister 所有的Manager在这里注册
    - GameSystemRegister 所有GameSystem在这里注册
    - DataTableRegister 数据表注册
    - MessageProcessorRegister Processor注册
    

### 关键类介绍

- ManagerRoot

    负责所有Manager的生命周期管理，现在的生命周期分为几个组（如下），当激活某个组时会调用对应Manager的Init方法，组退出时会调用Manager的Uninit

    - ImmortalGroup: 启动游戏到终止游戏一直存在
    - DefaultGroup: 默认组，会在更新流程后激活，重新登录则会退出
    - WildGroup: 野外大世界组，进入野外大世界（公海或者主城）时会激活， 离开后会退出
    - BattleGroup: 战斗组，进入副本战斗会激活，离开会退出

- ProcedureManager

    管理游戏的运行状态，具体状态如下，运行时状态间切换基本也按照此顺序，未来还可能会加入新的状态
    
    - Procedure_StartGame 启动游戏（未来这里可能还会加个SplashProcedure，需要显示健康公告或者公司logo什么的）
    - Procedure_Dispatcher 从Dispatcher服务器抓取各种信息（资源服务器ip，公告，各种参数等）
    - Procedure_VersionCheck 抓取最新的资源版本号，检查本地版本是否最新，不是则进入Procedure_Update，否则进入Procedure_ServerList
    - Procedure_Update 从资源服务器上抓取最新patch，对游戏资源进行更新
    - Procedure_ServerList 获取服务器列表
    - Procedure_Login 显示登录界面，如果是新账号则进入Procedure_SelectRole，否则进入Procedure_WildWorld
    - Procedure_SelectRole 创建角色流程
    - Procedure_WildWorld 进入公海或者主城
    - Procedure_Battle 进入战斗

- DataTableManager

    负责读取各种数据表

- EventManager

    接收发送事件

- GameSystemManager

    管理所有GameSystem，负责所有GameSystem的创建销毁

- GameObjectManager

    野外物体管理，管理GameObject

- BattleActorMananger

    战斗物体管理，管理BattleActor

- ClientNetworkManager

    网络管理，封装了C++的一些接口


### 运行时调用关系

![](client-new-framework-img/client-new-framework-01.jpg)
    

## C++层

### 原则

- 尽量轻，重逻辑都挪到lua或者蓝图里，方便热更
- 各种底层接口扩展
- 各种delegate
- 网络封装
- 要求效率的功能（移动等）
- 跟逻辑相关性不大的通用功能（读写表、Json转换、Protobuf转换等）
- 虚幻战斗框架的扩展

### 模块

- EngineExt: 游戏扩展引擎接口，包括游戏自己的Actor，GameMode等
- Common: 客户端服务器公用的功能
- Client: Input等
- Server: Player管理，场景管理等
- Editor: 各种编辑器

Common、Client、Server与lua的模块一一对应

### 主要概念

C++层把逻辑都集中到了两个类里，一个是GameXXX，负责C++中的游戏逻辑管理，一个是XXXShell，负责把C++的接口开给蓝图或者lua。
XXX代表模块（EngineExt、Common、Client、Server）。
之所以定义这两种类，是为了将C++中的逻辑集中在一起，而不是像以往一样逻辑到处写，弄的哪都是。
没有做太多别的结构是因为虚幻本身提供了一套完整的游戏框架，而且大部分业务逻辑都放在Lua，所以C++层本身的量应该很少，最终弄了这两种类，一个写逻辑一个写接口，简单易用方便扩展和理解。
   

- GameXXX

    - 把游戏用到的功能尽量放到此类中，可以有部分简单逻辑，有点类似GameInstance或者lua里的GameSystemManager的概念
    - 包括 GameEngineExt, GameCommon, GameClient, GameServer
    - GameEngineExt是最底层的Game管理，对应EngineExt模块，GameCommon继承GameEngineExt，GameClient和GameServer都继承GameCommon
    - 一个GameInstance拥有一个GameClient或者GameServer（取决于到底是客户端还是服务器）
    - C++层根据WorldContext可以通过静态方法获取
    - 蓝图或者Lua无法直接获取
    

- XXXShell
    
    - 把需要开给Lua或者蓝图的接口放在这里，比如各种Delegate，也会吧GameXXX中的一些逻辑功能封装成接口开给Lua或者蓝图用
    - 包括 EngineExtShell, CommonShell, ClientShell, ServerShell
    - EngineExtShell对应GameEngineExt，CommonShell继承EngineExtShell，ClientShell和ServerShell继承CommonShell
    - 一个GameInstance拥有一个ClientShell或者ServerShell（取决于到底是客户端还是服务器）
    - C++层和蓝图以及lua层都可以通过静态方法获取
    - 原则上需要暴露的接口才放到这里，不需要的则尽量放到GameXXX进行处理
    

## 蓝图层

- 副本建立在虚幻原生机制上（Client，Standalone，DelicatedServer模式），请阅读虚幻官方文档
- 战斗技能系统本身用蓝图实现
- 进入战斗后Lua以及C++主要是辅助作用，主要战斗逻辑都在蓝图
- 不同的副本玩法（GameMode）在lua里实现（GameModeSystem）
- 非战斗系统则尽量把蓝图当做配置来使用，业务逻辑或者框架尽量放到lua或者C++层
- 使用蓝图当做编辑器扩展
