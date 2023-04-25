-- ###########################################################################################
-- ### Spiel der Koenige - Workshopversion ###################################################
-- ###########################################################################################
-- ### Erstellung der Prozedur [Spiel].[prcMensch_vs_TSQL]                                 ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Dieses Skript erstellt oder aendert eine Prozedur, die dazu dient eine Partie       ###
-- ### Schach zwischen einem Menschen und dem T-SQL-Algorithmus zu starten.                ###
-- ###                                                                                     ###
-- ### Der Computer ueberwacht dabei zum einen die Regeln, zum anderen stellt er einen     ###
-- ### passenden Gegenspieler. Dabei kann ueber die zu mitzugebenen Parameter bspw. auf    ###
-- ### einen Schwierigkeitsgrad eingestellt werden. Hier ist von einem rein zufaelligen    ###
-- ### (aber regelkonformen) Gegenspiel bis zur taktischen Leistung eines Grossmeisters    ###
-- ### alles moeglich.                                                                     ###
-- ###                                                                                     ###
-- ### Der Computer zieht automatisch, wenn er das Zugrecht besitzt. Der menschliche       ###
-- ### Spieler ruft einfach die Prozedur [Spiel].[prcZugausfuehren] auf, wenn er an der    ###
-- ### Reihe ist.                                                                          ###
-- ###                                                                                     ###
-- ### Einige Zuege bedingen eine spezielle Eingabeform:                                   ###
-- ###    - eine Rochade wird nur ueber die Bewegung des Koenigs codiert, also bspw.       ###
-- ###      EXEC [Spiel].[prcZugAusfuehren] 'e1', 'g1', NULL, 'TRUE' fuer die kurze        ###
-- ###      Rochade von Weiss.                                                             ###
-- ###    - eine Bauernumwandlung erwartet verpflichtend einen sonst mit NULL zu           ###
-- ###      belegenden dritten Parameter. Beispiel EXEC [Weiss].[prcZugAusfuehren] 'e7',   ###
-- ###      'e8', 'D', 'TRUE'                                                              ###
-- ###                                                                                     ###
-- ### Die Prozedur fuehrt auch das Spielprotokoll in der langen Notation und aktualisiert ###
-- ### die Darstellung des Spielbrettes. Je nach Konfiguration wird abschliessend nicht    ###
-- ### nur der Partieverlauf gezeichnet sondern es werden auch Zugempfehlungen mit oder    ###
-- ### ohne Bewertungsangabe aufgelistet.                                                  ###
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
-- Erstellung der Prozedur [Spiel].[prcMensch_vs_TSQL]
-- -----------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [Spiel].[prcMensch_vs_TSQL] 
	(
		  @NameWeiss							AS NVARCHAR(30)
		, @NameSchwarz							AS NVARCHAR(30)
		, @SpielstaerkeSchwarz					AS TINYINT
		, @RestzeitWeissInSekunden				AS INTEGER
		, @RestzeitSchwarzInSekunden			AS INTEGER
		, @ComputerSchritteAnzeigenWeiss		AS BIT
		, @ComputerSchritteAnzeigenSchwarz		AS BIT
		, @Startquadrat							AS CHAR(2)
		, @Zielquadrat							AS CHAR(2)
		, @Umwandlungsfigur						AS CHAR(1)
		, @IstEnPassant							AS BIT
	)
AS
BEGIN

	-- Zuerst das Spielbrett aufbauen und die Infrastruktur konfigurieren
	EXECUTE [Spiel].[prcInitialisierung] 
		  @NameWeiss
		, @NameSchwarz
		, 1								-- fixer Wert, da WEISS immer ein menschlicher Spieler ist!
		, @SpielstaerkeSchwarz
		, @RestzeitWeissInSekunden
		, @RestzeitSchwarzInSekunden
		, @ComputerSchritteAnzeigenWeiss
		, @ComputerSchritteAnzeigenSchwarz

	-- Weiss macht den ersten Zug (dies ist der menschliche Spieler)
	EXECUTE [Spiel].[prcZugAusfuehren] 
		  @Startquadrat				= @Startquadrat
		, @Zielquadrat				= @Zielquadrat
		, @Umwandlungsfigur			= @Umwandlungsfigur
		, @IstEnPassant				= @IstEnPassant
		, @IstSpielerWeiss			= 'TRUE'

END
GO



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '520 - Prozedur [Spiel].[prcMensch_vs_TSQL] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO


/*  TEST DER PROZEDUR


USE [arelium_TSQL_Schach_V012]
GO

DECLARE	@return_value int

EXEC	[Spiel].[prcInitialisierung]

EXEC	@return_value = [Spiel].[prcZugAusfuehren]
		@Startquadrat = N'g1',
		@Zielquadrat = N'f3',
		@Umwandlungsfigur = NULL,
		@IstEnPassant = FALSE,
		@IstSpielerWeiss = TRUE

SELECT	'Return Value' = @return_value


*/