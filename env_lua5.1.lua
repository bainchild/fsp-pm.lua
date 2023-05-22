local http_request = require "http.request"
local get_cache = {}
local CORO_MAIN = newproxy(true)
local function thread_id()
   return coroutine.running() or CORO_MAIN
end
local function raw_get(uri)
   --print("rq",uri)
   local headers, stream = assert(http_request.new_from_uri(uri):go())
   local body = assert(stream:get_body_as_string())
   if headers:get ":status" ~= "200" then
      error(body)
   end
   return body
end
local function split(a,b)
   local n = {}
   for m in (a..b):gmatch("(.-)"..b) do
      table.insert(n,m)
   end
   return n
end
function get(url, nocache)
   if get_cache[url]==nil or os.clock()-get_cache[url][1] > 2 or nocache then
      get_cache[url] = {os.clock(), raw_get(url)}
   end
   return get_cache[url][2]
end
local hostname = "http://0.0.0.0:8000"--get("https://gist.githubusercontent.com/bainchild/e7e951e8c5c837acdf2bdb9633859d92/raw")
function custom_require(name, pre, ...)
   if type(pre) ~= "string" and type(pre) ~= "number" then pre = "" end
   local oldsilent = PM.silent
   if pre == "pm" and false then PM.silent = true end
   local run = thread_id()
   local oldpfx = PM.file_prefix[run] or ""
   if PM.enable_relative_requires then
      local split_name = split(name,"/")
      local oldname = name
      local nd = ((#split_name > 1 and table.concat(split_name, "/", 1, #split_name - 1)) or "")
      name = ((PM.file_prefix[thread_id()] and PM.file_prefix[thread_id()].."/") or "")..name
      PM.file_prefix[run] = (oldpfx or "") .. nd
      -- print(oldname," = change file prefix '",oldpfx,"' -> '",PM.file_prefix[run],"'")
   end
   printfm("Requiring /"..pre.."/"..name)
   local url = hostname.."/"..pre.."/"..name
   local s, source = pcall(get, url)
   if not s then s, source = pcall(get, url..".lua") end
   assert(s, "Error while requesting source: "..tostring(source))
   if split(source,"\n")[1]:sub(1,2)=="#!" then
      source = split(source,"\n")
      table.remove(source,1)
      source=table.concat(source,"\n")
   end
   local res
   assert(xpcall(function(...)
      res = {
         setfenv(assert(loadstring(source, name.." "..(pre and "("..pre..")" or ""))), custom_globals_env)(...);
      }
   end, function(...)
      print("error!", ...);
      for i = 0, 256 do
         local r = debug.getinfo(i, "nSl")
         if r~=nil and #r > 0 then
            local a = {}
            for _,v in pairs(r) do table.insert(a,v) end
            print(i,unpack(a))
         end
      end
      return ...
   ---@diagnostic disable-next-line: redundant-parameter
   end, ...))
   if PM.enable_relative_requires then
      PM.file_prefix[run] = oldpfx
   end
   if pre == "pm" then PM.silent = oldsilent end
   return unpack(res)
end
local old_require = require
require = function(n, ...)
   --local old_silent = PM.silent
   --PM.silent = true
   local r = {pcall(custom_require, n, "pm", ...)}
   --PM.silent = old_silent
   if r[1] then
      return unpack(r, 2)
   --else
   --	print("error when requiring,", unpack(r, 2))
   end
   return old_require(n, ...)
end
