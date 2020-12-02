package = "kong-plugin-ua-match"
version = "0.1-1"
source = {
   url = "https://github.com/samsk/kong-plugin-ua-match",
   tag = "v0.1"
}
description = {
   summary = "A Kong plugin to match User Agent string",
   homepage = "https://github.com/samsk/kong-plugin-ua-match",
   license = "MIT"
}
dependencies = {
   "lua ~> 5.1"
}
build = {
   type = "builtin",
   modules = {
      ["kong.plugins.ip-auth.handler"] = "handler.lua",
      ["kong.plugins.ip-auth.schema"] = "schema.lua"
   }
}
