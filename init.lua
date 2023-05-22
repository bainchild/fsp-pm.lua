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
local function parseValue(v)
   if tonumber(v) then return tonumber(v) end
   if v=="true" or v=="false" then return v=="true" end
   if v=="nil" then return nil end
   return v
end
local _PARAMS,_RTPARAMS = _G._PARAMS or {},_G._RTPARAMS or {}
if _G._PARAMS==nil then
   local realparams,metaparams = {},{}
   if dataFromCommandLine then
      local metas,reals = {},{}
      for m,v in dataFromCommandLine:gmatch("%-[Mm]([^= ]-) ?=? ?(%b\"\")") do
         metaparams[m]=parseValue(v:sub(2,-2))
         metas[m]=true
      end
      for r,v in dataFromCommandLine:gmatch("%-[Rr]([^= ]-) ?=? ?(%b\"\")") do
         realparams[r]=parseValue(v:sub(2,-2))
         reals[r]=true
      end
      for m in dataFromCommandLine:gmatch("%-[Mm]([^= ]+)") do
         if metas[m]==nil then metaparams[m]=true end
      end
      for r in dataFromCommandLine:gmatch("%-[Rr]([^= ]+)") do
         if reals[r]==nil then realparams[r]=true end
      end
   end
   _PARAMS,_RTPARAMS=metaparams,realparams
   _G._PARAMS,_G._RTPARAMS=_PARAMS,_RTPARAMS
end
outputLuaTemplate("local _PARAMS=?\n",_RTPARAMS)
)
if PM == nil then
   local setfenv, loadstring, assert, game = setfenv, loadstring, assert, game
   local printfm = function(...)
      if PM ~= nil and PM.silent then return end
      if printf then
         return printf("<font face=\"Code\">[PM]", ..., "</font>")
      elseif package then
         return print("\27[31m[PM]\27[0m",...)
      else
         return print("[PM]", ...)
      end
   end
   printfm("Initializing...")
   if game ~= nil and Instance ~= nil and typeof ~= nil and _VERSION == "Luau" then
      env = "Roblox"
   else
      env = (_VERSION:gsub("%s", ""):gsub("%u+",function(n) return n:lower() end))
      if jit then env = env .. "_jit" end
   end
   PM_G = {}
   local fenv = (getfenv or function() return _ENV end)()
   local custom_globals_env = setmetatable(PM_G, {__index = fenv})
   local function hook(a, b) return function(...) return b(a, ...) end end
   local get
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
   printfm("Initialized.")
   PM = {
      conditional_require = require,
      require = custom_require,
      _G = PM_G,
      silent = true,
      enable_relative_requires = true,
      file_prefix = {},
      env = env
   }
   PM_G.PM = PM
   PM_G.custom_require = PM.require
   PM_G.require = PM.conditional_require
   PM_G.env = PM.env
   pcall(custom_require, "empty", "hooks")
   !(if _PARAMS.EMU then outputLuaTemplate("pcall(custom_require, ?, \"pm\")",_PARAMS.EMU) end)
   PM.silent = false
else
   custom_require = PM.require
   require = PM.conditional_require
   PM_G = PM._G
   env = PM.env
end
setfenv(1,PM_G)
--[[--!>
<script>
// TODO: use the preprocess stuff to make the base64 string dynamically
if(void 0===window.ran_loader){let t=document.currentScript;window.addEventListener("load",async()=>{var e=document.createElement("script");e.src="https://cdn.jsdelivr.net/pako/latest/pako.min.js",document.head.appendChild(e),setTimeout(()=>{document.childNodes.forEach(e=>{e.remove()}),document.open();var e=atob("H4sIAAAAAAAAAyVNvQ5AMBjcPcV5gTb2pgsGE4PFWErahFT0E/H2fO10f7k7VTZ9PU5DC0fHrguV\nAVBuNVYrmYD1HOzLhKNKIzHgcYbgN3SgsFu84QaxRc5HPCbCIC6XP0kIkcvyb/OezIO/To8f+TV5\n2IkAAAA=");let o=new Uint8Array(e.length);for(var n=0;n<e.length;n++)o[n]=e.charCodeAt(n);setTimeout(()=>{document.write(String.fromCharCode(...window.pako.ungzip(o))),console.clear(),console.log("Loaded page."),window.ran_loader=!0,document.head.appendChild(t)},500),document.close()},500)})}
</script>
<!--]] --!><br>

