-- use CSE course database by Chris Miller

-- mysql -N -L > dump_reqdesc.sql

with catalog as (
select
case primarysubject
WHEN 'CS' THEN 'CSE'
ELSE primarysubject
END as primarysubject,
primarycatalognumber,
rqrmnt_group_long_description,
effectivedate,
coursetitlelong
from ps_rpt.ps_course_catalog_v
where primarycatalognumber < '500' -- undergraduate only
),
latest_catalog as (
select catalog.*
from catalog, (
    select primarysubject, primarycatalognumber, max(effectivedate) as maxed
    from catalog
    group by primarysubject, primarycatalognumber
) A
where effectivedate = maxed and catalog.primarysubject = A.primarysubject
and catalog.primarycatalognumber = A.primarycatalognumber
),
coursereq as (
select json_object(
    'sub', primarysubject,
    'catalognumber', primarycatalognumber,
    'req', coalesce(rqrmnt_group_long_description, ''),
    'eff', effectivedate,
    'title', coursetitlelong) as cinfo
from latest_catalog)
select json_arrayagg(cinfo)
from coursereq;
