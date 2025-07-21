CREATE TABLE Products (
  product_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100),
  category VARCHAR(50),
  price DECIMAL(10,2),
  supplier_id INT,
  FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id)
);
 

SELECT 
    p.category,
    p.name AS product_name,
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    SUM(od.quantity * od.unit_price) AS total_sales
FROM OrderDetails od
JOIN Orders o ON od.order_id = o.order_id
JOIN Products p ON od.product_id = p.product_id
GROUP BY p.category, p.name, month;


SELECT 
    w.name AS warehouse,
    p.name AS product,
    s.quantity
FROM Stock s
JOIN Warehouses w ON s.warehouse_id = w.warehouse_id
JOIN Products p ON s.product_id = p.product_id;
  

SELECT 
    s.name AS supplier,
    COUNT(p.product_id) AS products_supplied
FROM Suppliers s
JOIN Products p ON s.supplier_id = p.supplier_id
GROUP BY s.name;



-- Low stock alert trigger
CREATE TRIGGER check_stock
AFTER INSERT ON OrderDetails
FOR EACH ROW
BEGIN
  UPDATE Stock
  SET quantity = quantity - NEW.quantity
  WHERE product_id = NEW.product_id;

  IF (SELECT quantity FROM Stock WHERE product_id = NEW.product_id) < 10 THEN
    INSERT INTO LowStockAlerts (product_id, alert_date) VALUES (NEW.product_id, NOW());
  END IF;
END;



DELIMITER $$
CREATE PROCEDURE TransferStock(
  IN productId INT,
  IN fromWarehouse INT,
  IN toWarehouse INT,
  IN qty INT
)
BEGIN
  UPDATE Stock SET quantity = quantity - qty
  WHERE warehouse_id = fromWarehouse AND product_id = productId;

  UPDATE Stock SET quantity = quantity + qty
  WHERE warehouse_id = toWarehouse AND product_id = productId;
END$$
DELIMITER ;



-- Sales Dashboard
CREATE VIEW SalesDashboard AS
SELECT p.name AS product, SUM(od.quantity) AS units_sold, SUM(od.unit_price * od.quantity) AS revenue
FROM OrderDetails od
JOIN Products p ON od.product_id = p.product_id
GROUP BY p.name;

-- Reorder Report
CREATE VIEW ReorderReport AS
SELECT p.name, s.quantity
FROM Stock s
JOIN Products p ON s.product_id = p.product_id
WHERE s.quantity < 20;


CREATE INDEX idx_product_id ON Products(product_id);
CREATE INDEX idx_order_id ON Orders(order_id);
