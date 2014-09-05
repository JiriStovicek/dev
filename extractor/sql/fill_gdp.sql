drop table if exists temp;

create table temp (
  day date,
  px_value decimal(10,2),
  gdp_value decimal(10,0)
);

insert into temp (day, px_value, gdp_value)
select px.day, px.value, gdp.value from px left outer join gdp on px.day = gdp.day;

update temp t
set t.gdp_value =
  (select gdp.value
  from gdp
  where gdp.value is not null
  and gdp.day < t.day
  order by gdp.day desc
  limit 1)
where t.gdp_value is null;

