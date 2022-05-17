-- 1) What is the average AQI (air quality index) by year by season (winter, spring, summer, fall)?

with date_to_season as (
	select *,
		case
			when extract(month from date) in (12,1,2) then 'Winter'
			when extract(month from date) in (3,4,5) then 'Spring'
			when extract(month from date) in (6,7,8) then 'Summer'
			when extract(month from date) in (9,10,11) then 'Fall'
		end as season
	from aqi_total
	)
select extract(year from date)::varchar as year, season, round(avg(aqi),2) as avg_aqi
from date_to_season
group by year, season
order by year
;

-- 2) What were the top 10 locations with worst AQI in each year?

(select extract(year from date)::varchar as year, concat(county_name,',',' ',state_name) as location, round(avg(aqi),2) as avg_aqi
from aqi_2001
group by year, location
order by avg_aqi desc
limit 10)
union all
(select extract(year from date)::varchar as year, concat(county_name,',',' ',state_name) as location, round(avg(aqi),2) as avg_aqi
from aqi_2011
group by year, location
order by avg_aqi desc
limit 10)
union all
(select extract(year from date)::varchar as year, concat(county_name,',',' ',state_name) as location, round(avg(aqi),2) as avg_aqi
from aqi_2021
group by year, location
order by avg_aqi desc
limit 10)
;

-- 3) What were the top 10 locations that had the best improvement over 20 years, from the first year to the most recent year?

with
aqi_2001 as
	(select concat(a.county_name,',',' ',a.state_name) as location_2001, round(avg(a.aqi),2) as avg_aqi_2001
	from aqi_2001 a
	group by concat(a.county_name,',',' ',a.state_name)
	order by location_2001
	),
aqi_2021 as
	(select concat(county_name,',',' ',state_name) as location_2021, round(avg(a.aqi),2) as avg_aqi_2021
	from aqi_2021 a
	group by concat(county_name,',',' ',state_name)
	order by location_2021),
aqi_all as
	(select *
	from aqi_2001 ah
	inner join aqi_2021 al on ah.location_2001 = al.location_2021)
select location_2001 as location, (avg_aqi_2001-avg_aqi_2021) as best_improvement
from aqi_all
order by best_improvement desc
limit 10
;

-- What were the 10 locations with the worst decline over 20 years?

with
aqi_2001 as
	(select concat(a.county_name,',',' ',a.state_name) as location_2001, round(avg(a.aqi),2) as avg_aqi_2001
	from aqi_2001 a
	group by concat(a.county_name,',',' ',a.state_name)
	order by location_2001
	),
aqi_2021 as
	(select concat(county_name,',',' ',state_name) as location_2021, round(avg(a.aqi),2) as avg_aqi_2021
	from aqi_2021 a
	group by concat(county_name,',',' ',state_name)
	order by location_2021),
aqi_all as
	(select *
	from aqi_2001 ah
	inner join aqi_2021 al on ah.location_2001 = al.location_2021)
select location_2001 as location, (avg_aqi_2001-avg_aqi_2021) as worst_improvement
from aqi_all
order by worst_improvement
limit 10
;

-- 4) In Utah counties, how many days of "Unhealthy" air did we have in each year?

-- When AQI values are above 100, air quality is considered to be unhealthy

-- Days of "unhealthy" air between 2001 and 2021
select state_name, count(aqi) as days_with_unhealthy_aqi
from aqi_total at2
where aqi > 100 and state_name = 'Utah'
group by state_name
;

-- Days of "unhealthy" air between 2001 and 2021, grouped by year
select extract(year from date) as year, count(aqi) as days_with_unhealthy_aqi
from aqi_total at2
where aqi > 100 and state_name = 'Utah'
group by year
;

-- Days of "unhealthy" air between 2001 and 2021, grouped by county
select county_name, count(aqi) as days_with_unhealthy_aqi
from aqi_total at2
where aqi > 100 and state_name = 'Utah'
group by county_name
order by days_with_unhealthy_aqi desc
;

-- Days of "unhealthy" air in 2001, grouped by county
select county_name, count(aqi) as days_with_unhealthy_aqi
from aqi_2001 a
where aqi > 100 and state_name = 'Utah'
group by county_name
order by days_with_unhealthy_aqi desc
;

-- Days of "unhealthy" air in 2011, grouped by county
select county_name, count(aqi) as days_with_unhealthy_aqi
from aqi_2011 a
where aqi > 100 and state_name = 'Utah'
group by county_name
order by days_with_unhealthy_aqi desc
;

-- Days of "unhealthy" air in 2021, grouped by county
select county_name, count(aqi) as days_with_unhealthy_aqi
from aqi_2021 a
where aqi > 100 and state_name = 'Utah'
group by county_name
order by days_with_unhealthy_aqi desc
;

-- Is it improving?

-- Percentage change in average aqi between 2001 and 2021
with
aqi_2001 as (
	select state_name, avg(aqi) as utah_avg_aqi_in_2001
	from aqi_2001
	where state_name = 'Utah'
	group by state_name),
aqi_2021 as (
	select state_name, avg(aqi) as utah_avg_aqi_in_2021
	from aqi_2021
	where state_name = 'Utah'
	group by state_name)
select round(((utah_avg_aqi_in_2001-utah_avg_aqi_in_2021)/utah_avg_aqi_in_2001)*100,2) as percentage_change_in_aqi
from aqi_2001 a
inner join aqi_2021 a2 on a.state_name = a2.state_name
;

-- Percentage change in average aqi between 2001 and 2021, by county
-- *we inner join because we can't even calculate change if county is not found in both tables*

with
aqi_2001 as (
	select county_name, avg(aqi) as utah_avg_aqi_in_2001
	from aqi_2001
	where state_name = 'Utah'
	group by county_name
	order by county_name),
aqi_2021 as (
	select county_name, avg(aqi) as utah_avg_aqi_in_2021
	from aqi_2021
	where state_name = 'Utah'
	group by county_name
	order by county_name)
select a.county_name, round(((utah_avg_aqi_in_2001-utah_avg_aqi_in_2021)/utah_avg_aqi_in_2001)*100,2) as percentage_change_in_aqi
from aqi_2001 a
inner join aqi_2021 a2 on a.county_name = a2.county_name
;

-- 5) In Salt Lake County, which months have the most "Unhealthy" days?

select
	extract(month from date) as month,
	count(aqi)
from aqi_total at2
where county_name = 'Salt Lake' and aqi > 100
group by month
order by count desc
;

-- Has that changed in 20 years?

with
unhealthy_days_by_month_2001 as
	(select
		extract(year from date)::varchar as year,
		extract(month from date) as month,
		sum(case
			when aqi > 100 then 1
			else 0
		end) as count_aqi_2001
	from aqi_2001 a
	where county_name = 'Salt Lake'
	group by year, month
	order by month),
unhealthy_days_by_month_2021 as
	(select
		extract(year from date)::varchar as year,
		extract(month from date) as month,
		sum(case
			when aqi > 100 then 1
			else 0
		end) as count_aqi_2021
	from aqi_2021 a
	where county_name = 'Salt Lake'
	group by year, month
	order by month)
select a.year, a.month, count_aqi_2001, a2.year, a2.month, count_aqi_2021, coalesce(a2.count_aqi_2021,0)-a.count_aqi_2001 as difference
from unhealthy_days_by_month_2001 a
inner join unhealthy_days_by_month_2021 a2 on a.month = a2.month
;
