########################################################################
#                    AWE - Another Workflow Engine
# Authors:  
#   Jared Wilkening (jared@mcs.anl.gov)
#   Narayan Desai   (desai@mcs.anl.gov)
#   Folker Meyer    (folker@anl.gov)
########################################################################

aweServer        = require('./lib/aweServer.js'); 
aweServerHandler = require('./lib/aweServerHandlers.js');

########################################################################
# init server (pulls in conf/server.conf & conf/types.conf)
########################################################################

server	= new aweServer.Server()
handler	= new aweServerHandler.Handler(server)
type	= new aweServerHandler.Type(server)
work	= new aweServerHandler.Work(server)

# route definitions
server.get    '/',					(req, res)-> handler.status req, res
server.get    '/type',				(req, res)-> type.status req, res
server.post   '/type/register',		(req, res)-> type.register req, res
server.get    '/type/:id',			(req, res)-> type.get req, res
server.put    '/type/:id',			(req, res)-> type.put req, res
server.delete '/type/:id',			(req, res)-> type.delete req, res

server.get    '/work',				(req, res)-> work.status req, res
server.post   '/work/register',		(req, res)-> work.register req, res
server.get    '/work/checkout',		(req, res)-> work.checkout req, res
server.get    '/work/:id',			(req, res)-> work.get req, res
server.get    '/work/:id/renew',	(req, res)-> work.renew req, res
server.get    '/work/:id/done',		(req, res)-> work.done req, res
server.get    '/work/:id/release',	(req, res)-> work.release req, res

# start server
server.start()