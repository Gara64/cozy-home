Client = require("request-json").JsonClient
fs = require('fs')
User = require '../models/usersharing'

# we need to access the DS directly because the /user/ api
# is specific therefore not handled by the ODM
ds = new Client "http://localhost:9101/"

# auth is required only in test and production env
if process.env.NODE_ENV in ['test', 'production']
    ds.setBasicAuth process.env.NAME, process.env.TOKEN

module.exports =

    users: (req, res, next) ->
        User.all (err, users) ->
            if err then next err
            else res.send rows: users

    add: (req, res, next) ->

    remove: (req, res, next) ->
        id = req.params.usersharingid
        console.log 'id : ' + id
        User.find id, (err, user) ->
            if err? then next err
            else
                # proper removal of the user (user doc and filter)
                ds.del "access/#{id}/", (err, response, body) ->
                    log.error err if err
                    user.destroy (err) ->
                        err = err or body.error
                        if err? then next err
                        else
                            res.send 200, success: true
