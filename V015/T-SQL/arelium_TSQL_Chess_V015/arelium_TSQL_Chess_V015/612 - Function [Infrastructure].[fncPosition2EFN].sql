-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### Function [Infrastructure].[fncPosition2EFN]                                         ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### The task is to generate an EFN string from a given position. According to the       ###
-- ### protocol, it should contain all the necessary information about all the pieces and  ###
-- ### their placement as well as their colour. In addition, information on the possible   ###
-- ### castling moves is expected. Information on whether an "en passant" move is          ###
-- ### currently possible in this position must also be given, as well as the counter for  ###
-- ### the 50-move rule. Finally, it is stated which move number comes next.               ###
-- ### Details under https://www.embarc.de/fen-forsyth-edwards-notation/                   ###
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

CREATE OR ALTER FUNCTION [Infrastructure].[fncPosition2EFN]
(
	  @IsPlayerWhite				AS BIT
	, @PossibleCastles				AS VARCHAR(4)
	, @WhereIsEnPassantPossible		AS VARCHAR(2)
	, @CounterRule50Moves			AS INTEGER
	, @NextActionNumber				AS INTEGER
	, @ValuationPosition			AS typePosition			READONLY
)
RETURNS VARCHAR(256)
AS
BEGIN
	DECLARE @ReturnValue			AS VARCHAR(256)
	DECLARE @Row					AS VARCHAR(8)
	DECLARE @ColumnCounter			AS CHAR(1)
	DECLARE @RowCounter				AS TINYINT

	-- --------------------------------------------------------------------------
	-- Step 1: 
	-- convert all fields per row, append them one after the other and then
	-- join all rows separated by "/".
	-- --------------------------------------------------------------------------
	SET @RowCounter			= 8
	SET @ReturnValue		= ''
	SET @Row				= ''

	WHILE @RowCounter >= 1
	BEGIN
		SET @Row = ''
		SET @ColumnCounter		= 'A'
		WHILE @ColumnCounter	<= 'H'
		BEGIN
			SET @Row = @Row + 
			(
				SELECT 
					CASE [IsPlayerWhite]
						WHEN 0 THEN	 [FigureLetter]
						WHEN 1 THEN
							CASE [FigureLetter]
								WHEN 'P'	THEN 'p'
								WHEN 'R'	THEN 'r'
								WHEN 'N'	THEN 'n'
								WHEN 'B'	THEN 'b'
								WHEN 'Q'	THEN 'q'
								WHEN 'K'	THEN 'k'
								ELSE '?'
							END
						ELSE  -- can also be NULL!
							'?'
					END
				FROM @ValuationPosition
				WHERE 1 = 1
					AND [Row]		= @RowCounter
					AND [Column]	= @ColumnCounter
			)
			
			SET @ColumnCounter = CHAR(ASCII(@ColumnCounter) + 1)
		END
		SET @ReturnValue = @ReturnValue + @Row + '/'
		SET @RowCounter = @RowCounter - 1
	END

	-- --------------------------------------------------------------------------
	-- Step 2: 
	-- Replace multiple consecutive empty fields by their number.
	-- --------------------------------------------------------------------------

	-- Remove the last separator again
	SET @ReturnValue = LEFT(@ReturnValue, LEN(@ReturnValue) - 1)

	SET @ReturnValue = 
		REPLACE(
			REPLACE(
				REPLACE(
					REPLACE(
						REPLACE(
							REPLACE(
								REPLACE(
									REPLACE(@ReturnValue, '????????', 8)
								, '???????', 7)
							, '??????', 6)
						, '?????', 5)
					, '????', 4)
				, '???', 3)
			, '??', 2)
		, '?', 1)

	-- --------------------------------------------------------------------------
	-- Step 3: 
	-- Attach the other meta information in the correct order. If 
	-- have not been specified, note a "-".
	-- --------------------------------------------------------------------------

	SET @ReturnValue = @ReturnValue + ' ' + CASE @IsPlayerWhite WHEN 'TRUE' THEN 'w' ELSE 'b' END
	SET @ReturnValue = @ReturnValue + ' ' + CASE @PossibleCastles WHEN NULL THEN '-' ELSE @PossibleCastles END
	SET @ReturnValue = @ReturnValue + ' ' + CASE @WhereIsEnPassantPossible WHEN '' THEN '-' ELSE @WhereIsEnPassantPossible END
	SET @ReturnValue = @ReturnValue + ' ' + CASE @CounterRule50Moves WHEN NULL THEN '-' ELSE CONVERT(VARCHAR(6), @CounterRule50Moves) END
	SET @ReturnValue = @ReturnValue + ' ' + CONVERT(VARCHAR(5), @NextActionNumber)

	RETURN @ReturnValue
END
GO			



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistics ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '612 - Function [Infrastructure].[fncPosition2EFN].sql'
PRINT ' '
PRINT 'Script     :   ' + @Script
PRINT 'End        :   ' + @End
PRINT 'Time       :   ' + @Time
SELECT @Script AS Skript, @End AS Ende, @Time AS Zeit
GO

/*
-- Test of function [Infrastructure].[fncPosition2EFN] 

USE [arelium_TSQL_Chess_V015]
GO

DECLARE @AGameBoard	AS [dbo].[typePosition]
INSERT INTO @AGameBoard
	SELECT 
		  1								AS [VariantNo]
		, 1								AS [SearchDepth]
		, [SB].[Column]					AS [Column]
		, [SB].[Row]					AS [Row]
		, [SB].[Field]					AS [Field]
		, [SB].[IsPlayerWhite]			AS [IsPlayerWhite]
		, [SB].[FigureLetter]			AS [FigureLetter]
		, [SB].[FigureUTF8]				AS [FigureUTF8]
	FROM [Infrastructure].[GameBoard]	AS [SB]

SELECT [Infrastructure].[fncPosition2EFN] 
	('TRUE', 'kKq', 'a3', 3, 1, @AGameBoard)
GO
*/
