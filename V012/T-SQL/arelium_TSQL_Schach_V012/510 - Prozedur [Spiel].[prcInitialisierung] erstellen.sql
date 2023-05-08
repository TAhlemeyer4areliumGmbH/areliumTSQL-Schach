-- ###########################################################################################
-- ### Spiel der Koenige - Workshopversion ###################################################
-- ###########################################################################################
-- ### Erstellung der Prozedur [Spiel].[prcInitialisierung]                                ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Wenn eine neues Spiel begonenn wird, sind einige Einstellungen festzulegen und      ###
-- ### Vorbereitungen zu treffen. So ist das Spielbrett aufzubauen, die Grundstellung      ###
-- ### einzunehmen, der aktive Spieler festzulegen, usw...                                 ###
-- ###                                                                                     ###
-- ### Ausserdem sind die Spieler zu konfigurieren: Namen, Spielstaerke, zu nutzende       ###
-- ### Hilfsfunktionen, ...                                                                ###
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
-- Erstellung der Prozedur [Spiel].[prcInitialisierung]
-- -----------------------------------------------------------------------------------------
-- Es werden die Tabelle [Spiel].[Konfiguration] ausgelesen, wo u.a. die 
-- Spielstaerke beider Spieler hinterlegt ist. Abhaengig von den hier genannten
-- Werten wird die Stellungsbewertung auf verschiedene Kriterien aufgebaut. Einzelheiten
-- hierzu finden sich in der Tabelle [Infrastruktur].[Spielstaerke].
CREATE OR ALTER PROCEDURE [Spiel].[prcInitialisierung]
	  @NameWeiss							AS NVARCHAR(30)
	, @NameSchwarz							AS NVARCHAR(30)
	, @IstSpielerMenschWeiss				AS BIT 
	, @IstSpielerMenschSchwarz				AS BIT 
	, @SpielstaerkeWeiss					AS TINYINT
	, @SpielstaerkeSchwarz					AS TINYINT
	, @RestzeitWeissInSekunden				AS INTEGER
	, @RestzeitSchwarzInSekunden			AS INTEGER
	, @ComputerSchritteAnzeigenWeiss		AS BIT
	, @ComputerSchritteAnzeigenSchwarz		AS BIT
	, @BedienungsanleitungAnzeigen			AS BIT
AS
BEGIN
	SET NOCOUNT ON;

	-- den Spielbrettverlauf saeubern
	TRUNCATE TABLE [Spiel].[Spielbrettverlauf]

	-- Spielbrett aufbauen
	EXECUTE [Infrastruktur].[prcGrundstellungAufbauen] 
	-- oder:
	-- EXECUTE [prcVorgabepartieAufbauen] 3
	-- EXECUTE [prcFischerRandomChessAufbauen] 

	-- Theoretische Zuege berechnen
	EXECUTE [Infrastruktur].[prcTheoretischeAktionenInitialisieren] 


	-- Spieler anlegen
	TRUNCATE TABLE [Spiel].[Konfiguration]

	INSERT INTO [Spiel].[Konfiguration]
		( [IstSpielerWeiss]
		, [Spielername]
		, [IstSpielerMensch]
		, [SpielstaerkeID]
		, [RestzeitInSekunden]
		, [ZeitpunktLetzterZug]
		, [ComputerSchritteAnzeigen]
		, [IstKurzeRochadeErlaubt]
		, [IstLangeRochadeErlaubt]
		   )
     VALUES
		  ('FALSE'	, @NameWeiss	, @IstSpielermenschWeiss	, @SpielstaerkeWeiss	, @RestzeitWeissInSekunden		, GETDATE(), @ComputerSchritteAnzeigenWeiss		, 'TRUE', 'TRUE')
		, ('TRUE'	, @NameSchwarz	, @IstSpielermenschSchwarz	, @SpielstaerkeSchwarz	, @RestzeitSchwarzInSekunden	, GETDATE(), @ComputerSchritteAnzeigenSchwarz	, 'TRUE', 'TRUE')
 
	-- zuerst das aktuelle Spielbrett in eine Variable einlesen
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

	-- Moegliche Zuege ermitteln
	EXECUTE [Spiel].[prcAktionenFuerAktuelleStellungWegschreiben] @IstSpielerWeiss = 'TRUE', @IstStellungZuBewerten = 'TRUE', @AktuelleStellung = @ASpielbrett

	-- Die Zughistorie loeschen
	TRUNCATE TABLE [Spiel].[Zugverfolgung]

	-- Die Bibliothek laden
	DROP TABLE IF EXISTS [Bibliothek].[aktuelleNachschlageoptionen]

	SELECT [PartiemetadatenID], [Zugnummer], [ZugWeiss], [ZugSchwarz]  
	INTO [Bibliothek].[aktuelleNachschlageoptionen]
	FROM [Bibliothek].[Grossmeisterpartien]

	-- ------------------------------------------
	-- Stellung bewerten
	-- ------------------------------------------

	-- Die Bedienungsanleitung wird ausgegeben, um menschliche Spieler zu unterstuetzen
	IF @BedienungsanleitungAnzeigen = 'TRUE'
	BEGIN
		SELECT [naechste Schritte] FROM [Infrastruktur].[vBedienungsanleitung] ORDER BY [ID] ASC
	END

	-- Die Statistiktabelle fuer die aktuelle Stellung aktualisieren
	EXECUTE [Statistik].[prcStellungBewerten] 'TRUE',	@ASpielbrett

	-- Das Spielbrett und die Statistiken anzeigen
	SELECT * FROM [Infrastruktur].[vSpielbrett]

END
GO



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '500 - Funktion [Spiel].[prcInitialisierung] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO

/*
USE [arelium_TSQL_Schach_V012]
GO

DECLARE @RC int

-- TODO: Set parameter values here.

EXECUTE @RC = [Spiel].[prcInitialisierung] 'Peter', 'Sandy', 1, 7, 800, 1200, 'TRUE', 'FALSE'
GO

*/