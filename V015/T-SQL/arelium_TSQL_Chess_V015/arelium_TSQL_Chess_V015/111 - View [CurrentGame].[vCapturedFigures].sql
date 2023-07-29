-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### View [CurrentGame].[vCapturedFigures]                                               ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### This view determines the already captured pieces of both players. For this purpose, ###
-- ### the pieces of the current position are compared with those of the starting          ###
-- ### position. Deviations are displayed graphically, whereby a distinction is made       ###
-- ### between pawns and other pieces.                                                     ###
-- ###                                                                                     ###
-- ### The result contains an "ID" column. It is used for the JOIN possibility to display  ###
-- ### the individual blocks of the dashboard (the overall view from the board, move       ###
-- ### preview, captured pieces, statistics for the position evaluation, ...). The         ###
-- ### graphical representation of the pieces uses the REPLICATE statement to put the      ###
-- ### correct number of elements one after the other.                                     ###                   
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

CREATE OR ALTER VIEW [CurrentGame].[vCapturedFigures]
AS

	SELECT
		  1				AS [ID]
		, REPLICATE(NCHAR(9817), (SELECT 8 - COUNT(*) FROM [Infrastructure].[GameBoard] WHERE [IsPlayerWhite] = 'TRUE' AND [FigureLetter] = 'P'))
						AS [captured piece(s)]
	UNION ALL
	SELECT
		  2
		, REPLICATE(NCHAR(9815), (SELECT 2 - COUNT(*) FROM [Infrastructure].[GameBoard] WHERE [IsPlayerWhite] = 'TRUE' AND [FigureLetter] = 'B'))
		+ REPLICATE(NCHAR(9816), (SELECT 2 - COUNT(*) FROM [Infrastructure].[GameBoard] WHERE [IsPlayerWhite] = 'TRUE' AND [FigureLetter] = 'N'))
		+ REPLICATE(NCHAR(9814), (SELECT 2 - COUNT(*) FROM [Infrastructure].[GameBoard] WHERE [IsPlayerWhite] = 'TRUE' AND [FigureLetter] = 'R'))
		+ REPLICATE(NCHAR(9813), (SELECT 1 - COUNT(*) FROM [Infrastructure].[GameBoard] WHERE [IsPlayerWhite] = 'TRUE' AND [FigureLetter] = 'Q'))
	UNION ALL
	SELECT 3,''
	UNION ALL
	SELECT
		  4	
		, REPLICATE(NCHAR(9823), (SELECT 8 - COUNT(*) FROM [Infrastructure].[GameBoard] WHERE [IsPlayerWhite] = 'FALSE' AND [FigureLetter] = 'P'))
	UNION ALL
	SELECT
		  5
		, REPLICATE(NCHAR(9821), (SELECT 2 - COUNT(*) FROM [Infrastructure].[GameBoard] WHERE [IsPlayerWhite] = 'FALSE' AND [FigureLetter] = 'B'))
		+ REPLICATE(NCHAR(9822), (SELECT 2 - COUNT(*) FROM [Infrastructure].[GameBoard] WHERE [IsPlayerWhite] = 'FALSE' AND [FigureLetter] = 'N'))
		+ REPLICATE(NCHAR(9820), (SELECT 2 - COUNT(*) FROM [Infrastructure].[GameBoard] WHERE [IsPlayerWhite] = 'FALSE' AND [FigureLetter] = 'R'))
		+ REPLICATE(NCHAR(9819), (SELECT 1 - COUNT(*) FROM [Infrastructure].[GameBoard] WHERE [IsPlayerWhite] = 'FALSE' AND [FigureLetter] = 'Q'))
GO

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistics ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '111 - View [CurrentGame].[vCapturedFigures].sql'
PRINT ' '
PRINT 'Script     :   ' + @Script
PRINT 'End        :   ' + @End
PRINT 'Time       :   ' + @Time
SELECT @Script AS Skript, @End AS Ende, @Time AS Zeit
GO


/*
SELECT * FROM [CurrentGame].[vCapturedFigures]
*/