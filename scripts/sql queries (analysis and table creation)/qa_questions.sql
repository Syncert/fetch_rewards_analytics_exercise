--null barcodes result in missing opportunities to tie to brands. Every receipt item barcode that does not tie to a brand in the brand database equates to missed information about a purchase decision

SELECT
    strftime('%Y-%m', sr.purchase_date) AS purchase_month,
    CASE 
        WHEN sri.barcode IS NULL THEN 'is_null' 
		WHEN sri.barcode IS NOT NULL and sb.brand_id IS NULL THEN 'barcode_no_brand'
        WHEN sri.barcode IS NOT NULL and sb.brand_id IS NOT NULL THEN 'barcode_w_brand'
    END AS barcode_status,
    COUNT(*) AS total_count
FROM silver_receipts AS sr
LEFT JOIN silver_receipt_items AS sri ON sr.receipt_id = sri.receipt_id
LEFT JOIN silver_brands AS sb ON sri.barcode = sb.barcode
GROUP BY 
    strftime('%Y-%m', sr.purchase_date),
    CASE 
        WHEN sri.barcode IS NULL THEN 'is_null' 
		WHEN sri.barcode IS NOT NULL and sb.brand_id IS NULL THEN 'barcode_no_brand'
        WHEN sri.barcode IS NOT NULL and sb.brand_id IS NOT NULL THEN 'barcode_w_brand' 
    END
ORDER BY purchase_month DESC;

--There are 55.48% of scanned items missing barcodes, this is a missed opportunity
SELECT 
    COUNT(*) AS total_receipt_items,
    SUM(CASE WHEN sri.barcode IS NULL THEN 1 ELSE 0 END) AS missing_barcodes,
    ROUND(SUM(CASE WHEN sri.barcode IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS percent_missing
FROM silver_receipt_items sri;

--there appears to be a very low amount of receipt_item barcodes that match the brand database. Is there a reason for this?
select DISTINCT
		sri.barcode,
		count(sb.brand_code) as count
from silver_receipt_items sri
inner join silver_brands sb on sri.barcode = sb.barcode
group by sri.barcode
order by count desc

--There are discrepancies between date_scanned and purchase_month on the receipts data. Wondering how these different dates are being gathered in the system? 
select 
    strftime('%Y-%m', sr.purchase_date) AS purchase_month,
	count(*) 
from silver_receipts sr
group by strftime('%Y-%m', sr.purchase_date)
order by strftime('%Y-%m', sr.purchase_date) desc;

select 
    strftime('%Y-%m', sr.date_scanned) AS date_scanned,
	count(*) 
from silver_receipts sr
group by strftime('%Y-%m', sr.date_scanned)
order by strftime('%Y-%m', sr.date_scanned) desc