########################################################################
#                    AWE - Another Workflow Engine
# Authors:  
#   Jared Wilkening (jared@mcs.anl.gov)
#   Narayan Desai   (desai@mcs.anl.gov)
#   Folker Meyer    (folker@anl.gov)
########################################################################

fs   = require 'fs'
http = require 'http'
sys  = require 'sys'

########################################################################
# Request class
########################################################################

class exports.Request
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
			
	send: (callback)->		
		options=
			'host' : @host
			'port' : @port
			'method' : @method
			'path' : @path
			'headers' : @headers
			'agent' : false

		console.log options
		request = http.request options, (response)-> 
			responseBody = ""
			response.addListener "data", (chunk)->
				responseBody += chunk
			response.addListener "end", ()->
				callback null, responseBody
				
		request.on "error", (err)->
			console.log err.stack
			callback err, null
			
		if not @multipart
			request.write @body
			request.end()
		else
			this._sendFields request, (request)=>
				this._sendFiles request, (request)=>
					request.end("--#{@boundary}--")

	_sendFields: (request, cb)->
		for field in @fields
			console.log field		
			request.write "--#{@boundary}\r\nContent-Disposition: name=\"#{field[0]}\"\r\n\r\n"
			request.write field[1]
			request.write "\r\n"
		cb request

	_sendFiles: (request, cb)->
		return cb request if @files.length is 0
		current = @files.pop()
		rs = fs.createReadStream current[1], {encoding: 'utf8'}
		request.write "--#{@boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"#{current[0]}\"\r\n\r\n"
		rs.addListener "data", (chunk)->
			request.write chunk
		rs.addListener "end", ()=>
			request.write "\r\n"
			return this._sendFiles request, cb