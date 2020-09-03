package = "kong-plugin-skywalking" 

version = "0.2.0-2" 

local pluginName = "skywalking"

supported_platforms = {"linux", "macosx"}
source = {
  url = "https://github.com/polaris-liu/kong-plugin-skywalking.git",
  tag = "0.2.0"
}

description = {
  summary = "The Nginx Lua agent for Apache SkyWalking kong-plugin",
  homepage = "https://github.com/polaris-liu/kong-plugin-skywalking",
  license = "Apache 2.0"

}

dependencies = {
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins."..pluginName..".handler"] = "kong/plugins/"..pluginName.."/handler.lua",
    ["kong.plugins."..pluginName..".schema"] = "kong/plugins/"..pluginName.."/schema.lua",
    ["kong.plugins."..pluginName..".client"] = "kong/plugins/"..pluginName.."/client.lua",
    ["kong.plugins."..pluginName..".correlation_context"] = "kong/plugins/"..pluginName.."/correlation_context.lua",
    ["kong.plugins."..pluginName..".management"] = "kong/plugins/"..pluginName.."/management.lua",
    ["kong.plugins."..pluginName..".segment"] = "kong/plugins/"..pluginName.."/segment.lua",
    ["kong.plugins."..pluginName..".segment_ref"] = "kong/plugins/"..pluginName.."/segment_ref.lua",
    ["kong.plugins."..pluginName..".span"] = "kong/plugins/"..pluginName.."/span.lua",
    ["kong.plugins."..pluginName..".span_layer"] = "kong/plugins/"..pluginName.."/span_layer.lua",
    ["kong.plugins."..pluginName..".tracer"] = "kong/plugins/"..pluginName.."/tracer.lua",
    ["kong.plugins."..pluginName..".tracing_context"] = "kong/plugins/"..pluginName.."/tracing_context.lua",
  }
}