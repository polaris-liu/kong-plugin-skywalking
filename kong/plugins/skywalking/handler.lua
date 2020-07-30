local client = require "kong.plugins.skywalking.client"
local tracer = require "kong.plugins.skywalking.tracer"

local SkyWalkingHandler = {
  PRIORITY = 2001,
  VERSION = "1.0.0",
}

-- Your plugin handler's constructor. If you are extending the
-- Base Plugin handler, it's only role is to instantiate itself
-- with a name. The name is your plugin name as it will be printed in the logs.
function SkyWalkingHandler:new()
  kong.log.debug("saying hi from the SkyWalkingHandler 'new' handler")
  local metadata_buffer = ngx.shared.tracing_buffer
  local service_name = "User Service Name"
  local service_instance_name = "User Service Instance Name"
  local backend_http_uri = "http://192.168.9.9:11800"

  metadata_buffer:set('serviceName', service_name)
  metadata_buffer:set('serviceInstanceName', service_instance_name)

  client:startBackendTimer(backend_http_uri) 

  ngx.log(ngx.DEBUG, 'SkyWalkingHandler init ', metadata_buffer)
  ngx.log(ngx.DEBUG, 'SkyWalkingHandler serverAddr ', backend_http_uri)
end

function SkyWalkingHandler:rewrite(config)
  kong.log.debug("saying hi from the SkyWalkingHandler 'rewrite' handler")
  local service_path_name = "temp node"
  tracer:start(service_path_name)
  ngx.log(ngx.DEBUG, 'SkyWalkingHandler rewrite ', service_path_name)
end

function SkyWalkingHandler:body_filter(config)
  kong.log.debug("saying hi from the SkyWalkingHandler 'body_filter' handler")
  if ngx.arg[2] then
    tracer:finish()
  end
end

function SkyWalkingHandler:log(config)
  kong.log.debug("saying hi from the SkyWalkingHandler 'log' handler")
  tracer:prepareForReport()
end

return SkyWalkingHandler