DROP TABLE IF EXISTS out_portfolio;


CREATE TABLE out_portfolio
(
  asset varchar(256),
  value bigint
);


INSERT INTO out_portfolio (asset, value)

select 'cash', last_balance + cf as value
from (
  select balance as last_balance
  from balance cash
  where b_date = (select max(b_date) from balance)
) last_balance,
(
  select sum(amount) cf
  from transaction
  where version_id = 1 and t_date >= (select max(b_date) from balance)
) cf

union

select ticker, quantity * price value
from
(
  select s.ticker ticker, sum(t.quantity) quantity, p.price price
  from st_trades t
  join stock s on t.stock_id = s.id
  join st_price p on t.stock_id = p.stock_id
  where t.sell_date is null and p.b_date = (select max(b_date) from st_price)
  group by t.stock_id
) x;