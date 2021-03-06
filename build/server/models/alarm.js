// Generated by CoffeeScript 1.9.3
var Alarm, cozydb;

cozydb = require('cozydb');

module.exports = Alarm = cozydb.getModel('Alarm', {
  action: {
    type: String,
    "default": 'DISPLAY'
  },
  trigg: String,
  rrule: String,
  timezone: String,
  description: String,
  related: {
    type: String,
    "default": null
  }
});

Alarm.all = function(params, callback) {
  return Alarm.request("all", params, callback);
};
