/*
Purpose: The purpose of this project is to understand how customers utilize each payment channel 
for their monthly repayments and identify which customers the business should promote to use different 
payment channels. Additionally, it aims to determine which customers qualify for ownership based on 
business criteria and those who should receive discount offers.

Result: This initiative resulted in a 45% conversion rate of inactive customers to owners. and a 20% increase
in the business most preferred payment channel.
*/

-- Customer Buyout report generation --

SELECT *
FROM
(
SELECT *, CASE	
		WHEN Sep_paidperiod >= Expected_paidperiod AND MTN_Airtime_payment <=0 THEN 'Eligible'
				
		WHEN Sep_paidperiod >= Expected_paidperiod AND MTN_Airtime_payment > 0 AND MTN_Airtime_paidperiod < Sep_paidperiod THEN 'Mixed_Payment'
			
		WHEN Sep_paidperiod >= `Days_remaining_to_ownership` AND MTN_Airtime_payment > 0 AND MTN_Bank_payment <=0 AND CoralPay_payment <=0 AND QuickTeller_payment <=0 AND DIRECT_NG_payment <=0 THEN 'Full_Airtime_Payment'
		
		WHEN Days_remaining_to_ownership_Status = 'Month' AND Sep_paidperiod >= 2 AND Sep_paidperiod < Expected_paidperiod AND MTN_Airtime_payment <=0 THEN 'Signing up for a payment plan till Dec 31st'
		
		WHEN Days_remaining_to_ownership_Status = 'Day' AND Sep_paidperiod >= 60 AND Sep_paidperiod < Expected_paidperiod AND MTN_Airtime_payment <=0 THEN 'Signing up for a payment plan till Dec 31st'
		
	ELSE 'Not_Eligible'
	
END AS Eligibility_Status, 
	
		CASE 
			WHEN `Discount_rate` = 0 AND `Days_remaining_to_ownership_Status` = 'Day' AND `Days_remaining_to_ownership` <=30 THEN 'Promote long plan purchase for discounts 1'
			
			WHEN `Discount_rate` = 0 AND `Days_remaining_to_ownership_Status` = 'Month' AND `Days_remaining_to_ownership` <=1 THEN 'Promote long plan purchase for discounts 1'
			
			WHEN `Discount_rate` = 0 AND `Days_remaining_to_ownership_Status` = 'Day' AND `Days_remaining_to_ownership` > 30 THEN 'Promote long plan purchase for discounts 2'
			
			WHEN `Discount_rate` = 0 AND `Days_remaining_to_ownership_Status` = 'Month' AND `Days_remaining_to_ownership` > 1 THEN 'Promote long plan purchase for discounts 2'
			
			WHEN `Discount_rate` = 1 OR `Discount_rate` = 30 THEN 'Enjoy 1-month discount, buy out unit today'
			
			WHEN `Discount_rate` = 2 OR `Discount_rate` = 60 THEN 'Enjoy 2-months discount, buy out unit today'
			
			WHEN `Discount_rate` = 3 OR `Discount_rate` = 90 THEN 'Enjoy 3-months discount, buy out unit today'
			
			WHEN `Discount_rate` = 5 OR `Discount_rate` = 150 THEN 'Enjoy 5-months discount, buy out unit today'
			
			WHEN `Discount_rate` = 7 OR `Discount_rate` = 210 THEN 'Enjoy 7-months discount, buy out unit today'
			
			WHEN `Discount_rate` = 9 OR `Discount_rate` = 270 THEN 'Enjoy 9-months discount, buy out unit today'
			
			WHEN `Discount_rate` = 12 THEN 'Enjoy 12-months discount, buy out unit today'		
	ELSE 'Check'
	
END AS Duration_offer

FROM 
(
SELECT *, 
	
	(MTN_Bank_paidperiod + MTN_Airtime_paidperiod + CoralPay_paidperiod + QuickTeller_paidperiod + DIRECT_NG_paidperiod) AS Sep_paidperiod,
		
	(MTN_Bank_payment + MTN_Airtime_payment + CoralPay_payment + QuickTeller_payment + DIRECT_NG_payment) AS Total_Amount

FROM 
(					
SELECT B.`contract`, B.`crmcontract`, B.`created_date`, B.`customer_name`, B.`customer_payer_phone_number`, B.`secondary_phone_number`, B.`lcp_status`, B.`generation`, B.`channel`,
	B.`type`, B.`warranty_end_date`, B.`subtype`, B.`customer_status`, B.`Required_Status`,

		#SUM(CASE WHEN c.`payment_channel` != 'NIBSS' AND DATE(c.`transaction_date`) < '2023-09-02' THEN c.`payment_duration` ELSE 0 END) 'Sept_1st_Paidperiod',
		
		#SUM(CASE WHEN c.`payment_channel` != 'NIBSS' AND DATE(c.`transaction_date`) < '2023-09-02' THEN c.`charged_amount` ELSE 0 END) 'Sept_1st_Payment',
		
		SUM(CASE WHEN c.`payment_channel` = 'MTN NG Airtime Bank' THEN c.`payment_duration` ELSE 0 END) 'MTN_Bank_paidperiod',
		
		SUM(CASE WHEN c.`payment_channel` = 'MTN NG Airtime Bank' THEN c.`charged_amount` ELSE 0 END) 'MTN_Bank_payment',
		
		SUM(CASE WHEN c.`payment_channel` = 'MTN' THEN c.`payment_duration` ELSE 0 END) 'MTN_Airtime_paidperiod',
		
		SUM(CASE WHEN c.`payment_channel` = 'MTN' THEN c.`charged_amount` ELSE 0 END) 'MTN_Airtime_payment',
		
		SUM(CASE WHEN c.`payment_channel` = 'CoralPay' THEN c.`payment_duration` ELSE 0 END) 'CoralPay_paidperiod',
		
		SUM(CASE WHEN c.`payment_channel` = 'CoralPay' THEN c.`charged_amount` ELSE 0 END) 'CoralPay_payment',
		
		SUM(CASE WHEN c.`payment_channel` = 'QuickTeller' THEN c.`payment_duration` ELSE 0 END) 'QuickTeller_paidperiod',
		
		SUM(CASE WHEN c.`payment_channel` = 'QuickTeller' THEN c.`charged_amount` ELSE 0 END) 'QuickTeller_payment',
		
		SUM(CASE WHEN c.`payment_channel` = 'DIRECT NG Bank' THEN c.`payment_duration` ELSE 0 END) 'DIRECT_NG_paidperiod',
		
		SUM(CASE WHEN c.`payment_channel` = 'DIRECT NG Bank' THEN c.`charged_amount`ELSE 0 END) 'DIRECT_NG_payment',
		
	B.`segmentation_status`, B.`seniority`,B.`Days_remaining_to_ownership`, B.`Days_remaining_to_ownership_Status`, B.`ltoperiod` , Discount_rate, B.`paidperiod` AS Pre_Offer_Paidperiod,`Days_remaining_to_ownership` - Discount_rate Expected_paidperiod, B.`product_category`
				
FROM 
(
SELECT `contract`, `crmcontract`, `created_date`, `customer_name`, `customer_payer_phone_number`, `secondary_phone_number`, `lcp_status`, `generation`, `channel`, `Required_Status`,
	`type`, `warranty_end_date`, `subtype`, `customer_status`, `Days_remaining_to_ownership`, `Days_remaining_to_ownership_Status`, `Customer_Type`,
	`paidperiod`, CASE 
		
		WHEN `ltoperiod` - `paidperiod` > 1109 AND `Days_remaining_to_ownership_Status` = 'Day' THEN 270
		WHEN `ltoperiod` - `paidperiod` >= 720 AND `Days_remaining_to_ownership_Status` = 'Day' THEN 210
		WHEN `ltoperiod` - `paidperiod` >= 540 AND `Days_remaining_to_ownership_Status` = 'Day' THEN 150
		WHEN `ltoperiod` - `paidperiod` >= 360 AND `Days_remaining_to_ownership_Status` = 'Day' THEN 90
		WHEN `ltoperiod` - `paidperiod` >= 210 AND `Days_remaining_to_ownership_Status` = 'Day' THEN 60
		WHEN `ltoperiod` - `paidperiod` >= 120 AND `Days_remaining_to_ownership_Status` = 'Day' THEN 30
		
		WHEN `ltoperiod` - `paidperiod` >= 37 AND `Days_remaining_to_ownership_Status` = 'Month' THEN 12
		
		WHEN `ltoperiod` - `paidperiod` >= 24 AND `Days_remaining_to_ownership_Status` = 'Month' THEN 9
		
		WHEN `ltoperiod` - `paidperiod` >= 18 AND `Days_remaining_to_ownership_Status` = 'Month' THEN 5
		
		WHEN `ltoperiod` - `paidperiod` >= 12 AND `Days_remaining_to_ownership_Status` = 'Month' THEN 3
		
		WHEN `ltoperiod` - `paidperiod` >= 7 AND `Days_remaining_to_ownership_Status` = 'Month' THEN 2
		
		WHEN `ltoperiod` - `paidperiod` >= 4 AND `Days_remaining_to_ownership_Status` = 'Month' THEN 1
		
	ELSE 0 END AS Discount_rate,
	
	`segmentation_status`, `seniority`, `ltoperiod`, `product_category`
FROM `buyout_offer_dec23`
)B

LEFT JOIN
(
SELECT *
FROM  `daily_transactions_curr_MTD`
WHERE `report_date` = '2024-01-29' AND DATE(`transaction_date`) BETWEEN('2024-01-01') AND ('2024-01-28')
)c
ON B.`contract` = c.`contract`
GROUP BY B.`contract`, B.`crmcontract`, B.`created_date`, B.`customer_name`, B.`customer_payer_phone_number`, B.`lcp_status`, B.`generation`, B.`channel`,
	B.`type`, B.`warranty_end_date`, B.`subtype`, B.`customer_status`, B.`Days_remaining_to_ownership`, B.`Days_remaining_to_ownership_Status`, B.`Customer_Type`, Expected_paidperiod,B.`segmentation_status`, B.`seniority`, B.`ltoperiod`, B.`product_category`,
	B.Paidperiod, Discount_rate, B.`Required_Status`, B.`secondary_phone_number`
	)c

)END
) DAY

WHERE Eligibility_Status = 'Eligible' OR Eligibility_Status = 'Mixed_Payment' OR Eligibility_Status = 'Full_Airtime_Payment' OR Eligibility_Status = 'Signing up for a payment plan till Dec 31st';
