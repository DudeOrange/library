
REVOKE CREATE ON SCHEMA public FROM public;
REVOKE ALL ON ALL TABLES IN SCHEMA  pg_catalog FROM public;

-- пользователь "администратор" занимается обслуживанием БД, права почти как у superuser
CREATE USER p_admin CREATEDB INHERIT REPLICATION NOSUPERUSER NOCREATEROLE password 'p_admin';
GRANT ALL PRIVILEGES ON schema public TO p_admin;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO p_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO p_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA pg_catalog TO p_admin;

-- пользователь "библиотекарь", вносит данные в БД, может читать и изменять любые таблицы
CREATE USER librarian  INHERIT NOCREATEDB NOREPLICATION NOSUPERUSER NOCREATEROLE PASSWORD 'librarian';
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO librarian;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO librarian;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE ON TABLES TO librarian;
ALTER DEFAULT privileges FOR USER p_admin IN SCHEMA public GRANT SELECT, INSERT, UPDATE ON TABLES TO librarian;
GRANT SELECT ON pg_type, pg_class, pg_description, pg_namespace TO librarian;

-- пользователь "читатель", может читать некоторые из таблиц для поиска нужной книги
CREATE USER reader INHERIT NOCREATEDB NOREPLICATION NOSUPERUSER NOCREATEROLE PASSWORD 'reader';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO reader;

GRANT SELECT ON pg_type, pg_class, pg_description, pg_namespace TO reader;



DROP TABLE IF EXISTS readers CASCADE;
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS authors CASCADE;
DROP TABLE IF EXISTS lending CASCADE;
DROP TABLE IF EXISTS books_authors CASCADE;


CREATE TABLE readers (
id 				SERIAL PRIMARY KEY,
name 			varchar(50) NOT NULL,	-- ФИО читателя
address 		varchar(200) NOT NULL,	-- Адрес читателя для отправки корреспонденции
phone_number 	varchar(11) NOT NULL,	-- Контактный телефон
				constraint check_phone CHECK (phone_number ~ '^[0-9]*$')
);

CREATE TABLE books (
id 					SERIAL PRIMARY KEY,
publication_year 	smallint NOT NULL,		-- год издания книги
name 				varchar(50) NOT NULL,	-- название
volume 				smallint,				-- номер тома
number_of_books 	int NOT NULL,			-- количество книг в наличии
annotation 			text NOT NULL			-- аннотация
);

CREATE TABLE authors (
id 			SERIAL PRIMARY KEY,
name 		varchar(50) NOT NULL,	-- ФИО автора
biography 	text					-- биографическая справка
);

CREATE TABLE lending (
id_reader 		integer NOT NULL REFERENCES readers (id),
id_book 		integer NOT NULL REFERENCES books (id),
date_of_lend 	timestamp NOT NULL,							-- даты выдачи книги
date_of_return 	timestamp									-- дата возврата
);

CREATE TABLE books_authors (
id_author 	integer NOT NULL REFERENCES authors (id),
id_book 	integer NOT NULL REFERENCES books (id)
);


ALTER TABLE books ADD CONSTRAINT positive_number CHECK (number_of_books >= 0);

-- у книги может быть несколько авторов, в таких случаях будет использоваться кастомный тип author(name, biography), а все авторы книги помещаться в массив.
DROP TYPE IF EXISTS author CASCADE;
CREATE TYPE author as (field1 varchar(50), field2 text);


-- забираем права на чтение некоторых таблиц у читателя после того как их создали
REVOKE SELECT ON readers FROM reader;
REVOKE SELECT ON lending FROM reader;
