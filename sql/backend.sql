--**********************************************
--*        AWE - Another Workflow Engine        
--* Author:  Jared Wilkening (jared@mcs.anl.gov)
--**********************************************

drop table if exists workunits, types, stats, tasks cascade;
		
create table types (
	_id			serial primary key,
	type		varchar(64) unique,
	template	text not null,
	checker		text,
	owner		varchar(64),
	partionable	boolean default FALSE
);
	
create table workunits (
	_id				serial primary key,
	workunit		text not null,
	type			varchar(64) references types (type),
	status			varchar(64),
	owner			varchar(64),
	priority		int default 1,
	creation_time	timestamp DEFAULT current_timestamp,	
	checkout_host	varchar(64),
	checkout_time	timestamp,
	release_time	timestamp,
	done			boolean default FALSE
);

create table stats (
	_id			serial primary key,
	type		varchar(64) references types (type),
	wid			int not null,
	workunit	text,
	transfer    bigint not null,
	walltime	bigint not null,
	size        bigint not null,
	hostname    varchar(64),
	cpus		int,
	mem			int,
	cpu_avg		float,
	cpu_peak	float,
	mem_avg		float,
	mem_peak	float,
	iowait_avg	float,
	iowait_peak	float
);

create table tasks (
	_id				serial primary key,
	task			varchar(64) not null,
	data			text not null,
	status			varchar(64),
	error_message	text,
	attempt			int default 0,
	last_attempt	timestamp,
	delay			timestamp
);
