// Generated by CoffeeScript 1.9.0
var Application, CozyInstance, CozyUser, Device, Market, Notification, StackApplication, async;

async = require('async');

Device = require('../models/device');

Application = require('../models/application');

StackApplication = require('../models/stack_application');

CozyInstance = require('../models/cozyinstance');

CozyUser = require('../models/user');

Notification = require('../models/notification');

Market = require('../lib/market');

module.exports = {
  index: function(req, res, next) {
    return async.parallel({
      devices: function(cb) {
        return Device.all(cb);
      },
      cozy_user: function(cb) {
        return CozyUser.first(cb);
      },
      applications: function(cb) {
        return Application.all(cb);
      },
      notifications: function(cb) {
        return Notification.all(cb);
      },
      cozy_instance: function(cb) {
        return CozyInstance.first(cb);
      },
      stack_application: function(cb) {
        return StackApplication.all(cb);
      },
      market_applications: function(cb) {
        return Market.download(cb);
      }
    }, function(err, results) {
      var imports, key, value;
      if (err) {
        return next(err);
      } else {
        imports = "";
        for (key in results) {
          value = results[key];
          imports += "window." + key + " = " + (JSON.stringify(value)) + ";\n";
        }
        imports += "window.managed = " + process.env.MANAGED + ";\n";
        return res.render('index', {
          imports: imports
        });
      }
    });
  }
};
