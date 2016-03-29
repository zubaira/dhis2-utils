﻿
-- DATA ELEMENTS

-- Data elements and frequency with average agg operator (higher than yearly negative for data mart performance)

select d.dataelementid, d.name as dataelement, pt.name as periodtype from dataelement d 
join datasetmembers dsm on d.dataelementid=dsm.dataelementid 
join dataset ds on dsm.datasetid=ds.datasetid 
join periodtype pt on ds.periodtypeid = pt.periodtypeid 
where d.aggregationtype = 'average'
order by pt.name;

-- Data elements with aggregation levels

select d.dataelementid, d.name, dal.aggregationlevel from dataelementaggregationlevels dal 
join dataelement d on dal.dataelementid=d.dataelementid 
order by name, aggregationlevel;

-- Data elements with less than 100 data values

select de.dataelementid, de.name, (select count(*) from datavalue dv where de.dataelementid=dv.dataelementid) as count 
from dataelement de
where (select count(*) from datavalue dv where de.dataelementid=dv.dataelementid) < 100
order by count;

-- Number of data elements with less than 100 data values

select count(*) from dataelement de
where (select count(*) from datavalue dv where de.dataelementid=dv.dataelementid) < 100;

-- Duplicate data element codes

select code, count(code) as count
from dataelement
group by code
order by count desc;

-- Display overview of data elements and related category option combos

select de.uid as dataelement_uid, de.name as dataelement_name, de.code as dataelement_code, coc.uid as optioncombo_uid, cocn.categoryoptioncomboname as optioncombo_name 
from _dataelementcategoryoptioncombo dcoc 
inner join dataelement de on dcoc.dataelementuid=de.uid 
inner join categoryoptioncombo coc on dcoc.categoryoptioncombouid=coc.uid 
inner join _categoryoptioncomboname cocn on coc.categoryoptioncomboid=cocn.categoryoptioncomboid 
order by de.name;

-- (Write) Remove data elements from data sets which are not part of sections

delete from datasetmembers dsm
where dataelementid not in (
  select dataelementid from sectiondataelements ds
  inner join section s on (ds.sectionid=s.sectionid)
  where s.datasetid=dsm.datasetid)
and dsm.datasetid=1979200;


-- CATEGORIES

-- Exploded category option combo view

select cc.categorycomboid, cc.name as categorycomboname, cn.* from _categoryoptioncomboname cn
join categorycombos_optioncombos co using(categoryoptioncomboid)
join categorycombo cc using(categorycomboid)
order by categorycomboname, categoryoptioncomboname;

-- Display category option combo identifier and name

select cc.categoryoptioncomboid as id, uid, categoryoptioncomboname as name, code
from categoryoptioncombo cc
join _categoryoptioncomboname cn
on (cc.categoryoptioncomboid=cn.categoryoptioncomboid);

-- Display overview of category option combo

select coc.categoryoptioncomboid as coc_id, coc.uid as coc_uid, co.categoryoptionid as co_id, co.name as co_name, ca.categoryid as ca_id, ca.name as ca_name, cc.categorycomboid as cc_id, cc.name as cc_name
from categoryoptioncombo coc 
inner join categoryoptioncombos_categoryoptions coo on coc.categoryoptioncomboid=coo.categoryoptioncomboid
inner join dataelementcategoryoption co on coo.categoryoptionid=co.categoryoptionid
inner join categories_categoryoptions cco on co.categoryoptionid=cco.categoryoptionid
inner join dataelementcategory ca on cco.categoryid=ca.categoryid
inner join categorycombos_optioncombos ccoc on coc.categoryoptioncomboid=ccoc.categoryoptioncomboid
inner join categorycombo cc on ccoc.categorycomboid=cc.categorycomboid
where coc.categoryoptioncomboid=2118430;

-- Display overview of category option combos

select coc.uid as optioncombo_uid, cocn.categoryoptioncomboname as optioncombo_nafme, cc.uid as categorycombo_uid, cc.name as categorycombo_name 
from categoryoptioncombo coc 
inner join _categoryoptioncomboname cocn on coc.categoryoptioncomboid=cocn.categoryoptioncomboid 
inner join categorycombos_optioncombos ccoc on coc.categoryoptioncomboid=ccoc.categoryoptioncomboid 
inner join categorycombo cc on ccoc.categorycomboid=cc.categorycomboid;

-- Get category option combos linked to category option

select coc.categoryoptioncomboid as coc_id, coc.uid as coc_uid, co.categoryoptionid as co_id, co.name as co_name
from categoryoptioncombo coc 
inner join categoryoptioncombos_categoryoptions coo on coc.categoryoptioncomboid=coo.categoryoptioncomboid
inner join dataelementcategoryoption co on coo.categoryoptionid=co.categoryoptionid
where co.uid='LPeJEUjotaB';


-- ORGANISATION UNITS

-- Facility overview

select distinct ous.idlevel5 as internalid, ou.uid, ou.code, ou.name, ougs.type, ougs.ownership,
ou2.name as province, ou3.name as county, ou4.name as district, ou.coordinates as longitide_latitude
from _orgunitstructure ous
left join organisationunit ou on ous.organisationunitid=ou.organisationunitid
left join organisationunit ou2 on ous.idlevel2=ou2.organisationunitid
left join organisationunit ou3 on ous.idlevel3=ou3.organisationunitid
left join organisationunit ou4 on ous.idlevel4=ou4.organisationunitid
left join _organisationunitgroupsetstructure ougs on ous.organisationunitid=ougs.organisationunitid
where ous.level=5
order by province, county, district, ou.name;

-- Turn longitude/latitude around for organisationunit coordinates (adjust the like clause)

update organisationunit set coordinates=regexp_replace(coordinates,'\[(.+?\..+?),(.+?\..+?)\]','[\2,\1]')
where coordinates like '[0%'
and featuretype='Point';

-- Fetch longitude/latitude from organisationunit

select name, coordinates, 
cast( regexp_replace( coordinates, '\[(-?\d+\.?\d*)[,](-?\d+\.?\d*)\]', '\1' ) as double precision ) as longitude,
cast( regexp_replace( coordinates, '\[(-?\d+\.?\d*)[,](-?\d+\.?\d*)\]', '\2' ) as double precision ) as latitude 
from organisationunit
where featuretype='Point';

-- Identify empty groups

select 'Data element group' as type, o.name as name
from dataelementgroup o
where not exists (
  select * from dataelementgroupmembers
  where dataelementgroupid=o.dataelementgroupid)
union all
select 'Indicator group' as type, o.name as name
from indicatorgroup o
where not exists (
  select * from indicatorgroupmembers
  where indicatorgroupid=o.indicatorgroupid)
union all
select 'Organisation unit group' as type, o.name as name
from orgunitgroup o
where not exists (
  select * from orgunitgroupmembers
  where orgunitgroupid=o.orgunitgroupid)
order by type,name;

-- Nullify coordinates with longitude outside range (adjust where clause values)

update organisationunit set coordinates=null
where featuretype='Point'
and (
  cast(substring(coordinates from '\[(.+?\..+?),.+?\..+?\]') as double precision) < 32
  or cast(substring(coordinates from '\[(.+?\..+?),.+?\..+?\]') as double precision) > 43
);

-- (Write) Replace first digit in invalid uid with letter a

update organisationunit set uid = regexp_replace(uid,'\d','a') where uid SIMILAR TO '[0-9]%';

-- (Write) Insert random org unit codes

create function setrandomcode() returns integer AS $$
declare ou integer;
begin
for ou in select organisationunitid from _orgunitstructure where level=6 loop
  execute 'update organisationunit set code=(select substring(cast(random() as text),5,6)) where organisationunitid=' || ou;
end loop;
return 1;
end;
$$ language plpgsql;

select setrandomcode();


-- USERS

-- Compare user roles (lists what is in the first role but not in the second)

select authority from userroleauthorities where userroleid=33706 and authority not in (select authority from userroleauthorities where userroleid=21504);

-- User overview (Postgres only)

select u.username, u.lastlogin, u.selfregistered, ui.surname, ui.firstname, ui.email, ui.phonenumber, ui.jobtitle, (
  select array_to_string( array(
    select name from userrole ur
    join userrolemembers urm using(userroleid)
    where urm.userid=u.userid), ', ' )
  )  as userroles, (
  select array_to_string( array(
    select name from organisationunit ou
    join usermembership um using(organisationunitid)
    where um.userinfoid=ui.userinfoid), ', ' )
  ) as orgunits
from users u 
join userinfo ui on u.userid=ui.userinfoid
order by u.username;

-- Users in user role

select u.userid, u.username, ui.firstname, ui.surname from users u 
inner join userinfo ui on u.userid=ui.userinfoid 
inner join userrolemembers urm on u.userid=urm.userid 
inner join userrole ur on urm.userroleid=ur.userroleid 
where ur.name='UserRoleName';

-- Users with ALL authority

select u.userid, u.username, ui.firstname, ui.surname from users u 
inner join userinfo ui on u.userid=ui.userinfoid
where u.userid in (
  select urm.userid from userrolemembers urm 
  inner join userrole ur on urm.userroleid=ur.userroleid
  inner join userroleauthorities ura on ur.userroleid=ura.userroleid 
  where ura.authority = 'ALL'
);

-- User roles with authority

select ur.userroleid, ur.name
from userrole ur
inner join userroleauthorities ura on ur.userroleid=ura.userroleid 
where ura.authority = 'ALL';

-- (Write) MD5 set password to "district" for admin user

update users set password='48e8f1207baef1ef7fe478a57d19f2e5' where username='admin';

-- (Write) Bcrypt set password to "district" for admin user

update users set password='$2a$10$wjLPViry3bkYEcjwGRqnYO1bT2Kl.ZY0kO.fwFDfMX53hitfx5.3C' where username='admin';


-- VALIDATION RULES

-- Display validation rules which includes the given data element uid

select distinct vr.uid, vr.name
from validationrule vr
inner join expression le on vr.leftexpressionid=le.expressionid
inner join expression re on vr.rightexpressionid=re.expressionid
where le.expression ~ 'OuudMtJsh2z'
or re.expression  ~ 'OuudMtJsh2z'
  
-- (Write) Delete validation rules and clean up expressions

delete from validationrule where name = 'abc';
delete from expressiondataelement where expressionid not in (
  select leftexpressionid from validationrule
  union all
  select rightexpressionid from validationrule
);
delete from expression where expressionid not in (
  select leftexpressionid from validationrule
  union all
  select rightexpressionid from validationrule
);

-- DASHBOARDS

-- (Write) Remove orphaned dashboard items

delete from dashboarditem di 
where di.dashboarditemid not in (
  select dashboarditemid from dashboard_items)
and di.dashboarditemid not in (
  select dashboarditemid from dashboarditem_reports)
and di.dashboarditemid not in (
  select dashboarditemid from dashboarditem_reporttables)
and di.dashboarditemid not in (
  select dashboarditemid from dashboarditem_resources)
and di.dashboarditemid not in (
  select dashboarditemid from dashboarditem_users);
  
  
-- DATA VALUES

-- Display data out of reasonable time range

select count(*)
from datavalue dv
where dv.periodid in (
  select pe.periodid
  from period pe
  where pe.startdate < '1960-01-01'
  or pe.enddate > '2020-01-01');

-- (Write) Delete all data values for category combo

delete from datavalue where categoryoptioncomboid in (
select coc.categoryoptioncomboid from categoryoptioncombo coc
inner join categorycombos_optioncombos co on coc.categoryoptioncomboid=co.categoryoptioncomboid
inner join categorycombo cc on co.categorycomboid=cc.categorycomboid
where cc.uid='iO1SPIBYKuJ');

-- (Write) Delete all data values for an attribute category option

delete from datavalue dv
where dv.attributeoptioncomboid in (
  select coc.categoryoptioncomboid from categoryoptioncombo coc
  inner join categoryoptioncombos_categoryoptions coo on coc.categoryoptioncomboid=coo.categoryoptioncomboid
  inner join dataelementcategoryoption co on coo.categoryoptionid=co.categoryoptionid
  where co.uid='LPeJEUjotaB');

-- Data value exploded view

select de.name as dename, de.uid as deuid, pe.startdate as pestart, pe.enddate as peend, pt.name as ptname, 
ou.name as ouname, ou.uid as ouuid, coc.uid as cocuid, coc.categoryoptioncomboid as cocid, aoc.uid as aocuid, aoc.categoryoptioncomboid as aocid, dv.value as dvval
from datavalue dv
inner join dataelement de on (dv.dataelementid=de.dataelementid)
inner join period pe on (dv.periodid=pe.periodid)
inner join periodtype pt on (pe.periodtypeid=pt.periodtypeid)
inner join organisationunit ou on (dv.sourceid=ou.organisationunitid)
inner join categoryoptioncombo coc on (dv.categoryoptioncomboid=coc.categoryoptioncomboid)
inner join categoryoptioncombo aoc on (dv.attributeoptioncomboid=aoc.categoryoptioncomboid)
limit 10000;

-- Data values created by day

select dv.created::date as d, count(*) as count
from datavalue dv
inner join period pe on dv.peri	odid=pe.periodid
group by d
order by d;

-- (Write) Move startdate and enddate in period to next year

update period set 
startdate = (startdate + interval '1 year')::date,
enddate = (enddate + interval '1 year')::date;


-- EVENTS

-- Display events out of reasonable time range

select count(*)
from programstageinstance psi
where psi.executiondate < '1960-01-01'
or psi.executiondate > '2020-01-01';

-- Delete events out of reasonable time range

delete from trackedentitydatavalue tdv
where tdv.programstageinstanceid in (
  select psi.programstageinstanceid
  from programstageinstance psi
  where psi.executiondate < '1960-01-01'
  or psi.executiondate > '2020-01-01');

delete from programstageinstance psi
where psi.executiondate < '1960-01-01'
or psi.executiondate > '2020-01-01';

-- Get count of data values by year and month

select extract(year from pe.startdate) as yr, extract(month from pe.startdate) as mo, count(*)
from datavalue dv
inner join period pe on dv.periodid=pe.periodid
where dv.value != '0'
group by yr, mo
order by yr, mo;

-- Get count of datavalues by data element

select de.name as de, count(*) as c
from datavalue dv
inner join dataelement de on dv.dataelementid=dv.dataelementid
group by de
order by c;

-- Get count of data elements per program

select pr.name,count(psd.uid)
from program pr
inner join programstage ps on pr.programid=ps.programid
inner join programstagedataelement psd on ps.programstageid=psd.programstageid
group by pr.name;

-- (Write) Generate random coordinates based on org unit location for events

update programstageinstance psi
set longitude = (
  select ( cast( regexp_replace( coordinates, '\[(-?\d+\.?\d*)[,](-?\d+\.?\d*)\]', '\1' ) as double precision ) + ( random() / 10 ) )
  from organisationunit ou
  where psi.organisationunitid=ou.organisationunitid ),
latitude = (
  select ( cast( regexp_replace( coordinates, '\[(-?\d+\.?\d*)[,](-?\d+\.?\d*)\]', '\2' ) as double precision ) + ( random() / 10 ) )
  from organisationunit ou
  where psi.organisationunitid=ou.organisationunitid );

-- (Write) Move programstageinstance and programinstance to next year

update programstageinstance set 
duedate = (duedate + interval '1 year'),
executiondate = (executiondate + interval '1 year'),
completeddate = (completeddate + interval '1 year'),
created = (created + interval '1 year'),
lastupdated = (lastupdated + interval '1 year');

update programinstance set
incidentdate = (incidentdate + interval '1 year'),
enrollmentdate = (enrollmentdate + interval '1 year'),
enddate = (enddate + interval '1 year'),
created = (created + interval '1 year'),
lastupdated = (lastupdated + interval '1 year');

-- (Write) Move interpretations created / lastupdated to next year

update interpretation set created = (created + interval '1 year');
update interpretation set lastupdated=created;


-- APPROVAL

-- Display dataapproval overview

select dal.name as approvallevel_name, dal.uid as approvallevel_uid, ds.name as dataset_name, ds.uid as dataset_uid, 
pe.startdate, pe.enddate, pt.name as periodtype_name, ou.name as orgunit_name, ou.uid as orgunit_uid, 
aocn.categoryoptioncomboname as attroptioncombo_name, aoc.uid as attroptioncombo_uid, da.accepted, da.created, u.username as creator_username
from dataapproval da
inner join dataapprovallevel dal on da.dataapprovallevelid=dal.dataapprovallevelid
inner join dataset ds on da.datasetid=ds.datasetid
inner join period pe on da.periodid=pe.periodid
inner join periodtype pt on pe.periodtypeid=pt.periodtypeid
inner join organisationunit ou on ou.organisationunitid=da.organisationunitid
inner join categoryoptioncombo aoc on da.attributeoptioncomboid=aoc.categoryoptioncomboid
inner join _categoryoptioncomboname aocn on da.attributeoptioncomboid=aocn.categoryoptioncomboid
inner join users u on da.creator=u.userid
limit 1000;


-- SQL VIEWS

-- Generate SQL statements for dropping all SQL views
-- 1. Save to file with psql -d db -U user -f script.sql > drop.sql
-- 2. Clean up file and drop views with psql -d db -U user -f drop.sql

select 'drop view ' || table_name || ';'
from information_schema.views
where table_schema not in ('pg_catalog', 'information_schema')
and table_name !~ '^pg_' and table_name ~ '^_view';


-- SHARING

-- Remove rows in usergroupaccess which are no longer referenced

delete from usergroupaccess where usergroupaccessid not in (
select usergroupaccessid from categorycombousergroupaccesses
union all select usergroupaccessid from categoryoptiongroupsetusergroupaccesses
union all select usergroupaccessid from categoryoptiongroupusergroupaccesses
union all select usergroupaccessid from chartusergroupaccesses
union all select usergroupaccessid from constantusergroupaccesses
union all select usergroupaccessid from dashboardusergroupaccesses
union all select usergroupaccessid from dataapprovallevelusergroupaccesses
union all select usergroupaccessid from dataapprovalworkflowusergroupaccesses
union all select usergroupaccessid from dataelementcategoryoptionusergroupaccesses
union all select usergroupaccessid from dataelementcategoryusergroupaccesses
union all select usergroupaccessid from dataelementgroupsetusergroupaccesses
union all select usergroupaccessid from dataelementgroupusergroupaccesses
union all select usergroupaccessid from dataelementusergroupaccesses
union all select usergroupaccessid from datasetusergroupaccesses
union all select usergroupaccessid from documentusergroupaccesses
union all select usergroupaccessid from eventchartusergroupaccesses
union all select usergroupaccessid from eventreportusergroupaccesses
union all select usergroupaccessid from indicatorgroupsetusergroupaccesses
union all select usergroupaccessid from indicatorgroupusergroupaccesses
union all select usergroupaccessid from indicatorusergroupaccesses
union all select usergroupaccessid from interpretationusergroupaccesses
union all select usergroupaccessid from mapusergroupaccesses
union all select usergroupaccessid from optionsetusergroupaccesses
union all select usergroupaccessid from orgunitgroupsetusergroupaccesses
union all select usergroupaccessid from orgunitgroupusergroupaccesses
union all select usergroupaccessid from programindicatorusergroupaccesses
union all select usergroupaccessid from programusergroupaccesses
union all select usergroupaccessid from reporttableusergroupaccesses
union all select usergroupaccessid from reportusergroupaccesses
union all select usergroupaccessid from sqlviewusergroupaccesses
union all select usergroupaccessid from trackedentityattributeusergroupaccesses
union all select usergroupaccessid from usergroupusergroupaccesses
union all select usergroupaccessid from userroleusergroupaccesses
union all select usergroupaccessid from validationrulegroupusergroupaccesses);


-- VARIOUS

-- Identify missing sort_order entries in link tables
-- Replace 101 with the number of entries in the link table for one owner
-- Replace 102 with the identifier of the owner entity row
-- Replace categories_categoryoptions with the name of the link table

select generate_series 
from generate_series(1,101)
where not generate_series in (
  select sort_order
  from categories_categoryoptions
  where categoryid=102
);


