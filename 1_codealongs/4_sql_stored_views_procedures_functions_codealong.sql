USE Northwind;


/******************
Stored Views
******************/

/*
Stored Views are pre-written queries that you can save and reuse.
*/

-- Let's create a simple view that retrieves customer names and their corresponding contact
-- This view will allow us to query customer contacts easily.

CREATE VIEW CustomerContacts AS
SELECT 
	CustomerID, 
	ContactName, 
    ContactTitle
FROM 
	Customers;
 

-- Retrieve data from the view
SELECT * 
FROM CustomerContacts;

-- If you refresh the schemas on the left, you can also see your saved view there


-- Let's create a more complex view that combines data from multiple tables
-- This view provides extended order details

CREATE VIEW OrderDetailsExtended AS
SELECT 
	o.OrderID, 
    p.ProductName, 
    od.Quantity, 
    od.UnitPrice, 
    od.Quantity * od.UnitPrice AS TotalPrice
FROM Orders o
	JOIN Order_Details od USING(OrderID)
	JOIN Products p USING(ProductID);


-- Query the extended order details

SELECT * 
FROM OrderDetailsExtended;


-- Now create a filtered view named 'HighValueOrders'

CREATE VIEW HighValueOrders AS
SELECT 
	o.OrderID, 
    o.OrderDate, 
    od.Quantity * od.UnitPrice AS TotalValue
FROM Orders o
	JOIN Order_Details od USING (OrderID)
WHERE od.Quantity * od.UnitPrice > 1000;


-- Query the 'high_value_orders' view

SELECT * 
FROM HighValueOrders;


/******************
Stored Procedures
******************/

/*
Stored procedures are precompiled queries that can perform a variety of operations, 
including data retrieval, insertion, updating, and deletion, based on parameters passed to them. 
Unlike stored views, stored procedures can manipulate data within the database.
*/

-- Create a simple stored procedure that retrieves customer order history
-- This procedure allows us to get a summary of products ordered by a specific customer.

DELIMITER $$

CREATE PROCEDURE CustOrderHist (IN InputCustomerID VARCHAR(5))

BEGIN
    SELECT 
		ProductName, 
        SUM(Quantity) AS Total
    FROM Products
		JOIN Order_Details USING (ProductID)
		JOIN Orders USING (OrderID)
		JOIN Customers USING (CustomerID)
    WHERE Customers.CustomerID = InputCustomerID
    GROUP BY ProductName;
END $$

DELIMITER ;

-- Retrieve customer order history

CALL CustOrderHist('ALFAA');


-- Create another stored procedure that provides detailed order information
-- This procedure gives us detailed order information for a specific order

DELIMITER $$

CREATE PROCEDURE CustOrdersDetail (IN InputOrderID INT)

BEGIN
    SELECT 
		p.ProductName, 
        od.UnitPrice, 
        od.Quantity, 
        od.Discount * 100 AS Discount,
		ROUND(od.Quantity * (1 - od.Discount) * od.UnitPrice) AS ExtendedPrice
    FROM Products p
		JOIN Order_Details od USING (ProductID)
    WHERE od.OrderID = InputOrderID;
END $$

DELIMITER ;


-- Call the 'CustOrdersDetail' procedure

CALL CustOrdersDetail(10248);


/******************
Stored Functions
******************/

/*
Stored functions perform calculations or transformations within a query. 
They allow you to integrate custom logic directly into SQL statements, enhancing their readability and maintainability. 
Unlike stored procedures, stored functions focus solely on calculations and returning a single value
*/

-- This function calculates the age of an employee based on their birthdate

DELIMITER $$

CREATE FUNCTION GetEmployeeAge(InputEmployeeId INT)
RETURNS INT

NOT DETERMINISTIC
READS SQL DATA

BEGIN
    DECLARE birth_date DATE;
    DECLARE age INT;
    
    SELECT BirthDate INTO birth_date
    FROM Employees 
    WHERE EmployeeID = InputEmployeeId;
    
    SET age = TIMESTAMPDIFF(YEAR, birth_date, CURDATE());
    RETURN age;
END $$
DELIMITER ;


-- You can view the output of the function on a single emplyee using a SELECT clause.

SELECT GetEmployeeAge(5) AS EmployeeAge;


-- You can also use the Function as part of a broader query

SELECT 
	EmployeeId,
    FirstName,
    LastName,
    GetEmployeeAge(EmployeeId) AS Age
FROM
	Employees;
    
    
-- Let's look at another example    
-- This is a function to find the most recent order for a customer

DELIMITER $$

CREATE FUNCTION GetLatestOrder (InputCustomerId VARCHAR(5))
RETURNS INT

NOT DETERMINISTIC
READS SQL DATA

BEGIN
  DECLARE order_id INT;

  SELECT OrderID INTO order_id
  FROM Orders
  WHERE CustomerID = InputCustomerId
  ORDER BY OrderDate DESC
  LIMIT 1;

  RETURN order_id;
END $$

DELIMITER ;


-- Again, we can view a single query using SELECT

SELECT GetLatestOrder("ALFAA") AS LatestOrderNumber;


-- Or use it in a broader query

SELECT
	CustomerID,
    CompanyName,
    ContactName,
    Phone,
    GetLatestOrder(CustomerID) AS LatestOrderNumber
FROM
	Customers;