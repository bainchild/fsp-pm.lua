loadstring = function(src,chunk)
   local f = CompileString(src,chunk,false)
   if type(f)=="string" then
      return nil, f
   else
      return f
   end
end
PM_G.loadstring = loadstring
assert(HTTP~=nil,"HTTP function not present!")
function platform.request(info)
    local nhead = {}
    if info.Body then
        nhead["Content-Length"]=#info.Body;
    end
    if info.Headers then
        for i,v in pairs(info.Headers) do nhead[i]=v end
    end
    local success,reason,code,body,headers
    local function suc(cod,bod,header)
       code,body,headers=cod,bod,header
       success=true
    end
    local function fail(reaso)
       success=false
       reason=reaso
    end
    HTTP({
        success=suc;
        failed=fail;
        url=info.Url;
        body=info.Body;
        method=info.Method;
        headers=nhead;
        timeout=10^2*4;
    })
    if coroutine.isyieldable and coroutine.isyieldable() then
       local finished = coroutine.wrap(function()
          while true do coroutine.yield(success~=nil) end
       end)
       repeat until finished()
    else
       -- worst case scenario
       repeat until success~=nil
    end
    if not success then error(reason) end
    return {
        Success=success and code>=200 and code<=299;
        StatusCode=code;
        StatusMessage="Http code "..tostring(code);
        Headers=headers;
        Body=body;
    }
end
local get_cache = {}
local function raw_get(uri,head)
   return platform.request({
      Url=uri;
      Method="GET";
      Headers=head;
   })
end
local function raw_post(uri,data,head)
   return platform.request({
      Url=uri;
      Body=data;
      Method="POST";
      Headers=head;
   })
end
function platform.cached_get(url, refcache)
   if get_cache[url]==nil or os.clock()-get_cache[url][1] > 2 or refcache then
      get_cache[url] = {os.clock(), raw_get(url)}
   end
   assert(get_cache[url][2].Success,get_cache[url][2].StatusMessage)
   return get_cache[url][2]
end
platform.get = raw_get
platform.post = raw_post
local hostname = platform.cached_get(hostname_url)
platform.hostname = hostname