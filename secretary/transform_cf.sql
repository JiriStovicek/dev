DROP TABLE IF EXISTS out_cashflow_category_month;
DROP TABLE IF EXISTS out_cashflow_category_year;
DROP TABLE IF EXISTS out_balance_month;


CREATE TABLE out_cashflow_category_month
(
  year int,
  month int,
  cashflow bigint,
  revenues bigint,
  costs bigint,
  job bigint,
  passive bigint,
  rest bigint,
  needs bigint,
  wants bigint,
  savings bigint
);

CREATE TABLE out_cashflow_category_year
(
  year int,
  cashflow bigint,
  revenues bigint,
  costs bigint,
  job bigint,
  passive bigint,
  rest bigint,
  needs bigint,
  wants bigint,
  savings bigint
);

CREATE TABLE out_balance_month
(
  year int,
  month int,
  balance_bop bigint,
  cashflow bigint,
  balance_eop bigint
);


INSERT INTO out_cashflow_category_month (year, month, cashflow, revenues, costs, job, passive, rest, needs, wants, savings)

select cf.year, cf.month, cashflow, revenues, costs, ifnull(job,0), ifnull(passive,0), ifnull(rest,0), ifnull(needs,0), ifnull(wants,0), ifnull(savings,0)
from

  (select year, month, sum(amount) cashflow
  from v_transactions
  group by year, month) cf

left outer join

  (select year, month, sum(amount) revenues
  from v_transactions
  where type = 'Revenue'
  group by year, month) rev

on cf.year = rev.year and cf.month = rev.month

left outer join

  (select year, month, sum(amount) costs
  from v_transactions
  where type = 'Cost'
  group by year, month) cst

on cf.year = cst.year and cf.month = cst.month

left outer join

  (select year, month, sum(amount) job
  from v_transactions
  where category = 'Job'
  group by year, month) j

on cf.year = j.year and cf.month = j.month

left outer join

  (select year, month, sum(amount) passive
  from v_transactions
  where category = 'Passive'
  group by year, month) p

on cf.year = p.year and cf.month = p.month

left outer join

  (select year, month, sum(amount) rest
  from v_transactions
  where category = 'Rest'
  group by year, month) r

on cf.year = r.year and cf.month = r.month

left outer join

  (select year, month, sum(amount) needs
  from v_transactions
  where category = 'Needs'
  group by year, month) n

on cf.year = n.year and cf.month = n.month

left outer join

  (select year, month, sum(amount) wants
  from v_transactions
  where category = 'Wants'
  group by year, month) w

on cf.year = w.year and cf.month = w.month

left outer join

  (select year, month, sum(amount) savings
  from v_transactions
  where category = 'Savings'
  group by year, month) s

on cf.year = s.year and cf.month = s.month

order by year, month;



INSERT INTO out_cashflow_category_year (year, cashflow, revenues, costs, job, passive, rest, needs, wants, savings)

select year, sum(cashflow), sum(revenues), sum(costs), sum(job), sum(passive), sum(rest), sum(needs), sum(wants), sum(savings)
from out_cashflow_category_month
group by year



INSERT INTO out_balance_month (year, month, balance_bop, cashflow, balance_eop)

select year(t_date) year, month(t_date) month, balance_eop - cf balance_bop, cf cashflow, balance_eop from
(
select t.t_date, sum(t.amount) cf,

  (select balance from balance order by b_date desc limit 1)
  -
  (select ifnull(sum(r.amount),0) from
  transaction r
  where r.t_date < (select b_date from balance order by b_date desc limit 1) and r.t_date > t.t_date)
  balance_eop

from transaction t
where t.t_date < (select b_date from balance order by b_date desc limit 1)
group by t.t_date

union

select t.t_date, sum(t.amount) cf,

  (select balance from balance order by b_date desc limit 1)
  +
  (select sum(r.amount) from
  transaction r
  where r.t_date >= (select b_date from balance order by b_date desc limit 1) and r.t_date <= t.t_date)
  balance_eop

from transaction t
where t.t_date >= (select b_date from balance order by b_date desc limit 1)
group by t.t_date
) a
order by year, month;