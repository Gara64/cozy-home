{BaseModel} = require 'lib/base_model'
client = require 'lib/client'

# Describes a notification
module.exports = class Notification extends BaseModel

    urlRoot: 'api/notifications'
