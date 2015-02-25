create user 'jirka'@'localhost' identified by '1q2w3e'

create database invest;

GRANT ALL PRIVILEGES ON invest.* TO 'jirka'@'localhost' WITH GRANT OPTION;


DROP TABLE IF EXISTS `px`;

CREATE TABLE px
(
  day date,
  value decimal(10,2),

  primary key(day)
);


DROP TABLE IF EXISTS `gdp`;

CREATE TABLE gdp
(
  day date,
  value decimal(10,0),

  primary key(day)
);


DROP TABLE IF EXISTS `stocks`;

CREATE TABLE stocks
(
  day date,
  ticker varchar(12),
  price decimal(10,2),

  primary key(day, ticker)
);




delimiter //

drop procedure if exists fill_temp_px_gdp//

CREATE PROCEDURE fill_temp_px_gdp()
BEGIN

# table of px values with projected gdp values
drop table if exists temp_px_gdp;

create table temp_px_gdp (
  day date,
  px_value decimal(10,2),
  gdp_value decimal(10,0),
  px_gdp decimal(5,0)
);

insert into temp_px_gdp (day, px_value, gdp_value)
select px.day, px.value, gdp.value from px left outer join gdp on px.day = gdp.day;

update temp_px_gdp t
  set t.gdp_value =
  (select gdp.value
  from gdp
    where gdp.value is not null and gdp.day < t.day
    order by gdp.day desc
    limit 1)
  where t.gdp_value is null;

delete from temp_px_gdp
  where gdp_value is null;
  
update temp_px_gdp
  set px_gdp = round( round( (px_value * 1000) / gdp_value , 2 ) * 100 );


# frequency table of px/gdp ratios
drop table if exists temp_px_gdp_frequency;

create table temp_px_gdp_frequency (
  px_gdp decimal(5,0),
  frequency decimal(8,4)
);

insert into temp_px_gdp_frequency(frequency, px_gdp)
  select (count(day) / (select count(*) from temp_px_gdp)) * 100 frequency, px_gdp
  from temp_px_gdp
  group by px_gdp;

END//



drop function if exists get_curr_px_gdp//

CREATE FUNCTION get_curr_px_gdp()
RETURNS decimal
BEGIN

DECLARE curr DECIMAL(5,0);
SET curr = 0;

select round( px_value * 100000 / gdp_value ) into curr
  from temp_px_gdp
  order by day desc
  limit 1;
 
RETURN curr;

END//

delimiter ;