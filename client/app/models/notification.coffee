{BaseModel} = require 'lib/base_model'
client = require 'lib/client'

# Describes a notification
module.exports = class Notification extends BaseModel

    urlRoot: 'api/notifications'

    sharingRequestAnswer: (sourceURL, answer, callback) ->
        data =
            sourceURL: sourceURL
            answer: answer

        client.post "sharing/request/answer", data, callback
