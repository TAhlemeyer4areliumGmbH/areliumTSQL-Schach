-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### View [CurrentGame].[vDisplayNotation]                                               ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### This script creates or modifies a view that displays the last 9 moves of this game  ###
-- ### in long notation.                                                                   ###
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
CREATE OR ALTER VIEW [CurrentGame].[vDisplayNotation] 
AS
	-- In order to be able to ensure a sorted output in a view, "trickery" is used here. Actually 
	-- an ORDER BY in views is forbidden... but with a TOP 100 PERCENT you are allowed to use it...
	SELECT TOP 100 PERCENT  
		  ROW_NUMBER() OVER(ORDER BY [Inside].[MoveID] ASC)				AS [OrderID]
		, CASE WHEN [Inside].[MoveID] = ((SELECT MAX([MoveID]) FROM [CurrentGame].[Notation]) - 8)
			THEN '...'
			ELSE CONVERT(CHAR(3), FORMAT([Inside].[MoveID], '000'))
		  END															AS [MoveID]
		, CASE WHEN [Inside].[MoveID] = ((SELECT MAX([MoveID]) FROM [CurrentGame].[Notation]) - 8)
			THEN '...'
			ELSE [Inside].[White]
		END																AS [White]
		, CASE WHEN [Inside].[MoveID] = ((SELECT MAX([MoveID]) FROM [CurrentGame].[Notation]) - 8)
			THEN '...'
			ELSE [Inside].[Black]
		END																AS [Black]
	FROM
		(
			SELECT TOP 9
				  [White].[MoveID]										AS [MoveID] 
				, [White].[LongNotation]								AS [White]
				, ISNULL([Black].[LongNotation], '')					AS [Black]
			FROM [CurrentGame].[Notation] AS [White]
			LEFT JOIN (SELECT * FROM [CurrentGame].[Notation]) AS [Black]
				ON 1 = 1
					AND [White].[MoveID]				= [Black].[MoveID]
					AND [Black].[IsPlayerWhite]		= 'FALSE'

			WHERE 1 = 1
				AND [White].[IsPlayerWhite]	= 'TRUE'
			ORDER BY [White].[MoveID] DESC
		) AS [Inside]
	ORDER BY [MoveID] ASC

GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistics ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '112 - View [CurrentGame].[vDisplayNotation].sql'
PRINT ' '
PRINT 'Script     :   ' + @Script
PRINT 'End        :   ' + @End
PRINT 'Time       :   ' + @Time
SELECT @Script AS Skript, @End AS Ende, @Time AS Zeit
GO


/*
USE [arelium_TSQL_Chess_V015]
GO


SELECT * FROM [CurrentGame].[vDisplayNotation]
GO

*/