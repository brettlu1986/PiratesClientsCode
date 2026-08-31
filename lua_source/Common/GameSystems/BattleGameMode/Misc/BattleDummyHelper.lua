local BattleDummyHelper = {}

BattleDummyHelper.tbDummies = nil

function BattleDummyHelper:Init()
    self.tbDummies = {}
end

function BattleDummyHelper:Uninit()
    self.tbDummies = nil
end

function BattleDummyHelper:AddDummy(nGroupId, tbDummy)
    if self.tbDummies[nGroupId] == nil then 
        self.tbDummies[nGroupId] = {}
    end
    table.insert( self.tbDummies[nGroupId], tbDummy )
end

function BattleDummyHelper:GetDummiesByGroupId(nGroupId)
    if self.tbDummies[nGroupId] == nil then 
        return nil
    end 
    return self.tbDummies[nGroupId]
end

function BattleDummyHelper:DeleteDummiesByGroupId(nGroupId)
    self.tbDummies[nGroupId] = nil
end

return BattleDummyHelper