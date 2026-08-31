local CheckParamUtil = {}

function CheckParamUtil.table( varParam )
    if varParam ~= nil and type(varParam) ~= 'table' then
        error('param is not a table')
    end
end

function CheckParamUtil.string( varParam )
    if type(varParam) ~= 'string' then
        error('param is not a string')
    end
end

function CheckParamUtil.number( varParam )
    if type(varParam) ~= 'number' then
        error('param is not a number')
    end
end

function CheckParamUtil.boolean( varParam )
    if type(varParam) ~= 'boolean' then
        error('param is not a boolean')
    end
end

return CheckParamUtil