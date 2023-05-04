-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Beispielaufruf fuer eine Partie Mensch (WEISS) gegen Computer (SCHWARZ)             ###
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
USE [arelium_TSQL_Schach_V012]
GO

-- Gibt an, dass sich die Vergleichsoperatoren Gleich (=) und Ungleich (<>) bei Verwendung mit NULL-Werten in SQL Server 2019 (15.x) ISO-konform verhalten muessen.
-- ANSI NULLS ON ist neuer T-SQL Standard und wird in spaeteren Versionen festgeschrieben.
SET ANSI_NULLS ON
GO

-- Bewirkt, dass SQL Server die ISO-Regeln fuer Anfuehrungszeichen bei Bezeichnern und Literalzeichenfolgen befolgt.
SET QUOTED_IDENTIFIER ON
GO



DECLARE @RC int
DECLARE @NameWeiss nvarchar(30)
DECLARE @NameSchwarz						NVARCHAR(30)
DECLARE @SpielstaerkeWeiss					TINYINT
DECLARE @SpielstaerkeSchwarz				TINYINT
DECLARE @RestzeitWeissInSekunden			INTEGER
DECLARE @RestzeitSchwarzInSekunden			INTEGER
DECLARE @ComputerSchritteAnzeigenWeiss		BIT
DECLARE @ComputerSchritteAnzeigenSchwarz	BIT
DECLARE @Startquadrat						CHAR(2)
DECLARE @Zielquadrat						CHAR(2)
DECLARE @Umwandlungsfigur					CHAR(1)
DECLARE @IstEnPassant						BIT
DECLARE @GebrauchsanweisungAnzeigen			BIT

SET @NameWeiss							= 'Torsten'
SET @NameSchwarz						= 'Compi'
SET @SpielstaerkeWeiss					= 1
SET @SpielstaerkeSchwarz				= 3
SET @RestzeitWeissInSekunden			= 5700
SET @RestzeitSchwarzInSekunden			= 5700
SET @ComputerSchritteAnzeigenWeiss		= 1
SET @ComputerSchritteAnzeigenSchwarz	= 1
SET @Startquadrat						= 'e2'
SET @Zielquadrat						= 'e4'
SET @Umwandlungsfigur					= NULL
SET @IstEnPassant						= 'FALSE'
SET @GebrauchsanweisungAnzeigen			= 'FALSE'


EXECUTE @RC = [Spiel].[prcMensch_vs_TSQL] 
    @NameWeiss
  , @NameSchwarz
  -- Spielstaerke WEISS ist der Festwert 1
  , @SpielstaerkeSchwarz
  , @RestzeitWeissInSekunden
  , @RestzeitSchwarzInSekunden
  , @ComputerSchritteAnzeigenWeiss
  , @ComputerSchritteAnzeigenSchwarz
  , @Startquadrat
  , @Zielquadrat
  , @Umwandlungsfigur
  , @IstEnPassant
  , @GebrauchsanweisungAnzeigen
GO

/*
-- Die Zeit fuer WEISS laeuft...
EXECUTE [Spiel].[prcZugAusfuehrenUndReagieren] 
		  @Startquadrat				= 'g1'
		, @Zielquadrat				= 'f3'
		, @Umwandlungsfigur			= NULL
		, @IstEnPassant				= 'FALSE'
		, @IstSpielerWeiss			= 'TRUE'
GO	
*/
-- Schwarz zieht automatsich!

