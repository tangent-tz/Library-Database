DROP DATABASE IF EXISTS project;
CREATE DATABASE project;
USE project;

CREATE TABLE Member (
    lib_card_num    INT NOT NULL AUTO_INCREMENT,
    address         VARCHAR(100) NOT NULL,
    email           VARCHAR(50) NOT NULL,
    password        VARCHAR(20) NOT NULL,
    fName           VARCHAR(20) NOT NULL,
    lName           VARCHAR(20) NOT NULL,
    
    PRIMARY KEY (lib_card_num)
);

CREATE TABLE Book (
    ISBN13      CHAR(14) NOT NULL,
    price       DEC(5, 2) NOT NULL,
    dd_num      VARCHAR(10),
    title       VARCHAR(63) NOT NULL,
    publisher   VARCHAR(63),
    language    VARCHAR(15),
    picture     VARCHAR(255),

    PRIMARY KEY (ISBN13)
);

CREATE TABLE DVD (
    ISSN        CHAR(12) NOT NULL,
    price       DEC(5, 2) NOT NULL,
    dd_num      VARCHAR(10),
    title       VARCHAR(63) NOT NULL,
    publisher   VARCHAR(63),
    language    VARCHAR(15),
    picture     VARCHAR(255),

    PRIMARY KEY (ISSN)
);

CREATE TABLE CD (
    ISSN        CHAR(12) NOT NULL,
    price       DEC(5, 2) NOT NULL,
    dd_num      VARCHAR(10),
    title       VARCHAR(63) NOT NULL,
    publisher   VARCHAR(63),
    language    VARCHAR(15),
    picture     VARCHAR(255),

    PRIMARY KEY (ISSN)
);

CREATE TABLE Item (
    item_id         INT NOT NULL AUTO_INCREMENT,
    bookISBN        CHAR(14) NULL,
    cdISSN          CHAR(12) NULL,
    dvdISSN         CHAR(12) NULL,
    availability    TINYINT NOT NULL DEFAULT 1,

    PRIMARY KEY (item_ID),
    FOREIGN KEY (bookISBN)  REFERENCES Book(ISBN13),
    FOREIGN KEY (cdISSN)    REFERENCES CD(ISSN),
    FOREIGN KEY (dvdISSN)   REFERENCES DVD(ISSN),
    CONSTRAINT FK_Item CHECK (
        (
            (CASE WHEN bookISBN IS NULL THEN 0 ELSE 1 END) +
            (CASE WHEN cdISSN IS NULL THEN 0 ELSE 1 END) +
            (CASE WHEN dvdISSN IS NULL THEN 0 ELSE 1 END)
        ) = 1
    )
);

CREATE TABLE MemberStatus (
    -- status is good iff. (fines <= 0 and numOverdueItems == 0).
    lib_card_num        INT NOT NULL,
    fines                DEC(5, 2) DEFAULT 0.0,
    numOverdueItems     INT DEFAULT 0,

    PRIMARY KEY (lib_card_num),
    FOREIGN KEY (lib_card_num)  REFERENCES Member(lib_card_num)
);

CREATE TRIGGER ADD_ROW_TO_STATUS
AFTER INSERT ON Member
FOR EACH ROW
INSERT INTO MemberStatus (lib_card_num) VALUES (NEW.lib_card_num);

CREATE TRIGGER DELETE_STALE_STATUS_ROW
BEFORE DELETE ON Member
FOR EACH ROW
DELETE FROM MemberStatus WHERE lib_card_num = OLD.lib_card_num;


CREATE TABLE Reservation (
    item_ID         INT NOT NULL,
    reserveDate     DATE NOT NULL,
    lib_card_num    INT NOT NULL,

    FOREIGN KEY (item_ID)       REFERENCES Item(item_ID),
    FOREIGN KEY (lib_card_num)  REFERENCES Member(lib_card_num),
    CONSTRAINT PK_Reserve PRIMARY KEY (item_ID, reserveDate, lib_card_num)
);

CREATE TABLE LoanedItem (
    lib_card_num    INT NOT NULL,
    item_id         INT NOT NULL,
    timestamp       DATETIME NOT NULL,

    PRIMARY KEY (lib_card_num, item_id),
    FOREIGN KEY (lib_card_num)  REFERENCES Member(lib_card_num),
    FOREIGN KEY (item_id)       REFERENCES Item(item_id)
);

CREATE TABLE Authors (
    author      VARCHAR(100) NOT NULL,
    bookISBN    CHAR(14) NOT NULL,

    FOREIGN KEY (bookISBN) REFERENCES Book(ISBN13),
    CONSTRAINT PK_Author PRIMARY KEY (author, bookISBN)
);

CREATE TABLE DVDActors (
    actor       VARCHAR(100) NOT NULL,
    dvdISSN     CHAR(12) NOT NULL,

    FOREIGN KEY (dvdISSN) REFERENCES DVD(ISSN),
    CONSTRAINT PK_DVDActor PRIMARY KEY (actor, dvdISSN)
);

CREATE TABLE DVDDirectors (
    director    VARCHAR(100) NOT NULL,
    dvdISSN     CHAR(12) NOT NULL,

    FOREIGN KEY (dvdISSN) REFERENCES DVD(ISSN),
    CONSTRAINT PK_DVDDirector PRIMARY KEY (director, dvdISSN)
);

CREATE TABLE CDArtist (
    artist      VARCHAR(100) NOT NULL,
    cdISSN      CHAR(12) NOT NULL,

    FOREIGN KEY (cdISSN) REFERENCES CD(ISSN),
    CONSTRAINT PK_CDArtist PRIMARY KEY (artist, cdISSN)
);

CREATE TABLE BookGenre(
    genre       VARCHAR(15) NOT NULL,
    bookISBN    CHAR(14) NOT NULL,

    FOREIGN KEY (bookISBN) REFERENCES Book(ISBN13),
    CONSTRAINT PK_BookGenre PRIMARY KEY (genre, bookISBN)
);

CREATE TABLE CDGenre (
    genre       VARCHAR(15) NOT NULL,
    cdISSN      CHAR(12) NOT NULL,

    FOREIGN KEY (cdISSN) REFERENCES CD(ISSN),
    CONSTRAINT PK_BookGenre PRIMARY KEY (genre, cdISSN)
);

CREATE TABLE DVDGenre (
    genre       VARCHAR(15) NOT NULL,
    dvdISSN     CHAR(12) NOT NULL,

    FOREIGN KEY (dvdISSN) REFERENCES DVD(ISSN),
    CONSTRAINT PK_DVDGenre PRIMARY KEY (genre, dvdISSN)
);

INSERT INTO Member (address, email, password, fName, lName) VALUES
('123 Flynn St.', 'cooldude@hotmail.com', '123', 'Dude', 'Smith'),
('123 Main St.', 'cristian@sfu.ca', '123', 'Cristian','John'),
('123 Street Ave.', 'darebear@gmail.com', 'Seinfeld', 'Darren', 'Bear'),
('8888 University Dr.', 'sfu@sfu.ca', 'sfu', 'Kurt', 'Fraser'),
('13450 102 Ave.', 'alex@sfu.ca', 'password', 'Alex', 'Cap');


INSERT INTO Book (ISBN13, price, title, publisher, language, picture) VALUES
('978-0553213119', 6.00, 'Moby Dick', 'PBS', 'English', 'https://upload.wikimedia.org/wikipedia/commons/3/36/Moby-Dick_FE_title_page.jpg'),
('978-0062073556', 7.00, 'Death on the Nile', 'William Morrow Paperbacks', 'English', 'https://upload.wikimedia.org/wikipedia/en/9/96/Death_on_the_Nile_First_Edition_Cover_1937.jpg'),
('978-0316438988', 12.50, 'Blood of Elves', 'Orbit', 'English', 'https://upload.wikimedia.org/wikipedia/en/6/61/Blood_of_Elves_UK.jpg'),
('978-0316219136', 9.50, 'The Time of Contempt', 'Orbit', 'English', 'https://upload.wikimedia.org/wikipedia/en/4/48/Time_of_Contempt_UK.jpg'),
('978-0316219181', 12.50, 'Baptism of Fire', 'Orbit', 'English', 'https://upload.wikimedia.org/wikipedia/en/3/35/Baptism_of_Fire_UK.jpg');

INSERT INTO BookGenre (bookISBN, genre) VALUES
('978-0553213119', 'Fiction'),
('978-0553213119', 'Adventure'),
('978-0062073556', 'Fiction'),
('978-0062073556', 'Mystery'),
('978-0316438988', 'Fiction'),
('978-0316438988', 'Fantasy'),
('978-0316219136', 'Fiction'),
('978-0316219136', 'Fantasy'),
('978-0316219181', 'Fiction'),
('978-0316219181', 'Fantasy');

INSERT INTO Item (bookISBN) VALUES
('978-0553213119'),
('978-0062073556'),
('978-0316438988'),
('978-0316219136'),
('978-0316219181');


INSERT INTO DVD (ISSN, price, title, publisher, language, picture) VALUES
('667068824421', 13.99, 'Shrek', 'DreamWorks', 'English', 'https://upload.wikimedia.org/wikipedia/en/3/39/Shrek.jpg'),
('678149087321', 5.00, 'Shrek 2', 'DreamWorks', 'English', 'https://upload.wikimedia.org/wikipedia/en/b/b9/Shrek_2_poster.jpg'),
('505118913383', 5.00, 'Shrek the Third', 'DreamWorks', 'English', 'https://upload.wikimedia.org/wikipedia/en/0/01/Shrek_the_third_ver2.jpg'),
('191329061091', 13.99, 'Shrek Forever After', 'DreamWorks', 'English', 'https://upload.wikimedia.org/wikipedia/en/7/75/Shrek_forever_after_ver8.jpg'),
('097368523944', 13.99, 'Shrek the Halls', 'DreamWorks', 'English', 'https://upload.wikimedia.org/wikipedia/en/b/b7/Shrek_the_Halls_poster.jpg');

INSERT INTO DVDGenre (genre, dvdISSN) VALUES
('Comedy', '667068824421'),
('Comedy', '678149087321'),
('Comedy', '505118913383'),
('Comedy', '191329061091'),
('Comedy', '097368523944'),
('Animation', '667068824421'),
('Animation', '678149087321'),
('Animation', '505118913383'),
('Animation', '191329061091'),
('Animation', '097368523944');

INSERT INTO Item (dvdISSN) VALUES
('667068824421'),
('678149087321'),
('505118913383'),
('191329061091'),
('097368523944');


INSERT INTO CD (ISSN, price, title, publisher, language, picture) VALUES
('720616246523', 9.99, 'Queen Greatest Hits', 'Hollywood Records', 'English', 'https://upload.wikimedia.org/wikipedia/en/0/02/Queen_Greatest_Hits.png'),
('602498568279', 9.99, 'Under The Iron Sea', 'Universal Island Records', 'English', 'https://upload.wikimedia.org/wikipedia/en/1/13/Keane_Iron_Sea.jpg'),
('602498531785', 9.99, 'Eyes Open', 'Universal Music', 'English', 'https://upload.wikimedia.org/wikipedia/en/a/af/Speyesopen.jpg'),
('886970382724', 9.99, 'Grammy Nominees 2007', 'Sony BMG Music', 'English', 'https://cdn-s3.allmusic.com/release-covers/500/0000/678/0000678752.jpg'),
('602517581029', 9.99, 'Grammy Nominees 2008', 'Universal Music', 'English', 'http://cps-static.rovicorp.com/3/JPG_500/MI0000/011/MI0000011109.jpg?partner=allrovi.com');

INSERT INTO CDGenre (cdISSN, genre) VALUES
('720616246523', 'Music'),
('720616246523', 'Rock'),
('602498568279', 'Music'),
('602498568279', 'Rock'),
('602498531785', 'Music'),
('602498531785', 'Rock'),
('602498531785', 'Alternative'),
('886970382724', 'Music'),
('602517581029', 'Music');


INSERT INTO Item (cdISSN) VALUES
('720616246523'),
('602498568279'),
('602498531785'),
('886970382724'),
('602517581029');


INSERT INTO Reservation (item_id, reserveDate, lib_card_num) VALUES
(5, '2021-01-01', 2),
(4, '2021-02-02', 2),
(3, '2021-03-03', 2),
(2, '2021-03-03', 2),
(11, '2021-03-03', 2);

INSERT INTO LoanedItem VALUES
(3, 1, '2021-03-04 10:00:00'),
(3, 2, '2021-03-04 10:00:00'),
(3, 3, '2021-03-04 10:00:00'),
(3, 4, '2021-03-04 10:00:00'),
(3, 5, '2021-03-04 10:00:00'),
(3, 11, '2021-03-04 10:00:00');

INSERT INTO Authors (author, bookISBN) VALUES
('Herman Melville', '978-0553213119'),
('Agatha Christie', '978-0062073556'),
('Andrzej Sapkowski', '978-0316438988'),
('Andrzej Sapkowski', '978-0316219136'),
('Andrzej Sapkowski', '978-0316219181');

INSERT INTO DVDActors (actor, dvdISSN) VALUES
('Mike Myers', '667068824421'),
('Eddie Murphy', '667068824421'),
('Cameron Diaz', '667068824421'),
('John Lithgow', '667068824421'),
('Mike Myers', '678149087321'),
('Eddie Murphy', '678149087321'),
('Cameron Diaz', '678149087321'),
('John Lithgow', '678149087321'),
('Vincent Cassel', '678149087321');

INSERT INTO DVDDirectors (director, dvdISSN) VALUES
('Andrew Adamson', '667068824421'),
('Andrew Adamson', '678149087321'),
('Vicky Jenson', '678149087321'),
('Kelly Asbury', '505118913383'),
('Conrad Vernon', '505118913383'),
('Chris Miller', '191329061091'),
('Raman Hui', '191329061091');

INSERT INTO CDArtist (artist, cdISSN) VALUES
('Queen', '720616246523'),
('Keane', '602498568279'),
('Snow Patrol', '602498531785'),
('Various Artists', '886970382724'),
('Various Artists', '602517581029');
