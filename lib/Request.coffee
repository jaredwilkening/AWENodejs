##########################################################################
#                      AWE - Another Workflow Engine
# Authors:  
#     Jared Wilkening (jared@mcs.anl.gov)
#     Narayan Desai   (desai@mcs.anl.gov)
#     Folker Meyer    (folker@anl.gov)
##########################################################################

fs   = require 'fs'
http = require 'http'

##########################################################################
# Request class
##########################################################################

class Request
	constructor: (options, fields, files, body)->
		options or= {}
		@host = options.host or ''
		@port = options.port or ''
		@method = options.method or 'GET'
		@path = options.path or ''
		@headers = options.headers or {
			'User-Agent'        : 'Node.js (AWE)'
			'Content-Type'      : 'text/html; charset=ISO-8859-4'
			'Connection'        : 'keep-alive'
			'Transfer-Encoding' : 'chunked'
		}
		
		@fields = fields
		@files = files
		@body = body
		
		# for 'multipart/form' requests
		@boundary = ''
		this.contentType @headers['Content-Type']

	contentType: (type)->
		if type is 'multipart/form-data'
			@multipart = 1
			@boundary = "#{Math.floor(Math.random()*99999999999)}"	
			return @headers['Content-Type'] = "#{type}; boundary=\"#{@boundary}\""
		else
			@multipart = 0
			return @contentType = type
			
	send: (cb)->		
		options=
			'host' : @host
			'port' : @port
			'method' : @method
			'path' : @path
			'headers' : @headers
			'agent' : false

		request = http.request options, (response)-> 
			res =
				'statusCode' : response.statusCode
				'headers' : response.headers
				'body' : ''			
			response.on "error", (err)->
				return callback err, res
			response.addListener "data", (chunk)->
				res['body'] += chunk
			response.addListener "end", ()->
				return cb null, res
				
		request.on "error", (err)->
			console.log err.stack
			cb err, null
			
		if not @multipart
			if @body?
				request.write @body
			request.end()
		else
			this._sendFields request, ()=>
				this._sendFiles request, ()=>
					request.end("--#{@boundary}--")

	_sendFields: (request, cb)->
		for field in @fields
			request.write "--#{@boundary}\r\nContent-Disposition: name=\"#{field[0]}\"\r\n\r\n"
			request.write "#{field[1]}"
			request.write "\r\n"
		cb()

	_sendFiles: (request, cb)->
		return cb() if @files.length is 0
		current = @files.shift()
		if current[2]?
			rs = fs.createReadStream current[2], {encoding: 'utf8'}
			request.write "--#{@boundary}\r\nContent-Disposition: form-data; name=\"#{current[0]}\"; filename=\"#{current[1]}\"\r\n\r\n"
			rs.addListener "data", (chunk)->
				request.write chunk
			rs.addListener "end", ()=>
				request.write "\r\n"
				return this._sendFiles request, cb
		else
			request.write "--#{@boundary}\r\nContent-Disposition: form-data; name=\"#{current[0]}\"; filename=\"#{current[1]}\"\r\n\r\n"
			request.write current[3]
			request.write "\r\n"
			return this._sendFiles request, cb
			
##########################################################################
# exports
##########################################################################

module.exports = Request			