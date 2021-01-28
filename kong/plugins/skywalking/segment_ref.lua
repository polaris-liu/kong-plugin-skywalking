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
local k_utils = require "kong.tools.utils"
local encode_base64 = ngx.encode_base64
local decode_base64 = ngx.decode_base64

local _M = {}
-- local SegmentRef = {
--     -- There is no multiple-threads scenario in the LUA, no only hard coded as CROSS_PROCESS
--     type = 'CROSS_PROCESS',
--     trace_id,
--     segment_id,
--     span_id,
--     parent_service,
--     parent_service_instance,
--     parent_endpoint,
--     address_used_at_client,
-- }

function _M.new()
    return {
        type = 'CROSS_PROCESS',
        network_address_id = 0,
        entry_service_instance_id = 0,
        parent_service_instance_id = 0,
        entry_endpoint_id = 0,
        parent_endpoint_id = 0,
    }
end

-- Format a trace/segment id into an array.
-- An official ID should have three parts separated by '.' and each part of it is a number
function _M.formatID(str)
    local parts = split(str, [[\.]])
    if #parts ~= 3 then
        return nil
    end

    return parts
end

function _M.fromSW6Value(value)
    local ref = _M.new()

    local parts = k_utils.split(value, '-')
    if #parts ~= 9 then
        return nil
    end

    ref.trace_id = formatID(decode_base64(parts[2]))
    ref.segment_id = formatID(decode_base64(parts[3]))
    ref.span_id = tonumber(parts[4])
    ref.parent_service_instance_id = tonumber(parts[5])
    ref.entry_service_instance_id = tonumber(parts[6])
    local peerStr = decode_base64(parts[7])
    if string.sub(peerStr, 1, 1) == '#' then
        ref.network_address = string.sub(peerStr, 2)
    else
        ref.network_address_id = tonumber(peerStr)
    end
    local entryEndpointStr = decode_base64(parts[8])
    if string.sub(entryEndpointStr, 1, 1) == '#' then
        ref.entry_endpoint_name = string.sub(entryEndpointStr, 2)
    else
        ref.entry_endpoint_id = tonumber(entryEndpointStr)
    end
    local parentEndpointStr = decode_base64(parts[9])
    if string.sub(parentEndpointStr, 1, 1) == '#' then
        ref.parent_endpoint_name = string.sub(parentEndpointStr, 2)
    else
        ref.parent_endpoint_id = tonumber(parentEndpointStr)
    end

    return ref
end

-- Return string to represent this ref.
function _M.serialize(ref)
    local encodedRef = '1'
            .. '-' .. encode_base64(ref.trace_id)
            .. '-' .. encode_base64(ref.segment_id)
            .. '-' .. ref.span_id
            .. '-' .. encode_base64(ref.parent_service)
            .. '-' .. encode_base64(ref.parent_service_instance)
            .. '-' .. encode_base64(ref.parent_endpoint)
            .. '-' .. encode_base64(ref.address_used_at_client)

    return encodedRef
end

-- Due to nesting relationship inside Segment/Span/TracingContext at the runtime,
-- RefProtocol is created to prepare JSON format serialization.
-- Following SkyWalking official trace protocol v3
-- https://github.com/apache/skywalking-data-collect-protocol/blob/master/language-agent/Tracing.proto
-- local RefProtocol = {
--     -- Constant in LUA, no cross-thread
--     refType = 'CrossProcess',
--     traceId,
--     parentTraceSegmentId,
--     parentSpanId,
--     parentService,
--     parentServiceInstance,
--     parentEndpoint,
--     networkAddressUsedAtPeer,
-- }
-- Return RefProtocol
function _M.transform(ref)
    local refBuilder = {}
    refBuilder.refType = 'CrossProcess'
    refBuilder.traceId = ref.trace_id
    refBuilder.parentTraceSegmentId = ref.segment_id
    refBuilder.parentSpanId = ref.span_id
    refBuilder.parentService = ref.parent_service
    refBuilder.parentServiceInstance = ref.parent_service_instance
    refBuilder.parentEndpoint = ref.parent_endpoint
    refBuilder.networkAddressUsedAtPeer = ref.address_used_at_client
    return refBuilder
end

return _M
