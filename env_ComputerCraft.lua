assert(http~=nil,"Http library not present!")
function platform.request(info)
    if http.checkURL then
        assert(http.checkURL(info.Url))
    end
    local nhead = {}
    if info.Body then
        nhead["Content-Length"]=#info.Body;
    end
    if info.Headers then
        for i,v in pairs(info.Headers) do nhead[i]=v end
    end
    http.request({
        url=info.Url;
        body=info.Body;
        method=info.Method;
        headers=nhead;
        timeout=10^2*4;
        binary=true;
        redirect=true
    })
    local n = nil
    repeat
        n={os.pullEvent()}
    until n~=nil and (n[1]=="http_success" or n[1]=="http_failure") and n[2]==info.Url
    local resp
    if n[1]=="http_success" then
        resp=n[3]
    else
        assert(n[4]~=nil,"Error connecting to '"..tostring(info.Url).."': "..tostring(n[3]))
        resp=n[4]
    end
    local body = resp.readAll()
    if body==nil then body="" end
    resp.close()
    local code = resp.getStatusCode();
    return {
        Success=n[1]=="http_success" and code>=200 and code<=299;
        StatusCode=code;
        StatusMessage="HTTP Error "..code;
        Headers=resp.getResponseHeaders();
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