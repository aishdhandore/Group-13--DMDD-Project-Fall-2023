---------------------------------------------------------
-- View to Display Cast and Crew Information for a Movie:

CREATE VIEW vw_MovieCastCrew AS
SELECT
m.title AS movie_title,
cc.[name] AS cast_crew_name,
cc.date_of_birth,
cc.date_of_first_movie,
cc.nationality,
cc.gender,
cc.cast_type
FROM
Movie_Role mr
JOIN Movie m ON mr.movie_id = m.movie_id
JOIN Cast_Crew cc ON mr.cast_id = cc.cast_id;
GO

select * from vw_MovieCastCrew;

GO
---------------------------------------------------------
CREATE VIEW vw_MovieReviews AS
SELECT
r.review_id,
u.username,
m.title AS movie_title,
r.content,
r.rating,
r.review_date
FROM
Review r
JOIN [User] u ON r.user_id = u.user_id
JOIN Movie m ON r.movie_id = m.movie_id;
GO

SELECT * FROM vw_MovieReviews;
GO
-------------------------------------------------------------------
-- View to Show Movie Statistics:
ALTER VIEW vw_MovieStatistics AS
SELECT
    m.movie_id,
    m.title,
    m.release_year,
    m.duration,
    m.language,
    m.budget,
    m.revenue,
    pc.company_name AS production_company,
    (
        SELECT STRING_AGG(g.genre_name, ', ') 
        FROM (
            SELECT DISTINCT g.genre_name
            FROM Movie_Genre mg 
            JOIN Genre g ON mg.genre_id = g.genre_id
            WHERE mg.movie_id = m.movie_id
        ) g
    ) AS genres,
    COUNT(DISTINCT r.review_id) AS total_reviews,
    AVG(r.rating) AS average_rating
FROM
    Movie m
JOIN 
    ProductionCompany pc ON m.company_id = pc.company_id
LEFT JOIN 
    Review r ON m.movie_id = r.movie_id
GROUP BY
    m.movie_id, m.title, m.release_year, m.duration, m.language, m.budget, m.revenue, pc.company_name;
    
GO
SELECT * from vw_MovieStatistics;
GO

==================================================
--users who have written more than 3 reviews.

ALTER VIEW ActiveUsers AS
SELECT
    u.user_id,
    u.username,
    COUNT(r.review_id) AS NumberOfReviews
FROM
    [User] u
JOIN
    Review r ON u.user_id = r.user_id
GROUP BY
    u.user_id, u.username
HAVING
    COUNT(r.review_id) > 3

SELECT * From ActiveUsers ORDER BY NumberOfReviews DESC;

=========================================================
--top genres based on the average ratings of movies in each genre
CREATE VIEW TopGenres AS
SELECT
    g.genre_id,
    g.genre_name,
    CAST(AVG(CAST(r.rating AS DECIMAL(10, 2))) AS DECIMAL(10, 2)) AS AverageRating
FROM
    Genre g
JOIN
    Movie_Genre mg ON g.genre_id = mg.genre_id
JOIN
    Movie m ON mg.movie_id = m.movie_id
LEFT JOIN
    Review r ON m.movie_id = r.movie_id
GROUP BY
    g.genre_id, g.genre_name

SELECT * FROM TopGenres
ORDER BY AverageRating DESC;

----------------------------------------------------------------------------------------------------------
USE [MovieDatabase]
GO

ALTER FUNCTION dbo.GetLongestContractBroadcaster (@TopN INT)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (@TopN) b.broadcaster_name, DATEDIFF(DAY, mb.contract_start_date, mb.contract_end_date) AS ContractLength
    FROM Broadcaster b
    JOIN Movie_Broadcaster mb ON b.broadcast_id = mb.broadcast_id
    ORDER BY DATEDIFF(DAY, mb.contract_start_date, mb.contract_end_date) DESC
);
GO


SELECT * From dbo.GetLongestContractBroadcaster(5) AS LongestContractBroadcaster;
GO
------------------------------------------------------------------------------------

CREATE FUNCTION dbo.IsFinanciallySuccessful(@MovieID INT, @SuccessThreshold DECIMAL(5, 2))
RETURNS TABLE
AS
RETURN
(
    
    SELECT 
        m.movie_id, 
        m.title,
        m.budget,
        m.revenue,
        CASE 
            WHEN m.revenue >= m.budget * (1 + @SuccessThreshold / 100) THEN 'Yes'
            ELSE 'No'
        END AS IsSuccessful
    FROM 
        Movie m
    WHERE 
        m.movie_id = @MovieID
);

GO

SELECT * FROM dbo.IsFinanciallySuccessful(3, 30);
GO


ALTER FUNCTION dbo.GetAverageDurationByGenre(@GenreName VARCHAR(255))
RETURNS VARCHAR(10)
AS
BEGIN
    DECLARE @AverageDuration DECIMAL(10, 2);

    SELECT @AverageDuration = AVG(CAST(m.duration AS DECIMAL(10, 2)))
    FROM Movie m
    JOIN Movie_Genre mg ON m.movie_id = mg.movie_id
    JOIN Genre g ON mg.genre_id = g.genre_id
    WHERE g.genre_name = @GenreName;

    DECLARE @hours INT, @minutes INT, @formatted_duration VARCHAR(10);
    SET @hours = @AverageDuration / 60;
    SET @minutes = @AverageDuration % 60;
    SET @formatted_duration = CONCAT(@hours, 'h ', @minutes, 'min');
    RETURN @formatted_duration;

    RETURN ISNULL(@formatted_duration, 0);
END;
GO

SELECT dbo.GetAverageDurationByGenre('Action') AS AvgDuration;

USE [MovieDatabase]
GO


CREATE TABLE MovieAuditLog (
    AuditLogID INT IDENTITY(1,1) PRIMARY KEY,
    MovieID INT,
    OldRevenue DECIMAL(15, 2),
    NewRevenue DECIMAL(15, 2),
    UpdateDateTime DATETIME
);
GO


----------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_AuditMovieUpdate
ON Movie
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(budget) OR UPDATE(revenue)
    BEGIN
        INSERT INTO MovieAuditLog (MovieID, OldRevenue, NewRevenue, UpdateDateTime)
        SELECT 
            i.movie_id,
            d.revenue AS OldRevenue,
            i.revenue AS NewRevenue,
            GETDATE()
        FROM 
            inserted i
        INNER JOIN 
            deleted d ON i.movie_id = d.movie_id;
    END
END;
GO



SELECT * FROM Movie;
UPDATE Movie SET revenue = 305500000.00
WHERE movie_id = 1;

SELECT * FROM MovieAuditLog
----------------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------------
USE [MovieDatabase]
GO

--Create a master key for the database
CREATE MASTER KEY
ENCRYPTION BY PASSWORD = 'Password@123';

-- verify that master key exists
SELECT name KeyName,
symmetric_key_id KeyID,
key_length KeyLength,
algorithm_desc KeyAlgorithm
FROM sys.symmetric_keys;
GO

--Create a self signed certificate and name it UserPass

CREATE CERTIFICATE UserPass
WITH SUBJECT = 'User Password';
GO

--Create a symmetric key with AES 256 algorithm using the certificate as encryption/decryption method

CREATE SYMMETRIC KEY UserPass_SM
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE UserPass;
GO

--Now we are ready to encrypt the password and also decrypt
-- Open the symmetric key with which to encrypt the data.

OPEN SYMMETRIC KEY UserPass_SM
DECRYPTION BY CERTIFICATE UserPass;

-- Encrypt the value in column Password with symmetric key
UPDATE dbo.[User] 
SET [password] = EncryptByKey(Key_GUID('UserPass_SM'), convert(varbinary, [password]))
GO

-- First open the symmetric key with which to decrypt the data.
OPEN SYMMETRIC KEY UserPass_SM
DECRYPTION BY CERTIFICATE UserPass;
SELECT *,
CONVERT(varchar, DecryptByKey([password]))
AS 'Decrypted password'
FROM dbo.[User];
GO


----------------------------------------------------------------------------------------------------------
--NONCLUSTERED INDEX
CREATE NONCLUSTERED INDEX NCI_ListMoviesByGenre_MovieGenre
ON Movie_Genre(genre_id, movie_id);


CREATE NONCLUSTERED INDEX NCI_ListMoviesByGenre_Genre
ON Genre(genre_id, genre_name);


CREATE NONCLUSTERED INDEX NCI_GetTopRatedMoviesByYear_Review
ON Review(movie_id, rating);

USE [MovieDatabase]
GO

----------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------

CREATE FUNCTION dbo.CalculateAge (@BirthDate DATE)
RETURNS INT
AS
BEGIN
    RETURN DATEDIFF(YEAR, @BirthDate, GETDATE()) - 
           CASE
               WHEN (MONTH(@BirthDate) > MONTH(GETDATE())) OR 
                    (MONTH(@BirthDate) = MONTH(GETDATE()) AND DAY(@BirthDate) > DAY(GETDATE())) 
               THEN 1
               ELSE 0
           END
END
GO

ALTER TABLE Cast_Crew
ADD Age AS dbo.CalculateAge(date_of_birth)
GO

CREATE FUNCTION dbo.CalculateExperience (@FirstMovieDate DATE)
RETURNS INT
AS
BEGIN
    RETURN DATEDIFF(YEAR, @FirstMovieDate, GETDATE()) - 
           CASE
               WHEN (MONTH(@FirstMovieDate) > MONTH(GETDATE())) OR 
                    (MONTH(@FirstMovieDate) = MONTH(GETDATE()) AND DAY(@FirstMovieDate) > DAY(GETDATE())) 
               THEN 1
               ELSE 0
           END
END
GO

ALTER TABLE Cast_Crew
ADD Experience AS dbo.CalculateAge(date_of_first_movie)
GO

----------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------
USE [MovieDatabase]
GO

ALTER PROCEDURE GetTopRatedMoviesByYear
    @Year INT,
    @TopN INT
AS
BEGIN
    SELECT TOP (@TopN) m.movie_id, m.title, AVG(r.rating) as AvgRating
    FROM Movie m
    JOIN Review r ON m.movie_id = r.movie_id
    WHERE m.release_year = @Year
    GROUP BY m.movie_id, m.title
    ORDER BY AvgRating DESC;
END;
GO

SELECT * FROM Movie
SELECT * FROM Review

EXEC GetTopRatedMoviesByYear 2022, 5
GO
--------------------------------------------------------------------------

ALTER PROCEDURE DeleteMovieAndRelatedRecords
    @MovieID INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Delete related records in other tables before deleting the movie
        DELETE FROM Movie_Honors WHERE movie_id = @MovieID;
        DELETE FROM Movie_Genre WHERE movie_id = @MovieID;
        DELETE FROM Review WHERE movie_id = @MovieID;
        DELETE FROM Movie_Broadcaster WHERE movie_id = @MovieID;
        DELETE FROM Movie_Role WHERE movie_id = @MovieID;  -- Add this line to delete related broadcaster records
        DELETE FROM Movie WHERE movie_id = @MovieID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO


EXEC DeleteMovieAndRelatedRecords 13

SELECT * FROM Movie WHERE movie_id = @MovieID;
SELECT * FROM Movie_Genre WHERE movie_id = @MovieID;
SELECT * FROM Review WHERE movie_id = @MovieID;
SELECT * FROM Movie_Honors WHERE movie_id = @MovieID;
SELECT * FROM Movie_Broadcaster WHERE movie_id = @MovieID;
SELECT * FROM Movie_Role WHERE movie_id = 15;
GO
-----------------------------------------------------------------------------

ALTER PROCEDURE AddNewMovieWithGenre
    @CompanyName VARCHAR(255),
    @Title VARCHAR(255),
    @ReleaseYear INT,
    @Duration INT,
    @Language VARCHAR(50),
    @Budget DECIMAL(15, 2),
    @Revenue DECIMAL(15, 2),
    @GenreName VARCHAR(255),
    @MovieID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @CompanyID INT, @GenreID INT;

            SELECT @CompanyID = company_id FROM ProductionCompany WHERE company_name = @CompanyName;
            IF @CompanyID IS NULL
                THROW 50001, 'Production company not found.', 1;

            SELECT @GenreID = genre_id FROM Genre WHERE genre_name = @GenreName;
            IF @GenreID IS NULL
                THROW 50002, 'Genre not found.', 1;

            INSERT INTO Movie (company_id, title, release_year, duration, [language], budget, revenue)
            VALUES (@CompanyID, @Title, @ReleaseYear, @Duration, @Language, @Budget, @Revenue);
            SET @MovieID = SCOPE_IDENTITY();

            INSERT INTO Movie_Genre (movie_id, genre_id)
            VALUES (@MovieID, @GenreID);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        --DECLARE @currentSeed INT;
        --SET @currentSeed = IDENT_CURRENT('Movie');
        --SET @currentSeed -= 1;
        --DBCC CHECKIDENT ('Movie', RESEED, @currentSeed);
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO


DECLARE @NewMovieID INT;

EXEC AddNewMovieWithGenre
    @CompanyName = 'Paramount Pictures', -- Replace with an existing company name in your database
    @Title = 'Ugh',
    @ReleaseYear = 2015,
    @Duration = 120, -- Duration in minutes
    @Language = 'English',
    @Budget = 5000000.00, -- Example budget
    @Revenue = 610000000.00,
    @GenreName = 'Drama', -- Replace with an existing genre in your database
    @MovieID = @NewMovieID OUTPUT;

SELECT @NewMovieID as MovieID;

SELECT * FROM Movie
--Paramount Pictures

DBCC CHECKIDENT ('Movie', NORESEED);
DBCC CHECKIDENT ('Movie', RESEED, 25);

GO

------------------------------------------------------------

CREATE PROCEDURE ListMoviesByGenre
    @GenreName VARCHAR(255)
AS
BEGIN
    SELECT m.movie_id, m.title, m.release_year, m.duration
    FROM Movie m
    JOIN Movie_Genre mg ON m.movie_id = mg.movie_id
    JOIN Genre g ON mg.genre_id = g.genre_id
    WHERE g.genre_name = @GenreName;
END;
GO

EXEC ListMoviesByGenre 'Action'

-------------------------------------------------------------------------------------------




