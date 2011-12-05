##########################################################################
#                      AWE - Another Workflow Engine
# Authors:  
#     Jared Wilkening (jared@mcs.anl.gov)
#     Narayan Desai   (desai@mcs.anl.gov)
#     Folker Meyer    (folker@anl.gov)
##########################################################################

Server		= require('./lib/Server.js'); 
TaskQueue	= require('./lib/TaskQueue.js');
Handlers	= require('./lib/Handlers.js');

##########################################################################
# init server conf/server.conf
##########################################################################

server		= new Server()
taskqueue	= new TaskQueue(server)
handlers	= new Handlers(server, taskqueue)

##########################################################################
# route definitions
##########################################################################

server.get    '/', (req, res)-> handlers.status req, res
server.get    '/type', (req, res)-> handlers.type.status req, res
server.post   '/type', (req, res)-> handlers.type.register req, res
server.get    '/type/:id', (req, res)-> handlers.type.get req, res
server.put    '/type/:id', (req, res)-> handlers.type.put req, res
server.delete '/type/:id', (req, res)-> handlers.type.delete req, res

server.post   '/work', (req, res)-> handlers.work.register req, res
server.get    '/work', (req, res)-> 
	# /work?checkout
	return handlers.work.checkout req, res if req.query.checkout?     
	# /work
	return handlers.work.status req, res

server.get    '/work/:id', (req, res)->
	# /work/:id?renew
	return handlers.work.renew req, res if req.query.renew?
	# /work/:id?done
	return handlers.work.done req, res if req.query.done?
	# /work/:id?release
	return handlers.work.release req, res if req.query.release?
	# /work/:id
	return handlers.work.get req, res

##########################################################################
# start server
##########################################################################

server.start()
taskqueue.process(10)