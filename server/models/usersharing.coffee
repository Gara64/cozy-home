cozydb = require 'cozydb'

module.exports = UserSharing = cozydb.getModel 'UserSharing',
    login: String # the url
    configuration: Object

UserSharing.all = (params, callback) ->
    UserSharing.request "all", params, callback

UserSharing.byLogin = (params, callback) ->
    UserSharing.request "byLogin", params, callback
