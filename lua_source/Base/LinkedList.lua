local LinkedList = {}

LinkedList.New = function(Value)
    local tbRet = {}
    tbRet.Value = Value
    return tbRet
end

LinkedList.Add = function(tbHead, Value)
    local tbRet = {}
    tbRet.Value = Value
    tbRet.Next = tbHead
    return tbRet
end

LinkedList.Remove = function(tbHead, Value)
    local tbNode = tbHead
    local tbLast
    while(tbNode) do
        if(tbNode.Value == Value) then
            tbNode.bDeleted = true
            if(tbLast) then
                tbLast.Next = tbNode.Next
                return tbHead
            else
                return tbNode.Next
            end
        end
        tbLast = tbNode
        tbNode = tbNode.Next
    end
    return tbHead
end

LinkedList.RemoveWithEqualFunc = function(tbHead, fnEqualFunc, ...)
    local tbNode = tbHead
    local tbLast
    while(tbNode) do
        if(fnEqualFunc(tbNode, ...)) then
            tbNode.bDeleted = true
            if(tbLast) then
                tbLast.Next = tbNode.Next
                return tbHead
            else
                return tbNode.Next
            end
        end
        tbLast = tbNode
        tbNode = tbNode.Next
    end
    return tbHead
end

LinkedList.RemoveAllWithEqualFunc = function(tbHead, fnEqualFunc, ...)
    local tbNode = tbHead
    local tbLast
    while(tbNode) do
        if(fnEqualFunc(tbNode, ...)) then
            tbNode.bDeleted = true
            if(tbLast) then
                tbLast.Next = tbNode.Next
            end
        else
            tbLast = tbNode
        end
        tbNode = tbNode.Next
    end
end

LinkedList.Next = function(tbNode)
    if(tbNode == nil) then
        return nil
    end

    repeat
        tbNode = tbNode.Next
    until(tbNode == nil or tbNode.bDeleted == nil)
    return tbNode
end

LinkedList.Iterate = function(tbNode, fnFunc, ...)
    while(tbNode) do
        if(tbNode.bDeleted == nil) then
            if(fnFunc(tbNode, ...)) then
                return tbNode
            end
        end
        tbNode = tbNode.Next
    end
end

return LinkedList