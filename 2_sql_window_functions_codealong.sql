USE Northwind;


-- For this codealong we'll need to use details from both orders and order_details
-- To save us using  a JOIN in every query, we'll first create a temporary table that JOINs orders and order_details

CREATE TEMPORARY TABLE OrdersAndDetails (
SELECT 
	*
FROM
	Orders o 
	LEFT JOIN 
		Order_Details od USING (OrderId)
);

SELECT *
FROM OrdersAndDetails;


/*****************
Aggregate Window Functions
*****************/

/*
SUM()
*/

-- Here's a normal query using a SUM() aggregate function
-- Note that when we aggreagte we must also GROUP BY
-- This GROUPing causes us to lose a lot of detail in the table as it compresses rows together

SELECT
	OrderId,
    SUM(Quantity) AS OrderQuantityTotal
FROM
	OrdersAndDetails
GROUP BY OrderId;


-- By using a window function, we can use an aggregate and keep all of the rows in the table 

SELECT 
	OrderDate,
    ShipCountry,
	OrderId,
    ProductId,
    UnitPrice,
    Quantity,
	SUM(Quantity) OVER (PARTITION BY OrderId) AS OrderQuantityTotal
FROM OrdersAndDetails;


-- Above is a window function using the PARTITION definition
-- A partition definition GROUPs your data based on the given field

-- We can also use an ORDER definition
-- This will GROUP the data for the aggregate by the ORDER of the given field
-- Here's an example

SELECT 
	OrderDate,
    ShipCountry,
	OrderId,
    ProductId,
    UnitPrice,
    Quantity,
	SUM(Quantity) OVER (ORDER BY OrderDate) AS CumulativeDailyQuantity
FROM OrdersAndDetails;

-- You can see in the output that the sum is automatically grouped by the OrderDate that we used in ORDER BY.


-- It is also possible to order from highest to lowest by using DESC
SELECT 
	OrderDate,
    ShipCountry,
	OrderId,
    ProductId,
    UnitPrice,
    Quantity,
	SUM(Quantity) OVER (ORDER BY OrderDate DESC) AS ReverseCumulativeDailyQuantity
FROM OrdersAndDetails;


-- And it is possible to use both PARTITION and ORDER definitions in the same window function

SELECT 
	OrderDate,
    ShipCountry,
	OrderId,
    ProductId,
    UnitPrice,
    Quantity,
	SUM(Quantity) OVER (PARTITION BY ShipCountry ORDER BY OrderDate) AS CumulativeDailyQuantityByCountry
FROM OrdersAndDetails;

-- Now we have the cumulative daily quantity divided by the ShippingCountry


-- It's also possible to use more than 1 window function in a single SQL query

SELECT 
	OrderDate,
    ShipCountry,
	OrderId,
    ProductId,
    UnitPrice,
    Quantity,
    SUM(Quantity) OVER (PARTITION BY OrderId) AS OrderQuantityTotal,
	SUM(Quantity) OVER (PARTITION BY ShipCountry ORDER BY OrderDate) AS CumulativeDailyQuantityByCountry
FROM OrdersAndDetails;


-- Now that you've seen how window functions work with the SUM() aggregate,
-- let's see a few more examples with different aggregates

/*
AVG()
*/

SELECT 
	OrderDate,
    ShipCountry,
	OrderId,
    ProductId,
    UnitPrice,
    Quantity,
    AVG(UnitPrice) OVER (PARTITION BY OrderId) AS OrderAverageUnitPrice
FROM OrdersAndDetails;


/*
COUNT()
*/

SELECT 
	OrderDate,
    ShipCountry,
	OrderId,
    ProductId,
    UnitPrice,
    Quantity,
    COUNT(ProductId) OVER (PARTITION BY OrderId) AS NumberOfDifferentProductsInOrder
FROM OrdersAndDetails;


-- Most aggregate functions can be used as window functions


/*****************
Non-aggregate Window Functions
*****************/

-- Window functions go beyond just aggregates
-- They also have they're own special functions

/***
Ranking Window Functions
***/

-- Here we will look at the ranking functions that are available

/*
ROW_NUMBER()
*/

-- This one is exactly as it sounds, it will give each row a number
-- The first row will be 1, the second 2, the third 3, and so on and so forth

SELECT 
	OrderDate,
    ShipCountry,
	OrderId,
    ProductId,
    UnitPrice,
    Quantity,
    ROW_NUMBER() OVER (ORDER BY OrderDate) AS RowNumber
FROM OrdersAndDetails;


-- It also works with PARTITION definitions

SELECT 
	OrderDate,
    ShipCountry,
	OrderId,
    ProductId,
    UnitPrice,
    Quantity,
    ROW_NUMBER() OVER (PARTITION BY ShipCountry ORDER BY OrderDate) AS RowNumber
FROM OrdersAndDetails;

-- Note how the row numbers start again for each PARTITION


/*
RANK()
*/

-- This one gives each row a rank based on the order
-- If two rows are the same according to the order they will get the same rank
-- i.e. If 4 rows have the same value, they could be in joint in the rankings. E.g. joint 3rd place
-- This is useful if you want a top 10 cities, and LIMIT would cut off the 11th city, even if it had the exact same score as row 10

SELECT 
	OrderDate,
    ShipCountry,
	OrderId,
    ProductId,
    UnitPrice,
    Quantity,
    RANK() OVER (ORDER BY OrderDate) AS Rank_
FROM OrdersAndDetails;

-- Note that after certain rows are joint in the RANKing a few numbers a skipped
-- If there are 3 rows in joint 1st place, RANK still sees row 4 as being in 4th place
-- In this case, it could be argued that row 4 is actually in 2nd place --> this is when we use DENSE_RANK


/*
DENSE_RANK()
*/

-- DENSE_RANK is similar to RANK, but it deals with the idea of joint positions differently
-- For example, if the first 2 rows are joint 1st place and the 3rd row then follows behind
-- RANK would rank these rows first, first, third
-- DENSE_RANK would rank them first, first, second
-- Depending on your use case, depends on which one is more suitable

SELECT 
	OrderDate,
    ShipCountry,
	OrderId,
    ProductId,
    UnitPrice,
    Quantity,
    DENSE_RANK() OVER (ORDER BY OrderDate) AS row_num
FROM OrdersAndDetails;


/********
LAG and LEAD
*********/

-- These 2 functions work the same way but in opposite directions
-- Lag shows you a particular row before the selected one
-- Lead shows you rows after the selected one

-- Let's see how this works and why it's useful with a few examples

-- First, let's look at the daily sales

SELECT 
	OrderDate,
	SUM(UnitPrice * Quantity) AS DailySales
FROM OrdersAndDetails
GROUP BY OrderDate;


-- LAG allows us to create an extra column showing the vaue of the previous row

SELECT 
	OrderDate,
	SUM(UnitPrice * Quantity) AS DailySales,
    LAG(SUM(UnitPrice * Quantity)) OVER (ORDER BY SUM(UnitPrice * Quantity)) AS PreviousDaysSales
FROM OrdersAndDetails
GROUP BY OrderDate;


-- This is useful to then compare days, quarters, years, or any other comparison you wish to make

SELECT 
	OrderDate,
	SUM(UnitPrice * Quantity) AS DailySales,
    LAG(SUM(UnitPrice * Quantity)) OVER (ORDER BY SUM(UnitPrice * Quantity)) AS PreviousDaysSales,
    ROUND(SUM(UnitPrice * Quantity) - LAG(SUM(UnitPrice * Quantity)) OVER (ORDER BY SUM(UnitPrice * Quantity)), 2) AS Difference
FROM OrdersAndDetails
GROUP BY OrderDate;


-- LEAD, instead of giving you the previous row, gives you the next row

SELECT 
	OrderDate,
	SUM(UnitPrice * Quantity) AS DailySales,
    LEAD(SUM(UnitPrice * Quantity)) OVER (ORDER BY SUM(UnitPrice * Quantity)) AS PreviousDaysSales
FROM OrdersAndDetails
GROUP BY OrderDate;

-- Again, useful for comparisons


-- There are other non-aggregate window functions, check out the MySQL documentation 
-- https://dev.mysql.com/doc/refman/8.0/en/window-function-descriptions.html