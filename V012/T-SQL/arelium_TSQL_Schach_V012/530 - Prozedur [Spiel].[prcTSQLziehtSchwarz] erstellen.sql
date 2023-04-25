-- ###########################################################################################
-- ### Spiel der Koenige - Workshopversion ###################################################
-- ###########################################################################################
-- ### Erstellung der Prozedur [Spiel].[prcTSQLziehtSchwarz]                               ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Dieses Skript erstellt oder aendert eine Prozedur, die je nach eingestelltem        ###
-- ### Schwierigkeitsgrad einen Zug mit den SCHWARZEN Steinen ausfuehrt.                   ### 
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
-- Erstellung der Prozedur [Spiel].[prcTSQLziehtSchwarz]
-- -----------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [Spiel].[prcTSQLziehtSchwarz] 
AS
BEGIN
	DECLARE @Computerzug						AS [dbo].[typMoeglicheAktionen] 
	DECLARE @StartquadratComputerzug			AS CHAR(2)
	DECLARE @ZielquadratComputerzug				AS CHAR(2)
	DECLARE @UmwandlungsfigurComputerzug		AS CHAR(1)
	DECLARE @IstEnPassantComputerzug			AS BIT



	IF (SELECT [SpielstaerkeID] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = 'FALSE') = 2				-- zufaelliger Zug
	BEGIN
		
		INSERT INTO @Computerzug
			([TheoretischeAktionenID], [HalbzugNr], [FigurName], [IstSpielerWeiss], [StartSpalte], [StartReihe]
			,[StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung], [UmwandlungsfigurBuchstabe]
			,[ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade], [ZugIstEnPassant], [LangeNotation]
			,[KurzeNotationEinfach], [KurzeNotationKomplex], [Bewertung])
		SELECT TOP 1
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
			, [Bewertung]
		FROM [arelium_TSQL_Schach_V012].[Spiel].[MoeglicheAktionen]
		ORDER BY NEWID()

		-- diesen Zug jetzt ausfuehren
		SET @StartquadratComputerzug		= (SELECT TOP 1 [StartSpalte] + CONVERT(CHAR(1), [StartReihe]) FROM @Computerzug)
		SET @ZielquadratComputerzug			= (SELECT TOP 1 [ZielSpalte] + CONVERT(CHAR(1), [ZielReihe]) FROM @Computerzug)
		SET @UmwandlungsfigurComputerzug	= (SELECT TOP 1 [UmwandlungsfigurBuchstabe] FROM @Computerzug)
		SET @IstEnPassantComputerzug		= (SELECT TOP 1 [ZugIstEnPassant] FROM @Computerzug)

		EXECUTE [Spiel].[prcZugAusfuehren] 
			  @StartquadratComputerzug
			, @ZielquadratComputerzug
			, @UmwandlungsfigurComputerzug
			, @IstEnPassantComputerzug
			, 'FALSE'
	END

END
GO
------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '530 - Prozedur [Spiel].[prcTSQLziehtSchwarz] erstellen.sql'
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