local http = require("socket.http")
local ltn12 = require("ltn12")

function platform.sleep(seconds)
   local s=os.clock()
   os.execute("sleep "..(seconds or .05))
   return os.clock()-s
end
local get_cache = {}
function platform.request(info)
   local body = {}
   local src
   local nhead = {}
   if info.Body then
      src = ltn12.source.string(info.Body);
      nhead["content-length"]=#info.Body;
   end
   if info.Headers then
      for i,v in pairs(info.Headers) do nhead[i]=v end
   end
   local r,c,h = http.request({
      method=info.Method;
      url=info.Url;
      headers=nhead;
      source=src;
      sink=ltn12.sink.table(body);
   })
   return {
      Success=r==1 and c>=200 and c<=299;
      Headers=h;
      StatusCode=c;
      StatusMessage="HTTP Error "..tostring(c);
      Body=table.concat(body,"");
   }
end
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
function platform.cached_get(url, nocache)
   if get_cache[url]==nil or os.clock()-get_cache[url][1] > 2 or nocache then
      get_cache[url] = {os.clock(), raw_get(url)}
   end
   assert(get_cache[url][2].Success,get_cache[url][2].StatusMessage)
   return get_cache[url][2].Body
end
platform.get = raw_get
platform.post = raw_post
local hostname = "http://0.0.0.0:8000"
if not (pcall(raw_get,hostname)) then
   hostname = platform.cached_get(hostname_url)
end
platform.hostname = hostname