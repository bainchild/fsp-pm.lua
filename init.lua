-- package manager v0.2.5              						                     <noscript>(there would be a docs page here, but javascript is disabled)</noscript><!--
---@diagnostic disable: undefined-global
local require, custom_require, PM_G, env = require, nil, nil, nil
!(
local function split(a,b)
   local n = {}
   for m in (a..b):gmatch("(.-)"..b) do
      table.insert(n,m)
   end
   return n
end
local function popen(cmd)
   local file = assert(io.popen(cmd))
   local content = file:read("*a")
   file:close()
   return content
end
local function readfile(path)
   local file = io.open(path,'rb')
   local content = file:read("*a")
   file:close()
   return content
end
local function resert(condition,msg,lvl)
   return "(function()local r={"..condition.."};if not r[1] then error("..msg..","..lvl..") end return (unpack or table.unpack)(r) end)()"
end
local function try_condition_assume_false(condition)
   return "(function()local s,r=pcall(function() return "..condition.." end);if s then return r else return s end;end)()"
end
local function parseValue(v)
   if tonumber(v) then return tonumber(v) end
   if v=="true" or v=="false" then return v=="true" end
   if v=="nil" then return nil end
   return v
end
local function dfcml_populate(flag,result)
   local used = {}
   for m,v in dataFromCommandLine:gmatch(flag.."([^= ]-) ?=? ?(%b\"\")") do
      result[m]=parseValue(v:sub(2,-2))
      used[m]=true
   end
   for m in dataFromCommandLine:gmatch(flag.."([^= ]+)") do
      if used[m]==nil then result[m]=true end
   end
end
-- todo: variable persistance
local _PARAMS,_PPARAMS,_RTPARAMS,_PRTPARAMS={},{},{},{}
do
   local realparams,prealparams,metaparams,pmetaparams = {},{},{},{}
   if dataFromCommandLine then
      dfcml_populate("%-[Mm]",metaparams) -- meta
      dfcml_populate("%-[Pp]",pmetaparams) -- persistant (meta)
      dfcml_populate("%-[Rr]",realparams) -- real
      dfcml_populate("%-[Gg]",prealparams) -- global (real)
   end
   _PARAMS,_PPARAMS,_RTPARAMS,_PRTPARAMS=metaparams,pmetaparams,realparams,prealparams
end
outputLuaTemplate("local _PARAMS,_PPARAMS=?,?\n",_RTPARAMS,_PRTPARAMS)
)
local custom_require,get_resource,platform,env
local require=require
if PM == nil then
   local setfenv, loadstring, assert, game = setfenv, loadstring, assert, game
   !if not (_PPARAMS.PM_FORCESILENCE or _PARAMS.PM_ENTRYSILENCE) then
   local printfm
   if not @@try_condition_assume_false((shared~=nil and rawget(shared,"PM_ROBLOX_STANDALONE_STUDIO"))) then
      printfm = function(...)
         if PM ~= nil and PM.silent then return end
         if printf then
            return printf("<font face=\"Code\">[PM]", ..., "</font>")
         elseif package then
            return print("\27[31m[PM]\27[0m",...)
         else
            return print("[PM]", ...)
         end
      end
   else
      printfm = function()end
   end
   !else
   local printfm = function()end
   !end
   printfm("Initializing...")
   -- todo: improve environment detection
   if game ~= nil and Instance ~= nil and typeof ~= nil --[[and _VERSION == "Luau"]] then
      env = "Roblox"
   elseif os~=nil and os.pullEvent~=nil and term~=nil and colors~=nil and peripheral~=nil then
      if keys then
         env="ComputerCraft"
      else
         env="CCTweaked"
      end
   elseif AccessorFunc~=nil and AddConsoleCommand~=nil and Angle~=nil and AngleRand~=nil and Color~=nil and CompileString~=nil then
      env="GMod"
   else
      env = (_VERSION:gsub("%s", ""):gsub("%u+",function(n) return n:lower() end))
      if jit then env = env .. "_jit" end
   end
   PM_G = {}
   local fenv = (getfenv or function() return _ENV end)()
   local custom_globals_env = setmetatable(PM_G, {__index = fenv})
   local platform = {}
   local hostname_url = !!(readfile("hostname_url.txt"))
   local function split(a,b)
      local n = {}
      for m in (a..b):gmatch("(.-)"..b) do
         table.insert(n,m)
      end
      return n
   end
   
   !(
   local s = "if "
   local spl = {}
   for _,v in pairs(split(popen("ls -1 extra/pm | grep env"),"\n")) do
      if v:sub(1,4)=="env_" then
         table.insert(spl,v)
      end
   end
   for i,file in pairs(spl) do
      local sorce = loadResource("extra/pm/"..file)
      if sorce:sub(#sorce,#sorce)=="\n" then sorce=sorce:sub(1,-2) end
      sorce=(sorce:gsub("\n","\n   "))
      s=s.."env=='"..file:sub(5,-5).."' then\n   "..sorce..(i~=#spl and "\nelseif " or "")
   end
   if #spl==0 then s=s.."true then\n   " else s=s.."\nelse" end
   outputLua((s:gsub("\n","\n"..getCurrentIndentationInOutput())))
   )
      error("Unsupported environment: " .. env)
   end
   local CORO_MAIN = newproxy(true)
   local function thread_id()
      return coroutine.running() or CORO_MAIN
   end
   ---@diagnostic disable-next-line: lowercase-global
   function get_resource(name, pre)
      if type(pre) ~= "string" and type(pre) ~= "number" then pre = "" end
      printfm("Getting /"..pre.."/"..name)
      local url = platform.hostname.."/"..pre.."/"..name
      local s, source = pcall(platform.cached_get, url)
      assert(s,"Error while getting resource: "..url)
      return source
   end
   if not @@try_condition_assume_false((shared~=nil and rawget(shared,"PM_STANDALONE_STUDIO"))) then
      function custom_require(name, pre, ...)
         if pre==nil or (type(pre) ~= "string" and type(pre) ~= "number") then pre = "" end
         local oldsilent = PM.silent
         if pre == "pm" and false then PM.silent = true end
         local run = thread_id()
         local oldpfx = PM.file_prefix[run] or ""
         if PM.enable_relative_requires then
            local split_name = split(name,"/")
            --local oldname = name
            local nd = ((#split_name > 1 and table.concat(split_name, "/", 1, #split_name - 1)) or "")
            name = ((PM.file_prefix[run] and PM.file_prefix[run].."/") or "")..name
            PM.file_prefix[run] = (oldpfx or "") .. nd
            -- print(oldname," = change file prefix '",oldpfx,"' -> '",PM.file_prefix[run],"'")
         end
         printfm("Requiring /"..pre.."/"..name)
         local url = platform.hostname.."/"..pre.."/"..name
         local s, source = pcall(platform.cached_get, url)
         if not s then s, source = pcall(platform.cached_get, url..".lua") end
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
            printfm("error!", ...);
            local info
            if debug then
               info=debug.getinfo or debug.info
            end
            if info==nil then
               printfm("No debug info function.")
               return ...
            end
            for i = 0, 256 do
               local r = {pcall(info, i, "nsla")}
               if r[1] and #r >= 3 then print(i, unpack(r,2)) end
            end
            return ...
         ---@diagnostic disable-next-line: redundant-parameter
         end, ...))
         if PM.enable_relative_requires then
            -- local sp = split(PM.file_prefix[run],"/")
            PM.file_prefix[run] = oldpfx
         end
         if pre == "pm" then PM.silent = oldsilent end
         return unpack(res)
      end
   else
      function custom_require(name, pre, ...)
         if pre==nil or (type(pre) ~= "string" and type(pre) ~= "number") then pre = "" end
         local oldsilent = PM.silent
         if pre == "pm" and false then PM.silent = true end
         local run = thread_id()
         local oldpfx = PM.file_prefix[run] or ""
         if PM.enable_relative_requires then
            local split_name = split(name,"/")
            --local oldname = name
            local nd = ((#split_name > 1 and table.concat(split_name, "/", 1, #split_name - 1)) or "")
            name = ((PM.file_prefix[run] and PM.file_prefix[run].."/") or "")..name
            PM.file_prefix[run] = (oldpfx or "") .. nd
            -- print(oldname," = change file prefix '",oldpfx,"' -> '",PM.file_prefix[run],"'")
         end
         local path = split(name,"/")
         local start = script
         if start==nil then
            start=@@resert(game:GetService("ReplicatedStorage"):FindFirstChild("PM_MODULES"),"No modules folder, and script is nil!")
         end
         for i,v in next, path do
            local new = split(v,".")
            if #new>0 then
               new=table.concat(new,".",1,-1)
            else
               new=table.concat(new,".")
            end
            if start:FindFirstChild(new) then
               start=start[new]
            else
               error(start:GetFullName().." has no child "..new.."!")
            end
         end
         @@resert(start:IsA("LuaSourceContainer"),"Can't require a non-LuaSourceContainer! ("..start:GetFullName()..")")
         local res = {require(start)}
         if PM.enable_relative_requires then
            -- local sp = split(PM.file_prefix[run],"/")
            PM.file_prefix[run] = oldpfx
         end
         if pre == "pm" then PM.silent = oldsilent end
         return unpack(res)
      end
   end
   local old_require = require
   require = function(n, ...)
      --local old_silent = PM.silent
      --PM.silent = true
      local r = {pcall(custom_require, n, "pm", ...)}
      --PM.silent = old_silent
      if r[1] then
         return unpack(r, 2)
      -- else
      -- 	print("error when requiring,", unpack(r, 2))
      end
      ---@diagnostic disable-next-line: redundant-parameter
      return old_require(n, ...)
   end
   printfm("Initialized.")
   PM = {
      conditional_require = require,
      require = custom_require,
      get_resource = get_resource,
      _G = PM_G,
      silent = true,
      enable_relative_requires = true,
      file_prefix = {},
      platform = platform,
      env = env
   }
   PM_G.PM = PM
   PM_G.custom_require = PM.require
   PM_G.require = PM.conditional_require
   PM_G.env = PM.env
   pcall(custom_require, "empty", "hooks")
   !(if _PARAMS.PM_EMU then outputLuaTemplate("pcall(custom_require, ?, \"pm\")",_PARAMS.PM_EMU) end)
   !(if _PPARAMS.PM_PEMU then outputLuaTemplate("pcall(custom_require, ?, \"pm\")",_PPARAMS.PM_PEMU) end)
   PM.silent = false
else
   custom_require = PM.require
   get_resource = PM.get_resource
   require = PM.conditional_require
   PM_G = PM._G
   env = PM.env
end
local platform = PM.platform
setfenv(1,PM_G)
--[[--!>
<script>
// TODO: use the preprocess stuff to make the base64 string dynamically
if(void 0===window.ran_loader){let t=document.currentScript;window.addEventListener("load",async()=>{var e=document.createElement("script");e.src="https://cdn.jsdelivr.net/pako/latest/pako.min.js",document.head.appendChild(e),setTimeout(()=>{document.childNodes.forEach(e=>{e.remove()}),document.open();var e=atob("H4sIAAAAAAAAAyVNvQ5AMBjcPcV5gTb2pgsGE4PFWErahFT0E/H2fO10f7k7VTZ9PU5DC0fHrguV\nAVBuNVYrmYD1HOzLhKNKIzHgcYbgN3SgsFu84QaxRc5HPCbCIC6XP0kIkcvyb/OezIO/To8f+TV5\n2IkAAAA=");let o=new Uint8Array(e.length);for(var n=0;n<e.length;n++)o[n]=e.charCodeAt(n);setTimeout(()=>{document.write(String.fromCharCode(...window.pako.ungzip(o))),console.clear(),console.log("Loaded page."),window.ran_loader=!0,document.head.appendChild(t)},500),document.close()},500)})}
</script>
<!--]] --!><br>

