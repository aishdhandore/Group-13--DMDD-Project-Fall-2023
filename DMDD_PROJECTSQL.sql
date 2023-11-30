
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'MovieDatabase')
    DROP DATABASE MovieDatabase
GO

CREATE DATABASE [MovieDatabase]
GO
USE [MovieDatabase]
GO

-- Production Company Table
CREATE TABLE ProductionCompany (
    company_id INT IDENTITY(1,1) PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL UNIQUE, -- Ensures that each company name is unique
    founded_year INT CHECK (founded_year BETWEEN 1800 AND YEAR(GETDATE())),
    headquarters VARCHAR(255),
    company_description TEXT
);

-- Genre Table
CREATE TABLE Genre (
    genre_id INT IDENTITY(1,1) PRIMARY KEY,
    genre_name VARCHAR(255) NOT NULL UNIQUE, -- Ensures that each genre name is unique
    genre_description TEXT
);

-- Movie Table
CREATE TABLE Movie (
    movie_id INT IDENTITY(1,1) PRIMARY KEY,
    company_id INT,
    title VARCHAR(100) NOT NULL UNIQUE,
    release_year INT CHECK (release_year BETWEEN 1800 AND YEAR(GETDATE())),
    duration INT CHECK (duration > 0),
    [language] VARCHAR(50),
    budget DECIMAL(15, 2) CHECK (budget >= 0),
    revenue DECIMAL(15, 2) CHECK (revenue >= 0),
    FOREIGN KEY (company_id) REFERENCES ProductionCompany(company_id),
    UNIQUE (company_id, release_year) -- Ensures that each company has unique movies per year
);

-- Movie Genre Table
CREATE TABLE Movie_Genre (
    movie_genre_id INT IDENTITY(1,1) PRIMARY KEY,
    movie_id INT,
    genre_id INT,
    date_added DATE CHECK (date_added <= GETDATE()),
    FOREIGN KEY (movie_id) REFERENCES Movie(movie_id),
    FOREIGN KEY (genre_id) REFERENCES Genre(genre_id),
    UNIQUE (movie_id, genre_id) -- ensures the combination of movie and genre is unique
);

-- Awards Table
CREATE TABLE Awards (
    award_id INT IDENTITY(1,1) PRIMARY KEY,
    award_name VARCHAR(255) NOT NULL,
    award_year INT CHECK (award_year BETWEEN 1900 AND YEAR(GETDATE())),
    category VARCHAR(255) NOT NULL,
    UNIQUE (award_name, award_year, category) -- ensures that the combination of name, year, and category is unique
);

-- Movie Honors Table
CREATE TABLE Movie_Honors (
    movie_honor_id INT IDENTITY(1,1) PRIMARY KEY,
    movie_id INT,
    award_id INT,
    awarding_organization VARCHAR(255),
    judge VARCHAR(255),
    award_date DATE CHECK (award_date <= GETDATE()),
    honor_description TEXT,
    FOREIGN KEY (movie_id) REFERENCES Movie(movie_id),
    FOREIGN KEY (award_id) REFERENCES Awards(award_id)
);

-- Cast & Crew Table
CREATE TABLE Cast_Crew (
    cast_id INT IDENTITY(1,1) PRIMARY KEY,
    [name] VARCHAR(255) NOT NULL,
    date_of_birth DATE CHECK (date_of_birth <= GETDATE()),
    date_of_first_movie DATE CHECK (date_of_first_movie <= GETDATE()),
    nationality VARCHAR(255),
    gender CHAR(1) CHECK (gender IN ('M', 'F', 'O')),
    cast_type VARCHAR(50)
);

-- Movie Role Table
CREATE TABLE Movie_Role (
    movie_role_id INT IDENTITY(1,1) PRIMARY KEY,
    movie_id INT,
    cast_id INT,
    joining_date DATE CHECK (joining_date <= GETDATE()),
    role_description TEXT,
    salary DECIMAL(15, 2) CHECK (salary >= 0),
    FOREIGN KEY (movie_id) REFERENCES Movie(movie_id),
    FOREIGN KEY (cast_id) REFERENCES Cast_Crew(cast_id),                                                                                                      
    UNIQUE (movie_id, cast_id) -- ensures a cast member can't have more than one role in the same movie
);

-- Character Table
CREATE TABLE Character (
    character_id INT IDENTITY(1,1) PRIMARY KEY,
    cast_id INT,
    character_name VARCHAR(255) NOT NULL,
    role_type VARCHAR(50) NOT NULL,
    --UNIQUE (character_name, role_type) -- ensures character names are unique within the same role type
    FOREIGN KEY (cast_id) REFERENCES Cast_Crew(cast_id),
);

-- Cast Honors Table
CREATE TABLE Cast_Honors (
    cast_honor_id INT IDENTITY(1,1) PRIMARY KEY,
    cast_id INT,
    award_id INT,
    awarding_organization VARCHAR(255),
    judge VARCHAR(255),
    award_date DATE CHECK (award_date <= GETDATE()),
    honor_description TEXT,
    FOREIGN KEY (cast_id) REFERENCES Cast_Crew(cast_id),
    FOREIGN KEY (award_id) REFERENCES Awards(award_id)
);

-- User Table
CREATE TABLE [User] (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    [password] VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    registration_date DATE CHECK (registration_date <= GETDATE())
);

-- Review Table
CREATE TABLE Review (
    review_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT,
    movie_id INT,
    content TEXT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review_date DATE CHECK (review_date <= GETDATE()),
    FOREIGN KEY (user_id) REFERENCES [User](user_id),
    FOREIGN KEY (movie_id) REFERENCES Movie(movie_id)
    -- No unique constraint added as users can make multiple reviews for different movies
);


-- Broadcaster Table
CREATE TABLE Broadcaster (
    broadcast_id INT IDENTITY(1,1) PRIMARY KEY,
    broadcaster_name VARCHAR(255) NOT NULL UNIQUE,
    street_name VARCHAR(255),
    city VARCHAR(255),
    [state] VARCHAR(50),
    country VARCHAR(50) NOT NULL,
    url_link VARCHAR(255) CHECK (url_link LIKE  'http://%' OR url_link LIKE  'https://%' )
);

-- Movie Broadcaster Table
CREATE TABLE Movie_Broadcaster (
    movie_broadcaster_id INT IDENTITY(1,1) PRIMARY KEY,
    movie_id INT,
    broadcast_id INT,
    contract_start_date DATE,
    contract_end_date DATE,
    FOREIGN KEY (movie_id) REFERENCES Movie(movie_id),
    FOREIGN KEY (broadcast_id) REFERENCES Broadcaster(broadcast_id),
    UNIQUE (movie_id, broadcast_id), -- ensures a movie is associated with a broadcaster once per contract
    CHECK (contract_end_date > contract_start_date)
);




USE [MovieDatabase]
GO

INSERT INTO ProductionCompany (company_name, founded_year, headquarters, company_description)
VALUES 
('Phoenix Pictures', 1995, 'Culver City, CA', 'Founded by Producers Mike Medavoy and Arnold Messer in 1995'),
('DVV Entertainment', 2012, 'Hyderabad', 'D. V. V. Danayya is an Indian film producer.'),
('Paramount Pictures', 1912, 'Hollywood, CA', 'A legendary producer and global distributor of filmed entertainment since 1912'),
('20th Century Studios', 1935, 'Century City, CA', 'To give people the simple pleasure of being transported by a story on a screen.'),
('Walt Disney Pictures', 1923, 'Burbank, CA', 'The Happiest Place on Earth'),
('Castle Rock Entertainment',1987,'California','American film and television production company'),
('Produzioni De Sica',1933,'Sora','Production company founded by Vittorio De Sica'),
('Fox 2000 Pictures',1994,'Century City, CA','Fox 2000 Pictures was an American production company owned by The Walt Disney Studios.'),
('BlumHouse Produtions',2000,'Los Angeles','Blumhouse is a multimedia company regarded as the driving force in horror. The company produces high-quality indie budget horror films, and provocative scripted and unscripted television series.'),
('Ghost House Pictures',2002,'Los Angeles','Ghost House Pictures is an American film and television production company founded in 2002 by Sam Raimi and Robert Tapert.'),
('Columbia Pictures',1918,'Culver City, CA','A large Hollywood film company, producing films for cinema and television.'),
('DreamWorks Pictures',1994,'Universal City, CA','We tell stories about dreams and the journeys unconventional heroes take to make them come true.'),
('Warner Bros. Pictures',1923,'Burbank, CA','The stuff that dreams are made of.');

-- Add more rows below...

INSERT INTO Genre (genre_name, genre_description)
VALUES 
('Action', 'Fast-paced, high energy films.'),
('Drama', 'Narrative films known for serious plots.'),
('Thriller', 'Thrillers are characterized and defined by the moods they elicit, giving their audiences heightened feelings of suspense, excitement, surprise, anticipation and anxiety.'),
('Horror', 'Horror is a genre of literature, film, and television that is meant to scare, startle, shock, and even repulse audiences.'),
('Psychological Thriller', 'Psychological Thriller genre emphasizes interior characterization and motivation to explore the spiritual, emotional, and mental lives of its characters.'),
('Suspense', 'In the Suspense Genre anxiety developed from an unpredictable mystery keeps the reader on the edge of their seat, hooked into finding out what will happen next.'),
('Tragedy', 'Tragedy is a genre of drama based on human suffering and, mainly, the terrible or sorrowful events that befall a main character.'),
('Romance', 'Romance genre stories involve chivalry and often adventure.'),
('Comedy', 'Comedy is a genre of fiction that consists of discourses or works intended to be humorous or amusing by inducing laughter.'),
('Fantasy', 'Fantasy is a genre of speculative fiction involving magical elements, typically set in a fictional universe and usually inspired by mythology or folklore.'),
('Adventure', 'The adventure genre consists of books where the protagonist goes on an epic journey, either personally or geographically.'),
('Science Fiction', 'Science fiction is a genre of speculative fiction, which typically deals with imaginative and futuristic concepts such as advanced science and technology, space exploration, time travel, parallel universes, and extraterrestrial life.'),
('War', 'War film is a film genre concerned with warfare, typically about naval, air, or land battles, with combat scenes central to the drama.'),
('History', 'The history genre consists of events of significant change that happened in the past and the discovery, collection, presentation, and organization of the information.'),
('Crime', 'Crime fiction is the genre of fiction that deals with crimes, their detection, criminals, and their motives.'),
('Mystery', 'Mystery fiction is a genre in which the protagonist works to uncover the meaning or secret behind an unknown event.'),
('Animation','Animation is the method that encompasses myriad filmmaking techniques, by which still images are manipulated to create moving images.');
-- Add more rows below...

INSERT INTO Movie (company_id, title, release_year, duration, [language], budget, revenue)
VALUES 
(1, 'Shutter Island', 2010, 139, 'English', 80000000, 294800000),
(2, 'RRR', 2022, 182, 'Telugu', 5500000000, 13872600000),
(3, 'Titanic', 1997, 195, 'English', 200000000, 2257000000),
(4, 'Avatar', 2009, 162, 'English', 237000000, 2923000000),
(5, 'Finding Nemo', 2003, 100, 'English', 94000000, 940300000),
(6,'The Shawshank Redemption',1994,142,'English',25000000,16000000),
(7,'Bicycle Thieves',1948,89,'Italian',133000,428978),
(8,'Fight Club',1999,139,'English',65000000,101200000),
(9,'Get Out',2017,104,'English',4500000,225400000),
(10,'Dont Breathe',2016,88,'English',9900000,157800000),
(11,'Spider-Man',2002,121,'English',139000000,825000000),
(12,'1917',2019,119,'English',100000000,384600000),
(13,'Dunkirk',2017,106,'English',15000000,52700000),
(13,'The Dark Knight',2008,152,'English',185000000,1006000000),
(13,'Joker',2019,122,'English',70000000,1074000000);


-- Add more rows below...

INSERT INTO Movie_Genre (movie_id, genre_id, date_added)
VALUES 
(1, 16, '2021-01-01'),
(1, 3, '2021-01-01'),
(1, 5, '2021-01-01'),
(2, 1, '2021-01-02'),
(2, 2, '2021-01-02'),
(3, 8, '2021-01-02'),
(3, 2, '2021-01-02'),
(3, 1, '2021-01-02'),
(3, 7, '2021-01-02'),
(4, 1, '2021-01-02'),
(4, 11, '2021-01-02'),
(4,10, '2021-01-02'),
(4, 17, '2021-01-02'),
(5, 17, '2021-01-02'),
(5, 9, '2021-01-02'),
(5, 11, '2021-01-02'),
(6, 2, '2021-01-02'),
(7, 2, '2021-01-02'),
(8, 2, '2021-01-02'),
(9, 4, '2021-01-02'),
(9, 16, '2021-01-02'),
(9, 3, '2021-01-02'),
(10, 15, '2021-01-02'),
(10, 4, '2021-01-02'),
(10, 3, '2021-01-02'),
(11, 1, '2021-01-02'),
(11, 11, '2021-01-02'),
(11, 12, '2021-01-02'),
(12, 1, '2021-01-02'),
(12, 2, '2021-01-02'),
(12, 13, '2021-01-02'),
(13, 1, '2021-01-02'),
(13, 2, '2021-01-02'),
(13, 14, '2021-01-02'),
(13, 3, '2021-01-02'),
(13, 13, '2021-01-02'),
(14, 1, '2021-01-02'),
(14, 15, '2021-01-02'),
(14, 2, '2021-01-02'),
(14, 3, '2021-01-02'),
(15, 15, '2021-01-02'),
(15, 2, '2021-01-02'),
(15, 3, '2021-01-02');
-- Add more rows below...

INSERT INTO Awards (award_name, award_year, category)
VALUES 
('Teen Choice Award for Choice Movie Actor: Horror/Thriller',2010,'Acting'),
('Academy Award',2023,'Best Original Song'),
('Academy Award',1998,'Best Picture'),
('Academy Award',1998,'Best Director'),
('Academy Award',1998,'Best Cinematography'),
('Academy Award',1998,'Best Original Song'),
('Academy Award',1998,'Best Sound'),
('Academy Award',2010,'Best Art Direction'),
('Academy Award',2010,'Best Visual Effects'),
('Academy Award',2018,'Best Original Screenplay'),
('Academy Award',2010,'Best Cinematography'),
('Brazilian Film Academy',2010,'Best Foreign Film'),
('Golden Globe Award',2010,'Best Film - Drama'),
('Saturn Award',2004,'Best Animated Film'),
('Award of the japanese Academy',1996,'Best Foreign Film'),
('OFTA Film Hall of Fame',2023,'motion Picture'),
('Amanda Awards',2020,'Best Foreign Feature Film'),
('American Film Institute',2020,'Top 10 Films of the Year'),
('Saturn Award',2017,'Best Horror Film'),
('BSFC Award',2017,'Best Cinematography');
-- Add more rows below...

INSERT INTO Movie_Honors (movie_id, award_id, awarding_organization, judge, award_date, honor_description)
VALUES 
(2, 4, 'Academy', 'Jane Doe', '1998-02-01', 'Natu Natu'),
(3, 3, 'Academy', 'John Oliver', '1998-02-01', 'Best Picture at oscars'),
(4, 12, 'BFA', 'Dylan McDermott', '1998-02-01', 'Best foreign film'),
(4,13,'Golden Globe','Frankie Chiapperino','2010-01-01','Best film in drama'),
(5,14,'Saturn','Andrew Jenks','2004-01-01','Best animated film'),
(6,15,'Japanese Academy','John Legend','1996-01-01','Best foreign film'),
(13,18,'AFI','Caroline Waterlow','2020-01-03','Top 10 Films of the Year 2020'),
(10,19,'Saturn','Ed Burns','2017-01-01','Best Horror Film'),
(8,16,'Saturn','Brittany Snow','2023-01-01','Best motion Picture'),
(13,17,'Saturn','Opal Bennett','2020-01-01','Best Foreign Feature Film 2020');


-- Add more rows below...

INSERT INTO Cast_Crew ([name], date_of_birth, date_of_first_movie, nationality, gender, cast_type)
VALUES 
('Leonardo DiCaprio', '1974-11-11', '1991-12-11', 'American', 'M', 'Lead'),
('Ram Charan', '1985-03-27', '2007-09-28', 'Indian', 'M', 'Lead'),
('N. T. Rama Rao Jr.', '1983-05-20', '2001-05-23', 'Indian', 'M', 'Lead'),
('Alia Bhatt', '1993-03-15', '1999-09-03', 'Indian', 'F', 'Lead'),
('Kate Winslet', '1975-10-05', '1994-10-14', 'British', 'F', 'Lead'),
('Morgan Freeman', '1937-06-01', '1971-11-18', 'American', 'M', 'Supporting Actor'),
('Brad Pitt', '1963-12-18', '1987-08-08', 'American', 'M', 'Lead'),
('David Fincher', '1962-08-28', '1992-05-22', 'American', 'M', 'Director'),
('Roger Deakins', '1949-05-24', '1990-02-23', 'British', 'M', 'Cinematographer'),
('James Cameron', '1954-08-16', '1978-01-01', 'Canadian', 'M', 'Director'),
('Jordan Peele','1979-02-21','2016-03-13','American', 'M','Writer'),
('Russell Carpenter','1950-12-09','1999-12-21','American', 'M','Cinematographer'),
('Kim Sinclair','1954-07-10','2001-09-09','New Zealand', 'M','Art Director'),
('Robert Legato','1956-01-01','1987-06-05','American','M','VFX Supervisor'),
('Mauro Fiore','1964-11-15','1996-11-16','American','M','Cinematographer'),
('Hoyte Van Hoytema','1971-10-04','1999-04-15','Dutch','M','Cinematographer'),
('James Horner','1953-08-14','1985-08-25','American','M','Composer'),
('Gary Rydstrom','1959-06-29','1976-01-06','American','M','Sound Designer'),
('Tobey Maguire','1975-06-27','1989-12-15','American','M','Lead'),
('Christian Bale','1974-01-30','1987-12-11','British','M','Lead'),
('Heath Ledger','1979-04-04','1997-05-01','Australian','M','Lead');


-- Add more rows below...

INSERT INTO Movie_Role (movie_id, cast_id, joining_date, role_description, salary)
VALUES 
(1, 1, '2009-06-01', 'Protagonist', 2000000),
(2, 2, '2021-09-09', 'Protagonist', 8000000),
(2, 3, '2021-09-09', 'Protagonist', 6000000),
(2, 4, '2021-09-09', 'Protagonist', 5000000),
(3, 5, '1996-06-21', 'Protagonist', 19000000),
(6, 6, '1993-11-16', 'Protagonist', 26000000),
(8, 7, '1998-07-25', 'Protagonist', 20000),
(8, 8, '1998-07-27', 'Director', 160000),
(12, 9, '2018-03-13', 'Cinematographer', 2560000),
(3, 10, '1996-08-01', 'Director', 16000000),
(4, 10, '2008-11-01', 'Director', 56000000),
(9, 11, '2016-07-21', 'Writer', 10000),
(4, 12, '2008-09-17', 'Cinematographer', 1460000),
(4, 13, '2008-09-17', 'Art Director', 260000),
(3, 14, '1996-03-18', 'VFX Supervisor', 86000),
(4, 15, '2008-04-21', 'Cinematographer', 755000),
(13, 16, '2016-05-11', 'Cinematographer', 650000),
(3, 17, '1996-09-02', 'Composer', 120000),
(4, 17, '2008-06-01', 'Composer', 150000),
(3, 18, '1996-06-01', 'Sound Designer', 1470000),
(5, 18, '2002-04-06', 'Sound Designer', 1860000),
(11, 19, '2001-07-02', 'Protagonist', 510000),
(14, 20, '2007-02-02', 'Protagonist', 36000),
(14, 6, '2007-06-21', 'Supporting role', 15000000),
(14, 21, '2007-06-22', 'Antagonist', 600000);
-- Add more rows below...


INSERT INTO Character (cast_id, character_name, role_type)
VALUES 
(20,'Batman','Lead'),
(21,'Joker','Antagonist'),
(19,'Spiderman','Lead'),
(1,'Teddy Daniels','Lead'),
(6,'Ellis Boyd Redding','Friend'),
(3,'Komaram Bheem','Lead'),
(2,'A. Ramaraju','Lead'),
(4,'Sita','Lead'),
(5,'Rose DeWitt Bukater','Lead'),
(7,'Tyler Durden','Lead');
-- Add more rows below...

INSERT INTO Cast_Honors (cast_id, award_id, awarding_organization, judge, award_date, honor_description)
VALUES 
(1, 1, 'Fox', 'John Smith', '2023-02-01', 'Best actor'),
(10, 4, 'Academy', 'Jane Doe', '1998-02-01', 'Best Director'),
(12, 5, 'Academy', 'Jane Doe', '1998-02-01', 'Best Cinematographer'),
(17, 6, 'Academy', 'Jane Doe', '1998-02-01', 'Best Original Song'),
(18, 7, 'Academy', 'Jane Doe', '1998-02-01', 'Best Sound Engineer'),
(13, 8, 'Academy', 'Jane Doe', '2010-02-01', 'Best Art Director'),
(14, 9, 'Academy', 'Jane Doe', '2010-02-01', 'Mindblowing VFX'),
(15, 11, 'Academy', 'Jane Doe', '2010-02-01', 'Best Cinematographer'),
(11, 10, 'Academy', 'Jane Doe', '2018-02-01', 'Best Writer'),
(16, 20, 'BSFC', 'Jane Doe', '2017-02-01', 'Best Cinematographer');

-- Add more rows below...

INSERT INTO [User] (username, [password], email, registration_date)
VALUES 
('hemanth', 'helloworld', 'hemanthnvd@gmail.com', '2021-01-01'),
('john', 'mega2024', 'johnsmith@gmail.com', '2022-01-07'),
('sangram', 'sangram@123', 'sangramshinde@gmail.com', '2022-01-09'),
('charlie', 'corso123', 'charliecorso@gmail.com', '2018-12-02'),
('jillian', 'jill234', 'jillianfox@gmail.com', '2021-11-09'),
('henry', 'ashford@789', 'ashfordhenry@gmail.com', '2021-11-11'),
('walter', 'saymyname', 'walterwhite@gmail.com', '2020-05-06'),
('jessie', 'letscook', 'jessiepinkman@gmail.com', '2016-08-07'),
('bobdavis', 'davis321', 'bob321@gmail.com', '2023-06-01'),
('mike', 'ilovetobox', 'mickey@gmail.com', '2019-01-02');
-- Add more rows below...

INSERT INTO Review (user_id, movie_id, content, rating, review_date)
VALUES 
(1, 1, 'A thrilling ride from start to finish!', 5, '2021-04-01'),
(1, 7, 'Bicycle Thieves is a cinematic gem.', 5, '2021-04-01'),
(10, 4, 'Avatar visuals are breathtaking.', 5, '2021-04-01'),
(5, 6, 'The Shawshank Redemption is a masterpiece.', 5, '2021-04-01'),
(2, 8, 'Fight Club - mind-bending!', 4, '2021-04-01'),
(6, 10, 'Absolutely fantastic. Must watch!', 5, '2021-04-01'),
(7, 8, 'Average', 3, '2021-04-01'),
(4, 3, 'Hated the ending', 2, '2021-04-01'),
(8, 5, 'Finding Nemo is a family favorite.', 5, '2021-04-01'),
(1, 12, 'I love war movies', 5, '2021-04-01'),
(2, 2, 'Compelling story, but a bit slow-paced.', 4, '2021-04-02');
-- Add more rows below...


INSERT INTO Broadcaster (broadcaster_name, street_name, city, [state], country, url_link)
VALUES 
('Movie Network', '123 Main Street', 'Anytown', 'CA', 'USA', 'http://www.movienetwork.com'),
('Global Entertainment', '456 Broadway', 'Cityville', 'NY', 'USA', 'http://www.globalentertainment.tv'),
('CineChannel', '789 Oak Avenue', 'Filmtown', 'LA', 'USA', 'http://www.cinechannel.net'),
('International Films TV', '321 Pine Street', 'Cinemacity', 'CA', 'USA', 'http://www.internationalfilms.tv'),
('MovieFlix', '555 Maple Lane', 'Showville', 'TX', 'USA', 'http://www.movieflix.com'),
('Netflix', 'NA', 'NA', 'NA', 'USA', 'https://www.netflix.com'),
('Amazon Prime Video', 'NA', 'NA', 'NA', 'USA', 'https://www.amazon.com/Prime-Video'),
('Hulu', 'NA', 'NA', 'NA', 'USA', 'https://www.hulu.com'),
('Disney+', 'NA', 'NA', 'NA', 'USA', 'https://www.disneyplus.com'),
('HBO Max', 'NA', 'NA', 'NA', 'USA', 'https://www.hbomax.com'),
('Apple TV+', 'NA', 'NA', 'NA', 'USA', 'https://www.apple.com/apple-tv-plus'),
('Paramount+', 'NA', 'NA', 'NA', 'USA', 'https://www.paramountplus.com'),
('Peacock', 'NA', 'NA', 'NA', 'USA', 'https://www.peacocktv.com'),
('YouTube Premium', 'NA', 'NA', 'NA', 'USA', 'https://www.youtube.com/premium'),
('ESPN+', 'NA', 'NA', 'NA', 'USA', 'https://www.espn.com/watch/espnplus');

-- Add more rows below...

INSERT INTO Movie_Broadcaster (movie_id, broadcast_id, contract_start_date, contract_end_date)
VALUES 
(1, 1, '2022-01-01', '2023-01-01'),
(2, 2, '2021-05-15', '2022-05-15'),
(3, 3, '2021-10-01', '2022-10-01'),
(4, 4, '2021-03-20', '2022-03-20'),
(5, 5, '2021-06-10', '2023-06-10'),
(6, 6, '2022-01-01', '2023-01-01'),
(7, 7, '2021-05-15', '2021-09-15'),
(8, 8, '2021-10-01', '2022-10-01'),
(9, 9, '2021-03-20', '2021-07-20'),
(10, 10, '2021-06-10', '2023-06-10'),
(11, 11, '2022-01-01', '2023-01-01'),
(12, 12, '2021-05-15', '2022-05-15'),
(13, 13, '2021-10-01', '2023-10-01'),
(14, 14, '2021-03-20', '2023-03-20'),
(15, 15, '2021-06-10', '2021-08-10');
-- Add more rows below...



