(function() {
  var Handlers, Server, TaskQueue, handlers, server, taskqueue;

  Server = require('./lib/Server.js');

  TaskQueue = require('./lib/TaskQueue.js');

  Handlers = require('./lib/Handlers.js');

  server = new Server();

  taskqueue = new TaskQueue(server);

  handlers = new Handlers(server, taskqueue);

  server.get('/', function(req, res) {
    return handlers.status(req, res);
  });

  server.get('/type', function(req, res) {
    return handlers.type.status(req, res);
  });

  server.post('/type', function(req, res) {
    return handlers.type.register(req, res);
  });

  server.get('/type/:id', function(req, res) {
    return handlers.type.get(req, res);
  });

  server.put('/type/:id', function(req, res) {
    return handlers.type.put(req, res);
  });

  server["delete"]('/type/:id', function(req, res) {
    return handlers.type["delete"](req, res);
  });

  server.post('/work', function(req, res) {
    return handlers.work.register(req, res);
  });

  server.get('/work', function(req, res) {
    if (req.query.checkout != null) return handlers.work.checkout(req, res);
    return handlers.work.status(req, res);
  });

  server.get('/work/:id', function(req, res) {
    if (req.query.renew != null) return handlers.work.renew(req, res);
    if (req.query.done != null) return handlers.work.done(req, res);
    if (req.query.release != null) return handlers.work.release(req, res);
    return handlers.work.get(req, res);
  });

  server.start();

  taskqueue.process(10);

}).call(this);
