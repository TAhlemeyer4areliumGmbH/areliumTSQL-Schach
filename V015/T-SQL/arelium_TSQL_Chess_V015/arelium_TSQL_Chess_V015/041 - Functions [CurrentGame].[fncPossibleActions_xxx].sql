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



--------------------------------------------------------------------------------------------------
-- Construction work -----------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

CREATE OR ALTER FUNCTION [CurrentGame].[fncPossibleActionsRook] 
(
	   @IsPlayerWhite		AS BIT
	 , @EFN					AS VARCHAR(100)
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

		DECLARE @AssessmentPosition	AS [dbo].[typePosition]	
		
		INSERT INTO @AssessmentPosition
			SELECT * FROM [Infrastructure].[fncEFN2Position](@EFN)


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

			-- handelt es sich um einen Zug, ist das Zielfeld leer. Ist es hingegen ein 
			-- Schlag, muss das Zielfeld besetzt sein
			AND (
					([SPB].[FigureUTF8] = 160		AND [MZU].[IsActionCapture] = 'FALSE')
					OR
					([SPB].[FigureUTF8] <> 160		AND [MZU].[IsActionCapture] = 'TRUE')
				)

			-- ermittelt werden fuer jede Zugrichtung alle Felder bis zur
			-- ersten Figur (egal welcher Farbe), die im Weg steht

			-- erste Figur im Weg nach rechts
			AND [MZU].[TargetColumn] <= ISNULL(
				(
					SELECT MIN([Inside].[Column])
					FROM @AssessmentPosition				AS [Inside]
					WHERE 1 = 1
						AND [Inside].[FigureUTF8]		<> 160
						AND [Inside].[Column]		> [MZU].[StartColumn]
						AND [Inside].[Row]			= [MZU].[StartRow]
				), 'H')

			-- erste Figur im Weg nach links
			AND [MZU].[TargetColumn] >= ISNULL(
				(
					SELECT MAX([Inside].[Column])
					FROM @AssessmentPosition				AS [Inside]
					WHERE 1 = 1
						AND [Inside].[FigureUTF8]		<> 160
						AND [Inside].[Column]		< [MZU].[StartColumn]
						AND [Inside].[Row]			= [MZU].[StartRow]
				), 'A')

			-- erste Figur im Weg nach oben
			AND [MZU].[TargetRow] <= ISNULL(
				(
					SELECT MIN([Inside].[Row])
					FROM @AssessmentPosition				AS [Inside]
					WHERE 1 = 1
						AND [Inside].[FigureUTF8]		<> 160
						AND [Inside].[Column]		= [MZU].[StartColumn]
						AND [Inside].[Row]			> [MZU].[StartRow]
				), 8)

			-- erste Figur im Weg nach unten
			AND [MZU].[TargetRow] >= ISNULL(
				(
					SELECT MAX([Inside].[Row])
					FROM @AssessmentPosition				AS [Inside]
					WHERE 1 = 1
						AND [Inside].[FigureUTF8]		<> 160
						AND [Inside].[Column]		= [MZU].[StartColumn]
						AND [Inside].[Row]			< [MZU].[StartRow]
				), 1)

			-- es darf keine Figur der eigenen Farbe geschlagen werden
			AND [SPB].[FigureUTF8] NOT IN 
				(
					SELECT [FigureUTF8] FROM [Infrastructure].[Figure]
					WHERE 1 = 1
						AND [IsPlayerWhite] = @IsPlayerWhite
				)
		RETURN
	END
GO


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
			(	-- ziehen
				(
					[SPB].[FigureUTF8]				= 160
				AND
					[MZU].[IsActionCapture]			= 'FALSE'
				)
			OR	-- schlagen
				(
					-- schlagen, aber nicht die eigenen Figuren
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



CREATE OR ALTER FUNCTION [CurrentGame].[fncPossiblectionsBishop]
(
	   @IsPlayerWhite		AS BIT
	 , @AssessmentPosition	AS [dbo].[typePosition]			READONLY
	 , @ActiveField			AS INTEGER
)
-- Definition der Rueckgabetabelle
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
	-- die passenden Werte zusammenstellen
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
					-- schlagen, aber nicht die eigenen Figuren
					[SPB].[FigureUTF8] NOT IN (SELECT [FigureUTF8] 
										FROM [Infrastructure].[Figure]  
										WHERE [IsPlayerWhite] = @IsPlayerWhite)
		AND 
			(
				[MZU].[TargetField] IN 
					-- vom Laeufer aus gesehen nach links oben
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

				OR

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

				OR

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

				OR

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




CREATE OR ALTER FUNCTION [CurrentGame].[fncMoeglicheDamenaktionen]
(
	   @IsPlayerWhite		AS BIT
	 , @AssessmentPosition	AS [dbo].[typePosition]			READONLY
	 , @ActiveField			AS INTEGER
)
RETURNS @MoeglicheDamenaktionen TABLE 
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
		INSERT INTO @MoeglicheDamenaktionen
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
			AND [MZU].[TargetColumn]				= [SPB].[Column]
	WHERE 1 = 1
		AND [MZU].[IsPlayerWhite]				= @IsPlayerWhite
		AND [MZU].[FigureLetter]					= 'Q'
		AND [MZU].[StartField]					= @ActiveField
		AND 
			(
				([SPB].[FigureUTF8] = 160		AND [MZU].[IsActionCapture] = 'FALSE')
				OR
				([SPB].[FigureUTF8] <> 160		AND [MZU].[IsActionCapture] = 'TRUE')
			)
		AND
			-- schlagen, aber nicht die eigenen Figuren
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
					-- schlagen, aber nicht die eigenen Figuren
					[SPB].[FigureUTF8] NOT IN (SELECT [FigureUTF8] 
										FROM [Infrastructure].[Figure]  
										WHERE [IsPlayerWhite] = @IsPlayerWhite)
	RETURN
	END
GO			



CREATE OR ALTER FUNCTION [CurrentGame].[fncMoeglicheBauernaktionen]
(
	   @IsPlayerWhite		AS BIT
	 , @AssessmentPosition	AS [dbo].[typePosition]			READONLY
	 , @ActiveField			AS INTEGER
)
RETURNS @MoeglicheBauernaktionen TABLE 
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
		INSERT INTO @MoeglicheBauernaktionen
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
				(									-- normaler Zug, kein Schlag
					    [SPB].[FigureUTF8]		= 160	
					AND [MZU].[IsActionCapture]	= 'FALSE'
					AND 
						(							-- beim Doppelzug muss auch das Zwischenfeld 
													-- leer sein
							SELECT [BS].[FigureUTF8]
							FROM @AssessmentPosition		AS [BS]
							WHERE 1 = 1
								AND (
										(			-- WEISS zieht nach oben
											[BS].[Field] = [MZU].[StartField] + 1
											AND
											@IsPlayerWhite	= 'TRUE'
										)
										OR 
										(			-- SCHWARZ zieht nach unten
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
						-- schlagen, aber nicht die eigenen Figuren
						[SPB].[FigureUTF8] NOT IN (SELECT [FigureUTF8] 
											FROM [Infrastructure].[Figure]  
											WHERE [IsPlayerWhite] = @IsPlayerWhite)
				)
			)

	UNION
	
	-- Sonderbereich fuer den "en passant"-Fall
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




CREATE OR ALTER FUNCTION [CurrentGame].[fncPossibleActionsAllPieces] 
(
	   @IsPlayerWhite		AS BIT
	 , @AssessmentPosition	AS [dbo].[typePosition]			READONLY
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

			
		---- --------------------------------------------------------------------------
		---- Damen
		---- --------------------------------------------------------------------------

		-- Es werden alle auf dem Brett befindlichen Damen ermittelt. fuer jede so gefundene Dame werden nun alle 
		-- denkbaren und regelkonforme Aktionen notiert. Somit ist selbst nach mehrfacher Bauernumwandlung jede Dame 
		-- beruecksichtigt.
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


		---- --------------------------------------------------------------------------
		---- Tuerme
		---- --------------------------------------------------------------------------

		-- Es werden alle auf dem Brett befindlichen Tuerme ermittelt. fuer jeden so gefundenen Turm werden nun alle 
		-- denkbaren und regelkonforme Aktionen notiert. Somit ist selbst nach mehrfacher Bauernumwandlung jeder Turm 
		-- beruecksichtigt.	
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

		---- --------------------------------------------------------------------------
		---- Laeufer
		---- --------------------------------------------------------------------------

		-- Es werden alle auf dem Brett befindlichen Laeufer ermittelt. fuer jeden so gefundenen Laeufer werden nun alle 
		-- denkbaren und regelkonforme Aktionen notiert. Somit ist selbst nach mehrfacher Bauernumwandlung jeder Laeufer
		-- beruecksichtigt.	
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
		-- Springer
		-- --------------------------------------------------------------------------

		-- Es werden alle auf dem Brett befindlichen Springer ermittelt. fuer jeden so gefundenen Springer werden nun alle 
		-- denkbaren und regelkonforme Aktionen notiert. Somit ist selbst nach mehrfacher Bauernumwandlung jeder Springer
		-- beruecksichtigt.	
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
		---- Koenig
		---- --------------------------------------------------------------------------

		-- Es ist nur genau ein farblich passender Koenig auf den Spielfeld. Eine Bauernumwandlung ist nicht zu beruecksichtigen.	
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
		---- Bauern
		---- --------------------------------------------------------------------------

		-- Es sind maximal 16 Bauern auf den Spielfeld. Eine Bauernumwandlung ist nicht zu beruecksichtigen.	
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




		---- --------------------------------------------------------------------------
		---- illegale Zuege werden wieder rausgefiltert
		---- --------------------------------------------------------------------------




		---- --------------------------------------------------------------------------
		---- Rochaden
		---- --------------------------------------------------------------------------

		-- es kann vorkommen, dass eine Rochade als "gueltiger" Koenigszug ermittelt 
		-- wird, auch wenn die Spielregeln in dieser Situation eine Rochade 
		-- eigentlich unterbinden. Dies liegt daran, dass die Rochade einer der 
		-- drei Zuege (die anderen sind "en passant" und die Bauerumwandlung) ist, 
		-- bei dem gleich zwei Figuren betroffen sind. Dies kann durch eine einfache 
		-- Anfrage gegen die Tabelle [Infrastructure].[TheoreticalAction] nicht 
		-- sauber geprueft werden, da weitere Daten notwewndig sind. Somit sind 
		-- evtl. fehlerhaft erfasste Zugmoeglichkeiten wieder zu entfernen...

		-- ***************
		-- *** WEISS *****
		-- ***************
		IF (SELECT [IstKurzeRochadeErlaubt] FROM [CurrentGame].[Konfiguration] WHERE [IsPlayerWhite] = 'TRUE') = 'TRUE'
			OR (SELECT [IstLangeRochadeErlaubt] FROM [CurrentGame].[Konfiguration] WHERE [IsPlayerWhite] = 'TRUE') = 'TRUE'
		BEGIN

			-- --------------------------------------------------------------------------------------
			-- Eine Rochade ist nur moeglich, wenn der Koenig an der 
			-- "richtigen" Position steht (also auch nicht geschlagen wurden)
			-- --------------------------------------------------------------------------------------
			IF EXISTS (SELECT * FROM @AssessmentPosition WHERE [Field] = 33 AND [FigureLetter] = 'K' AND [IsPlayerWhite] = 'TRUE')
			BEGIN
				-- --------------------------------------------------------------------------------------
				-- eine Rochade ist nur dann moeglich, wenn der Koenig noch nie gezogen
				-- hat - selbst wenn er zwischenzeitlich auf das Ausgangsfeld zurueckgekehrt ist.  
				-- Es reicht also in der Notation zu ueberpruefen, ob es einen Zug/Schlag in 
				-- der Partiehistorie von dem Ausgangsfeld weg gegeben hat...
				-- --------------------------------------------------------------------------------------
				IF (SELECT COUNT(*) FROM [CurrentGame].[Notation] WHERE [LongNotation] LIKE 'K%' AND [IsPlayerWhite] = 'TRUE') = 0
				BEGIN
					-- --------------------------------------------------------------------------------------
					-- Eine Rochade ist nur moeglich, wenn der zugehoeriger Turm an der 
					-- "richtigen" Position steht (also auch nicht geschlagen wurden)
					 --------------------------------------------------------------------------------------

					IF (SELECT [IstKurzeRochadeErlaubt] FROM [CurrentGame].[Konfiguration] WHERE [IsPlayerWhite] = @IsPlayerWhite) = 'TRUE'
					BEGIN
					
						-- kurze Rochade
						IF EXISTS (SELECT * FROM @AssessmentPosition WHERE [Field] = 57 AND [FigureLetter] = 'T' AND [IsPlayerWhite] = 'TRUE')
						BEGIN
							-- --------------------------------------------------------------------------------------
							-- eine Rochade ist nur dann moeglich, wenn der Turm noch nie gezogen
							-- hat - selbst wenn er auf das Ausgangsfeld zurueckgekehrt ist. Es reicht also 
							-- in der Notation zu ueberpruefen, ob es einen Zug/Schlag in der Partiehistorie
							-- von dem Ausgangsfeld weg gegeben hat...
							-- --------------------------------------------------------------------------------------
							IF (SELECT COUNT(*) FROM [CurrentGame].[Notation] WHERE [LongNotation] LIKE 'Th1%' AND [IsPlayerWhite] = 'TRUE') = 0
							BEGIN
								DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'ABCDEFG'
							--	-- --------------------------------------------------------------------------------------
							--	-- eine Rochade ist nur dann moeglich, wenn der Koenig nicht ueber ein gerade angegriffenes
							--	-- Feld ziehen muss. Alle Felder (seinen aktuellen Standort, das Zielfeld und alle Felder 
							--	-- dazwischen - nicht jedoch Felder, die nur vom Turmzug betroffen sind) duerfen daher nicht
							--	-- im "Schach" stehen
							--	-- --------------------------------------------------------------------------------------
							--	IF EXISTS (SELECT * FROM [CurrentGame].[fncVirtuelleSchlaege] ((@IsPlayerWhite + 1) % 2, @AssessmentPosition, 33))			-- Feld E1 angegriffen
							--		OR EXISTS (SELECT * FROM [CurrentGame].[fncVirtuelleSchlaege] ((@IsPlayerWhite + 1) % 2, @AssessmentPosition, 41))		-- Feld F1 angegriffen
							--		OR EXISTS (SELECT * FROM [CurrentGame].[fncVirtuelleSchlaege] ((@IsPlayerWhite + 1) % 2, @AssessmentPosition, 49))		-- Feld G1 angegriffen
							--	BEGIN
							--		DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-o' AND [IsPlayerWhite] = 'TRUE'				-- kurze Rochade unmoeglich
							--	END
							END
							ELSE
							BEGIN
								DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-o' AND [IsPlayerWhite] = 'TRUE'				-- kurze Rochade unmoeglich
							END
						END
						ELSE
						BEGIN
							DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-o' AND [IsPlayerWhite] = 'TRUE'					-- kurze Rochade unmoeglich
						END
					END
					ELSE
					BEGIN
						DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-o' AND [IsPlayerWhite] = 'TRUE'					-- kurze Rochade unmoeglich
					END

					IF (SELECT [IstLangeRochadeErlaubt] FROM [CurrentGame].[Konfiguration] WHERE [IsPlayerWhite] = @IsPlayerWhite) = 'TRUE'
					BEGIN
					
						-- lange Rochade
						IF EXISTS (SELECT * FROM @AssessmentPosition WHERE [Field] =  1 AND [FigureLetter] = 'T' AND [IsPlayerWhite] = 'TRUE')
						BEGIN
							-- --------------------------------------------------------------------------------------
							-- eine Rochade ist nur dann moeglich, wenn der Turm noch nie gezogen
							-- hat - selbst wenn er auf das Ausgangsfeld zurueckgekehrt ist. Es reicht also 
							-- in der Notation zu ueberpruefen, ob es einen Zug/Schlag in der Partiehistorie
							-- von dem Ausgangsfeld weg gegeben hat...
							-- --------------------------------------------------------------------------------------
							IF (SELECT COUNT(*) FROM [CurrentGame].[Notation] WHERE [LongNotation] LIKE 'Ta1%' AND [IsPlayerWhite] = 'TRUE') > 0
							BEGIN
								-- --------------------------------------------------------------------------------------
								-- eine Rochade ist nur dann moeglich, wenn der Koenig nicht ueber ein gerade angegriffenes
								-- Feld ziehen muss. Alle Felder (seinen aktuellen Standort, das Zielfeld und alle Felder 
								-- dazwischen - nicht jedoch Felder, die nur vom Turmzug betroffen sind) duerfen daher nicht
								-- im "Schach" stehen
								-- --------------------------------------------------------------------------------------
								IF (SELECT COUNT(*) FROM [CurrentGame].[frcMoeglicheVirtuelleSchlaegeAufFeld] ((@IsPlayerWhite + 1) % 2, @AssessmentPosition, 33)) <> 0			-- Feld E1 angegriffen
									OR (SELECT COUNT(*) FROM [CurrentGame].[frcMoeglicheVirtuelleSchlaegeAufFeld] ((@IsPlayerWhite + 1) % 2, @AssessmentPosition, 25)) <> 0		-- Feld D1 angegriffen
									OR (SELECT COUNT(*) FROM [CurrentGame].[frcMoeglicheVirtuelleSchlaegeAufFeld] ((@IsPlayerWhite + 1) % 2, @AssessmentPosition, 17)) <> 0		-- Feld C1 angegriffen
								BEGIN
									DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-o-o' AND [IsPlayerWhite] = 'TRUE'			-- lange Rochade unmoeglich
								END

							END
							ELSE
							BEGIN
								DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-o-o' AND [IsPlayerWhite] = 'TRUE'			-- lange Rochade unmoeglich
							END
						END
						ELSE
						BEGIN
							DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-o-o' AND [IsPlayerWhite] = 'TRUE'				-- lange Rochade unmoeglich
						END
					END
					ELSE
					BEGIN
						DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-o-o' AND [IsPlayerWhite] = 'TRUE'				-- lange Rochade unmoeglich
					END
				END
				ELSE
				BEGIN
					DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-%' AND [IsPlayerWhite] = 'TRUE'						-- lange und kurze Rochade unmoeglich
				END
			END
			ELSE
			BEGIN
				DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-%' AND [IsPlayerWhite] = 'TRUE'							-- lange und kurze Rochade unmoeglich
			END
		END
		ELSE
		BEGIN
			DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-%' AND [IsPlayerWhite] = 'TRUE'							-- lange und kurze Rochade unmoeglich
		END

		-- ***************
		-- *** SCHWARZ ***
		-- ***************

		IF (SELECT [IstKurzeRochadeErlaubt] FROM [CurrentGame].[Konfiguration] WHERE [IsPlayerWhite] = 'FALSE') = 'TRUE'
			OR (SELECT [IstLangeRochadeErlaubt] FROM [CurrentGame].[Konfiguration] WHERE [IsPlayerWhite] = 'FALSE') = 'TRUE'
		BEGIN

			-- --------------------------------------------------------------------------------------
			-- Eine Rochade ist nur moeglich, wenn der Koenig an der 
			-- "richtigen" Position steht (also auch nicht geschlagen wurden)
			-- --------------------------------------------------------------------------------------
			IF EXISTS (SELECT * FROM @AssessmentPosition WHERE [Field] = 40 AND [FigureLetter] = 'K' AND [IsPlayerWhite] = 'FALSE')
			BEGIN
				-- --------------------------------------------------------------------------------------
				-- eine Rochade ist nur dann moeglich, wenn der Koenig noch nie gezogen
				-- hat - selbst wenn er zwischenzeitlich auf das Ausgangsfeld zurueckgekehrt ist.  
				-- Es reicht also in der Notation zu ueberpruefen, ob es einen Zug/Schlag in 
				-- der Partiehistorie von dem Ausgangsfeld weg gegeben hat...
				-- --------------------------------------------------------------------------------------
				IF (SELECT COUNT(*) FROM [CurrentGame].[Notation] WHERE [LongNotation] LIKE 'K%' AND [IsPlayerWhite] = 'FALSE') = 0
				BEGIN
					-- --------------------------------------------------------------------------------------
					-- Eine Rochade ist nur moeglich, wenn der zugehoeriger Turm an der 
					-- "richtigen" Position steht (also auch nicht geschlagen wurden)
					 --------------------------------------------------------------------------------------

					IF (SELECT [IstKurzeRochadeErlaubt] FROM [CurrentGame].[Konfiguration] WHERE [IsPlayerWhite] = @IsPlayerWhite) = 'FALSE'
					BEGIN
					
						-- kurze Rochade
						IF EXISTS (SELECT * FROM @AssessmentPosition WHERE [Field] = 64 AND [FigureLetter] = 'T' AND [IsPlayerWhite] = 'FALSE')
						BEGIN
							-- --------------------------------------------------------------------------------------
							-- eine Rochade ist nur dann moeglich, wenn der Turm noch nie gezogen
							-- hat - selbst wenn er auf das Ausgangsfeld zurueckgekehrt ist. Es reicht also 
							-- in der Notation zu ueberpruefen, ob es einen Zug/Schlag in der Partiehistorie
							-- von dem Ausgangsfeld weg gegeben hat...
							-- --------------------------------------------------------------------------------------
							IF (SELECT COUNT(*) FROM [CurrentGame].[Notation] WHERE [LongNotation] LIKE 'Th8%' AND [IsPlayerWhite] = 'FALSE') = 0
							BEGIN
								-- --------------------------------------------------------------------------------------
								-- eine Rochade ist nur dann moeglich, wenn der Koenig nicht ueber ein gerade angegriffenes
								-- Feld ziehen muss. Alle Felder (seinen aktuellen Standort, das Zielfeld und alle Felder 
								-- dazwischen - nicht jedoch Felder, die nur vom Turmzug betroffen sind) duerfen daher nicht
								-- im "Schach" stehen
								-- --------------------------------------------------------------------------------------
								IF (SELECT COUNT(*) FROM [CurrentGame].[fncVirtuelleSchlaege] ((@IsPlayerWhite + 1) % 2, @AssessmentPosition, 40)) <> 0		-- Feld E8 angegriffen
									OR (SELECT COUNT(*) FROM [CurrentGame].[fncVirtuelleSchlaege] ((@IsPlayerWhite + 1) % 2, @AssessmentPosition, 48)) <> 0	-- Feld F8 angegriffen
									OR (SELECT COUNT(*) FROM [CurrentGame].[fncVirtuelleSchlaege] ((@IsPlayerWhite + 1) % 2, @AssessmentPosition, 56)) <> 0	-- Feld G8 angegriffen
								BEGIN
									DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-o' AND [IsPlayerWhite] = 'FALSE'				-- kurze Rochade unmoeglich
								END
							END
							ELSE
							BEGIN
								DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-o' AND [IsPlayerWhite] = 'FALSE'				-- kurze Rochade unmoeglich
							END
						END
						ELSE
						BEGIN
							DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-o' AND [IsPlayerWhite] = 'FALSE'					-- kurze Rochade unmoeglich
						END
					END
					ELSE
					BEGIN
						DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-o' AND [IsPlayerWhite] = 'FALSE'					-- kurze Rochade unmoeglich
					END


					IF (SELECT [IstLangeRochadeErlaubt] FROM [CurrentGame].[Konfiguration] WHERE [IsPlayerWhite] = @IsPlayerWhite) = 'FALSE'
					BEGIN
					
						-- lange Rochade
						IF EXISTS (SELECT * FROM @AssessmentPosition WHERE [Field] =  8 AND [FigureLetter] = 'T' AND [IsPlayerWhite] = 'FALSE')
						BEGIN
							-- --------------------------------------------------------------------------------------
							-- eine Rochade ist nur dann moeglich, wenn der Turm noch nie gezogen
							-- hat - selbst wenn er auf das Ausgangsfeld zurueckgekehrt ist. Es reicht also 
							-- in der Notation zu ueberpruefen, ob es einen Zug/Schlag in der Partiehistorie
							-- von dem Ausgangsfeld weg gegeben hat...
							-- --------------------------------------------------------------------------------------
							IF (SELECT COUNT(*) FROM [CurrentGame].[Notation] WHERE [LongNotation] LIKE 'Ta8%' AND [IsPlayerWhite] = 'FALSE') > 0
							BEGIN
								-- --------------------------------------------------------------------------------------
								-- eine Rochade ist nur dann moeglich, wenn der Koenig nicht ueber ein gerade angegriffenes
								-- Feld ziehen muss. Alle Felder (seinen aktuellen Standort, das Zielfeld und alle Felder 
								-- dazwischen - nicht jedoch Felder, die nur vom Turmzug betroffen sind) duerfen daher nicht
								-- im "Schach" stehen
								-- --------------------------------------------------------------------------------------
								IF EXISTS (SELECT * FROM [CurrentGame].[frcMoeglicheVirtuelleSchlaegeAufFeld] ((@IsPlayerWhite + 1) % 2, @AssessmentPosition, 40))			-- Feld E8 angegriffen
									OR EXISTS (SELECT * FROM [CurrentGame].[frcMoeglicheVirtuelleSchlaegeAufFeld] ((@IsPlayerWhite + 1) % 2, @AssessmentPosition, 32))		-- Feld D8 angegriffen
									OR EXISTS (SELECT * FROM [CurrentGame].[frcMoeglicheVirtuelleSchlaegeAufFeld] ((@IsPlayerWhite + 1) % 2, @AssessmentPosition, 24))		-- Feld C8 angegriffen
								BEGIN
									DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-o-o' AND [IsPlayerWhite] = 'FALSE'			-- lange Rochade unmoeglich
								END

							END
							ELSE
							BEGIN
								DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-o-o' AND [IsPlayerWhite] = 'FALSE'			-- lange Rochade unmoeglich
							END
						END
						ELSE
						BEGIN
							DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-o-o' AND [IsPlayerWhite] = 'FALSE'				-- lange Rochade unmoeglich
						END
					END
					ELSE
					BEGIN
						DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-o-o' AND [IsPlayerWhite] = 'FALSE'				-- lange Rochade unmoeglich
					END
				END
				ELSE
				BEGIN
					DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-%' AND [IsPlayerWhite] = 'FALSE'						-- lange und kurze Rochade unmoeglich
				END
			END
			ELSE
			BEGIN
				DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-%' AND [IsPlayerWhite] = 'FALSE'							-- lange und kurze Rochade unmoeglich
			END
		END
		ELSE
		BEGIN
			DELETE FROM @PossibleActions WHERE [LongNotation] LIKE 'o-%' AND [IsPlayerWhite] = 'FALSE'							-- lange und kurze Rochade unmoeglich
		END

	

		---- --------------------------------------------------------------------------
		---- en passant
		---- --------------------------------------------------------------------------

		-- es kann vorkommen, dass ein "en Passant"-Schlag als "gueltiger" Schlag ermittelt 
		-- wird, auch wenn die Spielregeln in dieser Situation einen "en Passant"-Schlag
		-- eigentlich unterbinden. Dies liegt daran, dass der "en Passant"-Schlag einer der 
		-- drei Zuege (die anderen sind Rochade und die Bauerumwandlung) ist, 
		-- bei dem gleich zwei Figuren betroffen sind. Dies kann durch eine einfache 
		-- Anfrage gegen die Tabelle [Infrastructure].[TheoreticalAction] nicht 
		-- sauber geprueft werden, da weitere Daten notwewndig sind. Somit sind 
		-- evtl. fehlerhaft erfasste Zugmoeglichkeiten wieder zu entfernen...

		--DELETE FROM @PossibleActions
		--WHERE 1 = 1
		--	AND [LongNotation] like '%e.p.'	
		--	AND [IsPlayerWhite] = 'FALSE'
		--	AND (
		--			[CurrentGame].[fncIstFeldBedroht]([IsPlayerWhite], @AssessmentPosition, 24) = 'TRUE'
		--			OR
		--			[CurrentGame].[fncIstFeldBedroht]([IsPlayerWhite], @AssessmentPosition, 32) = 'TRUE'
		--		)
		--		-- WEITERE BEDINGUNGEN ZU IMPLEMENTIEREN

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




