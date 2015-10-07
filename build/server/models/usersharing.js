// Generated by CoffeeScript 1.9.0
var UserSharing, cozydb;

cozydb = require('cozydb');

module.exports = UserSharing = cozydb.getModel('UserSharing', {
  login: String,
  configuration: Object
});

UserSharing.all = function(params, callback) {
  return UserSharing.request("all", params, callback);
};

UserSharing.byLogin = function(params, callback) {
  return UserSharing.request("byLogin", params, callback);
};
