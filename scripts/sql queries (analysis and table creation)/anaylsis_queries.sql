--What are the top 5 brands by receipts scanned for most recent month?
--How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?

WITH month_ranked AS (
    SELECT 
        strftime('%Y-%m', date_scanned) AS purchase_month,
        RANK() OVER (ORDER BY MAX(date_scanned) DESC) AS month_rank
    FROM silver_receipts
    GROUP BY purchase_month
),
brand_ranking AS (
    SELECT 
        sb.brand_id,
        sb.name AS brand_name,
        strftime('%Y-%m', sr.date_scanned) AS purchase_month,
        COUNT(sr.receipt_id) AS total_receipts,
        RANK() OVER (PARTITION BY strftime('%Y-%m', sr.date_scanned) ORDER BY COUNT(sr.receipt_id) DESC) AS rank
    FROM silver_receipts sr
    JOIN silver_receipt_items sri ON sr.receipt_id = sri.receipt_id
    JOIN silver_brands sb ON sri.barcode = sb.barcode
    GROUP BY sb.brand_id, sb.name, purchase_month
)
SELECT * 
FROM brand_ranking
ORDER BY purchase_month DESC, rank;

-- When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
-- When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
SELECT 
	strftime('%Y-%m', sr.date_scanned) as scanned_month,
    sr.rewards_receipt_status,
    COALESCE(AVG(NULLIF(sr.total_spent, 0)), 0) AS avg_spent, 
    COALESCE(SUM(sri.quantity_purchased), 0) AS total_items_purchased
FROM silver_receipts sr
LEFT JOIN silver_receipt_items sri ON sr.receipt_id = sri.receipt_id
GROUP BY strftime('%Y-%m', sr.date_scanned),sr.rewards_receipt_status; 

--Which brand has the most spend among users who were created within the past 6 months?
--Which brand has the most transactions among users who were created within the past 6 months?
SELECT 
    sb.brand_id,
    sb.name AS brand_name,
    COUNT(sr.receipt_id) AS total_transactions,
    SUM(sr.total_spent) AS total_spent
FROM silver_users su
JOIN silver_receipts sr ON su.user_id = sr.user_id
JOIN silver_receipt_items sri ON sr.receipt_id = sri.receipt_id
JOIN silver_brands sb ON sri.barcode = sb.barcode
WHERE su.created_date >= date('now', '-6 months')
GROUP BY sb.brand_id, sb.name
ORDER BY total_spent DESC, total_transactions DESC