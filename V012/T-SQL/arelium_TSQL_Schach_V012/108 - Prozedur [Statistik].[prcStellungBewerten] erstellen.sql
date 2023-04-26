-- ###########################################################################################
-- ### Spiel der Koenige - Workshopversion ###################################################
-- ###########################################################################################
-- ### Erstellung der Prozedur [Statistik].[prcStellungBewerten]                           ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Abhaengig von der Konfiguration sind verschiedene Kriterien fuer die Stellungs-     ###
-- ### bewertung heranzuziehen. Je besser diese Funktion ausbalanciert ist und je          ###
-- ### umfangreicher und zahlreicher die Untersuchungen durchgefuehrt werden, je genauer   ###
-- ### und aussagekraeftiger wird der ermittelte Wert. Ausfuehrliche Bewertungen haben     ###
-- ### allerdings eine negative Auswirkung auf die Laufzeit und den Ressourcenbedarf.      ###
-- ###                                                                                     ###
-- ### Die Prozedur arbeitet nicht mit der Tabelle [Infrastruktur].[Spielbrett] sondern    ###
-- ### bekommt eine Stellung ueber einen der Parameter mitgeliefert. So sind spaeter       ###
-- ### Bewertungen von hypothetischen Stellungen moeglich, so dass man mehrere Zuege in    ###
-- ### die Zukunft "gucken" kann.                                                          ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Sicherheitshinweis:                                                                 ###
-- ###      Ueber diese Befehlssammlung werden Datenbankobjekte angelegt, geaendert oder   ###
-- ###      geloescht. Auch koennen Inhalte hinzugefuegt, manipuliert oder entfernt        ###
-- ###      werden. In produktiven Umgebungen darf dieses Skript NICHT eingesetzt werden,  ###
-- ###      um versehentliche Auswirkungen auf sonstige Strukturen auszuschliessen.        ###
-- ###                                                                                     ###
-- ### Erstellung:                                                                         ###
-- ###      Torsten Ahlemeyer fuer arelium GmbH, www.arelium.de                            ###
-- ###      Kontakt: torsten.ahlemeyer@arelium.de                                          ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Aenderungsnachweis:                                                                 ###
-- ###     1.00.0	2023-02-27	Torsten Ahlemeyer                                          ###
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
-- Erstellung der Prozedur [Statistik].[prcStellungBewerten]
-- -----------------------------------------------------------------------------------------
-- Es werden die Tabelle [Spiel].[Konfiguration] ausgelesen, wo u.a. die 
-- Spielstaerke beider Spieler hinterlegt ist. Abhaengig von den hier genannten
-- Werten wird die Stellungsbewertung auf verschiedene Kriterien aufgebaut. Einzelheiten
-- hierzu finden sich in der Tabelle [Infrastruktur].[Spielstaerke].
CREATE OR ALTER PROCEDURE [Statistik].[prcStellungBewerten]
	  @IstSpielerWeiss			AS BIT
	, @Bewertungsstellung		AS typStellung READONLY
AS
BEGIN
	DECLARE @RueckgabeWert		AS FLOAT
	DECLARE @ASpielbrett		AS [dbo].[typStellung]
	DECLARE @AAktionen			AS [dbo].[typMoeglicheAktionen]

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

	INSERT INTO @AAktionen
	SELECT 
		  [TheoretischeAktionenID]
		, [HalbzugNr]
		, [FigurName]
		, [IstSpielerWeiss]
		, [StartSpalte]
		, [StartReihe]
		, [StartFeld]
		, [ZielSpalte]
		, [ZielReihe]
		, [ZielFeld]
		, [Richtung]
		, [UmwandlungsfigurBuchstabe]
		, [ZugIstSchlag]
		, [ZugIstKurzeRochade]
		, [ZugIstLangeRochade]
		, [ZugIstEnPassant]
		, [LangeNotation]
		, [KurzeNotationEinfach]
		, [KurzeNotationKomplex]
		, NULL
	FROM [Spiel].[MoeglicheAktionen]

	-- Es soll die Summe der Figurwerte einbezogen werden
	IF (SELECT [ZuberechnenSummeFigurWert] FROM [Infrastruktur].[Spielstaerke] AS [SST] 
			INNER JOIN [Spiel].[Konfiguration] AS [KON] ON [SST].[SpielstaerkeID] = [KON].[SpielstaerkeID]
			WHERE [KON].[IstSpielerWeiss] = [Spiel].[fncIstWeissAmZug]()) = 'TRUE'
	BEGIN
		UPDATE [Statistik].[Stellungsbewertung]
		SET 
				[Weiss]	= [Statistik].[fncFigurWertZaehlen] ('TRUE',	@ASpielbrett)
			, [Schwarz]	= [Statistik].[fncFigurWertZaehlen] ('FALSE',	@ASpielbrett)
		WHERE [Label] = 'Figurwert:'
	END
	ELSE
	BEGIN
		UPDATE [Statistik].[Stellungsbewertung]
		SET 
				[Weiss]	= NULL
			, [Schwarz]	= NULL
		WHERE [Label] = 'Figurwert:'
	END

	-- Es sollen die Aktionsmoeglichkeiten gezaehlt werden
	IF (SELECT [ZuberechnenAnzahlAktionen] FROM [Infrastruktur].[Spielstaerke] AS [SST] 
			INNER JOIN [Spiel].[Konfiguration] AS [KON] ON [SST].[SpielstaerkeID] = [KON].[SpielstaerkeID]
			WHERE [KON].[IstSpielerWeiss] = [Spiel].[fncIstWeissAmZug]()) = 'TRUE'
	BEGIN
		UPDATE [Statistik].[Stellungsbewertung]
		SET 
				[Weiss]	= (SELECT COUNT(*) FROM [Spiel].[fncMoeglicheAktionen]('TRUE', @ASpielbrett))
			, [Schwarz]	= (SELECT COUNT(*) FROM [Spiel].[fncMoeglicheAktionen]('FALSE', @ASpielbrett))
		WHERE [Label] = 'Anzahl Aktionen:'
	END
	ELSE
	BEGIN
		UPDATE [Statistik].[Stellungsbewertung]
		SET 
				[Weiss]	= NULL
			, [Schwarz]	= NULL
		WHERE [Label] = 'Figurwert:'
	END

	
	---- Es sollen die Schlagmoeglichkeiten gezaehlt werden
	--UPDATE [Statistik].[Stellungsbewertung]
	--SET 
	--		[Weiss]	= (SELECT COUNT(*) FROM [Spiel].[fncMoeglicheSchlaege]('TRUE', @ASpielbrett))
	--	, [Schwarz]	= (SELECT COUNT(*) FROM [Spiel].[fncMoeglicheSchlaege]('FALSE', @ASpielbrett))
	--WHERE [Label] = 'Anzahl Schlaege:'

	---- Es sollen die noch verbleibenden Rochademoeglichkeiten gezaehlt werden
	--UPDATE [Statistik].[Stellungsbewertung]
	--SET 
	--	  [Weiss]	= (SELECT CONVERT(TINYINT, [IstKurzeRochadeErlaubt]) + CONVERT(TINYINT, [IstLangeRochadeErlaubt]) FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = 'TRUE')
	--	, [Schwarz]	= (SELECT CONVERT(TINYINT, [IstKurzeRochadeErlaubt]) + CONVERT(TINYINT, [IstLangeRochadeErlaubt]) FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = 'FALSE')
	--WHERE [Label] = 'Anzahl Rochaden:'

	---- Aus allen Einzelmessungen ist nun ein Gesamtwert zu bilden
	--UPDATE [Statistik].[Stellungsbewertung]
	--SET 
	--	  [Weiss]	= 0
	--	, [Schwarz]	= [Statistik].[fncAktuelleStellungBewerten]()
	--WHERE [Label] = 'Gesamtbewertung:'
	
END
GO

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '108 - Prozedur [Statistik].[prcStellungBewerten] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO


/*
-- Test der Prozedur [Statistik].[prcStellungBewerten]

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



EXECUTE [Statistik].[prcStellungBewerten] 'TRUE',	@ASpielbrett
EXECUTE [Statistik].[prcStellungBewerten] 'FALSE',	@ASpielbrett
GO
*/
