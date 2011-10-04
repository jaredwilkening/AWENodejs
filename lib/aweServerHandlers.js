(function() {
  var aweRequest, clientRes, errorRes, exec, finishJob, formidable, fs, getShockInfo, http, isBrowser, registerJob, sys, util;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  formidable = require('formidable');
  sys = require('sys');
  fs = require('fs');
  http = require('http');
  util = require('util');
  exec = require('child_process').exec;
  aweRequest = require('./aweRequest.js');
  exports.Handler = (function() {
    function Handler(server) {
      this.server = server;
    }
    Handler.prototype.status = function(req, res) {
      return this.server.query("select * from types", [], function(results) {
        var c, columns, r, rows, tmp, _i, _j, _len, _len2, _ref;
        columns = ['_id', 'type', 'template', 'checker', 'owner', 'partionable'];
        rows = [];
        _ref = results.rows || [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          r = _ref[_i];
          tmp = [];
          for (_j = 0, _len2 = columns.length; _j < _len2; _j++) {
            c = columns[_j];
            tmp.push(r[c]);
          }
          rows.push(tmp);
        }
        return res.render('index', {
          locals: {
            pageTitle: "AWE - Types",
            columns: columns,
            rows: rows
          }
        });
      });
    };
    return Handler;
  })();
  exports.Type = (function() {
    function Type(server) {
      this.server = server;
    }
    Type.prototype.status = function(req, res) {
      return this.server.query("select * from types", [], function(results) {
        var c, columns, r, rows, tmp, _i, _j, _len, _len2, _ref;
        columns = ['_id', 'type', 'template', 'checker', 'owner', 'partionable'];
        rows = [];
        _ref = results.rows || [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          r = _ref[_i];
          tmp = [];
          for (_j = 0, _len2 = columns.length; _j < _len2; _j++) {
            c = columns[_j];
            tmp.push(r[c]);
          }
          rows.push(tmp);
        }
        return res.render('index', {
          locals: {
            pageTitle: "AWE - Types",
            columns: columns,
            rows: rows
          }
        });
      });
    };
    Type.prototype.register = function(req, res) {
      var fields, files, form, _ref;
      if (req.method === "GET") {
        return res.render('registerType', {
          locals: {
            pageTitle: "AWE - Register Type"
          }
        });
      }
      form = new formidable.IncomingForm();
      _ref = [{}, {}], fields = _ref[0], files = _ref[1];
      form.on("field", function(field, value) {
        return fields[field] = value;
      });
      form.on("file", function(field, file) {
        return files[field] = file;
      });
      form.on("end", __bind(function() {
        var checker, template, type;
        if (!(files.template != null)) {
          return errorRes(res, req, null, "error: missing template file");
        }
        checker = null;
        try {
          template = JSON.parse(fs.readFileSync(files.template.path, 'utf8'));
          if (files.checker != null) {
            checker = JSON.parse(fs.readFileSync(files.checker.path, 'utf8'));
          }
        } catch (err) {
          return errorRes(res, req, err, "error: failed attempting to parse uploaded file(s)");
        }
        type = {
          'type': fields.type || '',
          'template': template,
          'checker': checker,
          'partionable': (fields.partionable != null) && fields.partionable === '1' ? true : false
        };
        return this.server.query("select _id from types where type = $1", [type.type], __bind(function(results) {
          if (results.rows.length > 0) {
            return errorRes(res, req, null, "error: type \"" + type.type + "\" already exists id: " + results.rows[0]._id);
          }
          return this.server.query("insert into types (type, template, checker, partionable) values ($1, $2, $3, $4) returning _id", [type.type, JSON.stringify(type.template), JSON.stringify(type.checker), type.partionable], __bind(function(results) {
            if (results.rowCount === 1 && (results.rows[0]._id != null)) {
              return res.redirect("/type/" + results.rows[0]._id);
            }
            return errorRes(res, req, null, "error: internal error, failed to create new type");
          }, this));
        }, this));
      }, this));
      return form.parse(req);
    };
    Type.prototype.put = function(req, res) {
      var fields, files, form, id, _ref;
      id = req.params.id;
      form = new formidable.IncomingForm();
      _ref = [{}, {}], fields = _ref[0], files = _ref[1];
      form.on("error", function(err) {
        return errorRes(res, req, err, "error: internal error, failed to update type " + id);
      });
      form.on("field", function(field, value) {
        return fields[field] = value;
      });
      form.on("file", function(field, file) {
        return files[field] = file;
      });
      form.on("end", __bind(function() {
        return this.server.query("select _id from types where _id = $1", [id], __bind(function(results) {
          var checker, template, updateFields, updateValues, x;
          if (results.rows.length === 0) {
            return errorRes(res, req, null, "error: id " + id + " does not exist");
          }
          template = null;
          checker = null;
          try {
            if (files.template != null) {
              template = JSON.parse(fs.readFileSync(files.template.path, 'utf8'));
            }
            if (files.checker != null) {
              checker = JSON.parse(fs.readFileSync(files.checker.path, 'utf8'));
            }
          } catch (err) {
            return errorRes(res, req, err, "error: failed attempting to parse uploaded file(s)");
          }
          updateFields = [];
          updateValues = [];
          if (fields.type != null) {
            updateFields.push("type");
            updateValues.push(fields.type);
          }
          updateFields.push("partionable");
          updateValues.push((fields.partionable != null) && fields.partionable === '1' ? true : false);
          if (template != null) {
            updateFields.push("template");
            updateValues.push(JSON.stringify(template));
          }
          if (checker != null) {
            updateFields.push("checker");
            updateValues.push(JSON.stringify(checker));
          }
          updateValues.push(id);
          return this.server.query("update types set (" + (updateFields.join(", ")) + ") = (" + ("$" + ((function() {
            var _ref2, _results;
            _results = [];
            for (x = 1, _ref2 = updateValues.length - 1; 1 <= _ref2 ? x <= _ref2 : x >= _ref2; 1 <= _ref2 ? x++ : x--) {
              _results.push(x);
            }
            return _results;
          })()).join(", $")) + ") where _id = $" + updateValues.length, updateValues, __bind(function(results, err) {
            if ((results != null) && results.rowCount === 1) {
              return res.redirect("/type/" + id);
            }
            if ((err != null) && (err.message != null) && /(duplicate)/.test(err.message)) {
              return errorRes(res, req, null, "error: type " + fields.type + " already exists, failed to update id " + id);
            }
            return errorRes(res, req, err, "error: internal error, failed to update id " + id);
          }, this));
        }, this));
      }, this));
      return form.parse(req);
    };
    Type.prototype.get = function(req, res) {
      var id;
      id = req.params.id;
      return this.server.query("select * from types where _id = $1", [id], function(results) {
        var checker, template, type;
        if (results.rows.length === 0) {
          return errorRes(res, req, null, "error: type " + id + " does not exist");
        }
        type = results.rows[0];
        template = JSON.parse(type.template);
        checker = JSON.parse(type.checker || "{}");
        if (!isBrowser(req)) {
          clientRes(res, {
            id: id,
            type: type.type,
            partionable: type.partionable,
            template: template,
            checker: checker
          });
        }
        return res.render('type', {
          locals: {
            pageTitle: "AWE - Type",
            id: id,
            type: type.type,
            partionable: type.partionable,
            template: JSON.stringify(template, null, 4),
            checker: JSON.stringify(checker, null, 4)
          }
        });
      });
    };
    Type.prototype["delete"] = function(req, res) {
      var id;
      id = req.params.id;
      return this.server.query("select * from types where _id = $1", [id], __bind(function(results) {
        if (results.rows.length === 0) {
          return errorRes(res, req, null, "error: id " + id + " does not exist");
        }
        return this.server.query("delete from types where _id = $1", [id], __bind(function(results, err) {
          if (err) {
            return errorRes(res, req, err, "error: internal error, failed to delete id " + id);
          }
          if (!isBrowser(req)) {
            return clientRes(res, {
              message: "Successfully deleted " + id
            });
          }
          if (isBrowser(req)) {
            return res.render('index', {
              locals: {
                pageTitle: "AWE - status",
                message: "Successfully deleted " + id
              }
            });
          }
        }, this));
      }, this));
    };
    return Type;
  })();
  exports.Work = (function() {
    function Work(server) {
      this.server = server;
    }
    Work.prototype.status = function(req, res) {
      return this.server.query("select * from workunits", [], function(data) {
        var c, columns, r, rows, tmp, _i, _j, _len, _len2, _ref;
        columns = ['_id', 'type', 'priority', 'creation_time', 'checkout_status', 'checkout_host', 'release_time', 'done'];
        rows = [];
        if (data.rows.length === 0) {
          return res.render('index', {
            locals: {
              pageTitle: "AWE - status",
              columns: columns,
              rows: rows
            }
          });
        }
        _ref = data.rows;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          r = _ref[_i];
          tmp = [];
          for (_j = 0, _len2 = columns.length; _j < _len2; _j++) {
            c = columns[_j];
            tmp.push(r[c]);
          }
          rows.push(tmp);
        }
        return res.render('index', {
          locals: {
            pageTitle: "AWE - status",
            columns: columns,
            rows: rows
          }
        });
      });
    };
    Work.prototype.register = function(req, res) {
      var fields, files, form, _ref;
      form = new formidable.IncomingForm();
      _ref = [{}, {}], fields = _ref[0], files = _ref[1];
      form.on("field", function(field, value) {
        if (field === "input") {
          if (!(fields[field] != null)) {
            fields[field] = [];
          }
          return fields[field].push(value);
        } else {
          return fields[field] = value;
        }
      });
      form.on("file", function(field, file) {
        if (!(files[field] != null)) {
          files[field] = [];
        }
        return files[field].push(file);
      });
      form.on("end", __bind(function() {
        if (!(fields.type != null)) {
          return errorRes(res, req, null, "error: missing type");
        }
        return this.server.query("select template from types where type=$1", [fields.type], __bind(function(results, err) {
          var i, options, reqFiles, request, type, _ref2;
          if (err != null) {
            console.log(err);
          }
          if (results.rows.length === 0) {
            return errorRes(res, req, null, "error: type " + fields.type + " does not exist");
          }
          try {
            type = JSON.parse(results.rows[0].template);
          } catch (err) {
            return errorRes(res, req, err, "error: internal server error");
          }
          if (!(files.input != null)) {
            return errorRes(res, req, null, "error: not files provided, please refer to the awe api doc");
          }
          if ((type.inputs != null) && Object.keys(type.inputs).length !== files.input.length) {
            return errorRes(res, req, null, "error: type " + type.type + " requires " + (Object.keys(type.inputs).length) + " input(s). " + files.input.length + " input(s) recieved");
          }
          options = {
            'host': this.server.shockUrl,
            'port': this.server.shockPort,
            'method': 'POST',
            'path': '/register',
            'headers': {
              'User-Agent': 'Node.js (AWE)',
              'Content-Type': "multipart/form-data",
              'Connection': 'keep-alive',
              'Transfer-Encoding': 'chunked'
            }
          };
          reqFiles = [];
          for (i = 0, _ref2 = files.input.length - 1; 0 <= _ref2 ? i <= _ref2 : i >= _ref2; 0 <= _ref2 ? i++ : i--) {
            reqFiles.push([files.input[i].name, files.input[i].path]);
          }
          request = new aweRequest.Request(options, [], reqFiles);
          return request.send(__bind(function(err, responseBody) {
            var aweRes, i, inputs, o, outputs, workUnitObj, _ref3;
            if (err != null) {
              console.log(err);
            }
            console.log(responseBody);
            try {
              aweRes = JSON.parse(responseBody);
            } catch (error) {
              return errorRes(res, req, error, "Something bad happened");
            }
            inputs = {};
            for (i = 0, _ref3 = files.input.length - 1; 0 <= _ref3 ? i <= _ref3 : i >= _ref3; 0 <= _ref3 ? i++ : i--) {
              inputs["i" + (i + 1)] = {
                "fileName": files.input[i].name,
                "url": "" + this.server.shockUrl + (this.server.shockPort != null ? ":" + this.server.shockPort : "") + "/get/" + aweRes.response.ids[i],
                "size": files.input[i].size
              };
            }
            outputs = {};
            for (o in type.outputs) {
              outputs[o] = {
                "fileName": type.outputs[o].fileName,
                "url": ""
              };
              if (type.outputs[o].pipe != null) {
                outputs[o]["pipe"] = type.outputs[o].pipe;
              }
            }
            workUnitObj = {
              "about": "AWE workunit",
              "workType": fields.workType,
              "cmd": type.cmd,
              "options": type.options || "",
              "args": type.args || "",
              "inputs": inputs,
              "outputs": outputs
            };
            return this.server.query("insert into workunits (workunit, type) values ($1, $2) returning _id", [JSON.stringify(workUnitObj), type.type], function(results, err) {
              if ((results.rowCount != null) && results.rowCount === 1) {
                return res.redirect("/work/" + results.rows[0]._id);
              } else {
                return errorRes(res, req, null, "error: unable to create workunit");
              }
            });
          }, this));
        }, this));
      }, this));
      return form.parse(req);
    };
    Work.prototype.checkout = function(req, res) {
      return this.server.query("begin work; lock table workunits in access exclusive mode; update workunits set (checkout_status, checkout_host, checkout_time, release_time) = ('checked_out', 'localhost', now(), now() + interval '1 hour') where _id in (select _id from workunits where (checkout_status not in ('checked_out', 'pending') or checkout_status is null) and not done order by priority desc, creation_time asc limit 1) returning _id; commit work;", [], __bind(function(results, err) {
        if ((results != null) && results.rows.length === 0) {
          return errorRes(res, req, null, "error: no work found");
        }
        if ((results != null) && (results.rows[0]._id != null)) {
          return res.redirect("/work/" + results.rows[0]._id);
        }
      }, this));
    };
    Work.prototype.get = function(req, res) {
      var id;
      id = req.params.id;
      return this.server.query("select * from workunits where _id = $1", [id], function(results) {
        var returnObj, work, workunit;
        if (results.rows.length === 0) {
          return errorRes(res, req, null, "error: work " + id + " does not exist");
        }
        work = results.rows[0];
        workunit = JSON.parse(work.workunit);
        returnObj = {
          id: id,
          type: work.type,
          workunit: workunit,
          priority: work.priority,
          creation_time: work.creation_time,
          checkout_status: work.checkout_status,
          checkout_host: work.checkout_host,
          checkout_time: work.checkout_time,
          release_time: work.release_time
        };
        if (!isBrowser(req)) {
          return clientRes(res, returnObj);
        }
        returnObj["pageTitle"] = "AWE - Work";
        returnObj["workunit"] = JSON.stringify(returnObj["workunit"], null, 4);
        return res.render('work', {
          locals: returnObj
        });
      });
    };
    Work.prototype.renew = function(req, res) {
      var id;
      id = req.params.id;
      return this.server.query("update workunits set (release_time) = (now() + interval '1 hour') where _id=$1", [id], __bind(function(results, err) {
        if (!(results != null) || results.rowCount === !1) {
          return errorRes(res, req, null, "error: no work found");
        }
        if (!isBrowser(req)) {
          return clientRes(res, {
            message: "Success"
          });
        }
        return res.render('index', {
          locals: {
            pageTitle: "AWE - Release",
            message: "Success"
          }
        });
      }, this));
    };
    Work.prototype.done = function(req, res) {
      var id;
      id = req.params.id;
      return this.server.query("update workunits set (checkout_status, checkout_time, release_time, done) = ('done', null, null, true) where _id=$1", [id], __bind(function(results, err) {
        if (!(results != null) || results.rowCount === !1) {
          return errorRes(res, req, null, "error: no work found");
        }
        if (!isBrowser(req)) {
          return clientRes(res, {
            message: "Success"
          });
        }
        return res.render('index', {
          locals: {
            pageTitle: "AWE - Release",
            message: "Success"
          }
        });
      }, this));
    };
    Work.prototype.release = function(req, res) {
      var id;
      id = req.params.id;
      return this.server.query("update workunits set (checkout_status, checkout_host, checkout_time, release_time) = ('ready', '', null, null) where _id=$1", [id], __bind(function(results, err) {
        if (!(results != null) || results.rowCount === !1) {
          return errorRes(res, req, null, "error: no work found");
        }
        if (!isBrowser(req)) {
          return clientRes(res, {
            message: "Success"
          });
        }
        return res.render('index', {
          locals: {
            pageTitle: "AWE - Release",
            message: "Success"
          }
        });
      }, this));
    };
    return Work;
  })();
  isBrowser = function(req) {
    return /(Mozilla|AppleWebKit|Chrome|Gecko|Safari)/.test(req.headers['user-agent']);
  };
  clientRes = function(res, response, httpcode) {
    httpcode || (httpcode = 200);
    try {
      res.writeHead(httpcode, {
        'content-type': 'application/json'
      });
    } catch (err) {

    }
    return res.end(JSON.stringify(response));
  };
  errorRes = function(res, req, err, message) {
    if ((err != null) && (err.stack != null)) {
      console.log(err.stack);
    } else if (err != null) {
      console.log(err);
    }
    if (isBrowser(req)) {
      return res.render('index', {
        locals: {
          pageTitle: "Shock - main",
          message: message
        }
      });
    }
    if (!isBrowser(req)) {
      return clientRes(res, {
        "message": message,
        "status": "Error"
      });
    }
  };
  getShockInfo = function(server, shock_key, callback) {
    var options, req;
    options = {
      'host': "" + shock_host,
      'port': shock_port,
      'path': "/info/" + shock_key,
      'method': "GET"
    };
    req = http.request(options, function(res) {
      var body_tmp;
      if (res.statusCode === !200) {
        console.log("statusCode: " + res.statusCode);
        return console.log("headers: " + (JSON.stringify(res.headers)));
      } else {
        res.setEncoding('utf8');
        body_tmp = '';
        res.on('data', function(chunk) {
          return body_tmp = "" + body_tmp + chunk;
        });
        return res.on('end', function() {
          var body;
          body = JSON.parse(body_tmp);
          if (body.response.info != null) {
            if (typeof callback === 'function') {
              return callback(null, body.response.info);
            }
          } else {
            if (typeof callback === 'function') {
              return callback('Object key not found', null);
            }
          }
        });
      }
    });
    req.on('error', function(err) {
      if (typeof callback === 'function') {
        return callback(err.message, null);
      }
    });
    return req.end();
  };
  registerJob = function(server, shock_key, name, type, parts, callback) {
    return server.query("insert into jobs (job_name, input_key, type, total, avail) values ($1, $2, $3, $4, $5) returning *", [name, shock_key, type, parts, parts], function(data) {
      var p;
      if (data.rows.length > 0 && (data.rows[0].job_name != null)) {
        for (p = 1; 1 <= parts ? p <= parts : p >= parts; 1 <= parts ? p++ : p--) {
          server.query("insert into workunits (job_id, part) values ($1, $2)", [data.rows[0]._id, p]);
        }
        if (typeof callback === 'function') {
          return callback(null);
        }
      } else {
        if (typeof callback === 'function') {
          return callback("Error creating job");
        }
      }
    });
  };
  finishJob = function(server, row) {
    if ((typeof verbose !== "undefined" && verbose !== null) && !row.done_file) {
      return console.log("Job " + row.job_name + " done. No done_file.");
    }
    if (typeof verbose !== "undefined" && verbose !== null) {
      console.log("Job " + row.job_name + " done.");
    }
    server.query("delete from jobs where _id = $1", [row._id], function(data) {
      if (typeof verbose !== "undefined" && verbose !== null) {
        return console.log("Job " + row.job_name + " removed from DB.");
      }
    });
    if (row.done_script) {
      if (typeof verbose !== "undefined" && verbose !== null) {
        console.log("Job " + row.job_name + " executing done script.");
      }
      return exec(row.done_script, function(error, stdout, stderr) {
        if (error != null) {
          console.log(error);
        }
        if (typeof verbose !== "undefined" && verbose !== null) {
          return console.log(stdout);
        }
      });
    }
  };
}).call(this);
