#Declearing Variable
SET @var1 := NULL;
SET @var1 = CURRENT_DATE - INTERVAL 1 DAY;


#Creating LCP Repayment Analysis Table.
DROP TABLE `LCP_Repayment_Analysis`;

CREATE TABLE `LCP_Repayment_Analysis` AS 

SELECT a.`contract`, `contract_id`, `system_id`, `current_lcp`, device_type, product_name, `customer_name`, `created_date`, `local_government`, `billing_state`, `current_tm`, `last_payment_date`, `ref_activation_end`,
CASE WHEN device_type = 'PRIME' AND ltoperiod = 24 THEN 12500
WHEN device_type = 'PRIME' AND ltoperiod = 28 THEN 12500
WHEN device_type = 'ECO' AND ltoperiod = 24 THEN 9500
WHEN device_type = 'ECO' AND ltoperiod = 28 THEN 9000
WHEN device_type = 'PRIME' AND ltoperiod = 12 THEN 16750
WHEN device_type = 'ECO' AND ltoperiod = 12 THEN 12000 END monthly_repayment_amount, `charged_amount`, `payment_type`, `payment_duration`, `payment_channel`, `payment_classification`,`transaction_date`, `activation_start`, `activation_end`,
CASE WHEN a.`contract` = c.`contract` AND `activation_end` > (CURRENT_DATE) THEN 'Paid' ELSE 'Defaulter' END Payment_Status, `outage_days`
FROM (
(SELECT a.`contract`, `contract_id`, `system_id`, `ltoperiod`,`current_lcp`, `customer_name`, a.product_name,`created_date`, `local_government`, `billing_state`, `current_tm`, `last_payment_date`, `ref_activation_end`,
CASE WHEN SUBSTR(a.product_name, 1,5) = 'PRIME' THEN 'PRIME' ELSE 'ECO' END device_type
FROM `lcp_base_use` a
JOIN `activity_log` b
WHERE a.`contract` = b.`contract`
AND a.`product_name` NOT LIKE '%OUTRIGHT%'
AND b.`ref_activation_end` <= @var1
AND b.`month_date` = 'Apr-23'
AND a.`contract` NOT IN (SELECT `contract`
				FROM `transfers`)
) a

LEFT OUTER JOIN

(SELECT `contract`, `outage_days` FROM `activity`) b
ON a.`contract` = b.`contract`

LEFT OUTER JOIN

(SELECT `contract`, SUM(`charged_amount`) `charged_amount`, `payment_type`, SUM(`payment_duration`) `payment_duration`, `payment_channel`, `payment_classification`,
MAX(`transaction_date`)`transaction_date`, MAX(`activation_start`)`activation_start` , MAX(`activation_end`) `activation_end`
FROM `daily_transactions_curr_MTD`
GROUP BY `contract`,`payment_type`,`payment_duration`,`payment_channel`,`payment_classification`
) c
ON a.`contract` = c.`contract`
	)
	


-- Checking the Created Table --
SELECT *
FROM `LCP_Repayment_Analysis`



-- Dafaulter and Retrievals Analysis --
	
SELECT *, CASE WHEN outage_days < 0 AND outage_days >= -5 THEN 'Late_Payments' 
		WHEN outage_days < -5 AND outage_days >= -30 THEN 'Retrieval'
		WHEN outage_days < -30 AND outage_days >= -45 THEN 'Late_Retrieval'
		WHEN outage_days < -45 THEN 'Pending_Rev' ELSE 'Check' END defaulters_segment,
#coalesce(activation_end, ref_activation_end) + interval abs(outage_days) day as calculate_start_date,
TIMESTAMPDIFF(MONTH, (COALESCE(activation_end, ref_activation_end)),(CURRENT_DATE - INTERVAL 1 DAY))+1 owed_month,
CASE WHEN outage_days < -45 THEN (TIMESTAMPDIFF(MONTH, (COALESCE(activation_end, ref_activation_end)),(CURRENT_DATE - INTERVAL 1 DAY))+1) * monthly_repayment_amount
	ELSE 0 END pending_tetrieval_rev
FROM `LCP_Repayment_Analysis`
WHERE Payment_Status = 'Defaulter';


 
 -- Contracts on Transfer --
 
SELECT *, TIMESTAMPDIFF(MONTH, ref_activation_end,(CURRENT_DATE - INTERVAL 1 DAY))+1 owed_month,
CASE WHEN outage_days < -45 THEN (TIMESTAMPDIFF(MONTH, ref_activation_end,(CURRENT_DATE - INTERVAL 1 DAY))+1) * monthly_repayment_amount
	ELSE 0 END pending_tetrieval_rev
FROM (
SELECT *,
CASE WHEN SUBSTR(product_name, 1,5) = 'PRIME' AND ltoperiod = 24 THEN 12500
	WHEN SUBSTR(product_name, 1,5) = 'PRIME' AND ltoperiod = 28 THEN 12500
	WHEN SUBSTR(product_name, 1,5) = 'PRIME' AND ltoperiod = 12 THEN 16750
	WHEN SUBSTR(product_name, 1,3) = 'ECO' AND ltoperiod = 24 THEN 9500
	WHEN SUBSTR(product_name, 1,3) = 'ECO' AND ltoperiod = 28 THEN 9000
	WHEN SUBSTR(product_name, 1,3) = 'ECO' AND ltoperiod = 12 THEN 12000 END monthly_repayment_amount
FROM (
SELECT a.`contract`, a.`contract_id`, b.`current_lcp`, b.`current_tm`, b.`billing_state`, b.`product_name`, a.`retrieval_date`,
c.`ltoperiod`, c.`paidperiod`, c.`outage_days`, c.`last_payment_date`, c.`ref_activation_end`, c.`customer_status`
FROM `transfers` a

LEFT JOIN

`lcp_base_use` b
ON a.`contract` = b.`contract`

LEFT JOIN

`activity` c
ON b.`contract` = c.`contract`
	) d
)e;



-- Ad_hoc Analysis

SELECT *, CASE
		WHEN prev_paidperiod >= expected_paidperiod THEN TIMESTAMPDIFF(DAY, COALESCE(previous_payment_date, min_payment_date), exp_payment_date)
		ELSE TIMESTAMPDIFF(DAY, COALESCE(min_payment_date, last_payment_date), exp_payment_date) END AS gap
FROM (

SELECT a.*, ADDDATE(entry_date, (FLOOR(TIMESTAMPDIFF(DAY, entry_date, '2023-07-23')/30)*30)) AS exp_payment_date,
ADDDATE(entry_date, ((FLOOR((TIMESTAMPDIFF(DAY, entry_date, '2023-07-23'))/30)+1)*30)) AS next_exp_payment_date,
`ltoperiod`, `total_days_activated`,`days_deficit`,  prev_paidperiod, previous_payment_date, current_paidperiod, min_payment_date, last_payment_date,
 last_status_update, next_status_update, `total_charged_amount`, `payment_count`
FROM (
(SELECT DISTINCT `contract_number`,`client_number`, created_date entry_date, CONCAT(`tm_first_name`,' ',`tm_last_name`) AS `tm_name`, CONCAT(`agent_first_name`,' ',`agent_last_name`) AS lcp_name, CONCAT(`first_name`,' ',`last_name`) AS customer_name, 
`monthly_payment`, DAY(created_date) created_day, FLOOR((TIMESTAMPDIFF(DAY, created_date, '2023-07-23'))/30)+1 AS expected_paidperiod, `customer_state`, `customer_district`, `agent_district`
FROM `upya_lcp_base`
#WHERE `tenure` != 'Outright plan'
WHERE created_date <= '2023-06-23'
AND DAY(created_date) <= 23) a

LEFT OUTER JOIN

(SELECT `contract_number`, `paidperiod` prev_paidperiod
FROM `upya_activity_log`
WHERE `report_date` = '2023-06-30') b
ON a.`contract_number` = b.`contract_number`

LEFT OUTER JOIN

(SELECT `contract_number`, `ltoperiod`, `paidperiod` current_paidperiod, `total_days_activated`, DATE(`last_status_update`) last_status_update, DATE(`next_status_update`) next_status_update, `days_deficit`
FROM `upya_activity_log`
WHERE `report_date` = '2023-07-23') c
ON a.`contract_number` = c.`contract_number`

LEFT OUTER JOIN

(SELECT `contract_number`, MAX(CASE WHEN `report_date` <= '2023-06-30' THEN DATE(`payment_date`) END) previous_payment_date, MAX(CASE WHEN `report_date` <= '2023-07-23' THEN DATE(`payment_date`) END) last_payment_date,
MIN(CASE WHEN `report_date` = '2023-07-23' THEN DATE(`payment_date`) END) min_payment_date, SUM(CASE WHEN `report_date` = '2023-07-23' THEN `amount` END) `total_charged_amount`,
COUNT(CASE WHEN `report_date` = '2023-07-23' THEN `contract_number` END) `payment_count`
FROM `upya_daily_transactions`
WHERE `contract_number` IN (SELECT `contract_number` FROM `upya_lcp_base` WHERE created_date <= '2023-06-23' AND DAY(created_date) <= 23)
GROUP BY `contract_number`, `created_date`) d
ON a.`contract_number` = d.`contract_number`
     )
   ) e
