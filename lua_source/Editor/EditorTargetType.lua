local EditorTargetType = {}

EditorTargetType.Common = 1
EditorTargetType.Client = 1<<1 | EditorTargetType.Common
EditorTargetType.BattleServer = 1<<2 | EditorTargetType.Common
EditorTargetType.All = EditorTargetType.Client | EditorTargetType.BattleServer

function EditorTargetType:From(szValue)
    if(szValue == nil) then
        return nil
    end
    return self[szValue]
end

return EditorTargetType