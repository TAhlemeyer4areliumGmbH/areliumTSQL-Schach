-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Ein Remis annehmen                                                                  ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Wurde ein Remis angeboten, kann einfach weiter gespielt werden - das Angebot gilt   ###
-- ### dann als abgelehnt. Soll es angenommen werden, ist diese Prozedur zu bemuehen.      ###
-- ###                                                                                     ###
-- ### Der Aufruf der Prozedur fuehrt zur sofortigen Punkteteilung.                        ###
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
CREATE OR ALTER PROCEDURE [Spiel].[prcRemisangebotAnnehmen]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @IstSpielerWeiss		AS BIT
	SET @IstSpielerWeiss			= [Spiel].[fncIstWeissAmZug]()

	IF @IstSpielerWeiss = 'FALSE'
	BEGIN
		INSERT INTO [Spiel].[Notation]
			(	  [VollzugID], [IstSpielerWeiss], [TheoretischeAktionenID], [LangeNotation]
				, [KurzeNotationEinfach], [KurzeNotationKomplex], [ZugIstSchachgebot])
		VALUES
			((SELECT MAX([VollzugID]) FROM [Spiel].[Notation])
			, 'FALSE'
			, (SELECT MIN([TheoretischeAktionenID]) FROM [Infrastruktur].[TheoretischeAktionen])
			, 'Remisangebot'
			, 'Remisangebot'
			, 'Remisangebot'
			, 'FALSE')
	END

	INSERT INTO [Spiel].[Notation]
		(	  [VollzugID], [IstSpielerWeiss], [TheoretischeAktionenID], [LangeNotation]
			, [KurzeNotationEinfach], [KurzeNotationKomplex], [ZugIstSchachgebot])
	VALUES
		((SELECT MAX([VollzugID]) + 1 FROM [Spiel].[Notation])
		, 'TRUE'
		, (SELECT MIN([TheoretischeAktionenID]) FROM [Infrastruktur].[TheoretischeAktionen])
		, CHAR(189) + '-' + CHAR(189)
		, CHAR(189) + '-' + CHAR(189)
		, CHAR(189) + '-' + CHAR(189)
		, 'TRUE')
		
	SELECT * FROM [Infrastruktur].[vSpielbrett]

END
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '412 - Prozedur [Spiel].[prcRemisangebotAnnehmen] erstellen.sql'
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