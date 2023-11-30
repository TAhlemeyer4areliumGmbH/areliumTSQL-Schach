-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### The foolish matt                                                                    ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### This example game shows the shortest possible game of chess. Here Black mates his   ###
-- ### opponent, who, however, has to help a lot. The move sequence is suitable for        ###
-- ### testing the moves, checking the calculation of the possible moves and testing the   ###
-- ### algorithm for chess and mate recognition.                                           ###
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



TRUNCATE TABLE [CurrentGame].[Configuration]
GO

INSERT INTO [CurrentGame].[Configuration]
	( [IsPlayerWhite]
	, [NameOfPlayer]
	, [IsPlayerHuman]
	, [LevelID]
	, [ShowOptions]
	)
VALUES
	  ('TRUE'	, 'Torsten',	'TRUE'	,255,	'TRUE')
	, ('FALSE'	, 'Julia',		'TRUE'	,255,	'TRUE')
GO




TRUNCATE TABLE [CurrentGame].[PossibleAction]
GO

TRUNCATE TABLE [CurrentGame].[Notation]
GO

EXECUTE [Infrastructure].[prcInitialisationOfTheoreticalActions]
GO

EXEC [Infrastructure].[prcSetUpBasicPosition]
GO


DECLARE @EFN varchar(255)
SET @EFN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'


INSERT INTO [CurrentGame].[PossibleAction]
	( [TheoreticalActionID], [HalfMoveNo], [FigureLetter], [IsPlayerWhite], [StartColumn], [StartRow], [StartField]
	, [TargetColumn], [TargetRow], [TargetField], [Direction], [TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside]
	, [IsActionCastlingQueensside], [IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex], [Rating])
EXEC [CurrentGame].[prcPossibleActionsAllPieces] 
	   'TRUE'		-- @IsPlayerWhite		AS BIT
	 , @EFN			--						AS VARCHAR(255)
GO



SELECT * FROM [Infrastructure].[vDashboard]
GO

EXECUTE [CurrentGame].[prcPerformAnAction] 
   'f2'			-- @StartSquare
  ,'f3'			-- @TargetSquare
  , NULL		-- @TransformationFigure
  , 'FALSE'		-- @IsEnPassant
  , 'TRUE'		-- @IsPlayerWhite
GO


EXECUTE [CurrentGame].[prcPerformAnAction] 
   'e7'			-- @StartSquare
  ,'e5'			-- @TargetSquare
  , NULL		-- @TransformationFigure
  , 'FALSE'		-- @IsEnPassant
  , 'FALSE'		-- @IsPlayerWhite
GO


EXECUTE [CurrentGame].[prcPerformAnAction] 
   'g2'			-- @StartSquare
  ,'g4'			-- @TargetSquare
  , NULL		-- @TransformationFigure
  , 'FALSE'		-- @IsEnPassant
  , 'TRUE'		-- @IsPlayerWhite
GO


EXECUTE [CurrentGame].[prcPerformAnAction] 
   'd8'			-- @StartSquare
  ,'h4'			-- @TargetSquare
  , NULL		-- @TransformationFigure
  , 'FALSE'		-- @IsEnPassant
  , 'FALSE'		-- @IsPlayerWhite
GO
