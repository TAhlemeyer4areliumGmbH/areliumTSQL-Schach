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
-- ###      Kontakt: torsten.ahlemeyer@arelium.de                                          ###
-- ###      ----------------                                                               ###
-- ###      Ein grosser Dank geht an (MVP) Uwe Ricken, der dem Projekt mit Rat und         ###
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
-- allgemeine Konfigurationen --------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

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

-- Mein privates Testsysten:		D:**\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012
-- Mein berufliches Testsystem:		C:**\arelium_Repos\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012

-- Strukturen ----------------------------------
--:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\002 - Datenbank erstellen.sql"		
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\010 - Datenstrukturen aufbauen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\012 - Stammdaten initial einfuegen.sql"
-- Spieleroeffnung
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\021 - Prozedur [Infrastruktur].[prcGrundstellungAufbauen] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\022 - Prozedur [Infrastruktur].[prcVorgabepartieAufbauen] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\023 - Prozedur [Infrastruktur].[prcFischerRandomChessAufbauen] erstellen.sql"
-- Datenbasis aufbereiten ----------------------
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\031 - Prozedur [Infrastruktur].[prcTheoretischeAktionenInitialisieren] erstellen.sql"
-- Aktionen ------------------------------------
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\041 - Funktion [Spiel].[fncMoeglicheTurmaktionen] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\042 - Funktion [Spiel].[fncMoeglicheSpringeraktionen] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\043 - Funktion [Spiel].[fncMoeglicheLaeuferaktionen] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\044 - Funktion [Spiel].[fncMoeglicheDamenaktionen] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\045 - Funktion [Spiel].[fncMoeglicheKoenigsaktionen] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\046 - Funktion [Spiel].[fncMoeglicheBauernaktionen] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\049 - Funktion [Spiel].[frcMoeglicheAktionen] erstellen.sql"
-- Schlaege ------------------------------------
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\051 - Funktion [Spiel].[fncMoeglicheTurmschlaege] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\052 - Funktion [Spiel].[fncMoeglicheSpringerschlaege] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\053 - Funktion [Spiel].[fncMoeglicheLaeuferschlaege] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\054 - Funktion [Spiel].[fncMoeglicheDamenschlaege] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\055 - Funktion [Spiel].[fncMoeglicheKoenigsschlaege] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\056 - Funktion [Spiel].[fncMoeglicheBauernschlaege] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\059 - Funktion [Spiel].[fncMoeglicheSchlaege] erstellen.sql"
-- virtuelle Schlaege --------------------------
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\061 - Funktion [Spiel].[fncVirtuelleTurmschlaege] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\062 - Funktion [Spiel].[fncVirtuelleSpringerschlaege] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\063 - Funktion [Spiel].[fncVirtuelleLaeuferschlaege] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\064 - Funktion [Spiel].[fncVirtuelleDamenschlaege] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\065 - Funktion [Spiel].[fncVirtuelleKoenigsschlaege] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\066 - Funktion [Spiel].[fncVirtuelleBauernschlaege] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\069 - Funktion [Spiel].[fncVirtuelleSchlaege] erstellen.sql"
-- Stellungsfunktionen ------------------------------------
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\082 - Prozedur [Spiel].[prcAktionenFuerAktuelleStellungWegschreiben] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\083 - Funktion [Spiel].[fncIstWeissAmZug] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\084 - Funktion [Spiel].[frcMoeglicheVirtuelleSchlaegeAufFeld] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\085 - Funktion [Spiel].[fncIstFeldBedroht] erstellen.sql"
-- Bewerten ------------------------------------
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\101 - Funktion [Statistik].[fncFigurwertZaehlen] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\102 - Funktion [Statistik].[fncAktionsmoeglichkeitenZaehlen] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\103 - Funktion [Statistik].[fncSchlagmoeglichkeitenZaehlen] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\104 - Funktion [Statistik].[fncBauernvormarsch] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\106 - Funktion [Statistik].[fncFreibauern] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\108 - Prozedur [Statistik].[prcStellungBewerten] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\109 - Funktion [Statistik].[fncAktuelleStellungBewerten] erstellen.sql"
-- Anzeigen ------------------------------------
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\111 - View [Spiel].[vGeschlageneFiguren] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\112 - View [Spiel].[vTeilnotationAnzeigen] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\113 - View [Infrastruktur].[vBedienungsanleitung] erstellen.sql"
--:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\114 - View [Bibliothek].[vEroeffnungsbibliothek] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\115 - Funktionen [Bibliothek].[fncCharIndexNG] erstellen.sql"		
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\116 - Funktion [Infrastruktur].[fncSekundenAlsUhrzeitFormatieren] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\117 - View [Bibliothek].[vSchonmalGespielt] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\118 - View [Infrastruktur].[vLogo] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\121 - Funktion [Infrastruktur].[fncStellungIstSchach] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\127 - View [Infrastruktur].[vSpielbrett] erstellen.sql"
-- Notation ------------------------------------
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\151 - Funktion [Infrastruktur].[fncLangeNotation] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\152 - Funktion [Infrastruktur].[fncKurzeNotationEinfach] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\153 - Funktion [Infrastruktur].[fncKurzeNotationKomplex] erstellen.sql"
-- PGN-Import ----------------------------------
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\203 - Prozedur [Bibliothek].[prcImportPGN] erstellen.sql"		
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\205 - Prozedur [Bibliothek].[prcGrossmeisterpartienEinlesen] erstellen.sql"		
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\206 - Prozedur [Bibliothek].[prcKurzeNotationAufbereiten] erstellen.sql"		
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\212 - Grossmeisterpartien einlesen.sql"		
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\215 - Funktion [Bibliothek].[fncSplitKurzeNotation] erstellen.sql"		

:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\310 - MiniMax-Algorithmus am Beispiel.sql"

:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\401 - Prozedur [Spiel].[prcZugSimulieren] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\402 - Prozedur [Spiel].[prcZugAnalysieren] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\410 - Prozedur [Spiel].[prcAktuellesSpielAufgeben] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\411 - Prozedur [Spiel].[prcRemisAnbieten] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\412 - Prozedur [Spiel].[prcRemisangebotAnnehmen] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\413 - Prozedur [Spiel].[prcZurueckZuZug] erstellen.sql"

:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\510 - Prozedur [Spiel].[prcInitialisierung] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\512 - Prozedur [Spiel].[prcZugausfuehren] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\513 - Prozedur [Spiel].[prcZugausfuehrenUndReagieren] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\520 - Prozedur [Spiel].[prcMensch_vs_TSQL] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\521 - Prozedur [Spiel].[prcTSQL_vs_Mensch] erstellen.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012\522 - Prozedur [Spiel].[prcTSQL_vs_TSQL] erstellen.sql"
-- Beispielpartien -----------------------------

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