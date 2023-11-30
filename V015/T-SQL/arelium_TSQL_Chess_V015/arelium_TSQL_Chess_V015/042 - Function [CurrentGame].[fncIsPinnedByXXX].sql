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


CREATE OR ALTER FUNCTION [CurrentGame].[fncIsPinnedByRook] 
(
	   @IsPlayerWhite			AS BIT										-- colour of the pinned figure
	 , @AssessmentPosition		AS [dbo].[typePosition]			READONLY
	 , @PossiblePinnedField		AS TINYINT
	 , @ThreatenedKingField		AS TINYINT
)
RETURNS BIT
AS
BEGIN
	DECLARE @RookField			AS TINYINT
	DECLARE @ReturnValue		AS BIT
	DECLARE @RowRook			AS INTEGER
	DECLARE @RowKing			AS INTEGER	
	DECLARE @RowPinnedField		AS TINYINT	
	DECLARE @ColumnRook			AS INTEGER
	DECLARE @ColumnKing			AS INTEGER
	DECLARE @ColumnPinnedField	AS INTEGER	
	DECLARE db_cursor			CURSOR FOR 
		SELECT [Field] 
		FROM @AssessmentPosition
		WHERE 1 = 1
			AND [IsPlayerWhite]		= ((@IsPlayerWhite + 1) % 2)
			AND [FigureLetter]		= 'R'

	SET @ReturnValue		= 'FALSE'
	SET @RowKing			= (SELECT [Row]		FROM @AssessmentPosition WHERE [Field] = @ThreatenedKingField)
	SET @RowPinnedField		= (SELECT [Row]		FROM @AssessmentPosition WHERE [Field] = @PossiblePinnedField)
	SET @ColumnKing			= (SELECT [Column]	FROM @AssessmentPosition WHERE [Field] = @ThreatenedKingField)
	SET @ColumnPinnedField	= (SELECT [Column]	FROM @AssessmentPosition WHERE [Field] = @PossiblePinnedField)

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @RookField  

	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		SET @RowRook		= (SELECT [Row]		FROM @AssessmentPosition WHERE [Field] = @RookField)
		SET @ColumnRook		= (SELECT [Column]	FROM @AssessmentPosition WHERE [Field] = @RookField)

		-- the attacking (opponent's) rook and the attacked (own) king must be on the same horizontal line. 
		-- The potentially pinned (own) piece must be between these pieces on the same horizontal line
		IF (@RowRook = @RowKing) AND (@RowKing = @RowPinnedField) AND (@ColumnPinnedField BETWEEN @ColumnKing AND @ColumnRook)
		BEGIN
			-- the attacking (opponent's) rook is to the right of the attacked (own) king
			-- the pinned piece must be the only piece between the rook and the king!
			IF @ColumnRook > @ColumnKing
			BEGIN
				IF (SELECT COUNT(*) FROM @AssessmentPosition 
					WHERE 1 = 1 
						AND [Row] = @RowRook
						AND [Column] BETWEEN CHAR(ASCII(@ColumnKing) + 1) AND CHAR(ASCII(@ColumnRook) - 1)
						AND [Field] <> @PossiblePinnedField
						AND [FigureLetter] IS NOT NULL
					) = 0
				BEGIN
					SET @ReturnValue = 'TRUE'
				END
			END 
			ELSE 
			-- the attacking (opponent's) rook is to the left of the attacked (own) king
			-- the pinned piece must be the only piece between the rook and the king!
			BEGIN
				IF (SELECT COUNT(*) FROM @AssessmentPosition 
					WHERE 1 = 1 
						AND [Row] = @RowRook
						AND [Column] BETWEEN CHAR(ASCII(@ColumnRook) + 1) AND CHAR(ASCII(@ColumnKing) - 1)
						AND [Field] <> @PossiblePinnedField
						AND [FigureLetter] IS NOT NULL
					) = 0
				BEGIN
					SET @ReturnValue = 'TRUE'
				END
			END
		END



		-- the attacking (opponent's) rook and the attacked (own) king must be on the same vertical line. 
		-- The potentially pinned (own) piece must be between these pieces on the same horizontal line
		IF (@ColumnRook = @ColumnKing) AND (@ColumnKing = @ColumnPinnedField) AND (@RowPinnedField BETWEEN @RowKing AND @RowRook)
		BEGIN
			-- the attacking (opponent's) rook is positioned above your own king
			-- the pinned piece must be the only piece between the rook and the king!
			IF @RowRook > @RowKing
			BEGIN
				IF (SELECT COUNT(*) FROM @AssessmentPosition 
					WHERE 1 = 1 
						AND [Column] = @ColumnRook
						AND [Row] BETWEEN @RowKing + 1 AND @RowRook - 1
						AND [Field] <> @PossiblePinnedField
						AND [FigureLetter] IS NOT NULL
					) = 0
				BEGIN
					SET @ReturnValue = 'TRUE'
				END
			END 
			ELSE 
			-- the attacking (opponent's) rook is positioned below your own king
			-- the pinned piece must be the only piece between the rook and the king!
			BEGIN
				IF (SELECT COUNT(*) FROM @AssessmentPosition 
					WHERE 1 = 1 
						AND [Column] = @ColumnRook
						AND [Row] BETWEEN @RowRook + 1 AND @RowKing - 1
						AND [Field] <> @PossiblePinnedField
						AND [FigureLetter] IS NOT NULL
					) = 0
				BEGIN
					SET @ReturnValue = 'TRUE'
				END
			END
		END

		FETCH NEXT FROM db_cursor INTO @RookField 
	END 

	CLOSE db_cursor  
	DEALLOCATE db_cursor
	RETURN @ReturnValue
END
GO



















CREATE OR ALTER FUNCTION [CurrentGame].[fncIsPinnedByQueen] 
(
	   @IsPlayerWhite			AS BIT										-- colour of the pinned figure
	 , @AssessmentPosition		AS [dbo].[typePosition]			READONLY
	 , @PossiblePinnedField		AS TINYINT
	 , @ThreatenedKingField		AS TINYINT
)
RETURNS BIT
AS
BEGIN
	DECLARE @QueenField			AS TINYINT
	DECLARE @ReturnValue		AS BIT
	DECLARE @RowQueen			AS INTEGER
	DECLARE @RowKing			AS INTEGER
	DECLARE @RowPinnedField		AS INTEGER	
	DECLARE @ColumnQueen		AS CHAR(1)
	DECLARE @ColumnKing			AS CHAR(1)
	DECLARE @ColumnPinnedField	AS CHAR(1)	
	DECLARE db_cursor			CURSOR FOR 
		SELECT [Field] 
		FROM @AssessmentPosition
		WHERE 1 = 1
			AND [IsPlayerWhite]		= ((@IsPlayerWhite + 1) % 2)
			AND [FigureLetter]		= 'Q'

	SET @ReturnValue		= 'FALSE'
	SET @RowKing			= (SELECT [Row]		FROM @AssessmentPosition WHERE [Field] = @ThreatenedKingField)
	SET @RowPinnedField		= (SELECT [Row]		FROM @AssessmentPosition WHERE [Field] = @PossiblePinnedField)
	SET @ColumnKing			= (SELECT [Column]	FROM @AssessmentPosition WHERE [Field] = @ThreatenedKingField)
	SET @ColumnPinnedField	= (SELECT [Column]	FROM @AssessmentPosition WHERE [Field] = @PossiblePinnedField)

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @QueenField  

	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		SET @RowQueen			= (SELECT [Row]		FROM @AssessmentPosition WHERE [Field] = @QueenField)
		SET @ColumnQueen		= (SELECT [Column]	FROM @AssessmentPosition WHERE [Field] = @QueenField)


		-- the attacking (opponent's) queen and the attacked (own) king must be on the same diagonal. 
		-- The potentially pinned (own) piece must be between these pieces on the same diagonal
		IF	    ABS(@RowQueen	- @RowKing)			= ABS(ASCII(@ColumnQueen)	- ASCII(@ColumnKing))				-- king and queen are on a diagonal
			AND ABS(@RowKing	- @RowPinnedField)	= ABS(ASCII(@ColumnKing)	- ASCII(@ColumnPinnedField))		-- king and pinned figure are on a diagonal
			AND ABS(@RowQueen	- @RowPinnedField)	= ABS(ASCII(@ColumnQueen)	- ASCII(@ColumnPinnedField))		-- pinned figure and queen are on a diagonal
			AND ABS(@RowKing	- @RowPinnedField)	< ABS(@RowQueen		- @RowKing)					-- the distance between the pinned piece and the king is smaller than the distance between the queen and the king
			AND ABS(@RowQueen	- @RowPinnedField)	< ABS(@RowQueen		- @RowKing)					-- the distance between the pinned piece and the queen is smaller than the distance between the queen and the king
		BEGIN
			-- the attacking (opponent's) Queen is to the right of the attacked (own) king
			-- the pinned piece must be the only piece between the Queen and the king!
			IF @ColumnQueen > @ColumnKing
			BEGIN
				IF (SELECT COUNT(*) FROM @AssessmentPosition 
					WHERE 1 = 1 
						AND [Column] < @ColumnQueen
						AND [Column] > @ColumnKing
						AND ABS(ASCII([Column]) - ASCII(@ColumnKing)) = ABS([Row] - @RowKing)
						AND [Field] <> @PossiblePinnedField
						AND [FigureLetter] IS NOT NULL
					) = 0
				BEGIN
					SET @ReturnValue = 'TRUE'
				END
			END 
			ELSE 
			-- the attacking (opponent's) Queen is to the left of the attacked (own) king
			-- the pinned piece must be the only piece between the Queen and the king!
			BEGIN
				IF (SELECT COUNT(*) FROM @AssessmentPosition 
					WHERE 1 = 1 
						AND [Column] > @ColumnQueen
						AND [Column] < @ColumnKing
						AND ABS(ASCII([Column]) - ASCII(@ColumnKing)) = ABS([Row] - @RowKing)
						AND [Field] <> @PossiblePinnedField
						AND [FigureLetter] IS NOT NULL
					) = 0
				BEGIN
					SET @ReturnValue = 'TRUE'
				END
			END
		END





		-- the attacking (opponent's) Queen and the attacked (own) king must be on the same horizontal line. 
		-- The potentially pinned (own) piece must be between these pieces on the same horizontal line
		IF (@RowQueen = @RowKing) AND (@RowKing = @RowPinnedField) AND (@ColumnPinnedField BETWEEN @ColumnKing AND @ColumnQueen)
		BEGIN
			-- the attacking (opponent's) Queen is to the right of the attacked (own) king
			-- the pinned piece must be the only piece between the Queen and the king!
			IF @ColumnQueen > @ColumnKing
			BEGIN
				IF (SELECT COUNT(*) FROM @AssessmentPosition 
					WHERE 1 = 1 
						AND [Row] = @RowQueen
						AND [Column] BETWEEN CHAR(ASCII(@ColumnKing) + 1) AND CHAR(ASCII(@ColumnQueen) - 1)
						AND [Field] <> @PossiblePinnedField
						AND [FigureLetter] IS NOT NULL
					) = 0
				BEGIN
					SET @ReturnValue = 'TRUE'
				END
			END 
			ELSE 
			-- the attacking (opponent's) Queen is to the left of the attacked (own) king
			-- the pinned piece must be the only piece between the Queen and the king!
			BEGIN
				IF (SELECT COUNT(*) FROM @AssessmentPosition 
					WHERE 1 = 1 
						AND [Row] = @RowQueen
						AND [Column] BETWEEN CHAR(ASCII(@ColumnQueen) + 1) AND CHAR(ASCII(@ColumnKing) - 1)
						AND [Field] <> @PossiblePinnedField
						AND [FigureLetter] IS NOT NULL
					) = 0
				BEGIN
					SET @ReturnValue = 'TRUE'
				END
			END
		END



		-- the attacking (opponent's) Queen and the attacked (own) king must be on the same vertical line. 
		-- The potentially pinned (own) piece must be between these pieces on the same horizontal line
		IF (@ColumnQueen = @ColumnKing) AND (@ColumnKing = @ColumnPinnedField) AND (@RowPinnedField BETWEEN @RowKing AND @RowQueen)
		BEGIN
			-- the attacking (opponent's) Queen is positioned above your own king
			-- the pinned piece must be the only piece between the Queen and the king!
			IF @RowQueen > @RowKing
			BEGIN
				IF (SELECT COUNT(*) FROM @AssessmentPosition 
					WHERE 1 = 1 
						AND [Column] = @ColumnQueen
						AND [Row] BETWEEN @RowKing + 1 AND @RowQueen - 1
						AND [Field] <> @PossiblePinnedField
						AND [FigureLetter] IS NOT NULL
					) = 0
				BEGIN
					SET @ReturnValue = 'TRUE'
				END
			END 
			ELSE 
			-- the attacking (opponent's) Queen is positioned below your own king
			-- the pinned piece must be the only piece between the Queen and the king!
			BEGIN
				IF (SELECT COUNT(*) FROM @AssessmentPosition 
					WHERE 1 = 1 
						AND [Column] = @ColumnQueen
						AND [Row] BETWEEN @RowQueen + 1 AND @RowKing - 1
						AND [Field] <> @PossiblePinnedField
						AND [FigureLetter] IS NOT NULL
					) = 0
				BEGIN
					SET @ReturnValue = 'TRUE'
				END
			END
		END

		FETCH NEXT FROM db_cursor INTO @QueenField 
	END 

	CLOSE db_cursor  
	DEALLOCATE db_cursor
	RETURN @ReturnValue
END
GO






















CREATE OR ALTER FUNCTION [CurrentGame].[fncIsPinnedByBishop] 
(
	   @IsPlayerWhite			AS BIT										-- colour of the pinned figure
	 , @AssessmentPosition		AS [dbo].[typePosition]			READONLY
	 , @PossiblePinnedField		AS TINYINT
	 , @ThreatenedKingField		AS TINYINT
)
RETURNS BIT
AS
BEGIN
	DECLARE @BishopField		AS TINYINT
	DECLARE @ReturnValue		AS BIT
	DECLARE @RowBishop			AS TINYINT
	DECLARE @RowKing			AS TINYINT	
	DECLARE @RowPinnedField		AS INTEGER
	DECLARE @ColumnBishop		AS CHAR(1)
	DECLARE @ColumnKing			AS CHAR(1)
	DECLARE @ColumnPinnedField	AS CHAR(1)	
	DECLARE db_cursor			CURSOR FOR 
		SELECT [Field] 
		FROM @AssessmentPosition
		WHERE 1 = 1
			AND [IsPlayerWhite]		= ((@IsPlayerWhite + 1) % 2)
			AND [FigureLetter]		= 'B'

	SET @ReturnValue		= 0
	SET @RowKing			= (SELECT [Row]		FROM @AssessmentPosition WHERE [Field] = @ThreatenedKingField)
	SET @RowPinnedField		= (SELECT [Row]		FROM @AssessmentPosition WHERE [Field] = @PossiblePinnedField)
	SET @ColumnKing			= (SELECT [Column]	FROM @AssessmentPosition WHERE [Field] = @ThreatenedKingField)
	SET @ColumnPinnedField	= (SELECT [Column]	FROM @AssessmentPosition WHERE [Field] = @PossiblePinnedField)

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @BishopField  

	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		SET @RowBishop			= (SELECT [Row]		FROM @AssessmentPosition WHERE [Field] = @BishopField)
		SET @ColumnBishop		= (SELECT [Column]	FROM @AssessmentPosition WHERE [Field] = @BishopField)


		-- the attacking (opponent's) Bishop and the attacked (own) king must be on the same diagonal. 
		-- The potentially pinned (own) piece must be between these pieces on the same diagonal
		IF		ABS(@RowBishop	- @RowKing)			= ABS(ASCII(@ColumnBishop)	- ASCII(@ColumnKing))			-- king and Bishop are on a diagonal
			AND ABS(@RowKing	- @RowPinnedField)	= ABS(ASCII(@ColumnKing)	- ASCII(@ColumnPinnedField))	-- king and pinned figure are on a diagonal
			AND ABS(@RowBishop	- @RowPinnedField)	= ABS(ASCII(@ColumnBishop)	- ASCII(@ColumnPinnedField))	-- pinned figure and Bishop are on a diagonal
			AND ABS(@RowKing	- @RowPinnedField)	< ABS(@RowBishop	- @RowKing)								-- the distance between the pinned piece and the king is smaller than the distance between the Bishop and the king
			AND ABS(@RowBishop	- @RowPinnedField)	< ABS(@RowBishop	- @RowKing)								-- the distance between the pinned piece and the Bishop is smaller than the distance between the Bishop and the king
		BEGIN
			-- the attacking (opponent's) Bishop is to the right of the attacked (own) king
			-- the pinned piece must be the only piece between the Bishop and the king!
			IF @ColumnBishop > @ColumnKing
			BEGIN
				IF (SELECT COUNT(*) FROM @AssessmentPosition 
					WHERE 1 = 1 
						AND [Column] < @ColumnBishop
						AND [Column] > @ColumnKing
						AND ABS(ASCII([Column]) - ASCII(@ColumnKing)) = ABS([Row] - @RowKing)
						AND [Field] <> @PossiblePinnedField
						AND [FigureLetter] IS NOT NULL
					) = 0
				BEGIN
					SET @ReturnValue = 'TRUE'
				END
			END 
			ELSE 
			-- the attacking (opponent's) Bishop is to the left of the attacked (own) king
			-- the pinned piece must be the only piece between the Bishop and the king!
			BEGIN
				IF (SELECT COUNT(*) FROM @AssessmentPosition 
					WHERE 1 = 1 
						AND [Column] > @ColumnBishop
						AND [Column] < @ColumnKing
						AND ABS(ASCII([Column]) - ASCII(@ColumnKing)) = ABS([Row] - @RowKing)
						AND [Field] <> @PossiblePinnedField
						AND [FigureLetter] IS NOT NULL
					) = 0
				BEGIN
					SET @ReturnValue = 'TRUE'
				END
			END
		END

		FETCH NEXT FROM db_cursor INTO @BishopField 
	END 

	CLOSE db_cursor  
	DEALLOCATE db_cursor
	RETURN @ReturnValue
END
GO



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistics ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '042 - Functions [CurrentGame].[fncIsPinnedByXXX].sql'
PRINT ' '
PRINT 'Script     :   ' + @Script
PRINT 'End        :   ' + @End
PRINT 'Time       :   ' + @Time
SELECT @Script AS Skript, @End AS Ende, @Time AS Zeit
GO




/* test the functions

USE [arelium_TSQL_Chess_V015]
GO

DECLARE @EFN				AS varchar(255)
DECLARE @IsPlayerWhite		AS BIT
DECLARE @AssessmentPosition2	AS [dbo].[typePosition]
DECLARE @FieldPawn			AS TINYINT

SET @EFN = 'k7/8/8/B7/8/8/8/R4K3 w KQkq - 0 1'
SET @IsPlayerWhite = 'TRUE'
		
INSERT INTO @AssessmentPosition2
	SELECT * FROM [Infrastructure].[fncEFN2Position](@EFN)

SELECT [CurrentGame].[fncIsPinnedByBishop] (
	   1						-- <@IsPlayerWhite, bit,>
	, @AssessmentPosition2		-- <@AssessmentPosition, [dbo].[typePosition],>
	,  5						-- <@PossiblePinnedField, tinyint,>
	, (SELECT [Field] FROM @AssessmentPosition2 WHERE [FigureLetter] = 'K' AND [IsPlayerWhite] = @IsPlayerWhite)
								-- <@ThreatenedKingField, tinyint,>
	)
GO





*/