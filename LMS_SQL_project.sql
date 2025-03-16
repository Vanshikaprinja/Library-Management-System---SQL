SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM return_status;


-- PROJECT TASK --
--Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books(isbn,book_title, category, rental_price, status, author, publisher)
VALUES
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

--Task 2: Update an Existing Member's Address
UPDATE members 
SET member_address = '125 Main St.'
WHERE member_id = 'C101';
SELECT * FROM members;

-- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE FROM issued_status
WHERE issued_id = 'IS1021';

--Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * FROM issued_status 
WHERE issued_emp_id = 'E101';


--Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT 
	issued_emp_id,
	count(issued_id) as total_book_issued
FROM issued_status
GROUP BY 1
HAVING COUNT(issued_id)> 1;

--Task 6: Create Summary Tables: 
--Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
CREATE TABLE book_count
AS
SELECT 
	b.isbn,
	b.book_title,
	COUNT(ist.issued_id) as no_issued
FROM books as b
JOIN issued_status as ist
on ist.issued_book_isbn = b.isbn
GROUP BY 1,2;

SELECT * FROM book_count;

--Task 7. Retrieve All Books in a Specific Category: 'Classic'
SELECT * FROM books
WHERE category = 'Classic';


--Task 8: Find Total Rental Income by Category:
SELECT
	b.category,
	SUM(b.rental_price)
FROM books as b
JOIN issued_status as ist
on ist.issued_book_isbn = b.isbn
GROUP BY 1;	

--Task 9: List Members Who Registered in the Last 180 Days:
SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';

--Task 10. Create a Table of Books with Rental Price Above a Certain Threshold $7:
CREATE TABLE book_above_7dollar
AS
SELECT * FROM books
WHERE rental_price > 7;

--Task 11: Retrieve the List of Books Not Yet Returned
SELECT 
	DISTINCT(ist.issued_book_name) 
FROM issued_status as ist
LEFT JOIN return_status as rs
ON
ist.issued_id = rs.issued_id
WHERE rs.return_id IS NULL;

--Task 12: Identify Members with Overdue Books
  --Write a query to identify members who have overdue books 
  --(assume a 30-day return period). 
  --Display the member's_id, member's name, book title, issue date, and days overdue.

SELECT 
	ist.issued_member_id,
	m.member_name,
	bk.book_title,
	ist.issued_date,
	rs.return_date,
	CURRENT_DATE - ist.issued_date as over_due_days
FROM issued_status as ist
JOIN
members as m
	ON 	m.member_id = ist.issued_member_id
JOIN
books as bk
	ON bk.isbn = ist.issued_book_isbn
LEFT JOIN
return_status as rs
	ON rs.issued_id = ist.issued_id
WHERE 
rs.return_date IS NULL
AND
(CURRENT_DATE - ist.issued_date) >30;


/*Task 13: Update Book Status on Return
Write a query to update the status of books 
in the books table to "Yes" when they are returned 
(based on entries in the return_status table).
*/
-- STORED PROCEDURE 


CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);
    
BEGIN
    -- all your logic and code
    -- inserting into returns based on users input
    INSERT INTO return_status(return_id, issued_id, return_date)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE);

    SELECT 
        issued_book_isbn,
        issued_book_name
        INTO
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
    
END;
$$


-- Testing FUNCTION add_return_records

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- calling function 
CALL add_return_records('RS138', 'IS135');

-- calling function 
CALL add_return_records('RS148', 'IS140');


-- Task 14: Branch Performance Report
/* Create a query that generates a performance report 
for each branch, showing the number of books issued, 
the number of books returned, 
and the total revenue generated from book rentals.
*/

CREATE TABLE branch_report_summary 
AS
SELECT 
	b.branch_id,
	b.manager_id,
	COUNT(ist.issued_id) as no_book_issued,
	COUNT(rs.return_id) as no_book_returned,
	SUM(bk.rental_price)as total_revenue
FROM 
issued_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON
e.branch_id = b.branch_id
LEFT JOIN
return_status as rs
ON
rs.issued_id = ist.issued_id
JOIN
books as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY 1,2;
sELECT * from branch_report_summary;


-- Task 15: CTAS: Create a Table of Active Members
/*Use the CREATE TABLE AS (CTAS) statement to create a new table 
active_members containing members 
who have issued at least one book in the last 12 months.
*/
CREATE TABLE active_member
AS
SELECT * from members
WHERE member_id IN(
SELECT DISTINCT issued_member_id 
	FROM issued_status
WHERE
	issued_date >= CURRENT_DATE - INTERVAL '12 month');
SELECT * FROM active_member;
	
-- Task 16: Find Employees with the Most Book Issues Processed
/*Write a query to find the top 3 employees
who have processed the most book issues. Display the 
employee name, number of books processed, and their branch.
*/

SELECT 
	e.emp_name,
	b.*,
	COUNT(ist.issued_id) as no_of_book_issued
FROM issued_status as ist
JOIN
Employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY 1,2;


-- Task 17: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. Description: Write a stored procedure that updates the status of a book in the library based on its issuance. The procedure should function as follows: The stored procedure should take the book_id as an input parameter. The procedure should first check if the book is available (status = 'yes'). If the book is available, it should be issued, and the status in the books table should be updated to 'no'. If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.

CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR (10), p_issued_memeber_id VARCHAR(30),p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
-- All the variable
	v_status VARCHAR(10);

BEGIN
	SELECT 
		status
		INTO
		v_status
	FROM books
	WHERE isbn = p_issued_book_isbn;

	
	IF v_status = 'Yes' THEN
		INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn , issued_emp_id)
		VALUES
		(p_issued_id , p_issued_memeber_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);
	
		RAISE NOTICE 'Book records added successfully for book isbn : %' , p_issued_book_isbn;
	ELSE
        RAISE NOTICE 'Sorry to inform you the book you have requested is unavailable book_isbn: %', p_issued_book_isbn;
    END IF;
END;
$$

-- Testing The function
SELECT * FROM books;
-- "978-0-553-29698-2" -- yes
-- "978-0-375-41398-8" -- no
SELECT * FROM issued_status;

CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');

SELECT * FROM books
WHERE isbn = '978-0-375-41398-8';



-- Task 18: Create Table As Select (CTAS) Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.
/*Description: Write a CTAS query to create a new table that lists each member and 
the books they have issued but not returned within 30 days. 
The table should include: The number of overdue books. 
The total fines, with each day's fine calculated at $0.50. The number of books issued by each member. 
The resulting table should show: Member ID Number of overdue books Total fines
*/
SELECT 
    ist.issued_member_id,
    m.member_name,
    COUNT(ist.issued_id) AS overdue_books,
    SUM(0.50 * (CURRENT_DATE - ist.issued_date - 30)) AS total_fines,
    (SELECT COUNT(*) FROM issued_status WHERE issued_member_id = ist.issued_member_id) AS total_books_issued
FROM issued_status AS ist
JOIN members AS m ON m.member_id = ist.issued_member_id
JOIN books AS bk ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL 
AND (CURRENT_DATE - ist.issued_date) > 30
GROUP BY ist.issued_member_id, m.member_name;






