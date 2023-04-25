-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Die aktuell moeglichen Zuege ermitteln und in einer Tabelle sichern                 ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Diese Prozedur liest die aktuelle Stellung aus und uebergibt sie der Funktion       ###
-- ### [Spiel].[fncMoeglicheAktionen]. Das Ergebnis wird in der Tabelle                    ###
-- ### [Spiel].[MoeglicheAktionen] persistiert, da es mehrfach (bspw. zur Bewertung der    ###
-- ### Stellung) benoetigt wird.                                                           ###
-- ###                                                                                     ###
-- ### Am Ende dieses Block gibt es eine (auskommentierte) Testroutine, mit der man fuer   ###
-- ### eine uebergebene Stellung testen kann, ob alle (und nur diese) gueltigen Zuege fuer ###
-- ### die genannten Figuren zurueck kommen.                                               ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Sicherheitshinweis:                                                                 ###
-- ###      Ueber diese Befehlssammlung werden Datenbankobjekte angelegt, geaendert oder   ###
-- ###      geloescht. Auch koennen Inhalte hinzugefuegt, manipuliert oder entfernt        ###
-- ###      werden. In produktiven Umgebungen darf dieses Skript NICHT eingesetzt werden,  ###
-- ###      um versehentliche Auswirkungen auf sonstige Strukturen auszuschliessen.        ###
-- ###                                                                                     ###
-- ### Erstellung:                                                                         ###
-- ###      Torsten Ahlemeyer fuer arelium GmbH, (https://www.arelium.de)                  ###
-- ###      ----------------                                                               ###
-- ###      Ein grosser Dank geht an (MVP) Uwe Ricken, der dem Projekt mit mit Rat und     ###
-- ###      Tat vor allem (aber nicht nur) im Bereich der Laufzeitoptimierung zur Seite    ###
-- ###      stand und steht (https://www.db-berater.de/).                                  ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Aenderungsnachweis:                                                                 ###
-- ###     1.00.0	2023-02-21	Torsten Ahlemeyer                                          ###
-- ###              Initiale Erstellung mit Default-Werten                                 ###
-- ###########################################################################################
-- ### COPYRIGHT-Hinweis (siehe https://creativecommons.org/licenses/by-nc-sa/3.0/de/)     ###
-- ###########################################################################################
-- ### Dieses Werk steht unter der CC-BY-NC-SA-Lizenz, d.h. es darf frei heruntergeladen,  ###
-- ### in jedwedem Format oder Medium vervielfaeltigt und unter den zum Original selben    ###
-- ### Lizenzbedingungen weiterverbreitet werden.                                          ###
-- ### Eine kommerzielle Nutzung ist hierbei allerdings ausgeschlossen. Das Werk darf      ###
-- ### veraendert werden und es duerfen eigenen Projekte auf diesem Code aufbauen.         ###
-- ### Es muessen angemessene Urheber- und Rechteangaben gemachen werden, einen Link zur   ###
-- ### Lizenz ist beizufuegen und Aenderungen sind kenntlich zu machen.                    ###
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
-- Kompatiblitaetsblock --------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

-- auf die Projekt-DB wechseln
USE [arelium_TSQL_Schach_V012]
GO

-- Gibt an, dass sich die Vergleichsoperatoren Gleich (=) und Ungleich (<>) bei Verwendung mit NULL-Werten in SQL Server 2019 (15.x) ISO-konform verhalten muessen.
-- ANSI NULLS ON ist neuer T-SQL Standard und wird in spaeteren Versionen festgeschrieben.
SET ANSI_NULLS ON
GO

-- Bewirkt, dass SQL Server die ISO-Regeln fuer Anfuehrungszeichen bei Bezeichnern und Literalzeichenfolgen befolgt.
SET QUOTED_IDENTIFIER ON
GO


-----------------------------
-- Aufraeumarbeiten ---------
-----------------------------
-- Dank des "CREATE OR ALTER"-Befehls ist ein vorheriges Loeschen des Datenbankobjektes 
-- nicht mehr noetig.

-----------------------------
-- Aufbauarbeiten -----------
-----------------------------

-- Diese Funktion erstellt und fuellt eine Tabelle mit allen Aktionen, die von der uebergebenen Stellung aus unter 
-- Beruecksichtigung der Spielregeln genutzt werden koennen. Auf Wunsch werden die einzelnen Zuege gleich noch bewertet
CREATE OR ALTER PROCEDURE [Spiel].[prcAktionenFuerAktuelleStellungWegschreiben]
	  @IstSpielerWeiss						AS BIT
	, @IstStellungZuBewerten				AS BIT
AS
BEGIN
	DECLARE @Bewertungsstellung					AS [dbo].[typStellung]

	INSERT INTO @Bewertungsstellung
		SELECT 
			  1								AS [VarianteNr]
			, 1								AS [Suchtiefe]
			, [SB].[Spalte]					AS [Spalte]
			, [SB].[Reihe]					AS [Reihe]
			, [SB].[Feld]					AS [Feld]
			, [SB].[IstSpielerWeiss]		AS [IstSpielerWeiss]
			, [FigurBuchstabe]				AS [FigurBuchstabe]
			, [SB].[FigurUTF8]				AS [FigurUTF8]
		FROM [Infrastruktur].[Spielbrett]	AS [SB]

	TRUNCATE TABLE [Spiel].[MoeglicheAktionen]

	INSERT INTO [Spiel].[MoeglicheAktionen]
           ([TheoretischeAktionenID]
           ,[HalbzugNr]
           ,[FigurName]
           ,[IstSpielerWeiss]
           ,[StartSpalte]
           ,[StartReihe]
           ,[StartFeld]
           ,[ZielSpalte]
           ,[ZielReihe]
           ,[ZielFeld]
           ,[Richtung]
           ,[UmwandlungsfigurBuchstabe]
           ,[ZugIstSchlag]
           ,[ZugIstKurzeRochade]
           ,[ZugIstLangeRochade]
           ,[ZugIstEnPassant]
           ,[LangeNotation]
           ,[KurzeNotationEinfach]
           ,[KurzeNotationKomplex])
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
		FROM [Spiel].[fncMoeglicheAktionen] (1, @Bewertungsstellung)

	IF @IstStellungZuBewerten = 'TRUE'
	BEGIN
		DECLARE @TheoretischeAktionenID AS BIGINT
		DECLARE curMoeglicheAktionen CURSOR FOR   
			SELECT [MA].[TheoretischeAktionenID]
			FROM [Spiel].[MoeglicheAktionen] AS [MA]

		OPEN curMoeglicheAktionen
  
		FETCH NEXT FROM curMoeglicheAktionen INTO @TheoretischeAktionenID
		WHILE @@FETCH_STATUS = 0  
		BEGIN 

			

			UPDATE [Spiel].[MoeglicheAktionen]
			SET [Bewertung] = 2
			WHERE [TheoretischeAktionenID] = @TheoretischeAktionenID

			FETCH NEXT FROM curMoeglicheAktionen INTO @TheoretischeAktionenID 
		END
		CLOSE curMoeglicheAktionen;  
		DEALLOCATE curMoeglicheAktionen; 
	END
	
END 
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '082 - Prozedur [Spiel].[prcAktuelleStellungBewerten] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO

