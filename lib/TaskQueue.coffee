##########################################################################
#                      AWE - Another Workflow Engine
# Authors:  
#     Jared Wilkening (jared@mcs.anl.gov)
#     Narayan Desai   (desai@mcs.anl.gov)
#     Folker Meyer    (folker@anl.gov)
##########################################################################

fs		= require 'fs'
temp	= require 'temp'
url		= require 'url'
Request	= require('./Request.js');

##########################################################################
# TaskQueue class
##########################################################################

class TaskQueue
	constructor: (server)->
		@server = server
		@processing = 0
		@cache = []
		@cache_update = false
		@workunit = new WorkUnit(server)
		
		# clear running at startup
		return this.clearRunning()

	clearRunning: ()->
		@server.query "update tasks set (status) = (null) where status = 'running'", [], (results, err)->
			console.log err if err?
			return
	
	process: (interval)-> 
		setInterval (()=> this.run()), interval
	
	queue: (task, data, delay)->
		delay or= 0
		@server.query "insert into tasks (task, data, delay) values ($1, $2, now() + interval '#{delay} second')", [task, JSON.stringify(data)], (results, err)->
			console.log err if err?
		return

	requeue: (id, delay)->
		delay or= 0
		@server.query "update tasks set (status, delay) = (null, now() + interval '#{delay} second') where _id = $1", [id], (results, err)->
			console.log err if err?	
		return

	delete: (id)->
		@server.query "delete from tasks where _id = $1", [id], (results, err)->
			console.log err if err?
		return

	update: (id, column, value)->
		@server.query "update tasks set (#{column}) = ($1) where _id = $2", [value, id], (results, err)->
			console.log err if err?	
		return
		
	next: (cb)->
		return cb null if @cache_update is true
		if @cache.length == 0
			@cache_update = true 
			@server.query "begin work; lock table tasks in access exclusive mode; update tasks set (status, try, last_try) = ('running', try+1, now()) where _id in (select _id from tasks where delay < now() and (status not in ('running', 'error') or status is null) order by try asc, _id asc limit 50) returning *; commit work;", [], (results, err)=>
				console.log err if err?
				for row in results.rows
					data = JSON.parse row.data
					task = 
						'id'		: row._id
						'workunit'	: data.workunit
						'task'		: row.task
						'data'		: data
					@cache.push task
				if @cache.length == 0
					setTimeout (()=> @cache_update = false), 5000
					return cb null
				else
					@cache_update = false
					return this.next cb
		else if @cache.length > 0
			return cb @cache.shift()
		else
			return cb null

	# Task types: check_input, register_input, register_output, check_done, check_workunit	
	run: ()->
		this.next (task)=>
			return if not task?
			#console.log "----------> #{task.task}"
			switch task.task
				when "register_input"
					registerShock @server, task.workunit, task.data, (results, err)=>
						if err?
							# console.log "register input - #{task.id} - #{task.workunit} - error"
							console.log err
							this.update task.id, 'status', 'error'
						else
							#console.log "----------> register input - #{task.id} - #{task.workunit} - success"
							task.data.file_name = results.file_name
							task.data.url = "http://#{@server.shockUrl}#{if @server.shockPort then ":#{@server.shockPort}" else "" }/node/#{results.id}/?download"
							task.data.checksum = results.checksum
							@workunit.update task.workunit, task.data, (err)=>
								console.log err if err?
								this.delete task.id
				when "register_output"
					registerShock @server, task.workunit, task.data, (results, err)=>
						if err?
							# console.log "register output - #{task.id} - #{task.workunit} - error"
							console.log err
							this.update task.id, 'status', 'error'
						else
							# console.log "register output - #{task.id} - #{task.workunit} - success"
							this.delete task.id
							task.data.url = "http://#{@server.shockUrl}#{if @server.shockPort then ":#{@server.shockPort}" else "" }/node/#{results.id}"
							@workunit.update task.workunit, task.data, (err)=>
								console.log err if err?
								return
				when "check_done"
					console.log "checking done"
				when "check_workunit"
					@workunit.check task.workunit, (done)=>
						if done
							# console.log "check workunit - #{task.id} - #{task.workunit} - ready"
							@workunit.update task.workunit, {'status': 'ready'}, (err)=>
								console.log err if err?
								this.delete task.id
						else
							# console.log "check workunit - #{task.id} - #{task.workunit} - not ready"
							this.requeue task.id, 20							

##########################################################################
# exports
##########################################################################

module.exports = TaskQueue

##########################################################################
# helper functions
##########################################################################
class WorkUnit
	constructor: (server)->
		@server = server	
		@updating = {}
		
	update: (id, data, cb)->
		if @updating[id] is true
			setTimeout (()=> 
				this.update id, data, cb
			), 50
		else
			@updating[id] = true
			if data.status?
				@server.query "update workunits set (status) = ($1) where _id = $2", [data.status, id], (results, err)=>
					@updating[id] = false
					return cb err if err?
					return cb null
			else
				@server.query "select * from workunits where _id = #{id}", [], (results, err)=>
					if err?
						console.log err 
						return cb null
					workunit = JSON.parse results.rows[0].workunit
					if data.output?			
						if data.url?
							workunit.outputs[data.output].url = data.url
					if data.input?
						if data.url?
							workunit.inputs[data.input].url = data.url
						if data.checksum?
							workunit.inputs[data.input].checksum = data.checksum
						if data.size?
							workunit.inputs[data.input].size = data.size
						if data.file_name?
							workunit.inputs[data.input].file_name = data.file_name
					@server.query "update workunits set (workunit) = ('#{JSON.stringify(workunit)}') where _id = #{id}", [], (results, err)=>
						@updating[id] = false
						return cb err if err?
						return cb null

	check: (id, cb)->
		@server.query "select * from workunits where _id = $1", [id], (results, err)=>
			console.log err if err?
			workunit = JSON.parse results.rows[0].workunit
			return cb false if not workunit.inputs?
			return cb false if not workunit.outputs?
			for name, input of workunit.inputs
				if not (input.url? and input.url != "" and input.checksum? and input.checksum != "" )
					return cb false
			for name, output of workunit.outputs
				if not (output.url? and output.url != "")
					return cb false
			return cb true
		
checkShock = (server, id, data, cb)->
	parsed = url.parse data.url
	options= 'host':parsed.hostname, 'port':parsed.port, 'method':'GET', 'path':parsed.pathname, 'headers':{'User-Agent':'Node.js (AWE)'}
	request = new Request(options, [], [])
	request.send (err, res)=>
		return cb null, err if err?
		try
			shockRes = JSON.parse(res.body)
		catch err
			return cb false
		if shockRes? and shockRes.status is 'ready'
			data.file_name = shockRes.file_name
			data.size = shockRes.file_size
			data.checksum = shockRes.file_checksum
			updateWorkunit server, id, data, ()=>
				cb err
		else
			return cb false
		
registerShock = (server, id, data, cb)->
	options= 'host':server.shockUrl, 'port':server.shockPort, 'method':'POST', 'path':'/register', 'headers':{'User-Agent':'Node.js (AWE)', 'Content-Type':'multipart/form-data', 'Connection':'keep-alive', 'Transfer-Encoding':'chunked'}
	reqFields = []
	reqFiles = []	
	attributes = 
		"awe_id" : id
	attributes['input'] = data.input if data.input?
	attributes['output'] = data.output if data.output?
	attrFile = JSON.stringify(attributes)
	reqFiles.push ['attributes', 'attributes.json', null, attrFile]
	if data.file?
		reqFiles.push ['file', data.file.name, data.file.path]
	request = new Request(options, reqFields, reqFiles)
	request.send (err, res)=>
		return cb null, err if err?
		switch res.statusCode
			when 302
				if data.file?
					fs.unlink data.file.path
				parsed = url.parse res.headers.location
				options= 'host':parsed.hostname, 'port':parsed.port, 'method':'GET', 'path':parsed.pathname, 'headers':{'User-Agent':'Node.js (AWE)'}
				request = new Request(options, [], [])
				request.send (err, res)=>
					try
						shockRes = JSON.parse(res.body)
					catch err
						return cb null, err
					return cb shockRes, null
			when 200
				if data.file?
					fs.unlink data.file.path					
				try
					shockRes = JSON.parse(res.body)
				catch err
					return cb null, err
				return cb shockRes, null
			when 404
				return cb null, "shock not reachable"		