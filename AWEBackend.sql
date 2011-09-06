--**********************************************
--*        AWE - Another Workflow Engine        
--* Author:  Jared Wilkening (jared@mcs.anl.gov)
--**********************************************

drop table if exists jobs cascade;
drop table if exists workunits cascade;

drop sequence if exists jobs_seq, workunits_seq cascade;

create sequence jobs_seq;
create sequence workunits_seq;

drop type if exists w_return cascade;
create type w_return as (
	job_name    varchar(40),
	_id       	int,
	job_id		int,
	f_offset	bigint,
	f_length	int
);

create table jobs (
	_id			int primary key default nextval('jobs_seq'),
	job_name	varchar(40),
	username	varchar(10) default null,
	priority	int default 1,
	total		int,
	avail		int,
	complete	int default 0,
	done		boolean default null,
	done_file 	varchar(256),
	done_script varchar(256),
	creation	timestamp DEFAULT current_timestamp	
);		

create table workunits (
	_id				int primary key default nextval('workunits_seq'),
	job_id			int references jobs(_id) on delete cascade,
	f_offset		bigint not null,
	f_length		int not null,
	checkout		boolean default FALSE,
	checkout_auth	char(32) default null,
	checkout_file	char(32) default null,
	checkout_time	timestamp default null,
	release_time	timestamp default null
);

create or replace function getWorkunits(c_auth text, c_file text, amount int) returns setof w_return as $$
declare
	job jobs%rowtype;
	r 	w_return%rowtype;
begin
	lock table jobs in access exclusive mode;
	select * into job from jobs where avail > 0 order by priority desc, creation asc limit 1;
	if job._id > 0 then
		for r in select j.job_name, w._id, w.job_id, w.f_offset, w.f_length from (select workunits._id, workunits.job_id, workunits.f_offset, workunits.f_length from workunits where workunits.job_id = job._id and not checkout limit amount) as w, (select jobs.job_name, jobs._id from jobs where jobs._id = job._id) as j where w.job_id = j._id loop
		 	update workunits set (checkout, checkout_auth, checkout_file, checkout_time, release_time) = (TRUE, c_auth, c_file, current_timestamp, current_timestamp + interval '90 minute') where workunits._id = r._id;
			update jobs set avail = (avail - 1) where jobs._id = job._id;		
			return next r;
		end loop;
		return;
	end if;
	return;
end;
$$ language plpgsql;

create or replace function doneWorkunits(c_file text) returns varchar(40) as $$
declare
	j_id int;
	num_deleted int;
	job jobs%rowtype;
begin
 	select job_id into j_id from workunits where checkout and checkout_file = c_file limit 1;
	delete from workunits where checkout and checkout_file = c_file;
	get diagnostics num_deleted = row_count;
	lock table jobs in row exclusive mode;
	update jobs set complete = complete + num_deleted where _id = j_id returning * into job;
	if job.complete = job.total then
	   update jobs set done = TRUE where _id = j_id;
	end if; 
	return job.job_name;
end;
$$ language plpgsql;

create or replace function releaseWorkunits(c_file text) returns int as $$
declare
	num_updated int;
	j_id int;
begin
	select job_id into j_id from workunits where checkout_file = c_file limit 1;  		
	update workunits set (checkout, checkout_auth, checkout_file, checkout_time, release_time) = (FALSE, null, null, null, null) where checkout_file = c_file;
	get diagnostics num_updated = row_count;
	if num_updated > 0 then
		lock table jobs in row exclusive mode;
		update jobs set avail = avail + num_updated where _id = j_id; 
	end if;
	return num_updated;
end;
$$ language plpgsql;

create or replace function releaseExpiredWorkunits() returns int as $$
declare
	num_updated int := 0;
	j_id int;
	r workunits%rowtype;
begin
	for r in select * from workunits where release_time < current_timestamp loop		
		update workunits set (checkout, checkout_auth, checkout_file, checkout_time, release_time) = (FALSE, null, null, null, null) where _id = r._id returning job_id into j_id;
		lock table jobs in row exclusive mode;
		update jobs set avail = avail + 1 where _id = j_id;
		num_updated = num_updated + 1;
	end loop;
	return num_updated;
end;
$$ language plpgsql;