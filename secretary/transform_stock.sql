DROP TABLE IF EXISTS dm_stock_analysis;


CREATE TABLE dm_stock_analysis
(
  b_date date,
  stock_id bigint,
  price decimal(10,2),

  ticker varchar(32),
  shares bigint,
  report_currency char(3),
  
  exchange_rate decimal(10,2),
  
  last_report_publish_date date,
  
  assets bigint,
  equity bigint,
  
  last_reported_quarter date,
  
  profit_last_4q bigint,
  revenue_last_4q bigint,
  
  profit_last_4q_czk bigint,
  revenue_last_4q_czk bigint,
  assets_czk bigint,
  equity_czk bigint,
  
  debt_czk bigint,
  debt_percent decimal(8,2),
  roe decimal(5,4),
  npm decimal(5,4),
  pe decimal(5,2),
  pb decimal(5,2),
  ps decimal(5,2),
  
  dividends_total_netto_czk bigint,
  change_percent decimal(5,2),
  change_percent_pa decimal(5,2),
  
  dy decimal(5,4)
);


-- load prices for each day and stock

INSERT INTO dm_stock_analysis (b_date, stock_id, price)

select b_date, stock_id, price
from st_price;


-- load ticker, emitted shares count and financial reports currency

UPDATE dm_stock_analysis a
left outer join stock s on a.stock_id = s.id
set a.ticker = s.ticker, a.shares = s.shares, a.report_currency = s.report_currency;

-- KOMB split 1:5 on 12th May 2016 - all historical dividends are already split on source, number of shares too
-- update price before the split
UPDATE dm_stock_analysis
set price = price / 5
where ticker = 'KOMB' and b_date <= "2016-05-11";


-- load exchange rates

UPDATE dm_stock_analysis a
left outer join exchange_rate e on a.b_date = e.b_date and a.report_currency = e.currency
set a.exchange_rate = e.price;


-- load last report publish date

UPDATE dm_stock_analysis a
set a.last_report_publish_date =
  (select r.report_date
  from st_report r
  where r.stock_id = a.stock_id and r.report_date <= a.b_date order by r.report_date desc limit 1);


-- load assets and equity in original report currency

UPDATE dm_stock_analysis a
left outer join st_report r on a.last_report_publish_date = r.report_date and r.stock_id = a.stock_id
set a.assets = r.assets, a.equity = r.equity;


-- create temporary table with income and profit split into quarters

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


-- load last reported quarter

UPDATE dm_stock_analysis a
set a.last_reported_quarter = (select max(q.quarter_date) from tmp_st_report_quarter_avg q where a.stock_id = q.stock_id and q.report_date = a.last_report_publish_date);

-- load profit and revenue in last 4 quarters, in original report currency

UPDATE dm_stock_analysis a
set a.profit_last_4q = (select sum(profit) from tmp_st_report_quarter_avg q where q.stock_id = a.stock_id and q.quarter_date <= a.last_reported_quarter and q.quarter_date > DATE_ADD(a.last_reported_quarter, INTERVAL -1 YEAR));

UPDATE dm_stock_analysis a
set a.revenue_last_4q = (select sum(income) from tmp_st_report_quarter_avg q where q.stock_id = a.stock_id and q.quarter_date <= a.last_reported_quarter and q.quarter_date > DATE_ADD(a.last_reported_quarter, INTERVAL -1 YEAR));

-- recalculate the assets, equity, revenue and profit to CZK based on exchange rate on each day

UPDATE dm_stock_analysis
set assets_czk = assets * exchange_rate, equity_czk = equity * exchange_rate, profit_last_4q_czk = profit_last_4q * exchange_rate, revenue_last_4q_czk = revenue_last_4q * exchange_rate;

-- calculate debt, percentual indebtedness, ROE, NPM, P/E, P/B, P/S

UPDATE dm_stock_analysis
set debt_czk = assets_czk - equity_czk, debt_percent = (assets_czk - equity_czk) / equity_czk, roe = profit_last_4q / equity, npm = profit_last_4q / revenue_last_4q, pe = price / (profit_last_4q_czk / shares), pb = price / (equity_czk / shares), ps = price / (revenue_last_4q_czk / shares);

-- load all dividends received from each b_date to today

UPDATE dm_stock_analysis a
set a.dividends_total_netto_czk = IFNULL((select sum(d.dividend_netto_czk) from st_dividends d where a.stock_id = d.stock_id and d.record_day between a.b_date and CURDATE()), 0);

-- calculate balance from each b_date to today (counting capital change and dividends)

UPDATE dm_stock_analysis a
set a.change_percent = (((select p.price from st_price p where a.stock_id = p.stock_id order by b_date desc limit 1) + a.dividends_total_netto_czk) / a.price) - 1;

-- calculate balance per year

UPDATE dm_stock_analysis
set change_percent_pa = change_percent / (YEAR(CURDATE()) - YEAR(b_date) + 1);

-- calculate dy (dividend yield) based on assumption the dividend is known from Jan 1 each year

UPDATE dm_stock_analysis a
set a.dy = (select sum(d.dividend_netto_czk) from st_dividends d where d.stock_id = a.stock_id and year(record_day) = year(a.b_date)) / a.price;


-- create table with P/E * P/B analysis

DROP TABLE IF EXISTS out_stock_analysis_pe_pb;


CREATE TABLE out_stock_analysis_pe_pb
(
  ticker varchar(32),
  buy_when_under decimal(5,2),
  current decimal(5,2),
  sell_when_over decimal(5,2),
  ratio decimal (5,2)
);


INSERT INTO out_stock_analysis_pe_pb (ticker, buy_when_under, current, sell_when_over)
select a.ticker, TRUNCATE(c.buy_when_pe_pb_under,2) buy_when_under, TRUNCATE(a.current_pe_pb,2) current, TRUNCATE(s.sell_when_pe_pb_over,2) sell_when_over
from
(
  select ticker, ln(dy/(pe*pb)) current_pe_pb
  from dm_stock_analysis
  where b_date = (select max(b_date) from dm_stock_analysis)
  group by ticker
) a
join
(
  select ticker, min(ln(dy/(pe*pb))) buy_when_pe_pb_under
  from dm_stock_analysis
  where ln(dy/(pe*pb)) is not null and change_percent_pa <= 0.2
  group by ticker
) c on a.ticker = c.ticker
join
(
  select ticker, max(ln(dy/(pe*pb))) sell_when_pe_pb_over
  from dm_stock_analysis
  where ln(dy/(pe*pb)) is not null and change_percent_pa >= 0.0
  group by ticker
) s on a.ticker = s.ticker;

-- calculate ratio between buy and sell recommendations (1 = buy, -1 = sell)
UPDATE out_stock_analysis_pe_pb
set ratio = (2 * (buy_when_under - current) / (sell_when_over - buy_when_under)) + 1;