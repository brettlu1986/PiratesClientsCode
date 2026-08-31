local PropNameDestructible = {}

PropNameDestructible.bReplicate = false

function PropNameDestructible.Init(Define, T, R)
    Define("nDestructibleObjectHp",               T.Float)
end

return PropNameDestructible