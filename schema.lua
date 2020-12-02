local typedefs = require "kong.db.schema.typedefs"

return {
  name = "ua-match",
  fields = {
    -- { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          -- order reflects evaluation order
          { permit_missing = { type = "boolean", default = false }, },
          { blacklist = { type = "array", elements = { type = "string", is_regex = true }, default = {}, }, },
          { whitelist = { type = "array", elements = { type = "string", is_regex = true }, default = {}, }, },
          { permit_by_default = { type = "boolean", default = false }, },
        },
     }, },
  },
}
