BaseView = require 'lib/base_view'

# Row displaying user name and attributes
module.exports = class UserRow extends BaseView
    className: "line config-device clearfix" #config-device for css
    tagName: "div"
    template: require 'templates/config_user'

    events:
        'click .remove-user': 'onRemoveClicked'

    getRenderData: ->
        user: @model.attributes

    constructor: (options) ->
        @model = options.model
        @id = "user-btn-#{options.model.id}"
        super

    onRemoveClicked: (event) ->
        if window.confirm t 'revoke user confirmation message'
            $(event.currentTarget).spin true
            $.ajax("/api/usersharing/#{@model.get('id')}",
                type: "DELETE"
                success: =>
                    @$el.fadeOut ->
                error: =>
                    @$('.remove-user').html t 'revoke user access'
                    console.log "error while revoking the user access"
            )
