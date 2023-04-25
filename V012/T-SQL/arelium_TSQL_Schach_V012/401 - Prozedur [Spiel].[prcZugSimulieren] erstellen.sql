-- ###########################################################################################
-- ### Spiel der Koenige - Workshopversion ###################################################
-- ###########################################################################################
-- ### Erstellung der Prozedur [Spiel].[prcZugSimulieren]                                  ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Diese Prozedur fuehrt (virtuell) einen Zug aus - die per Tabellenwertvariable       ###
-- ### uebergebene Stellung wird um einen Zug weitergefuehrt und wieder per                ###
-- ### Tabellenwertvariable zurueckgegeben.                                                ###
-- ###                                                                                     ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Sicherheitshinweis:                                                                 ###
-- ###      Ueber diese Befehlssammlung werden Datenbankobjekte angelegt, geaendert oder   ###
-- ###      geloescht. Auch koennen Inhalte hinzugefuegt, manipuliert oder entfernt        ###
-- ###      werden. In produktiven Umgebungen darf dieses Skript NICHT eingesetzt werden,  ###
-- ###      um versehentliche Auswirkungen auf sonstige Strukturen auszuschliessen.        ###
-- ###                                                                                     ###
-- ### Erstellung:                                                                         ###
-- ###      Torsten Ahlemeyer fuer arelium GmbH, www.arelium.de                            ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Aenderungsnachweis:                                                                 ###
-- ###     1.00.0	2023-03-07	Torsten Ahlemeyer                                          ###
-- ###              Initiale Erstellung                                                    ###
-- ###########################################################################################


--------------------------------------------------------------------------------------------------
-- Statistiken -----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

-- temporaere Tabelle anlegen, um sich die Startzeit zu merken
BEGIN TRY
	DROP TABLE #Start
END TRY
BEGIN CATCH
END CATCH

CREATE TABLE #Start (StartTime DATETIME)
INSERT INTO #Start (StartTime) VALUES (GETDATE())



--------------------------------------------------------------------------------------------------
-- Nutzinhalt ------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

USE [arelium_TSQL_Schach_V012]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- -----------------------------------------------------------------------------------------
-- Erstellung der Prozedur [Spiel].[prcZugSimulieren]
-- -----------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [Spiel].[prcZugSimulieren]
(
	  @VorgaengerStellung					AS [dbo].[typStellung]	READONLY
	, @TheoretischeAktionID					AS BIGINT
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Wunschzug						AS [dbo].[typMoeglicheAktionen]
	DECLARE @Folgestellung					AS [dbo].[typStellung]

    DECLARE @FigurName						AS VARCHAR(20)
    DECLARE @IstSpielerWeiss				AS BIT
    DECLARE @StartSpalte					AS CHAR(1)
    DECLARE @StartReihe						AS INTEGER
    DECLARE @StartFeld						AS INTEGER
    DECLARE @ZielSpalte						AS CHAR(1)
    DECLARE @ZielReihe						AS INTEGER
    DECLARE @ZielFeld						AS INTEGER
    DECLARE @Richtung						AS CHAR(2)
    DECLARE @UmwandlungsfigurBuchstabe		AS CHAR(1)
    DECLARE @ZugIstSchlag					AS BIT
    DECLARE @ZugIstKurzeRochade				AS BIT
    DECLARE @ZugIstLangeRochade				AS BIT
    DECLARE @ZugIstEnPassant				AS BIT
    DECLARE @LangeNotation					AS VARCHAR(9)
    DECLARE @KurzeNotationEinfach			AS VARCHAR(8)
    DECLARE @KurzeNotationKomplex			AS VARCHAR(8)
	
	INSERT INTO @Folgestellung
		SELECT 
			  1								AS [VarianteNr]
			, 1								AS [Suchtiefe]
			, [SB].[Spalte]					AS [Spalte]
			, [SB].[Reihe]					AS [Reihe]
			, [SB].[Feld]					AS [Feld]
			, [SB].[IstSpielerWeiss]		AS [IstSpielerWeiss]
			, [SB].[FigurBuchstabe]			AS [FigurBuchstabe]
			, [SB].[FigurUTF8]				AS [FigurUTF8]
		FROM @VorgaengerStellung			AS [SB]

	INSERT INTO @Wunschzug
           ( [TheoretischeAktionenID]	, [HalbzugNr]					, [FigurName]			, [IstSpielerWeiss]		, [StartSpalte]	
		   , [StartReihe]				, [StartFeld]					, [ZielSpalte]			, [ZielReihe]			, [ZielFeld]
		   , [Richtung]					, [UmwandlungsfigurBuchstabe]	, [ZugIstSchlag]		, [ZugIstKurzeRochade]	, [ZugIstLangeRochade]
		   , [ZugIstEnPassant]			,[LangeNotation]				, [KurzeNotationEinfach], [KurzeNotationKomplex], [Bewertung])
	SELECT
        TheoretischeAktionenID
        , 0
        , FigurName
        , IstSpielerWeiss
        , StartSpalte
        , StartReihe
        , StartFeld
        , ZielSpalte
        , ZielReihe
        , ZielFeld
        , Richtung
        , UmwandlungsfigurBuchstabe
        , ZugIstSchlag
        , ZugIstKurzeRochade
        , ZugIstLangeRochade
        , ZugIstEnPassant
        , LangeNotation
        , KurzeNotationEinfach
        , KurzeNotationKomplex
		, NULL
	FROM [Infrastruktur].[TheoretischeAktionen]
	WHERE TheoretischeAktionenID = @TheoretischeAktionID

	SET @FigurName						= (SELECT [FigurName]					FROM @Wunschzug)
	SET @IstSpielerWeiss				= (SELECT [IstSpielerWeiss]				FROM @Wunschzug)
	SET @StartSpalte					= (SELECT [StartSpalte]					FROM @Wunschzug)
	SET @StartReihe						= (SELECT [StartReihe]					FROM @Wunschzug)
	SET @StartFeld						= (SELECT [StartFeld]					FROM @Wunschzug)
	SET @ZielSpalte						= (SELECT [ZielSpalte]					FROM @Wunschzug)
	SET @ZielReihe						= (SELECT [ZielReihe]					FROM @Wunschzug)
	SET @ZielFeld						= (SELECT [ZielFeld]					FROM @Wunschzug)
	SET @Richtung						= (SELECT [Richtung]					FROM @Wunschzug)
	SET @UmwandlungsfigurBuchstabe		= (SELECT [UmwandlungsfigurBuchstabe]	FROM @Wunschzug)
	SET @ZugIstSchlag					= (SELECT [ZugIstSchlag]				FROM @Wunschzug)
	SET @ZugIstKurzeRochade				= (SELECT [ZugIstKurzeRochade]			FROM @Wunschzug)
	SET @ZugIstLangeRochade				= (SELECT [ZugIstLangeRochade]			FROM @Wunschzug)
	SET @ZugIstEnPassant				= (SELECT [ZugIstEnPassant]				FROM @Wunschzug)
	SET @LangeNotation					= (SELECT [LangeNotation]				FROM @Wunschzug)
	SET @KurzeNotationEinfach			= (SELECT [KurzeNotationEinfach]		FROM @Wunschzug)
	SET @KurzeNotationKomplex			= (SELECT [KurzeNotationKomplex]		FROM @Wunschzug)

	-- -----------------------------------------------------------
	-- Fall 1: kurze Rochade
	-- -----------------------------------------------------------
	IF 
		((@StartFeld = 33 AND @ZielFeld = 49) OR (@StartFeld = 40 AND @ZielFeld = 56))
		AND @FigurName = 'Koenig'
	BEGIN
		IF @IstSpielerWeiss = 'TRUE'
		BEGIN
			-- den neuen Koenig setzen
			UPDATE @Folgestellung
			SET   [FigurUTF8]			= 9812
				, [FigurBuchstabe]		= 'K'
				, [IstSpielerWeiss]		= @IstSpielerWeiss
			WHERE [Feld] = 49

			-- den neuen Turm setzen
			UPDATE @Folgestellung
			SET   [FigurUTF8]			= 9814
				, [FigurBuchstabe]		= 'T'
				, [IstSpielerWeiss]		= @IstSpielerWeiss
			WHERE [Feld] = 41

			---- den alten Turm loeschen
			UPDATE @Folgestellung
			SET	  [FigurUTF8]			= 160
				, [FigurBuchstabe]		= ' '
				, [IstSpielerWeiss]		= NULL
			WHERE [Feld] = 57

			-- den alten Koenig loeschen
			UPDATE @Folgestellung
			SET	  [FigurUTF8]			= 160
				, [FigurBuchstabe]		= ' '
				, [IstSpielerWeiss]		= NULL
			WHERE [Feld] = 33
		END
		ELSE
		BEGIN
			-- den neuen Koenig setzen
			UPDATE @Folgestellung
			SET   [FigurUTF8]			= 9818
				, [FigurBuchstabe]		= 'K'
				, [IstSpielerWeiss]		= @IstSpielerWeiss
			WHERE [Feld] = 56

			-- den neuen Turm setzen
			UPDATE @Folgestellung
			SET   [FigurUTF8]			= 9820
				, [FigurBuchstabe]		= 'T'
				, [IstSpielerWeiss]		= @IstSpielerWeiss
			WHERE [Feld] = 48

			---- den alten Turm loeschen
			UPDATE @Folgestellung
			SET	  [FigurUTF8]			= 160
				, [FigurBuchstabe]		= ' '
				, [IstSpielerWeiss]		= NULL
			WHERE [Feld] = 64

			-- den alten Koenig loeschen
			UPDATE @Folgestellung
			SET	  [FigurUTF8]			= 160
				, [FigurBuchstabe]		= ' '
				, [IstSpielerWeiss]		= NULL
			WHERE [Feld] = 40
		END
	END
	ELSE
	BEGIN
		-- -----------------------------------------------------------
		--Fall 2: lange Rochade
		-- -----------------------------------------------------------
		IF
			((@StartFeld = 33 AND @ZielFeld = 17) OR (@StartFeld = 40 AND @ZielFeld = 24))
			AND @FigurName = 'Koenig'
		BEGIN
			IF @IstSpielerWeiss = 'TRUE'
			BEGIN
				-- den neuen Koenig setzen
				UPDATE @Folgestellung
				SET   [FigurUTF8]			= 9812
					, [FigurBuchstabe]		= 'K'
					, [IstSpielerWeiss]		= @IstSpielerWeiss
				WHERE [Feld] = 17

				-- den neuen Turm setzen
				UPDATE @Folgestellung
				SET   [FigurUTF8]			= 9814
					, [FigurBuchstabe]		= 'T'
					, [IstSpielerWeiss]		= @IstSpielerWeiss
				WHERE [Feld] = 25

				---- den alten Turm loeschen
				UPDATE @Folgestellung
				SET	  [FigurUTF8]			= 160
					, [FigurBuchstabe]		= ' '
					, [IstSpielerWeiss]		= NULL
				WHERE [Feld] = 1

				-- den alten Koenig loeschen
				UPDATE @Folgestellung
				SET	  [FigurUTF8]			= 160
					, [FigurBuchstabe]		= ' '
					, [IstSpielerWeiss]		= NULL
				WHERE [Feld] = 33
			END
			ELSE
			BEGIN
				-- den neuen Koenig setzen
				UPDATE @Folgestellung
				SET   [FigurUTF8]			= 9818
					, [FigurBuchstabe]		= 'K'
					, [IstSpielerWeiss]		= @IstSpielerWeiss
				WHERE [Feld] = 24

				-- den neuen Turm setzen
				UPDATE @Folgestellung
				SET   [FigurUTF8]			= 9820
					, [FigurBuchstabe]		= 'T'
					, [IstSpielerWeiss]		= @IstSpielerWeiss
				WHERE [Feld] = 33

				---- den alten Turm loeschen
				UPDATE @Folgestellung
				SET	  [FigurUTF8]			= 160
					, [FigurBuchstabe]		= ' '
					, [IstSpielerWeiss]		= NULL
				WHERE [Feld] = 8

				-- den alten Koenig loeschen
				UPDATE @Folgestellung
				SET	  [FigurUTF8]			= 160
					, [FigurBuchstabe]		= ' '
					, [IstSpielerWeiss]		= NULL
				WHERE [Feld] = 40
			END
		END
		ELSE
		BEGIN
			-- -----------------------------------------------------------
			-- Fall 3: Bauernumwandlung
			-- -----------------------------------------------------------
			IF @UmwandlungsfigurBuchstabe IS NOT NULL
			BEGIN
				-- die neue Figur (D, L, S oder T) setzen
				UPDATE @Folgestellung
				SET   [FigurUTF8]			= (	SELECT [FigurUTF8] 
												FROM [Infrastruktur].[Figur]
												WHERE 1 = 1
													AND [FigurBuchstabe] = @UmwandlungsfigurBuchstabe 
													AND [IstSpielerWeiss] = @IstSpielerWeiss
												)
					, [FigurBuchstabe]		= @UmwandlungsfigurBuchstabe
					, [IstSpielerWeiss]		= @IstSpielerWeiss
				WHERE [Feld] = @Zielfeld

				-- den alten Bauern loeschen
				UPDATE @Folgestellung
				SET	  [FigurUTF8]			= 160
					, [FigurBuchstabe]		= ' '
					, [IstSpielerWeiss]		= NULL
				WHERE [Feld] = @Startfeld
			END
			ELSE
			BEGIN
				-- -----------------------------------------------------------
				-- Fall 4: en passant
				-- -----------------------------------------------------------
				IF @ZugIstEnPassant = 'TRUE'
				BEGIN
					-- den neuen Bauern setzen
					UPDATE @Folgestellung
					SET   [FigurUTF8]			= (	SELECT TOP 1 [FigurUTF8] 
													FROM @VorgaengerStellung
													WHERE 1 = 1
														AND [FigurBuchstabe] = 'B' 
														AND [IstSpielerWeiss] = @IstSpielerWeiss
													)
						, [FigurBuchstabe]		= 'B'
						, [IstSpielerWeiss]		= @IstSpielerWeiss
					WHERE [Feld] = @Zielfeld

					-- die (2!) alten Bauern loeschen
					UPDATE @Folgestellung
					SET	  [FigurUTF8]			= 160
						, [FigurBuchstabe]		= ' '
						, [IstSpielerWeiss]		= NULL
					WHERE	   [Feld] = @Startfeld 
							OR [Feld] = (CASE [IstSpielerWeiss] 
										WHEN 'TRUE'	THEN @Zielfeld + 1
										ELSE @Zielfeld - 1
										END)
				END
				ELSE
				BEGIN
					-- -----------------------------------------------------------
					-- Fall 5: Standardzug
					-- -----------------------------------------------------------
						
					-- die neuen Figur setzen
					UPDATE @Folgestellung
					SET   [FigurUTF8]			= (	SELECT [FigurUTF8] 
													FROM @VorgaengerStellung
													WHERE [Feld] = @Startfeld
													)
						, [FigurBuchstabe]		= (	SELECT [FigurBuchstabe] 
													FROM @VorgaengerStellung
													WHERE [Feld] = @Startfeld
													)
						, [IstSpielerWeiss]		= @IstSpielerWeiss
					WHERE [Feld] = @Zielfeld

					-- die alten Figur loeschen
					UPDATE @Folgestellung
					SET	  [FigurUTF8]			= 160
						, [FigurBuchstabe]		= ' '
						, [IstSpielerWeiss]		= NULL
					WHERE [Feld] = @Startfeld 
				END
			END
		END
	END

	-- neue Stellung ausgeben
	SELECT 
		[Spalte], [Reihe], [Feld], [IstSpielerWeiss], [FigurBuchstabe], [FigurUTF8]
	FROM @Folgestellung
END
GO

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '401 - Prozedur [Spiel].[prcZugSimulieren] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO

/*
-- Test der Funktion [Spiel].[prcZugSimulieren]
USE [arelium_TSQL_Schach_V012]
GO

DECLARE @ASpielbrett	AS [dbo].[typStellung]
INSERT INTO @ASpielbrett
	SELECT 
		  1								AS [VarianteNr]
		, 1								AS [Suchtiefe]
		, [SB].[Spalte]					AS [Spalte]
		, [SB].[Reihe]					AS [Reihe]
		, [SB].[Feld]					AS [Feld]
		, [SB].[IstSpielerWeiss]		AS [IstSpielerWeiss]
		, [SB].[FigurBuchstabe]			AS [FigurBuchstabe]
		, [SB].[FigurUTF8]				AS [FigurUTF8]
	FROM [Infrastruktur].[Spielbrett]	AS [SB]

DECLARE @TheoretischeAktionID bigint
SET @TheoretischeAktionID = 14681  -- Springer b1 nach c3

EXECUTE [Spiel].[prcZugSimulieren] 
   @ASpielbrett
  ,@TheoretischeAktionID
GO



*/