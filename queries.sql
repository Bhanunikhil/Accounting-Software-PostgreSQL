-- Creation of tables start
CREATE TABLE users (
    user_id INT PRIMARY KEY NOT NULL,
    user_password VARCHAR(20) NOT NULL,
    user_role INT NOT NULL
);
CREATE TABLE customers (
    customer_id INT PRIMARY KEY NOT NULL,
    customer_name VARCHAR NOT NULL,
	customer_ph varchar(13),
    email_id VARCHAR(50),
    address VARCHAR
);
CREATE TABLE vendors (
    vendor_id INT PRIMARY KEY NOT NULL,
    vendor_name VARCHAR NOT NULL,
	vendor_ph varchar(13),
    email_id VARCHAR(50),
    address VARCHAR 
);
CREATE TABLE general_ledger (
    account_id INT PRIMARY KEY NOT NULL,
    account_name VARCHAR(20) NOT NULL,
    account_type int NOT NULL,
    balance FLOAT
);
CREATE TABLE items (
    item_id INT PRIMARY KEY NOT NULL,
    name VARCHAR(30) NOT NULL,
    tax FLOAT,
    quantity INT NOT NULL,
	price FLOAT
);
CREATE TABLE invoices (
    invoice_id INT PRIMARY KEY NOT NULL,
    date DATE NOT NULL,
    total FLOAT NOT NULL,
    shipping_address VARCHAR,
    tax FLOAT,
    customer_id INT,
    account_id INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (account_id) REFERENCES general_ledger(account_id)
);
CREATE TABLE bills (
    bill_id INT PRIMARY KEY NOT NULL,
    date DATE NOT NULL,
    total FLOAT NOT NULL,
    tax FLOAT,
    vendor_id INT,
    account_id INT,
    FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id),
    FOREIGN KEY (account_id) REFERENCES general_ledger(account_id)
);
CREATE TABLE expenses (
    expense_id INT PRIMARY KEY NOT NULL,
    date DATE NOT NULL,
    total FLOAT NOT NULL,
    tax FLOAT,
    customer_id INT,
    account_id INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (account_id) REFERENCES general_ledger(account_id)
);

CREATE TABLE invoice_items (
    invoice_id INT NOT NULL,
    item_id INT NOT NULL, -- Reference to Items table 
    quantity INT NOT NULL,
    tax FLOAT,
    total FLOAT NOT NULL,
	   PRIMARY KEY (invoice_id, item_id),
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id) on DELETE CASCADE on UPDATE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(item_id) -- Added foreign key constraint
);
CREATE TABLE bill_items (
    bill_id INT NOT NULL,
    item_id INT NOT NULL, -- Reference to Items table
    quantity INT,
    tax FLOAT,
    total FLOAT NOT NULL,
    PRIMARY KEY (bill_id, item_id),
    FOREIGN KEY (bill_id) REFERENCES bills(bill_id) on DELETE CASCADE on UPDATE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(item_id) -- Added foreign key constraint
);
CREATE TABLE expense_items (
    expense_id INT NOT NULL,
    item_id INT NOT NULL, -- Reference to Items table
    quantity INT,
    tax FLOAT,
    total FLOAT NOT NULL,
	PRIMARY KEY (expense_id, item_id),
    FOREIGN KEY (expense_id) REFERENCES expenses(expense_id) on DELETE CASCADE on UPDATE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(item_id)
	);

CREATE TABLE payments (
    payment_id INT PRIMARY KEY NOT NULL,
    amount FLOAT NOT NULL,
    date DATE NOT NULL,
    customer_id INT,
    vendor_id INT,
    invoice_id INT,
    bill_id INT,
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id) on DELETE CASCADE on UPDATE CASCADE,
    FOREIGN KEY (bill_id) REFERENCES bills(bill_id) on DELETE CASCADE on UPDATE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id)
);
-- Creation of tables end

-- Copying data from csv files start here
COPY public.customers FROM 'E:\home\DMQL\Project\data_files\customers.csv' DELIMITER ',' CSV HEADER;
select *from customers;

COPY public.vendors FROM 'E:\home\DMQL\Project\data_files\vendors.csv' DELIMITER ',' CSV HEADER;
select *from vendors;

COPY public.items FROM 'E:\home\DMQL\Project\data_files\items.csv' DELIMITER ',' CSV HEADER;
select *from items;

COPY public.general_ledger FROM 'E:\home\DMQL\Project\data_files\general_ledger.csv' DELIMITER ',' CSV HEADER;
select *from general_ledger;

COPY public.invoices FROM 'E:\home\DMQL\Project\data_files\invoices.csv' DELIMITER ',' CSV HEADER;
select * from invoices;

COPY public.bills FROM 'E:\home\DMQL\Project\data_files\bills.csv' DELIMITER ',' CSV HEADER;
select * from bills;

COPY public.bill_items FROM 'E:\home\DMQL\Project\data_files\bill_items.csv' DELIMITER ',' CSV HEADER;
select * from bill_items;

COPY public.invoice_items FROM 'E:\home\DMQL\Project\data_files\invoice_items.csv' DELIMITER ',' CSV HEADER;
select * from invoice_items;

COPY public.payments FROM 'E:\home\DMQL\Project\data_files\payments.csv' DELIMITER ',' CSV HEADER;
select * from payments;

-- Copying of files to databse ends

-- Creation of triggers tart
-- Triggers for updating general ledger
CREATE OR REPLACE FUNCTION update_balance_after_invoice_insert()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE general_ledger
    SET balance = balance + NEW.total
    WHERE account_id = NEW.account_id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_balance_after_invoice_insert
AFTER INSERT ON invoices
FOR EACH ROW
EXECUTE PROCEDURE update_balance_after_invoice_insert();

--trigger for bills and general ledger
CREATE OR REPLACE FUNCTION update_balance_after_bills_insert()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE general_ledger
    SET balance = balance + NEW.total
    WHERE account_id = NEW.account_id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_balance_after_bills_insert
AFTER INSERT ON bills
FOR EACH ROW
EXECUTE PROCEDURE update_balance_after_bills_insert();

CREATE OR REPLACE FUNCTION update_balance_after_expenses_insert()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE general_ledger
    SET balance = balance + NEW.total
    WHERE account_id = NEW.account_id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_balance_after_expenses_insert
AFTER INSERT ON expenses
FOR EACH ROW
EXECUTE PROCEDURE update_balance_after_expenses_insert();

-- Triggers for updating the items quantity in item table after issuing invoices or receiving bills
CREATE OR REPLACE FUNCTION check_and_update_item_quantity_for_invoice()
RETURNS TRIGGER AS $$
DECLARE
    item_quantity INT;
BEGIN
    SELECT quantity INTO item_quantity
    FROM items
    WHERE item_id = NEW.item_id;

    IF item_quantity < NEW.quantity THEN
        RAISE EXCEPTION 'Error: Insufficient item quantity for item_id: %.', NEW.item_id;
    ELSE
        UPDATE items
        SET quantity = quantity - NEW.quantity
        WHERE item_id = NEW.item_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_and_update_item_quantity_for_invoice
BEFORE INSERT ON invoice_items
FOR EACH ROW
EXECUTE PROCEDURE check_and_update_item_quantity_for_invoice();

CREATE OR REPLACE FUNCTION check_and_update_item_quantity_for_bill()
RETURNS TRIGGER AS $$
DECLARE
    item_quantity INT;
BEGIN
    SELECT quantity INTO item_quantity
    FROM items
    WHERE item_id = NEW.item_id;

    IF item_quantity < NEW.quantity THEN
        RAISE EXCEPTION 'Error: Insufficient item quantity for item_id: %.', NEW.item_id;
    ELSE
        UPDATE items
        SET quantity = quantity - NEW.quantity
        WHERE item_id = NEW.item_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_and_update_item_quantity_for_bill
BEFORE INSERT ON bill_items
FOR EACH ROW
EXECUTE PROCEDURE check_and_update_item_quantity_for_bill();

-- Creation of triggers end here

-- Manually inserting values into users table (User role - 0 for admin and 1 for normal users)
insert into users(user_id, user_password, user_role) values(1000, 1234, 0);
insert into users(user_id, user_password, user_role) values(1001, 1001, 1);
insert into users(user_id, user_password, user_role) values(1002, 1002, 1);

-- delete from invoices where invoice_id = 100;
-- select * from general_ledger;

---QUERIES:
--------------------------------
-- Selecting all the invoices along with the customer details of those invoices using left join
SELECT i.invoice_id, i.date, i.total, c.customer_name, c.email_id
FROM invoices i
LEFT JOIN customers c ON i.customer_id = c.customer_id
ORDER BY i.date DESC;


------------------------------------
-- To find the maximum invoice amount of each customer using grouby and max
SELECT c.customer_name, MAX(i.total) AS max_invoice_amount
FROM customers c
JOIN invoices i ON c.customer_id = i.customer_id
GROUP BY c.customer_name
ORDER BY max_invoice_amount DESC;

------------------------------------

-- For printing all the vendors and the bills they have issued using right join

SELECT v.vendor_name, b.bill_id, b.date, b.total
FROM vendors v
RIGHT JOIN bills b ON v.vendor_id = b.vendor_id
ORDER BY v.vendor_name, b.date;

------------------------------------
-- To calculate the total payments done to each vendor using sum and groupby;
SELECT v.vendor_name, SUM(p.amount) AS total_payments FROM vendors v
JOIN payments p ON v.vendor_id = p.vendor_id
GROUP BY v.vendor_name
ORDER BY total_payments DESC;

-- ------------------------------------
-- Finding the vendors with the all time highest total amount bill amount and their total billing amount.
SELECT v.vendor_id, v.vendor_name, 
       CASE WHEN total_billed IS NULL THEN 0 ELSE total_billed END AS total_billed
FROM (
    SELECT vendor_id, SUM(total) AS total_billed
    FROM bills
    GROUP BY vendor_id
) AS vendor_bills
RIGHT JOIN vendors v ON v.vendor_id = vendor_bills.vendor_id
ORDER BY total_billed DESC;

----------------------------------------
-- To find the details of the lastest bill for each vendor using subquery

SELECT v.vendor_name, b.bill_id, b.date, b.total
FROM vendors v
JOIN bills b ON v.vendor_id = b.vendor_id
WHERE b.date = (SELECT MAX(date) FROM bills b2 WHERE b2.vendor_id = v.vendor_id);

--------------------------------------
-- To find out which items are never added in any bill using a subquery with NOT EXISTS

SELECT it.name
FROM items it
WHERE NOT EXISTS (SELECT * FROM bill_items bi WHERE bi.item_id = it.item_id);

----------------------------------------
-- To find the total amount spend on each item in expenses:

SELECT i.name, SUM(ei.total) AS total_spent
FROM items i
JOIN expense_items ei ON i.item_id = ei.item_id
GROUP BY i.name;

-------------------------------------------
-- Finding the items that have been billed in both invoices and bills:

SELECT name
FROM items
WHERE item_id IN (SELECT item_id FROM bill_items)
AND item_id IN (SELECT item_id FROM invoice_items);

-------------------------------------------
-- Finding the vendors with the highest bill amount totally, and also their total billing amount: 
SELECT v.vendor_id, v.vendor_name, 
       CASE WHEN total_billed IS NULL THEN 0 ELSE total_billed END AS total_billed
FROM vendors v
LEFT JOIN (
    SELECT vendor_id, SUM(total) AS total_billed
    FROM bills
    GROUP BY vendor_id
) AS vendor_bills ON v.vendor_id = vendor_bills.vendor_id
ORDER BY total_billed DESC;

----------------------------------------------
-- -- Finding the items that was sold in highest total quantity in invoices:
SELECT i.item_id, i.name, 
       CASE WHEN total_quantity IS NULL THEN 0 ELSE total_quantity END AS total_quantity
FROM (
    SELECT item_id, SUM(quantity) AS total_quantity
    FROM invoice_items
    GROUP BY item_id
) AS item_quantities
RIGHT JOIN items i ON i.item_id = item_quantities.item_id
ORDER BY total_quantity DESC;
