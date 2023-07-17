---INSPECTING DATA

SELECT*
FROM [dbo].[sales_data]

---maximun order date

SELECT MAX (invoiceDate)
FROM [dbo].[sales_data]

---KIP overview

SELECT  COUNT (DISTINCT (CustomerID)) AS total_customers,
        COUNT (DISTINCT (invoice)) AS total_orders,
        SUM(Quantity) AS total_quantity,
	CAST (SUM (TotalAmount) AS DECIMAL (16,0))  As total_revenue      
FROM  [dbo].[sales_data]

---RFM ANALYSIS

---Setting end date

DECLARE @today_date AS DATE = '2011-12-10'

---Finding recency,frequency and monetary values

DROP TABLE IF EXISTS #rfm
;WITH rfm AS
( SELECT  CustomerID,
        DATEDIFF( day, MAX(invoiceDate),@today_date) As Recency,
	COUNT (DISTINCT (invoice)) AS Frequency,
	CAST(SUM(TotalAmount) AS DECIMAL(16,0)) AS Monetary
FROM [dbo].[sales_data]
WHERE CustomerID IS NOT NULL 
GROUP BY CustomerID ),

---assigning scores to recency,frequency and monetary values using the NTILE function
	
rfm_score AS
 (SELECT CustomerID,
       Recency,
	Frequency,
	Monetary,
        NTILE(4)  OVER (ORDER BY Recency DESC) AS Recency_score,
	NTILE(4)  OVER (ORDER BY Frequency ) AS Frecency_score,
	NTILE(4)  OVER (ORDER BY Monetary) AS Monetary_score
FROM rfm )

---adding up the scores to find the total FRM scores and RFM cell

SELECT CustomerID,
        Recency,
	Frequency,
	Monetary,
        Recency_score,
	Frecency_score,
	Monetary_score,
	CAST(Recency_score AS VARCHAR) + CAST (Frecency_score AS VARCHAR)  + CAST(Monetary_score AS VARCHAR)    AS rfm_cell,
	Recency_score + Frecency_score + Monetary_score AS total_score

 INTO #rfm
 FROM rfm_score

 ---Distinct rfm cells to help assign segments

 SELECT DISTINCT rfm_cell
 FROM  #rfm 
 ORDER BY rfm_cell DESC

 ---segmenting customers using the RFM cell by making use of the case statement

 SELECT  CustomerID,
        Recency,
	Frequency,
	Monetary,
        Recency_score,
	Frecency_score,
	Monetary_score,
        total_score,
        rfm_cell,
CASE
       WHEN  rfm_cell  in ( 311, 312, 313, 314 ) THEN 'New customer'
       WHEN  rfm_cell  in ( 111, 112,113,114) THEN 'Random customer'
       WHEN  rfm_cell in ( 121, 122, 123, 124, 131,132,133,134,141,142,143,144 ) THEN 'Lost customer'
       WHEN  rfm_cell in (  211,  212, 213, 214 ) THEN 'At the risk of churning'
       WHEN  rfm_cell in ( 221, 222, 231, 232, 321, 322 ) THEN ' Active but low value '
       WHEN  rfm_cell in ( 223, 224, 233, 234, 243,  323, 324 ) THEN ' Active & high value' 
       WHEN  rfm_cell  in  (241, 242, 243, 244, 331,332, 342 ,421, 422, 431,441,442) THEN ' Loyal but low value'
       WHEN  rfm_cell in ( 333, 334, 343 ,344,423,424, 432,433)  THEN 'Loyal & high value'
       WHEN  rfm_cell in ( 434, 443, 444) THEN 'Champion'
END AS clusters
  
		
 FROM #rfm 











