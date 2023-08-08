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
	DECLARE @Loop				AS TINYINT
	DECLARE @StringPart				AS VARCHAR(8)
	DECLARE @ID						AS TINYINT
	DECLARE @Letter					AS CHAR(1)
	DECLARE @IsPlayerWhite			AS BIT
	DECLARE @EnPassantField			AS TINYINT
	DECLARE @FiftyMovesRule			AS TINYINT
	DECLARE @ActionCounter				AS INTEGER

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

	CREATE TABLE #TempPosition2([ID] TINYINT NOT NULL, [Position] [VARCHAR](8) NOT NULL) 

	DECLARE curEFN CURSOR FOR   
		SELECT [ID], [Value]
		FROM #TempPosition
		ORDER BY [ID] DESC;  

	OPEN curEFN
  
	FETCH NEXT FROM curEFN INTO @ID, @StringPart
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		SET @PositionString	= ''
		SET @Loop			= 1
		WHILE @Loop<= 8
		BEGIN
			SET @Letter			= SUBSTRING(@StringPart, 1, 1)

			IF ISNUMERIC(@Letter) = 1
			BEGIN
				SET @PositionString	= @PositionString + REPLICATE('$', CONVERT(TINYINT, @Letter))
				SET @Loop			= @Loop+ CONVERT(TINYINT, @Letter) 
			END
			ELSE
			BEGIN
				SET @PositionString	= @PositionString + @Letter
				SET @Loop			= @Loop+ 1
			END

			SET @StringPart = RIGHT(@StringPart, LEN(@StringPart) - 1)

		END		

		INSERT INTO #TempPosition2([ID], [Position])
		SELECT @ID, @PositionString

		FETCH NEXT FROM curEFN INTO @ID, @StringPart
	END
	CLOSE curEFN;  
	DEALLOCATE curEFN; 


	-- --------------------------------------------------------------
	-- Step 3: Evaluate the position information of the figures
	-- --------------------------------------------------------------

	-- Now the information from the EFN string is converted into UPDATE statements.
	DECLARE curImoprt CURSOR FOR   
		SELECT [ID], [Position]
		FROM #TempPosition2
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
				IF @Letter <> @Letter COLLATE Latin1_General_CS_AI
				BEGIN
					SET @IsPlayerWhite = 'TRUE'
				END
				ELSE
				BEGIN
					SET @IsPlayerWhite = 'FALSE'
				END
			END

			UPDATE [Infrastructure].[GameBoard]
			SET	  [IsPlayerWhite]		= @IsPlayerWhite
				, [FigurBuchstabe]		= (SELECT	CASE @Letter
														WHEN '$' COLLATE Latin1_General_CS_AI THEN '?'
														WHEN 'r' COLLATE Latin1_General_CS_AI THEN 'T'
														WHEN 'R' COLLATE Latin1_General_CS_AI THEN 'T'
														WHEN 'n' COLLATE Latin1_General_CS_AI THEN 'S'
														WHEN 'N' COLLATE Latin1_General_CS_AI THEN 'S'
														WHEN 'b' COLLATE Latin1_General_CS_AI THEN 'L'
														WHEN 'B' COLLATE Latin1_General_CS_AI THEN 'L'
														WHEN 'q' COLLATE Latin1_General_CS_AI THEN 'D'
														WHEN 'Q' COLLATE Latin1_General_CS_AI THEN 'D'
														WHEN 'k' COLLATE Latin1_General_CS_AI THEN 'K'
														WHEN 'K' COLLATE Latin1_General_CS_AI THEN 'K'
														WHEN 'p' COLLATE Latin1_General_CS_AI THEN 'B'
														WHEN 'P' COLLATE Latin1_General_CS_AI THEN 'B'
													END
											)
				, [FigurUTF8]			= (SELECT	CASE @Letter
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
			WHERE [Feld] = (@Loop- 1) * 8 + @ID
			SET @Loop			= @Loop+ 1
			SET @StringPart = RIGHT(@StringPart, LEN(@StringPart) - 1)

		END		

		INSERT INTO #TempPosition2([ID], [Position])
		SELECT @ID, @PositionString

		FETCH NEXT FROM curImoprt INTO @ID, @StringPart
	END
	CLOSE curImoprt;  
	DEALLOCATE curImoprt; 
	
	DROP TABLE #TempPosition
	DROP TABLE #TempPosition2

	-- --------------------------------------------------------------
	-- Schritt 4: Notation und damit das Zugrecht anpassen
	-- --------------------------------------------------------------

	INSERT INTO [Spiel].[Notation]
        ([VollzugID]
        ,[IsPlayerWhite]
        ,[TheoretischeAktionenID]
        ,[LangeNotation]
        ,[KurzeNotationEinfach]
        ,[KurzeNotationKomplex]
        ,[ZugIstSchachgebot])
	VALUES
        (0, 1, (SELECT MIN([TheoretischeAktionenID]) FROM [Infrastruktur].[TheoretischeAktionen]), 'EFN', 'EFN', 'EFN', 'FALSE')

	IF LEFT(@EFN, 1) = 'w'
	BEGIN
		INSERT INTO [Spiel].[Notation]
           ([VollzugID]
           ,[IsPlayerWhite]
           ,[TheoretischeAktionenID]
           ,[LangeNotation]
           ,[KurzeNotationEinfach]
           ,[KurzeNotationKomplex]
           ,[ZugIstSchachgebot])
		VALUES
           (0, 0, (SELECT MIN([TheoretischeAktionenID]) FROM [Infrastruktur].[TheoretischeAktionen]), 'EFN', 'EFN', 'EFN', 'FALSE')
	END

	-- --------------------------------------------------------------
	-- Schritt 5: Rochaderecht beachten
	-- --------------------------------------------------------------

	SET @EFN			= RIGHT(@EFN, LEN(@EFN) - 2)
	SET @StringPart		= TRIM(LEFT(@EFN, CHARINDEX(' ', @EFN, 1)))
	SET @EFN			= RIGHT(@EFN, LEN(@EFN) - CHARINDEX(' ', @EFN, 1))

	UPDATE [Spiel].[Konfiguration]
	SET   [IstKurzeRochadeErlaubt] = 'FALSE'
		, [IstLangeRochadeErlaubt] = 'FALSE'

	IF CHARINDEX('k' COLLATE Latin1_General_CS_AI, @StringPart, 1) <> 0
	BEGIN
		UPDATE [Spiel].[Konfiguration]
		SET   [IstKurzeRochadeErlaubt]	= 'TRUE'
		WHERE [IsPlayerWhite]			= 'FALSE'
	END

	IF CHARINDEX('K' COLLATE Latin1_General_CS_AI, @StringPart, 1) <> 0
	BEGIN
		UPDATE [Spiel].[Konfiguration]
		SET   [IstKurzeRochadeErlaubt]	= 'TRUE'
		WHERE [IsPlayerWhite]			= 'TRUE'
	END

	IF CHARINDEX('q' COLLATE Latin1_General_CS_AI, @StringPart, 1) <> 0
	BEGIN
		UPDATE [Spiel].[Konfiguration]
		SET   [IstLangeRochadeErlaubt]	= 'TRUE'
		WHERE [IsPlayerWhite]			= 'FALSE'
	END

	IF CHARINDEX('Q' COLLATE Latin1_General_CS_AI, @StringPart, 1) <> 0
	BEGIN
		UPDATE [Spiel].[Konfiguration]
		SET   [IstLangeRochadeErlaubt]	= 'TRUE'
		WHERE [IsPlayerWhite]			= 'TRUE'
	END
	
	-- --------------------------------------------------------------
	-- Schritt 6: en-passant beachten
	---- --------------------------------------------------------------

	SET @StringPart		= TRIM(LEFT(@EFN, CHARINDEX(' ', @EFN, 1)))
	SET @EFN			= RIGHT(@EFN, LEN(@EFN) - CHARINDEX(' ', @EFN, 1))

	IF @StringPart = '-'
	BEGIN
		SET @EnPassantField = NULL
	END
	ELSE
	BEGIN
		SET @EnPassantField = (	SELECT [Feld]
								FROM [Infrastruktur].[Spielbrett]
								WHERE 1 = 1
									AND [Spalte]	= LEFT(@StringPart, 1)
									AND [Reihe]		= RIGHT(@StringPart, 1)
							)
	END
	
	-- --------------------------------------------------------------
	-- Schritt 7: 50-Zuege-Regel
	---- --------------------------------------------------------------

	SET @StringPart		= TRIM(LEFT(@EFN, CHARINDEX(' ', @EFN, 1)))
	SET @EFN			= RIGHT(@EFN, LEN(@EFN) - CHARINDEX(' ', @EFN, 1))

	SET @FiftyMovesRule = CONVERT(TINYINT, @StringPart)
	
	-- --------------------------------------------------------------
	-- Schritt 8: Zugzahl
	---- --------------------------------------------------------------

	SET @StringPart		= TRIM(LEFT(@EFN, CHARINDEX(' ', @EFN, 1)))
	SET @ActionCounter		= CONVERT(INTEGER, @StringPart)

	SELECT * FROM [Infrastruktur].[vSpielbrett]


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

USE [arelium_TSQL_Schach_V012]
GO

DECLARE @EFN varchar(255)

--SET @EFN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
SET @EFN = '6r1/6pp/7r/1B5K/1P3k2/N7/3R4/8 w - - 30 79'

EXECUTE [Infrastruktur].[prcImportEFN] @EFN
GO

*/
 