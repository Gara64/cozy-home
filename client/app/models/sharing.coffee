{BaseModel} = require 'lib/base_model'
client = require 'lib/client'

# Describes a sharing
module.exports = class Sharing extends BaseModel

    urlRoot: 'api/sharing'

    sharingRequestAnswer: (sourceURL, answer, callback) ->
        data =
            sourceURL: sourceURL
            answer: answer

        client.post "sharing/request/answer", data, callback
