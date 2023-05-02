-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Zu einem bestimmten Zug in der Partiehistorie zurueck gehen                         ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Zu Uebungszwecken, beim testen oder im Spiel mit einem Neuling entsteht haeufig der ###
-- ### Wunsch einen oder mehrere Zuege einer Partie zurueckzunehmen. Diese Funktion ist in ###
-- ### regulaeren Spielen verboten! Sie fuehrt daher fuer das Punktekonto zum sofortigen   ###
-- ### Verlust der Partie.                                                                 ###
-- ###                                                                                     ###
-- ### Der Aufruf der Prozedur setzt die Angabe von zwei Parametern voraus:                ###
-- ###    - die Nummer des Vollzuges                                                       ###
-- ###    - die Information, ob als naechstes WEISS oder SCHWARZ zieht                     ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Sicherheitshinweis:                                                                 ###
-- ###      Ueber diese Befehlssammlung werden Datenbankobjekte angelegt, geaendert oder   ###
-- ###      geloescht. Auch koennen Inhalte hinzugefuegt, manipuliert oder entfernt        ###
-- ###      werden. In produktiven Umgebungen darf dieses Skript NICHT eingesetzt werden,  ###
-- ###      um versehentliche Auswirkungen auf sonstige Strukturen auszuschliessen.        ###
-- ###                                                                                     ###
-- ### Erstellung:                                                                         ###
-- ###      Torsten Ahlemeyer fuer arelium GmbH, (https://www.arelium.de)                  ###
-- ###      Kontakt: torsten.ahlemeyer@arelium.de                                          ###
-- ###      ----------------                                                               ###
-- ###      Ein grosser Dank geht an (MVP) Uwe Ricken, der dem Projekt mit mit Rat und     ###
-- ###      Tat vor allem (aber nicht nur) im Bereich der Laufzeitoptimierung zur Seite    ###
-- ###      stand und steht (https://www.db-berater.de/).                                  ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Aenderungsnachweis:                                                                 ###
-- ###     1.00.0	2023-02-07	Torsten Ahlemeyer                                          ###
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

--------------------------------------------------------------------------------------------------
-- Aufbauarbeiten --------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------


CREATE OR ALTER PROCEDURE [Spiel].[prcZurueckZuZug]
	  @VollzugID				BIGINT
	, @IstSpielerWeiss			BIT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @BSpielbrett			AS [dbo].[typStellung]

	IF @VollzugID <= (SELECT MAX([VollzugID]) FROM [Spiel].[Notation])
	BEGIN

		-- Die Notation anpassen
		DELETE FROM [Spiel].[Notation] WHERE [VollzugID] > @VollzugID
		IF @IstSpielerWeiss = 'FALSE'
		BEGIN
			DELETE FROM [Spiel].[Notation] WHERE [VollzugID] = @VollzugID AND [IstSpielerWeiss] = 'FALSE'
		END
	
		-- den Spielbrettverlauf anpassen
		DELETE FROM [Spiel].[Spielbrettverlauf] WHERE [VollzugID] > @VollzugID
		IF @IstSpielerWeiss = 'FALSE'
		BEGIN
			DELETE FROM [Spiel].[Spielbrettverlauf] WHERE [VollzugID] = @VollzugID AND [IstSpielerWeiss] = 'FALSE'
		END
	
		-- Das Spielbrett aktualisieren
		DELETE FROM [Infrastruktur].[Spielbrett]

		INSERT INTO [Infrastruktur].[Spielbrett](
			  [Spalte]
			, [Reihe]
			, [Feld]
			, [IstSpielerWeiss]
			, [FigurBuchstabe]
			, [FigurUTF8])
		SELECT 
			  [Spalte]
			, [Reihe]
			, [Feld]
			, [IstSpielerWeiss]
			, [FigurBuchstabe]
			, [FigurUTF8]
		FROM [Spiel].[Spielbrettverlauf]
		WHERE 1 = 1
			AND [VollzugID] = (SELECT MAX([VollzugID]) FROM [Spiel].[Spielbrettverlauf])
			AND [IstSpielerWeiss] = (@IstSpielerWeiss + 1) % 2

		-- Das Spielbrett darstellen
		SELECT * FROM [Infrastruktur].[vSpielbrett]


		-- Die aus der neuen Stellung moeglichen Zugvarianten ermitteln
		IF @IstSpielerWeiss = 'TRUE'
		BEGIN
			EXECUTE [Spiel].[prcAktionenFuerAktuelleStellungWegschreiben] @IstSpielerWeiss = 'FALSE', @IstStellungZuBewerten = 'TRUE', @AktuelleStellung = @BSpielbrett
		END
		ELSE
		BEGIN
			EXECUTE [Spiel].[prcAktionenFuerAktuelleStellungWegschreiben] @IstSpielerWeiss = 'TRUE', @IstStellungZuBewerten = 'TRUE', @AktuelleStellung = @BSpielbrett
		END

		-- evtl. den Schritt "moegliche Zuege ermitteln" auch an der Oberflaeche anzeigen
		IF 1 = 1
			AND (SELECT [ComputerSchritteAnzeigen]	FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = @IstSpielerWeiss) = 'TRUE'
			AND (SELECT [SpielstaerkeID]			FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = @IstSpielerWeiss) <> 1
		BEGIN
			PRINT 'moegliche Zuege ermitteln...'
		END
	
		-- Das aktuelle Brett einlesen
		INSERT INTO @BSpielbrett
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

		-- Statistiken aktualisieren
		IF (SELECT [ComputerSchritteAnzeigen] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = @IstSpielerWeiss) = 'TRUE'
		BEGIN
			EXECUTE [Statistik].[prcStellungBewerten] @IstSpielerWeiss,	@BSpielbrett
		END
		ELSE
		BEGIN
			UPDATE [Statistik].[Stellungsbewertung]
			SET		[Weiss] = NULL, [Schwarz] = NULL
		END

	END
END
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '413 - Prozedur [Spiel].[prcZurueckZuZug] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO





/*

USE [arelium_TSQL_Schach_V012]
GO

EXEC [Spiel].[prcRemisangebotAnnehmen]
GO

*/