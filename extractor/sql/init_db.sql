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
