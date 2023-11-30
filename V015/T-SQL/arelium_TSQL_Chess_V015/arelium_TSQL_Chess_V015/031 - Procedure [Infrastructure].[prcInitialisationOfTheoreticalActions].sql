-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### PROCEDURE [Infrastructure].[prcInitialisationOfTheoreticalActions]                  ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### All moves of all pieces that can theoretically occur within a chess game are        ###
-- ### written into the table. This includes not only all moves of rook, knight, knight,   ###
-- ### queen or king from any potential starting square to any target square which can be  ###
-- ### reached from this square in one move - but also the normal and special pawn moves   ###
-- ### (double step, en passant, pawn conversion) as well as all these moves also as       ###
-- ### capture moves, as far as they are identical with the move movements. In addition,   ###
-- ### there are the special pawn moves.  Furthermore, the list is supplemented by the     ###
-- ### two types of castling.                                                              ###
-- ###                                                                                     ###
-- ### Each of these entries exists once for white and once for black. The direction (e.g. ###
-- ### to the top right = RO) in which the move is executed is also recorded for each      ###
-- ### move. Pawns are not allowed to move in any direction.                               ###
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
-- ###     15.00.0   2023-07-12 Torsten Ahlemeyer                                          ###
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

CREATE OR ALTER PROCEDURE [Infrastructure].[prcInitialisationOfTheoreticalActions]
AS
BEGIN
	SET NOCOUNT ON;

	-- Instead of a simple TRUNCATE TABLE [Infrastructure].[TheoreticalAction], which would delete all the 
	-- data records in the table, here the figures are deleted in individual statements. 
	-- In this way, one can also address individual data sets specifically.
	DELETE FROM [Infrastructure].[TheoreticalAction]				-- Includes all moves and strokes of the rook
	WHERE [FigureLetter] = 'R'

	DELETE FROM [Infrastructure].[TheoreticalAction]				-- Includes all moves and strokes of the bishop
	WHERE [FigureLetter] = 'B'

	DELETE FROM [Infrastructure].[TheoreticalAction]				-- Includes all moves and strokes of the queen
	WHERE [FigureLetter] = 'Q'

	DELETE FROM [Infrastructure].[TheoreticalAction]				-- Includes all moves and strokes of the king
	WHERE [FigureLetter] = 'K'										-- includes the castles also

	DELETE FROM [Infrastructure].[TheoreticalAction]				-- Includes all moves and strokes of the knight
	WHERE [FigureLetter] = 'N'

	DELETE FROM [Infrastructure].[TheoreticalAction]				-- Includes all moves and strokes of the pawn
	WHERE [FigureLetter] = 'P'										-- includes double step, en passant, pawn conversion

	-- -----------------------------------------------------------------------------------------
	-- Possible rook moves, possible rook captures
	-- -----------------------------------------------------------------------------------------
	-- A rook moves only horizontally or vertically any distance within the board boundaries and also captures 
	-- in this way. The insert should apply to both players (CROSS JOIN "YesNoPlayers"). For a rook, the move 
	-- and the capture movements are identical (CROSS JOIN "YesNoMove"). Both horizontal 
	-- ([SB].[row] = [SJ].[row] AND [SB].[column] <> [SJ].[column]) and vertical 
	-- ([SB].[row] <> [SJ].[row] AND [SB].[column] = [SJ].[column]) moves are stored.

	INSERT INTO [Infrastructure].[TheoreticalAction] 
		(     [FigureLetter], [IsPlayerWhite], [StartColumn], [StartRow], [StartField]
			, [TargetColumn], [TargetRow], [TargetField], [Direction], [TransformationFigureLetter]
			, [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside]
			, [IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex])
	(
		SELECT DISTINCT
			  'R'																		AS [FigureLetter]
			, [CS].[YesNoPlayerWhite]													AS [IsPlayerWhite]
			, [SB].[Column]																AS [StartColumn] 
			, [SB].[Row]																AS [StartRow]
			, [SB].[Field]																AS [StartField]
			, [SJ].[Column]																AS [TargetColumn]
			, [SJ].[Row]																AS [TargetRow]
			, [SJ].[Field]																AS [TargetField]
			, CASE
					WHEN [SB].[Column]	< [SJ].[Column]		THEN		'RI'
					WHEN [SB].[Column]	> [SJ].[Column]		THEN		'LE'
					WHEN [SB].[Row]	< [SJ].[Row]			THEN		'UP'
					WHEN [SB].[Row]	> [SJ].[Row]			THEN		'DO'
				END																		AS [Direction]
			, NULL																		AS [TransformationFigureLetter]
			, [CZ].[YesNoCapture]														AS [IsActionCapture]
			, 'FALSE'																	AS [IsActionCastlingKingsside]
			, 'FALSE'																	AS [IsActionCastlingQueensside]
			, 'FALSE'																	AS [IsActionEnPassant]
			, 'R'	+ LOWER([SB].[Column]) + CONVERT(CHAR(1), [SB].[Row])
					+ CASE WHEN [CZ].[YesNoCapture] = 'TRUE' THEN 'x' ELSE '-' END
					+ LOWER([SJ].[Column]) + CONVERT(CHAR(1), [SJ].[Row])				AS [LongNotation]
			, 'R'	+ CASE WHEN [CZ].[YesNoCapture] = 'TRUE' THEN 'x' ELSE '' END
					+ LOWER([SJ].[Column]) + CONVERT(CHAR(1), [SJ].[Row])				AS [ShortNotationSimple]
			, 'R'	+ CASE WHEN [SB].[Column] = [SJ].[Column] 
							THEN CONVERT(CHAR(1), [SB].[Row]) 
							ELSE LOWER([SB].[Column]) END
					+ CASE WHEN [CZ].[YesNoCapture] = 'TRUE' THEN 'x' ELSE '' END
					+ LOWER([SJ].[Column]) + CONVERT(CHAR(1), [SJ].[Row])				AS [ShortNotationComplex]
		FROM [Infrastructure].[GameBoard]				AS [SB]
		LEFT JOIN [Infrastructure].[GameBoard]			AS [SJ]
			ON 1 = 1
				AND 
					(
						([SB].[Row] = [SJ].[Row] AND [SB].[Column] <> [SJ].[Column])
					OR
						([SB].[Row] <> [SJ].[Row] AND [SB].[Column] = [SJ].[Column])
					)
		CROSS JOIN (SELECT 'TRUE' AS [YesNoCapture] 
					UNION SELECT 'FALSE')				AS [CZ]
		CROSS JOIN (SELECT 'TRUE' AS [YesNoPlayerWhite] 
					UNION SELECT 'FALSE')				AS [CS]
	)



	-- -----------------------------------------------------------------------------------------
	-- Possible bishop moves, possible bishop captures
	-- -----------------------------------------------------------------------------------------
	-- A bishop moves only diagonally in any direction as far as desired within the board boundaries and 
	-- also captures in this way.
	-- The insert should apply to both players (CROSS JOIN "YesNoPlayers"). In the case of a runner, the 
	-- move and the stroke movements are identical (CROSS JOIN "YesNoMove"). All diagonal 
	-- (ABS(ASCII([SJ].[Column]) - ASCII([SB].[Column])) = ABS(CONVERT(INTEGER, [SJ].[Row]) - CONVERT(INTEGER, [SB].[Row]))) Movementsare stored. 

	INSERT INTO [Infrastructure].[TheoreticalAction] 
		(     [FigureLetter], [IsPlayerWhite], [StartColumn], [StartRow], [StartField]
			, [TargetColumn], [TargetRow], [TargetField], [Direction], [TransformationFigureLetter], [IsActionCapture]
			, [IsActionCastlingKingsside], [IsActionCastlingQueensside], [IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex])
	(
		SELECT DISTINCT
			  'B'										AS [FigureName]
			, [CF].[YesNoPlayerWhite]					AS [IsPlayerWhite]
			, [SB].[Column]								AS [StartColumn] 
			, [SB].[Row]								AS [StartRow]
			, [SB].[Field]								AS [StartField]
			, [SJ].[Column]								AS [TargetColumn]
			, [SJ].[Row]								AS [TargetRow]
			, [SJ].[Field]								AS [TargetField]
			, CASE
					WHEN [SB].[Column]	< [SJ].[Column]	AND [SB].[Row]	< [SJ].[Row]		THEN		'RU'
					WHEN [SB].[Column]	< [SJ].[Column]	AND [SB].[Row]	> [SJ].[Row]		THEN		'RD'
					WHEN [SB].[Column]	> [SJ].[Column]	AND [SB].[Row]	< [SJ].[Row]		THEN		'LU'
					WHEN [SB].[Column]	> [SJ].[Column]	AND [SB].[Row]	> [SJ].[Row]		THEN		'LD'
				END										AS [Direction]
			, NULL										AS [TransformationFigureLetter]
			, [CZ].[YesNoCapture]						AS [IsActionCapture]
			, 'FALSE'									AS [IsActionCastlingKingsside]
			, 'FALSE'									AS [IsActionCastlingQueensside]
			, 'FALSE'									AS [IsActionEnPassant]
			, 'B'	+ LOWER([SB].[Column]) + CONVERT(CHAR(1), [SB].[Row])
					+ CASE WHEN [CZ].[YesNoCapture] = 'TRUE' THEN 'x' ELSE '-' END
					+ LOWER([SJ].[Column]) + CONVERT(CHAR(1), [SJ].[Row])				AS [LongNotation]
			, 'B'	+ CASE WHEN [CZ].[YesNoCapture] = 'TRUE' THEN 'x' ELSE '' END
					+ LOWER([SJ].[Column]) + CONVERT(CHAR(1), [SJ].[Row])				AS [ShortNotationSimple]
			, 'B'	+ LOWER([SB].[Column])
					+ CASE WHEN [CZ].[YesNoCapture] = 'TRUE' THEN 'x' ELSE '' END
					+ LOWER([SJ].[Column]) + CONVERT(CHAR(1), [SJ].[Row])				AS [ShortNotationComplex]
		FROM [Infrastructure].[GameBoard]				AS [SB]
		LEFT JOIN [Infrastructure].[GameBoard]			AS [SJ]
			ON 1 = 1
				AND ABS(ASCII([SJ].[Column]) - ASCII([SB].[Column])) = ABS(CONVERT(INTEGER, [SJ].[Row]) - CONVERT(INTEGER, [SB].[Row]))
				AND [SJ].[Column]	<> [SB].[Column]
				AND [SJ].[Row]	<> [SB].[Row]
		CROSS JOIN (SELECT 'TRUE' AS [YesNoPlayerWhite] 
					UNION SELECT 'FALSE')				AS [CF]
		CROSS JOIN (SELECT 'TRUE' AS [YesNoCapture] 
					UNION SELECT 'FALSE')				AS [CZ]
	)



	-- -----------------------------------------------------------------------------------------
	-- Possible queen moves, possible queen captures
	-- -----------------------------------------------------------------------------------------
	-- In terms of moves, a queen is comparable to a combination of rook and bishop: it can 
	-- move and capture diagonally, horizontally or vertically as far as desired

		INSERT INTO [Infrastructure].[TheoreticalAction] ([FigureLetter], [IsPlayerWhite], [StartColumn], [StartRow], 
															[StartField], [TargetColumn], [TargetRow], [TargetField], [Direction], 
															[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], 
															[IsActionCastlingQueensside], [IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex])
		SELECT DISTINCT
			  'Q'
			, [IsPlayerWhite]
			, [StartColumn]
			, [StartRow]
			, [StartField]
			, [TargetColumn]
			, [TargetRow]
			, [TargetField]
			, [Direction]
			, NULL
			, [IsActionCapture]
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, 'Q' + RIGHT([LongNotation], LEN([LongNotation]) - 1) 
			, 'Q' + RIGHT([ShortNotationSimple], LEN([ShortNotationSimple]) - 1) 
			, 'Q' + RIGHT([ShortNotationComplex], LEN([ShortNotationComplex]) - 1)
		FROM  [Infrastructure].[TheoreticalAction]
		WHERE 1 = 1
			AND 
			(
				[FigureLetter]= 'B'
			OR
				[FigureLetter]= 'R'
			)

	-- -----------------------------------------------------------------------------------------
	-- Possible king moves, possible king captures
	-- -----------------------------------------------------------------------------------------
	-- In terms of movement, a king is comparable to a queen, but may only move 1 square at a time. 
	-- A king can move and capture diagonally, horizontally or vertically.

		INSERT INTO [Infrastructure].[TheoreticalAction] ([FigureLetter], [IsPlayerWhite], [StartColumn]
													, [StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField]
													, [Direction], [TransformationFigureLetter], [IsActionCapture]
													, [IsActionCastlingKingsside], [IsActionCastlingQueensside]
													, [IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex])
		SELECT DISTINCT
			  'K'
			, [IsPlayerWhite]
			, [StartColumn]
			, [StartRow]
			, [StartField]
			, [TargetColumn]
			, [TargetRow]
			, [TargetField]
			, [Direction]
			, NULL
			, [IsActionCapture]
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, 'K' + RIGHT([LongNotation], LEN([LongNotation]) - 1) 
			, 'K' + RIGHT([ShortNotationSimple], LEN([ShortNotationSimple]) - 1) 
			, 'K' + RIGHT([ShortNotationComplex], LEN([ShortNotationComplex]) - 1)
		FROM  [Infrastructure].[TheoreticalAction]
		WHERE 1 = 1
			AND [FigureLetter]= 'Q'
			AND ABS(ASCII([TargetColumn]) - ASCII([StartColumn]))						<= 1
			AND ABS(CONVERT(INTEGER, [TargetRow]) - CONVERT(INTEGER, [StartRow]))		<= 1

	-- -----------------------------------------------------------------------------------------
	-- Possible castling moves (there are no castling captures!)
	-- -----------------------------------------------------------------------------------------
	-- Castling is a combination of two moves - since two pieces are moved at the same time.
	-- However, castling, which exists in a short and a long variant, requires a number of criteria.
	-- 1) the king involved must not have moved yet
	-- 2) the rook involved must not have moved yet
	-- 3) there must be no piece between the rook and the king
	-- 4) the king must not be in check
	-- 5) the king's target square and all the squares over which it passes must not be attacked.
	-- The move is noted internally by writing down only the movement of the king! The 
	-- algorithm checks elsewhere that the preconditions (see above) are fulfilled and that
	-- the castling is correctly recorded according to long/short notation!

		INSERT INTO [Infrastructure].[TheoreticalAction] ([FigureLetter], [IsPlayerWhite], [StartColumn], [StartRow], [StartField]
															, [TargetColumn], [TargetRow], [TargetField], [Direction], [TransformationFigureLetter]
															, [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside], [IsActionEnPassant]
															, [LongNotation], [ShortNotationSimple], [ShortNotationComplex])
		-- kurze Rochade weiss
		VALUES	  ('K', 'TRUE',  'E', 1, 33, 'G', 1, 49, 'RI', NULL, 'FALSE', 'TRUE', 'FALSE', 'FALSE', 'o-o',		'o-o',		'o-o')
		-- lange Rochade weiss
				, ('K', 'TRUE',  'E', 1, 33, 'C', 1, 17, 'LE', NULL, 'FALSE', 'FALSE', 'TRUE', 'FALSE', 'o-o-o',	'o-o-o',	'o-o-o')
		-- kurze Rochade schwarz
				, ('K', 'FALSE', 'E', 8, 40, 'G', 8, 56, 'RI', NULL, 'FALSE', 'TRUE', 'FALSE', 'FALSE', 'o-o',		'o-o',		'o-o')
		-- lange Rochade schwarz
				, ('K', 'FALSE', 'E', 8, 40, 'C', 8, 24, 'LE', NULL, 'FALSE', 'FALSE', 'TRUE', 'FALSE', 'o-o-o',	'o-o-o',	'o-o-o')




	-- -----------------------------------------------------------------------------------------
	-- Possible knight moves, possible knight captures
	-- -----------------------------------------------------------------------------------------
	-- A knight moves two squares horizontally or vertically and then immediately in the same move 
	-- exactly one move at a 90° angle within the board boundaries. The stroke movement is identical.

	-- CTE as a short form to create and fill a table with the numbers from 1 to 64.
	;WITH CTE_GameBoard(XKoordinate, YKoordinate, Field)
		 AS (	SELECT 
					  CHAR(([number] / 8) +	65)		AS [XKoordinate]
					, ([number] % 8) + 1			AS [YKoordinate]
					, [number] + 1					AS [Field]
				FROM  master..spt_values
				WHERE 1 = 1
					AND [type] = 'P'
					AND [number] BETWEEN 0 AND 63
	)

	
	INSERT INTO [Infrastructure].[TheoreticalAction] 
													([FigureLetter], [IsPlayerWhite], [StartColumn]
													, [StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField]
													, [Direction], [TransformationFigureLetter], [IsActionCapture]
													, [IsActionCastlingKingsside], [IsActionCastlingQueensside]
													, [IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex])
	SELECT DISTINCT
		  'N'										AS [FigureLetter]
		, [CS].[YesNoPlayerWhite]					AS [IsPlayerWhite]
		, [S1].[XKoordinate]						AS [StartColumn]
		, [S1].[YKoordinate]						AS [StartRow]
		, [S1].[Field]								AS [StartField]
		, [S2].[XKoordinate]						AS [TargetColumn]
		, [S2].[YKoordinate]						AS [TargetRow]
		, [S2].[Field]								AS [TargetField]
		, CASE
				WHEN ASCII([S1].[XKoordinate]) - 2 = ASCII([S2].[XKoordinate]) 	
						AND [S1].[YKoordinate] - 1	= [S2].[YKoordinate]		THEN		'LD'
				WHEN ASCII([S1].[XKoordinate]) - 2 = ASCII([S2].[XKoordinate]) 	
						AND [S1].[YKoordinate] + 1	= [S2].[YKoordinate]		THEN		'LU'
				WHEN ASCII([S1].[XKoordinate]) + 2 = ASCII([S2].[XKoordinate]) 	
						AND [S1].[YKoordinate] - 1	= [S2].[YKoordinate]		THEN		'RD'
				WHEN ASCII([S1].[XKoordinate]) + 2 = ASCII([S2].[XKoordinate]) 	
						AND [S1].[YKoordinate] + 1	= [S2].[YKoordinate]		THEN		'RU'
				WHEN ASCII([S1].[XKoordinate]) - 1 = ASCII([S2].[XKoordinate]) 	
						AND [S1].[YKoordinate] - 2	= [S2].[YKoordinate]		THEN		'LD'
				WHEN ASCII([S1].[XKoordinate]) - 1 = ASCII([S2].[XKoordinate]) 	
						AND [S1].[YKoordinate] + 2	= [S2].[YKoordinate]		THEN		'LU'
				WHEN ASCII([S1].[XKoordinate]) + 1 = ASCII([S2].[XKoordinate]) 	
						AND [S1].[YKoordinate] - 2	= [S2].[YKoordinate]		THEN		'RD'
				WHEN ASCII([S1].[XKoordinate]) + 1 = ASCII([S2].[XKoordinate]) 	
						AND [S1].[YKoordinate] + 2	= [S2].[YKoordinate]		THEN		'RU'
			END										AS [Direction]
		, NULL										AS [TransformationFigureLetter]
		, [CZ].[YesNoCapture]						AS [IsActionCapture]
		, 'FALSE'									AS [IsActionCastlingKingsside]
		, 'FALSE'									AS [IsActionCastlingQueensside]
		, 'FALSE'									AS [IsActionEnPassant]
		, 'N'	+ LOWER([S1].[XKoordinate]) + CONVERT(CHAR(1), [S1].[YKoordinate])
				+ CASE WHEN [CZ].[YesNoCapture] = 'TRUE' THEN 'x' ELSE '-' END
				+ LOWER([S2].[XKoordinate]) + CONVERT(CHAR(1), [S2].[YKoordinate])				AS [LongNotation]
		, 'N'	+ CASE WHEN [CZ].[YesNoCapture] = 'TRUE' THEN 'x' ELSE '' END
				+ LOWER([S2].[XKoordinate]) + CONVERT(CHAR(1), [S2].[YKoordinate])				AS [ShortNotationSimple]
		, 'N'	+ LOWER([S1].[XKoordinate])
				+ CASE WHEN [CZ].[YesNoCapture] = 'TRUE' THEN 'x' ELSE '' END
				+ LOWER([S2].[XKoordinate]) + CONVERT(CHAR(1), [S2].[YKoordinate])				AS [ShortNotationComplex]
	FROM   CTE_GameBoard AS [S1]
		CROSS JOIN CTE_GameBoard AS [S2]
		CROSS JOIN (SELECT 'TRUE' AS [YesNoCapture] 
					UNION SELECT 'FALSE')			AS [CZ]
		CROSS JOIN (SELECT 'TRUE' AS [YesNoPlayerWhite] 
					UNION SELECT 'FALSE')			AS [CS]
	WHERE 1 = 1
		AND 
			(
				(
					(ABS(ASCII([S1].[XKoordinate]) - ASCII([S2].[XKoordinate])) = 1)
					AND
					(ABS([S1].[YKoordinate] - [S2].[YKoordinate]) = 2)
				)
			OR
				(
					(ABS(ASCII([S1].[XKoordinate]) - ASCII([S2].[XKoordinate])) = 2)
					AND
					(ABS([S1].[YKoordinate] - [S2].[YKoordinate]) = 1)
				)
			)



	-- -----------------------------------------------------------------------------------------
	-- Possible pawn moves
	-- -----------------------------------------------------------------------------------------
	-- Special rule for pawns: in the first move, two squares at once are also possible

	INSERT INTO [Infrastructure].[TheoreticalAction] 
		(     [FigureLetter], [IsPlayerWhite], [StartColumn], [StartRow], [StartField]
			, [TargetColumn], [TargetRow], [TargetField], [Direction], [TransformationFigureLetter], [IsActionCapture]
			, [IsActionCastlingKingsside], [IsActionCastlingQueensside], [IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex])
	(
		SELECT DISTINCT
			  'P'																AS [FigureLetter]
			, 'TRUE'															AS [IsPlayerWhite]
			, [Column]															AS [StartColumn] 
			, [Row]																AS [StartRow]
			, [Field]															AS [StartField]
			, [Column]															AS [TargetColumn]
			, [Row] + 2															AS [TargetRow]
			, [Field] + 2														AS [TargetField]
			, 'UP'																AS [Direction]
			, NULL																AS [TransformationFigureLetter]
			, 'FALSE'															AS [IsActionCapture]
			, 'FALSE'															AS [IsActionCastlingKingsside]
			, 'FALSE'															AS [IsActionCastlingQueensside]
			, 'FALSE'															AS [IsActionEnPassant]
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + '-'
				+ LOWER([Column]) + CONVERT(CHAR(1), [Row] + 2)				AS [LongNotation]
			, LOWER([Column]) + CONVERT(CHAR(1), [Row] + 2)					AS [ShortNotationSimple]
			, LOWER([Column]) + CONVERT(CHAR(1), [Row] + 2)					AS [ShortNotationComplex]
		FROM [Infrastructure].[GameBoard]
		WHERE 1 = 1
			AND [Row]		= 2

		UNION

		SELECT
			  'P'
			, 'FALSE'
			, [Column]
			, [Row]
			, [Field]
			, [Column]
			, [Row] - 2
			, [Field] - 2
			, 'DO'
			, NULL
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + '-'
				+ LOWER([Column]) + CONVERT(CHAR(1), [Row] - 2)
			, LOWER([Column]) + CONVERT(CHAR(1), [Row] - 2)
			, LOWER([Column]) + CONVERT(CHAR(1), [Row] - 2)
		FROM [Infrastructure].[GameBoard]
		WHERE 1 = 1
			AND [Row]		= 7

	)



	-- WHITE: Pawn in line 2 to 6 can move 1 square upwards.
	-- BLACK: Pawn in row 7 to 3 can move 1 space downwards
	INSERT INTO [Infrastructure].[TheoreticalAction] 
		(     [FigureLetter], [IsPlayerWhite], [StartColumn], [StartRow], [StartField]
			, [TargetColumn], [TargetRow], [TargetField], [Direction], [TransformationFigureLetter], [IsActionCapture]
			, [IsActionCastlingKingsside], [IsActionCastlingQueensside], [IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex])
	(
		SELECT DISTINCT
			  'P'										AS [FigureName]
			, 'TRUE'									AS [IsPlayerWhite]
			, [Column]									AS [StartColumn] 
			, [Row]										AS [StartRow]
			, [Field]									AS [StartField]
			, [Column]									AS [TargetColumn]
			, [Row] + 1									AS [TargetRow]
			, [Field] + 1								AS [StartField]
			, 'UP'										AS [Direction]
			, NULL										AS [TransformationFigureLetter]
			, 'FALSE'									AS [IsActionCapture]
			, 'FALSE'									AS [IsActionCastlingKingsside]
			, 'FALSE'									AS [IsActionCastlingQueensside]
			, 'FALSE'									AS [IsActionEnPassant]
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + '-'
				+ LOWER([Column]) + CONVERT(CHAR(1), [Row] + 1)				AS [LongNotation]
			, LOWER([Column]) + CONVERT(CHAR(1), [Row] + 1)					AS [ShortNotationSimple]
			, LOWER([Column]) + CONVERT(CHAR(1), [Row] + 1)					AS [ShortNotationComplex]
		FROM [Infrastructure].[GameBoard]
		WHERE 1 = 1
			AND [Row]		BETWEEN 2 AND 6

		UNION

		SELECT DISTINCT
			  'P'
			, 'FALSE'
			, [Column]
			, [Row]
			, [Field]
			, [Column]
			, [Row] - 1
			, [Field] - 1
			, 'DO'
			, NULL
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + '-'
				+ LOWER([Column]) + CONVERT(CHAR(1), [Row] - 1)				AS [LongNotation]
			, LOWER([Column]) + CONVERT(CHAR(1), [Row] - 1)					AS [ShortNotationSimple]
			, LOWER([Column]) + CONVERT(CHAR(1), [Row] - 1)					AS [ShortNotationComplex]
		FROM [Infrastructure].[GameBoard]
		WHERE 1 = 1
			AND [Row]		BETWEEN 3 AND 7
	)



	-- WHITE: Pawn in line 7 can move 1 square up and transforms into a new piece.
	-- BLACK: Pawn in row 2 can move 1 square down and changes into a new piece
	INSERT INTO [Infrastructure].[TheoreticalAction] 
		(     [FigureLetter], [IsPlayerWhite], [StartColumn], [StartRow], [StartField]
			, [TargetColumn], [TargetRow], [TargetField], [Direction], [TransformationFigureLetter], [IsActionCapture]
			, [IsActionCastlingKingsside], [IsActionCastlingQueensside], [IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex])
	(
		SELECT DISTINCT
			  'P'																AS [FigureName]
			, 'TRUE'															AS [IsPlayerWhite]
			, [SB].[Column]														AS [StartColumn] 
			, [SB].[Row]														AS [StartRow]
			, [SB].[Field]														AS [StartField]
			, [SB].[Column]														AS [TargetColumn]
			, [SB].[Row] + 1													AS [TargetRow]
			, [SB].[Field] + 1													AS [TargetField]
			, 'UP'																AS [Direction]
			, [CJ].[TransformationFigureLetter]									AS [TransformationFigureLetter]
			, 'FALSE'															AS [IsActionCapture]
			, 'FALSE'															AS [IsActionCastlingKingsside]
			, 'FALSE'															AS [IsActionCastlingQueensside]
			, 'FALSE'															AS [IsActionEnPassant]
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + '-'
				+ LOWER([Column]) + CONVERT(CHAR(1), [Row] + 1)
				+ UPPER([CJ].[TransformationFigureLetter])						AS [LongNotation]
			, LOWER([Column]) + CONVERT(CHAR(1), [Row] + 1)					
				+ UPPER([CJ].[TransformationFigureLetter])						AS [ShortNotationSimple]
			, LOWER([Column]) + CONVERT(CHAR(1), [Row] + 1)
				+ UPPER([CJ].[TransformationFigureLetter])						AS [ShortNotationComplex]
		FROM [Infrastructure].[GameBoard]				AS [SB]
		CROSS JOIN (SELECT 'N' AS [TransformationFigureLetter]
			UNION SELECT 'Q'	UNION SELECT 'B' UNION SELECT 'R')				AS [CJ]
		WHERE 1 = 1
			AND [SB].[Row]		= 7

		UNION

		SELECT DISTINCT
			  'P'
			, 'FALSE'
			, [SB].[Column]
			, [SB].[Row]
			, [SB].[Field]
			, [SB].[Column]
			, [SB].[Row] - 1
			, [SB].[Field] - 1
			, 'DO'
			, [CJ].[TransformationFigureLetter]
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + '-'
				+ LOWER([Column]) + CONVERT(CHAR(1), [Row] - 1)
				+ UPPER([CJ].[TransformationFigureLetter])
			, LOWER([Column]) + CONVERT(CHAR(1), [Row] - 1)					
				+ UPPER([CJ].[TransformationFigureLetter])
			, LOWER([Column]) + CONVERT(CHAR(1), [Row] - 1)
				+ UPPER([CJ].[TransformationFigureLetter])
		FROM [Infrastructure].[GameBoard]				AS [SB]
		CROSS JOIN (SELECT 'N'  AS [TransformationFigureLetter]
			UNION SELECT 'Q'	UNION SELECT 'B' UNION SELECT 'R')				AS [CJ]
		WHERE 1 = 1
			AND [SB].[Row]		= 2

	)


	-- -----------------------------------------------------------------------------------------
	-- Possible pawn captures
	-- -----------------------------------------------------------------------------------------
	-- The pawns are captured diagonally one square forward, i.e. in the direction of travel. 
	-- WHITE: Only pawns on rows 2-6 can capture. Pawn captures from row 7 
	-- are treated separately below, since they involve a piece conversion.
	-- BLACK: Only pawns on rows 7-3 can capture. Pawn captures from row 2 
	-- are treated separately below, since they involve piece conversion.

	INSERT INTO [Infrastructure].[TheoreticalAction] 
		(     [FigureLetter], [IsPlayerWhite], [StartColumn], [StartRow], [StartField]
			, [TargetColumn], [TargetRow], [TargetField], [Direction], [TransformationFigureLetter], [IsActionCapture]
			, [IsActionCastlingKingsside], [IsActionCastlingQueensside], [IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex])
	(
		-- WHITE: Strike to the right
		SELECT DISTINCT
			  'P'										AS [FigureName]
			, 'TRUE'									AS [IsPlayerWhite]
			, [Column]									AS [StartColumn] 
			, [Row]										AS [StartRow]
			, [Field]									AS [StartField]
			, CHAR(ASCII([Column]) + 1)					AS [TargetColumn]
			, [Row] + 1									AS [TargetRow]
			, [Field] + 9								AS [TargetField]
			, 'RU'										AS [Direction]
			, NULL										AS [TransformationFigureLetter]
			, 'TRUE'									AS [IsActionCapture]
			, 'FALSE'									AS [IsActionCastlingKingsside]
			, 'FALSE'									AS [IsActionCastlingQueensside]
			, 'FALSE'									AS [IsActionEnPassant]
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] + 1)	AS [LongNotation]
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] + 1)	AS [ShortNotationSimple]
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] + 1)	AS [ShortNotationComplex]
		FROM [Infrastructure].[GameBoard]
		WHERE 1 = 1
			AND [Column]	<= 'G'
			AND [Row]		BETWEEN 2 AND 6

		UNION

		-- WHITE: Strike to the left
		SELECT DISTINCT
			  'P'
			, 'TRUE'
			, [Column]
			, [Row]
			, [Field]
			, CHAR(ASCII([Column]) - 1)
			, [Row] + 1
			, [Field] - 7
			, 'LU'
			, NULL
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] + 1)
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] + 1)
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] + 1)
		FROM [Infrastructure].[GameBoard]
		WHERE 1 = 1
			AND [Column]	>= 'B'
			AND [Row]		BETWEEN 2 AND 6

		UNION

		-- BLACK: Strike to the right
		SELECT DISTINCT
			  'P'
			, 'FALSE'
			, [Column]
			, [Row]
			, [Field]		
			, CHAR(ASCII([Column]) + 1)
			, [Row] - 1
			, [Field] + 7
			, 'RD'
			, NULL
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] - 1)
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] - 1)
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] - 1)
		FROM [Infrastructure].[GameBoard]
		WHERE 1 = 1
			AND [Column]	<= 'G'
			AND [Row]		BETWEEN 3 AND 7

		UNION

		-- BLACK: Strike to the left
		SELECT DISTINCT
			  'P'
			, 'FALSE'
			, [Column]
			, [Row]
			, [Field]
			, CHAR(ASCII([Column]) - 1)
			, [Row] - 1
			, [Field] - 9
			, 'LD'
			, NULL
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] - 1)
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] - 1)
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] - 1)
		FROM [Infrastructure].[GameBoard]
		WHERE 1 = 1
			AND [Column]	>= 'B'
			AND [Row]		BETWEEN 3 AND 7
	)





	-- hit & convert: Capture is diagonally one square forward, i.e. in the direction of travel. 
	-- WHITE: Only pawns on row 7 can capture. Pawn captures from rows 2-6 
	-- are treated separately above, since they are not accompanied by a piece transformation.
	-- BLACK: Only pawns on row 2 can capture. Pawn captures from rows 7-3 
	-- are treated separately above, since they do not involve any piece conversion.
	INSERT INTO [Infrastructure].[TheoreticalAction] 
		(     [FigureLetter], [IsPlayerWhite], [StartColumn], [StartRow], [StartField]
			, [TargetColumn], [TargetRow], [TargetField], [Direction], [TransformationFigureLetter], [IsActionCapture]
			, [IsActionCastlingKingsside], [IsActionCastlingQueensside], [IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex])
	(
		SELECT DISTINCT
			  'P'																	AS [FigureName]
			, 'TRUE'																AS [IsPlayerWhite]
			, [SB].[Column]															AS [StartColumn] 
			, [SB].[Row]															AS [StartRow]
			, [SB].[Field]															AS [StartField]
			, CHAR(ASCII([Column]) + 1)												AS [TargetColumn]
			, [SB].[Row] + 1														AS [TargetRow]
			, [SB].[Field] + 9														AS [TargetField]
			, 'RU'																	AS [Direction]
			, [CJ].[TransformationFigureLetter]										AS [TransformationFigureLetter]
			, 'TRUE'																AS [IsActionCapture]
			, 'FALSE'																AS [IsActionCastlingKingsside]
			, 'FALSE'																AS [IsActionCastlingQueensside]
			, 'FALSE'																AS [IsActionEnPassant]
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] + 1)
				+ [CJ].[TransformationFigureLetter]									AS [LongNotation]
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] + 1)	
				+ [CJ].[TransformationFigureLetter]									AS [ShortNotationSimple]
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] + 1)	
				+ [CJ].[TransformationFigureLetter]									AS [ShortNotationComplex]
		FROM [Infrastructure].[GameBoard]				AS [SB]
		CROSS JOIN (SELECT 'N'  AS [TransformationFigureLetter]
			UNION SELECT 'Q'	UNION SELECT 'B' UNION SELECT 'R')				AS [CJ]
		WHERE 1 = 1
			AND [SB].[Row]		= 7
			AND [SB].[Column]		< 'H'

		UNION

		SELECT DISTINCT
			  'P'
			, 'TRUE'
			, [SB].[Column]
			, [SB].[Row]
			, [SB].[Field]
			, CHAR(ASCII([Column]) - 1)
			, [SB].[Row] + 1
			, [SB].[Field] - 7
			, 'LU'
			, [CJ].[TransformationFigureLetter]
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] + 1)
				+ [CJ].[TransformationFigureLetter]									AS [LongNotation]
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] + 1)
				+ [CJ].[TransformationFigureLetter]									AS [ShortNotationSimple]
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] + 1)	
				+ [CJ].[TransformationFigureLetter]									AS [ShortNotationComplex]
		FROM [Infrastructure].[GameBoard]				AS [SB]
		CROSS JOIN (SELECT 'N'  AS [TransformationFigureLetter]
			UNION SELECT 'Q'	UNION SELECT 'B' UNION SELECT 'R')				AS [CJ]
		WHERE 1 = 1
			AND [SB].[Row]		= 7
			AND [SB].[Column]		> 'A'
	
		UNION

		SELECT DISTINCT
			  'P'
			, 'FALSE'
			, [SB].[Column]
			, [SB].[Row]
			, [SB].[Field]
			, CHAR(ASCII([Column]) + 1)
			, [SB].[Row] - 1
			, [SB].[Field] + 7
			, 'RU'
			, [CJ].[TransformationFigureLetter]
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] - 1)
				+ [CJ].[TransformationFigureLetter]
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] - 1)	
				+ [CJ].[TransformationFigureLetter]
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] - 1)	
				+ [CJ].[TransformationFigureLetter]
		FROM [Infrastructure].[GameBoard]				AS [SB]
		CROSS JOIN (SELECT 'N'  AS [TransformationFigureLetter]
			UNION SELECT 'Q'	UNION SELECT 'B' UNION SELECT 'R')				AS [CJ]
		WHERE 1 = 1
			AND [SB].[Row]		= 2
			AND [SB].[Column]		< 'H'


		UNION

		SELECT DISTINCT
			  'P'
			, 'FALSE'
			, [SB].[Column]
			, [SB].[Row]
			, [SB].[Field]
			, CHAR(ASCII([Column]) - 1)
			, [SB].[Row] - 1
			, [SB].[Field] -9
			, 'LU'
			, [CJ].[TransformationFigureLetter]
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] - 1)
				+ [CJ].[TransformationFigureLetter]
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] - 1)
				+ [CJ].[TransformationFigureLetter]
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] - 1)
				+ [CJ].[TransformationFigureLetter]
		FROM [Infrastructure].[GameBoard]				AS [SB]
		CROSS JOIN (SELECT 'N'  AS [TransformationFigureLetter]
			UNION SELECT 'Q'	UNION SELECT 'B' UNION SELECT 'R')				AS [CJ]
		WHERE 1 = 1
			AND [SB].[Row]		= 2
			AND [SB].[Column]		> 'A'
	)




	-- Possible en passant captures:
	-- Only pawns can be captured directly after their double step. To do this 
	-- the capturing pawn must be on the 4th (BLACK captures WHITE) or on the 6th row (WHITE 
	-- captures BLACK).

	INSERT INTO [Infrastructure].[TheoreticalAction] 
		(     [FigureLetter], [IsPlayerWhite], [StartColumn], [StartRow], [StartField]
			, [TargetColumn], [TargetRow], [TargetField], [Direction], [TransformationFigureLetter], [IsActionCapture]
			, [IsActionCastlingKingsside], [IsActionCastlingQueensside], [IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex])
	(
		SELECT DISTINCT			
			  'P'																	AS [FigureName]
			, 'TRUE'																AS [IsPlayerWhite]
			, [Column]																AS [StartColumn] 
			, [Row]																	AS [StartRow]
			, [Field]																AS [StartField]
			, CHAR(ASCII([Column]) + 1)												AS [TargetColumn]
			, [Row] + 1																AS [TargetRow]
			, [Field] + 9															AS [TargetField]
			, 'RU'																	AS [Direction]
			, NULL																	AS [TransformationFigureLetter]
			, 'TRUE'																AS [IsActionCapture]
			, 'FALSE'																AS [IsActionCastlingKingsside]
			, 'FALSE'																AS [IsActionCastlingQueensside]
			, 'TRUE'																AS [IsActionEnPassant]
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] + 1)
				+ 'e.p.'															AS [LongNotation]
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] + 1)	
				+ 'e.p.'															AS [ShortNotationSimple]
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] + 1)	
				+ 'e.p.'															AS [ShortNotationComplex]
		FROM [Infrastructure].[GameBoard]
		WHERE 1 = 1
			AND [Column]	< 'H'
			AND [Row]		= 5

		UNION

		SELECT DISTINCT			
			  'P'
			, 'TRUE'
			, [Column]
			, [Row]
			, [Field]
			, CHAR(ASCII([Column]) - 1)
			, [Row] + 1
			, [Field] - 7
			, 'LU'
			, NULL
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'TRUE'
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] + 1)
				+ 'e.p.'
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] + 1)
				+ 'e.p.'
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] + 1)
				+ 'e.p.'
		FROM [Infrastructure].[GameBoard]
		WHERE 1 = 1
			AND [Column]	> 'A'
			AND [Row]		= 5

		UNION
	
		SELECT DISTINCT			
			  'P'
			, 'FALSE'
			, [Column]
			, [Row]
			, [Field]
			, CHAR(ASCII([Column]) + 1)
			, [Row] - 1
			, [Field] + 7
			, 'RD'
			, NULL
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'TRUE'
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] - 1)
				+ 'e.p.'
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] - 1)
				+ 'e.p.'
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) + 1)) + CONVERT(CHAR(1), [Row] - 1)
				+ 'e.p.'	FROM [Infrastructure].[GameBoard]
		WHERE 1 = 1
			AND [Column]	< 'H'
			AND [Row]		= 4

		UNION

		SELECT DISTINCT		
			  'P'
			, 'FALSE'
			, [Column]
			, [Row]
			, [Field]
			, CHAR(ASCII([Column]) - 1)
			, [Row] - 1
			, [Field] - 9
			, 'LD'
			, NULL
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'TRUE'
			, LOWER([Column]) + CONVERT(CHAR(1), [Row]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] - 1)
				+ 'e.p.'
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] - 1)
				+ 'e.p.'
			, LOWER([Column]) + 'x'
				+ LOWER(CHAR(ASCII([Column]) - 1)) + CONVERT(CHAR(1), [Row] - 1)
				+ 'e.p.'	
		FROM [Infrastructure].[GameBoard]
		WHERE 1 = 1
			AND [Column]	> 'A'
			AND [Row]		= 4
	)
END
GO







------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistics ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '031 - Procedur [Infrastructure].[prcInitialisationOfTheoreticalActions].sql'
PRINT ' '
PRINT 'Script     :   ' + @Script
PRINT 'End        :   ' + @End
PRINT 'Time       :   ' + @Time
SELECT @Script AS Skript, @End AS Ende, @Time AS Zeit
GO

/*
USE [arelium_TSQL_Chess_V015]
GO

EXECUTE [Infrastructure].[prcInitialisationOfTheoreticalActions]
GO
*/