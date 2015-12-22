cozydb = require 'cozydb'

module.exports = UserSharing = cozydb.getModel 'UserSharing',
    id: String
    shareID: String
   	hostUrl: String
    password: String
    desc: String
    docIDs: Array
    accepted: Boolean

UserSharing.byShareID = (params, callback) ->
	Sharing.request "byShareID", params, callback