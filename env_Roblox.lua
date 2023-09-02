if (pcall(function()
   game:GetService("HttpService"):RequestInternal({
      Method="GET";
      Url="https://example.com";
   })
end)) then
   function platform.request(info)
      local ret
      game:GetService("HttpService"):RequestInternal(info):Start(function(s,d)
         ret={s,d}
      end)
      repeat task.wait() until ret~=nil
      ret[2].Success = ret[1]
      return ret[2]
   end
else
   if game:GetService("RunService"):IsServer() then
      function platform.request(info)
         return game:GetService("HttpService"):RequestAsync(info)
      end
      local rep = game:GetService("ReplicatedStorage")
      if rep:FindFirstChild("PM_request") then
         rep:FindFirstChild("PM_request"):Destroy()
      end
      local rq = Instance.new("RemoteFunction")
      rq.Name = "PM_request"
      rq.OnServerInvoke = function(_,info)
         return platform.request(info)
      end
      rq.Parent = rep
   elseif game:GetService("RunService"):IsClient() then
      function platform.request(info)
         local remote = game:GetService("ReplicatedStorage"):FindFirstChild("PM_request")
         if remote and remote:IsA("RemoteFunction") then
            return remote:InvokeServer(info)
         else
            error("Can't find PM_request in ReplicatedStorage, and permissions aren't high enough to request from client.")
         end
      end
   end
end
platform.wait = task.wait
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
local get_cache = {}
function platform.cached_get(url, refcache)
   if get_cache[url]==nil or os.clock()-get_cache[url][1] > 2 or refcache then
      get_cache[url] = {os.clock(), raw_get(url)}
   end
   assert(get_cache[url][2].Success,get_cache[url][2].StatusMessage)
   return get_cache[url][2].Body
end
platform.get = raw_get
platform.post = raw_post
local hostname = platform.cached_get(hostname_url)
platform.hostname = hostname
