# Another Workflow Engine (AWE) API v0.1

As of the moment

# work 
- - -
<br>
## list workunits
### request
GET	$aweUrl/work

#### request body
None

#### request parameters
None
<br>
### response
Array of workunits json encoded

Example:

	{ 
		"results_count" : 2,
		"results" : [
			{
				"id":"14",
				"type":"simple",
				"workunit":{
					"about":"AWE workunit",
					"cmd":"cat",
					"options":"",
					"args":"<inputs::i1> <inputs::i2> > <outputs::o1>",
					"inputs":{
						"i1":{
							"fileName":"10kb_gsflex.fna",
							"url":"http://localhost:8888/awe/84/file",
							"size":11915
						},
						"i2":{
							"fileName":"10kb_gsflex.fna",
							"url":"http://localhost:8888/awe/85/file",
							"size":11915
						}
					},
					"outputs":{
						"o1":{
							"url":"http://localhost:8888/awe/o1_shockId/file"
						}
					}
				},
				"priority":1,
				"creation_time":"2011-09-27T14:32:29.706Z",
				"checkout_status":"checked_out",
				"checkout_host":"localhost",
				"checkout_time":"2011-09-28T11:41:43.796Z",
				"release_time":"2011-09-28T12:41:43.796Z"
			},
			{
				"id":"15",
				"type":"simple",
				"workunit":{
					"about":"AWE workunit",
					"cmd":"cat",
					"options":"",
					"args":"<inputs::i1> <inputs::i2> > <outputs::o1>",
					"inputs":{
						"i1":{
							"fileName":"10kb_gsflex.fna",
							"url":"http://localhost:8888/awe/84/file",
							"size":11915
						},
						"i2":{
							"fileName":"10kb_gsflex.fna",
							"url":"http://localhost:8888/awe/85/file",
							"size":11915
						}
					},
					"outputs":{
						"o1":{
							"url":"http://localhost:8888/awe/o1_shockId/file"
						}
					}
				},
				"priority":1,
				"creation_time":"2011-09-27T14:32:29.706Z",
				"checkout_status":"checked_out",
				"checkout_host":"localhost",
				"checkout_time":"2011-09-28T11:41:43.796Z",
				"release_time":"2011-09-28T12:41:43.796Z"
			}
		]
	}
<br><br>
## retrieve single workunit
### request
GET	$aweUrl/work/$id

#### request body
None

#### request parameters
None
<br>
### response
single workunit json encoded

Example:

	{
		"id":"14",
		"type":"simple",
		"workunit":{
			"about":"AWE workunit",
			"cmd":"cat",
			"options":"",
			"args":"<inputs::i1> <inputs::i2> > <outputs::o1>",
			"inputs":{
				"i1":{
					"fileName":"10kb_gsflex.fna",
					"url":"http://localhost:8888/awe/84/file",
					"size":11915
				},
				"i2":{
					"fileName":"10kb_gsflex.fna",
					"url":"http://localhost:8888/awe/85/file",
					"size":11915
				}
			},
			"outputs":{
				"o1":{
					"url":"http://localhost:8888/awe/o1_shockId/file"
				}
			}
		},
		"priority":1,
		"creation_time":"2011-09-27T14:32:29.706Z",
		"checkout_status":"checked_out",
		"checkout_host":"localhost",
		"checkout_time":"2011-09-28T11:41:43.796Z",
		"release_time":"2011-09-28T12:41:43.796Z"
	}
<br><br> 
## register workunit
### request
POST $aweUrl/work/register

#### request body
multipart encode form 

#### request parameters
None
<br>
#### response
302 redirect to workunit

	HTTP/1.1 302 Moved Temporarily
	Content-Type: text/html
	Location: http://awe.mcs.anl.gov/work/146
	<p>Moved Temporarily. Redirecting to <a href="http://awe.mcs.anl.gov/work/146">http://awe.mcs.anl.gov/work/146</a></p>
<br><br>  
## checkout workunit
### request
POST $aweUrl/work/checkout

#### request body
None

#### request parameters
None
<br>
### response
302 redirect to workunit
<br><br>  
## renew workunit lease
### request
GET $aweUrl/work/renew

#### request body
None

#### request parameters
None
<br>
### response

	{
		"status":"Success",
		"release_time":"2011-09-28T12:41:43.796Z"
	}
<br><br>  
## mark workunit as done
### request
POST $aweUrl/work/done

#### request body
None

#### request parameters
None
<br>
### response

	{
		"status":"Success"
	}
<br><br>  
## release workunit lease
### request
POST $aweUrl/work/release

#### request body
None

##### request parameters
None
<br>
### response

	{
		"status":"Success"
	}
  
<br><br>
# type
- - -
<br>
## list types
### request
POST $aweUrl/type

#### request body
None

#### request parameters
None
<br>
### response
Array of types json encoded

Example:

	{ 
		"results_count" : 2,
		"results" : [
			{
				"id":"16",
				"type":"simple",
				"partionable":false,
				"template":{
					"about":"AWE workunit",
					"type":"simple",
					"cmd":"cat",
					"options":"",
					"args":"<inputs::i1> <inputs::i2> > <outputs::o1>",
					"inputs":{
						"i1":{
							"file_name":"",
							"url":"",
							"checksum":""
						},
						"i2":{
							"file_name":"",
							"url":"",
							"checksum":""
						}
					},
					"outputs":{
						"o1":{
							"file_name":"",
							"url":"",
							"run-time":""
						}
					}
				},
				"checker": null
			},
			{
				"id":"17",
				"type":"simple2",
				"partionable":false,
				"template":{
					"about":"AWE workunit",
					"type":"simple",
					"cmd":"cat",
					"options":"",
					"args":"<inputs::i1> <inputs::i2> > <outputs::o1>",
					"inputs":{
						"i1":{
							"file_name":"",
							"url":"",
							"checksum":""
						},
						"i2":{
							"file_name":"",
							"url":"",
							"checksum":""
						}
					},
					"outputs":{
						"o1":{
							"file_name":"",
							"url":"",
							"run-time":""
						}
					}
				},
				"checker": null
			}
		]
	}			
<br><br>	
## retrieve type
### request
GET $aweUrl/type/$id

#### request body
None

#### request parameters
None
<br>
### response
Type object json encoded

Example:

	{
		"id":"16",
		"type":"simple",
		"partionable":false,
		"template":{
			"about":"AWE workunit",
			"type":"simple",
			"cmd":"cat",
			"options":"",
			"args":"<inputs::i1> <inputs::i2> > <outputs::o1>",
			"inputs":{
				"i1":{
					"file_name":"",
					"url":"",
					"checksum":""
				},
				"i2":{
					"file_name":"",
					"url":"",
					"checksum":""
				}
			},
			"outputs":{
				"o1":{
					"file_name":"",
					"url":"",
					"run-time":""
				}
			}
		},
		"checker": null
	}
<br><br>
## modify type
### request
PUT $aweUrl/type/$id

#### request body
mutlipart encoded form (all fields are optional)

type (string)

	name of type 

template (json file)

	{
		"about":"AWE workunit",
		"type":"simple",
		"cmd":"cat",
		"options":"",
		"args":"<inputs::i1> <inputs::i2> > <outputs::o1>",
		"inputs":{
			"i1":{
				"file_name":"",
				"url":"",
				"checksum":""
			},
			"i2":{
				"file_name":"",
				"url":"",
				"checksum":""
			}
		},
		"outputs":{
			"o1":{
				"file_name":"",
				"url":"",
				"run-time":""
			}
		}
	}

checker (json file)

	workunit that will verify runablity (not implemented)

partionable (boolean)

	contains partionable input

#### request parameters
None
<br>
### response
302 redirect to workunit

	HTTP/1.1 302 Moved Temporarily
	Content-Type: text/html
	Location: http://awe.mcs.anl.gov/type/16
	<p>Moved Temporarily. Redirecting to <a href="http://awe.mcs.anl.gov/type/16">http://awe.mcs.anl.gov/type/16</a></p>
<br><br>
## register type
### request
POST $aweUrl/type/register

#### request body
mutlipart encoded form (required fields*)

type (string)*

	name of type 

template (json file)*

	{
		"about":"AWE workunit",
		"type":"simple",
		"cmd":"cat",
		"options":"",
		"args":"<inputs::i1> <inputs::i2> > <outputs::o1>",
		"inputs":{
			"i1":{
				"file_name":"",
				"url":"",
				"checksum":""
			},
			"i2":{
				"file_name":"",
				"url":"",
				"checksum":""
			}
		},
		"outputs":{
			"o1":{
				"file_name":"",
				"url":"",
				"run-time":""
			}
		}
	}
	
checker (json file)

	workunit that will verify runablity (not implemented)
	
partionable (boolean)

	contains partionable input	
	
#### request parameters
None
<br>
### response

	{
		"status":"Success"
	}
<br><br>
## delete type
### request
DELETE $aweUrl/type/$id

#### request body
None

#### request parameters
None
<br>
### response

	{
		"status":"Success"
	}
<br><br>