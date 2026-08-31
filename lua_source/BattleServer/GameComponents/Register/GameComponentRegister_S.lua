local luaclass = require("luaclass")
local GameComponentRegisterClass = require("GameComponentRegister")
local GameComponentRegister_S = luaclass("GameComponentRegister_S", GameComponentRegisterClass)

--local GameComponentTypeDefine = require("GameComponentTypeDefine")

-- local C = GameComponentTypeDefine.tbClassType
-- local E = GameComponentTypeDefine.tbEnvironmentType
-- local A = GameComponentTypeDefine.tbActorType
-- local L = GameComponentTypeDefine.tbLifeCycleType    

-- GameComponentCreateHelper:Register(szClassName, nType, nEnvironmentType, nActorType, nLifeCycleType, bDynamicRequire, szComponentName)
-- szClassName: require的component名称
-- nObjectType: Object的类别，值参考GameComponentTypeDefine.tbObjectClassType
-- nEnvironmentType：战斗或者公海，值参考GameComponentTypeDefine.tbEnvironmentType
-- nActorType：船或者人，值参考GameComponentTypeDefine.tbActorType
-- nLifeCycleType：Component的生命周期，WithUEActor：随着UEActor创建和销毁，WithGameObject，随着GameObject创建和销毁，与UEActor的生命周期无关
-- bDynamicRequire：是否需要dynamic_require
-- szComponentName：生成的成员变量名称，默认nil，生成和szClassName一样的成员变量，GameObject创建完Component后可以直接使用GameObject.ComponentName访问


function GameComponentRegister_S:RegisterComponents(GameComponentCreateHelper)
    GameComponentRegister_S.super.RegisterComponents(self, GameComponentCreateHelper)

    --local H = GameComponentCreateHelper

    -- GameCharacter

    -- GamePlayer

    -- GamePlayerSelf

    -- GamePlayerOther

    -- GameNpc
end

return GameComponentRegister_S