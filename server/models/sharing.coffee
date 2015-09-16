cozydb = require 'cozydb'

module.exports = Sharing = cozydb.getModel 'Sharing',
    url: String
    login: String
    password: String
    shareID: String
    userID: String
    desc: String

Sharing.all = (params, callback) ->
    Sharing.request "all", params, callback

Sharing.destroyAll = (callback) ->
    Sharing.requestDestroy "all", callback
