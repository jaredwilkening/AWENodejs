(function() {
  var express, fs, pg;
  express = require('express');
  pg = require('pg');
  fs = require('fs');
  exports.Server = (function() {
    function Server() {
      var app;
      try {
        this.conf = JSON.parse(fs.readFileSync("conf/server.conf", 'utf8'));
        this.types = JSON.parse(fs.readFileSync("conf/types.conf", 'utf8'));
      } catch (err) {
        console.log(err);
      }
      this.extUrl = this.conf.extUrl;
      this.port = this.conf.port;
      this.shockUrl = this.conf.shockUrl;
      this.shockPort = this.conf.shockPort;
      this.dbconnect = "pg://" + this.conf.dbuser + (this.conf.dbpasswd != null ? ":" + this.conf.dbpasswd : "") + "@" + this.conf.dbhost + "/" + this.conf.dbname;
      this.dataRoot = this.conf.dataRoot;
      this.uploadsDir = this.conf.uploads;
      express.logger.token('custom', function(req, res) {
        var date;
        date = new Date;
        return "" + (req.socket && (req.socket.remoteAddress || (req.socket.socket && req.socket.socket.remoteAddress))) + " - [" + (date.toDateString()) + " " + (date.toLocaleTimeString()) + "] \"" + req.method + " " + req.url + "\" " + (res.__statusCode || res.statusCode) + " -";
      });
      app = express.createServer();
      app.configure(function() {
        app.use(express.logger({
          format: ':custom :response-time ms'
        }));
        app.use(express.static("static"));
        app.use(app.router);
        return app.set('view engine', 'jade');
      });
      this.app = app;
    }
    Server.prototype.start = function() {
      console.log("Starting AWE server (port :" + this.port + ", " + this.dbconnect + ", dataRoot=" + this.dataRoot + ", shockUrl=" + this.shockUrl + ")");
      return this.app.listen(this.port);
    };
    Server.prototype.get = function(url, callback) {
      try {
        return this.app.get(url, callback);
      } catch (err) {
        return console.log(err);
      }
    };
    Server.prototype.put = function(url, callback) {
      try {
        return this.app.put(url, callback);
      } catch (err) {
        return console.log(err);
      }
    };
    Server.prototype["delete"] = function(url, callback) {
      try {
        return this.app["delete"](url, callback);
      } catch (err) {
        return console.log(err);
      }
    };
    Server.prototype.post = function(url, callback) {
      try {
        return this.app.post(url, callback);
      } catch (err) {
        return console.log(err);
      }
    };
    Server.prototype.query = function(query_statement, query_array, callback) {
      return pg.connect(this.dbconnect, function(err, client) {
        var q;
        if (err) {
          return console.log(err);
        }
        return q = client.query(query_statement, query_array, function(err, results) {
          return q.on('end', function() {
            if (err != null) {
              return callback(null, err);
            }
            if (typeof callback === 'function') {
              return callback(results);
            }
          });
        });
      });
    };
    return Server;
  })();
}).call(this);
