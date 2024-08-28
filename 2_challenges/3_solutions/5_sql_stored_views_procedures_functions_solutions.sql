USE Chinook;

-- 1. Create a view help your colleagues see which countries have the most invoices

CREATE VIEW CountryInvoicesRanked AS
SELECT 
	BillingCountry AS Country,
	COUNT(DISTINCT InvoiceId) AS Invoices,
	RANK() OVER (ORDER BY COUNT(DISTINCT InvoiceId) DESC) AS Rank_
FROM 
	Invoice
GROUP BY BillingCountry
ORDER BY Invoices DESC;


SELECT *
FROM CountryInvoicesRanked;	


-- 2. Create a view help your colleagues see which cities have the most valuable customer base

CREATE VIEW CityCustomerSpending AS
SELECT
    c.City,
    c.Country,
    SUM(i.Total) AS TotalSpending,
    RANK() OVER (ORDER BY SUM(i.Total) DESC) AS Rank_
FROM
    Customer c
	JOIN Invoice i USING(CustomerId)
GROUP BY c.City, c.Country
ORDER BY TotalSpending DESC;


SELECT *
FROM CityCustomerSpending;


-- 3. Create a view to identify the top spending customer in each country. Order the results from highest spent to lowest.

CREATE VIEW TopSpenderByCountry AS
WITH CustomerSpending AS (
    SELECT
        c.CustomerId,
        c.Country,
        SUM(i.Total) AS TotalCustomerSpend,
        RANK() OVER (PARTITION BY c.Country ORDER BY SUM(i.Total) DESC) AS SpendingRank
    FROM Customer c
		JOIN Invoice i USING(CustomerId)
    GROUP BY c.CustomerId, c.Country
)
SELECT
	Country,
    TotalCustomerSpend AS HighestCustomerSpend,
    CustomerId
FROM CustomerSpending
WHERE SpendingRank <= 1
ORDER BY HighestCustomerSpend DESC;


SELECT *
FROM TopSpenderByCountry;


-- 4. Create a view to show the top 5 selling artists of the top selling genre
-- If there are multiple genres that all sell well, give the top 5 of all top selling genres collectively

CREATE VIEW TopFiveOfTopGenre AS
WITH RankedGenres AS (
    SELECT
        g.Name AS Genre,
        SUM(il.Quantity * t.UnitPrice) AS TotalSales,
        RANK() OVER (ORDER BY SUM(il.Quantity * t.UnitPrice) DESC) AS GenreRank
    FROM
        genre g
		JOIN track t USING (GenreId)
		JOIN invoiceline il USING (TrackId)
    GROUP BY g.GenreId
)
, RankedTracksOfTopGenre AS (
	SELECT
		g.Name AS Genre,
		a.Name AS Artist,
		SUM(il.Quantity * t.UnitPrice) AS TotalSales,
		RANK() OVER (ORDER BY SUM(il.Quantity * t.UnitPrice) DESC) AS TrackRank
	FROM
		genre g
		JOIN track t USING (GenreId)
		JOIN invoiceline il USING (TrackId)
		JOIN album al USING (AlbumId)
		JOIN artist a USING (ArtistId)
	WHERE g.Name IN (SELECT Genre FROM RankedGenres WHERE GenreRank = 1)
	GROUP BY g.Name, a.Name
)
SELECT *
FROM RankedTracksOfTopGenre
WHERE TrackRank <= 5;


SELECT *
FROM TopFiveOfTopGenre;


-- 5. Create a stored procedure that, when provided with an InvoiceId, 
-- retrieves all orders and corresponding order items acquired by the customer who placed the specified order

DELIMITER $$

CREATE PROCEDURE GetAllCustomerOrders(IN InputInvoiceId INT)
BEGIN
	SELECT 
		i.CustomerId,
		i.InvoiceID,
		il.TrackId,
		ar.Name AS Artist,
		t.Name AS Track,
		al.Title AS Album,
		il.UnitPrice,
		il.Quantity
	FROM Invoice i
		JOIN InvoiceLine il USING (InvoiceId)
		JOIN Track t USING (TrackId)
		JOIN Album al USING (AlbumId)
		JOIN Artist ar USING (ArtistId)
	WHERE CustomerId = (SELECT CustomerId
						FROM Invoice
						WHERE InvoiceId = InputInvoiceId);
END $$

DELIMITER ;


CALL GetAllCustomerOrders(1);


-- 6. Create a stored procedure to retrieve sales data from a given date range

DELIMITER $$

CREATE PROCEDURE GetSalesDataBetweenDates(IN InputStartDate DATE, IN InputEndDate DATE)
BEGIN
    SELECT 
        I.InvoiceId,
        I.CustomerId,
        I.InvoiceDate,
        SUM(il.UnitPrice * il.Quantity) AS TotalSales
    FROM 
        Invoice i
    JOIN 
        InvoiceLine il USING (InvoiceId)
    WHERE 
        i.InvoiceDate BETWEEN InputStartDate AND InputEndDate
    GROUP BY 
        i.InvoiceId;
END $$

DELIMITER ;


CALL GetSalesDataBetweenDates('2022-01-01', '2022-01-31');


-- 7. Create a stored function to calculate the average invoice amount for a given country

DELIMITER $$

CREATE FUNCTION GetAverageInvoiceAmountForCountry(InputCountryName VARCHAR(255))
RETURNS DECIMAL(10, 2)

NOT DETERMINISTIC
READS SQL DATA 

BEGIN
    DECLARE avgAmount DECIMAL(10, 2);

    SELECT AVG(Total) INTO avgAmount
    FROM Invoice
    WHERE BillingCountry = InputCountryName;

    RETURN avgAmount;
END $$

DELIMITER ;


SELECT GetAverageInvoiceAmountForCountry('USA');


-- 8. Create a stored function that returns the best-selling artist in a specified genre

DELIMITER $$

CREATE FUNCTION GetBestSellingArtistInGenre(InputGenre VARCHAR(255))
RETURNS VARCHAR(255)

NOT DETERMINISTIC
READS SQL DATA 

BEGIN
    DECLARE TopArtist VARCHAR(255);
    
	WITH RankedGenreArtists AS (
		SELECT
			ar.Name AS Artist,
			COUNT(il.TrackId) AS SoldTrackCount,
			RANK() OVER (ORDER BY COUNT(il.TrackId) DESC) AS Rank_
		FROM
			InvoiceLine il
				JOIN Track t USING (TrackId)
				JOIN Album al USING (AlbumId)
				JOIN Artist ar USING (ArtistId)
				JOIN Genre g USING (GenreId)
		WHERE g.Name = InputGenre
		GROUP BY ar.ArtistId
	)
	SELECT Artist INTO TopArtist
	FROM RankedGenreArtists
	WHERE Rank_ = 1;
    
    RETURN TopArtist;
END $$

DELIMITER ;


SELECT GetBestSellingArtistInGenre("Rock");


-- 9. Create a stored function to calculate the total amount that customer spent with the company

DELIMITER $$

CREATE FUNCTION GetTotalSpend(InputCustomerId INT)
RETURNS DECIMAL(10, 2)

NOT DETERMINISTIC
READS SQL DATA 

BEGIN
    DECLARE SumTotal DECIMAL(10, 2);
    
	SELECT SUM(Total) INTO SumTotal
	FROM Invoice
	WHERE CustomerId = InputCustomerId;
    
    RETURN SumTotal;
END $$

DELIMITER ;


SELECT GetTotalSpend(1);


-- 10. Create a stored function to find the average song length for an album

DELIMITER $$

CREATE FUNCTION GetAverageTrackLength(InputAlbumId INT)
RETURNS FLOAT

NOT DETERMINISTIC
READS SQL DATA 

BEGIN
    DECLARE AvgTrackLength FLOAT;
    
	SELECT AVG(t.MilliSeconds) INTO AvgTrackLength
	FROM Track t
		JOIN Album al USING (AlbumId)
	WHERE al.AlbumId = InputAlbumId;
    
    RETURN AvgTrackLength;
END $$

DELIMITER ;


SELECT GetAverageTrackLength(1);


-- 11. Create a stored function to return the most popular genre for a given country

DELIMITER $$

CREATE FUNCTION GetTopGenre(InputCountry VARCHAR(255))
RETURNS VARCHAR(255)

NOT DETERMINISTIC
READS SQL DATA 

BEGIN
    DECLARE TopGenre VARCHAR(255);
    
	WITH RankedGenresOfCountry AS (
		SELECT
			g.Name AS Genre,
			COUNT(il.TrackId) AS TotalTracksSold,
			RANK() OVER (ORDER BY COUNT(il.TrackId) DESC) AS Rank_
		FROM Invoice i
			JOIN InvoiceLine il USING (InvoiceId)
			JOIN Track t USING (TrackId)
			JOIN Genre g USING (GenreId)
		WHERE BillingCountry = InputCountry
		GROUP BY g.GenreId, g.Name
	)
	SELECT Genre INTO TopGenre
	FROM RankedGenresOfCountry
	WHERE Rank_ = 1;
    
    RETURN TopGenre;
END $$

DELIMITER ;


SELECT GetTopGenre("USA");