{BaseModel} = require 'lib/base_model'
client = require 'lib/client'

# Describes a sharing
module.exports = class Sharing extends BaseModel

    urlRoot: 'api/sharing'
    desc: ''
