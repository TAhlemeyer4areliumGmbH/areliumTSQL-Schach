-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Aufbau der Grundstellung                                                            ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Dieses Skript leert das Spielfeld und baut alle Figuren eines Schachspiels derart   ###
-- ### auf, dass die laut Spielreglen einzunehmende Grundstellung erreicht wird.           ###
-- ###                                                                                     ###
-- ### Weiss spielt von Reihe 1 nach Reihe 8, Schwarz spielt entgegengesetzt. Auf der      ###
-- ### Grundreihe beider Farben stehen von A-H folgende Figuren: (T), (S), (L), (D), (K),  ###
-- ### (L), (S), (T)  mit T=Turm, S=Springer, L=Laeufer, D=Dame und K=Koenig. Auf der      ###
-- ### Reihe 2 (Weiss) bzgw. Reihe 7 (Schwarz) befinden sich ausschliesslich Bauern        ###
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

-- Die UPDATE-Befehle werden in eine Prozedur ausgelagert und sind daher bequem von 
-- ueberall aus einfach aufrufbar
CREATE OR ALTER PROCEDURE [Infrastruktur].[prcGrundstellungAufbauen]
AS
BEGIN
	SET NOCOUNT ON;

-- Alle Felder werden initial mit einem geschuetzten Leerzeichen besetzt. So wird quasi das 
-- leere Spielbrett aufgestellt. Die Figuren werden in einem spaeteren Schritt zugefuegt...
-- Das Einfuegen geschieht in zwei ineinander verschachtelten Schleifen, da die Angaben fuer
-- Reihen und Spalten jeweils hochgezaehlt werden muessen
	TRUNCATE TABLE [Infrastruktur].[Spielbrett]

	DECLARE @SchleifeReihe		AS INTEGER
	DECLARE @SchleifeSpalte		AS CHAR(1)
	DECLARE @Feld				AS INTEGER

	SET @SchleifeSpalte = 'A'

	WHILE ASCII(@SchleifeSpalte) BETWEEN ASCII('A') AND ASCII('H')
	BEGIN
		SET @SchleifeReihe = 1
		WHILE @SchleifeReihe BETWEEN 1 AND 8
		BEGIN
			SET @FELD = ((ASCII(@SchleifeSpalte) - 65) * 8) + @SchleifeReihe
			INSERT INTO [Infrastruktur].[Spielbrett] ([Spalte], [Reihe], [Feld], [IstSpielerWeiss], [FigurBuchstabe], [FigurUTF8])
				VALUES (@SchleifeSpalte, @SchleifeReihe, @Feld, NULL, CHAR(160), 160)
		
			SET @SchleifeReihe = @SchleifeReihe + 1
		END
		SET @SchleifeSpalte = CHAR(ASCII(@SchleifeSpalte) + 1)
	END

	-- ----------------------------------------------------
	-- Alle Felder leeren
	-- ----------------------------------------------------
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 160, [FigurBuchstabe] = ' ', [IstSpielerWeiss] = NULL

	-- ----------------------------------------------------
	-- weisse Bauern auf der 2. Reihe 
	-- ----------------------------------------------------
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9817, [FigurBuchstabe] = 'B', [IstSpielerWeiss] = 'TRUE' 
	WHERE	1 = 1
		AND [Reihe]		= 2

	-- ----------------------------------------------------
	-- schwarze Bauern auf der 7. Reihe 
	-- ----------------------------------------------------
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9823, [FigurBuchstabe] = 'B', [IstSpielerWeiss] = 'FALSE'
	WHERE	1 = 1
		AND [Reihe]		= 7
				

	-- ----------------------------------------------------
	-- weisse Tuerme in Grundposition 
	-- ----------------------------------------------------
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9814 , [FigurBuchstabe] = 'T', [IstSpielerWeiss] = 'TRUE'
	WHERE	1 = 1
		AND [Reihe]		= 1
		AND [Spalte]	IN ('A', 'H')

	-- ----------------------------------------------------
	-- schwarze Tuerme in Grundposition
	-- ----------------------------------------------------
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9820, [FigurBuchstabe] = 'T', [IstSpielerWeiss] = 'FALSE'
	WHERE	1 = 1
		AND [Reihe]		= 8
		AND [Spalte]	IN ('A', 'H')

	-- ----------------------------------------------------
	-- weisse Springer in Grundposition
	-- ----------------------------------------------------
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9816, [FigurBuchstabe] = 'S', [IstSpielerWeiss] = 'TRUE'
	WHERE	1 = 1
		AND [Reihe]		= 1
		AND [Spalte]	IN ('B', 'G')

	-- ----------------------------------------------------
	-- schwarze Springer in Grundposition
	-- ----------------------------------------------------
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9822, [FigurBuchstabe] = 'S', [IstSpielerWeiss] = 'FALSE'
	WHERE	1 = 1
		AND [Reihe]		= 8
		AND [Spalte]	IN ('B', 'G')

	-- ----------------------------------------------------
	-- weisse Laeufer in Grundposition
	-- ----------------------------------------------------
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9815, [FigurBuchstabe] = 'L', [IstSpielerWeiss] = 'TRUE'
	WHERE	1 = 1
		AND [Reihe]		= 1
		AND [Spalte]	IN ('C', 'F')

	-- ----------------------------------------------------
	-- schwarze Laeufer in Grundposition
	-- ----------------------------------------------------
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9821, [FigurBuchstabe] = 'L', [IstSpielerWeiss] = 'FALSE'
	WHERE	1 = 1
		AND [Reihe]		= 8
		AND [Spalte]	IN ('C', 'F')

	-- ----------------------------------------------------
	-- weisse Dame in Grundposition
	-- ----------------------------------------------------
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9813, [FigurBuchstabe] = 'D', [IstSpielerWeiss] = 'TRUE' 
	WHERE	1 = 1
		AND [Reihe]		= 1
		AND [Spalte]	= 'D'

	-- ----------------------------------------------------
	-- schwarze Dame in Grundposition
	-- ----------------------------------------------------
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9819, [FigurBuchstabe] = 'D', [IstSpielerWeiss] = 'FALSE'
	WHERE	1 = 1
		AND [Reihe]		= 8
		AND [Spalte]	= 'D'

	-- ----------------------------------------------------
	-- weisser Koenig in Grundposition
	-- ----------------------------------------------------
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9812, [FigurBuchstabe] = 'K', [IstSpielerWeiss] = 'TRUE'
	WHERE	1 = 1
		AND [Reihe]		= 1
		AND [Spalte]	= 'E'

	-- ----------------------------------------------------
	-- schwarzer Koenig in Grundposition
	-- ----------------------------------------------------
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9818, [FigurBuchstabe] = 'K', [IstSpielerWeiss] = 'FALSE' 
	WHERE 1 = 1
		AND [Reihe]		= 8
		AND [Spalte]	= 'E'



	-- Alle Einträge dieses Spiels aus der Tabelle [Spiel].[Notation] löschen
	DELETE 
	FROM [Spiel].[Notation]
	WHERE 1 = 1


END
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '021 - Prozedur [Infrastruktur].[prcGrundstellungAufbauen] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO





/*


-- Aufbau der Grundstellung:
-- Auf das leere Brett werden die einzelnen Figuren an ihre Startposition gesetzt. Dazu wird das 
-- passende Feld mit dem UTF-8-Wert der Spielfigur aktualisiert.
EXEC [Infrastruktur].[prcGrunstellungAufbauen]
GO

*/