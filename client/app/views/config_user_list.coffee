ViewCollection = require 'lib/view_collection'
UserRow = require 'views/config_user'


module.exports = class UsersListView extends ViewCollection
    id: 'config-user-list'
    tagName: 'div'
    template: require 'templates/config_user_list'
    itemView: require 'views/config_user'

    constructor: (users) ->
        @users = users
        super collection: users


    afterRender: =>
        @userList = @$ "#user-list"
