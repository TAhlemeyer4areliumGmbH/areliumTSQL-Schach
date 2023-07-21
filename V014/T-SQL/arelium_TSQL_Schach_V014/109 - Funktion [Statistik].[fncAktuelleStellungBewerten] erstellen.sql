-- ###########################################################################################
-- ### arelium_TSQL_Schach_V014 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Funktion [Statistik].[fncAktuelleStellungBewerten]                                  ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### In der Tabelle [Statistik].[Stellungsbewertung] stehen die Ergebnisse der Einzel-   ###
-- ### bewertungen nach unterschiedlichsten Kriterien. Diese sind nun nach einem festen    ###
-- ### Schluessel zu gewichten und zu seinem Gesamtwert zu verdichten.                     ###
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
-- ###      Kontakt: torsten.ahlemeyer@arelium.de                                          ###
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
USE [arelium_TSQL_Schach_V014]
GO

-- Gibt an, dass sich die Vergleichsoperatoren Gleich (=) und Ungleich (<>) bei Verwendung mit NULL-Werten in SQL Server 2019 (15.x) ISO-konform verhalten muessen.
-- ANSI NULLS ON ist neuer T-SQL Standard und wird in spaeteren Versionen festgeschrieben.
SET ANSI_NULLS ON
GO

-- Bewirkt, dass SQL Server die ISO-Regeln fuer Anfuehrungszeichen bei Bezeichnern und Literalzeichenfolgen befolgt.
SET QUOTED_IDENTIFIER ON
GO


-- -----------------------------------------------------------------------------------------
-- Erstellung der Funktion [Statistik].[fncAktuelleStellungBewerten]
-- -----------------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION [Statistik].[fncAktuelleStellungBewerten]
()
RETURNS FLOAT
AS
BEGIN
	DECLARE @RueckgabeWert AS FLOAT

	DECLARE @Figurwert				AS FLOAT
	DECLARE @AnzahlAktionen			AS FLOAT
	DECLARE @AnzahlSchlaege			AS FLOAT
	DECLARE @AnzahlRochade			AS FLOAT
	DECLARE @Bauernvormarsch		AS FLOAT
	DECLARE @AnzahlFreibauern		AS FLOAT
	DECLARE @LaengeBauerketten		AS FLOAT

	SET @Figurwert			= (SELECT [Weiss] - [Schwarz] FROM [Statistik].[Stellungsbewertung] WHERE [Label] = 'Figurwert:')
	SET @AnzahlAktionen		= (SELECT [Weiss] - [Schwarz] FROM [Statistik].[Stellungsbewertung] WHERE [Label] = 'Anzahl Aktionen:') / 15
	SET @AnzahlSchlaege		= (SELECT [Weiss] - [Schwarz] FROM [Statistik].[Stellungsbewertung] WHERE [Label] = 'Anzahl Schlaege:') / 20
	SET @AnzahlRochade		= (SELECT [Weiss] - [Schwarz] FROM [Statistik].[Stellungsbewertung] WHERE [Label] = 'Anzahl Rochaden:') / 30
	SET @Bauernvormarsch	= (SELECT [Weiss] - [Schwarz] FROM [Statistik].[Stellungsbewertung] WHERE [Label] = 'Bauernvormarsch:') / 20
	SET @AnzahlFreibauern	= (SELECT [Weiss] - [Schwarz] FROM [Statistik].[Stellungsbewertung] WHERE [Label] = 'Anzahl Freibauern:') / 30
	SET @LaengeBauerketten	= (SELECT [Weiss] - [Schwarz] FROM [Statistik].[Stellungsbewertung] WHERE [Label] = 'Länge Bauernketten:') / 50
	
	SET @RueckgabeWert =  ISNULL(@Figurwert, 0.0)			+ ISNULL(@AnzahlAktionen, 0.0) 
						+ ISNULL(@AnzahlSchlaege, 0.0)	+ ISNULL(@AnzahlRochade, 0.0)
						+ ISNULL(@Bauernvormarsch, 0.0)	+ ISNULL(@AnzahlFreibauern, 0.0)
						+ ISNULL(@LaengeBauerketten, 0.0)
					
	RETURN @RueckgabeWert 

END
GO

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '109 - Funktion [Statistik].[fncAktuelleStellungBewerten] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO


/*
-- Test der Funktion [Statistik].[fncAktuelleStellungBewerten]

SELECT [Statistik].[fncAktuelleStellungBewerten]()
GO
*/
