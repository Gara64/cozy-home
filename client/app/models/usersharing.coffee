{BaseModel} = require 'lib/base_model'

# Describes a device installed in mycloud.
module.exports = class UserSharing extends Backbone.Model

    urlRoot: 'api/usersharing/'
