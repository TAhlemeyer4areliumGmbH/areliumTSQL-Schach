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
                    , (      36 6, 46 6, 46 4, 38 4, 38 0, 46 0, 46 -8, 36 -8, 36 -6, 44 -6, 44 -2, 36 -2, 36 6 ) 
                    , (      48 6, 58 6, 58 4, 50 4, 50 -6, 58 -6, 58 -8, 48 -8, 48 6 ) 
                    , (      60 6, 62 6, 62 0, 68 0, 68 6, 70 6, 70 -8, 68 -8, 68 -2, 62 -2, 62 -8, 60 -8, 60 6 ) 
                    , (      72 -8, 76 6, 78 6, 82 -8, 80 -8, 78 -3, 76 -3, 76 -2, 77.5 -2, 77 -1, 76 -1, 75 -3, 74 -8, 72 -8) 
                    , (      84 6, 94 6, 94 4, 86 4, 86 -6, 94 -6, 94 -8, 84 -8, 84 6 ) 
                    , (      96 6, 98 6, 98 0, 104 0, 104 6, 106 6, 106 -8, 104 -8, 104 -2, 98 -2, 98 -8, 96 -8, 96 6 ) 
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
	 ,		( 160, NULL,	'empty field',		CHAR(160),	NCHAR(160) ,  0)
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
             ( 1, ' 5 year old child, no help',											0, 0,  0,  0,  0,  0,  0, 0, 0)
           , ( 2, ' 5 year old child, preview enabled, help of grandmaster disabled',	1, 0,  0,  0,  0,  0,  0, 0, 0)
		   , ( 3, ' 5 year old child, preview enabled, help of grandmaster enabled',	1, 1,  0,  0,  0,  0,  0, 0, 0)

		   --  8yo child plays like 5oy child + calculate total figure value
           , (11, ' 8 year old child, no help',											0, 0,  1,  0,  0,  0,  0, 0, 0)
           , (12, ' 8 year old child, preview enabled, help of grandmaster disabled',	1, 0,  1,  0,  0,  0,  0, 0, 0)
		   , (13, ' 8 year old child, preview enabled, help of grandmaster enabled',	1, 1,  1,  0,  0,  0,  0, 0, 0)

		   -- 12yo child plays like 8oy child + calculate numer of actions
           , (21, '12 year old child, no help',											0, 0,  1,  1,  0,  0,  0, 0, 0)
           , (22, '12 year old child, preview enabled, help of grandmaster disabled',	1, 0,  1,  1,  0,  0,  0, 0, 0)
		   , (23, '12 year old child, preview enabled, help of grandmaster enabled',	1, 1,  1,  1,  0,  0,  0, 0, 0)

		   -- 14yo child plays like 12oy child + calculate numer of captures
           , (31, '14 year old child, no help',											0, 0,  1,  1,  0,  0,  0, 0, 0)
           , (32, '14 year old child, preview enabled, help of grandmaster disabled',	1, 0,  1,  1,  0,  0,  0, 0, 0)
		   , (33, '14 year old child, preview enabled, help of grandmaster enabled',	1, 1,  1,  1,  0,  0,  0, 0, 0)

		   -- 16yo child plays like 14oy child + calculate numer of castles
           , (41, '16 year old child, no help',											0, 0,  1,  1,  1,  0,  0, 0, 0)
           , (42, '16 year old child, preview enabled, help of grandmaster disabled',	1, 0,  1,  1,  1,  0,  0, 0, 0)
		   , (43, '16 year old child, preview enabled, help of grandmaster enabled',	1, 1,  1,  1,  1,  0,  0, 0, 0)

		   -- 18yo child plays like 16oy child + calculate status of pawn progress
           , (51, '18 year old adult, no help',											0, 0,  1,  1,  1,  1,  0, 0, 0)
           , (52, '18 year old adult, preview enabled, help of grandmaster disabled',	1, 0,  1,  1,  1,  1,  0, 0, 0)
		   , (53, '18 year old adult, preview enabled, help of grandmaster enabled',	1, 1,  1,  1,  1,  1,  0, 0, 0)

		   -- 25yo adult plays like 18oy adult + calculate number of yeomen
           , (61, '25 year old adult, no help',											0, 0,  1,  1,  1,  1,  1, 0, 0)
           , (62, '25 year old adult, preview enabled, help of grandmaster disabled',	1, 0,  1,  1,  1,  1,  1, 0, 0)
		   , (63, '25 year old adult, preview enabled, help of grandmaster enabled',	1, 1,  1,  1,  1,  1,  1, 0, 0)

		   -- 30yo adult plays like 25oy adult + calculate number of pawn chains
           , (71, '30 year old adult, no help',											0, 0,  1,  1,  1,  1,  1, 1, 1)
           , (72, '30 year old adult, preview enabled, help of grandmaster disabled',	1, 0,  1,  1,  1,  1,  1, 1, 1)
		   , (73, '30 year old adult, preview enabled, help of grandmaster enabled',	1, 1,  1,  1,  1,  1,  1, 1, 1)
GO








INSERT INTO [Statistic].[PositionEvaluation]
           ([PositionEvaluationID], [Label], [White], [Black], [Comment])
     VALUES
             (	1,	'figure value:'			,	40, 40, 'Sum of the values of still active pieces per colour')
           , (	2,	'#possible moves:'		,	20, 20, 'how many legal activitiescan each colour make in the next turn?')
           , (	3,	'#possible captures:'	,	16, 16, 'how many fields are currently threatened/protected?')
           , (	4,	'#possible castles:'	,	 2,  2, 'How many of the two theoretical castles are still available in principle (not only at present)?')
           , (	5,	'status pawn progress:'	,	 0,  0, 'How far ahead are your own pawns? The further, the more valuable...')
           , (	6,	'#yeomen:'				,	 0,  0, 'How many of your own pawns are yeoman pawns? The more the better?')
           , (	7,	'status of pawn chains:',	 8,  8, 'are pawns able to protect each other?')
		   , (  8,  'overall rating:'		, NULL,  0, 'positive values mean an advantage for white, negative for black')
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