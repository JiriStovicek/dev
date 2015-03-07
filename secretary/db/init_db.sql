--create user 'jirka'@'localhost' identified by '1q2w3e'

--create database secretary;

--GRANT ALL PRIVILEGES ON secretary.* TO 'jirka'@'localhost' WITH GRANT OPTION;


DROP TABLE IF EXISTS `transaction`;
DROP TABLE IF EXISTS `tr_account`;
DROP TABLE IF EXISTS `tr_category`;
DROP TABLE IF EXISTS `tr_type`;


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
  id bigint not null auto_increment,
  amount bigint not null,
  account_id bigint not null,
  note varchar(32),
  t_date date,

  primary key(id),
  foreign key(account_id) references tr_account(id)
);


insert into tr_type(id,name) values (1,'Revenue'),(2,'Cost');

insert into tr_category(id,name,type_id) values (1,'Job',1),(2,'Passive',1),(3,'Rest',1),(4,'Needs',2),(5,'Savings',2),(6,'Wants',2);




CREATE TABLE stage_transaction
(
  amount bigint,
  account varchar(32),
  account_id bigint,
  type varchar(32),
  type_id bigint,
  note varchar(32),
  t_date date
);