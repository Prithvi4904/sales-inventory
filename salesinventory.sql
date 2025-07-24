-- CREATE TABLES
CREATE TABLE Suppliers (
  supplier_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  contact_email VARCHAR(100)
);

CREATE TABLE Products (
  product_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100),
  category VARCHAR(50),
  price DECIMAL(10,2),
  supplier_id INT,
  FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id)
);

CREATE TABLE Warehouses (
  warehouse_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100),
  location VARCHAR(100)
);

CREATE TABLE Stock (
  stock_id INT PRIMARY KEY AUTO_INCREMENT,
  product_id INT,
  warehouse_id INT,
  quantity INT,
  FOREIGN KEY (product_id) REFERENCES Products(product_id),
  FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id)
);

CREATE TABLE Orders (
  order_id INT PRIMARY KEY AUTO_INCREMENT,
  order_date DATE
);

CREATE TABLE OrderDetails (
  order_detail_id INT PRIMARY KEY AUTO_INCREMENT,
  order_id INT,
  product_id INT,
  quantity INT,
  unit_price DECIMAL(10, 2),
  FOREIGN KEY (order_id) REFERENCES Orders(order_id),
  FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

CREATE TABLE LowStockAlerts (
  alert_id INT PRIMARY KEY AUTO_INCREMENT,
  product_id INT,
  alert_date DATETIME,
  FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- VIEWS

-- Sales Dashboard View
CREATE VIEW SalesDashboard AS
SELECT 
  p.name AS product, 
  SUM(od.quantity) AS units_sold, 
  SUM(od.unit_price * od.quantity) AS revenue
FROM OrderDetails od
JOIN Products p ON od.product_id = p.product_id
GROUP BY p.name;

-- Reorder Report View
CREATE VIEW ReorderReport AS
SELECT 
  p.name, 
  s.quantity
FROM Stock s
JOIN Products p ON s.product_id = p.product_id
WHERE s.quantity < 20;

-- QUERIES

-- Monthly Sales by Product
SELECT 
    p.category,
    p.name AS product_name,
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    SUM(od.quantity * od.unit_price) AS total_sales
FROM OrderDetails od
JOIN Orders o ON od.order_id = o.order_id
JOIN Products p ON od.product_id = p.product_id
GROUP BY p.category, p.name, month;

-- Product stock by warehouse
SELECT 
    w.name AS warehouse,
    p.name AS product,
    s.quantity
FROM Stock s
JOIN Warehouses w ON s.warehouse_id = w.warehouse_id
JOIN Products p ON s.product_id = p.product_id;

-- Products supplied by each supplier
SELECT 
    s.name AS supplier,
    COUNT(p.product_id) AS products_supplied
FROM Suppliers s
JOIN Products p ON s.supplier_id = p.supplier_id
GROUP BY s.name;

-- TRIGGERS

DELIMITER $$

CREATE TRIGGER check_stock
AFTER INSERT ON OrderDetails
FOR EACH ROW
BEGIN
  -- Reduce stock
  UPDATE Stock
  SET quantity = quantity - NEW.quantity
  WHERE product_id = NEW.product_id;

  -- Alert if stock < 10
  IF (SELECT quantity FROM Stock WHERE product_id = NEW.product_id LIMIT 1) < 10 THEN
    INSERT INTO LowStockAlerts (product_id, alert_date) 
    VALUES (NEW.product_id, NOW());
  END IF;
END$$

DELIMITER ;

-- PROCEDURE

DELIMITER $$

CREATE PROCEDURE TransferStock(
  IN productId INT,
  IN fromWarehouse INT,
  IN toWarehouse INT,
  IN qty INT
)
BEGIN
  UPDATE Stock 
  SET quantity = quantity - qty
  WHERE warehouse_id = fromWarehouse AND product_id = productId;

  UPDATE Stock 
  SET quantity = quantity + qty
  WHERE warehouse_id = toWarehouse AND product_id = productId;
END$$

DELIMITER ;

-- INDEXES

CREATE INDEX idx_product_id ON Products(product_id);
CREATE INDEX idx_order_id ON Orders(order_id);
CREATE INDEX idx_supplier_id ON Products(supplier_id);
CREATE INDEX idx_warehouse_id ON Stock(warehouse_id);
