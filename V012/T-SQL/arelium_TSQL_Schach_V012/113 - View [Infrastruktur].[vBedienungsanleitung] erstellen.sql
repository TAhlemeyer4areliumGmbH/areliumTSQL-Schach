-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### VIEW [Infrastruktur].[vBedienungsanleitung]                                         ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Dieses Skript erstellt oder aendert eine Sicht, die einen menschlichen Spieler      ###
-- ### ueber die korrekte Bedienung hinweist seinen naechsten Zug durchzufuehren.          ###
-- ###                                                                                     ###
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
-- ###     1.00.0	2023-02-17	Torsten Ahlemeyer                                          ###
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

CREATE OR ALTER VIEW [Infrastruktur].[vBedienungsanleitung]
AS
SELECT 1 AS [ID], CONVERT(NVARCHAR(500), 
	'Am Zug bist Du (' + 
	(SELECT [Spielername] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = [Spiel].[fncIstWeissAmZug]())
	+ ') als Spieler ' + CASE [Spiel].[fncIstWeissAmZug]() WHEN 'TRUE' THEN 'WEISS' ELSE 'SCHWARZ' END + '.')
	AS [naechste Schritte]
UNION
SELECT 2, ''
UNION
SELECT 3, 'eine Aktion (egal ob Zug oder Schlag) bedarf nur der Angabe der Start- und der Zielkoordinate. Handelt es sich um eine Bauerumwandlung ist anzugeben, welche Figur eingetauscht'
UNION
SELECT 4, 'wurde (''L'', ''S'', ''T'', ''D'') - sonst ist der dritte Parameter NULL. Fällt der Zug unter die <en passant>-Regel, ist der vierte Parameter mit ''TRUE'' anzugeben (sonst ''FALSE'').'
UNION
SELECT 5, 'Der abschliessende Parameter beantwortet die Frage, ob Du die WEISSEN oder die SCHWARZEN Steine spielst und ist daher auf ' + CASE [Spiel].[fncIstWeissAmZug]() WHEN 'TRUE' THEN 'WEISS' ELSE 'SCHWARZ' END + ' zu setzen'
UNION
SELECT 6, 'Bei einer Rochade ist nur die Königsbewegung auszuführen. Aufgeben kannst Du über den Befehl <EXECUTE [Spiel].[prcAktuellesSpielAufgeben]>. Ein Remis bietet man mit <EXECUTE [Spiel].[prcRemisAnbieten]> an.'
UNION
SELECT 7, ''
UNION
SELECT 8, 'Beispiel für einen korrekten Aufruf (die Standarderöffnung mit dem Doppelschritt des Damenbauern):'
UNION
SELECT 9, 'EXECUTE [Spiel].[prcZugAusfuehren] ''d2'', ''d4'', NULL, ''FALSE'', ''TRUE'''
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '113 - View [Infrastruktur].[vSpielbrett] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO


/*
USE [arelium_TSQL_Schach_V012]
GO


SELECT * FROM [Infrastruktur].[vBedienungsanleitung]


*/