drop table if exists temp_px_gdp;

create table temp_px_gdp (
  day date,
  px_value decimal(10,2),
  gdp_value decimal(10,0)
);

insert into temp_px_gdp (day, px_value, gdp_value)
select px.day, px.value, gdp.value from px left outer join gdp on px.day = gdp.day;

update temp_px_gdp t
set t.gdp_value =
  (select gdp.value
  from gdp
  where gdp.value is not null
  and gdp.day < t.day
  order by gdp.day desc
  limit 1)
where t.gdp_value is null;