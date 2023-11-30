-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### Function [CurrentGame].[fncIsFieldThreatened]                                       ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### If there is not only theoretically but also actually a move allowed in this         ###
-- ### position or a stroke that has the requested square as a target square, this         ###
-- ### function returns a 'TRUE' - otherwise a 'FALSE'.                                    ###
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
-- ###     15.00.0   2023-09-21 Torsten Ahlemeyer                                          ###
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
-- Construction work -----------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION [CurrentGame].[fncIsFieldThreatened] 
(
	  @IsPlayerWhite			AS BIT
	, @Gameboard				AS [dbo].[typePosition]		READONLY
	, @Field					AS TINYINT
)
RETURNS BIT
AS
BEGIN
	DECLARE @ReturnValue		AS BIT
	SET @ReturnValue			= 0

	IF EXISTS (	SELECT 
				* 
				FROM [CurrentGame].[fncPossibleActionsAllPieces] (@IsPlayerWhite, [Infrastructure].[fncPosition2EFN](@IsPlayerWhite, 'kKqQ', '', 3, 1, @Gameboard))
				WHERE 1 = 1
					AND [TargetField] = @Field
				)
	BEGIN
		SET @ReturnValue = 1
	END

	RETURN @ReturnValue
END
GO



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistics ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '085 - Function [CurrentGame].[fncIsFieldThreatened].sql'
PRINT ' '
PRINT 'Script     :   ' + @Script
PRINT 'End        :   ' + @End
PRINT 'Time       :   ' + @Time
SELECT @Script AS Skript, @End AS Ende, @Time AS Zeit
GO


/*
-- Test der Funktion [CurrentGame].[fncIsFieldThreatened]
	DECLARE @GameboardB				AS [dbo].[typePosition]

	INSERT INTO @GameboardB
	([Column], [Row], [Field], [IsPlayerWhite], [EFNPositionNr], [FigureLetter], [FigureUTF8])
	SELECT 
			[GB].[Column]					AS [Column]
		, [GB].[Row]					AS [Row]
		, [GB].[Field]					AS [Field]
		, [GB].[IsPlayerWhite]			AS [IsPlayerWhite]
		, [GB].[EFNPositionNr]			AS [EFNPositionNr]
		, [GB].[FigureLetter]			AS [FigureLetter]
		, [GB].[FigureUTF8]				AS [FigureUTF8]
	FROM [Infrastructure].[GameBoard]	AS [GB]

SELECT [CurrentGame].[fncIsFieldThreatened](
	0
	, @GameboardB
	, 33
)

	SELECT 
	* 
	FROM [CurrentGame].[fncPossibleActionsAllPieces] (0, 'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR b KkQq a3 3 1')
	WHERE 1 = 1
		AND [TargetField] = 33

		SELECt * FROM @GameboardB
SELECT [Infrastructure].[fncPosition2EFN](0, 'kKqQ', '', 3, 1, @GameboardB)
GO
*/
