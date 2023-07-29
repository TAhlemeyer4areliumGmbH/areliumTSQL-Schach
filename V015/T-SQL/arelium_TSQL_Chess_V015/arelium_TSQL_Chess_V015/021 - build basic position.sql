-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### Initialisation of the basic position                                                ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### This script empties the playing field and builds up all the pieces of a chess game  ###
-- ### in such a way that the basic position to be taken according to the rules of the     ###
-- ### game is reached.                                                                    ###
-- ### White plays from row 1 to row 8, black plays in the opposite direction. On the      ###
-- ### basic row of both colours from A to H are the following pieces: (R), (N), (B), (Q), ###
-- ### (K), with R=rook, N=knight, B=bishop, Q=queen and K=king. The Rows 2 (White) and    ###
-- ### 7 (Black) are exclusively occupied by pawns.                                        ###
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

-- The UPDATE commands are stored in a procedure and can therefore be easily called from anywhere. 
CREATE OR ALTER PROCEDURE [Infrastructure].[prcBuildBasicPosition]
AS
BEGIN
	SET NOCOUNT ON;

	-- All fields are initially filled with a protected space. In this way, the 
	-- empty board is set up. The pieces are added in a later step...
	-- The insertion is done in two nested loops, as the information for
	-- rows and columns have to be incremented.
	TRUNCATE TABLE [Infrastructure].[GameBoard]

	DECLARE @LoopRow		AS INTEGER
	DECLARE @LoopColumn		AS CHAR(1)
	DECLARE @Field			AS INTEGER

	SET @LoopColumn = 'A'

	WHILE ASCII(@LoopColumn) BETWEEN ASCII('A') AND ASCII('H')
	BEGIN
		SET @LoopRow = 1
		WHILE @LoopRow BETWEEN 1 AND 8
		BEGIN
			SET @Field = ((ASCII(@LoopColumn) - 65) * 8) + @LoopRow
			INSERT INTO [Infrastructure].[GameBoard] ([Column], [Row], [Field], [IsPlayerWhite], [FigureLetter], [FigureUTF8])
				VALUES (@LoopColumn, @LoopRow, @Field, NULL, CHAR(160), 160)
		
			SET @LoopRow = @LoopRow + 1
		END
		SET @LoopColumn = CHAR(ASCII(@LoopColumn) + 1)
	END

	-- ----------------------------------------------------
	-- clear all fields
	-- ----------------------------------------------------
	UPDATE [Infrastructure].[GameBoard]	
	SET [FigureUTF8] = 160, [FigureLetter] = ' ', [IsPlayerWhite] = NULL

	-- ----------------------------------------------------
	-- white pawns on row 2
	-- ----------------------------------------------------
	UPDATE [Infrastructure].[GameBoard]	
	SET [FigureUTF8] = 9817, [FigureLetter] = 'P', [IsPlayerWhite] = 'TRUE' 
	WHERE	1 = 1
		AND [Row]		= 2

	-- ----------------------------------------------------
	-- black pawns on row 7
	-- ----------------------------------------------------
	UPDATE [Infrastructure].[GameBoard]	
	SET [FigureUTF8] = 9823, [FigureLetter] = 'P', [IsPlayerWhite] = 'FALSE'
	WHERE	1 = 1
		AND [Row]		= 7
				

	-- ----------------------------------------------------
	-- white rooks on a1 and h1
	-- ----------------------------------------------------
	UPDATE [Infrastructure].[GameBoard]	
	SET [FigureUTF8] = 9814 , [FigureLetter] = 'R', [IsPlayerWhite] = 'TRUE'
	WHERE	1 = 1
		AND [Row]		= 1
		AND [Column]	IN ('A', 'H')

	-- ----------------------------------------------------
	-- black rooks on a8 and h8
	-- ----------------------------------------------------
	UPDATE [Infrastructure].[GameBoard]	
	SET [FigureUTF8] = 9820, [FigureLetter] = 'R', [IsPlayerWhite] = 'FALSE'
	WHERE	1 = 1
		AND [Row]		= 8
		AND [Column]	IN ('A', 'H')

	-- ----------------------------------------------------
	-- white knights on b1 and g1
	-- ----------------------------------------------------
	UPDATE [Infrastructure].[GameBoard]	
	SET [FigureUTF8] = 9816, [FigureLetter] = 'N', [IsPlayerWhite] = 'TRUE'
	WHERE	1 = 1
		AND [Row]		= 1
		AND [Column]	IN ('B', 'G')

	-- ----------------------------------------------------
	-- black knights on b8 and g8
	-- ----------------------------------------------------
	UPDATE [Infrastructure].[GameBoard]	
	SET [FigureUTF8] = 9822, [FigureLetter] = 'N', [IsPlayerWhite] = 'FALSE'
	WHERE	1 = 1
		AND [Row]		= 8
		AND [Column]	IN ('B', 'G')

	-- ----------------------------------------------------
	-- white bishops on c1 and f1
	-- ----------------------------------------------------
	UPDATE [Infrastructure].[GameBoard]	
	SET [FigureUTF8] = 9815, [FigureLetter] = 'B', [IsPlayerWhite] = 'TRUE'
	WHERE	1 = 1
		AND [Row]		= 1
		AND [Column]	IN ('C', 'F')

	-- ----------------------------------------------------
	-- black bishops on c8 and f8
	-- ----------------------------------------------------
	UPDATE [Infrastructure].[GameBoard]	
	SET [FigureUTF8] = 9821, [FigureLetter] = 'B', [IsPlayerWhite] = 'FALSE'
	WHERE	1 = 1
		AND [Row]		= 8
		AND [Column]	IN ('C', 'F')

	-- ----------------------------------------------------
	-- white queen on d1
	-- ----------------------------------------------------
	UPDATE [Infrastructure].[GameBoard]	
	SET [FigureUTF8] = 9813, [FigureLetter] = 'Q', [IsPlayerWhite] = 'TRUE' 
	WHERE	1 = 1
		AND [Row]		= 1
		AND [Column]	= 'D'

	-- ----------------------------------------------------
	-- black queen on d8
	-- ----------------------------------------------------
	UPDATE [Infrastructure].[GameBoard]	
	SET [FigureUTF8] = 9819, [FigureLetter] = 'Q', [IsPlayerWhite] = 'FALSE'
	WHERE	1 = 1
		AND [Row]		= 8
		AND [Column]	= 'D'

	-- ----------------------------------------------------
	-- white king on e8
	-- ----------------------------------------------------
	UPDATE [Infrastructure].[GameBoard]	
	SET [FigureUTF8] = 9812, [FigureLetter] = 'K', [IsPlayerWhite] = 'TRUE'
	WHERE	1 = 1
		AND [Row]		= 1
		AND [Column]	= 'E'

	-- ----------------------------------------------------
	-- black king on e8
	-- ----------------------------------------------------
	UPDATE [Infrastructure].[GameBoard]	
	SET [FigureUTF8] = 9818, [FigureLetter] = 'K', [IsPlayerWhite] = 'FALSE' 
	WHERE 1 = 1
		AND [Row]		= 8
		AND [Column]	= 'E'



	-- Alle Einträge dieses Spiels aus der Tabelle [Spiel].[Notation] löschen
	DELETE 
	FROM [CurrentGame].[Notation]
	WHERE 1 = 1


END
GO



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistics ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '021 - build basic position.sql'
PRINT ' '
PRINT 'Script     :   ' + @Script
PRINT 'End        :   ' + @End
PRINT 'Time       :   ' + @Time
SELECT @Script AS Skript, @End AS Ende, @Time AS Zeit
GO




/*
USE [arelium_TSQL_Chess_V015]
GO

EXEC [Infrastructure].[prcBuildBasicPosition]
GO

*/