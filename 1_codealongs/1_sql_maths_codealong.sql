/**********************************
SQL MATHS
*********************************/


/*****
Arithmetic
*****/


-- Plus
SELECT 10 + 5;


-- Minus
SELECT 10 - 5;


-- Multiply
SELECT 10 * 5;


-- Divide
SELECT 10 / 5;


-- Modulus
SELECT 10 % 5.5;


-- Let's see how this can be used on a dataset

USE northwind;


-- Find the difference between the highest and lowest unit prices.
SELECT 
    MAX(unitprice) - MIN(unitprice) AS RangeOfPrices
FROM
    products;


-- Calculate the total price of products for each order.
SELECT 
    orderid, 
    SUM(quantity * unitprice) AS TotalPrice
FROM
    order_details
GROUP BY orderid;


-- Find products with even quantities in stock.
SELECT 
    productname,
    unitsinstock
FROM
    products
WHERE
    unitsinstock % 2 = 0;


/*****
Math Functions
*****/


-- ABS(): Returns the absolute value of a number.
SELECT ABS(-2);


-- CEIL(): Returns the smallest integer value not less than the argument.
SELECT CEIL(5.2);


-- FLOOR(): Returns the largest integer value not greater than the argument.
SELECT FLOOR(6.9);


-- POW(): Returns the argument raised to the specified power.
SELECT POW(10, 2);


-- ROUND(): Rounds a number to a specified number of decimal places.
SELECT ROUND(3.141592653, 3);


-- Let's see how this can be used on a dataset


-- Round up the unit price to the nearest whole number for each product in the 'products' table.
SELECT 
    productid, 
    productname, 
    CEIL(unitprice) AS RoundedUpPrice
FROM
    products;


-- Round down the unit price to the nearest whole number for each product in the 'products' table.
SELECT 
    productid, 
    productname, 
    FLOOR(unitprice) AS RoundedDownPrice
FROM
    products;


-- Round the unit price to one decimal place for each product in the 'products' table.
SELECT 
    ProductID, 
    ProductName, 
    ROUND(UnitPrice, 1) AS RoundedPrice
FROM
    products;