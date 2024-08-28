USE Northwind;

/*****************
Subquery
*****************/

-- Subqueries are queries nested within another query.
-- They can be used to perform complex data retrieval and manipulation tasks. 

/***
Subquery in a WHERE clause
***/

-- Find all products that have a price higher than the average product price:

SELECT 
    ProductName, 
    UnitPrice
FROM
    Products
WHERE
    UnitPrice > (SELECT AVG(UnitPrice)
				 FROM Products); 


-- Subqueries work as queries by themselves!

SELECT 
	AVG(UnitPrice)
FROM 
	Products;


/***
Subquery in a HAVING clause
***/

-- Find all the countries that have a total freight cost higher than that of Germany

SELECT 
    ShipCountry, 
    SUM(Freight) AS TotalFreight
FROM
    Orders
GROUP BY ShipCountry
HAVING SUM(Freight) > (SELECT 
                           SUM(Freight)
                       FROM
                           Orders
                       WHERE
                           ShipCountry = 'Germany')
ORDER BY TotalFreight DESC;


/***
Subquery in a FROM clause
***/

-- What's the average price of an order including freight?

SELECT AVG(OrderTotal)
FROM(
	SELECT 
		od.OrderId,
		SUM(od.UnitPrice * od.Quantity) + o.Freight AS OrderTotal
	FROM Order_Details od
	JOIN Orders o USING(OrderId)
	GROUP BY od.OrderId
) AS OrderTotals;

-- Notice the AS keyword at the end of the FROM clause.
-- The table we've created needs a name in this case.


/***
Subquery in a SELECT clause
***/

-- How many customers are there per employee?

SELECT (SELECT COUNT(DISTINCT CustomerId) FROM Customers) / (SELECT COUNT(DISTINCT EmployeeId) FROM Employees);


/*****************
Common Table Expression (CTE)
*****************/

/*
Common Table Expressions (CTEs) allow you to create temporary result sets, which can be referenced within another SQL statement.
They are particularly useful for breaking down complex queries into simpler, more readable components, 
and can be thought of as an extension to subqueries, providing more flexibility and readability.

When to use CTEs instead of subqueries
1. Can improve readability when subqueries get too complex. 
2. If you need to refer to to query multiple times, saves running it multiple times.
3. CTE's can be recurvise, subqueries cannot. *Recursion is an advanced SQL skill that we won't cover here* 
*/
 
-- Let's start with a very simple example so you can see the structure of a CTE

WITH OrdersGreaterThanTen AS (
	SELECT 
		OrderId,
        SUM(Quantity)
	FROM Order_Details
    GROUP BY OrderId
    HAVING SUM(Quantity) > 10
    ORDER BY SUM(Quantity) DESC
)
SELECT *
FROM OrdersGreaterThanTen;


-- Now let's look at a more complicated example where a CTE might be useful
-- What's the highest order value per day?

WITH OrderValues AS (
	SELECT
		DATE(o.OrderDate) AS OrderDate,
		od.OrderId,
        SUM(od.UnitPrice * od.Quantity) AS OrderValue
	FROM Order_Details od
	JOIN Orders o USING (OrderId)
    GROUP BY DATE(o.OrderDate), od.OrderId
)
SELECT 
	OrderDate, 
    MAX(OrderValue)
FROM OrderValues
GROUP BY OrderDate;


-- You can use multiple CTEs 
-- And they can even be used in conjunction with subqueries

-- Here we'll answer the same question as in Subqueries, Having
-- Find all the countries that have a total freight cost higher than that of Germany

WITH TotalFreightByCountry AS (
    SELECT 
        ShipCountry, 
        SUM(Freight) AS TotalFreight
    FROM
        Orders 
    GROUP BY ShipCountry
),
FreightSumGermany AS (
    SELECT SUM(Freight) AS TotalFreightGermany
    FROM Orders
    WHERE ShipCountry = 'Germany'
)
SELECT 
    ShipCountry, 
    TotalFreight
FROM 
    TotalFreightByCountry
WHERE 
    TotalFreight > (SELECT TotalFreightGermany FROM FreightSumGermany)
ORDER BY 
    TotalFreight DESC;

/*
You're now starting to see how complicated SQL queries can become.
This isn't always an advantage.
Sometimes it's better to abstract some of that complexity away, and make things more manageable.
This is where Temporary Tables can help.
*/

/*****************
Temporary Tables
*****************/


/*
Temporary tables in SQL are a type of table that you can create and use to store intermediate results. 
Just like subqueries and CTEs, they can simplify complex queries, improve readability, and offer performance benefits, 
but unlike them, temporary tables persist for the duration of the session, allowing reuse across multiple queries or procedures.
*/

-- A word of warning, temporary tables cannot be used more than once in the same query!


-- Let's anwer the same question again. This time using temporary tables
-- Find all the countries that have a total freight cost higher than that of Germany

CREATE TEMPORARY TABLE TotalFreightByCountry (
    SELECT 
        ShipCountry, 
        SUM(Freight) AS TotalFreight
    FROM
        Orders 
    GROUP BY ShipCountry
);

-- you can view the temporary table you've made
SELECT * 
FROM TotalFreightByCountry;

CREATE TEMPORARY TABLE FreightSumGermany (
    SELECT SUM(Freight) AS TotalFreightGermany
    FROM Orders
    WHERE ShipCountry = 'Germany'
);

SELECT 
    Country, 
    TotalFreight
FROM 
    TotalFreightByCountry
WHERE 
    TotalFreight > (SELECT TotalFreightGermany FROM FreightSumGermany)
ORDER BY 
    TotalFreight DESC;

    
-- We can also use these temporary tables in different queries
-- Something we can't do with subqueries and CTEs

SELECT SUM(TotalFreight) AS GlobalFreight
FROM TotalFreightByCountry;


-- Let's solve another problem with temporary tables
-- What's the highest order value per day?

CREATE TEMPORARY TABLE OrderValues (
	SELECT
		DATE(o.OrderDate) AS OrderDate,
		od.OrderId,
        SUM(od.UnitPrice * od.Quantity) AS OrderValue
	FROM Order_Details od
	JOIN Orders o USING (OrderId)
    GROUP BY DATE(o.OrderDate), od.OrderId
);

SELECT 
	OrderDate, 
    MAX(OrderValue)
FROM OrderValues
GROUP BY OrderDate;

-- Again, we can then use the table for other queries too

SELECT 
	OrderDate, 
    MIN(OrderValue)
FROM OrderValues
GROUP BY OrderDate;

SELECT 
	OrderDate, 
    AVG(OrderValue)
FROM OrderValues
GROUP BY OrderDate;