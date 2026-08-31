local GameObjectTypeDef = 
{
    Undefined           = 0,
    PlayerController    = 1,    -- 只是标记用，没什么实际意义
    PlayerSelf          = 2, 
    PlayerOther         = 3,
    Npc                 = 4,
    Trigger             = 5,
    Dummy               = 6,    -- dummy
    AtmoSphereNpc       = 7,
    AtmoSphereShipNpc   = 8,
    Horse               = 9,
    DestructibleObject  = 10,
}


return GameObjectTypeDef
