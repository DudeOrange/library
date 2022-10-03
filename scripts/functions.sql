-- функция добавляет автора в таблицу authors, возвращает добавленную строку

DROP FUNCTION IF EXISTS add_author;

CREATE OR REPLACE FUNCTION add_author (name varchar(50), biography text default NULL) 
	RETURNS TABLE(id int, name varchar, biography text) as $func$

	INSERT INTO 
		authors 
	VALUES 
		(default, $1, $2);

	SELECT * 
	FROM 
		authors 
	WHERE 
		authors.name = $1 AND 
		authors.biography = $2;
$func$ LANGUAGE sql;

SELECT * FROM add_author('Александр Сергеевич Пушкин', 'Великий русский поэт');



-- функция добавляет несколько авторов из массива в таблицу authors, возвращает добавленные строки

DROP FUNCTION IF EXISTS add_few_authors;

CREATE OR REPLACE FUNCTION add_few_authors (VARIADIC arr author[])
	RETURNS TABLE(id int, name varchar, biography text) as $$

	INSERT INTO 
		authors(name, biography) 
	SELECT 	
		fields.field1, 
		fields.field2 
	FROM 
		unnest(arr) as fields 
	RETURNING *;
$$ LANGUAGE sql;

SELECT * FROM add_few_authors(('Аркадий Натанович Стругацкий', 'Советский писатель-фантаст.'), ('Борис Натанович Стругацкий', 'Советский писатель-фантаст.'));



-- функция добавляет читателя в таблицу readers, возвращает добавленную строку

DROP FUNCTION IF EXISTS add_reader;

CREATE OR REPLACE FUNCTION add_reader (name varchar(50), address varchar(200), phone_number varchar(11)) 
	RETURNS TABLE(id int, name varchar, address varchar, phone_number varchar) as $$

	INSERT INTO 
		readers 
	VALUES 
		(default, $1, $2, $3);

	SELECT * 
	FROM 
		readers 
	WHERE 	
		readers.name = $1 AND 
		readers.address = $2 AND 
		readers.phone_number = $3;
$$ LANGUAGE sql;

SELECT * FROM add_reader('Александр Сергеевич Пупкин', 'г. Санкт-Петербург, ул. Джона Рида, д. 56, кв. 15', '89132946753');
SELECT * FROM add_reader('Александр Сергеевич Пушкин', 'г. Санкт-Петербург, с. Красное, ул. Рабочая, д. 12', '89111230695');



-- функция добавляет книгу в таблицу books, появляется связь с таблицей автора, возвращает добавленную строку

DROP FUNCTION IF EXISTS add_book;

CREATE OR REPLACE FUNCTION add_book (publication_year_v smallint, name_book_v varchar, number_of_books_v int, annotation_v text,
									name_author_v varchar, bio_v text, volume_v smallint default NULL) 
	RETURNS TABLE 	(id_b int, p_year smallint, n_book varchar, vol smallint, numb_of_books int, annot text,
					id_a int, n_author varchar, biog text) as $func$

	DECLARE 
		book_id int;
		author_id int;
	BEGIN
-- добавляем данные в таблицу books	
		INSERT INTO 
			books 
		VALUES 
			(default, $1, $2, $7, $3, $4) 
		RETURNING 
			id 
		INTO 
			book_id;

-- проверяем хранятся ли в базе данные об авторе книги и берем его id. Если нет, записываем новго автора в таблицу authors и заполняем таблицу связку books_authors
	IF 
		(SELECT 
			id 
		FROM 
			authors a 
		WHERE 
			a.name = $5 AND 
			a.biography = $6) is NOT NULL
	THEN 
		author_id := (	SELECT 
							id 
						FROM 
							authors a 
						WHERE 
							a.name = $5 AND 
							a.biography = $6);
		INSERT INTO 
			books_authors 
		VALUES 
			(author_id, book_id);
	ELSE
		INSERT INTO 
			authors 
		VALUES 
			(default, $5, $6) 
		RETURNING 
			id 
		INTO 
			author_id;

		INSERT INTO 
			books_authors 
		VALUES 
			(author_id, book_id);
	END IF;
	
	RETURN QUERY 
		SELECT 
			b.id as id_book, 
			publication_year, 
			b.name as name_book, 
			volume, number_of_books, 
			annotation, a.id as id_author, 
			a.name as name_author, 
			biography
		FROM 
			books b JOIN 
			books_authors ba on b.id = ba.id_book JOIN 
			authors a on ba.id_author = a.id 
		WHERE 
			b.publication_year = $1 AND 
			b.name = $2 AND 
			b.annotation = $4 AND 
			a.name = $5 AND 
			a.biography = $6;
	END
$func$ LANGUAGE plpgsql;

SELECT * FROM add_book(1999::smallint, 'Ночной дозор', 16, 'История светлого мага Антона Городецкого', 'Сергей Лукьяненко', 'Популярный фантаст');



-- функция добавляет книгу c несколькими авторами в таблицу books, если автор уже существует он берется из таблицы authors, либо он добавляется в таблицу, возвращает добавленные строки

DROP FUNCTION IF EXISTS add_books;

CREATE OR REPLACE FUNCTION add_books(publication_year_v smallint, name_book_v varchar, volume_v smallint, number_of_books_v int, annotation_v text, 
									VARIADIC arr author[]) 
	RETURNS TABLE  (id_b int, p_year smallint, n_book varchar, vol smallint, numb_of_books int, annot text,
					id_a int, n_author varchar, biog text) as $func$

	DECLARE 
		elem author;
		book_id int;
		author_id int;
		author_arr int[];
	BEGIN 	
--		книга добавляется одна, поэтому сразу запишем ее в таблицу и получим id
		INSERT INTO 
			books 
		VALUES 
			(default, $1, $2, $3, $4, $5) 
		RETURNING 
			id 
		INTO 
			book_id;
--		авторов несколько, поэтому обрабатываем каждого автора в цикле по отдельности, полученные id записываем в массив author_arr для последующего вывода	
		FOREACH elem in array arr
		LOOP
			IF 
				(SELECT 
					id 
				FROM 
					authors a 
				WHERE 
					a.name = elem.field1 AND 
					a.biography = elem.field2) is NOT NULL
			THEN 
				author_id := (	SELECT 
									id 
								FROM 
									authors a 
								WHERE 
									a.name = elem.field1 AND 
									a.biography = elem.field2);

				author_arr := array_append(author_arr, author_id);

				INSERT INTO 
					books_authors 
				VALUES 
					(author_id, book_id);
			ELSE
				INSERT INTO 
					authors 
				VALUES 
					(default, elem.field1, elem.field2) 
				RETURNING 
					id 
				INTO 
					author_id;

				author_arr := array_append(author_arr, author_id);

				INSERT INTO 
					books_authors 
				VALUES 
					(author_id, book_id);
			END IF;
		END LOOP;

		RETURN QUERY 
			SELECT 
				b.id as id_book, 
				publication_year, 
				b.name as name_book, 
				volume, 
				number_of_books, 
				annotation, 
				a.id as id_author, 
				a.name as name_author, 
				biography
			FROM 
				books b JOIN 
				books_authors ba on b.id = ba.id_book JOIN 
				authors a on ba.id_author = a.id 
			WHERE 
				b.id = book_id AND 
				a.id = ANY(author_arr);
	END

$func$ LANGUAGE plpgsql;


SELECT * FROM add_books(2001::smallint, 'Дневной дозор', null, 16, 'Продолжение истории светлого мага Антона Городецкого', VARIADIC array[('Сергей Лукьяненко', 'Популярный фантаст')::author, ('Владимир Васильев', 'Менее популярный фантаст')::author]);

SELECT * FROM add_books(2011::smallint, 'Сборник рассказов', null, 54, 'Рассказы для детей', VARIADIC array[('Николай Носов', 'Советский писатель')::author, ('Корней Чуковский', 'Советский писатель книг для детей')::author]);



-- выдача книги в библиотеке, уменьшаем количествово оставшихся книг на единицу в таблице books, вносим запись о выдаче в таблицу lending. Возвращает таблицу lending

DROP FUNCTION IF EXISTS lending_book;

CREATE OR REPLACE FUNCTION lending_book (name_reader varchar(50), address varchar(200), phone_number varchar(11), date_of_lend timestamp,
										name_author varchar(50), publication_year smallint, name_book varchar(50), volume smallint default null)
	RETURNS TABLE(id_reader int, id_book int, lending_date timestamp, date_of_return timestamp) as $func$
	
	DECLARE 
		book_id int;
		reader_id int;
	BEGIN 
--		т.к. не все книги состоят из нескольких томов для строки volume требуется делать отдельную проверку на null	
		IF $8 is not null
		THEN
			WITH temp_books_authors as (
				SELECT 
					b.id 
				FROM 
					books b JOIN 
					books_authors ba on b.id = ba.id_book JOIN 
					authors a on ba.id_author = a.id 
				WHERE 
					a.name = $5 AND 
					b.publication_year = $6 AND 
					b.name = $7 AND 
					b.volume = $8)
			
			SELECT 
				id 
			INTO 
				book_id 
			FROM 
				temp_books_authors;

			SELECT 
				id 
			INTO 
				reader_id 
			FROM 
				readers r 
			WHERE 
				r.name = $1 AND 
				r.address = $2 AND 
				r.phone_number = $3;
		
			UPDATE 
				books 
			SET 
				number_of_books = number_of_books - 1 
			WHERE 
				id = book_id;

			INSERT INTO 
				lending 
			values 
				(reader_id, book_id, $4, null);
				
			RETURN QUERY 
				SELECT * 
				FROM 
					lending l 
				WHERE 
					l.id_reader = reader_id AND 
					l.id_book = book_id;
		
		ELSE 
			WITH temp_books_authors as (
				SELECT 
					b.id 
				FROM 
					books b JOIN 
					books_authors ba on b.id = ba.id_book JOIN 
					authors a on ba.id_author = a.id 
				WHERE 
					a.name = $5 AND 
					b.publication_year = $6 AND 
					b.name = $7)
			
			SELECT 
				id 
			INTO 
				book_id 
			FROM 
				temp_books_authors;

			SELECT 
				id 
			INTO 
				reader_id 
			FROM 
				readers r 
			WHERE 
				r.name = $1 AND 
				r.address = $2 AND 
				r.phone_number = $3;
		
			UPDATE 
				books 
			SET 
				number_of_books = number_of_books - 1 
			WHERE 
				id = book_id;

			INSERT INTO 
				lending 
			values 
				(reader_id, book_id, $4, null);

			RETURN QUERY 
				SELECT * 
				FROM 
					lending l 
				WHERE 
					l.id_reader = reader_id AND 
					l.id_book = book_id;
	
		END IF;	
	END													
$func$ LANGUAGE plpgsql;

SELECT * FROM lending_book ('Александр Сергеевич Пупкин', 'г. Санкт-Петербург, ул. Джона Рида, д. 56, кв. 15', '89132946753', '2022-07-03'::timestamp,
							'Сергей Лукьяненко', 2001::smallint, 'Дневной дозор');

SELECT * FROM lending_book ('Александр Сергеевич Пупкин', 'г. Санкт-Петербург, ул. Джона Рида, д. 56, кв. 15', '89132946753', '2020-11-03'::timestamp,
							'Николай Носов', 2011::smallint, 'Сборник рассказов');
							
SELECT * FROM lending_book ('Александр Сергеевич Пупкин', 'г. Санкт-Петербург, ул. Джона Рида, д. 56, кв. 15', '89132946753', '2020-11-28'::timestamp,
							'Сергей Лукьяненко', 1999::smallint, 'Ночной дозор');
							
SELECT * FROM lending_book ('Александр Сергеевич Пушкин', 'г. Санкт-Петербург, с. Красное, ул. Рабочая, д. 12', '89111230695', '2012-11-28'::timestamp,
							'Сергей Лукьяненко', 1999::smallint, 'Ночной дозор');



-- возврат книги в библиотеку, функция аналогична взятию в аренду. Увеличиваем количество книг в библиотеке на единицу, записываем дату возврта в таблицу lending. Возвращает таблицу lending

DROP FUNCTION IF EXISTS returning_book;

CREATE OR REPLACE FUNCTION returning_book (name_reader varchar(50), address varchar(200), phone_number varchar(11),
										name_author varchar(50), publication_year smallint, name_book varchar(50), volume smallint default null)
	RETURNS TABLE(id_r int, id_b int, lend_date timestamp, return_date timestamp) as $func$
	
	DECLARE 
		book_id int;
		reader_id int;
		returning_date timestamp := now()::date;
	BEGIN 
		IF $7 is not null
		THEN
			WITH temp_books_authors as (
				SELECT 
					b.id 
				FROM 
					books b JOIN 
					books_authors ba on b.id = ba.id_book JOIN 
					authors a on ba.id_author = a.id 
				WHERE 
					a.name = $4 AND 
					b.publication_year = $5 AND 
					b.name = $6 AND b.volume = $7)
			
			SELECT 
				id 
			INTO 
				book_id 
			FROM 
				temp_books_authors;

			SELECT 
				id 
			INTO 
				reader_id 
			FROM 
				readers r 
			WHERE 
				r.name = $1 AND 
				r.address = $2 AND 
				r.phone_number = $3;
		
			UPDATE 
				books 
			SET 
				number_of_books = number_of_books + 1 
			WHERE 
				id = book_id;

			UPDATE 
				lending 
			SET 
				date_of_return = returning_date 
			WHERE 
				id_reader = reader_id AND 
				id_book = book_id;

			RETURN QUERY 
				SELECT * 
				FROM 
					lending l 
				WHERE 
					l.id_reader = reader_id AND 
					l.id_book = book_id;
		
		ELSE 
			WITH temp_books_authors as (
				SELECT 
					b.id 
				FROM 
					books b JOIN 
					books_authors ba on b.id = ba.id_book JOIN 
					authors a on ba.id_author = a.id 
				WHERE 
					a.name = $4 AND 
					b.publication_year = $5 AND 
					b.name = $6)
			
			SELECT 
				id 
			INTO 
				book_id 
			FROM 
				temp_books_authors;

			SELECT 
				id 
			INTO 
				reader_id 
			FROM 
				readers r 
			WHERE 
				r.name = $1 AND 
				r.address = $2 AND 
				r.phone_number = $3;
		
			UPDATE 
				books 
			SET 
				number_of_books = number_of_books + 1 
			WHERE 
				id = book_id;

			UPDATE 
				lending 
			SET 
				date_of_return = returning_date 
			WHERE 
				id_reader = reader_id AND 
				id_book = book_id;

			RETURN QUERY 
				SELECT * 
				FROM 
					lending l 
				WHERE 
					l.id_reader = reader_id AND 
					l.id_book = book_id;
	
		END IF;	
	end													
$func$ LANGUAGE plpgsql;


SELECT * FROM returning_book ('Александр Сергеевич Пупкин', 'г. Санкт-Петербург, ул. Джона Рида, д. 56, кв. 15', '89132946753',
							'Сергей Лукьяненко', 2001::smallint, 'Дневной дозор');