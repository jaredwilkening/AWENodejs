/**********************************************
 *        AWE - Another Workflow Engine        
 * Author:  Jared Wilkening (jared@mcs.anl.gov)
 **********************************************/

var express    = require('express');
var formidable = require('formidable');
var pg         = require('pg');
var md5        = require("./lib/md5.js");
var path       = require('path');
var sys        = require('sys');
var fs         = require('fs');
var exec       = require('child_process').exec;
var spawn      = require('child_process').spawn;

// Config
var conf;
try {
	conf = JSON.parse(fs.readFileSync("conf.json", 'utf8'));	
} catch (err){
	console.log(err);
}

var verbose = conf.verbose;
var app = express.createServer();
var port = conf.port;
var ver = conf.version;
var dbconnect = conf[ver].dbconnect;
var jobs_dir = conf[ver].jobsdir;
var uploads_dir = conf[ver].uploads; 

app.configure(function(){
	app.use(express.logger({ format: ':remote-addr - - [:date] ":method :url" :status - :response-time ms' }));
	app.use(express.static("static"));
	app.use(app.router);
	app.set('view engine', 'jade');
});

function  get(url, callback){ try {  app.get(url, callback); } catch (err) { console.log(err); }}
function post(url, callback){ try {	app.post(url, callback); } catch (err) { console.log(err); }}

function pgquery(dbconnect, query_statement, query_array, callback) {
	pg.connect(dbconnect, function(err, client) { 
		if (err) { console.log(err); } else {
			client.query(query_statement, query_array, function (err, data) {
				if (err) { console.log(err); } else {
					if (typeof(callback) == "function") {				
						callback(data);
					}
				}
			});
		}
	});		
}

// AWE status
get('/', function(req, res, next){
	pgquery(dbconnect, "select * from jobs", [], function (data) {
		var columns = ['job_name', 'creation', 'priority', 'total','avail', 'complete', 'done'];
		var rows = [];
		if (data.rows.length > 0) {
			for (var r in data.rows){
				var tmp = [];
				for (var c in columns) {
					tmp.push(data.rows[r][columns[c]]);
				}
				rows.push(tmp);
			}
		}
		res.render('index', {locals: { pageTitle: "AWE - status", columns: columns, rows: rows}});
	});
});

get('/count/:type', function(req, res){
	if (req.params.type == 'queued') {
		pgquery(dbconnect, "select count(_id) from workunits where not checkout", [], function (data) {
			res.writeHead(200, {'content-type': 'text/plain'});
		  	res.end(""+data.rows[0].count);
		});
	} else if (req.params.type == 'running') {
		pgquery(dbconnect, "select count(_id) from workunits where checkout", [], function (data) {
			res.writeHead(200, {'content-type': 'text/plain'});
		  	res.end(""+data.rows[0].count);
		});
	} else {
	  	res.writeHead(200, {'content-type': 'text/plain'});
	  	res.end('ERROR: must specify count type via /count/queued|running');
	}
});

// AWE file downloads
get('/checkout', function(req, res){
	if (req.query.checkout_auth) {
		var c_auth = req.query.checkout_auth;
		var file_md5 = md5(c_auth+new Date().getTime().toString());
		pgquery(dbconnect, "select * from getWorkunits($1,$2,1)", [c_auth, file_md5], function (data) {
			if (data.rows.length > 0 && data.rows[0].job_name !== null){
				fs.stat(jobs_dir+"/"+data.rows[0].job_name, function (err, stats) {
					if (err) {
						res.writeHead(200, {'content-type': 'text/plain'});
						res.end("No work");
					} else {
						res.writeHead(200, {'content-type': 'application/octet-stream', 'content-disposition': ':attachment;filename='+file_md5});
						fs.createReadStream(jobs_dir+"/"+data.rows[0].job_name, {encoding: 'utf8', start: data.rows[0].f_offset, end: (data.rows[0].f_offset + data.rows[0].f_length)}).addListener("data", function(chunk){
							res.write(chunk);
				  		}).addListener("end", function () {
					  		res.end();
						});
					}
				});
			} else {
				res.writeHead(200, {'content-type': 'text/plain'});
				res.end("No work");
			}
		});
	} else {
		res.writeHead(200, {'content-type': 'text/plain'});
		res.end('ERROR: checkout_auth required');
	}
}); 


// AWE file uploads
get('/checkin', function(req, res){
	res.render('checkin', {locals: { pageTitle: "AWE - checkin"}});
}); 

get('/checkin/empty', function(req, res){
	if (req.query.filename) {
		res.writeHead(200, {'content-type': 'text/plain'});
		res.end('OK');			
		pgquery(dbconnect, "select doneworkunits as job_name from doneWorkunits($1)", [req.query.filename], function (data){
			if (data.rows.length > 0 && data.rows[0].job_name !== null) {
				var touch = spawn('touch', [jobs_dir+'/'+data.rows[0].job_name+'.results/'+req.query.filename+".empty"]);
				touch.stderr.on('data', function(data){ console.log('mv stderr: '+data);});
			} else {
				console.log("Could not find file: "+req.query.filename+" in db.");
			}
		});
	} else {
		res.writeHead(200, {'content-type': 'text/plain'});
		res.end('ERROR: filename required');
	} 	 
});

post('/checkin', function(req, res){
	var form = new formidable.IncomingForm();
	form.uploadDir = uploads_dir;
	form.parse(req, function(err, fields, files) {
		res.writeHead(200, {'content-type': 'text/plain'});
		res.end('received upload');
		for (var f in files) {
			filename = path.basename(files[f].filename);
			pgquery(dbconnect, "select doneworkunits as job_name from doneWorkunits($1)", [filename], function (data) {
				if (data.rows.length > 0 && data.rows[0].job_name !== null) {
					(verbose) ? console.log(data.rows[0]) : '';
					var mv = spawn('mv', [files[f].path, jobs_dir+'/'+data.rows[0].job_name+'.results/'+filename]);
					mv.stderr.on('data', function(data){ console.log('mv stderr: '+data);});
				} else {
					console.log("Could not find file: "+filename+" in db.");
				}					
			});		
		}
	});
});

// AWE release 
get('/release', function(req, res){
	if (req.query.filename) {
		pgquery(dbconnect, "select * from releaseWorkunits($1)", [req.query.filename]);
	  	res.writeHead(200, {'content-type': 'text/plain'});
	  	res.end('received release');
	} else {
	  res.writeHead(200, {'content-type': 'text/plain'});
	  res.end('ERROR: filename required');
	}
});

// Timed work release 
setInterval(function() {
	pgquery(dbconnect, "select releaseexpiredworkunits as r_count from releaseExpiredWorkunits()", [], function (data) {
		if (data.rows.length > 0 && data.rows[0].r_count > 0){
			console.log('Released '+data.rows[0].r_count+' expired workunits');
		} else {
			(verbose) ? console.log('No expired workunits') : '';
		}		
	});
}, 60000);

// Time check to deal with finished jobs 
setInterval(function() { 
	pgquery(dbconnect, "select _id, job_name, done_file, done_script from jobs where done", [], function (data) {    
    	if (data.rows.length > 0){ 
			for (var r in data.rows){
				try {  
            		finish_job(data.rows[r]); 
				} catch (err) {
					console.log(err);
				}
			} 
 		} 
	}); 
}, 120000);

function finish_job(row) {
	if (!row.done_file) {
		(verbose) ? console.log("Job "+row.job_name+" done. No done_file.") : "";
 		return;
  	}
	(verbose) ? console.log("Job "+row.job_name+" done.") : "";
	
	pgquery(dbconnect, "delete from jobs where _id = $1", [row._id], function (data) {
		(verbose) ? console.log("Job "+row.job_name+" removed from DB.") : "";
	});
	if (row.done_script) {
		(verbose) ? console.log("Job "+row.job_name+": executing done script.") : "";
		exec(row.done_script, function (error, stdout, stderr) {
			if (error !== null) {
				console.log(error);
			} else {		
				(verbose) ? console.log(stdout) : "";
			}
		});
	}
}

// And away we go...
console.log("Starting server at port :"+port);
app.listen(port);
