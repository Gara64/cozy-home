// Generated by CoffeeScript 1.9.0
var logger, request,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

request = require('request-json');

logger = require('printit')({
  prefix: 'manifest'
});

exports.Manifest = (function() {
  function Manifest() {
    this.getMetaData = __bind(this.getMetaData, this);
    this.getIconPath = __bind(this.getIconPath, this);
    this.getDescription = __bind(this.getDescription, this);
    this.getVersion = __bind(this.getVersion, this);
    this.getWidget = __bind(this.getWidget, this);
    this.getPermissions = __bind(this.getPermissions, this);
  }

  Manifest.prototype.download = function(app, callback) {
    var Provider, provider, providerName;
    if (app.git != null) {
      providerName = app.git.match(/(github\.com|gitlab\.cozycloud\.cc)/);
      providerName = providerName[0];
      if (providerName === "gitlab.cozycloud.cc") {
        Provider = require('./git_providers').CozyGitlabProvider;
      } else {
        Provider = require('./git_providers').GithubProvider;
      }
      provider = new Provider(app);
      return provider.getManifest((function(_this) {
        return function(err, data) {
          if (err != null) {
            _this.config = {};
            return callback(err);
          } else {
            _this.config = data;
            return provider.getStars(function(err, stars) {
              if (err != null) {
                return callback(err);
              } else {
                _this.config.stars = stars;
                return callback(null);
              }
            });
          }
        };
      })(this));
    } else {
      this.config = {};
      logger.warn('App manifest without git URL');
      logger.raw(app);
      return callback(null);
    }
  };

  Manifest.prototype.getPermissions = function() {
    var _ref;
    if (((_ref = this.config) != null ? _ref["cozy-permissions"] : void 0) != null) {
      return this.config["cozy-permissions"];
    } else {
      return {};
    }
  };

  Manifest.prototype.getWidget = function() {
    if (this.config['cozy-widget'] != null) {
      return this.config["cozy-widget"];
    } else {
      return null;
    }
  };

  Manifest.prototype.getVersion = function() {
    var _ref;
    if (((_ref = this.config) != null ? _ref['version'] : void 0) != null) {
      return this.config['version'];
    } else {
      return "0.0.0";
    }
  };

  Manifest.prototype.getDescription = function() {
    var _ref;
    if (((_ref = this.config) != null ? _ref['description'] : void 0) != null) {
      return this.config["description"];
    } else {
      return null;
    }
  };

  Manifest.prototype.getIconPath = function() {
    var _ref;
    if (((_ref = this.config) != null ? _ref['icon-path'] : void 0) != null) {
      return this.config['icon-path'];
    } else {
      return null;
    }
  };

  Manifest.prototype.getColor = function() {
    var _ref;
    if (((_ref = this.config) != null ? _ref['cozy-color'] : void 0) != null) {
      return this.config['cozy-color'];
    } else {
      return null;
    }
  };

  Manifest.prototype.getMetaData = function() {
    var metaData;
    metaData = {};
    if (this.config.description != null) {
      metaData.description = this.config.description;
    }
    if (this.config.name != null) {
      metaData.name = this.config.name.replace('cozy-', '');
    }
    if (this.config['cozy-displayName'] != null) {
      metaData.displayName = this.config['cozy-displayName'];
    } else {
      metaData.displayName = this.config.name.replace('cozy-', '');
      metaData.displayName = metaData.displayName.replace('-', ' ');
    }
    if (this.config['icon-path'] != null) {
      metaData.iconPath = this.config['icon-path'];
    }
    if (this.config['cozy-permissions'] != null) {
      metaData.permissions = this.config['cozy-permissions'];
    }
    if (this.config.stars != null) {
      metaData.stars = this.config.stars;
    }
    if (this.config['cozy-color']) {
      metaData.color = this.config['cozy-color'];
    }
    return metaData;
  };

  return Manifest;

})();
