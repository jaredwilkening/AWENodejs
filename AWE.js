(function() {
  var aweServer, aweServerHandler, handler, server, type, work;
  aweServer = require('./lib/aweServer.js');
  aweServerHandler = require('./lib/aweServerHandlers.js');
  server = new aweServer.Server();
  handler = new aweServerHandler.Handler(server);
  type = new aweServerHandler.Type(server);
  work = new aweServerHandler.Work(server);
  server.get('/', function(req, res) {
    return handler.status(req, res);
  });
  server.get('/type', function(req, res) {
    return type.status(req, res);
  });
  server.post('/type/register', function(req, res) {
    return type.register(req, res);
  });
  server.get('/type/:id', function(req, res) {
    return type.get(req, res);
  });
  server.put('/type/:id', function(req, res) {
    return type.put(req, res);
  });
  server["delete"]('/type/:id', function(req, res) {
    return type["delete"](req, res);
  });
  server.get('/work', function(req, res) {
    return work.status(req, res);
  });
  server.post('/work/register', function(req, res) {
    return work.register(req, res);
  });
  server.get('/work/checkout', function(req, res) {
    return work.checkout(req, res);
  });
  server.get('/work/:id', function(req, res) {
    return work.get(req, res);
  });
  server.get('/work/:id/renew', function(req, res) {
    return work.renew(req, res);
  });
  server.get('/work/:id/done', function(req, res) {
    return work.done(req, res);
  });
  server.get('/work/:id/release', function(req, res) {
    return work.release(req, res);
  });
  server.start();
}).call(this);
