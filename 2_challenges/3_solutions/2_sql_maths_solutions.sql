USE Chinook;


-- 1. What's the difference between the largest and the smallest invoice price?
SELECT 
    MAX(total) - MIN(total)
FROM
    invoice;


-- 2. What is the difference in length between the longest and shortest track in minutes?
SELECT 
    MAX(milliseconds) / 60000 - MIN(milliseconds) / 60000 AS LengthDifferenceMinutes
FROM
    track;
    

-- 3. What is the average length of a track in the 'Rock' genre in minutes?
SELECT 
    AVG(t.milliseconds) / 60000 AS AverageLengthMinutes
FROM
    track t
        JOIN
    genre g USING (genreid)
WHERE
    g.name = 'Rock';


-- 4. What is the average length of a 'Rock' track in minutes, rounded to 2 decimal places?
SELECT 
    ROUND(AVG(milliseconds) / 60000, 2) AS AverageLengthMinutes
FROM
    track t
        JOIN
    genre g USING (genreid)
WHERE
    g.name = 'Rock';


-- 5. What is the average length of a 'Rock' track in minutes, rounded down to the nearest integer?
SELECT 
    FLOOR(AVG(milliseconds) / 60000) AS AverageLengthMinutes
FROM
    track t
        JOIN
    genre g USING (genreid)
WHERE
    g.name = 'Rock';
    

-- 6. What is the average length of a 'Rock' track in minutes, rounded up to the nearest integer?
SELECT 
    CEIL(AVG(milliseconds) / 60000) AS AverageLengthMinutes
FROM
    track t
        JOIN
    genre g USING (genreid)
WHERE
    g.name = 'Rock';


-- 7. What is the total length of all tracks for each genre in minutes.
-- Order them from largest to smallest length of time.
SELECT 
    g.name AS Genre,
    SUM(t.milliseconds) / 60000 AS TotalLengthMinutes
FROM
    track t
        JOIN
    genre g USING (genreid)
GROUP BY g.Name
ORDER BY TotalLengthMinutes DESC;


-- 8. How many tracks have a length between 3 and 5 minutes?
SELECT 
    COUNT(trackid) AS CountTracks3To5Minutes
FROM
    Track
WHERE
    Milliseconds / 60000 BETWEEN 3 AND 5;


-- 9. If each song costs $1.27, how much would it cost to buy all the songs in the 'Classical' genre?
SELECT 
    COUNT(t.trackid) * 1.27 AS TotalCost
FROM
    track t
        JOIN
    genre g ON t.GenreId = g.GenreId
WHERE
    g.Name = 'Classical';


-- 10. How many more composers are there than artists?
SELECT 
    COUNT(DISTINCT (t.composer)) - COUNT(DISTINCT (a.artistid)) AS Difference
FROM
    track t
        LEFT JOIN
    album al USING (albumid)
        LEFT JOIN
    artist a USING (artistid);


-- 11. Which 'Metal' genre albums have an odd number of tracks?
SELECT 
	al.albumid AS AlbumId,
    al.title AS AlbumTitle, 
    COUNT(t.trackid) AS NumberOfTracks
FROM
    album al
        JOIN
    track t USING (albumid)
        JOIN
    genre g USING (genreid)
WHERE
    g.name = 'Metal'
GROUP BY al.albumid, al.title
HAVING COUNT(t.trackid) % 2 = 1;


-- 12. What is the average invoice total rounded to the nearest whole number?
SELECT 
    ROUND(AVG(total)) AS AverageInvoiceTotal
FROM
    invoice;
    

-- 13. Classify tracks as 'Short', 'Medium', or 'Long' based on their length.
-- Long is 5 minutes or longer. Short is less than 3 minutes.
SELECT 
	trackid,
    Name,
    CASE
        WHEN Milliseconds / 60000 < 3 THEN 'Short'
        WHEN Milliseconds / 60000 < 5 THEN 'Medium'
        ELSE 'Long'
    END AS LengthCategory
FROM
    track;
    

-- 14. Taking into consideration the unitprice and the quantity sold,
-- rank the songs from highest grossing to lowest.
-- Include the track name and the artist.
SELECT 
    a.name AS Artist,
    t.name AS Track,
    SUM(il.unitprice * il.quantity) AS Gross
FROM
    invoiceline il
        LEFT JOIN
    track t USING (trackid)
        LEFT JOIN
    album al USING (albumid)
        LEFT JOIN
    artist a USING (artistid)
GROUP BY il.trackid
ORDER BY Gross DESC;
