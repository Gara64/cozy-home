async = require 'async'
clearance = require 'cozy-clearance'
cozydb = require 'cozydb'
NotificationsHelper = require 'cozy-notifications-helper'
Client = require("request-json").JsonClient
log = require('printit')
    prefix: 'sharing'

Album = require '../models/album'
Sharing = require '../models/sharing'
UserSharing = require '../models/usersharing'

localizationManager = require '../helpers/localization_manager'
localization = require '../lib/localization_manager'

clientDS = new Client "http://localhost:9101/"
# auth is required only in test and production env
if process.env.NODE_ENV in ['test', 'production']
    clientDS.setBasicAuth process.env.NAME, process.env.TOKEN

# Define random function for user's token
randomString = (length) ->
    string = ""
    while (string.length < length)
        string = string + Math.random().toString(36).substr(2)
    return string.substr 0, length

module.exports.fetchSharing = (req, res, next) ->

    Sharing.find req.params.shareid, (err, sharing) ->
        if err then next err
        else if not sharing
            res.send 404, error: 'Sharing not found'
        else
            console.log 'found sharing : ' + JSON.stringify sharing
            res.send 200, sharing

module.exports.updateSharing = (req, res, next) ->
    console.log 'answer is : ' + req.body.accepted
    Sharing.find req.body.id, (err, sharing) ->
        if err then next err
        else if not sharing
            res.send 404, error: 'Sharing not found'
        else
            sharing.updateAttributes accepted: req.body.accepted, (err) ->
                if err then next err
                else
                    console.log 'update ok'
                    res.send 200, sharing

                    answer sharing, (err) ->
                        if err then next err


module.exports.request = (req, res, next) ->
    console.log 'request for a new sharing from proxy'
    console.log 'sharing : ' + JSON.stringify req.body

    attributes = req.body.request
    create attributes, (err, sharing) ->
        return next err if err? or next null if sharing is null


        notifier = new NotificationsHelper 'home'
        messageKey = 'notification sharing request'
        message = localization.t messageKey
        notificationSlug = "sharing_request_notification"

        notifier.createOrUpdatePersistent notificationSlug,
            app: 'home'
            text: messageKey
            resource:
                app: 'home'
                url: "sharing-request/#{sharing.id}"
        , (err) ->
            if err?
                log.error err
                next err
            else
                res.send 200

answer = (sharing, callback) ->
    console.log 'answer the source url : ' + JSON.stringify sharing

    return callback null unless sharing?
    client = new Client sharing.url

    share =
        shareID: sharing.shareID
        accepted: sharing.accepted
        desc: sharing.desc
        sharer: sharing.url
        docType: 'Sharing'

    if sharing.answer is yes
        # Check if the sharer is in db
        # If he is not, create the doc; if he is, get the password
        getUser sharing.url, (err, user) ->
            if not user?
                user =
                    login: sharing.url
                    userID: sharing.userID

                createUserSharing user, (err, access) ->
                    return callback err if err?
                    share.password = access.password
            else
                getUserPassword user.id, (err, password) ->
                    return callback err if err?
                    share.password = password

            # Create the Sharing doc
            createShare share, (err) ->
                return callback err if err?

                # Answer to the sharer
                client.post "sharing/answer", share, (err, result, body) ->
                callback null
    else
        # Answer to the sharer
        client.post "sharing/answer", share, (err, result, body) ->
        callback null
        # do not wait the callback here, could be long

# Create share :
createShare = (share, callback) ->
    # Create sharing document
    Sharing.create share, (err, sharing) ->
        callback err, sharing

# Create user :
#       * create user document
#       * create user access
createUserSharing = (user, callback) ->
    user.docType = "UserSharing"
    # Create device document
    clientDS.post "data/", user, (err, result, docInfo) ->
        return callback(err) if err?

        # Create access for this device
        access =
            login: user.login
            password: randomString 32
            app: docInfo._id
            permissions: [] #should contains doc ids - or stored in plugdb
        clientDS.post 'access/', access, (err, result, body) ->
            return callback(err) if err?
            data =
                password: access.password
                login: user.login
                permissions: access.permissions
            # Return access to device
            callback null, data

getUserPassword = (id, callback) ->
    clientDS.post "request/access/byApp", id, (err, result) ->
        console.log 'res password : ' + JSON.stringify result
        if result?
            callback err, result.token
        else
            callback err

getUser = (url, callback) ->
    UserSharing.request "byLogin", url, (err, result) ->
        console.log 'res user : ' + JSON.stringify result
        callback err, result


create = (attributes, callback) ->
    return callback null if not attributes?

    console.log 'attributes : ' + JSON.stringify attributes

    data =
        url: attributes.url or '/'
        login: attributes.login or ''
        password: attributes.password or ''
        shareID: attributes.shareID or ''
        userID: attributes.userID or ''
        desc: attributes.desc or ''
        accepted: false

    Sharing.create data, (err, sharing) =>
        callback err, sharing

updateOrCreate = (attributes, next) ->
    if not req.params.app or not req.params.ref
        return res.send 500, error: 'Wrong usage'

    attributes = req.body
    attributes.type = 'persistent'
    attributes.ref = req.params.ref
    attributes.app = req.params.app

    attributes.resource ?=
        url: attributes.url or '/'


    params = key: [req.params.app, req.params.ref]

    Notification.request 'byApps', params, (err, notifs) =>
        if err then next err
        else if not notifs or notifs.length is 0
            Notification.create attributes, (err, notif) ->
                if err then next err
                else
                    res.send 201, notif
        else
            notifs[0].updateAttributes attributes, (err, notif) ->
                if err then next err
                else
                    res.send 200, notif


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
