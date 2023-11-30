-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### Importing a position via the EFN notation                                           ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### An EFN string is read in and the information contained there is transferred into a  ###
-- ### concrete position. The EFN notation contains not only the positions of the          ###
-- ### individual figures but also further meta information. Thus, the EFN notation can    ###
-- ### also be used to judge whether an "en passant" move is allowed as the next action,   ###
-- ### whether one still has the right to a long/short castling move, or whether it is his ###
-- ### move. Details:  https://www.embarc.de/fen-forsyth-edwards-notation/                 ###
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

CREATE OR ALTER PROCEDURE [Infrastructure].[prcImportEFN]
	  @EFN								AS VARCHAR(255)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @PositionString			AS VARCHAR(64)
	DECLARE @Loop					AS TINYINT
	DECLARE @StringPart				AS VARCHAR(8)
	DECLARE @Castling				AS VARCHAR(8)
	DECLARE @ID						AS TINYINT
	DECLARE @Letter					AS CHAR(1)
	DECLARE @IsPlayerWhite			AS BIT
	DECLARE @EnPassantField			AS TINYINT
	DECLARE @FiftyMovesRule			AS TINYINT
	DECLARE @ActionCounter			AS INTEGER
	DECLARE @NextPlayer				AS CHAR(1)
	DECLARE @SaveEFN				AS VARCHAR(100)

	SET @SaveEFN = @EFN

	-- --------------------------------------------------------------
	-- Step 1: 8 rows in EFN string 
	-- --------------------------------------------------------------
	-- The board data is extracted from the EFN string.
	SET @PositionString		= LEFT(@EFN, CHARINDEX(' ', @EFN))
	SET @EFN				= TRIM(RIGHT(@EFN, LEN(@EFN) - LEN(@PositionString)))
	
	-- The SPLIT function is used to split the rows.
	SELECT 
		  9 - ROW_NUMBER() OVER (ORDER BY GETDATE()) AS [ID]
		, [Value]
	INTO #TempPosition
	FROM STRING_SPLIT(@PositionString, '/');

	-- --------------------------------------------------------------
	-- Step 2: 8 squares per row
	-- --------------------------------------------------------------
	UPDATE #TempPosition SET [Value] = REPLACE([Value], '8', REPLICATE('$', 8))
	UPDATE #TempPosition SET [Value] = REPLACE([Value], '7', REPLICATE('$', 7))
	UPDATE #TempPosition SET [Value] = REPLACE([Value], '6', REPLICATE('$', 6))
	UPDATE #TempPosition SET [Value] = REPLACE([Value], '5', REPLICATE('$', 5))
	UPDATE #TempPosition SET [Value] = REPLACE([Value], '4', REPLICATE('$', 4))
	UPDATE #TempPosition SET [Value] = REPLACE([Value], '3', REPLICATE('$', 3))
	UPDATE #TempPosition SET [Value] = REPLACE([Value], '2', REPLICATE('$', 2))
	UPDATE #TempPosition SET [Value] = REPLACE([Value], '1', REPLICATE('$', 1))

	-- --------------------------------------------------------------
	-- Step 3: Evaluate the position information of the figures
	-- --------------------------------------------------------------

	-- Now the information from the EFN string is converted into UPDATE statements.
	DECLARE curImoprt CURSOR FOR   
		SELECT [ID], [Value]
		FROM #TempPosition
		ORDER BY [ID] DESC;  

	OPEN curImoprt
  
	FETCH NEXT FROM curImoprt INTO @ID, @StringPart
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		SET @PositionString	= ''
		SET @Loop			= 1
		WHILE @Loop<= 8
		BEGIN
			SET @Letter			= LEFT(@StringPart, 1)

			IF @Letter = '$'
			BEGIN
				SET @IsPlayerWhite = NULL
			END
			ELSE
			BEGIN
				IF UPPER(@Letter COLLATE Latin1_General_CS_AI) <> @Letter COLLATE Latin1_General_CS_AI
				BEGIN
					SET @IsPlayerWhite = 'FALSE'
				END
				ELSE
				BEGIN
					SET @IsPlayerWhite = 'TRUE'
				END
			END

			UPDATE [Infrastructure].[GameBoard]
			SET	  [IsPlayerWhite]		= @IsPlayerWhite
				, [FigureLetter]		= (SELECT	CASE @Letter
														WHEN '$' COLLATE Latin1_General_CS_AI THEN NULL
														WHEN 'r' COLLATE Latin1_General_CS_AI THEN 'R'
														WHEN 'R' COLLATE Latin1_General_CS_AI THEN 'R'
														WHEN 'n' COLLATE Latin1_General_CS_AI THEN 'N'
														WHEN 'N' COLLATE Latin1_General_CS_AI THEN 'N'
														WHEN 'b' COLLATE Latin1_General_CS_AI THEN 'B'
														WHEN 'B' COLLATE Latin1_General_CS_AI THEN 'B'
														WHEN 'q' COLLATE Latin1_General_CS_AI THEN 'Q'
														WHEN 'Q' COLLATE Latin1_General_CS_AI THEN 'Q'
														WHEN 'k' COLLATE Latin1_General_CS_AI THEN 'K'
														WHEN 'K' COLLATE Latin1_General_CS_AI THEN 'K'
														WHEN 'p' COLLATE Latin1_General_CS_AI THEN 'P'
														WHEN 'P' COLLATE Latin1_General_CS_AI THEN 'P'
													END
											)
				, [FigureUTF8]			= (SELECT	CASE @Letter
														WHEN '$' COLLATE Latin1_General_CS_AI THEN 160
														WHEN 'r' COLLATE Latin1_General_CS_AI THEN 9820
														WHEN 'R' COLLATE Latin1_General_CS_AI THEN 9814
														WHEN 'n' COLLATE Latin1_General_CS_AI THEN 9822
														WHEN 'N' COLLATE Latin1_General_CS_AI THEN 9816
														WHEN 'b' COLLATE Latin1_General_CS_AI THEN 9821
														WHEN 'B' COLLATE Latin1_General_CS_AI THEN 9815
														WHEN 'q' COLLATE Latin1_General_CS_AI THEN 9819
														WHEN 'Q' COLLATE Latin1_General_CS_AI THEN 9813
														WHEN 'k' COLLATE Latin1_General_CS_AI THEN 9818
														WHEN 'K' COLLATE Latin1_General_CS_AI THEN 9812
														WHEN 'p' COLLATE Latin1_General_CS_AI THEN 9823
														WHEN 'P' COLLATE Latin1_General_CS_AI THEN 9817
													END
											)
			WHERE [Field]	= (@Loop- 1) * 8 + @ID

			SET @Loop		= @Loop+ 1
			SET @StringPart = RIGHT(@StringPart, LEN(@StringPart) - 1)
		END		

		FETCH NEXT FROM curImoprt INTO @ID, @StringPart
	END
	CLOSE curImoprt;  
	DEALLOCATE curImoprt; 

	DROP TABLE #TempPosition

	
	-- --------------------------------------------------------------
	-- Step 4: next player
	-- --------------------------------------------------------------

	SET @NextPlayer = LEFT(@EFN, 1)


	-- --------------------------------------------------------------
	-- Step 5: Observe castling rights
	-- --------------------------------------------------------------

	SET @EFN			= RIGHT(@EFN, LEN(@EFN) - 2)
	SET @Castling		= TRIM(LEFT(@EFN, CHARINDEX(' ', @EFN, 1)))
	SET @EFN			= RIGHT(@EFN, LEN(@EFN) - CHARINDEX(' ', @EFN, 1))

	UPDATE [CurrentGame].[GameStatus]
	SET   [IsShortCastlingStillAllowed]			= 'FALSE'
		, [IsLongCastlingStillAllowed]			= 'FALSE'


	IF CHARINDEX('k' COLLATE Latin1_General_CS_AI, @Castling, 1) <> 0
	BEGIN
		UPDATE [CurrentGame].[GameStatus]
		SET   [IsShortCastlingStillAllowed]		= 'TRUE'
		WHERE [IsPlayerWhite]					= 'FALSE'
	END

	IF CHARINDEX('K' COLLATE Latin1_General_CS_AI, @Castling, 1) <> 0
	BEGIN
		UPDATE [CurrentGame].[GameStatus]
		SET   [IsShortCastlingStillAllowed]		= 'TRUE'
		WHERE [IsPlayerWhite]					= 'TRUE'
	END

	IF CHARINDEX('q' COLLATE Latin1_General_CS_AI, @Castling, 1) <> 0
	BEGIN
		UPDATE [CurrentGame].[GameStatus]
		SET   [IsLongCastlingStillAllowed]		= 'TRUE'
		WHERE [IsPlayerWhite]					= 'FALSE'
	END

	IF CHARINDEX('Q' COLLATE Latin1_General_CS_AI, @Castling, 1) <> 0
	BEGIN
		UPDATE [CurrentGame].[GameStatus]
		SET   [IsLongCastlingStillAllowed]		= 'TRUE'
		WHERE [IsPlayerWhite]					= 'TRUE'
	END

	
	-- --------------------------------------------------------------
	-- Step 6: note en-passant
	---- --------------------------------------------------------------

	SET @StringPart		= TRIM(LEFT(@EFN, CHARINDEX(' ', @EFN, 1)))
	SET @EFN			= RIGHT(@EFN, LEN(@EFN) - CHARINDEX(' ', @EFN, 1))

	IF @StringPart = '-'
	BEGIN
		SET @EnPassantField = NULL
	END
	ELSE
	BEGIN
		SET @EnPassantField = (	SELECT [Field]
								FROM [Infrastructure].[GameBoard]
								WHERE 1 = 1
									AND [Column]	= LEFT(@StringPart, 1)
									AND [Row]		= RIGHT(@StringPart, 1)
							)
	END

	-- --------------------------------------------------------------
	-- Step 7: 50-count rule
	---- --------------------------------------------------------------

	SET @StringPart		= TRIM(LEFT(@EFN, CHARINDEX(' ', @EFN, 1)))
	SET @EFN			= RIGHT(@EFN, LEN(@EFN) - CHARINDEX(' ', @EFN, 1))

	SET @FiftyMovesRule = CONVERT(TINYINT, @StringPart)

	UPDATE [CurrentGame].[GameStatus]
	SET [Number50ActionsRule] = @FiftyMovesRule
	
	-- --------------------------------------------------------------
	-- Step 8: action number
	---- --------------------------------------------------------------

	SET @StringPart		= TRIM(LEFT(@EFN, CHARINDEX(' ', @EFN, 1)))
	SET @ActionCounter	= CONVERT(INTEGER, @StringPart)

	DELETE FROM [CurrentGame].[Notation]

	INSERT INTO [CurrentGame].[Notation]
        ( [MoveID]
        , [IsPlayerWhite]
        , [TheoreticalActionID]
        , [LongNotation]
        , [ShortNotationSimple]
        , [ShortNotationComplex]
        , [IsMoveChessBid]
		, [EFN])
	VALUES
        (0, 1, NULL, 'EFN', 'EFN', 'EFN', 'FALSE', @SaveEFN)

	IF @NextPlayer = 'w'
	BEGIN
		INSERT INTO [CurrentGame].[Notation]
           (  [MoveID]
			, [IsPlayerWhite]
			, [TheoreticalActionID]
			, [LongNotation]
			, [ShortNotationSimple]
			, [ShortNotationComplex]
			, [IsMoveChessBid]
			, [EFN])
		VALUES
           (0, 0, NULL, 'EFN', 'EFN', 'EFN', 'FALSE', @SaveEFN)
	END
	





	--SELECT * FROM [Infrastruktur].[vSpielbrett]


END
GO



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistics ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '610 - Procedure [Infrastruktur].[prcImportEFN].sql'
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

EXECUTE [Infrastructure].[prcImportEFN] @EFN
GO

*/
 