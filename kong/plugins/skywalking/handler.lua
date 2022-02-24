--
-- Licensed to the Apache Software Foundation (ASF) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The ASF licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

local sw_client = require "kong.plugins.skywalking.client"
local sw_tracer = require "kong.plugins.skywalking.tracer"

local SkyWalkingHandler = {
  PRIORITY = 2001,
  VERSION = "1.0.0",
}

function SkyWalkingHandler:access(config)
  kong.log.info('access phase of skywalking plugin')
  kong.ctx.plugin.skywalking_sample = false
  -- set hostname to service_instance_name
  local hostname = os.getenv("HOSTNAME")
  if config.cluster_flag and hostname ~= nil then
    config.service_instance_name = hostname
  end
  if config.sample_ratio == 1 or math.random() * 10000 < config.sample_ratio then
      kong.ctx.plugin.skywalking_sample = true
      sw_client:startBackendTimer(config) 
      sw_tracer:start(config)
  end
end

function SkyWalkingHandler:body_filter(config)
  if kong.ctx.plugin.skywalking_sample and ngx.arg[2] then
    sw_tracer:finish()
  end
end

function SkyWalkingHandler:log(config)
  if string.upper(ngx.req.get_method()) =='HEAD' then
    sw_tracer:finish()
  end
  if kong.ctx.plugin.skywalking_sample then
    sw_tracer:prepareForReport()
  end
end

return SkyWalkingHandler