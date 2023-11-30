-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### Functions [CurrentGame].[fncPossibleActions_xxx]                                    ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### If you want to find out which possibilities you have to move the special piece in a ###
-- ### certain position, you use this function. It expects the specification of a position ###
-- ### (this does not necessarily have to be [Infrastructure].[GameBoard]!) and the square ###
-- ### for which the movement and capture possibilities are to be queried. In this way,    ###
-- ### statements about any positions are conceivable.                                     ###
-- ###                                                                                     ###
-- ### The function exists in a similar way for all figures:                               ###
-- ###    * [CurrentGame].[fncPossibleActionsRook]                                         ###
-- ###    * [CurrentGame].[fncPossibleActionsKnight]                                       ###
-- ###    * [CurrentGame].[fncPossibleActionsBishop]                                       ###
-- ###    * [CurrentGame].[fncPossibleActionsQueen]                                        ###
-- ###    * [CurrentGame].[fncPossibleActionsKing]                                         ###
-- ###    * [CurrentGame].[fncPossibleActionsPawn]                                         ###
-- ###                                                                                     ###
-- ### If you combine the returns for the individual calls for all instances of each       ###
-- ### figure, you get a complete overview of all possible continuations:                  ###
-- ###    * [CurrentGame].[fncPossibleActionsAllPieces]                                    ###
-- ###                                                                                     ###
-- ### At the end of this block there is a (commented out) test routine, with which one    ###
-- ### can test for a given position and single or all pieces, which valid moves come back ###
-- ### for the mentioned piece(s).                                                         ###
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




-- ###############################################################################################
-- ### Construction work #########################################################################
-- ###############################################################################################



-- #################################################################################################################

-- -----------------------------------------------------------------------------------------------------------------
-- Above there is a separate procedure for each type of figure. Here they are now addressed for a complete position 
-- according to the pieces still on the board. Not only the position is transferred alone, as important information, 
-- such as the question about the still permissible castles, would be lost. Instead, the EFN string of the position 
-- is transferred, where such information is additionally coded.
-- -----------------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE [CurrentGame].[prcPossibleActionsAllPieces] 

	   @IsPlayerWhite		AS BIT
	 , @EFN					AS VARCHAR(255)
AS
	BEGIN

		DECLARE @FieldQueen						AS TINYINT
		DECLARE @FieldRook						AS TINYINT
		DECLARE @FieldKnight					AS TINYINT
		DECLARE @FieldBishop					AS TINYINT
		DECLARE @FieldKing						AS TINYINT
		DECLARE @FieldPawn						AS TINYINT
		DECLARE @IsActionChessBid				AS BIT
		DECLARE @TransformationFigureLetter		AS CHAR(1)
		DECLARE @PossibleActions				AS [dbo].[typePossibleAction]

		-- --------------------------------------------------------------------------
		-- Extract the position from the EFN string and assign it to a variable
		-- --------------------------------------------------------------------------

		DECLARE @AssessmentPosition				AS [dbo].[typePosition]	
		
		INSERT INTO @AssessmentPosition
			SELECT * FROM [Infrastructure].[fncEFN2Position](@EFN)
			
		-- --------------------------------------------------------------------------
		-- queen(s)
		-- --------------------------------------------------------------------------

		-- All queens on the board are determined. For each queen found in this way, all conceivable and 
		-- rule-compliant actions are noted. Thus, even after multiple pawn conversions, every queen 
		-- is taken into account
		INSERT INTO @PossibleActions
		(
			[TheoreticalActionID], [HalfMoveNo], [FigureLetter], [IsPlayerWhite], [StartColumn],
			[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
			[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
			[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex], [Rating]
		)
		SELECT [TheoreticalActionID], 1, [FigureLetter], [IsPlayerWhite], [StartColumn],
			[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
			[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
			[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex], NULL
		FROM [CurrentGame].[fncPossibleActionsQueen] (@IsPlayerWhite, @AssessmentPosition)


		-- --------------------------------------------------------------------------
		-- rook(s)
		-- --------------------------------------------------------------------------

		-- All the rooks on the board are determined. For each rook found in this way, all conceivable and rule-compliant 
		-- actions are now noted. Thus, even after multiple pawn conversions, every rook is taken into account.		
		INSERT INTO @PossibleActions
		(
			[TheoreticalActionID], [HalfMoveNo], [FigureLetter], [IsPlayerWhite], [StartColumn],
			[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
			[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
			[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex], [Rating]
		)
		SELECT [TheoreticalActionID], 1, [FigureLetter], [IsPlayerWhite], [StartColumn],
			[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
			[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
			[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex], NULL 
		FROM [CurrentGame].[fncPossibleActionsRook] (@IsPlayerWhite, @AssessmentPosition)

		-- --------------------------------------------------------------------------
		-- bishop(s)
		-- --------------------------------------------------------------------------
		-- All the bishops on the board are determined. For each bishop found in this way, all conceivable and rule-compliant 
		-- actions are now noted. Thus, even after multiple pawn conversions, every bishop is taken into account.	
		INSERT INTO @PossibleActions
		(
			[TheoreticalActionID], [HalfMoveNo], [FigureLetter], [IsPlayerWhite], [StartColumn],
			[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
			[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
			[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex], [Rating]
		)
		SELECT [TheoreticalActionID], 1, [FigureLetter], [IsPlayerWhite], [StartColumn],
			[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
			[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
			[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex], NULL
		FROM [CurrentGame].[fncPossibleActionsBishop] (@IsPlayerWhite, @AssessmentPosition)

		-- --------------------------------------------------------------------------
		-- Knight(s)
		-- --------------------------------------------------------------------------

		-- All the knights on the board are found. For each knight found in this way, all conceivable actions 
		-- in accordance with the rules are noted. Possible and rule-compliant actions are noted. Thus, even after 
		-- multiple pawn conversions, each knight is taken into account.	
		INSERT INTO @PossibleActions
		(
			[TheoreticalActionID], [HalfMoveNo], [FigureLetter], [IsPlayerWhite], [StartColumn],
			[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
			[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
			[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex], [Rating]
		)
		SELECT [TheoreticalActionID], 1, [FigureLetter], [IsPlayerWhite], [StartColumn],
			[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
			[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
			[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex], NULL
		FROM [CurrentGame].[fncPossibleActionsKnight] (@IsPlayerWhite, @AssessmentPosition)

		-- --------------------------------------------------------------------------
		-- king
		-- --------------------------------------------------------------------------

		-- There is only one king of the same colour on the board. A pawn conversion is not to be taken into account.	
		INSERT INTO @PossibleActions
		(
			[TheoreticalActionID], [HalfMoveNo], [FigureLetter], [IsPlayerWhite], [StartColumn],
			[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
			[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
			[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex], [Rating]
		)
		SELECT [TheoreticalActionID], 1, [FigureLetter], [IsPlayerWhite], [StartColumn],
			[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
			[TransformationFigureLetter], [IsActionCapture],	[IsActionCastlingKingsside], [IsActionCastlingQueensside],
			[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex], NULL
		FROM [CurrentGame].[fncPossibleActionsKing] (@IsPlayerWhite, @AssessmentPosition)

		-- --------------------------------------------------------------------------
		-- pawn(s)
		-- --------------------------------------------------------------------------

		-- There is a maximum of 16 pawns on the board. A pawn conversion is not to be taken into account.	
		INSERT INTO @PossibleActions
		(
			[TheoreticalActionID], [HalfMoveNo], [FigureLetter], [IsPlayerWhite], [StartColumn],
			[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
			[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
			[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex], [Rating]
		)
		SELECT [TheoreticalActionID], 1, [FigureLetter], [IsPlayerWhite], [StartColumn],
			[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
			[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
			[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex], NULL 
		FROM [CurrentGame].[fncPossibleActionsPawn] (@IsPlayerWhite, @AssessmentPosition)

		-- ##########################################################################
		-- ### Illegal actions are filtered out again ###############################
		-- ##########################################################################




		-- --------------------------------------------------------------------------
		-- Rochades
		-- --------------------------------------------------------------------------

		-- It can happen that castling is determined as a "valid" king move, since here only the current game 
		-- situation is analysed from a snapshot. Often, however, the rules of the game prevent castling - for 
		-- example, because a piece has already been moved, which is not necessarily visible from the current 
		-- view of the board. Therefore, the EFN string must be evaluated and individual actions may 
		-- have to be discarded.
		
		DECLARE @BeginOfCastles		AS TINYINT
		DECLARE @Castles			AS VARCHAR(4)
		
		SET @BeginOfCastles			= [Library].[fncCharIndexNG2](' ', @EFN, 2) + 1
		SET @Castles				= LEFT(RIGHT(@EFN, LEN(@EFN) - @BeginOfCastles), CHARINDEX(RIGHT(@EFN, LEN(@EFN) - @BeginOfCastles), ' ', 1))

		IF CHARINDEX(@Castles, 'K', 1) <> 0 DELETE FROM @PossibleActions WHERE [LongNotation] = 'o-o' 
		IF CHARINDEX(@Castles, 'k', 1) <> 0 DELETE FROM @PossibleActions WHERE [LongNotation] = 'o-o'
		IF CHARINDEX(@Castles, 'Q', 1) <> 0 DELETE FROM @PossibleActions WHERE [LongNotation] = 'o-o-o'
		IF CHARINDEX(@Castles, 'q', 1) <> 0 DELETE FROM @PossibleActions WHERE [LongNotation] = 'o-o-o'
		
	

		-- --------------------------------------------------------------------------
		-- en passant
		-- --------------------------------------------------------------------------

		-- It can happen that "en passant" is determined as a "valid" pawn move, since here only the current game 
		-- situation is analysed from a snapshot. Often, however, the rules of the game prevent "en passant" - for 
		-- example, because the pawn's double move was already several moves ago, which is not necessarily visible 
		-- from the current view of the board. Therefore, the EFN string must be evaluated and individual 
		-- actions may have to be discarded.

		DECLARE @BeginOfEnPassant	AS TINYINT
		DECLARE @EnPassant			AS CHAR(2)
		
		SET @BeginOfEnPassant		= [Library].[fncCharIndexNG2](' ', @EFN, 3) + 1
		SET @EnPassant				= LEFT(RIGHT(@EFN, LEN(@EFN) - @BeginOfEnPassant), 2)

		IF @EnPassant <> '- ' 
		BEGIN
			-- the EFN string contains the information that no "en passant" situation exists
			DELETE FROM @PossibleActions WHERE [LongNotation] like '%e.p.'
		END
		ELSE
		BEGIN
			-- it can only be struck "en passant" on the field transmitted in the EFN string. This can be up to 2 
			-- possible captures by the opponent! (my pawn has completed a double move exactly between two pawns of the opponent).

			DELETE FROM @PossibleActions WHERE [LongNotation] like '%e.p.' AND [LongNotation] NOT like '%' + @EnPassant  + 'e.p.'
			
		END


	

		-- --------------------------------------------------------------------------
		-- pinned figures
		-- --------------------------------------------------------------------------

		-- Pieces that are not allowed to move, because they give direct access to the own king, so that it could be 
		-- captured by the opponent in the next move, are called "pinned figures". Since in chess you are not allowed 
		-- to place yourself in check, it is forbidden to move a pinned figure!

		DECLARE @NextPosition				AS [dbo].[typePosition]
		DECLARE @KingField					AS TINYINT
		DECLARE @KingRow					AS TINYINT
		DECLARE @KingColumn					AS CHAR(1)
		DECLARE @cuField					AS TINYINT
		DECLARE @cuTheoreticalAction		AS BIGINT

		SET @KingField	= (SELECT [Field]	FROM @AssessmentPosition WHERE [FigureLetter] = 'K' AND [IsPlayerWhite] = @IsPlayerWhite)
		SET @KingRow	= (SELECT [Row]		FROM @AssessmentPosition WHERE [FigureLetter] = 'K' AND [IsPlayerWhite] = @IsPlayerWhite)
		SET @KingColumn = (SELECT [Column]	FROM @AssessmentPosition WHERE [FigureLetter] = 'K' AND [IsPlayerWhite] = @IsPlayerWhite)






		-- the question of a pinned figure only arises if the opponent still has a (active) queen, bishop or rook at his disposal
		IF EXISTS
			(
				SELECT * FROM @AssessmentPosition
				WHERE 1 = 1
					AND [FigureLetter]		IN ('B', 'Q', 'R') 
					AND [IsPlayerWhite]		= ((@IsPlayerWhite + 1) % 2)
			)
		BEGIN
			-- rook(s)
			DECLARE @FieldRook		AS TINYINT
			DECLARE curRooks CURSOR FOR 
				SELECT * FROM @AssessmentPosition
				WHERE 1 = 1
					AND [FigureLetter]		= 'R' 
					AND [IsPlayerWhite]		= ((@IsPlayerWhite + 1) % 2)

			OPEN curRooks  
			FETCH NEXT FROM curRooks INTO @FieldRook  

			WHILE @@FETCH_STATUS = 0  
			BEGIN  
				
				FETCH NEXT FROM curRooks INTO @FieldRook 
			END 
			CLOSE curRooks  
			DEALLOCATE db_cursor


			-- bishop(s)



			-- queen(s)

		END
		-- *****
		-- hier nicht die möglichen Züege, soindern ausgelagert unmöglichen Zuege mit einer Zwischenfigur




		-- --------------------------------------------------------------------------
		-- Returning the chess bid
		-- --------------------------------------------------------------------------

		-- If you are in check, according to the rules you must react to it in the immediately following move and 
		-- cancel the check bid. This can be done by fleeing the king, striking the generic piece giving the check 
		-- or by breaking the line between one's own king and the piece giving the check (thus only possible with a 
		-- rook, bishop or queen attack). 
		--DECLARE @cuThreat AS BIGINT

		--If EXISTS (SELECT [CurrentGame].[fncIsFieldThreatened]
		--		(
		--			  ((@IsPlayerWhite + 1) % 2)
		--			, @AssessmentPosition
		--			, @KingField
		--		)
		--	)
		--BEGIN
		--	DECLARE cu_Threat CURSOR FOR 
		--		-- A pinneded piece may well move and still remain pinneded - which would then be a valid move
		--		SELECT [PossibleActionID] FROM @PossibleActions
					
		--	OPEN cu_Threat  
		--	FETCH NEXT FROM cu_Threat INTO @cuThreat  

		--	WHILE @@FETCH_STATUS = 0  
		--	BEGIN  
		--		DELETE FROM @NextPosition

		--		INSERT INTO @NextPosition
		--		EXEC [LS_ARELIUM_TSQL_CHESS_V15].[CurrentGame].[prcMovePieces] @AssessmentPosition, @cuThreat

		--		IF (
		--				SELECT [CurrentGame].[fncIsFieldThreatened](
		--					@IsPlayerWhite
		--					, @NextPosition
		--					, @KingField
		--				)
		--			) = 'TRUE'
		--		BEGIN
		--			DELETE FROM @PossibleActions
		--			WHERE [TheoreticalActionID] = @cuThreat
		--		END
		--		FETCH NEXT FROM cu_Threat INTO @cuThreat 
		--	END 

		--	CLOSE cu_Threat  
		--	DEALLOCATE cu_Threat 			
		--END

		SELECT [TheoreticalActionID], 1, [FigureLetter], [IsPlayerWhite], [StartColumn],
			[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
			[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
			[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex], NULL
		FROM @PossibleActions
	--RETURN
	END 
GO





------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistics ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '043 - Procedure [CurrentGame].[prcPossibleActions].sql'
PRINT ' '
PRINT 'Script     :   ' + @Script
PRINT 'End        :   ' + @End
PRINT 'Time       :   ' + @Time
SELECT @Script AS Skript, @End AS Ende, @Time AS Zeit
GO

/*

USE [arelium_TSQL_Chess_V015]
GO

DECLARE @EFN				AS varchar(255)
DECLARE @IsPlayerWhite		AS BIT
DECLARE @AssessmentPosition2	AS [dbo].[typePosition]
DECLARE @FieldPawn			AS TINYINT

SET @EFN = 'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR w KkQq a3 3 1'    --SET @EFN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'   --SET @EFN = '6r1/6pp/7r/1B5K/1P3k2/N7/3R4/8 w - - 30 79'
SET @IsPlayerWhite = 'FALSE'
		
		--INSERT INTO @AssessmentPosition2
			--SELECT * FROM [Infrastructure].[fncEFN2Position](@EFN)

SELECT * FROM [CurrentGame].[fncPossibleActionsAllPieces] ('FALSE', 'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR w KkQq a3 3 1')
*/






