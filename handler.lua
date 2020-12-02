local lrucache = require "resty.lrucache"
local strip = require("kong.tools.utils").strip

local ipairs = ipairs
local re_find = ngx.re.find

local UAMatchHandler = {}

UAMatchHandler.PRIORITY = 2000
UAMatchHandler.VERSION = "1.0.0"

local BAD_REQUEST = 400
local FORBIDDEN = 403

local MATCH_EMPTY     = 0
local MATCH_WHITELIST = 1
local MATCH_BLACKLIST = 2

-- per-worker cache of matched UAs
-- we use a weak table, index by the `conf` parameter, so once the plugin config
-- is GC'ed, the cache follows automatically
local ua_caches = setmetatable({}, { __mode = "k" })
local UA_CACHE_SIZE = 10 ^ 4

local function get_user_agent()
  local user_agent = kong.request.get_headers()["user-agent"]
  if type(user_agent) == "table" then
    return nil, "Invalid duplicate headers"
  end
  return user_agent
end

local function examine_agent(user_agent, conf)
  user_agent = strip(user_agent)

  if conf.blacklist then
    for _, rule in ipairs(conf.blacklist) do
      if re_find(user_agent, rule, "jo") then
        return MATCH_BLACKLIST
      end
    end
  end

  if conf.whitelist then
    for _, rule in ipairs(conf.whitelist) do
      if re_find(user_agent, rule, "jo") then
        return MATCH_WHITELIST
      end
    end
  end

  return MATCH_EMPTY
end

function UAMatchHandler:access(conf)
  local user_agent, err = get_user_agent()
  if err then
    return kong.response.exit(BAD_REQUEST, { message = err })
  end

  -- no header found
  if not user_agent then
    if conf.permit_missing then
      return
    else
      return kong.response.exit(FORBIDDEN, { message = "Required headers missing" })
    end
  end

  -- create cache
  local cache = ua_caches[conf]
  if not cache then
    cache = lrucache.new(UA_CACHE_SIZE)
    ua_caches[conf] = cache
  end

  -- check cache or examine UA
  local match  = cache:get(user_agent)
  if not match then
    match = examine_agent(user_agent, conf)
    cache:set(user_agent, match)
  end

  -- return FORBIDDEN if request not allowed
  -- NOTE: response message ambiguity is intentional
  if match > 1 then
    return kong.response.exit(FORBIDDEN, { message = "Request forbidden" })
  elseif match == MATCH_EMPTY and not conf.permit_by_default then
    return kong.response.exit(FORBIDDEN, { message = "Request not allowed" })
  end
end

return UAMatchHandler
