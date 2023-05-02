-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Beispielpartie 002                                                                  ###
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
   @NameWeiss						= 'Peter'
  ,@NameSchwarz						= 'Sandy'
  ,@SpielstaerkeWeiss				= 2			-- menschlicher Gegner
  ,@SpielstaerkeSchwarz				= 2			-- menschlicher Gegner
  ,@RestzeitWeissInSekunden			= 5400		-- Beispiel: 1 Stunde und 30 Minuten = 5400 Sekunden
  ,@RestzeitSchwarzInSekunden		= 7200		-- Beispiel: 2 Stunden = 7200 Sekunden
  ,@ComputerSchritteAnzeigenWeiss	= 'TRUE'
  ,@ComputerSchritteAnzeigenSchwarz	= 'FALSE'
GO



-- Die Zeit fuer WEISS laeuft...

-- Es zieht WEISS den ersten Zug -> Bauer von e2 nach e4
EXECUTE [Spiel].[prcZugAusfuehren] 
		  @Startquadrat				= 'e2'
		, @Zielquadrat				= 'e4'
		, @Umwandlungsfigur			= NULL
		, @IstEnPassant				= 'FALSE'
		, @IstSpielerWeiss			= 'TRUE'
GO	


-- Die Zeit fuer SCHWARZ laeuft...

-- Es zieht SCHWARZ den ersten Zug -> Springer von b8 nach c6
EXECUTE [Spiel].[prcZugAusfuehren] 
		  @Startquadrat				= 'c7'
		, @Zielquadrat				= 'c5'
		, @Umwandlungsfigur			= NULL
		, @IstEnPassant				= 'FALSE'
		, @IstSpielerWeiss			= 'FALSE'
GO	

-- Vollzug 002
EXECUTE [Spiel].[prcZugAusfuehren] 'g1', 'f3', NULL, 'FALSE', 'TRUE'
GO	
EXECUTE [Spiel].[prcZugAusfuehren] 'g7', 'g6', NULL, 'FALSE', 'FALSE'
GO	

-- Vollzug 003
EXECUTE [Spiel].[prcZugAusfuehren] 'g1', 'f3', NULL, 'FALSE', 'TRUE'
GO	
EXECUTE [Spiel].[prcZugAusfuehren] 'f8', 'g7', NULL, 'FALSE', 'FALSE'
GO	

-- Vollzug 004
EXECUTE [Spiel].[prcZugAusfuehren] 'b1', 'c3', NULL, 'FALSE', 'TRUE'
GO	
EXECUTE [Spiel].[prcZugAusfuehren] 'd7', 'd6', NULL, 'FALSE', 'FALSE'
GO	

-- Vollzug 005
EXECUTE [Spiel].[prcZugAusfuehren] 'f1', 'e2', NULL, 'FALSE', 'TRUE'
GO	
EXECUTE [Spiel].[prcZugAusfuehren] 'e7', 'e5', NULL, 'FALSE', 'FALSE'
GO	

-- Vollzug 006
EXECUTE [Spiel].[prcZugAusfuehren] 'd4', 'e5', NULL, 'FALSE', 'TRUE'			-- das Programm erkennt selbststaendig, dass es sich um einen Schlag handelt!
GO																				-- ... und passt auch die Legende der geschlagenen Figuren entsprechend an
EXECUTE [Spiel].[prcZugAusfuehren] 'c6', 'e5', NULL, 'FALSE', 'FALSE'
GO	

-- Vollzug 007
EXECUTE [Spiel].[prcZugAusfuehren] 'e1', 'g1', NULL, 'FALSE', 'TRUE'			-- Bei einer Rochade wird nur der Koenigszug angegeben
GO																				-- ... das Programm prueft die Gueltigkeit und notiert eine kurze Rochade ("o-o")
EXECUTE [Spiel].[prcZugAusfuehren] 'g8', 'e7', NULL, 'FALSE', 'FALSE'
GO	

-- Vollzug 008
EXECUTE [Spiel].[prcZugAusfuehren] 'c1', 'e3', NULL, 'FALSE', 'TRUE'			
GO																				
EXECUTE [Spiel].[prcZugAusfuehren] 'f7', 'f5', NULL, 'FALSE', 'FALSE'
GO	

-- Vollzug 009
EXECUTE [Spiel].[prcZugAusfuehren] 'f1', 'e1', NULL, 'FALSE', 'TRUE'			-- in der Notation werden Auslassungszeichen eingefuegt
GO																				
EXECUTE [Spiel].[prcZugAusfuehren] 'e8', 'g8', NULL, 'FALSE', 'FALSE'
GO	

-- Vollzug 010
EXECUTE [Spiel].[prcZugAusfuehren] 'e3', 'g5', NULL, 'FALSE', 'TRUE'			
GO																				
EXECUTE [Spiel].[prcZugAusfuehren] 'c8', 'e6', NULL, 'FALSE', 'FALSE'
GO	

-- Vollzug 011
EXECUTE [Spiel].[prcZugAusfuehren] 'e4', 'f5', NULL, 'FALSE', 'TRUE'			
GO																				
EXECUTE [Spiel].[prcZugAusfuehren] 'e6', 'f5', NULL, 'FALSE', 'FALSE'
GO	

-- Vollzug 012
EXECUTE [Spiel].[prcZugAusfuehren] 'c3', 'd5', NULL, 'FALSE', 'TRUE'			
GO																				
EXECUTE [Spiel].[prcZugAusfuehren] 'd8', 'd7', NULL, 'FALSE', 'FALSE'
GO	

-- Vollzug 013
EXECUTE [Spiel].[prcZugAusfuehren] 'd5', 'e7', NULL, 'FALSE', 'TRUE'			-- das Programm erkennt selbststaendig das Schachgebot!
GO																				-- und schraenkt die moeglichen Zuege ein...
EXECUTE [Spiel].[prcZugAusfuehren] 'a8', 'b8', NULL, 'FALSE', 'FALSE'			-- und erkennt einen Zugversuch gegen die Regeln!
GO	
EXECUTE [Spiel].[prcZugAusfuehren] 'd7', 'e7', NULL, 'FALSE', 'FALSE'
GO	

-- Vollzug 014
EXECUTE [Spiel].[prcZugAusfuehren] 'g5', 'e7', NULL, 'FALSE', 'TRUE'			-- der Damenverlust schwaecht Schwarz signifikant
GO																				
EXEC [Spiel].[prcAktuellesSpielAufgeben]
GO
