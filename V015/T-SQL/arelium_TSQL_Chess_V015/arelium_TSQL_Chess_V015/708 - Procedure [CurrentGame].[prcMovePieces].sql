-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### Procedure [CurrentGame].[prcMovePieces]                                             ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Once the validity of an action has been checked, the board needs to be adjusted. To ###
-- ### do this, a piece must be moved to a new square - some actions involve several of    ###
-- ### the player's own pieces or pieces of others: Castling, pawn conversion, all         ###
-- ### captures including the "en passants"...                                             ###
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


CREATE OR ALTER PROCEDURE [CurrentGame].[prcMovePieces]
(
	  @PredecessorPosition					AS [dbo].[typePosition]	READONLY
	, @TheoreticalActionID					AS BIGINT
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @DesiredAction					AS [dbo].[typePossibleAction]
	DECLARE @FollowingPosition				AS [dbo].[typePosition]

    DECLARE @FigureLetter					AS VARCHAR(20)
    DECLARE @IsPlayerWhite					AS BIT
    DECLARE @StartColumn					AS CHAR(1)
    DECLARE @StartRow						AS INTEGER
    DECLARE @StartField						AS INTEGER
    DECLARE @TargetColumn					AS CHAR(1)
    DECLARE @TargetRow						AS INTEGER
    DECLARE @TargetField					AS INTEGER
    DECLARE @Direction						AS CHAR(2)
    DECLARE @TransformationFigureLetter		AS CHAR(1)
    DECLARE @IsActionCapture				AS BIT
    DECLARE @IsActionCastlingKingsside		AS BIT
    DECLARE @IsActionCastlingQueensside		AS BIT
    DECLARE @IsActionEnPassant				AS BIT
    DECLARE @LongNotation					AS VARCHAR(9)
    DECLARE @ShortNotationSimple			AS VARCHAR(8)
    DECLARE @ShortNotationComplex			AS VARCHAR(8)
	
	INSERT INTO @FollowingPosition
		([Column], [Row], [Field], [EFNPositionNr], [IsPlayerWhite], [FigureLetter], [FigureUTF8])
		SELECT 
			  [GB].[Column]					AS [Column]
			, [GB].[Row]					AS [Row]
			, [GB].[Field]					AS [Field]
			, [GB].[EFNPositionNr]			AS [EFNPositionNr]
			, [GB].[IsPlayerWhite]			AS [IsPlayerWhite]
			, [GB].[FigureLetter]			AS [FigureLetter]
			, [GB].[FigureUTF8]				AS [FigureUTF8]
		FROM @PredecessorPosition			AS [GB]


	INSERT INTO @DesiredAction
           ( [TheoreticalActionID], [HalfMoveNo], [FigureLetter], [IsPlayerWhite], [StartColumn]	
		   , [StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction]
		   , [TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside]
		   , [IsActionEnPassant],[LongNotation], [ShortNotationSimple], [ShortNotationComplex], [Rating])
	SELECT
          TheoreticalActionID
		, 1
		, FigureLetter
        , IsPlayerWhite
        , StartColumn
        , StartRow
        , StartField
        , TargetColumn
        , TargetRow
        , TargetField
        , Direction
        , TransformationFigureLetter
        , IsActionCapture
        , IsActionCastlingKingsside
        , IsActionCastlingQueensside
        , IsActionEnPassant
        , LongNotation
        , ShortNotationSimple
        , ShortNotationComplex
		, NULL
	FROM [Infrastructure].[TheoreticalAction]
	WHERE TheoreticalActionID = @TheoreticalActionID

	SET @FigureLetter					= (SELECT [FigureLetter]				FROM @DesiredAction)
	SET @IsPlayerWhite					= (SELECT [IsPlayerWhite]				FROM @DesiredAction)
	SET @StartColumn					= (SELECT [StartColumn]					FROM @DesiredAction)
	SET @StartRow						= (SELECT [StartRow]					FROM @DesiredAction)
	SET @StartField						= (SELECT [StartField]					FROM @DesiredAction)
	SET @TargetColumn					= (SELECT [TargetColumn]				FROM @DesiredAction)
	SET @TargetRow						= (SELECT [TargetRow]					FROM @DesiredAction)
	SET @TargetField					= (SELECT [TargetField]					FROM @DesiredAction)
	SET @Direction						= (SELECT [Direction]					FROM @DesiredAction)
	SET @TransformationFigureLetter		= (SELECT [TransformationFigureLetter]	FROM @DesiredAction)
	SET @IsActionCapture				= (SELECT [IsActionCapture]				FROM @DesiredAction)
	SET @IsActionCastlingKingsside		= (SELECT [IsActionCastlingKingsside]	FROM @DesiredAction)
	SET @IsActionCastlingQueensside		= (SELECT [IsActionCastlingQueensside]	FROM @DesiredAction)
	SET @IsActionEnPassant				= (SELECT [IsActionEnPassant]			FROM @DesiredAction)
	SET @LongNotation					= (SELECT [LongNotation]				FROM @DesiredAction)
	SET @ShortNotationSimple			= (SELECT [ShortNotationSimple]			FROM @DesiredAction)
	SET @ShortNotationComplex			= (SELECT [ShortNotationComplex]		FROM @DesiredAction)

	-- -----------------------------------------------------------
	-- Case 1: short castling
	-- -----------------------------------------------------------
	IF 
		((@StartField = 33 AND @TargetField = 49) OR (@StartField = 40 AND @TargetField = 56))
		AND @FigureLetter = 'K'
	BEGIN
		IF @IsPlayerWhite = 'TRUE'
		BEGIN
			-- Set the new king
			UPDATE @FollowingPosition
			SET   [FigureUTF8]			= 9812
				, [FigureLetter]		= 'K'
				, [IsPlayerWhite]		= @IsPlayerWhite
			WHERE [Field] = 49

			-- Set the new rook
			UPDATE @FollowingPosition
			SET   [FigureUTF8]			= 9814
				, [FigureLetter]		= 'T'
				, [IsPlayerWhite]		= @IsPlayerWhite
			WHERE [Field] = 41

			-- remove the old tower
			UPDATE @FollowingPosition
			SET	  [FigureUTF8]			= 160
				, [FigureLetter]		= NULL
				, [IsPlayerWhite]		= NULL
			WHERE [Field] = 57

			-- remove the old king
			UPDATE @FollowingPosition
			SET	  [FigureUTF8]			= 160
				, [FigureLetter]		= NULL
				, [IsPlayerWhite]		= NULL
			WHERE [Field] = 33
		END
		ELSE
		BEGIN
			-- Set the new king
			UPDATE @FollowingPosition
			SET   [FigureUTF8]			= 9818
				, [FigureLetter]		= 'K'
				, [IsPlayerWhite]		= @IsPlayerWhite
			WHERE [Field] = 56

			-- Set the new rook
			UPDATE @FollowingPosition
			SET   [FigureUTF8]			= 9820
				, [FigureLetter]		= 'T'
				, [IsPlayerWhite]		= @IsPlayerWhite
			WHERE [Field] = 48

			-- remove the old tower
			UPDATE @FollowingPosition
			SET	  [FigureUTF8]			= 160
				, [FigureLetter]		= NULL
				, [IsPlayerWhite]		= NULL
			WHERE [Field] = 64

			-- remove the old king
			UPDATE @FollowingPosition
			SET	  [FigureUTF8]			= 160
				, [FigureLetter]		= NULL
				, [IsPlayerWhite]		= NULL
			WHERE [Field] = 40
		END
	END
	ELSE
	BEGIN
		-- -----------------------------------------------------------
		-- Case 2: castling long
		-- -----------------------------------------------------------
		IF
			((@StartField = 33 AND @TargetField = 17) OR (@StartField = 40 AND @TargetField = 24))
			AND @FigureLetter = 'K'
		BEGIN
			IF @IsPlayerWhite = 'TRUE'
			BEGIN
				-- Set the new king
				UPDATE @FollowingPosition
				SET   [FigureUTF8]			= 9812
					, [FigureLetter]		= 'K'
					, [IsPlayerWhite]		= @IsPlayerWhite
				WHERE [Field] = 17

				-- Set the new rook
				UPDATE @FollowingPosition
				SET   [FigureUTF8]			= 9814
					, [FigureLetter]		= 'T'
					, [IsPlayerWhite]		= @IsPlayerWhite
				WHERE [Field] = 25

				-- remove the old tower
				UPDATE @FollowingPosition
				SET	  [FigureUTF8]			= 160
					, [FigureLetter]		= NULL
					, [IsPlayerWhite]		= NULL
				WHERE [Field] = 1

				-- remove the old king
				UPDATE @FollowingPosition
				SET	  [FigureUTF8]			= 160
					, [FigureLetter]		= ' '
					, [IsPlayerWhite]		= NULL
				WHERE [Field] = 33
			END
			ELSE
			BEGIN
				---- Set the new king
				UPDATE @FollowingPosition
				SET   [FigureUTF8]			= 9818
					, [FigureLetter]		= 'K'
					, [IsPlayerWhite]		= @IsPlayerWhite
				WHERE [Field] = 24

				-- Set the new rook
				UPDATE @FollowingPosition
				SET   [FigureUTF8]			= 9820
					, [FigureLetter]		= 'T'
					, [IsPlayerWhite]		= @IsPlayerWhite
				WHERE [Field] = 33

				-- remove the old tower
				UPDATE @FollowingPosition
				SET	  [FigureUTF8]			= 160
					, [FigureLetter]		= NULL
					, [IsPlayerWhite]		= NULL
				WHERE [Field] = 8

				-- remove the old king
				UPDATE @FollowingPosition
				SET	  [FigureUTF8]			= 160
					, [FigureLetter]		= NULL
					, [IsPlayerWhite]		= NULL
				WHERE [Field] = 40
			END
		END
		ELSE
		BEGIN
			-- -----------------------------------------------------------
			-- Case 3: pawn transformation
			-- -----------------------------------------------------------
			IF @TransformationFigureLetter IS NOT NULL
			BEGIN
				-- set the new figure (Q, B, K or R)
				UPDATE @FollowingPosition
				SET   [FigureUTF8]			= (	SELECT [FigureUTF8] 
												FROM [Infrastructure].[Figure]
												WHERE 1 = 1
													AND [FigureLetter]		= @TransformationFigureLetter 
													AND [IsPlayerWhite]		= @IsPlayerWhite
												)
					, [FigureLetter]		= @TransformationFigureLetter
					, [IsPlayerWhite]		= @IsPlayerWhite
				WHERE [Field] = @TargetField

				-- remove the old pawn
				UPDATE @FollowingPosition
				SET	  [FigureUTF8]			= 160
					, [FigureLetter]		= NULL
					, [IsPlayerWhite]		= NULL
				WHERE [Field] = @StartField
			END
			ELSE
			BEGIN
				-- -----------------------------------------------------------
				-- Case 4: en passant
				-- -----------------------------------------------------------
				IF @IsActionEnPassant = 'TRUE'
				BEGIN
					-- set the new pawn
					UPDATE @FollowingPosition
					SET   [FigureUTF8]			= (	SELECT TOP 1 [FigureUTF8] 
													FROM @PredecessorPosition
													WHERE 1 = 1
														AND [FigureLetter] = 'B' 
														AND [IsPlayerWhite] = @IsPlayerWhite
													)
						, [FigureLetter]		= 'B'
						, [IsPlayerWhite]		= @IsPlayerWhite
					WHERE [Field] = @TargetField

					-- remove (2!) old pawns
					UPDATE @FollowingPosition
					SET	  [FigureUTF8]			= 160
						, [FigureLetter]		= NULL
						, [IsPlayerWhite]		= NULL
					WHERE	   [Field] = @StartField 
							OR [Field] = (CASE [IsPlayerWhite] 
										WHEN 'TRUE'	THEN @TargetField + 1
										ELSE @TargetField - 1
										END)
				END
				ELSE
				BEGIN
					-- -----------------------------------------------------------
					-- Case 5: Standard move
					-- -----------------------------------------------------------
						
					-- set the new figure
					UPDATE @FollowingPosition
					SET   [FigureUTF8]			= (	SELECT [FigureUTF8] 
													FROM @PredecessorPosition
													WHERE [Field] = @StartField
													)
						, [FigureLetter]		= (	SELECT [FigureLetter] 
													FROM @PredecessorPosition
													WHERE [Field] = @StartField
													)
						, [IsPlayerWhite]		= @IsPlayerWhite
					WHERE [Field] = @TargetField

					-- remove the old figure
					UPDATE @FollowingPosition
					SET	  [FigureUTF8]			= 160
						, [FigureLetter]		= NULL
						, [IsPlayerWhite]		= NULL
					WHERE [Field] = @StartField 
				END
			END
		END
	END


	-- Output new position
	SELECT 
		[Column], [Row], [Field], [EFNPositionNr], [IsPlayerWhite], [FigureLetter], [FigureUTF8]
	FROM @FollowingPosition
END
GO




------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistics ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '708 - Procedure [CurrentGame].[prcMovePieces].sql'
PRINT ' '
PRINT 'Script     :   ' + @Script
PRINT 'End        :   ' + @End
PRINT 'Time       :   ' + @Time
SELECT @Script AS Skript, @End AS Ende, @Time AS Zeit
GO


/*
DECLARE @GameboardA				AS [dbo].[typePosition]

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

		SELECT * FROM @GameboardA

EXEC [CurrentGame].[prcMovePieces] @GameboardA, 14681





USE [arelium_TSQL_Chess_V015]
GO

DECLARE @StartSquare char(2)			= 'E2'
DECLARE @TargetSquare char(2)			= 'E4'
DECLARE @TransformationFigure char(1)	= NULL
DECLARE @IsEnPassant bit				= 'FALSE'
DECLARE @IsPlayerWhite bit				= 'TRUE'

EXECUTE [CurrentGame].[prcPerformAnAction] 
   @StartSquare
  ,@TargetSquare
  ,@TransformationFigure
  ,@IsEnPassant
  ,@IsPlayerWhite
GO


*/