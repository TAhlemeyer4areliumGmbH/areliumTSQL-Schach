-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### Insert content initially                                                            ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### When a new game is started, some settings and preparations have to be made. The     ###
-- ### board has to be set up, the starting position has to be taken, the active player    ###
-- ### has to be determined, etc....                                                       ###
-- ###                                                                                     ###
-- ### In addition, the players are to be configured: Names, playing strength, auxiliary   ###
-- ### functions to be used, ...                                                           ###
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
-- The table [CurrentGame].[Configuration] is read out, where among other things the playing strength 
-- of both players is stored. Depending on the values mentioned here, the position evaluation is 
-- based on different criteria. Details on this can be found in the table [Infrastructure].[Level]
CREATE OR ALTER PROCEDURE [CurrentGame].[prcInitialisation] 
	  @NameWhite					AS NVARCHAR(30)
	, @NameBlack					AS NVARCHAR(30)
	, @IsPlayerHumanWhite			AS BIT
	, @IsPlayerHumanBlack			AS BIT
	, @LevelWhite					AS TINYINT
	, @LevelBlack					AS TINYINT
	, @RemainingTimeWhiteInSeconds	AS INTEGER
	, @RemainingTimeBlackInSeconds	AS INTEGER
AS
BEGIN
	SET NOCOUNT ON;

	-- Set up basic position
	EXECUTE [Infrastructure].[prcSetUpBasicPosition]

	-- Create player record
	TRUNCATE TABLE [CurrentGame].[Configuration]

	INSERT INTO [CurrentGame].[Configuration]
           ( [IsPlayerWhite]
           , [PlayerName]
           , [LevelID]
		   , [RemainingTimeInSeconds]
		   , [TimestampLastMove])
     VALUES
             ('FALSE'	, @NameWhite	, @IsPlayerHumanWhite,   @LevelWhite	, @RemainingTimeWhiteInSeconds	, NULL, 'TRUE', 'TRUE', 0, NULL)
           , ('TRUE'	, @NameBlack	, @IsPlayerHumanBlack,   @LevelBlack	, @RemainingTimeBlackInSeconds	, NULL, 'TRUE', 'TRUE', 0, NULL)

	-- first read the current board into a variable
	DECLARE @GameBoard	AS [dbo].[typStellung]
	INSERT INTO @GameBoard
		SELECT 
			  1								AS [VariantNo]
			, 1								AS [SearchDepth]
			, [GB].[Column]					AS [Column]
			, [GB].[Row]					AS [Row]
			, [GB].[Field]					AS [Field]
			, [GB].[IsPlayerWhite]			AS [IsPlayerWhite]
			, [GB].[FigureLetter]			AS [FigureLetter]
			, [GB].[FigureUTF8]				AS [FigureUTF8]
		FROM [Infrastructure].[GameBoard]	AS [GB]

	-- Identify possible actions
	EXECUTE [CurrentGame].[prcAktionenFuerAktuelleStellungWegschreiben] @IstSpielerWeiss = 'TRUE', @IstStellungZuBewerten = 'TRUE', @AktuelleStellung = @GameBoard

	-- Die Zughistorie loeschen
	TRUNCATE TABLE [CurrentGame].[Zugverfolgung]

	-- ------------------------------------------
	-- Stellung bewerten
	-- ------------------------------------------

	-- Die Statistiktabelle fuer die aktuelle Stellung aktualisieren
	EXECUTE [Statistik].[prcStellungBewerten] 'TRUE',	@GameBoard

	-- Das Spielbrett und die Statistiken anzeigen
	SELECT * FROM [Infrastruktur].[vSpielbrett]

END
GO



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '500 - Funktion [CurrentGame].[prcInitialisation] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO

/*
USE [arelium_TSQL_Schach_V012]
GO

DECLARE @RC int

-- TODO: Set parameter values here.

EXECUTE @RC = [CurrentGame].[prcInitialisation] 'Peter', 'Sandy', 1, 7, 800, 1200
GO

*/