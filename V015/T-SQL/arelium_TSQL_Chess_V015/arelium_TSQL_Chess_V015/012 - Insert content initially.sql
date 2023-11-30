-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### Insert content initially                                                            ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### This script fills the tables with initial values. These are mainly lookup values    ###
-- ### that are identical for each batch.                                                  ###
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

TRUNCATE TABLE [Infrastructure].[Logo] 
DELETE FROM [Infrastructure].[Figure] 
DELETE FROM [Infrastructure].[Level]
DELETE FROM [Statistic].[PositionEvaluation]
DELETE FROM [Infrastructure].[GameBoard]
DELETE FROM [Infrastructure].[DiagonalAllocation]
GO


--------------------------------------------------------------------------------------------------
-- Construction work -----------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

-- First the logo table is filled. You can look at the logo later with a 
-- SELECT * FROM [Infrastructure].[Logo]. Just click on the additional 
-- tab "spatial results" in the results area.
-- The figures will be drawn by specifying the coordinates, which will be 
-- connected directly. It must be a closed area!


INSERT INTO [Infrastructure].[Logo] 
VALUES (N'Rook', geography::STGeomFromText( 
            'POLYGON((0 0, 0 2, 2 2, 2 4, 6 10, 6 20, 1 26, 1 32, 7 32, 7 28, 10 28, 10 32, 16 32
                                , 16 28, 19 28, 19 32, 25 32, 25 26, 20 20, 20 10, 24 4, 24 2, 26 2, 26 0, 0 0 
                        )'  
             -- visualize "T-SQL", one letter per row
             + '    , (      28 18, 34 18, 34 17, 32 17, 32  9, 30  9, 30 17, 28 17, 28 18 ) 
                    , (      34 14, 38 14, 38 13, 34 13, 34 14 ) 
                    , (      40 18, 46 18, 46 17, 42 17, 42 14, 46 14, 46 9, 40 9, 40 10, 44 10, 44 13, 40 13, 40 18 ) 
                    , (      50 18, 56 18, 56 12, 54 12, 54 17, 52 17, 52 10, 54 10, 53 11, 54 12, 57 9, 56 8, 55 9, 54 9, 50  9, 50 18 ) 
                    , (      60 18, 62 18, 62 10, 66 10, 66 9, 60 9, 60 18 )'

			-- visualize "Chess" (Schach), one letter per row
			 + '
                    , (      48 6, 58 6, 58 4, 50 4, 50 -6, 58 -6, 58 -8, 48 -8, 48 6 ) 
                    , (      60 6, 62 6, 62 0, 68 0, 68 6, 70 6, 70 -8, 68 -8, 68 -2, 62 -2, 62 -8, 60 -8, 60 6 ) 
                    , (      72 6, 82 6, 82 4, 74 4, 74 0, 82 0, 82 -2, 74 -2,   74 -6, 82 -6, 82 -8, 72 -8, 72 6 ) 
                    , (      84 6, 94 6, 94 4, 86 4, 86 0, 94 0, 94 -8, 84 -8, 84 -6, 92 -6, 92 -2, 84 -2, 84 6 ) 
                    , (      96 6,106 6,106 4, 98 4, 98 0,106 0,106 -8, 96 -8, 96 -6,104 -6,104 -2, 96 -2, 96 6 ) 
             )' 
  ,4326) 
  );





-- Initial filling of the table [Infrastructure].[Figure]:
-- Each figure and the empty field are filled with their UTF-8 ID, a plaintext, 
-- an abbreviation, a graphical symbol and a value for WHITE and BLACK
-- --------------------------------------------
-- Note: The ASCII value 160 corresponds to a protected space. Since the pawn in the 
-- short notation does not use an letter, the normal space (32) is used here. 
-- Consequently, a different character must be used for the unoccupied field.
INSERT INTO [Infrastructure].[Figure] ([FigureUTF8], [IsPlayerWhite], [FigureName], [FigureLetter], [FigureIcon], [FigureValue])
     VALUES (9812, 'TRUE',  'King',				'K',		NCHAR(9812),  0)
	 ,		(9813, 'TRUE',  'Queen',			'Q',		NCHAR(9813), 10)
	 ,		(9815, 'TRUE',  'Bishop',			'B',		NCHAR(9815),  3)
	 ,		(9816, 'TRUE',  'Knight',			'N',		NCHAR(9816),  3)
	 ,		(9814, 'TRUE',  'Rook',				'R',		NCHAR(9814),  5)
	 ,		(9817, 'TRUE',  'Pawn',				'P',		NCHAR(9817),  1)
	 ,		( 160,   NULL,	'empty field',		' ',		' ',  0)
     ,		(9818, 'FALSE', 'King',				'K',		NCHAR(9818),  0)
	 ,		(9819, 'FALSE', 'Queen',			'Q',		NCHAR(9819), 10)
	 ,		(9821, 'FALSE', 'Bishop',			'B',		NCHAR(9821),  3)
	 ,		(9822, 'FALSE', 'Knight',			'N',		NCHAR(9822),  3)
	 ,		(9820, 'FALSE', 'Rook',				'R',		NCHAR(9820),  5)
	 ,		(9823, 'FALSE', 'Pawn',				'P',		NCHAR(9823),  1)
GO


-- Initial filling of the table [Infrastructure].[Levels]:
-- The individual levels are defined by the question of which criteria are to be used for the 
-- position evaluation. Additions can be made here at any time in the form of new columns 
-- (additional criteria, then please adapt the corresponding function
-- [CurrentGame].[fncStatisticEvaluations]) or lines (new levels).
INSERT INTO [Infrastructure].[Level]
           ( 	  [LevelID]
				, [PlainText]
				, [IsActionPreviewVisible]
				, [IsGrandmasterSupportVisible]
				, [CalculateTotalFigureValue]
				, [CalculateNumberOfActions]
				, [CalculateNumberOfCaptures]
				, [CalculateNumberOfCastles]
				, [CalculateStatusPawnProgress]
				, [CalculateNumberOfYeomen]
				, [CalculateStatusOfPawnChains]
			)
     VALUES
			-- random but rule-abiding action by the player (like a toddler)
             ( 1, ' 5 yo, no help',							0, 0, 0, 0, 0, 0, 0, 0, 0)
           , ( 2, ' 5 yo, preview only',					1, 0, 0, 0, 0, 0, 0, 0, 0)
		   , ( 3, ' 5 yo, preview + grandmaster',			1, 1, 0, 0, 0, 0, 0, 0, 0)

		   --  8yo child plays like 5oy child + calculate total figure value
           , (11, ' 8 yo, no help',							0, 0, 1, 0, 0, 0, 0, 0, 0)
           , (12, ' 8 yo, preview only',					1, 0, 1, 0, 0, 0, 0, 0, 0)
		   , (13, ' 8 yo, preview + grandmaster',			1, 1, 1, 0, 0, 0, 0, 0, 0)

		   -- 12yo child plays like 8oy child + calculate numer of actions
           , (21, '12 yo, no help',							0, 0, 1, 1, 0, 0, 0, 0, 0)
           , (22, '12 yo, preview only',					1, 0, 1, 1, 0, 0, 0, 0, 0)
		   , (23, '12 yo, preview + grandmaster',			1, 1, 1, 1, 0, 0, 0, 0, 0)

		   -- 14yo child plays like 12oy child + calculate numer of captures
           , (31, '14 yo, no help',							0, 0, 1, 1, 0, 0, 0, 0, 0)
           , (32, '14 yo, preview only',					1, 0, 1, 1, 0, 0, 0, 0, 0)
		   , (33, '14 yo, preview + grandmaster',			1, 1, 1, 1, 0, 0, 0, 0, 0)

		   -- 16yo child plays like 14oy child + calculate numer of castles
           , (41, '16 yo, no help',							0, 0, 1, 1, 1, 0, 0, 0, 0)
           , (42, '16 yo, preview only',					1, 0, 1, 1, 1, 0, 0, 0, 0)
		   , (43, '16 yo, preview + grandmaster',			1, 1, 1, 1, 1, 0, 0, 0, 0)

		   -- 18yo child plays like 16oy child + calculate status of pawn progress
           , (51, '18 yo, no help',							0, 0, 1, 1, 1, 1, 0, 0, 0)
           , (52, '18 yo, preview only',					1, 0, 1, 1, 1, 1, 0, 0, 0)
           , (53, '18 yo, grandmaster only',				0, 1, 1, 1, 1, 1, 0, 0, 0)
		   , (54, '18 yo, preview + grandmaster',			1, 1, 1, 1, 1, 1, 0, 0, 0)

		   -- 25yo adult plays like 18oy adult + calculate number of yeomen
           , (61, '25 yo, no help',							0, 0, 1, 1, 1, 1, 1, 0, 0)
           , (62, '25 yo, preview only',					1, 0, 1, 1, 1, 1, 1, 0, 0)
           , (63, '25 yo, grandmaster only',				0, 1, 1, 1, 1, 1, 1, 0, 0)
		   , (64, '25 yo, preview + grandmaster',			1, 1, 1, 1, 1, 1, 1, 0, 0)

		   -- 30yo adult plays like 25oy adult + calculate number of pawn chains
           , (71, '30 yo, no help',							0, 0, 1, 1, 1, 1, 1, 1, 1)
           , (72, '30 yo, preview only',					1, 0, 1, 1, 1, 1, 1, 1, 1)
           , (73, '30 yo, grandmaster only',				0, 1, 1, 1, 1, 1, 1, 1, 1)
		   , (74, '30 yo, preview + grandmaster',			1, 1, 1, 1, 1, 1, 1, 1, 1)

		   -- Human player without any statistics
           , (242, 'human',							0, 0, 0, 0, 0, 0, 0, 0, 0)
           , (243, 'human, preview only',			1, 0, 0, 0, 0, 0, 0, 0, 0)
           , (244, 'human, grandmaster only',		0, 1, 0, 0, 0, 0, 0, 0, 0)
           , (245, 'human, preview + grandmaster',	1, 1, 0, 0, 0, 0, 0, 0, 0)

		   -- Human player with statistics
           , (252, 'human',							0, 0, 1, 1, 1, 1, 1, 1, 1)
           , (253, 'human, preview only',			1, 0, 1, 1, 1, 1, 1, 1, 1)
           , (254, 'human, grandmaster only',		0, 1, 1, 1, 1, 1, 1, 1, 1)
           , (255, 'human, preview + grandmaster',	1, 1, 1, 1, 1, 1, 1, 1, 1)
GO








INSERT INTO [Statistic].[PositionEvaluation]
           ([PositionEvaluationID], [Label], [White], [Black], [Comment])
     VALUES
             (	1,	'figure value:'			,	40, 40, 'Sum of the values of still active pieces per colour')
           , (	2,	'figure value:'			,	40, 40, 'Sum of the values of still active pieces per colour')
           , (	3,	'possible moves:'		,	20, 20, 'how many legal activitiescan each colour make in the next turn?')
           , (	4,	'dominated fields:'		,	 8,  8, 'how many fields are currently threatened/protected (for multiple times)?')
           , (	5,	'possible captures:'	,	 0,  0, 'how many fields are currently threatened and occupied by foreign stones?')
           , (	6,	'possible castles:'		,	 2,  2, 'How many of the two theoretical castles are still available in principle (not only at present)?')
           , (	7,	'status pawn progress:'	,	 0,  0, 'How far ahead are your own pawns? The further, the more valuable...')
           , (	8,	'yeomen:'				,	 0,  0, 'How many of your own pawns are yeoman pawns? The more the better?')
           , (	9,	'status of pawn chains:',	14, 14, 'are pawns able to protect each other?')
GO



INSERT INTO [Infrastructure].[GameBoard]
           ([Column], [Row], [Field], [EFNPositionNr], [IsPlayerWhite], [FigureLetter], [FigureUTF8])
	SELECT 
		  CHAR(([number] / 8) +	65)								AS [Column]
		, ([number] % 8) + 1									AS [Row]
		, [number] + 1											AS [Field]
		, 56 - (([number] % 8) * 8) + ([number] / 8) + 1		AS [EFNPositionNr]
		, NULL													AS [IsPlayerWhite]
		, NULL													AS [FigureLetter]
		, NULL													AS [FigureUTF8]
	FROM  master..spt_values
	WHERE 1 = 1
		AND [type] = 'P'
		AND [number] BETWEEN 0 AND 63
GO



INSERT INTO [CurrentGame].[GameStatus]
	( [IsPlayerWhite], [RemainingTimeInSeconds], [TimestampLastOpponentMove], [IsShortCastlingStillAllowed]
	 ,[IsLongCastlingStillAllowed], [Number50ActionsRule], [IsEnPassantPossible], [IsCheck], [IsMate])
VALUES
	  ( 'TRUE',		3*60*60, GETDATE(), 'TRUE', 'TRUE', 0, NULL, 'FALSE', 'FALSE')
	, ( 'FALSE',	3*60*60, GETDATE(), 'TRUE', 'TRUE', 0, NULL, 'FALSE', 'FALSE')
GO



DECLARE @DiagColumn			AS CHAR(1)
DECLARE @DiagRow			AS TINYINT
DECLARE @DiagCounter		AS TINYINT

SET @DiagCounter = 1

WHILE @DiagCounter <= 64
BEGIN

	-- Diagonal Up-Right
	SET @DiagColumn	= (SELECT CHAR(ASCII([Column]) + 1)	FROM [Infrastructure].[GameBoard] WHERE [Field] = @DiagCounter)
	SET @DiagRow	= (SELECT [Row] + 1					FROM [Infrastructure].[GameBoard] WHERE [Field] = @DiagCounter)
	WHILE @DiagColumn <= 'H' AND @DiagRow <= 8
	BEGIN
		INSERT INTO [Infrastructure].[DiagonalAllocation] ([Field], [DiagonalType], [TargetField])
			VALUES (@DiagCounter, 'UR', (SELECT [Field] FROM [Infrastructure].[GameBoard] WHERE [Column] = @DiagColumn AND [Row] = @DiagRow))
		SET @DiagColumn		= CHAR(ASCII(@DiagColumn) + 1)
		SET @DiagRow		= @DiagRow + 1
	END

	-- Diagonal Up-Left
	SET @DiagColumn	= (SELECT CHAR(ASCII([Column]) - 1)	FROM [Infrastructure].[GameBoard] WHERE [Field] = @DiagCounter)
	SET @DiagRow	= (SELECT [Row] + 1					FROM [Infrastructure].[GameBoard] WHERE [Field] = @DiagCounter)
	WHILE @DiagColumn >= 'A' AND @DiagRow <= 8
	BEGIN
		INSERT INTO [Infrastructure].[DiagonalAllocation] ([Field], [DiagonalType], [TargetField])
			VALUES (@DiagCounter, 'UL', (SELECT [Field] FROM [Infrastructure].[GameBoard] WHERE [Column] = @DiagColumn AND [Row] = @DiagRow))
		SET @DiagColumn		= CHAR(ASCII(@DiagColumn) - 1)
		SET @DiagRow		= @DiagRow + 1
	END

	-- Diagonal Down-Left
	SET @DiagColumn	= (SELECT CHAR(ASCII([Column]) - 1)	FROM [Infrastructure].[GameBoard] WHERE [Field] = @DiagCounter)
	SET @DiagRow	= (SELECT [Row] - 1					FROM [Infrastructure].[GameBoard] WHERE [Field] = @DiagCounter)
	WHILE @DiagColumn >= 'A' AND @DiagRow >= 1
	BEGIN
		INSERT INTO [Infrastructure].[DiagonalAllocation] ([Field], [DiagonalType], [TargetField])
			VALUES (@DiagCounter, 'DL', (SELECT [Field] FROM [Infrastructure].[GameBoard] WHERE [Column] = @DiagColumn AND [Row] = @DiagRow))
		SET @DiagColumn		= CHAR(ASCII(@DiagColumn) - 1)
		SET @DiagRow		= @DiagRow - 1
	END

	-- Diagonal Down-Right
	SET @DiagColumn	= (SELECT CHAR(ASCII([Column]) + 1)	FROM [Infrastructure].[GameBoard] WHERE [Field] = @DiagCounter)
	SET @DiagRow	= (SELECT [Row] - 1					FROM [Infrastructure].[GameBoard] WHERE [Field] = @DiagCounter)
	WHILE @DiagColumn <= 'H' AND @DiagRow >= 1
	BEGIN
		INSERT INTO [Infrastructure].[DiagonalAllocation] ([Field], [DiagonalType], [TargetField])
			VALUES (@DiagCounter, 'DR', (SELECT [Field] FROM [Infrastructure].[GameBoard] WHERE [Column] = @DiagColumn AND [Row] = @DiagRow))
		SET @DiagColumn		= CHAR(ASCII(@DiagColumn) + 1)
		SET @DiagRow		= @DiagRow - 1
	END

	SET @DiagCounter  = @DiagCounter  + 1
END
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistics ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '012 - Insert content initially.sql'
PRINT ' '
PRINT 'Script     :   ' + @Script
PRINT 'End        :   ' + @End
PRINT 'Time       :   ' + @Time
SELECT @Script AS Skript, @End AS Ende, @Time AS Zeit
GO