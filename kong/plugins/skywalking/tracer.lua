--
-- Licensed to the Apache Software Foundation (ASF) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The ASF licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
local Span = require('kong.plugins.skywalking.span')
local kong = kong

local Tracer = {}

function Tracer:start(config, correlation)
    local metadata_buffer = ngx.shared.skywalking_tracing_buffer
    local TC = require('kong.plugins.skywalking.tracing_context')
    local Layer = require('kong.plugins.skywalking.span_layer')

    local tracingContext
    local service_name = config.service_name
    local service_instance_name = config.service_instance_name
    tracingContext = TC.new(service_name, service_instance_name)

    -- Constant pre-defined in SkyWalking main repo
    -- 6000 represents Nginx
    local nginxComponentId = 6000

    local contextCarrier = {}
    contextCarrier["sw8"] = ngx.req.get_headers()["sw8"]
    contextCarrier["sw8-correlation"] = ngx.req.get_headers()["sw8-correlation"]
    local entrySpan = TC.createEntrySpan(tracingContext, ngx.var.uri, nil, contextCarrier)
    Span.start(entrySpan, ngx.now() * 1000)
    Span.setComponentId(entrySpan, nginxComponentId)
    Span.setLayer(entrySpan, Layer.HTTP)

    Span.tag(entrySpan, 'http.method', kong.request.get_method())
    Span.tag(entrySpan, 'http.params', kong.request.get_scheme() .. '://' .. kong.request.get_host() .. ':' .. kong.request.get_port() .. kong.request.get_path_with_query())

    contextCarrier = {}
    -- Use the same URI to represent incoming and forwarding requests
    -- Change it if you need.
    local upstreamUri = ngx.var.uri

    local upstreamServerName = kong.request.get_host()
    ------------------------------------------------------
    local exitSpan = TC.createExitSpan(tracingContext, upstreamUri, entrySpan, upstreamServerName, contextCarrier, correlation)
    Span.start(exitSpan, ngx.now() * 1000)
    Span.setComponentId(exitSpan, nginxComponentId)
    Span.setLayer(exitSpan, Layer.HTTP)

    for name, value in pairs(contextCarrier) do
        ngx.req.set_header(name, value)
    end

    -- Push the data in the context
    kong.ctx.plugin.tracingContext = tracingContext
    kong.ctx.plugin.entrySpan = entrySpan
    kong.ctx.plugin.exitSpan = exitSpan
end

function Tracer:finish()
    -- Finish the exit span when received the first response package from upstream
    if kong.ctx.plugin.exitSpan ~= nil then
        Span.finish(kong.ctx.plugin.exitSpan, ngx.now() * 1000)
        kong.ctx.plugin.exitSpan = nil
    end
end

function Tracer:prepareForReport()
    local TC = require('kong.plugins.skywalking.tracing_context')
    local Segment = require('kong.plugins.skywalking.segment')
    if kong.ctx.plugin.entrySpan ~= nil then
        Span.finish(kong.ctx.plugin.entrySpan, ngx.now() * 1000)
        local status, segment = TC.drainAfterFinished(kong.ctx.plugin.tracingContext)
        if status then
            local segmentJson = require('cjson').encode(Segment.transform(segment))
            ngx.log(ngx.DEBUG, 'segment = ', segmentJson)

            local queue = ngx.shared.skywalking_tracing_buffer
            local length = queue:lpush('segment', segmentJson)
            ngx.log(ngx.DEBUG, 'segment buffer size = ', queue:llen('segment'))
        end
    end
end

return Tracer
