cozydb = require 'cozydb'

module.exports = UserSharing = cozydb.getModel 'UserSharing',
    id: String
    shareID: String
   	hostUrl: String
    password: String
    desc: String
    docIDs: Array
    accepted: Boolean
    url: String
    permissions: Array

UserSharing.all = (params, callback) ->
    UserSharing.request "all", params, callback

UserSharing.byShareID = (params, callback) ->
	UserSharing.request "byShareID", params, callback