USE Chinook;


-- 1. Rank the customers by total sales

SELECT 
	i.customerid, 
    c.firstname, 
    c.lastname, 
    SUM(i.total) as total_sales,
	RANK() OVER (ORDER BY SUM(i.total) DESC) as sales_rank
FROM 
	invoice i
	JOIN customer c 	
		ON i.customerid = c.customerid
GROUP BY customerid, firstname, lastname;


-- 2. Select only the top 10 ranked customer from the previous question

WITH TotalRankedPurchases AS (
	SELECT 
		i.customerid, 
		c.firstname, 
        c.lastname, 
        SUM(i.total) as total_sales,
		RANK() OVER (ORDER BY SUM(i.total) DESC) as sales_rank
FROM 
	invoice i
	JOIN 
		customer c ON i.customerid = c.customerid
GROUP BY customerid, firstname, lastname
)
SELECT *
FROM TotalRankedPurchases
WHERE sales_rank <= 10;


-- 3. Rank albums based on the total number of tracks sold.

SELECT
	ar.Name,
    a.title AS album_title,
    SUM(il.quantity) AS total_tracks_sold,
    DENSE_RANK() OVER (ORDER BY SUM(il.quantity) DESC) AS album_rank
FROM album a
JOIN artist ar USING (ArtistId)
JOIN track t ON a.albumid = t.albumid
JOIN invoiceline il ON t.trackid = il.trackid
GROUP BY a.albumid
ORDER BY album_rank;


-- 4. Do music preferences vary by country? What are the top 3 genres for each country?

WITH TopGenresPerCountry AS (
	SELECT
		i.BillingCountry AS Country,
		g.Name AS Genre,
		COUNT(il.TrackId) AS TrackCount,
        RANK() OVER (PARTITION BY i.BillingCountry ORDER BY COUNT(il.TrackId) DESC) AS Ranking
	FROM
		InvoiceLine il
		JOIN Track t USING (TrackId)
		JOIN Genre g USING (Genreid)
		JOIN Invoice i USING (InvoiceId)
	GROUP BY Country, Genre
)
SELECT *
FROM TopGenresPerCountry
WHERE Ranking <= 3;
    
    
-- 5. In which countries is Blues the most popular genre?
WITH TopGenresPerCountry AS (
	SELECT
		i.BillingCountry AS Country,
		g.Name AS Genre,
		COUNT(il.TrackId) AS TrackCount,
		RANK() OVER (PARTITION BY i.BillingCountry ORDER BY COUNT(il.TrackId)) AS Ranking
	FROM
		InvoiceLine il
		JOIN Track t USING (TrackId)
		JOIN Genre g USING (Genreid)
		JOIN Invoice i USING (InvoiceId)
	GROUP BY Country, Genre
)
SELECT Country
FROM TopGenresPerCountry
WHERE Ranking = 1 
	AND Genre = "Blues";
    

-- 6. Has there been year on year growth? By how much have sales increased per year?
SELECT 
	YEAR(InvoiceDate) AS Year_,
    SUM(Total) AS YearTotalSales,
	LAG(SUM(Total)) OVER (ORDER BY YEAR(InvoiceDate)) as PreviousYearTotal,
    SUM(Total) - LAG(SUM(Total)) OVER (ORDER BY YEAR(InvoiceDate)) AS YearOnYearDifference
FROM invoice
GROUP BY YEAR(InvoiceDate);

    
-- 7. How do the sales vary month-to-month as a percentage? 

SELECT
	YEAR(InvoiceDate) AS Year_,
	MONTH(InvoiceDate) AS Month_,
	SUM(Total) AS MonthlyInvoiceTotals,
    LAG(SUM(Total)) OVER (ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate)) AS PreviousMonthsInvoiceTotal,
    ROUND(100 * (SUM(Total) - LAG(SUM(total)) OVER (ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate))) / (LAG(SUM(Total)) OVER (ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate))), 2) AS SalesPercentageChange
FROM
	invoice
GROUP BY MONTH(InvoiceDate), YEAR(InvoiceDate);


-- 8. What is the monthly sales growth, categorised by whether it was an increase or decrease compared to the previous month?

SELECT 
    YEAR(InvoiceDate) AS Sales_Year, 
    MONTH(InvoiceDate) AS Sales_Month, 
    SUM(Total) AS Sales_Amount,
    (SUM(Total) - LAG(SUM(Total)) OVER(ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate))) AS Monthly_Sales_Growth,
    CASE
        WHEN (SUM(Total) - LAG(SUM(Total)) OVER(ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate))) > 0 THEN 'Increase'
        WHEN (SUM(Total) - LAG(SUM(Total)) OVER(ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate))) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS Growth_Category
FROM Invoices
GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY Sales_Year, Sales_Month;


-- 9. How many months in the data showed an increase in sales compared to the previous month?

WITH MonthlyGrowthCategorised AS (
SELECT 
    YEAR(InvoiceDate) AS Sales_Year, 
    MONTH(InvoiceDate) AS Sales_Month, 
    SUM(Total) AS Sales_Amount,
    (SUM(Total) - LAG(SUM(Total)) OVER(ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate))) AS Monthly_Sales_Growth,
    CASE
        WHEN (SUM(Total) - LAG(SUM(Total)) OVER(ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate))) > 0 THEN 'Increase'
        WHEN (SUM(Total) - LAG(SUM(Total)) OVER(ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate))) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS Growth_Category
FROM Invoice
GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY Sales_Year, Sales_Month
)
SELECT COUNT(*) AS NumberOfIncreasedSalesMonths
FROM MonthlyGrowthCategorised
WHERE Growth_Category = "Increase";


-- 10. As a percentage of all months in the dataset, how many months in the data showed an increase in sales compared to the previous month?

WITH MonthlyGrowthCategorised AS (
SELECT 
    YEAR(InvoiceDate) AS Sales_Year, 
    MONTH(InvoiceDate) AS Sales_Month, 
    SUM(Total) AS Sales_Amount,
    (SUM(Total) - LAG(SUM(Total)) OVER(ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate))) AS Monthly_Sales_Growth,
    CASE
        WHEN (SUM(Total) - LAG(SUM(Total)) OVER(ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate))) > 0 THEN 'Increase'
        WHEN (SUM(Total) - LAG(SUM(Total)) OVER(ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate))) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS Growth_Category
FROM Invoice
GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY Sales_Year, Sales_Month
)
SELECT 
	100 
    * (SELECT COUNT(*) FROM MonthlyGrowthCategorised WHERE Growth_Category = "Increase")
    / (SELECT COUNT(*) FROM MonthlyGrowthCategorised) 
    AS PercentOfMonthsWithIncrease;


-- 11. How have purchases of rock music changed quarterly? Show the quarterly change in the amount of tracks sold

SELECT
    YEAR(i.InvoiceDate) AS Year_,
    QUARTER(i.InvoiceDate) AS Quarter_,
    COUNT(il.TrackID) AS QuarterPurchases,
    LAG(COUNT(il.TrackID)) OVER (ORDER BY YEAR(i.InvoiceDate), QUARTER(i.InvoiceDate)) AS PreviousQuarter,
    (COUNT(il.TrackID) - LAG(COUNT(il.TrackID)) OVER (ORDER BY YEAR(i.InvoiceDate), QUARTER(i.InvoiceDate))) AS QuarterlyChange
FROM
    Invoice i
	JOIN InvoiceLine il USING (InvoiceId)
JOIN Track t USING (TrackId)
JOIN Genre g USING (GenreId)
WHERE g.Name = 'Rock'
GROUP BY Year_, Quarter_
ORDER BY Year_, Quarter_;


-- 12. Determine the average time between purchases for each customer.

WITH PurchaseDates AS (
    SELECT 
        CustomerId, 
        InvoiceDate, 
        LAG(InvoiceDate) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate) AS PreviousInvoiceDate
    FROM 
        Invoice
)
SELECT 
    CustomerId, 
    AVG(DATEDIFF(InvoiceDate, PreviousInvoiceDate)) AS AvgDaysBetweenPurchases
FROM 
    PurchaseDates
GROUP BY 
    CustomerId;