########################################################################
#                    AWE - Another Workflow Engine
# Authors:  
#   Jared Wilkening (jared@mcs.anl.gov)
#   Narayan Desai   (desai@mcs.anl.gov)
#   Folker Meyer    (folker@anl.gov)
########################################################################

formidable = require 'formidable'
sys        = require 'sys'
fs         = require 'fs' 
http       = require 'http' 
util       = require 'util'
exec       = require('child_process').exec
aweRequest = require('./aweRequest.js');

########################################################################
# Handler class
########################################################################

class exports.Handler
	constructor: (server)->
		@server = server

	status: (req, res)->
		@server.query "select * from types", [], (results)->
			columns = ['_id', 'type', 'template', 'checker', 'owner', 'partionable']
			rows = []
			for r in (results.rows or [])
				tmp = []
				for c in columns
					tmp.push r[c]
				rows.push tmp
			return res.render 'index', {locals: { pageTitle: "AWE - Types", columns: columns, rows: rows}}

class exports.Type
	constructor: (server)->
		@server = server
	
	status: (req, res)->
		@server.query "select * from types", [], (results)->
			columns = ['_id', 'type', 'template', 'checker', 'owner', 'partionable']
			rows = []
			for r in (results.rows or [])
				tmp = []
				for c in columns
					tmp.push r[c]
				rows.push tmp
			return res.render 'index', {locals: { pageTitle: "AWE - Types", columns: columns, rows: rows}}

	register: (req, res)->
		return res.render 'registerType', {locals: { pageTitle: "AWE - Register Type"}} if req.method == "GET"
		form = new formidable.IncomingForm()
		[fields, files] = [{},{}]
		form.on "field", (field, value)->
			fields[field]=value
		form.on "file", (field, file)->
			files[field] = file
		form.on "end", ()=>
			return errorRes res, req, null, "error: missing template file" if not files.template?
			checker = null
			try
				template = JSON.parse fs.readFileSync files.template.path, 'utf8'
				checker = JSON.parse fs.readFileSync files.checker.path, 'utf8' if files.checker?
			catch err
				return errorRes res, req, err, "error: failed attempting to parse uploaded file(s)"
			type=
				'type' : fields.type or ''
				'template' : template
				'checker' : checker				
				'partionable' : if fields.partionable? and fields.partionable is '1' then true else false			
			@server.query "select _id from types where type = $1", [type.type], (results)=>
				return errorRes res, req, null, "error: type \"#{type.type}\" already exists id: #{results.rows[0]._id}" if results.rows.length > 0
				@server.query "insert into types (type, template, checker, partionable) values ($1, $2, $3, $4) returning _id", [type.type, JSON.stringify(type.template), JSON.stringify(type.checker), type.partionable], (results)=>					
					return res.redirect "/type/#{results.rows[0]._id}" if results.rowCount is 1 and results.rows[0]._id?
					return errorRes res, req, null, "error: internal error, failed to create new type"
		form.parse req
						
	put: (req, res)->
		id = req.params.id		
		form = new formidable.IncomingForm()
		[fields, files] = [{},{}]
		form.on "error", (err)->
			return errorRes res, req, err, "error: internal error, failed to update type #{id}"
		form.on "field", (field, value)->
			fields[field]=value
		form.on "file", (field, file)->
			files[field] = file
		form.on "end", ()=>
			@server.query "select _id from types where _id = $1", [id], (results)=>
				return errorRes res, req, null, "error: id #{id} does not exist" if results.rows.length is 0
				template = null
				checker = null
				try
					template = JSON.parse fs.readFileSync files.template.path, 'utf8' if files.template?
					checker = JSON.parse fs.readFileSync files.checker.path, 'utf8' if files.checker?
				catch err
					return errorRes res, req, err, "error: failed attempting to parse uploaded file(s)"			
				updateFields = []
				updateValues = []
				if fields.type?
					updateFields.push "type"
					updateValues.push fields.type				
				updateFields.push "partionable"				
				updateValues.push if fields.partionable? and fields.partionable is '1' then true else false
				if template?
					updateFields.push "template"
					updateValues.push JSON.stringify(template)
				if checker?	
					updateFields.push "checker" 
					updateValues.push JSON.stringify(checker)
				updateValues.push id
				@server.query "update types set (#{updateFields.join(", ")}) = (#{"$"+(x for x in [1..updateValues.length-1]).join(", $")}) where _id = $#{updateValues.length}", updateValues, (results, err)=>
					return res.redirect "/type/#{id}" if results? and results.rowCount is 1
					return errorRes res, req, null, "error: type #{fields.type} already exists, failed to update id #{id}" if err? and err.message? and /(duplicate)/.test err.message
					return errorRes res, req, err, "error: internal error, failed to update id #{id}"
		form.parse req

	get: (req, res)->
		id = req.params.id
		@server.query "select * from types where _id = $1", [id], (results)->
			return errorRes res, req, null, "error: type #{id} does not exist" if results.rows.length is 0
			type = results.rows[0]
			template = JSON.parse(type.template)

			checker = JSON.parse(type.checker or "{}")			
			clientRes res, {id: id, type: type.type, partionable: type.partionable, template: template, checker: checker} if not isBrowser req
			return res.render 'type', {locals: {pageTitle: "AWE - Type", id: id, type: type.type, partionable: type.partionable, template: JSON.stringify(template, null, 4), checker: JSON.stringify(checker, null, 4) }}

	delete: (req, res)->
		id = req.params.id
		@server.query "select * from types where _id = $1", [id], (results)=>
			return errorRes res, req, null, "error: id #{id} does not exist" if results.rows.length is 0
			@server.query "delete from types where _id = $1", [id], (results, err)=>
				return errorRes res, req, err, "error: internal error, failed to delete id #{id}" if err
				return clientRes res, {message: "Successfully deleted #{id}"} if not isBrowser req
				return res.render 'index', {locals: { pageTitle: "AWE - status", message: "Successfully deleted #{id}"}} if isBrowser req
			
class exports.Work
	constructor: (server)->
		@server = server
		
	status: (req, res)->
		@server.query "select * from workunits", [], (data)->
			columns = ['_id', 'type', 'priority','creation_time', 'checkout_status', 'checkout_host', 'release_time', 'done']
			rows = []
			return res.render 'index', {locals: { pageTitle: "AWE - status", columns: columns, rows: rows}} if data.rows.length is 0
			for r in data.rows
				tmp = []
				for c in columns
					tmp.push r[c]
				rows.push tmp
			res.render 'index', {locals: { pageTitle: "AWE - status", columns: columns, rows: rows}}
	
	register: (req, res)->
		form = new formidable.IncomingForm()
		[fields, files] = [{},{}]
		form.on "field", (field, value)->
			if field in ["input"]
				fields[field] = [] if not fields[field]?
				fields[field].push value 
			else
				fields[field]=value
		form.on "file", (field, file)->
			files[field] = [] if not files[field]?
			files[field].push file
		form.on "end", ()=>
			return errorRes res, req, null, "error: missing type" if not fields.type?
			@server.query "select template from types where type=$1", [fields.type], (results, err)=>
				console.log err if err?
				return errorRes res, req, null, "error: type #{fields.type} does not exist" if results.rows.length is 0
				try
					type = JSON.parse results.rows[0].template
				catch err
					return errorRes res, req, err, "error: internal server error"
				return errorRes res, req, null, "error: not files provided, please refer to the awe api doc" if not files.input?
				return errorRes res, req, null, "error: type #{type.type} requires #{Object.keys(type.inputs).length} input(s). #{files.input.length} input(s) recieved" if type.inputs? and Object.keys(type.inputs).length != files.input.length
				options=
					'host' : @server.shockUrl
					'port' : @server.shockPort
					'method' : 'POST'
					'path' : '/register'
					'headers' : 
						'User-Agent'     : 'Node.js (AWE)'
						'Content-Type'   : "multipart/form-data"
						'Connection'     : 'keep-alive'
						'Transfer-Encoding' : 'chunked'
					
				reqFiles = []		
				for i in [0..(files.input.length-1)]
					reqFiles.push [files.input[i].name, files.input[i].path]		
				request = new aweRequest.Request(options, [], reqFiles)
				request.send (err, responseBody)=>
					console.log err if err?
					console.log responseBody
					try
						aweRes = JSON.parse(responseBody)
					catch error
						return errorRes res, req, error, "Something bad happened"
					inputs = {}
					for i in [0..(files.input.length-1)]				
						inputs["i#{i+1}"] =
							"fileName"     : files.input[i].name
							"url"          : "#{@server.shockUrl}#{if @server.shockPort? then ":#{@server.shockPort}" else "" }/get/#{aweRes.response.ids[i]}"
							"size"         : files.input[i].size	
							#"checksum"     : ""
							#"checksumType" : "md5"
						
					outputs = {}
					for o of type.outputs
						outputs[o] =
							"fileName" : type.outputs[o].fileName
							"url"      : ""
						if type.outputs[o].pipe?	
							outputs[o]["pipe"] = type.outputs[o].pipe 

					workUnitObj = 
						"about"      : "AWE workunit"
						"workType"   : fields.workType
						"cmd"        : type.cmd
						"options"    : type.options or ""
						"args"       : type.args or ""
						"inputs"     : inputs
						"outputs"    : outputs
									
					@server.query "insert into workunits (workunit, type) values ($1, $2) returning _id", [JSON.stringify(workUnitObj), type.type], (results, err)->
						if results.rowCount? and results.rowCount == 1
							return res.redirect "/work/#{results.rows[0]._id}"
						else
							return errorRes res, req, null, "error: unable to create workunit"
		form.parse req

	checkout: (req, res)->
		@server.query "begin work; lock table workunits in access exclusive mode; update workunits set (checkout_status, checkout_host, checkout_time, release_time) = ('checked_out', 'localhost', now(), now() + interval '1 hour') where _id in (select _id from workunits where (checkout_status not in ('checked_out', 'pending') or checkout_status is null) and not done order by priority desc, creation_time asc limit 1) returning _id; commit work;", [], (results, err)=>
			return errorRes res, req, null, "error: no work found" if results? and results.rows.length is 0
			return res.redirect "/work/#{results.rows[0]._id}" if results? and results.rows[0]._id?

	get: (req, res)->
		id = req.params.id
		@server.query "select * from workunits where _id = $1", [id], (results)->
			return errorRes res, req, null, "error: work #{id} does not exist" if results.rows.length is 0
			work = results.rows[0]
			workunit = JSON.parse(work.workunit)
			returnObj=
				id: id
				type: work.type
				workunit: workunit
				priority: work.priority
				creation_time: work.creation_time
				checkout_status: work.checkout_status
				checkout_host: work.checkout_host
				checkout_time: work.checkout_time
				release_time: work.release_time
			return clientRes res, returnObj if not isBrowser req			
			returnObj["pageTitle"] = "AWE - Work"
			returnObj["workunit"] = JSON.stringify(returnObj["workunit"], null, 4)
			return res.render 'work', {locals: returnObj}

	renew: (req, res)->
		id = req.params.id		
		@server.query "update workunits set (release_time) = (now() + interval '1 hour') where _id=$1", [id], (results, err)=>
			return errorRes res, req, null, "error: no work found" if not results? or results.rowCount is not 1
			return clientRes res, {message: "Success"} if not isBrowser req
			return res.render 'index', {locals: {pageTitle: "AWE - Release", message: "Success"} }
		
	done: (req, res)->
		id = req.params.id		
		@server.query "update workunits set (checkout_status, checkout_time, release_time, done) = ('done', null, null, true) where _id=$1", [id], (results, err)=>
			return errorRes res, req, null, "error: no work found" if not results? or results.rowCount is not 1
			return clientRes res, {message: "Success"} if not isBrowser req
			return res.render 'index', {locals: {pageTitle: "AWE - Release", message: "Success"} }					

	release: (req, res)->	
		id = req.params.id		
		@server.query "update workunits set (checkout_status, checkout_host, checkout_time, release_time) = ('ready', '', null, null) where _id=$1", [id], (results, err)=>
			return errorRes res, req, null, "error: no work found" if not results? or results.rowCount is not 1
			return clientRes res, {message: "Success"} if not isBrowser req
			return res.render 'index', {locals: {pageTitle: "AWE - Release", message: "Success"} }
			
########################################################################
# helper functions
########################################################################
isBrowser = (req)->
	return /(Mozilla|AppleWebKit|Chrome|Gecko|Safari)/.test req.headers['user-agent']

clientRes = (res, response, httpcode)->
	httpcode or= 200
	try
		res.writeHead httpcode, {'content-type': 'application/json'}
	catch err
		# headers might have already been written 
	res.end JSON.stringify response
	
errorRes = (res, req, err, message)->
	if err? and err.stack?
		console.log err.stack 
	else if err?
		console.log err 
	return res.render 'index', {locals: { pageTitle: "Shock - main", message: message }} if isBrowser req
	return clientRes res, { "message" : message, "status" : "Error" } if not isBrowser req

getShockInfo = (server, shock_key, callback)->
	options = 'host' : "#{shock_host}", 'port' : shock_port, 'path' : "/info/#{shock_key}", 'method' : "GET"
	req = http.request options, (res)->
		if res.statusCode is not 200
			console.log "statusCode: #{res.statusCode}"
			console.log "headers: #{JSON.stringify res.headers}"
		else
			res.setEncoding 'utf8'
			body_tmp = ''
			res.on 'data', (chunk)->
				body_tmp = "#{body_tmp}#{chunk}"
			res.on 'end', ()->
				body = JSON.parse body_tmp
				if body.response.info?
					callback null, body.response.info if typeof callback is 'function'				
				else 
					callback 'Object key not found', null if typeof callback is 'function'				
	req.on 'error', (err)->
		callback err.message, null if typeof callback is 'function'		
	req.end()

registerJob = (server, shock_key, name, type, parts, callback)->
	server.query "insert into jobs (job_name, input_key, type, total, avail) values ($1, $2, $3, $4, $5) returning *", [name, shock_key, type, parts, parts], (data)->
		if data.rows.length > 0 and data.rows[0].job_name?
			for p in [1..parts]
				server.query "insert into workunits (job_id, part) values ($1, $2)", [data.rows[0]._id, p]
			callback null if typeof callback is 'function'
		else
			callback "Error creating job" if typeof callback is 'function'

finishJob = (server, row)->
	return console.log "Job #{row.job_name} done. No done_file." if verbose? and not row.done_file
	console.log "Job #{row.job_name} done." if verbose?

	server.query "delete from jobs where _id = $1", [row._id], (data)->
		console.log "Job #{row.job_name} removed from DB." if verbose?
	if row.done_script
		console.log "Job #{row.job_name} executing done script." if verbose? 
		exec row.done_script, (error, stdout, stderr)->
			console.log error if error?
			console.log stdout if verbose?		
