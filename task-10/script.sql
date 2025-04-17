use presidio_sql;
-- DROP TABLES Customers,Products,Orders,OrderDetails;

-- Customers table
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Phone VARCHAR(20) NOT NULL
);

-- Products table
CREATE TABLE Products (
    ProductID INT PRIMARY KEY AUTO_INCREMENT,
    ProductName VARCHAR(100) NOT NULL,
    Category VARCHAR(50),
    Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    Stock INT NOT NULL CHECK (Stock >= 0)
);

-- Orders table
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL,
    Status VARCHAR(50) DEFAULT 'Pending',
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON DELETE CASCADE
);

-- OrderDetails table
CREATE TABLE OrderDetails (
    OrderDetailID INT PRIMARY KEY AUTO_INCREMENT,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
	Quantity INT NOT NULL CHECK (Quantity > 0),
    Price DECIMAL(10, 2) NOT NULL CHECK (Price >= 0),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE
);

INSERT INTO Customers (Name, Email, Phone)
VALUES 
('Nila S', 'nila@example.com', '9876543210'),
('Meera K', 'meera@example.com', '9123456789'),
('Thara Menon', 'thara@example.com', '9988776655'),
('Dhruv V', 'dhruv@example.com', '9001122334');

INSERT INTO Products (ProductName, Category, Price, Stock)
VALUES 
('Laptop', 'Electronics', 79999.99, 50),
('Mouse', 'Accessories', 1999.99, 30),
('Keyboard', 'Accessories', 8549.99, 100),
('Earbuds', 'Audio', 3499.99, 75);

INSERT INTO Orders (CustomerID, OrderDate)
VALUES 
(1, '2025-04-10'),
(2, '2025-04-11');

INSERT INTO OrderDetails (OrderID, ProductID, Quantity, Price)
VALUES 
(1, 1, 1, 79999.99),
(1, 3, 2, 8549.99),
(2, 2, 1, 1999.99);

SET PROFILING = 1;

SELECT o.OrderID, o.OrderDate, c.Name, p.ProductName, od.Quantity, od.Price
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE c.CustomerID = 1;

SHOW PROFILES;

SET PROFILING = 0;

EXPLAIN
SELECT o.OrderID, o.OrderDate, c.Name, p.ProductName, od.Quantity, od.Price
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE c.CustomerID = 1;

-- Indexes on foreign keys
CREATE INDEX idx_orders_customer_id ON Orders(CustomerID);
CREATE INDEX idx_orderdetails_order_id ON OrderDetails(OrderID);
CREATE INDEX idx_orderdetails_product_id ON OrderDetails(ProductID);

-- Index on product name (commonly searched field)
CREATE INDEX idx_products_name ON Products(ProductName);

SELECT ProductName, Stock FROM Products WHERE ProductID = 2;

DELIMITER //

CREATE TRIGGER trg_update_stock_after_order
AFTER INSERT ON OrderDetails
FOR EACH ROW
BEGIN
  UPDATE Products
  SET Stock = Stock - NEW.Quantity
  WHERE ProductID = NEW.ProductID;
END //

DELIMITER ;

INSERT INTO Orders (CustomerID, OrderDate)
VALUES (1, '2025-04-13');
SET @oid = LAST_INSERT_ID();

-- Insert into OrderDetails (this fires the trigger)
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, Price)
VALUES (@oid, 2, 2, 1999.99);

SELECT ProductName, Stock FROM Products WHERE ProductID = 4;

-- STORED PROCEDURE WITH TRIGGER
DELIMITER $$

CREATE PROCEDURE PlaceOrder(
    IN in_customer_id INT,
    IN in_product_id INT,
    IN in_quantity INT,
    IN in_price DECIMAL(10,2)
)
BEGIN
    DECLARE order_id INT;
    
    -- Error handler
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  
        SELECT 'SQL Error occurred. Transaction rolled back.' AS Message;
    END;

    -- Start transaction
    START TRANSACTION;

    INSERT INTO Orders (CustomerID, OrderDate)
    VALUES (in_customer_id, CURDATE());
    SET order_id = LAST_INSERT_ID();

    -- Insert into OrderDetails (trigger reduces stock)
    INSERT INTO OrderDetails (OrderID, ProductID, Quantity, Price)
    VALUES (order_id, in_product_id, in_quantity, in_price);
   
	COMMIT;

    SELECT 'Order placed successfully.' AS Message;
END$$

DELIMITER ;

CALL PlaceOrder(2,4,5,3499.99);

CALL PlaceOrder(2,4,95,3499.99);

CALL PlaceOrder(2,75,2,3499.99);

-- VIEW
CREATE VIEW OrderSummary AS
SELECT 
    o.OrderID,
    o.OrderDate,
    c.Name AS CustomerName,
    p.ProductName,
    od.Quantity,
    od.Price as UnitPrice,
    (od.Price * od.Quantity) as TotalPrice
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID;

SELECT * FROM OrderSummary WHERE CustomerName = 'Nila S';






