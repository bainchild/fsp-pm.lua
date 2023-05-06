local get_cache = {}
function get(url, nocache)
    if get_cache[url]==nil or os.clock()-get_cache[url][1] > 2 or nocache then
        get_cache[url] = {os.clock(), game:GetService("HttpService"):GetAsync(url)}
    end
    return get_cache[url][2]
end
local hostname = get("https://gist.githubusercontent.com/bainchild/e7e951e8c5c837acdf2bdb9633859d92/raw")
function custom_require(name, pre, ...)
    if type(pre) ~= "string" and type(pre) ~= "number" then pre = "" end
    local oldsilent = PM.silent
    if pre == "pm" and false then PM.silent = true end
    local run = coroutine.running()
    local oldpfx = PM.file_prefix[run] or ""
    if PM.enable_relative_requires then
        local split_name = name:split("/")
        local oldname = name
        local nd = ((#split_name > 1 and table.concat(split_name, "/", 1, #split_name - 1)) or "")
        name = ((PM.file_prefix[coroutine.running()] and PM.file_prefix[coroutine.running()].."/") or "")..name
        PM.file_prefix[run] = (oldpfx or "") .. nd
        -- print(oldname," = change file prefix '",oldpfx,"' -> '",PM.file_prefix[run],"'")
    end
    printfm("Requiring /"..pre.."/"..name)
    local url = hostname.."/"..pre.."/"..name
    local s, source = pcall(get, url)
    if not s then s, source = pcall(get, url..".lua") end
    assert(s, "Error while requesting source: "..tostring(source))
    local res
    assert(xpcall(function(...)
        res = {
            setfenv(assert(loadstring(source, name.." "..(pre and "("..pre..")" or ""))), custom_globals_env)(...);
        }
    end, function(...)
        print("error!", ...);
        for i = 0, 256 do
            local r = {debug.info(i, "nsla")}
            if #r > 0 then print(i, unpack(r)) end
        end
        return ...
    end, ...))
    if PM.enable_relative_requires then
        -- local sp = PM.file_prefix[run]:split("/")
        PM.file_prefix[run] = oldpfx
    end
    if pre == "pm" then PM.silent = oldsilent end
    return unpack(res)
end
local old_require = require
require = function(n, ...)
    local r = {pcall(custom_require, n, "pm", ...)}
    if r[1] then
        return unpack(r, 2)
    else
        print("error when requiring,", unpack(r, 2))
    end
    return old_require(n, ...)
end
