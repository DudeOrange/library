-- представление, показывающее должников, отсортировано по убыванию кол-ва дней пока книга не возвращена

CREATE OR REPLACE TEMPORARY VIEW debtors as(
	SELECT 
		r.name as reader_name, 
		r.address, 
		r.phone_number, 
		b.name as book_name, 
		date_of_lend, 
		now()::date - date_of_lend as days_not_returned 
	FROM 
		lending l JOIN 
		readers r on l.id_reader = r.id JOIN 
		books b on l.id_book = b.id 
	WHERE 
		date_of_return is null
	ORDER BY 
		date_of_lend, 
		r.name);
							
SELECT * FROM debtors;


-- представление, показывающее читателя, который взял больше всего книг в библиотеке (и вернул). Отсортировано в порядке убывания количества книг

CREATE OR REPLACE TEMPORARY VIEW best_reader as(
	SELECT 
		name, 
		address, 
		phone_number, 
		count(date_of_lend) as lend_books_total, 
		count(date_of_return) as return_books_total  
	FROM 
		readers r JOIN 
		lending l on r.id = l.id_reader
	GROUP BY 
		1, 2, 3
	ORDER BY 
		4 DESC, 5 DESC, 1);

SELECT * FROM best_reader;

-- представление, показывающее автора, книги которого берут чаще всего

CREATE OR REPLACE TEMPORARY VIEW best_author as(
	SELECT 
		name, 
		biography, 
		count(date_of_lend)  
	FROM 
		authors a JOIN 
		books_authors ba on a.id = ba.id_author JOIN 
		lending l on ba.id_book = l.id_book
	GROUP BY 
		1, 2
	ORDER BY 
		3 DESC, 1);

SELECT * FROM best_author;

-- представление, показывающее книги, которые берут чаще всего

CREATE OR REPLACE TEMPORARY VIEW best_book as(
	SELECT 
		name, 
		publication_year, 
		volume, 
		annotation, 
		count(date_of_lend)  
	FROM 
		books b JOIN 
		lending l on b.id = l.id_book 
	GROUP BY 
		1, 2, 3, 4
	ORDER BY 
		5 DESC, 1, 2);

SELECT * FROM best_book;