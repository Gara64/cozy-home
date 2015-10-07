BaseCollection = require 'lib/base_collection'
UserSharing = require 'models/usersharing'


# List of installed devices.
module.exports = class UserSharingCollection extends BaseCollection

    model: UserSharing
    url: 'api/usersharing/'
