(function() {
  var fs, http, sys;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  fs = require('fs');
  http = require('http');
  sys = require('sys');
  exports.Request = (function() {
    function Request(options, fields, files, body) {
      options || (options = {});
      this.host = options.host || '';
      this.port = options.port || '';
      this.method = options.method || 'GET';
      this.path = options.path || '';
      this.headers = options.headers || {
        'User-Agent': 'Node.js (AWE)',
        'Content-Type': 'text/html; charset=ISO-8859-4',
        'Connection': 'keep-alive',
        'Transfer-Encoding': 'chunked'
      };
      this.fields = fields;
      this.files = files;
      this.body = body;
      this.boundary = '';
      this.contentType(this.headers['Content-Type']);
    }
    Request.prototype.contentType = function(type) {
      if (type === 'multipart/form-data') {
        this.multipart = 1;
        this.boundary = "" + (Math.floor(Math.random() * 99999999999));
        return this.headers['Content-Type'] = "" + type + "; boundary=\"" + this.boundary + "\"";
      } else {
        this.multipart = 0;
        return this.contentType = type;
      }
    };
    Request.prototype.send = function(callback) {
      var options, request;
      options = {
        'host': this.host,
        'port': this.port,
        'method': this.method,
        'path': this.path,
        'headers': this.headers,
        'agent': false
      };
      console.log(options);
      request = http.request(options, function(response) {
        var responseBody;
        responseBody = "";
        response.addListener("data", function(chunk) {
          return responseBody += chunk;
        });
        return response.addListener("end", function() {
          return callback(null, responseBody);
        });
      });
      request.on("error", function(err) {
        console.log(err.stack);
        return callback(err, null);
      });
      if (!this.multipart) {
        request.write(this.body);
        return request.end();
      } else {
        return this._sendFields(request, __bind(function(request) {
          return this._sendFiles(request, __bind(function(request) {
            return request.end("--" + this.boundary + "--");
          }, this));
        }, this));
      }
    };
    Request.prototype._sendFields = function(request, cb) {
      var field, _i, _len, _ref;
      _ref = this.fields;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        field = _ref[_i];
        console.log(field);
        request.write("--" + this.boundary + "\r\nContent-Disposition: name=\"" + field[0] + "\"\r\n\r\n");
        request.write(field[1]);
        request.write("\r\n");
      }
      return cb(request);
    };
    Request.prototype._sendFiles = function(request, cb) {
      var current, rs;
      if (this.files.length === 0) {
        return cb(request);
      }
      current = this.files.pop();
      rs = fs.createReadStream(current[1], {
        encoding: 'utf8'
      });
      request.write("--" + this.boundary + "\r\nContent-Disposition: form-data; name=\"file\"; filename=\"" + current[0] + "\"\r\n\r\n");
      rs.addListener("data", function(chunk) {
        return request.write(chunk);
      });
      return rs.addListener("end", __bind(function() {
        request.write("\r\n");
        return this._sendFiles(request, cb);
      }, this));
    };
    return Request;
  })();
}).call(this);
