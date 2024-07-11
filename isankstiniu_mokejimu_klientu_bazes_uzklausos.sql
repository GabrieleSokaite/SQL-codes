/* 1) Query by which you could extract active clients at the 2013-06-19. */
SELECT account_id, activation_date, deletion_date
FROM sandbox_activations
WHERE DATE(activation_date) <= '2013-06-19'
	AND (DATE(deletion_date) > '2013-06-19');


/* 2) How many clients were activated and deactivated during June of 2013. Please provide
both numbers as a result of one query. */
select 
	SUM(CASE when activation_date BETWEEN '2013-06-01' and '2013-06-30' Then 1 else 0 end) as activated_june,
    SUM(CASE when deletion_date BETWEEN '2013-06-01' and '2013-06-30' Then 1 else 0 end) as deactivated_june
from sandbox_activations;


/*3) How many active clients had more than one SIM card on 2013-06-19. Unique client
could be identified by using unique device information (prepaid customers are usually not
identified in the systems).*/
select count(DISTINCT imei_a) as clients_with_multiple_sim_cards
from (
  SELECT imei_a
  from sandbox_activations
  where activation_date <= '2013-06-19'
  	and (deletion_date > '2013-06-19')
  group by imei_a
  having count(DISTINCT account_id) > 1
) as active_clients_with_multiple_sims;


/* 4) Select currently active clients and pick up TOP5 device brands by each phone type.
Please provide the result in one single query. */
with ActiveClients as (
  SELECT *
  FROM sandbox_activations
  WHERE status = 'ACTIVE'
  ), CountBrands as (
    select device_type, device_brand, 
    count(*) as brand_count,
    ROW_NUMBER() OVER (PARTITION BY device_type ORDER BY COUNT(*) DESC) as rank
    from ActiveClients
    group by device_type, device_brand
    )
    select device_type, device_brand, brand_count
    from CountBrands
    where rank < 6
    order by device_type, device_brand DESC;
    
    
/* 5) Request is to provide a new column for currently active clients. New column should have
the value of IMEI if the client is the first who used this IMEI (you can check by the client
activation date). If the client is not the first one, then column value should be 'Multi SIM'. */
select *,
	case 
    	when ROW_NUMBER() OVER(PARTITION BY imei_a order by activation_date) = 1 then imei_a
        else 'Multi SIM'
    end as imei_status
from sandbox_activations
where status = 'ACTIVE';


/* 6) Rebuild the table into an IMEI history query where you could track the history of the
reuse of the device. This table/query should have the columns:
-- imei
-- msisdn
-- device_brand
-- device_model
-- imei_eff_dt - the date when msisdn is used with the IMEI
-- imei_end_dt - the date when new other msisdn reused the phone.*/
with IMEI_history as (
	select imei_a as imei, msisdn, device_brand, device_model, activation_date as imei_eff_dt,
    	LEAD(activation_date, 1, NULL) OVER (PARTITION BY imei_a ORDER BY activation_date) as imei_end_dt
    from sandbox_activations
    where status = 'ACTIVE'
    )
    select imei, msisdn, device_brand, device_model, imei_eff_dt, imei_end_dt
    from IMEI_history;
 