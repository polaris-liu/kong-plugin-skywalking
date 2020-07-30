local typedefs = require "kong.db.schema.typedefs"

return {
  name = "skywalking",
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { backend_http_uri = typedefs.url({ required = true }) },
          { service_name = { type = "string", default = "'User Service Name", }, },
          { service_instance_name = { type = "string", default = "User Service Instance Name", }, },
          { service_path_name = { type = "string", default = "Backend Service", }, },
        },
      },
    },
  },
}