-- ###########################################################################################
-- ### arelium_TSQL_Schach_V014 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### VIEW [AktuellesSpiel].[TeilnotationAnzeigen] erstellen                                       ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Dieses Skript erstellt oder aendert eine Sicht, die die letzten 9 Zuege dieser      ###
-- ### Partie in der lange Notation ausgiebt.                                              ###
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
USE [arelium_TSQL_Schach_V014]
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

CREATE OR ALTER VIEW [AktuellesSpiel].[vTeilnotationAnzeigen]
AS
	-- um in einer View eine sortiere Ausgabe sicher stellen zu koennen, wird hier "getrickst". Eigentlich ist 
	-- ein ORDER BY in Views verboten... mit einem TOP 100 PERCENT darf man es doch nutzen...
	SELECT TOP 100 PERCENT  
		  ROW_NUMBER() OVER(ORDER BY [INNEN].[VollzugID] ASC)			AS [OrderID]
		, CASE WHEN [INNEN].[VollzugID] = ((SELECT MAX([VollzugID]) FROM [AktuellesSpiel].[Notation]) - 8)
			THEN '...'
			ELSE CONVERT(CHAR(3), FORMAT([INNEN].[VollzugID], '000'))
		  END															AS [VollzugID]
		, CASE WHEN [INNEN].[VollzugID] = ((SELECT MAX([VollzugID]) FROM [AktuellesSpiel].[Notation]) - 8)
			THEN '...'
			ELSE [INNEN].[WEISS]
		END																AS [WEISS]
		, CASE WHEN [INNEN].[VollzugID] = ((SELECT MAX([VollzugID]) FROM [AktuellesSpiel].[Notation]) - 8)
			THEN '...'
			ELSE [INNEN].[SCHWARZ]
		END																AS [SCHWARZ]
	FROM
		(
			SELECT TOP 9
				  [WEISS].[VollzugID]									AS [VollzugID] 
				, [WEISS].[LangeNotation]								AS [WEISS]
				, ISNULL([SCHWARZ].[LangeNotation], '')					AS [SCHWARZ]
			FROM [AktuellesSpiel].[Notation] AS [WEISS]
			LEFT JOIN (SELECT * FROM [AktuellesSpiel].[Notation]) AS [SCHWARZ]
				ON 1 = 1
					AND [WEISS].[VollzugID]				= [SCHWARZ].[VollzugID]
					AND [SCHWARZ].[IstSpielerWeiss]		= 'FALSE'

			WHERE 1 = 1
				AND [WEISS].[IstSpielerWeiss]	= 'TRUE'
			ORDER BY [WEISS].[VollzugID] DESC
		) AS [INNEN]
	ORDER BY [VollzugID] ASC

GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '112 - View [AktuellesSpiel].[vTeilnotationAnzeigen] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO


/*
USE [arelium_TSQL_Schach_V014]
GO


SELECT * FROM [AktuellesSpiel].[vTeilnotationAnzeigen]


*/