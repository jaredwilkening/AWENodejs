--**********************************************
--*        AWE - Another Workflow Engine        
--* Author:  Jared Wilkening (jared@mcs.anl.gov)
--**********************************************

drop table if exists workunits, types cascade;
drop sequence if exists workSeq, typeSeq cascade;

create sequence workSeq;
create sequence typeSeq;

create table types (
	_id			int primary key default nextval('typeSeq'),
	type		varchar(64) unique,
	template	text not null,
	checker		text default null,
	owner		varchar(64) default null,
	partionable	boolean default FALSE
);
	
create table workunits (
	_id				int primary key default nextval('workSeq'),
	workunit		text not null,
	type			varchar(64) references types (type),
	owner			varchar(64) default null,
	priority		int default 1,
	creation_time	timestamp DEFAULT current_timestamp,
	checkout_status	varchar(64) default null,
	checkout_host	varchar(64) default null,
	checkout_time	timestamp default null,
	release_time	timestamp default null,
	done			boolean default FALSE
);

