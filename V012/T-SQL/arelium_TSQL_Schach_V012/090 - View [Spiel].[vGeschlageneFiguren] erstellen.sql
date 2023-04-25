-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Erstellung der Sicht [Spiel].[vGeschlageneFiguren]                                  ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Es sollen die im Vergleich zur Startposition gefallenen Figuren aufgelistet werden. ###
-- ### Dazu sind je Farbe zwei Reihen grafisch darzustellen: die geschlagenen Bauern und   ###
-- ### die geschlagenen sonstigen Figuren. Figuren, die durch Bauernumwandlung auf das     ###
-- ### Brett gelangt sind, werden nicht gezaehlt (aber die umgewandelten Bauern sehr       ###
-- ### wohl).                                                                              ###
-- ###                                                                                     ###
-- ### Im Ergebnis ist eine Spalte "ID" enthalten. Sie dient der JOIN-Moeglichkeit, um     ###
-- ### die einzelnen Bloecke des Amaturenbrettes (der Gesamtansicht aus Brett,             ###
-- ### Zugvorschau, geschlagenen Figuren, Statistiken zur Stellungsbewertung, ...). Die    ###
-- ### grafische Darstellung der Figuren nutzt die REPLICATE-Anweisung, um die richtige    ###
-- ### Anzahl an Elementen hintereinander zu haengen.                                      ###
-- ###                                                                                     ###
-- ### Am Ende dieses Block gibt es eine (auskommentierte) Testroutine, mit der man fuer   ###
-- ### eine uebergebene Stellung testen kann, ob alle (und nur diese) gueltigen Zuege fuer ###
-- ### die genannte Figur zurueck kommen.                                                  ###
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
-- ###     1.00.0	2023-02-09	Torsten Ahlemeyer                                          ###
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
CREATE OR ALTER VIEW [Spiel].[vGeschlageneFiguren]
AS

	SELECT
		  1				AS [ID]
		, REPLICATE(NCHAR(9817), (SELECT 8 - COUNT(*) FROM [Infrastruktur].[Spielbrett] WHERE [IstSpielerWeiss] = 'TRUE' AND [FigurBuchstabe] = 'B'))
						AS [geschlagene Figur(en)]
	UNION ALL
	SELECT
		  2
		, REPLICATE(NCHAR(9815), (SELECT 2 - COUNT(*) FROM [Infrastruktur].[Spielbrett] WHERE [IstSpielerWeiss] = 'TRUE' AND [FigurBuchstabe] = 'L'))
		+ REPLICATE(NCHAR(9816), (SELECT 2 - COUNT(*) FROM [Infrastruktur].[Spielbrett] WHERE [IstSpielerWeiss] = 'TRUE' AND [FigurBuchstabe] = 'S'))
		+ REPLICATE(NCHAR(9814), (SELECT 2 - COUNT(*) FROM [Infrastruktur].[Spielbrett] WHERE [IstSpielerWeiss] = 'TRUE' AND [FigurBuchstabe] = 'T'))
		+ REPLICATE(NCHAR(9813), (SELECT 1 - COUNT(*) FROM [Infrastruktur].[Spielbrett] WHERE [IstSpielerWeiss] = 'TRUE' AND [FigurBuchstabe] = 'D'))
	UNION ALL
	SELECT 3,''
	UNION ALL
	SELECT
		  4	
		, REPLICATE(NCHAR(9823), (SELECT 8 - COUNT(*) FROM [Infrastruktur].[Spielbrett] WHERE [IstSpielerWeiss] = 'FALSE' AND [FigurBuchstabe] = 'B'))
	UNION ALL
	SELECT
		  5
		, REPLICATE(NCHAR(9821), (SELECT 2 - COUNT(*) FROM [Infrastruktur].[Spielbrett] WHERE [IstSpielerWeiss] = 'FALSE' AND [FigurBuchstabe] = 'L'))
		+ REPLICATE(NCHAR(9822), (SELECT 2 - COUNT(*) FROM [Infrastruktur].[Spielbrett] WHERE [IstSpielerWeiss] = 'FALSE' AND [FigurBuchstabe] = 'S'))
		+ REPLICATE(NCHAR(9820), (SELECT 2 - COUNT(*) FROM [Infrastruktur].[Spielbrett] WHERE [IstSpielerWeiss] = 'FALSE' AND [FigurBuchstabe] = 'T'))
		+ REPLICATE(NCHAR(9819), (SELECT 1 - COUNT(*) FROM [Infrastruktur].[Spielbrett] WHERE [IstSpielerWeiss] = 'FALSE' AND [FigurBuchstabe] = 'D'))
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '090 - Sicht [Spiel].[vGeschlageneFiguren] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO


/*
SELECT * FROM [Spiel].[vGeschlageneFiguren]
*/