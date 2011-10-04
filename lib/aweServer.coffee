########################################################################
#                    AWE - Another Workflow Engine
# Authors:  
#   Jared Wilkening (jared@mcs.anl.gov)
#   Narayan Desai   (desai@mcs.anl.gov)
#   Folker Meyer    (folker@anl.gov)
########################################################################

express    = require 'express'
pg         = require 'pg'
fs         = require 'fs'

########################################################################
# Server class
########################################################################

class exports.Server
	constructor: ()->
		# pull in conf
		try 
			@conf  = JSON.parse fs.readFileSync "conf/server.conf", 'utf8'
			@types = JSON.parse fs.readFileSync "conf/types.conf", 'utf8' 	
		catch err
			console.log err
			
		@extUrl		= @conf.extUrl
		@port		= @conf.port		
		@shockUrl 	= @conf.shockUrl
		@shockPort 	= @conf.shockPort 
		@dbconnect  = "pg://#{@conf.dbuser}#{if @conf.dbpasswd? then ":#{@conf.dbpasswd}" else "" }@#{@conf.dbhost}/#{@conf.dbname}"
		@dataRoot 	= @conf.dataRoot
		@uploadsDir = @conf.uploads

		express.logger.token 'custom', (req, res)->
			date = new Date
			return "#{req.socket && (req.socket.remoteAddress || (req.socket.socket && req.socket.socket.remoteAddress))} - [#{date.toDateString()} #{date.toLocaleTimeString()}] \"#{req.method} #{req.url}\" #{res.__statusCode or res.statusCode} -"

		# setup express server
		app = express.createServer()
		app.configure ()->
			app.use express.logger { format: ':custom :response-time ms' }
			app.use express.static "static"
			app.use app.router 
			app.set 'view engine', 'jade'
		@app = app
				
	start: ()->
		console.log "Starting AWE server (port :#{@port}, #{@dbconnect}, dataRoot=#{@dataRoot}, shockUrl=#{@shockUrl})"
		@app.listen @port		
			
	get: (url, callback)->	
		try 
			@app.get url, callback
		catch err
			console.log err

	put: (url, callback)->	
		try 
			@app.put url, callback
		catch err
			console.log err

	delete: (url, callback)->	
		try 
			@app.delete url, callback
		catch err
			console.log err
					
	post: (url, callback)->
		try 
			@app.post url, callback
		catch err
			console.log err

	query: (query_statement, query_array, callback)->
		pg.connect @dbconnect, (err, client) ->
			return console.log err if err 
			q = client.query query_statement, query_array, (err, results)->
				q.on 'end', ()->	
					return callback null, err if err? 
					return callback results if typeof callback is 'function'