-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Beispielpartie 001                                                                  ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Dieses Skript simuliert eine komplette Schachpartie und soll die Features dieses    ###
-- ### Programms vorstellen. Man fuehrt es Schritt fuer Schritt aus.                       ###
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





--------------------------------------------------------------------------------------------------
-- Partie 001 ------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

-- Das Spiel initialisieren

EXECUTE [Spiel].[prcInitialisierung] 
    @NameWeiss							= 'Peter'
  , @NameSchwarz						= 'Sandy'
  , @IstSpielerMenschWeiss				= 'TRUE'
  , @IstSpielerMenschSchwarz			= 'TRUE'
  , @SpielstaerkeWeiss					= 4			-- Kindergartenkind+
  , @SpielstaerkeSchwarz				= 2			-- Kleinkind+
  , @RestzeitWeissInSekunden			= 5400		-- Beispiel: 1 Stunde und 30 Minuten = 5400 Sekunden
  , @RestzeitSchwarzInSekunden			= 7200		-- Beispiel: 2 Stunden = 7200 Sekunden
  , @ComputerSchritteAnzeigenWeiss		= 'TRUE'
  , @ComputerSchritteAnzeigenSchwarz	= 'FALSE'
  , @BedienungsanleitungAnzeigen		= 'TRUE'	-- Zeigt vorab eine Anleitung mit den moeglichen Befehlen
GO



-- Die Zeit fuer WEISS laeuft...

-- Es zieht WEISS den ersten Zug -> Bauer von f2 nach f3
EXECUTE [Spiel].[prcZugAusfuehren] 
		  @Startquadrat				= 'f2'
		, @Zielquadrat				= 'f3'
		, @Umwandlungsfigur			= NULL
		, @IstEnPassant				= 'FALSE'
		, @IstSpielerWeiss			= 'TRUE'
GO	


-- Die Zeit fuer SCHWARZ laeuft...

-- Es zieht SCHWARZ den ersten Zug -> Bauer von e7 nach e5
EXECUTE [Spiel].[prcZugAusfuehren] 
		  @Startquadrat				= 'e7'
		, @Zielquadrat				= 'e5'
		, @Umwandlungsfigur			= NULL
		, @IstEnPassant				= 'FALSE'
		, @IstSpielerWeiss			= 'FALSE'
GO	

-- Vollzug 002
EXECUTE [Spiel].[prcZugAusfuehren] 'g2', 'g4', NULL, 'FALSE', 'TRUE'
GO	
EXECUTE [Spiel].[prcZugAusfuehren] 'd8', 'h4', NULL, 'FALSE', 'FALSE'
GO	