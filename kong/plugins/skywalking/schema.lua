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

local typedefs = require "kong.db.schema.typedefs"

return {
  name = "skywalking",
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { backend_http_uri = typedefs.url({ required = true }) },
          { service_name = { type = "string", default = "Kong Service", }, },
          { service_instance_prefix = { type = "string", default = "", }, },
          { sample_ratio = { type = "number", between = { 1 , 10000 }, default = 1 }, },
        },
      },
    },
  },
}