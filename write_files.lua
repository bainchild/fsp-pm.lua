#!/bin/lua5.1
local script_loc = arg[0]
local function usage(c)
   print("Usage: "..script_loc.." [preload directory]")
   print("if directory is omitted, it will try current directory and parent directory.")
   os.exit(c or 0)
end
local function split(a,b)
	local m = {}
	for mat in (a..b):gmatch("(.-)"..b) do
		table.insert(m,mat)
	end
	return m
end
local execute = function(...)
	print(">",...)
	return os.execute(...)
end
local function is_file(f)
	return execute("test -f '"..f.."'")==0
end
local function is_folder(f)
	return execute("test -d '"..f.."'")==0
end
local function link(a,b)
	return execute("ln '"..a.."' '"..b.."'")==0
end
local function copy(a,b)
	return execute("cp -r '"..a.."' '"..b.."'")==0	
end
local function move(a,b)
	return execute("mv '"..a.."' '"..b.."'")==0	
end
local function remove(a)
	return execute("rm -r '"..a.."'")==0
end
local function get_variable(n)
	local f = io.popen("echo "..n)
	local c = f:read("*a")
	f:close()
	return c
end
local function popen(cmd)
	print(">",cmd)
	local f = io.popen(cmd)
	local content = f:read("*a")
	return content, get_variable("$?")
end
local function dirname(a)
	return popen("dirname "..a):sub(1,-2)
end
local function realpath(a)
	return popen("realpath '"..a.."'"):sub(1,-2)
end
local function inode(a)
	return split(popen("ls -li '"..a.."'")," ")[1]
end
local function readlink(a,base)
	local r,s = popen("readlink '"..a.."'")
	if s==0 then return r end
	r=popen("find "..base.." -inum "..inode(a))
	r=split(r,"\n")
	if #r~=0 then
		for i,v in pairs(r) do
			if v~=a then
				return v
			end
		end
	end
	print("Couldn't find hardlink inode match.")
	return nil
end
local function exists(a)
   return is_file(a) or is_folder(a)
end
local function has_preload(a)
   return exists(a.."/".."preload") and exists(a.."/".."public")
end

local script_dir = dirname(script_loc)
local path = arg[1]
if path==nil then
   if has_preload(".") then
      path="."
   elseif has_preload("..") then
      path=".."
   else
      usage(2)
   end
elseif path~="--help" and path~="-h" then
	if not has_preload(path) then
		usage(1)
	end
else
	usage(0)
end
if not exists(path.."/extra") then
	 os.execute("mkdir '"..path.."/extra'")
end

if exists(path.."/extra/pm") then
	if realpath(path.."/extra/pm")~=realpath(script_dir) then
		move(path.."/extra/pm",path.."/extra/pm.old")
		copy(script_dir,path.."/extra/pm")
	end
else
	copy(script_dir,path.."/extra/pm")
end
if exists(path.."/preload/pm") then
	if realpath(readlink(path.."/preload/pm",path))~=path.."/pm/init.lua" then
		if exists(path.."/preload/pm.old") then remove(path.."/preload/pm.old") end
		move(path.."/preload/pm",path.."/preload/pm.old")
		link(path.."/extra/pm/init.lua",path.."/preload/pm")
	end
else
	link(path.."/extra/pm/init.lua",path.."/preload/pm")
end

print("Successful!")