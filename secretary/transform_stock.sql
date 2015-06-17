DROP TABLE IF EXISTS out_stock_analysis_day;


CREATE TABLE out_stock_analysis_day
(
  price decimal(8,2),
  b_date date,
  ticker varchar(256),
  shares bigint,
  assets bigint,
  equity bigint,
  income bigint,
  profit bigint,
  dividend_netto_czk decimal(8,2),
  dividend_yearly decimal(8,2)
);


INSERT INTO out_stock_analysis_day (price, b_date, ticker, shares, assets, equity, income, profit, dividend_netto_czk, dividend_yearly)


select p.price, p.b_date, s.ticker, s.shares, r.assets, r.equity, r.income, r.profit, d.dividend_netto_czk, dy.dividend_yearly
from st_price p
join stock s on p.stock_id = s.id
left outer join st_report r on r.stock_id = p.stock_id and r.report_date = (select r2.report_date from st_report r2 where p.stock_id = r2.stock_id and r2.report_date < p.b_date order by r2.report_date desc limit 1)
left outer join st_dividends d on p.stock_id = d.stock_id and p.b_date = (select p2.b_date from st_price p2 where p2.stock_id = p.stock_id and p2.b_date >= d.record_day order by p2.b_date asc limit 1)

left outer join (select stock_id, year(record_day) y, sum(dividend_netto_czk) dividend_yearly from st_dividends group by stock_id, year(record_day)) dy on p.stock_id = dy.stock_id and year(p.b_date) = dy.y

where report_date is not null
order by ticker, p.b_date;