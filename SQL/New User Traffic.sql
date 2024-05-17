/*
Purpose: This project seeks to know movements of customers making use of business preferred payment channels for the first time
in 6 Months.

*/

-- Generating the New User Analysis Report --
SELECT a.*,`generation`, `Required_Status`

FROM 
(
SELECT *, CASE
		WHEN Months6_MTN_Bank = 0 AND Curr_MTN_Bank = 1 THEN 'MTN_Bank'
		WHEN Months6_CoralPay = 0 AND Curr_CoralPay = 1 THEN 'Coral'
		WHEN Months6_Quickteller = 0 AND Curr_Quickteller = 1 THEN 'Quickteller'
		WHEN Months6_Direct_Bank = 0 AND Curr_Direct_Bank = 1 THEN 'Direct_Bank'
		WHEN Curr_MTN_Bank = 0 AND Curr_MTN_Airtime = 0 AND Curr_CoralPay = 0 AND Curr_Quickteller = 0 AND Curr_Direct_Bank = 0 AND Curr_NIBSS = 0 THEN 'Yet_to_Pay'
		ELSE 'Old_User'
	END AS 'User',

CASE 
	WHEN Months6_MTN_Airtime = 1 AND Curr_MTN_Airtime = 0 AND Curr_MTN_Bank = 1 THEN 'Airtime_to_MTNBank'
	WHEN Months6_MTN_Airtime = 1 AND Curr_MTN_Airtime = 0 AND Curr_CoralPay = 1 THEN 'Airtime_to_CoralPay'
	WHEN Months6_MTN_Airtime = 1 AND Curr_MTN_Airtime = 0 AND Curr_Quickteller = 1 THEN 'Airtime_to_Quickteller'
	WHEN Months6_MTN_Airtime = 1 AND Curr_MTN_Airtime = 0 AND Curr_Direct_Bank = 1 THEN 'Airtime_to_Direct_Bank'
	WHEN Months6_MTN_Airtime = 1 AND Curr_MTN_Airtime = 1 AND Curr_MTN_Bank = 0 AND Curr_CoralPay = 0 AND Curr_Quickteller = 0 AND Curr_Direct_Bank = 0 THEN 'MTN_Regular'
	WHEN Months6_MTN_Airtime = 1 AND Months6_MTN_Bank = 0 AND Months6_CoralPay =0 AND Months6_Quickteller = 0 AND Months6_Direct_Bank = 0 AND Curr_MTN_Airtime = 1 AND (Curr_MTN_Bank = 1 OR Curr_CoralPay = 1 OR Curr_Quickteller = 1 OR Curr_Direct_Bank = 1) THEN 'Airtime_to_Mixed_Payment'
	
	WHEN Months6_MTN_Airtime = 1 AND (Months6_MTN_Bank = 1 OR Months6_CoralPay = 1 OR Months6_Quickteller = 1 OR Months6_Direct_Bank = 1) AND Curr_MTN_Airtime = 1 AND (Curr_MTN_Bank = 1 OR Curr_CoralPay = 1 OR Curr_Quickteller = 1 OR Curr_Direct_Bank = 1) THEN 'Mixed_Payment_to_Mixed_Payment'
	
	WHEN Curr_MTN_Bank = 0 AND Curr_MTN_Airtime = 0 AND Curr_CoralPay = 0 AND Curr_Quickteller = 0 AND Curr_Direct_Bank = 0 AND Curr_NIBSS = 0 THEN 'Yet_to_Pay'
	ELSE 'No Movement'
END AS 'Movement'
	
FROM
(
SELECT `contract`,
MAX(CASE WHEN `payment_type` LIKE '%MTN NG Airtime Bank%' AND `report_date` >= '2023-04-01' AND `report_date` <= '2023-09-01' THEN 1 ELSE 0 END) Months6_MTN_Bank,
MAX(CASE WHEN `payment_type` LIKE 'MTN_NG_Airtime' AND `report_date` >= '2023-04-01' AND `report_date` <= '2023-09-01' THEN 1 ELSE 0 END) Months6_MTN_Airtime,
MAX(CASE WHEN `payment_type` LIKE '%CoralPay%' AND `report_date` >= '2023-04-01' AND `report_date` <= '2023-09-01' THEN 1 ELSE 0 END) Months6_CoralPay,
MAX(CASE WHEN `payment_type` LIKE '%QuickTeller%' AND `report_date` >= '2023-04-01' AND `report_date` <= '2023-09-01' THEN 1 ELSE 0 END) Months6_Quickteller,
MAX(CASE WHEN `payment_type` LIKE '%DIRECT NG Bank%' AND `report_date` >= '2023-04-01' AND `report_date` <= '2023-09-01' THEN 1 ELSE 0 END) Months6_Direct_Bank,
MAX(CASE WHEN `payment_type` LIKE '%NIBSS%' AND `report_date` >= '2023-04-01' AND `report_date` <= '2023-09-01' THEN 2 ELSE 0 END) Months6_NIBSS,

MAX(CASE WHEN `payment_type` LIKE '%MTN NG Airtime Bank%' AND `report_date` = '2023-10-01' THEN 1 ELSE 0 END) Curr_MTN_Bank,
MAX(CASE WHEN `payment_type` LIKE 'MTN_NG_Airtime' AND `report_date` = '2023-10-01' THEN 1 ELSE 0 END) Curr_MTN_Airtime,
MAX(CASE WHEN `payment_type` LIKE '%CoralPay%' AND `report_date` = '2023-10-01' THEN 1 ELSE 0 END) Curr_CoralPay,
MAX(CASE WHEN `payment_type` LIKE '%QuickTeller%' AND `report_date` = '2023-10-01' THEN 1 ELSE 0 END) Curr_Quickteller,
MAX(CASE WHEN `payment_type` LIKE '%DIRECT NG Bank%' AND `report_date` = '2023-10-01' THEN 1 ELSE 0 END) Curr_Direct_Bank,
MAX(CASE WHEN `payment_type` LIKE '%NIBSS%' AND `report_date` = '2023-10-01' THEN 1 ELSE 0 END) Curr_NIBSS

FROM
(
SELECT * FROM `daily_transactions`
WHERE `contract` IN (
			SELECT `contract`
			FROM `buyout_offer`
		    )
AND `report_date` >= '2023-04-01'
)H
GROUP BY `contract`
)New_User

)a

LEFT JOIN 

`buyout_offer` b
ON a.`contract` = b.`contract`
