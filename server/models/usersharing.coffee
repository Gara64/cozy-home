cozydb = require 'cozydb'

module.exports = UserSharing = cozydb.getModel 'UserSharing',
    id: String
    shareID: String
   	hostUrl: String
    password: String
    desc: String
    rules: [Object]
    accepted: Boolean
    url: String
    permissions: Object
    continuous: Boolean
    preToken: String

UserSharing.all = (params, callback) ->
    UserSharing.request "all", params, callback

UserSharing.byShareID = (params, callback) ->
	UserSharing.request "byShareID", params, callback