--create user 'jirka'@'localhost' identified by '1q2w3e'
--create database secretary;
--GRANT ALL PRIVILEGES ON secretary.* TO 'jirka'@'localhost' WITH GRANT OPTION;


-- CASH FLOW

DROP VIEW IF EXISTS `v_transactions`;
DROP TABLE IF EXISTS `transaction`;
DROP TABLE IF EXISTS `tr_version`;
DROP TABLE IF EXISTS `tr_account`;
DROP TABLE IF EXISTS `tr_category`;
DROP TABLE IF EXISTS `tr_type`;

CREATE TABLE tr_version
(
  id bigint not null,
  name varchar(32) not null,

  primary key(id)
);

CREATE TABLE tr_type
(
  id bigint not null,
  name varchar(32) not null,

  primary key(id)
);

CREATE TABLE tr_category
(
  id bigint not null,
  name varchar(32) not null,
  type_id bigint not null,

  primary key(id),
  foreign key(type_id) references tr_type(id)
);

CREATE TABLE tr_account
(
  id bigint not null auto_increment,
  name varchar(32) not null,
  category_id bigint not null,

  primary key(id),
  foreign key(category_id) references tr_category(id)
);

CREATE TABLE transaction
(
  id varchar(16),
  amount bigint not null,
  account_id bigint not null,
  note varchar(256) charset cp1250 collate cp1250_general_ci,
  t_date date,
  version_id bigint not null,

  primary key(id),
  foreign key(account_id) references tr_account(id)
  foreign key(version_id) references tr_version(id)
);


insert into tr_version(id,name) values (1,'Reality'),(2,'Forecast');

insert into tr_type(id,name) values (1,'Revenue'),(2,'Cost');

insert into tr_category(id,name,type_id) values (1,'Job',1),(2,'Passive',1),(3,'Rest',1),(4,'Needs',2),(5,'Savings',2),(6,'Wants',2);


CREATE VIEW v_transactions
AS
select year(t.t_date) year, month(t.t_date) month, typ.name type, c.name category, a.name account, t.amount amount, t.note note, v.name version
from transaction t
join tr_version v on t.version_id = v.id
join tr_account a on t.account_id = a.id
join tr_category c on a.category_id = c.id
join tr_type typ on c.type_id = typ.id;


CREATE VIEW v_forecast
AS
select year, month, type, category, account, amount, note, version
from v_transactions
where (version = "Reality" and year < year(curdate()) or month < month(curdate()) )
  or (version = "Forecast" and year = year(curdate()) and month >= month(curdate()))


-- BALANCE

DROP TABLE IF EXISTS balance;

CREATE TABLE balance
(
  b_date date,
  balance bigint not null
);


-- STOCKS

DROP TABLE IF EXISTS st_price;
DROP TABLE IF EXISTS st_report;
DROP TABLE IF EXISTS st_dividends;
DROP TABLE IF EXISTS st_trades;
DROP TABLE IF EXISTS stock;

CREATE TABLE stock
(
  id bigint not null auto_increment,
  ticker varchar(32) not null,
  shares bigint,
  report_currency char(3),
  
  primary key(id)
);

CREATE TABLE st_trades
(
  stock_id bigint not null,
  quantity int not null,
  
  buy_date date not null,
  buy_price decimal(8,2) not null,
  buy_charge decimal(8,2) not null,
  
  sell_date date,
  sell_price decimal(8,2),
  sell_charge decimal(8,2),
  
  foreign key(stock_id) references stock(id)
);

CREATE TABLE st_dividends
(
  stock_id bigint not null,
  record_day date not null,
  dividend_brutto decimal(8,2) not null,
  exchange_rate decimal(8,2),
  tax_rate decimal(4,2) not null,
  dividend_netto_czk decimal(8,2) not null,
  
  foreign key(stock_id) references stock(id)
);

CREATE TABLE st_report
(
  stock_id bigint not null,
  report_date date not null,
  periods_per_year smallint not null,
  period_number smallint not null,
  
  assets bigint not null,
  equity bigint not null,
  income bigint not null,
  profit bigint not null,
  
  foreign key(stock_id) references stock(id)
);

CREATE TABLE st_price
(
  stock_id bigint not null,
  price bigint not null,  
  b_date date,
  
  foreign key(stock_id) references stock(id)
);