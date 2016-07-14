DROP TABLE IF EXISTS out_stock_analysis;


CREATE TABLE out_stock_analysis
(
  b_date date,
  stock_id bigint,
  price decimal(10,2),

  ticker varchar(32),
  shares bigint,
  profit_last_4q_czk bigint,
  revenue_last_4q_czk bigint,
  assets_czk bigint,
  equity_czk bigint,
  
  debt_czk bigint,

  roe decimal(5,2),
  npm decimal(5,2),
  pe decimal(5,2),
  pb decimal(5,2),
  ps decimal(5,2),
  debt_percent decimal(8,2),
  dy decimal(5,2),
  
  dividends_total bigint,
  balance_percent decimal(5,2),
  
  assets bigint,
  equity bigint,
  profit_last_4q bigint,
  revenue_last_4q bigint,
  report_currency char(3),
  exchange_rate decimal(10,2)
);


-- load prices for each day and stock

INSERT INTO out_stock_analysis (b_date, stock_id, price)

select b_date, stock_id, price
from st_price;


-- load ticker, emitted shares count and financial reports currency

UPDATE out_stock_analysis a
left outer join stock s on a.stock_id = s.id
set a.ticker = s.ticker, a.shares = s.shares, a.report_currency = s.report_currency

-- update number of shares before KOMB split 1:5 on 12th May 2016

UPDATE out_stock_analysis
set shares = shares / 5
where ticker = 'KOMB' and b_date <= "2016-05-11";


-- load exchange rates

UPDATE out_stock_analysis a
left outer join exchange_rate e on a.b_date = e.b_date and a.report_currency = e.currency
set a.exchange_rate = e.price;


-- load assets and equity in original report currency

UPDATE out_stock_analysis a
join st_report r on a.stock_id = r.stock_id and r.report_date = (select i.report_date from st_report i where i.stock_id = a.stock_id and i.report_date <= a.b_date limit 1)
set a.assets = r.assets, a.equity = r.equity;


-- load profit and revenue in last 4 quarters, in original report currency

---- create temporary table with income and profit split into quarters

DROP TABLE IF EXISTS tmp_st_report_quarter_avg;

CREATE TABLE tmp_st_report_quarter_avg
(
  stock_id bigint,
  report_date date,
  quarter_date date,
  income bigint,
  profit bigint
);

INSERT INTO tmp_st_report_quarter_avg (stock_id, report_date, income, profit, quarter_date)
select r.stock_id, r.report_date, income / (4/r.periods_per_year) split_income, profit / (4/r.periods_per_year) split_profit, date_add(makedate(period_year, 1), interval (((4/r.periods_per_year) * (r.period_number - 1)) + quarters.q - 1) quarter) quarter_date
  from st_report r
join
  (select 1 q union select 2 union select 3 union select 4) quarters
  on quarters.q <= (4 / r.periods_per_year);