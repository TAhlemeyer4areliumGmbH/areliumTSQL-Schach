-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### FUNCTION [Infrastructure].[fncEFN2Position]                                         ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### An EFN string is read in and the information contained there is transferred into a  ###
-- ### concrete position. In this function, only a part of the EFN string is relevant -    ###
-- ### the notation also contains further meta information. In this way, the EFN notation  ###
-- ### can also be used to judge whether an "en passant" move is allowed as the next       ###
-- ### action, whether one still has the right to a long/short castling move or whether it ###
-- ### is his move.       Details: https://www.embarc.de/fen-forsyth-edwards-notation/     ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Security note:                                                                      ###
-- ###    This collection of commands is used to create, alter oder drop objects or insert ###
-- ###    update or delete content. This script must NOT be used in productive             ###
-- ###    environments, to avoid accidental effects on other structures.                   ###
-- ###                                                                                     ###
-- ### Creation:                                                                           ###
-- ###   Torsten Ahlemeyer for arelium GmbH, (https://www.arelium.de)                      ###
-- ###   Contact: torsten.ahlemeyer@arelium.de                                             ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### A big thank you goes to (MVP) Uwe Ricken, who helped the project with motivation,   ###
-- ### advice and especially (but not only) in the area of runtime optimisation and        ###
-- ### continues to do so (https://www.db-berater.de/).                                    ###
-- ###                                                                                     ###
-- ### Another thank you goes to Ralph Kemperdick, who supports the project in an advisory ###
-- ### capacity. With his large network, especially in the Microsoft world, he makes many  ###
-- ### problem-solving approaches possible in the first place.                             ###
-- ###                                                                                     ###
-- ### Also extremely helpful is Buck Woody. The long-time Microsoft employee was          ###
-- ### persuaded by this project at a conference and has since supported it with his       ###
-- ### enormous reach and experience in adult education. Buck knows the perfect contacts   ###
-- ### to make the chess programme known worldwide.                                        ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Changelog:                                                                          ###
-- ###     15.00.0   2023-07-07 Torsten Ahlemeyer                                          ###
-- ###               Initial creation with default values                                  ###
-- ###########################################################################################
-- ### COPYRIGHT notice  (see https://creativecommons.org/licenses/by-nc-sa/3.0/de/)       ###
-- ###                    or https://creativecommons.org/licenses/by-nc-sa/3.0/de/deed.en) ###
-- ###########################################################################################
-- ### This work is licensed under the CC-BY-NC-SA licence, i.e. it may be freely          ###
-- ### downloaded, in any format or medium, and redistributed under the same licence       ###
-- ### conditions.                                                                         ###
-- ### However, commercial use is excluded. The work may be modified and you may base your ###
-- ### own projects on this code. Appropriate copyright and rights information must be     ###
-- ### provided, a link to the licence must be included and changes must be indicated.     ###
-- ###########################################################################################


--------------------------------------------------------------------------------------------------
-- Runtime statistics for this script ------------------------------------------------------------
--------------------------------------------------------------------------------------------------

-- Create a temporary table to remember the start time
BEGIN TRY
	DROP TABLE #Start
END TRY
BEGIN CATCH
END CATCH

CREATE TABLE #Start (StartTime DATETIME)
INSERT INTO #Start (StartTime) VALUES (GETDATE())

--------------------------------------------------------------------------------------------------
-- Compatibility block ---------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

-- Switch to the project database
USE [arelium_TSQL_Chess_V015]
GO

-- Specifies that the equal (=) and unequal (<>) comparison operators must behave in an 
-- ISO-compliant manner when used with NULL values in SQL Server 2019 (15.x).
-- ANSI NULLS ON is a new T-SQL standard and will be fixed in later versions.
SET ANSI_NULLS ON
GO

-- Causes SQL Server to obey the ISO rules for leading characters in identifiers and literal strings.
SET QUOTED_IDENTIFIER ON
GO



--------------------------------------------------------------------------------------------------
-- Clean-up --------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

-- All objects that are created or changed by this script are listed here. Since some DDL
-- commands do not have an IF-EXISTS syntax, this is the first place to clean up the list. Existing 
-- objects are deleted by DROP, so that they can be re-created later in an orderly fashion.

--------------------------------------------------------------------------------------------------
-- Construction work -----------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------


CREATE OR ALTER FUNCTION [Infrastructure].[fncEFN2Position]
	(
		  @EFN					AS VARCHAR(255)
	)
RETURNS @EFN2Position TABLE
	(
	  [Column]					CHAR(1)		NOT NULL						-- A-H
	, [Row]						TINYINT		NOT NULL						-- 1-8
	, [Field]					TINYINT		NOT NULL						-- A1 = 1, A2 = 2, ..., B1 = 9, ..., H8 = 64
	, [EFNPositionNr]			TINYINT		NOT NULL						-- A1 = 1, B1 = 2, ..., A2 = 9, ..., H8 = 64
	, [IsPlayerWhite]			BIT			NULL							-- 1 = TRUE
	, [FigureLetter]			CHAR(1)		NULL						
		CHECK ([FigureLetter] IN (NULL, 'B', 'N', 'R', 'K', 'Q', 'P'))
	, [FigureUTF8]				BIGINT		NULL		
	)

BEGIN
	--DECLARE @PositionString		AS VARCHAR(64)
	--DECLARE @Row				AS TINYINT
	--DECLARE @Column				AS TINYINT
	--DECLARE @StringPart			AS VARCHAR(8)
	--DECLARE @ID					AS TINYINT
	DECLARE @Letter				AS CHAR(1)

	-- --------------------------------------------------------------
	-- Step 1: resolve several empty fields in succession
	-- --------------------------------------------------------------

	-- The board data is extracted from the EFN string.
	SET @EFN				= LEFT(@EFN, CHARINDEX(' ', @EFN, 1) - 1)
	SET @EFN				= TRIM(@EFN)
	SET @EFN				= REPLACE(@EFN, '/', '')
	SET @EFN				= REPLACE(@EFN, '1', '?')
	SET @EFN				= REPLACE(@EFN, '2', '??')
	SET @EFN				= REPLACE(@EFN, '3', '???')
	SET @EFN				= REPLACE(@EFN, '4', '????')
	SET @EFN				= REPLACE(@EFN, '5', '?????')
	SET @EFN				= REPLACE(@EFN, '6', '??????')
	SET @EFN				= REPLACE(@EFN, '7', '???????')
	SET @EFN				= REPLACE(@EFN, '8', '????????')

	-- --------------------------------------------------------------
	-- Step 2: Evaluate the position information of the figures
	-- --------------------------------------------------------------
	INSERT INTO @EFN2Position
		( [Column]
		, [Row]
		, [Field]
		, [EFNPositionNr]
		, [IsPlayerWhite]
		, [FigureLetter]
		, [FigureUTF8])
	SELECT 
		  [Column]													AS [Column]
		, [Row]														AS [Row]
		, [Field]													AS [Field]
		, [EFNPositionNr]											AS [EFNPositionNr]
		, CASE SUBSTRING(@EFN, [EFNPositionNr], 1)
			WHEN '?' COLLATE Latin1_General_CS_AI THEN NULL
			WHEN 'r' COLLATE Latin1_General_CS_AI THEN 'FALSE'
			WHEN 'R' COLLATE Latin1_General_CS_AI THEN 'TRUE'
			WHEN 'n' COLLATE Latin1_General_CS_AI THEN 'FALSE'
			WHEN 'N' COLLATE Latin1_General_CS_AI THEN 'TRUE'
			WHEN 'b' COLLATE Latin1_General_CS_AI THEN 'FALSE'
			WHEN 'B' COLLATE Latin1_General_CS_AI THEN 'TRUE'
			WHEN 'q' COLLATE Latin1_General_CS_AI THEN 'FALSE'
			WHEN 'Q' COLLATE Latin1_General_CS_AI THEN 'TRUE'
			WHEN 'k' COLLATE Latin1_General_CS_AI THEN 'FALSE'
			WHEN 'K' COLLATE Latin1_General_CS_AI THEN 'TRUE'
			WHEN 'p' COLLATE Latin1_General_CS_AI THEN 'FALSE'
			WHEN 'P' COLLATE Latin1_General_CS_AI THEN 'TRUE'
			END														AS [IsPlayerWhite]
		, CASE SUBSTRING(@EFN, [EFNPositionNr], 1)
			WHEN '?' COLLATE Latin1_General_CS_AI THEN NULL
			WHEN 'r' COLLATE Latin1_General_CS_AI THEN 'R'
			WHEN 'R' COLLATE Latin1_General_CS_AI THEN 'R'
			WHEN 'n' COLLATE Latin1_General_CS_AI THEN 'N'
			WHEN 'N' COLLATE Latin1_General_CS_AI THEN 'N'
			WHEN 'b' COLLATE Latin1_General_CS_AI THEN 'B'
			WHEN 'B' COLLATE Latin1_General_CS_AI THEN 'B'
			WHEN 'q' COLLATE Latin1_General_CS_AI THEN 'Q'
			WHEN 'Q' COLLATE Latin1_General_CS_AI THEN 'Q'
			WHEN 'k' COLLATE Latin1_General_CS_AI THEN 'K'
			WHEN 'K' COLLATE Latin1_General_CS_AI THEN 'K'
			WHEN 'p' COLLATE Latin1_General_CS_AI THEN 'P'
			WHEN 'P' COLLATE Latin1_General_CS_AI THEN 'P'
			END														AS [FigureLetter]
		, CASE SUBSTRING(@EFN, [EFNPositionNr], 1)
			WHEN '?' COLLATE Latin1_General_CS_AI THEN 160
			WHEN 'r' COLLATE Latin1_General_CS_AI THEN 9820
			WHEN 'R' COLLATE Latin1_General_CS_AI THEN 9814
			WHEN 'n' COLLATE Latin1_General_CS_AI THEN 9822
			WHEN 'N' COLLATE Latin1_General_CS_AI THEN 9816
			WHEN 'b' COLLATE Latin1_General_CS_AI THEN 9821
			WHEN 'B' COLLATE Latin1_General_CS_AI THEN 9815
			WHEN 'q' COLLATE Latin1_General_CS_AI THEN 9819
			WHEN 'Q' COLLATE Latin1_General_CS_AI THEN 9813
			WHEN 'k' COLLATE Latin1_General_CS_AI THEN 9818
			WHEN 'K' COLLATE Latin1_General_CS_AI THEN 9812
			WHEN 'p' COLLATE Latin1_General_CS_AI THEN 9823
			WHEN 'P' COLLATE Latin1_General_CS_AI THEN 9817
			END														AS [FigureUTF8]
	FROM [Infrastructure].[GameBoard]

	RETURN
END
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistics ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '614 - Function [Infrastructure].[fncEFN2Position].sql'
PRINT ' '
PRINT 'Script     :   ' + @Script
PRINT 'End        :   ' + @End
PRINT 'Time       :   ' + @Time
SELECT @Script AS Skript, @End AS Ende, @Time AS Zeit
GO


/*

USE [arelium_TSQL_Chess_V015]
GO

DECLARE @EFN varchar(255)

SET @EFN = 'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR w KkQq a3 3 1'
--SET @EFN = '6r1/6pp/7r/1B5K/1P3k2/N7/3R4/8 w - - 30 79'

TRUNCATE TABLE [Infrastructure].[GameBoard]

INSERT INTO [Infrastructure].[GameBoard]
	([Column], [Row], [Field], [EFNPositionNr], [IsPlayerWhite], [FigureLetter] ,[FigureUTF8])
	SELECT  [Column], [Row], [Field], [EFNPositionNr], [IsPlayerWhite], [FigureLetter], [FigureUTF8]
	FROM [Infrastructure].[fncEFN2Position](@EFN)
	ORDER BY Field
GO

SELECT * FROM [Infrastructure].[vDashboard]
GO
*/
 