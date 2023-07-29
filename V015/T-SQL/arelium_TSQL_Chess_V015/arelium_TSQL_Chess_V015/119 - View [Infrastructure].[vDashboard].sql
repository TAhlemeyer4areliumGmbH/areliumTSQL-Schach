-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### VIEW [CurrentGame].[vDashboard]                                                     ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### This script takes care of the graphical representation of all relevant game         ###
-- ### parameters. The board is visualised from both views, the notation of the game so    ###
-- ### far is published, the pieces captured so far are listed, the opening library is     ###
-- ### consulted and the scoring statistics are prepared.                                  ###
-- ###                                                                                     ###
-- ### The individual components that make up the dashboard are linked by JOIN via an      ###
-- ### invisible ID column (and can thus also be commented out individually if required).  ###
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

CREATE OR ALTER VIEW [Infrastructure].[vDashboard]
AS
SELECT 
	  CASE 
		WHEN (SELECT COUNT(*) FROM [CurrentGame].[Notation]) = 0 THEN '' 
		ELSE ISNULL([LN].[MoveID], '')
	  END 												AS [Move#]
	, ISNULL([LN].[MoveWhite], '')						AS [MoveWhite]
	, ISNULL([LN].[Moveblack], '')						AS [MoveBlack]
	, '|'												AS [?]
	, [POV_White].[.]									AS [,.]
	, [POV_White].[A]									AS [A.]
	, [POV_White].[B]									AS [B.]
	, [POV_White].[C]									AS [C.]
	, [POV_White].[D]									AS [D.]
	, [POV_White].[E]									AS [E.]
	, [POV_White].[F]									AS [F.]
	, [POV_White].[G]									AS [G.]
	, [POV_White].[H]									AS [H.]
	, [POV_White].[..]									AS [.]
	, '|'												AS [..]
	, CASE [POV_White].[OrderNr]
		WHEN 1 THEN N'White: ' 
			+ CASE (SELECT [LevelID] FROM [CurrentGame].[Configuration] WHERE [IsPlayerWhite] = 'TRUE') WHEN 1 THEN '' ELSE '(Comp)'
			+ ':'
			END
		WHEN 2 THEN N'Remaining time: '
		WHEN 3 THEN N'50-Moves-Rule: '
		WHEN 4 THEN N'Turn: '
		WHEN 5 THEN N'en-passant: '
		WHEN 6 THEN N'Evaluation: '
		WHEN 7 THEN N'50-Moves-Rule: '
		WHEN 8 THEN N'Black: '
			+ CASE (SELECT [LevelID] FROM [CurrentGame].[Configuration] WHERE [IsPlayerWhite] = 'FALSE') WHEN 1 THEN N'' ELSE '(Comp)'
			+ ':'
			END
		WHEN 9 THEN N'Remaining time: '
		ELSE ''
	END													AS [ ]
	, CASE [POV_White].[OrderNr]
		WHEN 1 THEN (SELECT [NameOfPlayer] FROM [CurrentGame].[Configuration] WHERE [IsPlayerWhite] = 'TRUE')
		WHEN 2 THEN [Infrastructure].[fncSecondsAsTimeFormatting]((SELECT [RemainingTimeInSeconds] FROM [CurrentGame].[Configuration] WHERE [IsPlayerWhite]= 'TRUE'))
		WHEN 3 THEN (SELECT CONVERT(CHAR(3), [Number50ActionsRule]) FROM [CurrentGame].[Configuration] WHERE [IsPlayerWhite] = 'TRUE')
		WHEN 4 THEN CASE [CurrentGame].[fncIsNextMoveWhite]() WHEN 'TRUE' THEN 'White' ELSE 'Black' END
		WHEN 5 THEN ISNULL((SELECT [IsEnPassantPossible] FROM [CurrentGame].[Configuration] WHERE [IsPlayerWhite]= (([CurrentGame].[fncIsNextMoveWhite]() + 1) % 2)), '')
		--WHEN 6 THEN CONVERT(VARCHAR(8), [Statistik].[fncAktuelleStellungBewerten]())
		WHEN 7 THEN (SELECT CONVERT(CHAR(3), [Number50ActionsRule]) FROM [CurrentGame].[Configuration] WHERE [IsPlayerWhite]= 'FALSE')
		WHEN 8 THEN (SELECT [NameOfPlayer] FROM [CurrentGame].[Configuration] WHERE [IsPlayerWhite]= 'FALSE')
		WHEN 9 THEN [Infrastructure].[fncSecondsAsTimeFormatting]((SELECT [RemainingTimeInSeconds] FROM [CurrentGame].[Configuration] WHERE [IsPlayerWhite]= 'FALSE'))
		ELSE ''
	END													AS [_]
	, '|'												AS [,,]
	, [POV_Black].[.]								AS [,]
	, [POV_Black].[H]								AS [H,]
	, [POV_Black].[G]								AS [G,]
	, [POV_Black].[F]								AS [F,]
	, [POV_Black].[E]								AS [E,]
	, [POV_Black].[D]								AS [D,]
	, [POV_Black].[C]								AS [C,]
	, [POV_Black].[B]								AS [B,]
	, [POV_Black].[A]								AS [A,]
	, [POV_Black].[..]								AS [.,]
	, ISNULL([GF].[captured piece(s)], '')			AS [captured piece(s)]
	, '|'												AS [;]
	--, CASE (SELECT [ComputerSchritteAnzeigen] FROM [CurrentGame].[Configuration] WHERE [IsPlayerWhite]= (([CurrentGame].[fncIsNextMoveWhite]() + 1) % 2)) 
	--		WHEN 'TRUE' THEN ISNULL([MA].[LongNotation], '')
	--		ELSE '---'									
	--	END												AS [Zugideen]
	, '|'												AS [:]
	, ISNULL([BE].[Label], '')							AS [Kriterium]
	, ISNULL([BE].[White], '')							AS [White]
	, CASE [BE].[Label] 
		WHEN 'overall rating:' THEN FORMAT(CONVERT(FLOAT, ISNULL([BE].[Black], '')), '0.0#')	
		ELSE ISNULL([BE].[Black], '')
	   END												AS [Black]
	, ISNULL([GMP].[Value], '')							AS [Library]
FROM
	(
		-- This is the board from the point of view of WHITE
		-- The PIVOT makes an 8x8 chessboard out of the long field list. Where the aggregation returns a 
		-- value <> 0, the appropriate figure is painted. All other fields are filled with blanks. The 
		-- board labels are generated depending on the player colour (WHITE = A-H and 8-1, BLACK = H-A 
		-- and 1-8). So that both boards (and later the rest of the "dashboard") can be properly joined, 
		-- the sub-queries each provide an [OrderNo], which is not displayed in the main query.
		SELECT
			  [ID]													AS [OrderNr]
			, CONVERT(CHAR(1), [Row])								AS [.]
			, CASE WHEN [A] = 0 THEN ' ' ELSE NCHAR([A]) END		AS [A]
			, CASE WHEN [B] = 0 THEN ' ' ELSE NCHAR([B]) END		AS [B]
			, CASE WHEN [C] = 0 THEN ' ' ELSE NCHAR([C]) END		AS [C]
			, CASE WHEN [D] = 0 THEN ' ' ELSE NCHAR([D]) END		AS [D]
			, CASE WHEN [E] = 0 THEN ' ' ELSE NCHAR([E]) END		AS [E]
			, CASE WHEN [F] = 0 THEN ' ' ELSE NCHAR([F]) END		AS [F]
			, CASE WHEN [G] = 0 THEN ' ' ELSE NCHAR([G]) END		AS [G]
			, CASE WHEN [H] = 0 THEN ' ' ELSE NCHAR([H]) END		AS [H]
			, CONVERT(CHAR(1), [Row])								AS [..]
		FROM
		(
			SELECT [Row], [A], [B], [C], [D], [E], [F], [G], [H]
			FROM  
			(SELECT [Column], [Row], [FigureUTF8]
				FROM [Infrastructure].[GameBoard]) AS SourceTable  
			PIVOT  
			(  
			MAX([FigureUTF8])  
			FOR [Column] IN ([A], [B], [C], [D], [E], [F], [G], [H])  
			) AS PivotTable  
		) AS aussen
		INNER JOIN (SELECT 8 AS [ID] UNION SELECT 7 UNION SELECT 6 UNION SELECT 5 UNION SELECT 4 UNION SELECT 3 UNION SELECT 2 UNION SELECT 1) AS [Umkehr]
			ON [Umkehr].[ID] = 9 - [Row]
		UNION
		SELECT 9, ' ', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', ' '
	) AS [POV_White]

	INNER JOIN 

	(
		-- This is the board as seen by BLACK
		SELECT 
			  [Row]												AS [OrderNr]
			, CONVERT(CHAR(1), [Row])								AS [.]
			, CASE WHEN [H] = 0 THEN ' ' ELSE NCHAR([H]) END		AS [H]
			, CASE WHEN [G] = 0 THEN ' ' ELSE NCHAR([G]) END		AS [G]
			, CASE WHEN [F] = 0 THEN ' ' ELSE NCHAR([F]) END		AS [F]
			, CASE WHEN [E] = 0 THEN ' ' ELSE NCHAR([E]) END		AS [E]
			, CASE WHEN [D] = 0 THEN ' ' ELSE NCHAR([D]) END		AS [D]
			, CASE WHEN [C] = 0 THEN ' ' ELSE NCHAR([C]) END		AS [C]
			, CASE WHEN [B] = 0 THEN ' ' ELSE NCHAR([B]) END		AS [B]
			, CASE WHEN [A] = 0 THEN ' ' ELSE NCHAR([A]) END		AS [A]
			, CONVERT(CHAR(1), [Row])								AS [..]
		FROM
		(
			SELECT [Row], [A], [B], [C], [D], [E], [F], [G], [H]
			FROM  
			(SELECT [Column], [Row], [FigureUTF8]
				FROM [Infrastructure].[GameBoard]) AS SourceTable  
			PIVOT  
			(  
			MAX([FigureUTF8])  
			FOR [Column] IN ([A], [B], [C], [D], [E], [F], [G], [H])  
			) AS PivotTable  
		) AS aussen
		UNION
		SELECT 9, ' ', 'H', 'G', 'F', 'E', 'D', 'C', 'B', 'A', ' '
	) AS [POV_Black]
		ON [POV_White].[OrderNr] = [POV_Black].[OrderNr]

	-- Here the overview of the captured pieces is added. The pawns and other pieces 
	-- are shown graphically per colour.
	LEFT JOIN [CurrentGame].[vCapturedFigures] AS [GF]
		ON [GF].[ID] = [POV_White].[OrderNr]
				
	-- here, the first 9 allowed moves from this position are randomly displayed for 
	-- the next active player (for this, the procedure [CurrentGame].[prcNoteActionsCurrentPosition]
	-- must have been called correctly BEFORE).
	LEFT JOIN 
		(
			SELECT TOP 9 
				  ROW_NUMBER() OVER(ORDER BY NEWID() ASC) AS [OrderNr]
				, *
			FROM [CurrentGame].[PossibleAction]
		) AS [MA]
	ON [MA].[OrderNr] = [POV_White].[OrderNr]

	-- The ratings are now displayed according to the configured criteria:
	LEFT JOIN 
		( 
			SELECT 
				  [PositionEvaluationID]													AS [PositionEvaluationID]
				, [Label]																	AS [Label]
				,	CASE [Label]	
						WHEN 'Result:' THEN ' '
						ELSE ISNULL(CONVERT(VARCHAR(10), [White]), N' ')
					END																		AS [White]
				, ISNULL(CONVERT(VARCHAR(10), [Black])	, N' ')								AS [Black]
			  FROM [Statistic].[PositionEvaluation]
		) AS [BE]
	ON [POV_White].[OrderNr] = [BE].[PositionEvaluationID]

	-- The course of the game so far is now shown in the long notation.
	LEFT JOIN 
		( 
			SELECT
				  [OrderID]				AS [OrderID]
				, [MoveID]				AS [MoveID] 
				, [White]				AS [MoveWhite]
				, [Black] 				AS [MoveBlack]
			FROM [CurrentGame].[vDisplayNotation]
		) AS [LN]
	ON [POV_White].[OrderNr] = [LN].[OrderID]

	-- We will now look up the grandmaster games to see if such a game has already been played.
	LEFT JOIN 
		( 
			SELECT
				  [Value]				AS [Value]
				  , [ID]				AS [ID]
			FROM [Library].[vPlayedBefore]
		) AS [GMP]
	ON [POV_White].[OrderNr] = [GMP].[ID]
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistics ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '119 - View [Infrastructure].[vDashboard].sql'
PRINT ' '
PRINT 'Script     :   ' + @Script
PRINT 'End        :   ' + @End
PRINT 'Time       :   ' + @Time
SELECT @Script AS Skript, @End AS Ende, @Time AS Zeit
GO


/*
USE [arelium_TSQL_Chess_V015]
GO

SELECT * FROM [Infrastructure].[vDashboard]
GO

*/