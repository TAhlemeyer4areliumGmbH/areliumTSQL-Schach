-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Einspielen ALLER Skripte                                                            ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Dieses Skript erstellt eine voll lauffaehige Version der Schachapplikation aus      ###
-- ### nachgelagerten Skripten, die entsprechend ihrer Numemrierung aufgerufen und         ###
-- ### ausgefuehrt werden.                                                                 ###
-- ###                                                                                     ###
-- ###                 **********************************************                      ###
-- ###                 *** Dieses Skript benoetigt den CMD-Modus! ***                      ###
-- ###                 **********************************************                      ###
-- ###   (im SSMS ist im Menuepunkt <Query> der Unterpunkt <SQLCMD Mode> zu aktivieren)    ###
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

-- auf die immer vorhandene MASTER-DB wechseln
USE [master]
GO

-- Gibt an, dass sich die Vergleichsoperatoren Gleich (=) und Ungleich (<>) bei Verwendung mit NULL-Werten in SQL Server 2019 (15.x) ISO-konform verhalten muessen.
-- ANSI NULLS ON ist neuer T-SQL Standard und wird in spaeteren Versionen festgeschrieben.
SET ANSI_NULLS ON
GO

-- Bewirkt, dass SQL Server die ISO-Regeln fuer Anfuehrungszeichen bei Bezeichnern und Literalzeichenfolgen befolgt.
SET QUOTED_IDENTIFIER ON
GO

--------------------------------------------------------------------------------------------------
-- Aufraeumarbeiten ------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

-- es gibt keine Aufraeumarbeiten!


--------------------------------------------------------------------------------------------------
--- Aufbauarbeiten -------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

-- allgemeine Konfigurationen --------------------------------------------------------------------

-- hier wird in einer globalen temporaeren Tabelle abgelegt, in welcher Umgebung das Skript laeuft
-- so kann man in den einzelnen Skripten auf diese Information zurueckgreifen und entsprechend 
-- des uebermittelten Wertes handeln. Erlaubte Werte: LOC, DEV, TEST und PROD
:on error exit
BEGIN TRY
	DROP TABLE ##System
END TRY
BEGIN CATCH
END CATCH
CREATE TABLE ##System (DeploymentSystem VARCHAR(4))
INSERT INTO ##System (DeploymentSystem) 
	VALUES ('LOC')	-- DEV / TEST / PROD

-- Mein privates Testsysten:		D:**\Beruf\arelium\Sessions\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012
-- Mein berufliches Testsystem:		C:**\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012

--:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\001 - Datenbank erstellen.sql"		
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\010 - Datenstrukturen aufbauen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\012 - Stammdaten initial einfuegen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\020 - Prozedur [Infrastruktur].[prcGrundstellungAufbauen] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\030 - Prozedur [Infrastruktur].[prcTheoretischeAktionenInitialisieren] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\061 - Funktion [Spiel].[fncMoeglicheTurmaktionen] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\062 - Funktion [Spiel].[fncMoeglicheSpringeraktionen] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\063 - Funktion [Spiel].[fncMoeglicheLaeuferaktionen] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\064 - Funktion [Spiel].[fncMoeglicheDamenaktionen] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\065 - Funktion [Spiel].[fncMoeglicheKoenigsaktionen] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\066 - Funktion [Spiel].[fncMoeglicheBauernaktionen] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\071 - Funktion [Spiel].[fncMoeglicheTurmschlaege] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\072 - Funktion [Spiel].[fncMoeglicheSpringerschlaege] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\073 - Funktion [Spiel].[fncMoeglicheLaeuferschlaege] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\074 - Funktion [Spiel].[fncMoeglicheDamenschlaege] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\075 - Funktion [Spiel].[fncMoeglicheKoenigsschlaege] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\076 - Funktion [Spiel].[fncMoeglicheBauernschlaege] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\080 - Funktion [Spiel].[frcMoeglicheAktionen] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\081 - Funktion [Spiel].[fncMoeglicheSchlaege] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\082 - Prozedur [Spiel].[prcAktionenFuerAktuelleStellungWegschreiben] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\085 - Funktion [Spiel].[fncIstFeldBedroht] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\090 - View [Spiel].[vGeschlageneFiguren] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\091 - View [Spiel].[vTeilnotationAnzeigen] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\092 - View [Infrastruktur].[vBedienungsanleitung] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\093 - Sicht [Bibliothek].[vEroeffnungsbibliothek] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\095 - View [Infrastruktur].[vSpielbrett] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\100 - Funktion [Statistik].[fncFigurwertZaehlen] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\101 - Funktion [Statistik].[fncAktionsmoeglichkeitenZaehlen] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\102 - Funktion [Statistik].[fncSchlagmoeglichkeitenZaehlen] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\108 - Prozedur [Statistik].[prcStellungBewerten] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\109 - Funktion [Statistik].[fncStellungBewerten] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\120 - Funktion [Spiel].[fncIstWeissAmZug] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\121 - Funktion [Infrastruktur].[fncStellungIstSchach] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\150 - Funktion [Infrastruktur].[fncLangeNotation] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\151 - Funktion [Infrastruktur].[fncKurzeNotationEinfach] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\152 - Funktion [Infrastruktur].[fncKurzeNotationKomplex] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\200 - Prozedur [Bibliothek].[prcImportPGN] erstellen.sql"		
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\202 - Prozedur [Bibliothek].[prcKurzeNotationAufbereiten] erstellen.sql"		
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\204 - Prozedur [Bibliothek].[prcGrossmeisterpartienEinlesen] erstellen.sql"		
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\300 - MiniMax-Algorithmus am Beispiel.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\400 - Prozedur [Spiel].[ZugSimulieren] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\450 - Funktion [Infrastruktur].[fncSekundenAlsUhrzeitFormatieren] erstellen.sql"
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\500 - Prozedur [Spiel].[prcInitialisierung] erstellen.sql"		
:r "C:\arelium_Repos\arelium_TSQL_Schach\V012\T-SQL\arelium_TSQL_Schach_V012\510 - Prozedur [Spiel].[prcZugausfuehren] erstellen.sql"		

--------------------------------------------------------------------------------------------------
-- Statistiken -----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------


PRINT 'arelium_TSQL_Schach: Das Projekt <Spiel der Koenige>'
PRINT '--------------------------------------------------------------------------------'
PRINT 'Skript     :   000 - Gesamtskript.sql'
PRINT 'Start      :   ' + CONVERT(VARCHAR(25), GETDATE(), 114)
PRINT 'Server     :   ' + @@SERVERNAME
PRINT 'Datenbank  :   ' + DB_NAME()
PRINT 'Version    :   12.01		07.02.2023		Torsten Ahlemeyer fuer die arelium GmbH (unter CC-BY-NC-SA)'
GO




PRINT 'Alle Skripte fuer den Workshop <T-SQL Battleship> wurden erfolgreich verarbeitet...'
GO