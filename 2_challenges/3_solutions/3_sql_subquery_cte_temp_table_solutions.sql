USE chinook;

-- 1. What is the difference in minutes between the total length of 'Rock' tracks and 'Jazz' tracks?
SELECT 
    (SELECT SUM(Milliseconds)
	FROM Track t
	JOIN Genre g ON t.GenreId = g.GenreId
	WHERE g.Name = 'Rock')
	- 
	(SELECT SUM(Milliseconds)
	FROM Track t
	JOIN Genre g ON t.GenreId = g.GenreId
	WHERE g.Name = 'Jazz') 
	/ 60000 AS LengthDifferenceMinutes;


-- 2. How many tracks have a length greater than the average track length?
SELECT 
    COUNT(*) AS TracksAboveAverageLength
FROM
    Track
WHERE
    Milliseconds > (SELECT AVG(Milliseconds)
					FROM Track);
            

-- 3. What is the percentage of tracks sold per genre?
SELECT 
    g.Name AS Genre,
    COUNT(il.TrackId) * 100 / (SELECT COUNT(TrackId) FROM InvoiceLine) AS PercentageSold
FROM
    InvoiceLine il
        JOIN
    Track t ON il.TrackId = t.TrackId
        JOIN
    Genre g ON t.GenreId = g.GenreId
GROUP BY g.GenreId, g.Name;


-- 4. Can you check that the column of percentages adds up to 100%?

WITH TableOfPercentages AS (
	SELECT 
		g.Name AS Genre,
		COUNT(il.TrackId) * 100.0 / (SELECT COUNT(TrackId) FROM InvoiceLine) AS PercentageSold
	FROM
		InvoiceLine il
			JOIN
		Track t ON il.TrackId = t.TrackId
			JOIN
		Genre g ON t.GenreId = g.GenreId
	GROUP BY g.Name
)
SELECT SUM(PercentageSold)
FROM TableOfPercentages;


-- 5. What is the difference between the highest number of tracks in a genre and the lowest?
SELECT MAX(NumTracks) - MIN(NumTracks) AS RangeOfTracksByGenre
FROM (
	  SELECT COUNT(*) AS NumTracks 
	  FROM Track
	  GROUP BY GenreId
) AS TrackCounts;


-- 6. What is the average value of Chinook customers (total spending)?
SELECT ROUND(AVG(TotalSpending), 2) AS AvgLifetimeSpend
FROM (
    SELECT c.CustomerId,
           SUM(i.Total) AS TotalSpending
    FROM Customer c
    JOIN Invoice i USING (CustomerId)
    GROUP BY c.CustomerId
) AS CustomerSpending;


-- 7. How many complete albums were sold? Not just tracks from an album, but the whole album bought on one invoice.

CREATE TEMPORARY TABLE TracksOnInvoice (
	SELECT
		il.invoiceid,
		t.albumid,
		COUNT(DISTINCT il.trackid) AS InvoiceTrackCount
	FROM
		invoiceline il
		LEFT JOIN
		track t USING (trackid)
	GROUP BY il.invoiceid, t.albumid
);

CREATE TEMPORARY TABLE TracksOnAlbum (
	SELECT 
		albumid,
        COUNT(DISTINCT trackid) AS AlbumTrackCount
	FROM
		track
	GROUP BY albumid
);

SELECT COUNT(AlbumTrackCount)
FROM TracksOnInvoice
	LEFT JOIN
		TracksOnAlbum USING (albumid)
WHERE InvoiceTrackCount = AlbumTrackCount;


-- 8. What is the maximum spent by a customer in each genre?

WITH CustomerSpendingPerGenre AS (
	SELECT
		g.Name AS Genre,
		c.CustomerId,
		SUM(il.UnitPrice * il.Quantity) AS Spend
	FROM
		Customer c
	JOIN
		Invoice i USING (CustomerId)
	JOIN
		InvoiceLine il USING (InvoiceId)
	JOIN
		Track t USING (TrackId)
	JOIN
		Genre g USING (GenreId)
	GROUP BY
		g.Name, c.CustomerId
)
SELECT
	Genre,
    MAX(Spend)
FROM CustomerSpendingPerGenre
GROUP BY Genre
ORDER BY MAX(Spend) DESC;
	

-- 9. What percentage of customers who made a purchase in 2022 returned to make additional purchases in subsequent years?

CREATE TEMPORARY TABLE CustomersYearlyPurchases (
	SELECT 
		YEAR(i.invoicedate) AS YEAR_,
        i.customerid,
        SUM(i.total)
	FROM invoice i
    GROUP BY YEAR(i.invoicedate), i.customerid
);
    
CREATE TEMPORARY TABLE CustomersIn2022 (
	SELECT
		customerid
	FROM
		CustomersYearlyPurchases
	WHERE
		YEAR_ = 2022
);

SELECT
(SELECT
	COUNT(DISTINCT customerid)
FROM
	CustomersYearlyPurchases
WHERE
	YEAR_ > 2022 
    AND customerid IN (SELECT * FROM CustomersIn2022))
* 100
/ (SELECT COUNT(customerid) FROM customer) AS PercentageReturnAfter2022;
    

-- 10. Which genre is each employee most successful at selling? Most successful is greatest amount of tracks sold.

CREATE TEMPORARY TABLE AmountSoldPerEmployeePerGenre (
SELECT 
	e.employeeid,
    CONCAT(e.firstname, " ", e.lastname) AS EmployeeName,
    g.Name AS GenreName,
    SUM(il.quantity) AS QuantitySoldInGenre
FROM
	employee e
    JOIN customer c
		ON e.employeeid = c.supportrepid
	JOIN invoice i
		USING (customerid)
	JOIN invoiceline il
		USING (invoiceid)
	JOIN track t
		USING (trackid)
	JOIN genre g
		USING (genreid)
GROUP BY e.employeeid, g.genreid, g.Name
);

CREATE TEMPORARY TABLE MaxSoldPerEmployeePerGenre (
SELECT
	employeeid,
    EmployeeName,
    MAX(QuantitySoldInGenre) AS MaxSold
FROM
	AmountSoldPerEmployeePerGenre
GROUP BY employeeid, EmployeeName
);

SELECT 
	a.EmployeeName,
    a.GenreName
FROM
	MaxSoldPerEmployeePerGenre m
	JOIN
		AmountSoldPerEmployeePerGenre a USING (employeeid)
WHERE m.MaxSold = a.QuantitySoldInGenre;


-- 11. How many customers made a second purchase the month after their first purchase?

WITH FirstPurchaseTable AS (
	SELECT
		customerid,
		MIN(DATE(invoicedate)) AS DateOfFirstPurchase
	FROM invoice
    GROUP BY customerid
),
SecondPurchaseTable AS (
	SELECT
		customerid,
		MIN(DATE(invoicedate)) AS DateOfSecondPurchase
	FROM invoice
    JOIN FirstPurchaseTable USING (customerid)
    WHERE DATE(invoicedate) > DateOfFirstPurchase
    GROUP BY customerid
)
SELECT
	COUNT(*)
FROM (
	SELECT 
		DateOfFirstPurchase,
		DateOfSecondPurchase,
		TIMESTAMPDIFF(MONTH, DateOfFirstPurchase, DateOfSecondPurchase) AS MonthDifference
	FROM FirstPurchaseTable
		JOIN SecondPurchaseTable USING (customerid)
	HAVING MonthDifference = 1
) AS OnlyOneMonthDifference;