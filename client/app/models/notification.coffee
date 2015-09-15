{BaseModel} = require 'lib/base_model'
request = require 'lib/request'

# Describes a notification
module.exports = class Notification extends BaseModel

    urlRoot: 'api/notifications'

    sharingRequestAnswer: (sourceURL, answer, callback) ->
        data = JSON.parse {sourceURL, answer}
        request.post "sharing/request/answer", data, callback
