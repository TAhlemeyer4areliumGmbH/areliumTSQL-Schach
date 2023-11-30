-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### Procedure [CurrentGame].[prcPerformAnAction]                                        ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### When it is your turn, you may make a move or capture an opponent's piece. To do     ###
-- ### this, you enter the start and target field (as coordinates). It is not necessary to ###
-- ### enter a piece, as the execution of an action always refers to the current position. ###
-- ### Depending on the type of action, you must enter further information (which is       ###
-- ### otherwise simply assigned NULL). This includes the type of transformation piece in  ###
-- ### the exchange of pawns as well as the questions of whether it is an "en passant"     ###
-- ### move and who is performing the action (White or Black).                             ###
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
CREATE OR ALTER PROCEDURE [CurrentGame].[prcPerformAnAction] 
	(
		  @StartSquare				AS CHAR(2)
		, @TargetSquare				AS CHAR(2)
		, @TransformationFigure		AS CHAR(1)
		, @IsEnPassant				AS BIT
		, @IsPlayerWhite			AS BIT
	)
AS
BEGIN
	DECLARE @StartField				AS INTEGER
	DECLARE @TargetField			AS INTEGER
	DECLARE @FigureLetter			AS CHAR(1)
	DECLARE @FigureColorIsWhite		AS BIT
	DECLARE @DisiredActionID		AS BIGINT
	DECLARE @GameboardA				AS [dbo].[typePosition]
	DECLARE @GameboardB				AS [dbo].[typePosition]
	DECLARE @IsCheck				AS BIT
	DECLARE @IsMate					AS BIT
	DECLARE @ActionID				AS BIGINT

	IF NOT EXISTS
		(	SELECT * FROM [CurrentGame].[GameStatus]
			WHERE 1 = 1
				AND [IsMate] = 'TRUE'
		)
	BEGIN
		-- Read in the current board
		INSERT INTO @GameboardA
		SELECT 
			  [GB].[Column]					AS [Column]
			, [GB].[Row]					AS [Row]
			, [GB].[Field]					AS [Field]
			, [GB].[EFNPositionNr]			AS [EFNPositionNr]
			, [GB].[IsPlayerWhite]			AS [IsPlayerWhite]
			, [GB].[FigureLetter]			AS [FigureLetter]
			, [GB].[FigureUTF8]				AS [FigureUTF8]
		FROM [Infrastructure].[GameBoard]	AS [GB]

		-- Does the parameter @StartSquare have the correct length?
		IF 
			LEN(@StartSquare)		<> 2
		BEGIN
			SELECT 'The start square has an invalid length. The specification of a column and a row such as <e2> is expected.'
			SELECT * FROM [Infrastructure].[vDashboard]
		END
		ELSE
		BEGIN
			-- Does the parameter @StartSquare have the correct format?
			IF 
				   LOWER(LEFT(@StartSquare, 1))		NOT IN ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h')
				OR RIGHT(@StartSquare, 1)			NOT IN ('1', '2', '3', '4', '5', '6', '7', '8')
			BEGIN
				SELECT 'The start square has an invalid format. The specification of a column and a row such as <e2> is expected.'
				SELECT * FROM [Infrastructure].[vDashboard]
			END
			ELSE
			BEGIN
				-- Does the parameter @TargetSquare have the right length?
				IF 
					LEN(@TargetSquare)		<> 2
				BEGIN
					SELECT 'The target square has an invalid length. The specification of a column and a row such as <e2> is expected.'
					SELECT * FROM [Infrastructure].[vDashboard]
				END
				ELSE
				BEGIN
					-- Does the parameter @TargetField have the correct format?
					IF 
						   LOWER(LEFT(@TargetSquare, 1))	NOT IN ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h')
						OR RIGHT(@TargetSquare, 1)			NOT IN ('1', '2', '3', '4', '5', '6', '7', '8')
					BEGIN
						SELECT 'The target square has an invalid format. The specification of a column and a row such as <e2> is expected.'
						SELECT * FROM [Infrastructure].[vDashboard]
					END
					ELSE
					BEGIN
						-- Is a conversion piece indicated and if so, is it a queen, a rook, a bishop or a knight?
						IF (@TransformationFigure IS NOT NULL) AND (UPPER(@TransformationFigure) NOT IN ('K', 'B', 'Q', 'R'))
						BEGIN
							SELECT 'If a transformation piece is indicated, it must be a queen (Q), a rook (R), a bishop (B) or a knight (K)!'
							SELECT * FROM [Infrastructure].[vDashboard]
						END
						ELSE
						BEGIN
							-- Read out start and target field
							SET @StartField		= (	SELECT [Field] 
													FROM [Infrastructure].[GameBoard] 
													WHERE 1 = 1
														AND [Column]	= LEFT(@StartSquare, 1) 
														AND [Row]		= CONVERT(TINYINT, RIGHT(@StartSquare, 1))
												)
							SET @TargetField		= (	SELECT [Field] 
													FROM [Infrastructure].[GameBoard] 
													WHERE 1 = 1
														AND [Column]	= LEFT(@TargetSquare, 1) 
														AND [Row]		= CONVERT(TINYINT, RIGHT(@TargetSquare, 1))
												)
							SET @FigureLetter	= (	SELECT [FigureLetter]
													FROM [Infrastructure].[GameBoard] 
													WHERE 1 = 1
														AND [Field]				= @StartField
												)
							SET @FigureColorIsWhite	= (	SELECT [IsPlayerWhite]
													FROM [Infrastructure].[GameBoard] 
													WHERE 1 = 1
														AND [Field]				= @StartField
												)
							-- Is there a figure on the StartField at all?
							IF @FigureLetter = ' '
							BEGIN
								SELECT 'The StartField is empty. Please choose a field with your own character!'
								SELECT * FROM [Infrastructure].[vDashboard]
							END
							ELSE
							BEGIN
								-- Is there a piece of your colour on the StartField?
								IF @FigureColorIsWhite <> @IsPlayerWhite
								BEGIN
									SELECT 'There is no figure of your own on the StartField. Please choose a field with your own figure!'
									SELECT * FROM [Infrastructure].[vDashboard]
								END
								ELSE
								BEGIN
									-- Should the "right" colour draw?
									IF [CurrentGame].[fncIsNextMoveWhite]() <> @IsPlayerWhite
									BEGIN
										SELECT 'Please note: Currently ' + CASE [CurrentGame].[fncIsNextMoveWhite]() WHEN 'TRUE' THEN 'WHITE' ELSE 'BLACK' END + ' has the right / duty to move!'
										SELECT * FROM [Infrastructure].[vDashboard]
									END
									ELSE
									BEGIN
										-- ... the right player and both start and destination field, own figure ... 
										-- but: Is the move allowed at all? (compulsion to move, chess bid, captivation, ...)
										IF NOT EXISTS
											(	SELECT * 
												FROM [CurrentGame].[PossibleAction]
												WHERE 1 = 1
													AND [StartField]	= @StartField
													AND [TargetField]	= @TargetField
											)
										BEGIN
											SELECT 'this move is not allowed in this situation! Is there perhaps a captivity or a compulsion to move (due to a chess bid)?' AS [Error code]
											SELECT * FROM [Infrastructure].[vDashboard]
										END
										ELSE
										BEGIN
											-- Determine whether there is a move that fulfils the desired parameters - i.e. leads from the StartField to the 
											-- DestinationField. CAUTION: There is a special case in which there are two different moves of the same player with 
											-- identical start- and target-field: The normal pawn move and an en passant move. To distinguish between the two 
											-- cases, look at the target field. If there is a pawn here, it is a normal pawn move - otherwise it is the en passant variant.
											SET @DisiredActionID = (
												SELECT [TheoreticalActionID]
												FROM [CurrentGame].[PossibleAction]
												WHERE 1 = 1
													AND [StartField]					= @StartField
													AND [TargetField]					= @TargetField
													AND (
															   @TransformationFigure	IS NULL 
															OR @TransformationFigure	= [TransformationFigureLetter]
														)
													AND [IsPlayerWhite]			= @IsPlayerWhite
												)
											
											-- Is there such an action?
											IF @DisiredActionID IS NULL
											BEGIN
												SELECT 'there is no valid action (in the current position) to move from' + @StartSquare + ' to ' + @TargetSquare + '!'
												SELECT * FROM [Infrastructure].[vDashboard]
											END
											ELSE
											BEGIN

												-- here the desired move is made and the result is written in the table with the current board. In the 
												-- case of a pawn conversion, an "en passant" or a castling move castling, more than one piece may be affected. 
												TRUNCATE TABLE [Infrastructure].[GameBoard]
												INSERT INTO [Infrastructure].[GameBoard]
													([Column], [Row], [Field], [EFNPositionNr], [IsPlayerWhite], [FigureLetter], [FigureUTF8])  
												EXEC [CurrentGame].[prcMovePieces] @GameboardA, @DisiredActionID

												-- Update the timekeeping for the currently active player
												UPDATE [CurrentGame].[GameStatus]
												SET	  [RemainingTimeInSeconds]	= [RemainingTimeInSeconds] - ABS(DATEDIFF(SECOND, [TimestampLastOpponentMove], GETDATE()))
													, [TimestampLastOpponentMove] = GETDATE()
												WHERE [IsPlayerWhite]		= @IsPlayerWhite

												-- Read in the current board
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
											
												---- Note the move
												SET @ActionID	=	(SELECT ISNULL(MAX([MoveID]), 0) + @IsPlayerWhite FROM [CurrentGame].[Notation])
												SET @IsCheck	=	(SELECT [CurrentGame].[fncIsFieldThreatened]
																		(
																			  @IsPlayerWhite
																			, @GameboardB
																			, (SELECT [Field] FROM @GameboardB WHERE [FigureLetter] = 'K' AND [IsPlayerWhite] = ((@IsPlayerWhite + 1) % 2))
																		)
																	)

												SET @IsMate	= 0 --(SELECT [CurrentGame].[fncIsFieldThreatened]
												--								(
												--									  @IsPlayerWhite
												--									, @GameboardB
												--									, (SELECT [Field] FROM @GameboardB WHERE [FigureLetter] = 'K' AND [IsPlayerWhite] = ((@IsPlayerWhite + 1) % 2))
												--								)
												--							)
										
												INSERT INTO [CurrentGame].[Notation]
														   ( [MoveID]
														   , [IsPlayerWhite]
														   , [TheoreticalActionID]
														   , [LongNotation]
														   , [ShortNotationSimple]
														   , [ShortNotationComplex]
														   , [IsMoveChessBid]
														   , [EFN]
														)
												SELECT
													  @ActionID										AS [MoveID]
													, @IsPlayerWhite								AS [IsPlayerWhite]
													, [TheoreticalActionID]							AS [TheoreticalActionID]
													, CASE @IsCheck 
														WHEN 'TRUE' THEN [LongNotation] + '+'
														ELSE [LongNotation] 
													END												AS [LongNotation]
													, CASE @IsCheck 
														WHEN 'TRUE' THEN [ShortNotationSimple] + '+'
														ELSE [ShortNotationSimple] 
													END												AS [ShortNotationSimple]
													, CASE @IsCheck 
														WHEN 'TRUE' THEN [ShortNotationComplex] + '+'
														ELSE [ShortNotationComplex] 
													END												AS [ShortNotationComplex]
													, @IsCheck										AS [IsMoveChessBid]
													, (SELECT [Infrastructure].[fncPosition2EFN]	
															( @IsPlayerWhite
															, (SELECT [Infrastructure].[fncCastlingPossibilities]())
															, 'a3'				-- *** ToDo En Passant
															, 3					-- *** ToDo 50 Züge Regel
															, 1					-- *** ToDo Zugzahl
															, @GameboardB
															)
														)											AS [EFN]

												FROM [Infrastructure].[TheoreticalAction]
												WHERE [TheoreticalActionID] = @DisiredActionID

											
											
												-- Permanently blocking possible future castles
												IF (SELECT [IsShortCastlingStillAllowed] FROM [CurrentGame].[GameStatus] WHERE [IsPlayerWhite] = @IsPlayerWhite) = 'TRUE'
												BEGIN
													IF @IsPlayerWhite = 'TRUE'
													BEGIN
														-- if rook or king are moved, (short) castling for white is no longer possible
														IF (@StartSquare = 'a1') or (@StartSquare = 'e1')
														BEGIN
															UPDATE [CurrentGame].[GameStatus]
															SET [IsLongCastlingStillAllowed]	= 'FALSE'
															WHERE [IsPlayerWhite]			= @IsPlayerWhite
														END
														-- if rook or king are moved, (long) castling for white is no longer possible
														IF (@StartSquare = 'h1') or (@StartSquare = 'e1')
														BEGIN
															UPDATE [CurrentGame].[GameStatus]
															SET [IsShortCastlingStillAllowed]	= 'FALSE'
															WHERE [IsPlayerWhite]			= @IsPlayerWhite
														END
														-- if field of black rook is occupied, (short) castling for black is no longer possible
														IF (@TargetSquare = 'a8')
														BEGIN
															UPDATE [CurrentGame].[GameStatus]
															SET [IsLongCastlingStillAllowed]	= 'FALSE'
															WHERE [IsPlayerWhite]			= ((@IsPlayerWhite + 1) % 2)
														END
														-- if field of black rook is occupied, (long) castling for black is no longer possible
														IF (@TargetSquare = 'h8')
														BEGIN
															UPDATE [CurrentGame].[GameStatus]
															SET [IsShortCastlingStillAllowed]	= 'FALSE'
															WHERE [IsPlayerWhite]			= ((@IsPlayerWhite + 1) % 2)
														END
													END
													ELSE
													BEGIN
														-- if rook or king are moved, (short) castling for black is no longer possible
														IF (@StartSquare = 'a8') or (@StartSquare = 'e8')
														BEGIN
															UPDATE [CurrentGame].[GameStatus]
															SET [IsLongCastlingStillAllowed]	= 'FALSE'
															WHERE [IsPlayerWhite]			= @IsPlayerWhite
														END
														-- if rook or king are moved, (long) castling for black is no longer possible
														IF (@StartSquare = 'h8') or (@StartSquare = 'e8')
														BEGIN
															UPDATE [CurrentGame].[GameStatus]
															SET [IsShortCastlingStillAllowed]	= 'FALSE'
															WHERE [IsPlayerWhite]			= @IsPlayerWhite
														END
														-- if field of white rook is occupied, (short) castling for white is no longer possible
														IF (@TargetSquare = 'a1')
														BEGIN
															UPDATE [CurrentGame].[GameStatus]
															SET [IsLongCastlingStillAllowed]	= 'FALSE'
															WHERE [IsPlayerWhite]			= ((@IsPlayerWhite + 1) % 2)
														END
														-- if field of white rook is occupied, (long) castling for white is no longer possible
														IF (@TargetSquare = 'h1')
														BEGIN
															UPDATE [CurrentGame].[GameStatus]
															SET [IsShortCastlingStillAllowed]	= 'FALSE'
															WHERE [IsPlayerWhite]			= ((@IsPlayerWhite + 1) % 2)
														END
													END
												END

												-- Determine possible actions
												TRUNCATE TABLE [CurrentGame].[PossibleAction]

												INSERT INTO [CurrentGame].[PossibleAction]
													( [TheoreticalActionID], [HalfMoveNo], [FigureLetter], [IsPlayerWhite], [StartColumn], [StartRow], [StartField]
													, [TargetColumn], [TargetRow], [TargetField], [Direction], [IsActionCapture], [IsActionEnPassant], [IsActionCastlingKingsside]
													, [IsActionCastlingQueensside], [TransformationFigureLetter], [LongNotation], [ShortNotationSimple], [ShortNotationComplex], [Rating])
												SELECT 
													  [TheoreticalActionID], [HalfMoveNo], [FigureLetter], [IsPlayerWhite], [StartColumn], [StartRow], [StartField]
													, [TargetColumn], [TargetRow], [TargetField], [Direction], [IsActionCapture], [IsActionEnPassant], [IsActionCastlingKingsside]
													, [IsActionCastlingQueensside], [TransformationFigureLetter], [LongNotation], [ShortNotationSimple], [ShortNotationComplex], 0
												FROM [CurrentGame].[fncPossibleActionsAllPieces] 
												(
													   ((@IsPlayerWhite + 1) % 2)
													 , (	SELECT TOP 1 [EFN] 
															FROM [CurrentGame].[Notation] 
															WHERE [IsPlayerWhite] = @IsPlayerWhite
															ORDER BY [MoveID] DESC
														)
												)

											
												
												-- Observe the 50-move rule
												IF 
													(SELECT [IsActionCapture] FROM [Infrastructure].[TheoreticalAction] WHERE @DisiredActionID = [TheoreticalActionID]) = 'TRUE'
													OR
													(SELECT [FigureLetter] FROM [Infrastructure].[TheoreticalAction] WHERE @DisiredActionID = [TheoreticalActionID]) = 'P'
												BEGIN
													UPDATE [CurrentGame].[GameStatus]
													SET [Number50ActionsRule]		= 0
													WHERE [IsPlayerWhite]			= @IsPlayerWhite
												END
												ELSE
												BEGIN
													UPDATE [CurrentGame].[GameStatus]
													SET [Number50ActionsRule]		= [Number50ActionsRule] + 1
													WHERE [IsPlayerWhite]			= @IsPlayerWhite
												END

												-- Throw out all library games from the table [Library].[currentlookupoptions] which no 
												-- longer correspond to the current position
												--DELETE FROM [Bibliothek].[aktuelleNachschlageoptionen]
												--WHERE 1 = 1
												--	AND [PartiemetadatenID] NOT IN
												--		(
												--			SELECT [PartiemetadatenID]
												--			FROM [Bibliothek].[aktuelleNachschlageoptionen]
												--			WHERE 1 = 1
												--				AND [Zugnummer] = ISNULL((SELECT ISNULL(MAX([MoveID]), 0) FROM [CurrentGame].[Notation]), 0)
												--				AND	(	
												--						( [ZugWeiss] = 
												--									(	SELECT [ShortNotationSimple] 
												--										FROM [CurrentGame].[Notation] 
												--										WHERE 1 = 1
												--											AND [IsPlayerWhite]	= @IsPlayerWhite
												--											AND [MoveID]			= ISNULL((SELECT ISNULL(MAX([MoveID]), 0) FROM [CurrentGame].[Notation]), 0)
												--									)
												--							AND @IsPlayerWhite	= 'TRUE'
												--						)
												--						OR 
												--						( [ZugSchwarz] = 
												--									(	SELECT [ShortNotationSimple] 
												--										FROM [CurrentGame].[Notation] 
												--										WHERE 1 = 1
												--											AND [IsPlayerWhite]	= @IsPlayerWhite 
												--											AND [MoveID]			= ISNULL((SELECT ISNULL(MAX([MoveID]), 0) FROM [CurrentGame].[Notation]), 0)
												--									)
												--							AND @IsPlayerWhite	= 'FALSE'
												--						)
												--				)
												--		)




												-- Das Amaturenbrett inklusive Spielbrett wird neu gezeichnet
												SELECT * FROM [Infrastructure].[vDashboard]

											END
										END
									END
								END
							END
						END
					END
				END
			END
		END
	END
	ELSE
	BEGIN
		SELECT 'this game is already decided!' AS [error code]
		SELECT * FROM [Infrastructure].[vDashboard]
	END
END
GO



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistics ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '710 - Procedure [CurrentGame].[prcPerformAnAction].sql'
PRINT ' '
PRINT 'Script     :   ' + @Script
PRINT 'End        :   ' + @End
PRINT 'Time       :   ' + @Time
SELECT @Script AS Skript, @End AS Ende, @Time AS Zeit
GO




/*  Test

USE [arelium_TSQL_Chess_V015]
GO

DECLARE @RC int
DECLARE @StartSquare char(2)			= 'b1'
DECLARE @TargetSquare char(2)			= 'c3'
DECLARE @TransformationFigure char(1)	= NULL
DECLARE @IsEnPassant bit				= 'FALSE'
DECLARE @IsPlayerWhite bit				= 'true'


EXECUTE @RC = [CurrentGame].[prcPerformAnAction] 
   @StartSquare
  ,@TargetSquare
  ,@TransformationFigure
  ,@IsEnPassant
  ,@IsPlayerWhite
GO

*/