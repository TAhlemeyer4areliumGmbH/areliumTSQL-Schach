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



--------------------------------------------------------------------------------------------------
-- Rook(s) ---------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

CREATE OR ALTER FUNCTION [CurrentGame].[fncPossibleActionsRook] 
(
	   @IsPlayerWhite		AS BIT
	 , @AssessmentPosition	AS [dbo].[typePosition]			READONLY
	 , @ActiveField			AS INTEGER								
)
RETURNS @PossibleActionsRook TABLE 
	(
		  [TheoreticalActionID]			BIGINT			NOT NULL
		, [FigureLetter]				CHAR(1)			NOT NULL
		, [IsPlayerWhite]				BIT				NOT NULL
		, [StartColumn]					CHAR(1)			NOT NULL
		, [StartRow]					TINYINT			NOT NULL
		, [StartField]					TINYINT			NOT NULL
		, [TargetColumn]				CHAR(1)			NOT NULL
		, [TargetRow]					TINYINT			NOT NULL
		, [TargetField]					TINYINT			NOT NULL
		, [Direction]					CHAR(2)			NOT NULL
		, [IsActionCapture]				BIT				NOT NULL
		, [IsActionEnPassant]			BIT				NOT NULL
		, [IsActionCastlingKingsside]	BIT				NOT NULL
		, [IsActionCastlingQueensside]	BIT				NOT NULL
		, [TransformationFigureLetter]	CHAR(1)			NULL
		, [LongNotation]				VARCHAR(20)		NULL
		, [ShortNotationSimple]			VARCHAR(8)		NULL
		, [ShortNotationComplex]		VARCHAR(8)		NULL
	) AS
	BEGIN

		INSERT INTO @PossibleActionsRook
		(
			  [TheoreticalActionID]
			, [FigureLetter]
			, [IsPlayerWhite]
			, [StartColumn]
			, [StartRow]
			, [StartField]
			, [TargetColumn]
			, [TargetRow]
			, [TargetField]
			, [Direction]
			, [IsActionCapture]
			, [IsActionEnPassant]
			, [IsActionCastlingKingsside]
			, [IsActionCastlingQueensside]
			, [TransformationFigureLetter]
			, [LongNotation]
			, [ShortNotationSimple]
			, [ShortNotationComplex]
		)
		SELECT DISTINCT
			  [MZU].[TheoreticalActionID]					AS [TheoreticalActionID]
			, [MZU].[FigureLetter]							AS [FigureLetter]			
			, [MZU].[IsPlayerWhite]							AS [IsPlayerWhite]
			, [MZU].[StartColumn]							AS [StartColumn]
			, [MZU].[StartRow]								AS [StartRow]
			, [MZU].[StartField]							AS [StartField]
			, [MZU].[TargetColumn]							AS [TargetColumn]
			, [MZU].[TargetRow]								AS [TargetRow]
			, [MZU].[TargetField]							AS [TargetField]
			, [MZU].[Direction]								AS [Direction]
			, [MZU].[IsActionCapture]						AS [IsActionCapture]
			, [MZU].[IsActionEnPassant]						AS [IsActionEnPassant]
			, [MZU].[IsActionCastlingKingsside]				AS [IsActionCastlingKingsside]
			, [MZU].[IsActionCastlingQueensside]			AS [IsActionCastlingQueensside]
			, NULL											AS [TransformationFigureLetter]
			, [LongNotation]								AS [LongNotation]
			, [ShortNotationSimple]							AS [ShortNotationSimple]
			, [ShortNotationComplex]						AS [ShortNotationComplex]
		FROM [Infrastructure].[TheoreticalAction]			AS [MZU]						
		INNER JOIN @AssessmentPosition						AS [SPB]						
			ON 1 = 1
				AND [MZU].[TargetRow]				= [SPB].[Row]
				AND [MZU].[TargetColumn]			= [SPB].[Column]
		WHERE 1 = 1
			AND [MZU].[IsPlayerWhite]				= @IsPlayerWhite
			AND [MZU].[FigureLetter]				= 'R'
			AND [MZU].[StartField]					= @ActiveField

			-- If it is a move, the target field is empty. If, on the other hand, it is a 
			-- strike, the target field must be occupied.
			AND (
					([SPB].[FigureUTF8] = 160		AND [MZU].[IsActionCapture] = 'FALSE')
					OR
					([SPB].[FigureUTF8] <> 160		AND [MZU].[IsActionCapture] = 'TRUE')
				)

			-- For each direction of movement, all squares up to the
			-- first piece (of any colour) that is in the way.

			-- first figure in the path to the right
			AND [MZU].[TargetColumn] <= ISNULL(
				(
					SELECT MIN([Inside].[Column])
					FROM @AssessmentPosition				AS [Inside]
					WHERE 1 = 1
						AND [Inside].[FigureUTF8]		<> 160
						AND [Inside].[Column]		> [MZU].[StartColumn]
						AND [Inside].[Row]			= [MZU].[StartRow]
				), 'H')

			-- first figure in the path to the left
			AND [MZU].[TargetColumn] >= ISNULL(
				(
					SELECT MAX([Inside].[Column])
					FROM @AssessmentPosition				AS [Inside]
					WHERE 1 = 1
						AND [Inside].[FigureUTF8]		<> 160
						AND [Inside].[Column]		< [MZU].[StartColumn]
						AND [Inside].[Row]			= [MZU].[StartRow]
				), 'A')

			-- first figure in the way up
			AND [MZU].[TargetRow] <= ISNULL(
				(
					SELECT MIN([Inside].[Row])
					FROM @AssessmentPosition				AS [Inside]
					WHERE 1 = 1
						AND [Inside].[FigureUTF8]		<> 160
						AND [Inside].[Column]		= [MZU].[StartColumn]
						AND [Inside].[Row]			> [MZU].[StartRow]
				), 8)

			-- first figure in the way down
			AND [MZU].[TargetRow] >= ISNULL(
				(
					SELECT MAX([Inside].[Row])
					FROM @AssessmentPosition				AS [Inside]
					WHERE 1 = 1
						AND [Inside].[FigureUTF8]		<> 160
						AND [Inside].[Column]		= [MZU].[StartColumn]
						AND [Inside].[Row]			< [MZU].[StartRow]
				), 1)

			-- no piece of your own colour may be captured
			AND [SPB].[FigureUTF8] NOT IN 
				(
					SELECT [FigureUTF8] FROM [Infrastructure].[Figure]
					WHERE 1 = 1
						AND [IsPlayerWhite] = @IsPlayerWhite
				)
		RETURN
	END
GO


--------------------------------------------------------------------------------------------------
-- Knight(s) -------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

CREATE OR ALTER FUNCTION [CurrentGame].[fncPossibleActionsKnight]
(
	   @IsPlayerWhite		AS BIT
	 , @AssessmentPosition	AS [dbo].[typePosition]			READONLY
	 , @ActiveField			AS INTEGER
)
RETURNS @PossibleActionsKnight TABLE 
	(
		  [TheoreticalActionID]			BIGINT			NOT NULL
		, [FigureLetter]					CHAR(1)			NOT NULL
		, [IsPlayerWhite]				BIT				NOT NULL
		, [StartColumn]					CHAR(1)			NOT NULL
		, [StartRow]					TINYINT			NOT NULL
		, [StartField]					TINYINT			NOT NULL
		, [TargetColumn]				CHAR(1)			NOT NULL
		, [TargetRow]					TINYINT			NOT NULL
		, [TargetField]					TINYINT			NOT NULL
		, [Direction]					CHAR(2)			NOT NULL
		, [IsActionCapture]				BIT				NOT NULL
		, [IsActionEnPassant]			BIT				NOT NULL
		, [IsActionCastlingKingsside]	BIT				NOT NULL
		, [IsActionCastlingQueensside]	BIT				NOT NULL
		, [TransformationFigureLetter]	CHAR(1)			NULL
		, [LongNotation]				VARCHAR(20)		NULL
		, [ShortNotationSimple]			VARCHAR(8)		NULL
		, [ShortNotationComplex]		VARCHAR(8)		NULL
	) AS
	BEGIN
		INSERT INTO @PossibleActionsKnight
		(
			  [TheoreticalActionID]
			, [FigureLetter]
			, [IsPlayerWhite]
			, [StartColumn]
			, [StartRow]
			, [StartField]
			, [TargetColumn]
			, [TargetRow]
			, [TargetField]
			, [Direction]
			, [IsActionCapture]
			, [IsActionEnPassant]
			, [IsActionCastlingKingsside]
			, [IsActionCastlingQueensside]
			, [TransformationFigureLetter]
			, [LongNotation]
			, [ShortNotationSimple]
			, [ShortNotationComplex]
		)
	SELECT DISTINCT
		  [MZU].[TheoreticalActionID]					AS [TheoreticalActionID]
		, [MZU].[FigureLetter]							AS [FigureLetter]			
		, [MZU].[IsPlayerWhite]							AS [IsPlayerWhite]
		, [MZU].[StartColumn]							AS [StartColumn]
		, [MZU].[StartRow]								AS [StartRow]
		, [MZU].[StartField]							AS [StartField]
		, [MZU].[TargetColumn]							AS [TargetColumn]
		, [MZU].[TargetRow]								AS [TargetRow]
		, [MZU].[TargetField]							AS [TargetField]
		, [MZU].[Direction]								AS [Direction]
		, [MZU].[IsActionCapture]						AS [IsActionCapture]
		, [MZU].[IsActionEnPassant]						AS [IsActionEnPassant]
		, [MZU].[IsActionCastlingKingsside]				AS [IsActionCastlingKingsside]
		, [MZU].[IsActionCastlingQueensside]			AS [IsActionCastlingQueensside]
		, NULL											AS [TransformationFigureLetter]
		, [LongNotation]								AS [LongNotation]
		, [ShortNotationSimple]							AS [ShortNotationSimple]
		, [ShortNotationComplex]						AS [ShortNotationComplex]
	FROM [Infrastructure].[TheoreticalAction]			AS [MZU] 
	INNER JOIN @AssessmentPosition						AS [SPB]
		ON 1 = 1
			AND [MZU].[TargetRow]				= [SPB].[Row]
			AND [MZU].[TargetColumn]				= [SPB].[Column]
	WHERE 1 = 1
		AND [MZU].[IsPlayerWhite]				= @IsPlayerWhite
		AND [MZU].[FigureLetter]					= 'N'
		AND [MZU].[StartField]					= @ActiveField
		AND 
			(	-- move
				(
					[SPB].[FigureUTF8]				= 160
				AND
					[MZU].[IsActionCapture]			= 'FALSE'
				)
			OR	-- capture
				(
					-- capture, but not your own pieces
					[SPB].[FigureUTF8] NOT IN (SELECT [FigureUTF8] 
										FROM [Infrastructure].[Figure]  
										WHERE [IsPlayerWhite] = @IsPlayerWhite)
				AND
					[MZU].[IsActionCapture]			= 'TRUE'
				AND 
					[SPB].[FigureUTF8]				<> 160
				)
			)
	RETURN
	END
GO			



--------------------------------------------------------------------------------------------------
-- Bishop(s) -------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

CREATE OR ALTER FUNCTION [CurrentGame].[fncPossiblectionsBishop]
(
	   @IsPlayerWhite		AS BIT
	 , @AssessmentPosition	AS [dbo].[typePosition]			READONLY
	 , @ActiveField			AS INTEGER
)
-- Definition of the return table
RETURNS @MoeglicheLaeuferaktionen TABLE 
	(
		  [TheoreticalActionID]			BIGINT			NOT NULL
		, [FigureLetter]				CHAR(1)			NOT NULL
		, [IsPlayerWhite]				BIT				NOT NULL
		, [StartColumn]					CHAR(1)			NOT NULL
		, [StartRow]					TINYINT			NOT NULL
		, [StartField]					TINYINT			NOT NULL
		, [TargetColumn]				CHAR(1)			NOT NULL
		, [TargetRow]					TINYINT			NOT NULL
		, [TargetField]					TINYINT			NOT NULL
		, [Direction]					CHAR(2)			NOT NULL
		, [IsActionCapture]				BIT				NOT NULL
		, [IsActionEnPassant]			BIT				NOT NULL
		, [IsActionCastlingKingsside]	BIT				NOT NULL
		, [IsActionCastlingQueensside]	BIT				NOT NULL
		, [TransformationFigureLetter]	NVARCHAR(20)	NULL
		, [LongNotation]				VARCHAR(20)		NULL
		, [ShortNotationSimple]			VARCHAR(8)		NULL
		, [ShortNotationComplex]		VARCHAR(8)		NULL
	) AS
	BEGIN

		INSERT INTO @MoeglicheLaeuferaktionen
		(
			  [TheoreticalActionID]
			, [FigureLetter]
			, [IsPlayerWhite]
			, [StartColumn]
			, [StartRow]
			, [StartField]
			, [TargetColumn]
			, [TargetRow]
			, [TargetField]
			, [Direction]
			, [IsActionCapture]
			, [IsActionEnPassant]
			, [IsActionCastlingKingsside]
			, [IsActionCastlingQueensside]
			, [TransformationFigureLetter]
			, [LongNotation]
			, [ShortNotationSimple]
			, [ShortNotationComplex]
		)
	-- Compile the appropriate values
	SELECT 
		  [MZU].[TheoreticalActionID]					AS [TheoreticalActionID]
		, [MZU].[FigureLetter]							AS [FigureLetter]			
		, [MZU].[IsPlayerWhite]							AS [IsPlayerWhite]	
		, [MZU].[StartColumn]							AS [StartColumn]
		, [MZU].[StartRow]								AS [StartRow]
		, [MZU].[StartField]							AS [StartField]
		, [MZU].[TargetColumn]							AS [TargetColumn]
		, [MZU].[TargetRow]								AS [TargetRow]
		, [MZU].[TargetField]							AS [TargetField]
		, [MZU].[Direction]								AS [Direction]
		, [MZU].[IsActionCapture]						AS [IsActionCapture]
		, [MZU].[IsActionEnPassant]						AS [IsActionEnPassant]
		, [MZU].[IsActionCastlingKingsside]				AS [IsActionCastlingKingsside]
		, [MZU].[IsActionCastlingQueensside]			AS [IsActionCastlingQueensside]
		, NULL											AS [TransformationFigureLetter]
		, [LongNotation]								AS [LongNotation]
		, [ShortNotationSimple]							AS [ShortNotationSimple]
		, [ShortNotationComplex]						AS [ShortNotationComplex]
	FROM  [Infrastructure].[TheoreticalAction]			AS [MZU] 
	INNER JOIN @AssessmentPosition						AS [SPB]
		ON 1 = 1
			AND [MZU].[TargetRow]				= [SPB].[Row]
			AND [MZU].[TargetColumn]			= [SPB].[Column]
	WHERE 1 = 1
		AND [MZU].[IsPlayerWhite]				= @IsPlayerWhite
		AND [MZU].[FigureLetter]					= 'B'
		AND [MZU].[StartField]					= @ActiveField
		AND 
			(
				([SPB].[FigureUTF8] = 160	AND [MZU].[IsActionCapture] = 'FALSE')
				OR
				([SPB].[FigureUTF8] <> 160	AND [MZU].[IsActionCapture] = 'TRUE')
			)
		AND 
					-- capture, but not your own pieces
					[SPB].[FigureUTF8] NOT IN (SELECT [FigureUTF8] 
										FROM [Infrastructure].[Figure]  
										WHERE [IsPlayerWhite] = @IsPlayerWhite)
		AND 
			(
				[MZU].[TargetField] IN 
					-- top left as seen from the bishop
					(
						SELECT DISTINCT [TA].[TargetField]
						FROM [Infrastructure].[TheoreticalAction] AS [TA]
						WHERE 1 = 1
							AND [TA].[Direction]		= 'LU'
							AND [TA].[StartField]		=  [MZU].[StartField]
							AND [TA].[FigureLetter]		= 'B'
							AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
							AND [TA].[TargetRow]		<=
								ISNULL((
									SELECT MIN([TargetRow])
									FROM [Infrastructure].[TheoreticalAction]		AS [TA]
									LEFT JOIN @AssessmentPosition					AS [ISB]
										ON [TA].[TargetField] = [ISB].[Field]
									WHERE 1 = 1
										AND [TA].[Direction]		= 'LU'
										AND [TA].[StartField]		=  [MZU].[StartField]
										AND [TA].[FigureLetter]		= 'B'
										AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
										AND [ISB].[FigureUTF8]		<> 160
										), 8)
							AND [TA].[IsActionCapture]		= CASE 
																WHEN (
																		SELECT [INB].[FigureUTF8] 
																		FROM @AssessmentPosition AS [INB]
																		WHERE [INB].[Field] = [TA].[TargetField]
																	) <> 160
																THEN 'TRUE'
																ELSE 'FALSE'
															END

					)

				OR --down left as seen from the bishop

				[MZU].[TargetField] IN 
					(
						SELECT DISTINCT [TA].[TargetField]
						FROM [Infrastructure].[TheoreticalAction] AS [TA]
						WHERE 1 = 1
							AND [TA].[Direction]		= 'LD'
							AND [TA].[StartField]		=  [MZU].[StartField]
							AND [TA].[FigureLetter]		= 'B'
							AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
							AND [TA].[TargetRow]		>=
								ISNULL((
									SELECT MAX([TargetRow])
									FROM [Infrastructure].[TheoreticalAction]		AS [TA]
									LEFT JOIN @AssessmentPosition					AS [ISB]
										ON [TA].[TargetField] = [ISB].[Field]
									WHERE 1 = 1
										AND [TA].[Direction]		= 'LD'
										AND [TA].[StartField]		=  [MZU].[StartField]
										AND [TA].[FigureLetter]		= 'B'
										AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
										AND [ISB].[FigureUTF8]		<> 160
										), 1)
							AND [TA].[IsActionCapture]		= CASE 
																WHEN (
																		SELECT [INB].[FigureUTF8] 
																		FROM @AssessmentPosition AS [INB]
																		WHERE [INB].[Field] = [TA].[TargetField]
																	) <> 160
																THEN 'TRUE'
																ELSE 'FALSE'
															END
					)

				OR -- down right as seen from the bishop

				[MZU].[TargetField] IN 
					(
						SELECT DISTINCT [TA].[TargetField]
						FROM [Infrastructure].[TheoreticalAction] AS [TA]
						WHERE 1 = 1
							AND [TA].[Direction]		= 'RD'
							AND [TA].[StartField]		=  [MZU].[StartField]
							AND [TA].[FigureLetter]		= 'B'
							AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
							AND [TA].[TargetRow]		>=
								ISNULL((
									SELECT MAX([TargetRow])
									FROM [Infrastructure].[TheoreticalAction]		AS [TA]
									LEFT JOIN @AssessmentPosition					AS [ISB]
										ON [TA].[TargetField] = [ISB].[Field]
									WHERE 1 = 1
										AND [TA].[Direction]		= 'RD'
										AND [TA].[StartField]		=  [MZU].[StartField]
										AND [TA].[FigureLetter]		= 'B'
										AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
										AND [ISB].[FigureUTF8]		<> 160
										), 1)
							AND [TA].[IsActionCapture]		= CASE 
																WHEN (
																		SELECT [INB].[FigureUTF8] 
																		FROM @AssessmentPosition AS [INB]
																		WHERE [INB].[Field] = [TA].[TargetField]
																	) <> 160
																THEN 'TRUE'
																ELSE 'FALSE'
															END
					)

				OR -- top right as seen from the bishop

				[MZU].[TargetField] IN 
					(
						SELECT DISTINCT [TA].[TargetField]
						FROM [Infrastructure].[TheoreticalAction] AS [TA]
						WHERE 1 = 1
							AND [TA].[Direction]		= 'RU'
							AND [TA].[StartField]		=  [MZU].[StartField]
							AND [TA].[FigureLetter]		= 'B'
							AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
							AND [TA].[TargetRow]		<=
								ISNULL((
									SELECT MIN([TargetRow])
									FROM [Infrastructure].[TheoreticalAction]		AS [TA]
									LEFT JOIN @AssessmentPosition					AS [ISB]
										ON [TA].[TargetField] = [ISB].[Field]
									WHERE 1 = 1
										AND [TA].[Direction]		= 'RU'
										AND [TA].[StartField]		=  [MZU].[StartField]
										AND [TA].[FigureLetter]		= 'B'
										AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
										AND [ISB].[FigureUTF8]		<> 160
										), 8)
							AND [TA].[IsActionCapture]		= CASE 
																WHEN (
																		SELECT [INB].[FigureUTF8] 
																		FROM @AssessmentPosition AS [INB]
																		WHERE [INB].[Field] = [TA].[TargetField]
																	) <> 160
																THEN 'TRUE'
																ELSE 'FALSE'
															END
					)
			)
	RETURN
	END
GO			




--------------------------------------------------------------------------------------------------
-- Queen(s) ---------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

CREATE OR ALTER FUNCTION [CurrentGame].[fncPossibleActionsQueen]
(
	   @IsPlayerWhite		AS BIT
	 , @AssessmentPosition	AS [dbo].[typePosition]			READONLY
	 , @ActiveField			AS INTEGER
)
RETURNS @PossibleActionsQueen TABLE 
	(
		  [TheoreticalActionID]			BIGINT			NOT NULL
		, [FigureLetter]				CHAR(1)			NOT NULL
		, [IsPlayerWhite]				BIT				NOT NULL
		, [StartColumn]					CHAR(1)			NOT NULL
		, [StartRow]					TINYINT			NOT NULL
		, [StartField]					TINYINT			NOT NULL
		, [TargetColumn]				CHAR(1)			NOT NULL
		, [TargetRow]					TINYINT			NOT NULL
		, [TargetField]					TINYINT			NOT NULL
		, [Direction]					CHAR(2)			NOT NULL
		, [IsActionCapture]				BIT				NOT NULL
		, [IsActionEnPassant]			BIT				NOT NULL
		, [IsActionCastlingKingsside]	BIT				NOT NULL
		, [IsActionCastlingQueensside]	BIT				NOT NULL
		, [TransformationFigureLetter]	NVARCHAR(20)	NULL
		, [LongNotation]				VARCHAR(20)		NULL
		, [ShortNotationSimple]			VARCHAR(8)		NULL
		, [ShortNotationComplex]		VARCHAR(8)		NULL
	) AS
	BEGIN
		INSERT INTO @PossibleActionsQueen
		(
			  [TheoreticalActionID]
			, [FigureLetter]
			, [IsPlayerWhite]	
			, [StartColumn]
			, [StartRow]
			, [StartField]
			, [TargetColumn]
			, [TargetRow]
			, [TargetField]
			, [Direction]
			, [IsActionCapture]
			, [IsActionEnPassant]
			, [IsActionCastlingKingsside]
			, [IsActionCastlingQueensside]
			, [TransformationFigureLetter]
			, [LongNotation]
			, [ShortNotationSimple]
			, [ShortNotationComplex]
		)
	SELECT 
		  [MZU].[TheoreticalActionID]					AS [TheoreticalActionID]
		, [MZU].[FigureLetter]							AS [FigureLetter]			
		, [MZU].[IsPlayerWhite]							AS [IsPlayerWhite]
		, [MZU].[StartColumn]							AS [StartColumn]
		, [MZU].[StartRow]								AS [StartRow]
		, [MZU].[StartField]							AS [StartField]
		, [MZU].[TargetColumn]							AS [TargetColumn]
		, [MZU].[TargetRow]								AS [TargetRow]
		, [MZU].[TargetField]							AS [TargetField]
		, [MZU].[Direction]								AS [Direction]
		, [MZU].[IsActionCapture]						AS [IsActionCapture]
		, [MZU].[IsActionEnPassant]						AS [IsActionEnPassant]
		, [MZU].[IsActionCastlingKingsside]				AS [IsActionCastlingKingsside]
		, [MZU].[IsActionCastlingQueensside]			AS [IsActionCastlingQueensside]
		, NULL											AS [TransformationFigureLetter]
		, [LongNotation]								AS [LongNotation]
		, [ShortNotationSimple]							AS [ShortNotationSimple]
		, [ShortNotationComplex]						AS [ShortNotationComplex]
	FROM [Infrastructure].[TheoreticalAction]			AS [MZU] 
	INNER JOIN @AssessmentPosition						AS [SPB]
		ON 1 = 1
			AND [MZU].[TargetRow]				= [SPB].[Row]
			AND [MZU].[TargetColumn]			= [SPB].[Column]
	WHERE 1 = 1
		AND [MZU].[IsPlayerWhite]				= @IsPlayerWhite
		AND [MZU].[FigureLetter]				= 'Q'
		AND [MZU].[StartField]					= @ActiveField
		AND 
			(
				([SPB].[FigureUTF8] = 160		AND [MZU].[IsActionCapture] = 'FALSE')
				OR
				([SPB].[FigureUTF8] <> 160		AND [MZU].[IsActionCapture] = 'TRUE')
			)
		AND
			-- capture, but not your own pieces
			[SPB].[FigureUTF8] NOT IN (SELECT [FigureUTF8] 
								FROM [Infrastructure].[Figure]  
								WHERE [IsPlayerWhite] = @IsPlayerWhite)
		AND 
			(
				[MZU].[TargetField] IN 
					(
						SELECT DISTINCT [TA].[TargetField]
						FROM [Infrastructure].[TheoreticalAction] AS [TA]
						WHERE 1 = 1
							AND [TA].[Direction]		= 'LU'
							AND [TA].[StartField]		=  [MZU].[StartField]
							AND [TA].[FigureLetter]		= 'Q'
							AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
							AND [TA].[TargetRow]		<=
								ISNULL((
									SELECT MIN([TargetRow])
									FROM [Infrastructure].[TheoreticalAction]		AS [TA]
									LEFT JOIN @AssessmentPosition					AS [ISB]
										ON [TA].[TargetField] = [ISB].[Field]
									WHERE 1 = 1
										AND [TA].[Direction]		= 'LU'
										AND [TA].[StartField]		=  [MZU].[StartField]
										AND [TA].[FigureLetter]		= 'Q'
										AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
										AND [ISB].[FigureUTF8]		<> 160
										), 8)
							AND [TA].[IsActionCapture]		= CASE 
																WHEN (
																		SELECT [INB].[FigureUTF8] 
																		FROM @AssessmentPosition AS [INB]
																		WHERE [INB].[Field] = [TA].[TargetField]
																	) <> 160
																THEN 'TRUE'
																ELSE 'FALSE'
															END
					)

				OR

				[MZU].[TargetField] IN 
					(
						SELECT DISTINCT [TA].[TargetField]
						FROM [Infrastructure].[TheoreticalAction] AS [TA]
						WHERE 1 = 1
							AND [TA].[Direction]		= 'LD'
							AND [TA].[StartField]		=  [MZU].[StartField]
							AND [TA].[FigureLetter]		= 'Q'
							AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
							AND [TA].[TargetRow]		>=
								ISNULL((
									SELECT MAX([TargetRow])
									FROM [Infrastructure].[TheoreticalAction]		AS [TA]
									LEFT JOIN @AssessmentPosition					AS [ISB]
										ON [TA].[TargetField] = [ISB].[Field]
									WHERE 1 = 1
										AND [TA].[Direction]		= 'LD'
										AND [TA].[StartField]		=  [MZU].[StartField]
										AND [TA].[FigureLetter]		= 'Q'
										AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
										AND [ISB].[FigureUTF8]		<> 160
										), 1)
							AND [TA].[IsActionCapture]		= CASE 
																WHEN (
																		SELECT [INB].[FigureUTF8] 
																		FROM @AssessmentPosition AS [INB]
																		WHERE [INB].[Field] = [TA].[TargetField]
																	) <> 160
																THEN 'TRUE'
																ELSE 'FALSE'
															END
					)

				OR

				[MZU].[TargetField] IN 
					(
						SELECT DISTINCT [TA].[TargetField]
						FROM [Infrastructure].[TheoreticalAction] AS [TA]
						WHERE 1 = 1
							AND [TA].[Direction]		= 'RD'
							AND [TA].[StartField]		=  [MZU].[StartField]
							AND [TA].[FigureLetter]		= 'Q'
							AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
							AND [TA].[TargetRow]		>=
								ISNULL((
									SELECT MAX([TargetRow])
									FROM [Infrastructure].[TheoreticalAction]		AS [TA]
									LEFT JOIN @AssessmentPosition					AS [ISB]
										ON [TA].[TargetField] = [ISB].[Field]
									WHERE 1 = 1
										AND [TA].[Direction]		= 'RD'
										AND [TA].[StartField]		=  [MZU].[StartField]
										AND [TA].[FigureLetter]		= 'Q'
										AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
										AND [ISB].[FigureUTF8]		<> 160
										), 1)
							AND [TA].[IsActionCapture]		= CASE 
																WHEN (
																		SELECT [INB].[FigureUTF8] 
																		FROM @AssessmentPosition AS [INB]
																		WHERE [INB].[Field] = [TA].[TargetField]
																	) <> 160
																THEN 'TRUE'
																ELSE 'FALSE'
															END
					)

				OR

				[MZU].[TargetField] IN 
					(
						SELECT DISTINCT [TA].[TargetField]
						FROM [Infrastructure].[TheoreticalAction] AS [TA]
						WHERE 1 = 1
							AND [TA].[Direction]		= 'RU'
							AND [TA].[StartField]		=  [MZU].[StartField]
							AND [TA].[FigureLetter]		= 'Q'
							AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
							AND [TA].[TargetRow]		<=
								ISNULL((
									SELECT MIN([TargetRow])
									FROM [Infrastructure].[TheoreticalAction]		AS [TAI]
									LEFT JOIN @AssessmentPosition					AS [ISB]
										ON [TAI].[TargetField] = [ISB].[Field]
									WHERE 1 = 1
										AND [TAI].[Direction]		= 'RU'
										AND [TAI].[StartField]		=  [MZU].[StartField]
										AND [TAI].[FigureLetter]	= 'Q'
										AND [TAI].[IsPlayerWhite]	= @IsPlayerWhite
										AND [ISB].[FigureUTF8]		<> 160
										), 8)
							AND [TA].[IsActionCapture]		= CASE 
																WHEN (
																		SELECT [INB].[FigureUTF8] 
																		FROM @AssessmentPosition AS [INB]
																		WHERE [INB].[Field] = [TA].[TargetField]
																	) <> 160
																THEN 'TRUE'
																ELSE 'FALSE'
															END
					)

				OR

				[MZU].[TargetField] IN 
					(
						SELECT DISTINCT [TA].[TargetField]
						FROM [Infrastructure].[TheoreticalAction] AS [TA]
						WHERE 1 = 1
							AND [TA].[Direction]		= 'DO'
							AND [TA].[StartField]		=  [MZU].[StartField]
							AND [TA].[FigureLetter]		= 'Q'
							AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
							AND [TA].[TargetRow]		>=
								ISNULL((
									SELECT MAX([TargetRow])
									FROM [Infrastructure].[TheoreticalAction]		AS [TA]
									LEFT JOIN @AssessmentPosition					AS [ISB]
										ON [TA].[TargetField] = [ISB].[Field]
									WHERE 1 = 1
										AND [TA].[Direction]		= 'DO'
										AND [TA].[StartField]		=  [MZU].[StartField]
										AND [TA].[FigureLetter]		= 'Q'
										AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
										AND [ISB].[FigureUTF8]		<> 160
										), 1)
					)

				OR

				[MZU].[TargetField] IN 
					(
						SELECT DISTINCT [TA].[TargetField]
						FROM [Infrastructure].[TheoreticalAction] AS [TA]
						WHERE 1 = 1
							AND [TA].[Direction]		= 'UP'
							AND [TA].[StartField]		=  [MZU].[StartField]
							AND [TA].[FigureLetter]		= 'Q'
							AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
							AND [TA].[TargetRow]		<=
								ISNULL((
									SELECT MIN([TargetRow])
									FROM [Infrastructure].[TheoreticalAction]		AS [TA]
									LEFT JOIN @AssessmentPosition					AS [ISB]
										ON [TA].[TargetField] = [ISB].[Field]
									WHERE 1 = 1
										AND [TA].[Direction]		= 'UP'
										AND [TA].[StartField]		=  [MZU].[StartField]
										AND [TA].[FigureLetter]		= 'Q'
										AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
										AND [ISB].[FigureUTF8]		<> 160
										), 8)
					)		

				OR

				[MZU].[TargetField] IN 
					(
						SELECT DISTINCT [TA].[TargetField]
						FROM [Infrastructure].[TheoreticalAction] AS [TA]
						WHERE 1 = 1
							AND [TA].[Direction]		= 'RI'
							AND [TA].[StartField]		=  [MZU].[StartField]
							AND [TA].[FigureLetter]		= 'Q'
							AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
							AND [TA].[TargetColumn]		<=
								ISNULL((
									SELECT MIN([TargetColumn])
									FROM [Infrastructure].[TheoreticalAction]		AS [TA]
									LEFT JOIN @AssessmentPosition					AS [ISB]
										ON [TA].[TargetField] = [ISB].[Field]
									WHERE 1 = 1
										AND [TA].[Direction]		= 'RI'
										AND [TA].[StartField]		=  [MZU].[StartField]
										AND [TA].[FigureLetter]		= 'Q'
										AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
										AND [ISB].[FigureUTF8]		<> 160
										), 'H')
					)		

				OR

				[MZU].[TargetField] IN 
					(
						SELECT DISTINCT [TA].[TargetField]
						FROM [Infrastructure].[TheoreticalAction] AS [TA]
						WHERE 1 = 1
							AND [TA].[Direction]		= 'LE'
							AND [TA].[StartField]		=  [MZU].[StartField]
							AND [TA].[FigureLetter]		= 'Q'
							AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
							AND [TA].[TargetColumn]		>=
								ISNULL((
									SELECT MAX([TargetColumn])
									FROM [Infrastructure].[TheoreticalAction]		AS [TA]
									LEFT JOIN @AssessmentPosition					AS [ISB]
										ON [TA].[TargetField] = [ISB].[Field]
									WHERE 1 = 1
										AND [TA].[Direction]		= 'LE'
										AND [TA].[StartField]		=  [MZU].[StartField]
										AND [TA].[FigureLetter]		= 'Q'
										AND [TA].[IsPlayerWhite]	= @IsPlayerWhite
										AND [ISB].[FigureUTF8]		<> 160
										), 'A')
					)	
			)
	RETURN
	END
GO			





--------------------------------------------------------------------------------------------------
-- King ------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

CREATE OR ALTER FUNCTION [CurrentGame].[fncPossibibleActionsKing]
(
	   @IsPlayerWhite		AS BIT
	 , @AssessmentPosition	AS [dbo].[typePosition]			READONLY
	 , @ActiveField			AS INTEGER
)
RETURNS @PossibleActionsKing TABLE 
	(
		  [TheoreticalActionID]			BIGINT			NOT NULL
		, [FigureLetter]				CHAR(1)			NOT NULL
		, [IsPlayerWhite]				BIT				NOT NULL
		, [StartColumn]					CHAR(1)			NOT NULL
		, [StartRow]					TINYINT			NOT NULL
		, [StartField]					TINYINT			NOT NULL
		, [TargetColumn]				CHAR(1)			NOT NULL
		, [TargetRow]					TINYINT			NOT NULL
		, [TargetField]					TINYINT			NOT NULL
		, [Direction]					CHAR(2)			NOT NULL
		, [IsActionCapture]				BIT				NOT NULL
		, [IsActionEnPassant]			BIT				NOT NULL
		, [IsActionCastlingKingsside]	BIT				NOT NULL
		, [IsActionCastlingQueensside]	BIT				NOT NULL
		, [TransformationFigureLetter]	NVARCHAR(20)	NULL
		, [LongNotation]				VARCHAR(20)		NULL
		, [ShortNotationSimple]			VARCHAR(8)		NULL
		, [ShortNotationComplex]		VARCHAR(8)		NULL
	) AS
	BEGIN
		INSERT INTO @PossibleActionsKing
		(
			  [TheoreticalActionID]
			, [FigureLetter]
			, [IsPlayerWhite]	
			, [StartColumn]
			, [StartRow]
			, [StartField]
			, [TargetColumn]
			, [TargetRow]
			, [TargetField]
			, [Direction]
			, [IsActionCapture]
			, [IsActionEnPassant]
			, [IsActionCastlingKingsside]
			, [IsActionCastlingQueensside]
			, [TransformationFigureLetter]
			, [LongNotation]
			, [ShortNotationSimple]
			, [ShortNotationComplex]
		)
	SELECT 
		  [MZU].[TheoreticalActionID]					AS [TheoreticalActionID]
		, [MZU].[FigureLetter]							AS [FigureLetter]			
		, [MZU].[IsPlayerWhite]							AS [IsPlayerWhite]	
		, [MZU].[StartColumn]							AS [StartColumn]
		, [MZU].[StartRow]								AS [StartRow]
		, [MZU].[StartField]							AS [StartField]
		, [MZU].[TargetColumn]							AS [TargetColumn]
		, [MZU].[TargetRow]								AS [TargetRow]
		, [MZU].[TargetField]							AS [TargetField]
		, [MZU].[Direction]								AS [Direction]
		, [MZU].[IsActionCapture]						AS [IsActionCapture]
		, [MZU].[IsActionEnPassant]						AS [IsActionEnPassant]
		, [MZU].[IsActionCastlingKingsside]				AS [IsActionCastlingKingsside]
		, [MZU].[IsActionCastlingQueensside]			AS [IsActionCastlingQueensside]
		, NULL											AS [TransformationFigureLetter]
		, [LongNotation]								AS [LongNotation]
		, [ShortNotationSimple]							AS [ShortNotationSimple]
		, [ShortNotationComplex]						AS [ShortNotationComplex]
	FROM [Infrastructure].[TheoreticalAction]			AS [MZU] 
	INNER JOIN @AssessmentPosition						AS [SPB]
		ON 1 = 1
			AND [MZU].[TargetRow]				= [SPB].[Row]
			AND [MZU].[TargetColumn]			= [SPB].[Column]
	WHERE 1 = 1
		AND [MZU].[IsPlayerWhite]				= @IsPlayerWhite
		AND [MZU].[FigureLetter]				= 'K'
		AND [MZU].[StartField]					= @ActiveField
		AND 
			(
				([SPB].[FigureUTF8] = 160	AND [MZU].[IsActionCapture] = 'FALSE')
				OR
				([SPB].[FigureUTF8] <> 160	AND [MZU].[IsActionCapture] = 'TRUE')
			)
		AND 
					-- capture, but not your own pieces
					[SPB].[FigureUTF8] NOT IN (SELECT [FigureUTF8] 
										FROM [Infrastructure].[Figure]  
										WHERE [IsPlayerWhite] = @IsPlayerWhite)
	RETURN
	END
GO			



--------------------------------------------------------------------------------------------------
-- Pawn(s) ---------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

CREATE OR ALTER FUNCTION [CurrentGame].[fncPossibleActionsPawn]
(
	   @IsPlayerWhite		AS BIT
	 , @AssessmentPosition	AS [dbo].[typePosition]			READONLY
	 , @ActiveField			AS INTEGER
)
RETURNS @PossibleActionsPawn TABLE 
	(
		  [TheoreticalActionID]			BIGINT			NOT NULL
		, [FigureLetter]				CHAR(1)			NOT NULL
		, [IsPlayerWhite]				BIT				NOT NULL
		, [StartColumn]					CHAR(1)			NOT NULL
		, [StartRow]					TINYINT			NOT NULL
		, [StartField]					TINYINT			NOT NULL
		, [TargetColumn]				CHAR(1)			NOT NULL
		, [TargetRow]					TINYINT			NOT NULL
		, [TargetField]					TINYINT			NOT NULL
		, [Direction]					CHAR(2)			NOT NULL
		, [IsActionCapture]				BIT				NOT NULL
		, [IsActionEnPassant]			BIT				NOT NULL
		, [IsActionCastlingKingsside]	BIT				NOT NULL
		, [IsActionCastlingQueensside]	BIT				NOT NULL
		, [TransformationFigureLetter]	NVARCHAR(20)	NULL
		, [LongNotation]				VARCHAR(11)		NULL
		, [ShortNotationSimple]			VARCHAR(8)		NULL
		, [ShortNotationComplex]		VARCHAR(8)		NULL
	) AS
	BEGIN
		INSERT INTO @PossibleActionsPawn
		(
			  [TheoreticalActionID]
			, [FigureLetter]
			, [IsPlayerWhite]
			, [StartColumn]
			, [StartRow]
			, [StartField]
			, [TargetColumn]
			, [TargetRow]
			, [TargetField]
			, [Direction]
			, [IsActionCapture]
			, [IsActionEnPassant]
			, [IsActionCastlingKingsside]
			, [IsActionCastlingQueensside]
			, [TransformationFigureLetter]
			, [LongNotation]
			, [ShortNotationSimple]
			, [ShortNotationComplex]
		)
	SELECT DISTINCT
		  [MZU].[TheoreticalActionID]					AS [TheoreticalActionID]
		, [MZU].[FigureLetter]							AS [FigureLetter]			
		, [MZU].[IsPlayerWhite]							AS [IsPlayerWhite]	
		, [MZU].[StartColumn]							AS [StartColumn]
		, [MZU].[StartRow]								AS [StartRow]
		, [MZU].[StartField]							AS [StartField]
		, [MZU].[TargetColumn]							AS [TargetColumn]
		, [MZU].[TargetRow]								AS [TargetRow]
		, [MZU].[TargetField]							AS [TargetField]
		, [MZU].[Direction]								AS [Direction]
		, [MZU].[IsActionCapture]						AS [IsActionCapture]
		, [MZU].[IsActionEnPassant]						AS [IsActionEnPassant]
		, [MZU].[IsActionCastlingKingsside]				AS [IsActionCastlingKingsside]
		, [MZU].[IsActionCastlingQueensside]			AS [IsActionCastlingQueensside]
		, [MZU].[TransformationFigureLetter]			AS [TransformationFigureLetter]
		, [LongNotation]								AS [LongNotation]
		, [ShortNotationSimple]							AS [ShortNotationSimple]
		, [ShortNotationComplex]						AS [ShortNotationComplex]
	FROM [Infrastructure].[TheoreticalAction]			AS [MZU] 
	INNER JOIN @AssessmentPosition						AS [SPB]
		ON 1 = 1
			AND [MZU].[TargetRow]				= [SPB].[Row]
			AND [MZU].[TargetColumn]			= [SPB].[Column]
	WHERE 1 = 1
		AND [MZU].[IsPlayerWhite]				= @IsPlayerWhite
		AND [MZU].[FigureLetter]				= 'P'
		AND [MZU].[StartField]					= @ActiveField
		AND 
			(
				(									-- normal move
					    [SPB].[FigureUTF8]		= 160	
					AND [MZU].[IsActionCapture]	= 'FALSE'
					AND 
						(							-- in the case of a double move, the intermediate field 
													-- must be empty
							SELECT [BS].[FigureUTF8]
							FROM @AssessmentPosition		AS [BS]
							WHERE 1 = 1
								AND (
										(			-- WHITE moves upwards
											[BS].[Field] = [MZU].[StartField] + 1
											AND
											@IsPlayerWhite	= 'TRUE'
										)
										OR 
										(			-- BLACK moves downwards
											[BS].[Field] = [MZU].[StartField] - 1
											AND
											@IsPlayerWhite	= 'FALSE'
										)
									)
						) = 160
				)
				
				OR
				
				(
					    [SPB].[FigureUTF8]		<> 160	
					AND [MZU].[IsActionCapture]	= 'TRUE'
					AND 
						-- capture, but not your own pieces
						[SPB].[FigureUTF8] NOT IN (SELECT [FigureUTF8] 
											FROM [Infrastructure].[Figure]  
											WHERE [IsPlayerWhite] = @IsPlayerWhite)
				)
			)

	UNION
	
	-- Special area for the "en passant" case
		SELECT DISTINCT
		  [MZU].[TheoreticalActionID]					AS [TheoreticalActionID]
		, [MZU].[FigureLetter]							AS [FigureLetter]			
		, [MZU].[IsPlayerWhite]							AS [IsPlayerWhite]	
		, [MZU].[StartColumn]							AS [StartColumn]
		, [MZU].[StartRow]								AS [StartRow]
		, [MZU].[StartField]							AS [StartField]
		, [MZU].[TargetColumn]							AS [TargetColumn]
		, [MZU].[TargetRow]								AS [TargetRow]
		, [MZU].[TargetField]							AS [TargetField]
		, [MZU].[Direction]								AS [Direction]
		, [MZU].[IsActionCapture]						AS [IsActionCapture]
		, [MZU].[IsActionEnPassant]						AS [IsActionEnPassant]
		, [MZU].[IsActionCastlingKingsside]				AS [IsActionCastlingKingsside]
		, [MZU].[IsActionCastlingQueensside]			AS [IsActionCastlingQueensside]
		, [MZU].[TransformationFigureLetter]			AS [TransformationFigureLetter]
		, LEFT([MZU].[LongNotation], 11)				AS [LongNotation]
		, [MZU].[ShortNotationSimple]					AS [ShortNotationSimple]
		, [MZU].[ShortNotationComplex]					AS [ShortNotationComplex]
	FROM [Infrastructure].[TheoreticalAction]			AS [MZU] 
	INNER JOIN @AssessmentPosition						AS [SPB]
		ON 1 = 1
			AND [MZU].[TargetRow]				= [SPB].[Row]
			AND [MZU].[TargetColumn]			= [SPB].[Column]
	WHERE 1 = 1
		AND [MZU].[IsActionEnPassant]			= 'TRUE'
		AND [MZU].[IsPlayerWhite]				= @IsPlayerWhite
		AND (
				(
					[MZU].[IsPlayerWhite]		= 'TRUE'
					AND [MZU].[StartRow]		= 5
					AND (EXISTS (SELECT * FROM @AssessmentPosition AS [Inside] WHERE 1 = 1
									AND ASCII([SPB].[Column])		= ASCII([Inside].[Column]) + 1
									AND [Inside].[Row]				= 5
									AND [Inside].[FigureLetter]		= 'B'
									AND [Inside].[IsPlayerWhite]	= @IsPlayerWhite
								)
						)
					AND (EXISTS (SELECT * FROM [CurrentGame].[Notation] AS [Inside] WHERE 1 = 1
									AND SUBSTRING([Inside].[LongNotation], 2, 1)	= '7'
									AND SUBSTRING([Inside].[LongNotation], 5, 1)	= '5'
									AND [Inside].[IsPlayerWhite]					= ((@IsPlayerWhite + 1) % 2)
									AND [Inside].[MoveID]							= (SELECT MAX([MoveID]) FROM [CurrentGame].[Notation] WHERE [IsPlayerWhite] = ((@IsPlayerWhite + 1) % 2))
								)
						)
				)
				OR
				(
					[MZU].[IsPlayerWhite]			= 'TRUE'
					AND [MZU].[StartRow]			= 5
					AND (EXISTS (SELECT * FROM @AssessmentPosition AS [Inside] WHERE 1 = 1
									AND ASCII([SPB].[Column])		= ASCII([Inside].[Column]) - 1
									AND [Inside].[Row]				= 5
									AND [Inside].[FigureLetter]	= 'B'
									AND [Inside].[IsPlayerWhite]	= ((@IsPlayerWhite + 1) % 2)
								)
						)
					AND (EXISTS (SELECT * FROM [CurrentGame].[Notation] AS [Inside] WHERE 1 = 1
									AND SUBSTRING([Inside].[LongNotation], 2, 1)	= '7'
									AND SUBSTRING([Inside].[LongNotation], 5, 1)	= '5'
									AND [Inside].[IsPlayerWhite]					= ((@IsPlayerWhite + 1) % 2)
									AND [Inside].[MoveID]							= (SELECT MAX([MoveID]) FROM [CurrentGame].[Notation] WHERE [IsPlayerWhite] = ((@IsPlayerWhite + 1) % 2))
								)
						)
				)
			OR
				(
					[MZU].[IsPlayerWhite]			= 'FALSE'
					AND [MZU].[StartRow]			= 4
					AND (EXISTS (SELECT * FROM @AssessmentPosition AS [Inside] WHERE 1 = 1
									AND ASCII([SPB].[Column])		= ASCII([Inside].[Column]) + 1
									AND [Inside].[Row]				= 4
									AND [Inside].[FigureLetter]	= 'B'
									AND [Inside].[IsPlayerWhite]	= ((@IsPlayerWhite + 1) % 2)
								)
						)
					AND (EXISTS (SELECT * FROM [CurrentGame].[Notation] AS [Inside] WHERE 1 = 1
									AND SUBSTRING([Inside].[LongNotation], 2, 1)	= '2'
									AND SUBSTRING([Inside].[LongNotation], 5, 1)	= '4'
									AND [Inside].[IsPlayerWhite]					= ((@IsPlayerWhite + 1) % 2)
									AND [Inside].[MoveID]							= (SELECT MAX([MoveID]) FROM [CurrentGame].[Notation] WHERE [IsPlayerWhite] = ((@IsPlayerWhite + 1) % 2))
								)
						)
				)
				OR
				(
					[MZU].[IsPlayerWhite]			= 'FALSE'
					AND [MZU].[StartRow]			= 4
					AND (EXISTS (SELECT * FROM @AssessmentPosition AS [Inside] WHERE 1 = 1
									AND ASCII([SPB].[Column])		= ASCII([Inside].[Column]) + 1
									AND [Inside].[Row]				= 4
									AND [Inside].[FigureLetter]	= 'B'
									AND [Inside].[IsPlayerWhite]	= ((@IsPlayerWhite + 1) % 2)
								)
						)
					AND (EXISTS (SELECT * FROM [CurrentGame].[Notation] AS [Inside] WHERE 1 = 1
									AND SUBSTRING([Inside].[LongNotation], 2, 1)	= '2'
									AND SUBSTRING([Inside].[LongNotation], 5, 1)	= '4'
									AND [Inside].[IsPlayerWhite]					= ((@IsPlayerWhite + 1) % 2)
									AND [Inside].[MoveID]							= (SELECT MAX([MoveID]) FROM [CurrentGame].[Notation] WHERE [IsPlayerWhite] = ((@IsPlayerWhite + 1) % 2))
								)
						)
				)
			)				
		AND [MZU].[StartField]					= @ActiveField

	RETURN
	END
GO			




-- #################################################################################################################

-- -----------------------------------------------------------------------------------------------------------------
-- Above there is a separate procedure for each type of figure. Here they are now addressed for a complete position 
-- according to the pieces still on the board. Not only the position is transferred alone, as important information, 
-- such as the question about the still permissible castles, would be lost. Instead, the EFN string of the position 
-- is transferred, where such information is additionally coded.
-- -----------------------------------------------------------------------------------------------------------------

CREATE OR ALTER FUNCTION [CurrentGame].[fncPossibleActionsAllPieces] 
(
	   @IsPlayerWhite		AS BIT
	 , @EFN					AS VARCHAR(255)
)
RETURNS @PossibleActions TABLE	
	(
		  [TheoreticalActionID]			BIGINT			NOT NULL
		, [HalfMoveNo]					INTEGER			NOT NULL
		, [FigureLetter]				CHAR(1)			NOT NULL
		, [IsPlayerWhite]				BIT				NOT NULL
		, [StartColumn]					CHAR(1)			NOT NULL
		, [StartRow]					TINYINT			NOT NULL
		, [StartField]					TINYINT			NOT NULL
		, [TargetColumn]				CHAR(1)			NOT NULL
		, [TargetRow]					TINYINT			NOT NULL
		, [TargetField]					TINYINT			NOT NULL
		, [Direction]					CHAR(2)			NOT NULL
		, [IsActionCapture]				BIT				NOT NULL
		, [IsActionEnPassant]			BIT				NOT NULL
		, [IsActionCastlingKingsside]	BIT				NOT NULL
		, [IsActionCastlingQueensside]	BIT				NOT NULL
		, [TransformationFigureLetter]	NVARCHAR(20)	NULL
		, [LongNotation]				VARCHAR(20)		NULL
		, [ShortNotationSimple]			VARCHAR(8)		NULL
		, [ShortNotationComplex]		VARCHAR(8)		NULL
	) AS
	BEGIN

		DECLARE @FieldQueen						AS TINYINT
		DECLARE @FieldRook						AS TINYINT
		DECLARE @FieldKnight					AS TINYINT
		DECLARE @FieldBishop					AS TINYINT
		DECLARE @FieldKing						AS TINYINT
		DECLARE @FieldPawn						AS TINYINT
		--DECLARE @ChessBidPosition					AS BIGINT
		--DECLARE @PinPosition					AS BIGINT
		DECLARE @IsActionChessBid				AS BIT
		--DECLARE @BGameBoard					AS [dbo].[typePosition]
		--DECLARE @LongNotation					AS VARCHAR(20)
		DECLARE @TransformationFigureLetter		AS CHAR(1)
		--DECLARE @FieldStart						AS TINYINT
		--DECLARE @FieldTarget					AS TINYINT



		-- --------------------------------------------------------------------------
		-- Extract the position from the EFN string and assign it to a variable
		-- --------------------------------------------------------------------------

		DECLARE @AssessmentPosition				AS [dbo].[typePosition]	
		
		INSERT INTO @AssessmentPosition
			SELECT 1, 1, * FROM [Infrastructure].[fncEFN2Position](@EFN)

			
		---- --------------------------------------------------------------------------
		---- queen(s)
		---- --------------------------------------------------------------------------

		-- All queens on the board are determined. For each queen found in this way, all conceivable and 
		-- rule-compliant actions are noted. Thus, even after multiple pawn conversions, every queen 
		-- is taken into account
		DECLARE curActionQueen CURSOR FOR   
			SELECT DISTINCT [Field]
			FROM @AssessmentPosition
			WHERE 1 = 1
				AND [FigureLetter]	= 'Q'
				AND [IsPlayerWhite]	= @IsPlayerWhite
			ORDER BY [Field];  

		OPEN curActionQueen
  
		FETCH NEXT FROM curActionQueen INTO @FieldQueen
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
			INSERT INTO @PossibleActions
			(
				[TheoreticalActionID], [HalfMoveNo], [FigureLetter], [IsPlayerWhite], [StartColumn],
				[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
				[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
				[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex]
			)
			SELECT [TheoreticalActionID], 1, [FigureLetter], [IsPlayerWhite], [StartColumn],
				[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
				[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
				[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex] 
			FROM [CurrentGame].[fncPossibleActionsQueen] (@IsPlayerWhite, @AssessmentPosition, @FieldQueen)

			FETCH NEXT FROM curActionQueen INTO @FieldQueen 
		END
		CLOSE curActionQueen;  
		DEALLOCATE curActionQueen; 


		-- --------------------------------------------------------------------------
		-- rook(s)
		-- --------------------------------------------------------------------------

		-- All the rooks on the board are determined. For each rook found in this way, all conceivable and rule-compliant 
		-- actions are now noted. Thus, even after multiple pawn conversions, every rook is taken into account.		
		DECLARE curActionsRook CURSOR FOR   
			SELECT DISTINCT [Field]
			FROM @AssessmentPosition
			WHERE 1 = 1
				AND [FigureLetter]	= 'R'
				AND [IsPlayerWhite]	= @IsPlayerWhite
			ORDER BY [Field];  
  
		OPEN curActionsRook
  
		FETCH NEXT FROM curActionsRook INTO @FieldRook
  
		WHILE @@FETCH_STATUS = 0  
		BEGIN 

			INSERT INTO @PossibleActions
			(
				[TheoreticalActionID], [HalfMoveNo], [FigureLetter], [IsPlayerWhite], [StartColumn],
				[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
				[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
				[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex]
			)
			SELECT [TheoreticalActionID], 1, [FigureLetter], [IsPlayerWhite], [StartColumn],
				[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
				[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
				[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex] 
			FROM [CurrentGame].[fncPossibleActionsRook] (@IsPlayerWhite, @AssessmentPosition, @FieldRook)

			FETCH NEXT FROM curActionsRook INTO @FieldRook 
		END
		CLOSE curActionsRook;  
		DEALLOCATE curActionsRook; 

		-- --------------------------------------------------------------------------
		-- bishop(s)
		-- --------------------------------------------------------------------------

		-- All the runners on the board are found. For each runner found in this way, all conceivable actions 
		-- that conform to the rules are noted. Possible and rule-compliant actions are noted. Thus, even after multiple 
		-- pawn conversions, each runner is taken into account.	
		DECLARE curActionsBishop CURSOR FOR   
			SELECT DISTINCT [Field]
			FROM @AssessmentPosition
			WHERE 1 = 1
				AND [FigureLetter]	= 'B'
				AND [IsPlayerWhite]	= @IsPlayerWhite
			ORDER BY [Field];  
  
		OPEN curActionsBishop
  
		FETCH NEXT FROM curActionsBishop INTO @FieldBishop
  
		WHILE @@FETCH_STATUS = 0  
		BEGIN 

			INSERT INTO @PossibleActions
			(
				[TheoreticalActionID], [HalfMoveNo], [FigureLetter], [IsPlayerWhite], [StartColumn],
				[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
				[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
				[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex]
			)
			SELECT [TheoreticalActionID], 1, [FigureLetter], [IsPlayerWhite], [StartColumn],
				[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
				[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
				[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex] 
			FROM [CurrentGame].[fncPossibleActionsBishop] (@IsPlayerWhite, @AssessmentPosition, @FieldBishop)

			FETCH NEXT FROM curActionsBishop INTO @FieldBishop 
		END
		CLOSE curActionsBishop;  
		DEALLOCATE curActionsBishop; 

		-- --------------------------------------------------------------------------
		-- Knight(s)
		-- --------------------------------------------------------------------------

		-- All the knights on the board are found. For each knight found in this way, all conceivable actions 
		-- in accordance with the rules are noted. Possible and rule-compliant actions are noted. Thus, even after 
		-- multiple pawn conversions, each knight is taken into account.	
		DECLARE curActionsKnight CURSOR FOR   
			SELECT DISTINCT [Field]
			FROM @AssessmentPosition
			WHERE 1 = 1
				AND [FigureLetter]	= 'N'
				AND [IsPlayerWhite]	= @IsPlayerWhite
			ORDER BY [Field];  
  
		OPEN curActionsKnight
  
		FETCH NEXT FROM curActionsKnight INTO @FieldKnight
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
			INSERT INTO @PossibleActions
			(
				[TheoreticalActionID], [HalfMoveNo], [FigureLetter], [IsPlayerWhite], [StartColumn],
				[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
				[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
				[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex]
			)
			SELECT [TheoreticalActionID], 1, [FigureLetter], [IsPlayerWhite], [StartColumn],
				[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
				[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
				[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex] 
			FROM [CurrentGame].[fncPossibleActionsKnight] (@IsPlayerWhite, @AssessmentPosition, @FieldKnight)

			FETCH NEXT FROM curActionsKnight INTO @FieldKnight 
		END
		CLOSE curActionsKnight;  
		DEALLOCATE curActionsKnight; 

		---- --------------------------------------------------------------------------
		---- king
		---- --------------------------------------------------------------------------

		-- There is only one king of the same colour on the board. A pawn conversion is not to be taken into account.	
		SET @FieldKing = (SELECT [Field] FROM @AssessmentPosition WHERE [FigureLetter] = 'K' AND [IsPlayerWhite] = @IsPlayerWhite)
		INSERT INTO @PossibleActions
		(
			[TheoreticalActionID], [HalfMoveNo], [FigureLetter], [IsPlayerWhite], [StartColumn],
			[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
			[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
			[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex]
		)
		SELECT [TheoreticalActionID], 1, [FigureLetter], [IsPlayerWhite], [StartColumn],
			[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
			[TransformationFigureLetter], [IsActionCapture],	[IsActionCastlingKingsside], [IsActionCastlingQueensside],
			[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex]
		FROM [CurrentGame].[fncPOssibleActionsKing] (@IsPlayerWhite, @AssessmentPosition, @FieldKing)



		---- --------------------------------------------------------------------------
		---- pawn(s)
		---- --------------------------------------------------------------------------

		-- There is a maximum of 16 pawns on the board. A pawn conversion is not to be taken into account.	
		DECLARE curActionsPawn CURSOR FOR   
			SELECT DISTINCT [Field]
			FROM @AssessmentPosition
			WHERE 1 = 1
				AND [FigureLetter]	= 'P'
				AND [IsPlayerWhite]	= @IsPlayerWhite
			ORDER BY [Field];  
  
		OPEN curActionsPawn
  
		FETCH NEXT FROM curActionsPawn INTO @FieldPawn
  
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
			INSERT INTO @PossibleActions
			(
				[TheoreticalActionID], [HalfMoveNo], [FigureLetter], [IsPlayerWhite], [StartColumn],
				[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
				[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
				[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex]
			)
			SELECT [TheoreticalActionID], 1, [FigureLetter], [IsPlayerWhite], [StartColumn],
				[StartRow], [StartField], [TargetColumn], [TargetRow], [TargetField], [Direction],
				[TransformationFigureLetter], [IsActionCapture], [IsActionCastlingKingsside], [IsActionCastlingQueensside],
				[IsActionEnPassant], [LongNotation], [ShortNotationSimple], [ShortNotationComplex] 
			FROM [CurrentGame].[fncPossibleActionsPawn] (@IsPlayerWhite, @AssessmentPosition, @FieldPawn)

			FETCH NEXT FROM curActionsPawn INTO @FieldPawn 
		END
		CLOSE curActionsPawn;  
		DEALLOCATE curActionsPawn; 




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


	

		-- --------------------------------------------------------------------------
		-- en passant
		-- --------------------------------------------------------------------------

		-- It can happen that "en passant" is determined as a "valid" pawn move, since here only the current game 
		-- situation is analysed from a snapshot. Often, however, the rules of the game prevent "en passant" - for 
		-- example, because the pawn's double move was already several moves ago, which is not necessarily visible 
		-- from the current view of the board. Therefore, the EFN string must be evaluated and individual 
		-- actions may have to be discarded.


	RETURN
	END 
GO




------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistics ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '041 - Functions [CurrentGame].[fncPossibleActions_xxx].sql'
PRINT ' '
PRINT 'Script     :   ' + @Script
PRINT 'End        :   ' + @End
PRINT 'Time       :   ' + @Time
SELECT @Script AS Skript, @End AS Ende, @Time AS Zeit
GO

/*

USE [arelium_TSQL_Chess_V015]
GO

DECLARE @EFN varchar(255)

SET @EFN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
--SET @EFN = '6r1/6pp/7r/1B5K/1P3k2/N7/3R4/8 w - - 30 79'

SELECT * FROM [Infrastructure].[fncEFN2Position](@EFN)
GO




-- Test der Funktion [CurrentGame].[fncMoeglicheTurmaktionen]

DECLARE @ASpielbrett	AS [dbo].[[dbo].[typePosition]]
INSERT INTO @ASpielbrett
	SELECT 
		  1								AS [VarianteNr]
		, 1								AS [Suchtiefe]
		, [SB].[Column]					AS [Column]
		, [SB].[Row]					AS [Row]
		, [SB].[Field]					AS [Field]
		, [SB].[IsPlayerWhite]		AS [IsPlayerWhite]
		, [SB].[FigureLetter]			AS [FigureLetter]
		, [SB].[FigureUTF8]				AS [FigureUTF8]
	FROM [Infrastruktur].[Spielbrett]	AS [SB]

DECLARE @ActiveField	AS INTEGER
SET @ActiveField = 14--(
	--SELECT TOP 1 [SB].[Field]
	--FROM [Infrastruktur].[Spielbrett]	AS [SB]
	--WHERE 1 = 1
	--	AND [SB].[IsPlayerWhite] = 'TRUE'
	--	AND [SB].[FigureLetter] = 'T'
	--)

SELECT * FROM [CurrentGame].[fncMoeglicheTurmaktionen] (
	'True'
	, @ASpielbrett
	, @ActiveField)
ORDER BY 2,3,4,5,7

GO
*/




