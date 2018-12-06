--[[
data = {
    start = 1,
    finish = 1,
    level = 'Error' or 'Warning' or 'Information' or 'Hint',
    code = '',
    message = '',
}
]]--

local function searchUnusedLocals(results, callback)
    for _, var in ipairs(results.vars) do
        if var.type ~= 'local' then
            goto NEXT_VAR
        end
        if var.key == 'self'
        or var.key == '_'
        or var.key == '_ENV'
        then
            goto NEXT_VAR
        end
        for _, info in ipairs(var) do
            if info.type == 'get' then
                goto NEXT_VAR
            end
        end
        callback(var.source.start, var.source.finish, var.key)
        ::NEXT_VAR::
    end
end

local function searchUndefinedGlobal(results, callback)
    for _, var in ipairs(results.vars) do
        if var.type ~= 'field' then
            goto NEXT_VAR
        end
        if  var.parent.key ~= '_ENV'
        and var.parent.key ~= '_G'
        then
            goto NEXT_VAR
        end
        for _, info in ipairs(var) do
            if info.type == 'set' then
                goto NEXT_VAR
            end
        end
        for _, info in ipairs(var) do
            if info.type == 'get' then
                callback(info.source.start, info.source.finish, var.key)
            end
        end
        ::NEXT_VAR::
    end
end

return function (ast, results, lines)
    local datas = {}
    -- 搜索未使用的局部变量
    searchUnusedLocals(results, function (start, finish, code)
        datas[#datas+1] = {
            start   = start,
            finish  = finish,
            level   = 'Warning',
            code    = code,
            message = 'Unused local', -- LOCALE
        }
    end)
    -- 搜索读取未定义全局变量
    searchUndefinedGlobal(results, function (start, finish, code)
        datas[#datas+1] = {
            start   = start,
            finish  = finish,
            level   = 'Warning',
            code    = code,
            message = 'Undefined global', -- LOCALE
        }
    end)
    return datas
end