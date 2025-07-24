-- Create Database
CREATE DATABASE finance_tracker;
USE finance_tracker;

-- Users Table
CREATE TABLE Users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL
);

-- Categories Table
CREATE TABLE Categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  category_name VARCHAR(50) NOT NULL
);

-- Income Table
CREATE TABLE Income (
  income_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  source VARCHAR(100),
  income_date DATE NOT NULL,
  FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- Expenses Table
CREATE TABLE Expenses (
  expense_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  category_id INT,
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  expense_date DATE NOT NULL,
  description TEXT,
  FOREIGN KEY (user_id) REFERENCES Users(user_id),
  FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);

-- Sample Users
INSERT INTO Users (name, email)
VALUES 
  ('Alice', 'alice@example.com'), 
  ('Bob', 'bob@example.com');

-- Sample Categories
INSERT INTO Categories (category_name)
VALUES 
  ('Food'), 
  ('Transport'), 
  ('Bills'), 
  ('Entertainment');

-- Sample Income
INSERT INTO Income (user_id, amount, source, income_date)
VALUES 
  (1, 5000.00, 'Salary', '2025-07-01'),
  (2, 4500.00, 'Freelancing', '2025-07-05');

-- Sample Expenses
INSERT INTO Expenses (user_id, category_id, amount, expense_date, description)
VALUES
  (1, 1, 200.00, '2025-07-02', 'Groceries'),
  (1, 2, 50.00, '2025-07-03', 'Bus fare'),
  (1, 3, 100.00, '2025-07-04', 'Electricity bill'),
  (2, 4, 150.00, '2025-07-06', 'Movie night');

-- Monthly Expense Summary by User
SELECT 
    user_id,
    DATE_FORMAT(expense_date, '%Y-%m') AS month,
    SUM(amount) AS total_expense
FROM Expenses
GROUP BY user_id, month;

-- Total Spent by Category per User
SELECT 
    e.user_id,
    c.category_name,
    SUM(e.amount) AS total_spent
FROM Expenses e
JOIN Categories c ON e.category_id = c.category_id
GROUP BY e.user_id, c.category_name;

-- Create View: Total Income per User
CREATE VIEW TotalIncome AS
SELECT 
  user_id, 
  SUM(amount) AS income
FROM Income
GROUP BY user_id;

-- Create View: Total Expenses per User
CREATE VIEW TotalExpenses AS
SELECT 
  user_id, 
  SUM(amount) AS expense
FROM Expenses
GROUP BY user_id;

-- Create View: User Balance (Income - Expenses)
CREATE VIEW UserBalance AS
SELECT 
    i.user_id,
    i.income,
    IFNULL(e.expense, 0) AS expense,
    (i.income - IFNULL(e.expense, 0)) AS balance
FROM TotalIncome i
LEFT JOIN TotalExpenses e ON i.user_id = e.user_id;
