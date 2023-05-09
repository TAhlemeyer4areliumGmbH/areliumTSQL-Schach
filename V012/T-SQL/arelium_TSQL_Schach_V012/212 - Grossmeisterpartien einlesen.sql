-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Einlesen der Grossmeisterpartien fuer die Eroeffnungsbibliothek                     ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Dieses Programm kann Dateien im Format PGN im BULK-Verfahren einlesen und die dort  ###
-- ### gespeicherten Informationen zu Analysezwecken und/oder nutzen, um dem Computer-     ###
-- ### gegner auf Grossmeisterniveau zu heben. Unkommentierte Partiemittschnitte lassen    ###
-- ### kostenfrei aus dem Internet herunterladen. Derartige Textdateien bestehen aus einem ###
-- ### Metateil mit Partieinformationen (wer gegen wen, wann und wo gespielt, ...) und der ###
-- ### "kurzen Notation" der gesamten Partie. Diese Daten sind sauber zu trennen und dann  ###
-- ### aufzubereiten, so dass sie spaeter in Tabellenform abgefragt werden koennen.        ###
-- ###                                                                                     ###
-- ### Das Script ist bzgl. der Ablagepfade zu den einzulesenden Dateien anzupassen!       ###
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
-- ###     1.00.0	2023-04-17	Torsten Ahlemeyer                                          ###
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
USE [arelium_TSQL_Schach_V012]
GO

-- Gibt an, dass sich die Vergleichsoperatoren Gleich (=) und Ungleich (<>) bei Verwendung mit NULL-Werten in SQL Server 2019 (15.x) ISO-konform verhalten muessen.
-- ANSI NULLS ON ist neuer T-SQL Standard und wird in spaeteren Versionen festgeschrieben.
SET ANSI_NULLS ON
GO

-- Bewirkt, dass SQL Server die ISO-Regeln fuer Anfuehrungszeichen bei Bezeichnern und Literalzeichenfolgen befolgt.
SET QUOTED_IDENTIFIER ON
GO


-- ------------------------------------------------------------------------------
-- --- Gesammelte Grossmeisterpartien von Emanuel Lasker einlesen
-- ------------------------------------------------------------------------------
DECLARE @KompletterDateiAblagepfad		VARCHAR(255)
DECLARE @MaxZaehler						INTEGER

--SET @KompletterDateiAblagepfad	= 'D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\PNGs\Lasker.pgn'
SET @KompletterDateiAblagepfad	= 'C:\arelium_Repos\areliumTSQL-Schach\V012\PNGs\Lasker.pgn'
SET @MaxZaehler					= 20

EXECUTE [Bibliothek].[prcImportPGN] 
   @KompletterDateiAblagepfad
  ,@MaxZaehler
GO

-- ------------------------------------------------------------------------------
-- --- Gesammelte Grossmeisterpartien von Uwe Huebner einlesen
-- ------------------------------------------------------------------------------
DECLARE @KompletterDateiAblagepfad		VARCHAR(255)
DECLARE @MaxZaehler						INTEGER

--SET @KompletterDateiAblagepfad	= 'D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\PNGs\Huebner.pgn'
SET @KompletterDateiAblagepfad	= 'C:\arelium_Repos\areliumTSQL-Schach\V012\PNGs\Huebner.pgn'
SET @MaxZaehler					= 20

EXECUTE [Bibliothek].[prcImportPGN] 
   @KompletterDateiAblagepfad
  ,@MaxZaehler
GO

-- ------------------------------------------------------------------------------
-- --- Gesammelte Grossmeisterpartien von Gari Kasparov einlesen
-- ------------------------------------------------------------------------------
DECLARE @KompletterDateiAblagepfad		VARCHAR(255)
DECLARE @MaxZaehler						INTEGER

--SET @KompletterDateiAblagepfad	= 'D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\PNGs\Kasparov.pgn'
SET @KompletterDateiAblagepfad	= 'C:\arelium_Repos\areliumTSQL-Schach\V012\PNGs\Kasparov.pgn'
SET @MaxZaehler					= 20

EXECUTE [Bibliothek].[prcImportPGN] 
   @KompletterDateiAblagepfad
  ,@MaxZaehler
GO


-- ------------------------------------------------------------------------------
-- --- Gesammelte Grossmeisterpartien von Anatoli Karpov einlesen
-- ------------------------------------------------------------------------------
DECLARE @KompletterDateiAblagepfad		VARCHAR(255)
DECLARE @MaxZaehler						INTEGER

--SET @KompletterDateiAblagepfad	= 'D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\PNGs\Karpov.pgn'
SET @KompletterDateiAblagepfad	= 'C:\arelium_Repos\areliumTSQL-Schach\V012\PNGs\Karpov.pgn'
SET @MaxZaehler					= 20

EXECUTE [Bibliothek].[prcImportPGN] 
   @KompletterDateiAblagepfad
  ,@MaxZaehler
GO




------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '212 - Grossmeisterpartien einlesen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO