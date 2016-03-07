async = require 'async'
clearance = require 'cozy-clearance'
cozydb = require 'cozydb'
NotificationsHelper = require 'cozy-notifications-helper'
Client = require("request-json").JsonClient
log = require('printit')
    prefix: 'sharing'
UserSharing = require '../models/usersharing'

Album               = require '../models/album'

localizationManager = require '../helpers/localization_manager'

clientDS = new Client "http://localhost:9101/"
# auth is required only in test and production env
if process.env.NODE_ENV in ['test', 'production']
    clientDS.setBasicAuth process.env.NAME, process.env.TOKEN


module.exports.fetchSharing = (req, res, next) ->

    UserSharing.find req.params.shareid, (err, sharing) ->
        if err then next err
        else if not sharing
            res.send 404, error: 'Sharing not found'
        else
            console.log 'found sharing : ' + JSON.stringify sharing
            res.send 200, sharing

# Update the UserSharing with the user answer
module.exports.updateSharing = (req, res, next) ->
    answer = req.body.accepted
    console.log 'answer is : ' + answer
    UserSharing.find req.body.id, (err, userSharing) ->
        if err then next err
        else if not userSharing
            err = new Error "Sharing not found"
            err.status = 404
            next err
        else
            userSharing.updateAttributes accepted: answer, (err, sharing) ->
                if err then next err
                else
                    req.params = userSharing
                    next()


module.exports.request = (req, res, next) ->
    console.log 'create notif for id ' + req.body.id

    if not req.body.id?
        err = new Error "Bad request"
        err.status = 400
        next err
    else

        # Create notification
        notifier = new NotificationsHelper 'home'
        messageKey = 'notification sharing request'
        message = localizationManager.t messageKey
        notificationSlug = "sharing_request_notification"

        notifier.createOrUpdatePersistent notificationSlug,
            app: 'home'
            text: messageKey
            resource:
                app: 'home'
                url: "sharing-request/#{req.body.id}"
        , (err) ->
            if err?
                log.error err
                next err
            else
                res.send 200, success: true

# Send the answer to the DS
module.exports.sendAnswer = (req, res, next) ->
    params = req.params
    console.log 'params : ' + JSON.stringify params
    if not params?
        err = new Error "Bad request"
        err.status = 400
        next err
    else
        clientDS.post "services/sharing/sendAnswer", params, (err, result, body) ->
            if err then next err
            else
                res.send result.statusCode, body


getDisplayName = (callback) ->
    cozydb.api.getCozyUser (err, user) ->
        if user?.public_name and user.public_name.length > 0
            callback null, user.public_name
        else
            localizationManager.ensureReady (err) ->
                callback null, localization.t 'default user name'

clearanceCtl = clearance.controller
    mailTemplate: (options, callback) ->
        getDisplayName (err, displayName) ->
            options.displayName = displayName
            localizationManager.render 'sharemail', options, callback

    mailSubject: (options, callback) ->
        getDisplayName (err, displayName) ->
            callback null, localization.t 'email sharing subject',
                displayName: displayName
                name: options.doc.title

# fetch album, put it in req.doc
module.exports.fetch = (req, res, next, id) ->
    Album.find id, (err, album) ->
        if album
            req.doc = album
            next()
        else
            err = new Error localizationManager.t "wrong usage"
            err.status = 400
            next err

# middleware to mark public request as such
module.exports.markPublicRequests = (req, res, next) ->
    req.public = true if req.url.match /^\/public/
    next()

module.exports.checkPermissions = (album, req, callback) ->
    # owner can do everything
    return callback null, true unless req.public

    if album.clearance is 'hidden'
        album.clearance = 'public'

    if album.clearance is 'private'
        album.clearance = []

    # public request are handled by cozy-clearance
    clearance.check album, 'r', req, callback

# we cache album's clearance to avoid extra couchquery
cache = {}
module.exports.checkPermissionsPhoto = (photo, perm, req, callback) ->
    # owner can do everything
    return callback null, true unless req.public

    # public request are handled by cozy-clearance
    albumid = photo.albumid
    incache = cache[albumid]
    if incache
        clearance.check {clearance: incache}, perm, req, callback
    else
        Album.find albumid, (err, album) ->
            return callback null, false if err or not album
            if album.clearance is 'hidden'
                album.clearance = 'public'

            if album.clearance is 'private'
                album.clearance = []
            cache[albumid] = album.clearance
            clearance.check album, perm, req, callback

# overrige clearanceCtl to clear cache
module.exports.change = (req, res, next) ->
    cache[req.params.shareid] = null
    clearanceCtl.change req, res, next

module.exports.sendAll = clearanceCtl.sendAll
module.exports.contactList = clearanceCtl.contactList
module.exports.contact = clearanceCtl.contact
module.exports.contactPicture = clearanceCtl.contactPicture
