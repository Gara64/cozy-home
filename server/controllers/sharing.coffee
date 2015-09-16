async = require 'async'
clearance = require 'cozy-clearance'
cozydb = require 'cozydb'
NotificationsHelper = require 'cozy-notifications-helper'
Client = require("request-json").JsonClient
log = require('printit')
    prefix: 'sharing'

Album = require '../models/album'

localizationManager = require '../helpers/localization_manager'
localization = require '../lib/localization_manager'



module.exports.request = (req, res, next) ->
    console.log 'request for a new sharing from proxy'
    console.log 'params : ' + JSON.stringify req.params.sourceURL if req.params?
    if not req.params?.sourceURL?
        err = new Error 'source missing'
        err.status = 400
        next err

    sourceURL = req.params.sourceURL
    notifier = new NotificationsHelper 'home'
    messageKey = 'notification sharing request'
    message = localization.t messageKey
    notificationSlug = "sharing_request_notification"
    data = req.body
    notifier.createOrUpdatePersistent notificationSlug,
        app: 'home'
        text: messageKey
        resource:
            app: 'home'
            url: "sharing-request/#{sourceURL}"
    , (err) ->
        if err?
            log.error err
            next err
        else
            res.send 200
            console.log 'notif done'

module.exports.answer = (req, res, next) ->
    #TODO : request requesting cozy on /sharing/answer
    # req.params.answer contains the answer to send
    # req.body.url is the url to request
    console.log 'answer the source url'
    console.log 'body : ' + JSON.stringify req.body if req.body?

    url = req.body?.sourceURL
    answer = req.body?.answer

    if not url? or not answer?
        err = new Error 'parameters missing'
        err.status = 400
        next err

    #client = new Client "http://localhost:9104/"
    client = new Client url
    client.post "sharing/answer/#{answer}", null, (err, result, body) ->
        err = err or body.error
        if err? then next err
        else
            console.log JSON.stringify body
            res.send success: true, msg: body


getDisplayName = (callback) ->
    cozydb.api.getCozyUser (err, user) ->
        if user?.public_name and user.public_name.length > 0
            callback null, user.public_name
        else
            localizationManager.ensureReady (err) ->
                callback null, localizationManager.t 'default user name'

clearanceCtl = clearance.controller
    mailTemplate: (options, callback) ->
        getDisplayName (err, displayName) ->
            options.displayName = displayName
            localizationManager.render 'sharemail', options, callback

    mailSubject: (options, callback) ->
        getDisplayName (err, displayName) ->
            callback null, localizationManager.t 'email sharing subject',
                displayName: displayName
                name: options.doc.title

# fetch album, put it in req.doc
module.exports.fetch = (req, res, next, id) ->
    Album.find id, (err, album) ->
        if album
            req.doc = album
            next()
        else
            err = new Error 'bad usage'
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
