-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### Transforming an EFN-string into a postion                                           ###
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

CREATE OR ALTER PROCEDURE [Infrastructure].[prcEFNString2Position]
	  @EFN								AS VARCHAR(255)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @PositionString			AS VARCHAR(71)
	DECLARE @MetaString				AS VARCHAR(40)
	DECLARE @Row					AS TINYINT
	DECLARE @Column					AS TINYINT
	DECLARE @Field					AS TINYINT
	DECLARE @EFNPositionNr			AS TINYINT
	DECLARE @StringPart				AS VARCHAR(8)
	DECLARE @Castling				AS VARCHAR(8)
	DECLARE @EnPassantField			AS TINYINT
	DECLARE @FiftyMovesRule			AS TINYINT
	DECLARE @ActionCounter			AS INTEGER
	DECLARE @NextPlayer				AS CHAR(1)

	-- --------------------------------------------------------------
	-- Step 1: Converting the numbers back into several empty fields
	-- --------------------------------------------------------------

	SET @PositionString		= LEFT(@EFN, CHARINDEX(' ', @EFN))
	SET @MetaString			= RIGHT(@EFN, LEN(@EFN) - LEN(@PositionString) - 1)

	SET @PositionString = REPLACE(@PositionString, '8', REPLICATE('$', 8))
	SET @PositionString = REPLACE(@PositionString, '7', REPLICATE('$', 7))
	SET @PositionString = REPLACE(@PositionString, '6', REPLICATE('$', 6))
	SET @PositionString = REPLACE(@PositionString, '5', REPLICATE('$', 5))
	SET @PositionString = REPLACE(@PositionString, '4', REPLICATE('$', 4))
	SET @PositionString = REPLACE(@PositionString, '3', REPLICATE('$', 3))
	SET @PositionString = REPLACE(@PositionString, '2', REPLICATE('$', 2))
	SET @PositionString = REPLACE(@PositionString, '1', REPLICATE('$', 1))
	SET @PositionString = REPLACE(@PositionString, '/', '')

	-- --------------------------------------------------------------
	-- Step 2: Update position
	-- --------------------------------------------------------------

	UPDATE [Infrastructure].[GameBoard]
	SET 
		[IsPlayerWhite]	= CASE SUBSTRING(@PositionString, [EFNPositionNr], 1)
			WHEN '$' COLLATE Latin1_General_CS_AI THEN NULL
			WHEN 'r' COLLATE Latin1_General_CS_AI THEN 'FALSE'
			WHEN 'R' COLLATE Latin1_General_CS_AI THEN 'TRUE'
			WHEN 'n' COLLATE Latin1_General_CS_AI THEN 'FALSE'
			WHEN 'N' COLLATE Latin1_General_CS_AI THEN 'TRUE'
			WHEN 'b' COLLATE Latin1_General_CS_AI THEN 'FALSE'
			WHEN 'B' COLLATE Latin1_General_CS_AI THEN 'TRUE'
			WHEN 'q' COLLATE Latin1_General_CS_AI THEN 'FALSE'
			WHEN 'Q' COLLATE Latin1_General_CS_AI THEN 'TRUE'
			WHEN 'k' COLLATE Latin1_General_CS_AI THEN 'FALSE'
			WHEN 'K' COLLATE Latin1_General_CS_AI THEN 'TRUE'
			WHEN 'p' COLLATE Latin1_General_CS_AI THEN 'FALSE'
			WHEN 'P' COLLATE Latin1_General_CS_AI THEN 'TRUE'
			END
		, [FigureLetter] = CASE SUBSTRING(@PositionString, [EFNPositionNr], 1)
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
		, [FigureUTF8] = CASE SUBSTRING(@PositionString, [EFNPositionNr], 1)
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
	

	-- --------------------------------------------------------------
	-- Step 3: next player
	-- --------------------------------------------------------------

	SET @NextPlayer = LEFT(@MetaString, 1)


	-- --------------------------------------------------------------
	-- Step 4: Observe castling rights
	-- --------------------------------------------------------------

	SET @MetaString		= RIGHT(@MetaString, LEN(@MetaString) - 2)
	SET @Castling		= TRIM(LEFT(@MetaString, CHARINDEX(' ', @MetaString, 1)))
	SET @MetaString		= RIGHT(@MetaString, LEN(@MetaString) - CHARINDEX(' ', @MetaString, 1))

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
	-- Step 5: note en-passant
	---- --------------------------------------------------------------

	SET @MetaString		= TRIM(LEFT(@MetaString, CHARINDEX(' ', @MetaString, 1)))
	SET @MetaString		= RIGHT(@MetaString, LEN(@MetaString) - CHARINDEX(' ', @MetaString, 1))

	IF @MetaString = '-'
	BEGIN
		SET @EnPassantField = NULL
	END
	ELSE
	BEGIN
		SET @EnPassantField = (	SELECT [Field]
								FROM [Infrastructure].[GameBoard]
								WHERE 1 = 1
									AND [Column]	= LEFT(@MetaString, 1)
									AND [Row]		= RIGHT(@MetaString, 1)
							)
	END

	-- --------------------------------------------------------------
	-- Step 6: 50-count rule
	---- --------------------------------------------------------------

	SET @MetaString		= TRIM(LEFT(@MetaString, CHARINDEX(' ', @MetaString, 1)))
	SET @MetaString		= RIGHT(@MetaString, LEN(@MetaString) - CHARINDEX(' ', @MetaString, 1))

	SET @FiftyMovesRule = CONVERT(TINYINT, @MetaString)

	UPDATE [CurrentGame].[GameStatus]
	SET [Number50ActionsRule] = @FiftyMovesRule
	
	-- --------------------------------------------------------------
	-- Step 7: action number
	---- --------------------------------------------------------------

	SET @MetaString		= TRIM(LEFT(@MetaString, CHARINDEX(' ', @MetaString, 1)))
	SET @ActionCounter	= CONVERT(INTEGER, @MetaString)

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
        (0, 1, NULL, 'EFN', 'EFN', 'EFN', 'FALSE', @EFN)

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
           (0, 0, NULL, 'EFN', 'EFN', 'EFN', 'FALSE', @EFN)
	END

	SELECT * FROM [Infrastructure].[vDashboard]


END
GO



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistics ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '611 - Procedure [Infrastruktur].[prcEFNString2Position].sql'
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

SET @EFN = 'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR w KkQq a3 3 1'
--'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
--SET @EFN = '6r1/6pp/7r/1B5K/1P3k2/N7/3R4/8 w - - 30 79'

EXECUTE [Infrastructure].[prcEFNString2Position] @EFN
GO

*/
 