-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Anlage der Datenbank                                                                ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Dieses Skript legt einige der benoetigten Datenbankobjekte an. Das Projekt arbeitet ###
-- ### mit Schemata, um eine saubere Struktur vorzugeben und eine leichte Rechtezuweisung  ###
-- ### umsetzen zu koennen. Auch der Basissatz von DB-Objekten wird hier erstellt. Hierbei ###
-- ### handelt es sich um diverse Nachschlagetabellen mit Konfigurationseinstellungen, den ###
-- ### Speicherobjekten fuer das Spielbrett, das Analysebrett, den Partiefortgang, usw...  ###
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

-- Hier sind alle Objekte aufgelistet, die durch dieses Skript angelegt oder veraendert werden. Da es bei einigen DDL
-- Befehlen (wie bspw. CREATE TABLE) keine IF-EXISTS-Syntax gibt, wird hier erstmal sauber aufgeraeumt. Bestehende 
-- Objekte werden per DROP geloescht, um spaeter geordnet neu erstellt werden zu koennen.
 
-- Constraints
	--IF EXISTS (SELECT 1 FROM SYS.OBJECTS WHERE NAME = 'FK_Spiel_MoeglicheAktionen_TheoretischeAktionen' AND TYPE='F')
	--	ALTER TABLE [Spiel].[MoeglicheAktionen] DROP CONSTRAINT [FK_Spiel_MoeglicheAktionen_TheoretischeAktionen]
	IF EXISTS (SELECT 1 FROM SYS.OBJECTS WHERE NAME = 'FK_Spiel_Notation_TheoretischeAktionen' AND TYPE='F')
		ALTER TABLE [Spiel].[Notation] DROP CONSTRAINT [FK_Spiel_Notation_TheoretischeAktionen]
	IF EXISTS (SELECT 1 FROM SYS.OBJECTS WHERE NAME = 'FK_Infrastruktur_Spielbrett_FigurUTF8' AND TYPE='F')
		ALTER TABLE [Infrastruktur].[Spielbrett] DROP CONSTRAINT [FK_Infrastruktur_Spielbrett_FigurUTF8]
	IF EXISTS (SELECT 1 FROM SYS.OBJECTS WHERE NAME = 'FK_Spiel_Notation_TheoretischeAktionen' AND TYPE='F')
		ALTER TABLE [Archiv].[Zugarchiv] DROP CONSTRAINT [FK_Spiel_Notation_TheoretischeAktionen]
	IF EXISTS (SELECT 1 FROM SYS.OBJECTS WHERE NAME = 'FK_Spiel_Konfiguration_SpielstaerkeID' AND TYPE='F')
		ALTER TABLE [Spiel].[Konfiguration] DROP CONSTRAINT [FK_Spiel_Konfiguration_SpielstaerkeID]
		 
 	--IF EXISTS (SELECT 1 FROM SYS.OBJECTS WHERE NAME = 'FK_Archiv_Zugarchiv_FigurUTF8' AND TYPE='F')
	--	ALTER TABLE [Archiv].[Zugarchiv] DROP CONSTRAINT [FK_Archiv_Zugarchiv_FigurUTF8]
	--IF EXISTS (SELECT 1 FROM SYS.OBJECTS WHERE NAME = 'FK_Infrastruktur_Spielbrett_FigurUTF8' AND TYPE='F')
	--	ALTER TABLE [Infrastruktur].[Spielbrett] DROP CONSTRAINT [FK_Infrastruktur_Spielbrett_FigurUTF8]
	--IF EXISTS (SELECT 1 FROM SYS.OBJECTS WHERE NAME = 'PK_Figur' AND TYPE='F')
	--	ALTER TABLE [Infrastruktur].[Figur] DROP CONSTRAINT [PK_Figur]
	--GO

	
-- Tabellen
	DROP TABLE IF EXISTS [Infrastruktur].[TheoretischeAktionen]
	DROP TABLE IF EXISTS [Infrastruktur].[Figur]
	DROP TABLE IF EXISTS [Infrastruktur].[Spielbrett]
	DROP TABLE IF EXISTS [Infrastruktur].[Spielstaerke]
	DROP TABLE IF EXISTS [Infrastruktur].[Logo]

	DROP TABLE IF EXISTS [Spiel].[Notation]
	DROP TABLE IF EXISTS [Spiel].[Suchbaum]
	DROP TABLE IF EXISTS [Spiel].[Zeitmessung]
	DROP TABLE IF EXISTS [Spiel].[MoeglicheAktionen]
	DROP TABLE IF EXISTS [Spiel].[Konfiguration]
	DROP TABLE IF EXISTS [Spiel].[Zugverfolgung]
	DROP TABLE IF EXISTS [Spiel].[Spielbrettverlauf]
	
	DROP TABLE IF EXISTS [Statistik].[Stellungsbewertung]

	DROP TABLE IF EXISTS [Bibliothek].[Partiemetadaten]
	DROP TABLE IF EXISTS [Bibliothek].[Grossmeisterpartien]
	DROP TABLE IF EXISTS [Bibliothek].[aktuelleNachschlageoptionen]

	DROP TABLE IF EXISTS [Infrastruktur].[PNG_Stufe1]
	DROP TABLE IF EXISTS [Infrastruktur].[PNG_Stufe2]

	GO





-----------------------------
-- Aufbauarbeiten -----------
-----------------------------

-- Schemata
-- ------------------------------------------------------------------------------------------------
-- Schemata sind Ordnungsstrukturen, die der Uebersichtlichkeit dienen. Das Projekt legt im 
-- Laufe der Zeit eine Vielzahl von Objekten an. Um den Ueberblick zu behalten, werden diese 
-- nach fachlicher Verwendung gruppiert. So erscheinen sie auch sortiert im Objekt-Explorer...
-- Ausserdem erleichtern Schemata die Rechtevergabe, da nicht mehr einzelne Objekte sondern nur
-- noch die uebergeordneten Schemata berechtigt weden muessen. So kann verhindert werden, dass 
-- bspw. der Spieler SCHWARZ eien Funktzion aufruft, die fuer Spieler WEISS gedacht ist.

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Infrastruktur')	EXEC('CREATE SCHEMA [Infrastruktur]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Aufgabe')	    EXEC('CREATE SCHEMA [Aufgabe]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Statistik')	    EXEC('CREATE SCHEMA [Statistik]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Weiss')		    EXEC('CREATE SCHEMA [Weiss]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Schwarz')	    EXEC('CREATE SCHEMA [Schwarz]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Spiel')		    EXEC('CREATE SCHEMA [Spiel]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Archiv')	    EXEC('CREATE SCHEMA [Archiv]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Bibliothek')    EXEC('CREATE SCHEMA [Bibliothek]');
GO 



-- Typen
-- ------------------------------------------------------------------------------------------------
-- Benutzerdefinierte Datentypen erlauben eigene Speicherobjekte. In diesem Projekt werden sie 
-- hauptsaechlich genutzt, um Tabelleninhalte an Prozeduren und Funktionen uebergeben zu koennen



-- in dieser Datenstruktur sollen die Kriterien fuer die Stellunsgbewertung abgelegt
-- werden koennen.
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = N'typBewertung')
	CREATE TYPE typBewertung 
		AS TABLE ( 
			  [ID]							INTEGER			NOT NULL
			, [Label]						NVARCHAR(20)	NOT NULL
			, [Weiss]						FLOAT			NULL
			, [Schwarz]						FLOAT			NULL
			, [Kommentar]					NVARCHAR(200)	NOT NULL
		)
GO




-- der benutzerdefinierte Typ [typStellung] nimmt eine komplette (fiktive) Brettstellung
-- bestehend aus 64 Feldern entgegen. Er wird z.B. bei der Stellungsbewertung/-analyse
-- eingesetzt. Daher verfuegt er auch ueber die Spalten [VarianteNr] und [Suchtiefe] mit der 
-- die Suchbaeume verwaltet werden.
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = N'typStellung')
	CREATE TYPE typStellung 
		AS TABLE ( 
			  [VarianteNr]					BIGINT						NOT NULL
			, [Suchtiefe]					INTEGER						NOT NULL
			, [Spalte]						CHAR(1)						NOT NULL
			, [Reihe]						INTEGER						NOT NULL
			, [Feld]						INTEGER						NOT NULL
			, [IstSpielerWeiss]				BIT							NULL
			, [FigurBuchstabe]				CHAR(1)						NOT NULL
			, [FigurUTF8]					BIGINT						NOT NULL
		)
GO

-- Im benutzerdefinierten Typ [typNotation] wird ein einzelner Zug protokolliert. Die
-- lange Notation 
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = N'typNotation')
	CREATE TYPE typNotation 
		AS TABLE ( 
			  [VollzugID]					INTEGER						NOT NULL
			, [IstSpielerWeiss]				BIT							NOT NULL
			, [TheoretischeAktionenID]		BIGINT						NOT NULL
			, [LangeNotation]				VARCHAR(20)					NOT NULL   -- Maximaleintrag ist bspw. Se7xg8# oder e7xd8D+
			, [KurzeNotationEinfach]		VARCHAR(8)					NOT NULL   -- (lang) Le3xg5 --> wird zu (kurz) Lxg5
			, [KurzeNotationKomplex]		VARCHAR(8)					NOT NULL   -- (lang) Sb3-e4 --> wird zu (kurz) Sbe4
			, [ZugIstSchachgebot]			BIT							NOT NULL
		)
GO

-- der benutzerdefinierte Typ [typMoeglicheAktionen] entspricht in seiner Spaltendefinition der gleichnamigen 
-- Tabelle [Infrastruktur].[TheoretischeAktionen]. Hier koennen alle aus einer bestimmten Brettstellung herausspielbaren 
-- strukturiert gespeichert werden
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = N'typMoeglicheAktionen' )
	CREATE TYPE typMoeglicheAktionen
		AS TABLE ( 
			  [MoeglicheAktionenID]			BIGINT		IDENTITY(1,1)	NOT NULL
			, [TheoretischeAktionenID]		BIGINT						NOT NULL
			, [HalbzugNr]					INTEGER						NOT NULL		-- Stand der Partie, zudem die Analyse einsetzen soll
			, [FigurName]					VARCHAR(20)					NOT NULL		-- Bauer, Laeufer, Springer, Turm, Koenig, Dame
			, [IstSpielerWeiss]				BIT							NULL			-- 1 = TRUE
			, [StartSpalte]					CHAR(1)						NOT NULL		-- A-H
			, [StartReihe]					INTEGER						NOT NULL		-- 1-8
			, [StartFeld]					INTEGER						NOT NULL		-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
			, [ZielSpalte]					CHAR(1)						NOT NULL		-- A-H
			, [ZielReihe]					INTEGER						NOT NULL		-- 1-8
			, [ZielFeld]					INTEGER						NOT NULL		-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
			, [Richtung]					CHAR(2)						NOT NULL		-- Links (LI), Rechts (RE), Oben (OB) und Unten (UN) sowie die 
																						-- Kombinationen wie Rechts-Unten (RU) oder Links-Oben (LO)
			, [UmwandlungsfigurBuchstabe]	VARCHAR(20)					NULL			-- Bauer, Laeufer, Springer, Turm, Koenig, Dame
			, [ZugIstSchlag]				BIT							NOT NULL		-- 1 = TRUE
			, [ZugIstKurzeRochade]			BIT							NOT NULL		-- 1 = TRUE
			, [ZugIstLangeRochade]			BIT							NOT NULL		-- 1 = TRUE
			, [ZugIstEnPassant]				BIT							NOT NULL		-- 1 = TRUE
			, [LangeNotation]				VARCHAR(20)					NULL			-- z.B.: Le3xg5 (Laeufer auf e3 schlaegt g5) oder 
																						--       b7-b8T (Bauer von b7 nach b8 --> Bauernumwandlung in einen Turm)
			, [KurzeNotationEinfach]		VARCHAR(8)					NULL			-- z.B.: (lang) Le3xg5 --> wird zu (kurz) Lxg5
			, [KurzeNotationKomplex]		VARCHAR(8)					NULL			-- z.B.: (lang) Sb3-e4 --> wird zu (kurz) Sbe4
																						--       wenn Se4 alleine nicht eindeutig wäre, da auch 
																						--		 auf c2 ein Springer steht, der ebenfalls e4 erreichen kann
			, [Bewertung]					FLOAT						NULL			-- je groesser, je besser. positiv = weiss im Vorteil
			)
GO



-- Tabellen
-- ------------------------------------------------------------------------------------------------
-- Tabellen dienen zur dauerhaften Speicherung von Daten - 


-- Diese Tabelle nimmt Daten vom Typ GEOGRAPHY auf, um damit das Spiellogo zu malen
CREATE TABLE [Infrastruktur].[Logo]
  (
         [ID]              INTEGER				IDENTITY(1, 1)	NOT NULL Primary Key
       , [Gebietname]      NVARCHAR(50)
       , GEBIET            GEOGRAPHY); 
 GO 


-- Diese Tabelle soll alle Zustaende abbilden, die die Belegung eines einzelnen Feldes 
-- darstellen. Es kann jede vorhandene Figur sowie der Zustand "keine Figur" (Leerfeld) 
-- vorkommen. Ueber den UTF-8-Wert lassen sich grafische Darstellungen von Figuren 
-- simulieren (--> SELECT NCHAR(9812))
CREATE TABLE [Infrastruktur].[Figur](
	  [FigurUTF8]				BIGINT			NOT NULL					-- UTF8-Wert der Figurengrafik
	, [IstSpielerWeiss]			BIT				NULL						-- 1 = TRUE
	, [FigurName]				NVARCHAR(20)	NOT NULL					-- Bauer, Laeufer, Springer, Turm, Koenig, Dame
	, [FigurBuchstabe]			CHAR(1)			NOT NULL					-- (B)auer, (L)aeufer, (S)pringer, (T)urm, (K)oenig, (D)ame
	, [FigurSymbol]				NCHAR(1)		NOT NULL					-- bspw. SELECT NCHAR(9812), siehe Spalte [FigurUTF8]
	, [FigurWert]				INTEGER			NOT NULL					-- Standard: Bauer=1, Laeufer=3, Springer=3, Turm=5, Dame=10
																			-- der Koenig ist unbezahlbar. Hier koennen taktisch ein paar
																			-- Stellschrauben gesetzt werden.
	,
 CONSTRAINT [PK_Figur] PRIMARY KEY CLUSTERED 
(
	    [FigurUTF8]			ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- -----------------------------------------------------------------------------------------------------------------

-- Diese Tabelle soll alle theoretisch denkbaren Zuege unabhaengig von der tatsaechlichen 
-- Brettsituation aufnehmen. Wir betrachten also, auf welchen Feldern eine bestimmte Figur
-- ueberhaupt stehen kann (ein weisser Bauer kann laut Regelwerk bspw. nie das Feld "e1" 
-- besetzen) und welche Felder diese Figur von dort aus ueberhaupt legal erreichen kann 
-- (wenn da Brett ansonsten leer waere). Dabei unterscheiden wir Zuege und Schlaege, denn 
-- einige Figuren wie bspw. der Bauer, ziehen anders als sie schlagen...
CREATE TABLE [Infrastruktur].[TheoretischeAktionen](
	  [TheoretischeAktionenID]		BIGINT		IDENTITY(1,1)	NOT NULL
	, [FigurName]					VARCHAR(20)					NOT NULL		-- Bauer, Laeufer, Springer, Turm, Koenig, Dame
		CHECK ([FigurName] IN ('Bauer', 'Laeufer', 'Springer', 'Turm', 'Koenig', 'Dame'))
	, [IstSpielerWeiss]				BIT							NULL			-- 1 = TRUE
	, [StartSpalte]					CHAR(1)						NOT NULL		-- A-H
	, [StartReihe]					INTEGER						NOT NULL		-- 1-8
	, [StartFeld]					INTEGER						NOT NULL		-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
	, [ZielSpalte]					CHAR(1)						NOT NULL		-- A-H
	, [ZielReihe]					INTEGER						NOT NULL		-- 1-8
	, [ZielFeld]					INTEGER						NOT NULL		-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
	, [Richtung]					CHAR(2)						NOT NULL		-- Links (LI), Rechts (RE), Oben (OB) und Unten (UN) sowie die 
																				-- Kombinationen wie Rechts-Unten (RU) oder Links-Oben (LO)
		CHECK ([Richtung] IN ('OB', 'RO', 'RE', 'RU', 'UN', 'LU', 'LI', 'LO'))
	, [UmwandlungsfigurBuchstabe]	CHAR(1)					NULL			-- Laeufer, Springer, Turm, Dame
		CHECK ([UmwandlungsfigurBuchstabe] IN (NULL, 'L', 'S', 'T', 'D'))
	, [ZugIstSchlag]				BIT							NOT NULL		-- 1 = TRUE
	, [ZugIstKurzeRochade]			BIT							NOT NULL		-- 1 = TRUE
	, [ZugIstLangeRochade]			BIT							NOT NULL		-- 1 = TRUE
	, [ZugIstEnPassant]				BIT							NOT NULL		-- 1 = TRUE
	, [LangeNotation]				VARCHAR(20)					NULL			-- z.B.: Le3xg5 (Laeufer auf e3 schlaegt g5) oder 
																				--       b7-b8T (Bauer von b7 nach b8 --> Bauernumwandlung in einen Turm)
	, [KurzeNotationEinfach]		VARCHAR(8)					NULL			-- z.B.: (lang) Le3xg5 --> wird zu (kurz) Lxg5
	, [KurzeNotationKomplex]		VARCHAR(8)					NULL			-- z.B.: (lang) Sb3-e4 --> wird zu (kurz) Sbe4
																				--       wenn Se4 alleine nicht eindeutig wäre, da auch 
																				--		 auf c2 ein Springer steht, der ebenfalls e4 erreichen kann
	,
 CONSTRAINT [PK_TheoretischeAktionen] PRIMARY KEY CLUSTERED 
(
	    [TheoretischeAktionenID]		ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- -----------------------------------------------------------------------------------------------------------------

-- Diese Tabelle soll alle in der tatsaechlichen Brettsituation moeglichen Zuege 
-- aufnehmen. Dies koennen nur Zuege sein, die
--   * in der Tabelle [Infrastruktur].[TheoretischeAktionen] stehen
--   * ein Startfeld haben, welches in der aktuellen Brettsituation mit einer 
--     Figur der passenden Farbe besetzt ist
--   * bei dem die Spielregeln einen Zug nicht verhindern (bspw. in dem weitere Figuren
--     im Wege zwischen dem Start und dem Zielfeld stehen)
--   * eine Figur bewegen, die nicht gefesselt ist
-- Strukturell gleicht die Tabelle [Spiel].[MoeglicheAktionen] der Tabelle [Infrastruktur].[TheoretischeAktionen]
CREATE TABLE [Spiel].[MoeglicheAktionen](
	  [MoeglicheAktionenID]			BIGINT		IDENTITY(1,1)	NOT NULL		-- Primaerschluessel, Surrogatkey
	, [TheoretischeAktionenID]		BIGINT						NOT NULL		-- Fremdschluessel auf [Infrastruktur].[TheoretischeAktionen]
	, [HalbzugNr]					INTEGER						NOT NULL		-- Stand der Partie, fuer den diese Zuege ausfuehrbar sind
	, [FigurName]					VARCHAR(20)					NOT NULL		-- Bauer, Laeufer, Springer, Turm, Koenig, Dame
		CHECK ([FigurName] IN ('Bauer', 'Laeufer', 'Springer', 'Turm', 'Koenig', 'Dame'))
	, [IstSpielerWeiss]				BIT							NULL			-- 1 = TRUE
	, [StartSpalte]					CHAR(1)						NOT NULL		-- A-H
	, [StartReihe]					INTEGER						NOT NULL		-- 1-8
	, [StartFeld]					INTEGER						NOT NULL		-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
	, [ZielSpalte]					CHAR(1)						NOT NULL		-- A-H
	, [ZielReihe]					INTEGER						NOT NULL		-- 1-8
	, [ZielFeld]					INTEGER						NOT NULL		-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
	, [Richtung]					CHAR(2)						NOT NULL		-- Links (LI), Rechts (RE), Oben (OB) und Unten (UN) sowie die 
																				-- Kombinationen wie Rechts-Unten (RU) oder Links-Oben (LO)
		CHECK ([Richtung] IN ('OB', 'RO', 'RE', 'RU', 'UN', 'LU', 'LI', 'LO'))
	, [UmwandlungsfigurBuchstabe]	VARCHAR(20)					NULL			-- Bauer, Laeufer, Springer, Turm, Koenig, Dame
		CHECK ([UmwandlungsfigurBuchstabe] IN ('L', 'S', 'T', 'D'))
	, [ZugIstSchlag]				BIT							NOT NULL		-- 1 = TRUE
	, [ZugIstKurzeRochade]			BIT							NOT NULL		-- 1 = TRUE
	, [ZugIstLangeRochade]			BIT							NOT NULL		-- 1 = TRUE
	, [ZugIstEnPassant]				BIT							NOT NULL		-- 1 = TRUE
	, [LangeNotation]				VARCHAR(20)					NULL			-- z.B.: Le3xg5 (Laeufer auf e3 schlaegt g5) oder 
																				--       b7-b8T (Bauer von b7 nach b8 --> Bauernumwandlung in einen Turm)
	, [KurzeNotationEinfach]		VARCHAR(8)					NULL			-- z.B.: (lang) Le3xg5 --> wird zu (kurz) Lxg5
	, [KurzeNotationKomplex]		VARCHAR(8)					NULL			-- z.B.: (lang) Sb3-e4 --> wird zu (kurz) Sbe4
																				--       wenn Se4 alleine nicht eindeutig wäre, da auch 
																				--		 auf c2 ein Springer steht, der ebenfalls e4 erreichen kann
	, [Bewertung]					FLOAT						NULL			-- Gegenwert in Bauerneinheiten, positiv = WEISS hat Vorteil, negativ = SCHWARZ im Vorteil
	,
 CONSTRAINT [PK_MoeglicheZuege] PRIMARY KEY CLUSTERED 
(
	    [MoeglicheAktionenID]		ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

---- In die Spalte [TheoretischeAktionenID] duerfen nur Werte eingetragen werden, die 
---- auch in der Tabelle [Infrastruktur].[TheoretischeAktionen] vorkommen!
--ALTER TABLE [Spiel].[MoeglicheAktionen] 
--	ADD CONSTRAINT [FK_Spiel_MoeglicheAktionen_TheoretischeAktionen] 
--	FOREIGN KEY ([TheoretischeAktionenID]) REFERENCES [Infrastruktur].[TheoretischeAktionen]([TheoretischeAktionenID]);
--GO

-- -----------------------------------------------------------------------------------------------------------------

-- Diese Tabelle stellt das aktuelle Spielbrett dar. Fuer jedes Feld (Kombination aus Reihe 
-- und Spalte) wird festgehalten, ob und durch wen dieses Feld belegt ist.
CREATE TABLE [Infrastruktur].[Spielbrett](
	  [Spalte]					CHAR(1)		NOT NULL						-- A-H
	, [Reihe]					INTEGER		NOT NULL						-- 1-8
	, [Feld]					INTEGER		NOT NULL						-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
	, [IstSpielerWeiss]			BIT			NULL							-- 1 = TRUE
	, [FigurBuchstabe]			CHAR(1)		NOT NULL						-- (L)aeufer, (S)pringer, (T)urm, (K)oenig, (D)ame / Bauer = NULL
		CHECK ([FigurBuchstabe] IN (NULL, 'L', 'S', 'T', 'K', 'D'))
	, [FigurUTF8]				BIGINT		NOT NULL						-- UTF8-Wert der Figurengrafik
	, CONSTRAINT [PK_Spielbrett] PRIMARY KEY CLUSTERED
		(
			  [Feld]			ASC
		)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, 
		ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY]
GO

ALTER TABLE [Infrastruktur].[Spielbrett] ADD CONSTRAINT [FK_Infrastruktur_Spielbrett_FigurUTF8] FOREIGN KEY ([FigurUTF8]) REFERENCES [Infrastruktur].[Figur]([FigurUTF8]);
GO

-- -----------------------------------------------------------------------------------------------------------------


-- Diese Tabelle stellt das aktuelle Spielbrett im Verlauf der gesamten Partie dar. 
-- Fuer jedes Feld (Kombination aus Reihe und Spalte) wird festgehalten, ob und durch wen dieses Feld belegt ist.
-- Diese Ansicht wird fuer jeden Zug vollstaendig wiederholt
CREATE TABLE [Spiel].[Spielbrettverlauf](
	  [VollzugID]					BIGINT		NOT NULL						-- Brettansicht VOR dem genannten Vollzug
	, [Spalte]						CHAR(1)		NOT NULL						-- A-H
	, [Reihe]						INTEGER		NOT NULL						-- 1-8
	, [Feld]						INTEGER		NOT NULL						-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
	, [IstSpielerWeiss]				BIT			NOT NULL						-- 1 = TRUE
	, [FigurBuchstabe]				CHAR(1)		NOT NULL						-- (L)aeufer, (S)pringer, (T)urm, (K)oenig, (D)ame / Bauer = NULL
		CHECK ([FigurBuchstabe] IN (NULL, 'L', 'S', 'T', 'K', 'D'))
	, [FigurUTF8]					BIGINT		NOT NULL						-- UTF8-Wert der Figurengrafik
	, CONSTRAINT [PK_Spielbrett] PRIMARY KEY CLUSTERED
		(
			  [VollzugID]					ASC
			, [IstSpielerWeiss]				ASC
			, [Feld]						ASC
		)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, 
		ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY]
GO




-- In diesem Objekt sollen die ermittelten Werte fuer die Stellunsgbewertung zwischengespeichert
-- werden. So sind sie nicht zeitaufwaendig mehrfach zu berechnen, sondern koennen einfach 
-- ausgelesen werden. Diese Tabelle bezeiht sich ausschliesslich auf die aktuelle Stellung.
CREATE TABLE [Statistik].[Stellungsbewertung]
(
	  [ID]						INTEGER			NOT NULL
	, [Label]					NVARCHAR(20)	NOT NULL
    , [Weiss]					FLOAT			NULL
    , [Schwarz]					FLOAT			NULL
	, [Kommentar]				NVARCHAR(200)	NOT NULL
	, CONSTRAINT PK_Stellungsbewertung_ID PRIMARY KEY CLUSTERED ([ID])
)
GO




-- Die Zugverfolgung ist eine Sammlung aller historischen Stellungen des aktuellen Spiels. Es werden also 
-- alle Stellungen in ihrer Reihenfolge gespeichert udn koennen so bei Bedarf einfach wieder 
-- hergestellt werden. So laesst sich bspw. eine "Zug zuruecknehmen"-Funktion realisieren...
CREATE TABLE [Spiel].[Zugverfolgung]
(
	  [ID]						BIGINT		NOT NULL
	, [Vollzug]					INTEGER		NOT NULL
	, [Halbzug]					INTEGER		NOT NULL
	, [Spalte]					CHAR(1)		NOT NULL						-- A-H
	, [Reihe]					INTEGER		NOT NULL						-- 1-8
	, [Feld]					INTEGER		NOT NULL						-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
	, [IstSpielerWeiss]			BIT			NULL							-- 1 = TRUE
	, [FigurBuchstabe]			CHAR(1)		NOT NULL						-- (L)aeufer, (S)pringer, (T)urm, (K)oenig, (D)ame / Bauer = NULL
		CHECK ([FigurBuchstabe] IN (NULL, 'L', 'S', 'T', 'K', 'D'))
	, [FigurUTF8]				BIGINT		NOT NULL						-- UTF8-Wert der Figurengrafik
	, CONSTRAINT [PK_Zugverfolgung] PRIMARY KEY CLUSTERED
		(
			  [ID], [Halbzug], [Spalte], [Reihe]			ASC
		)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, 
		ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO




-- Die Schachuhr soll mit dieser Tabelle verwaltet werden. Die Zeitangaben werden pro Spieler rueckwaerts 
-- gezaehlt, sobald der Spieler das Zugrecht/die Zugpflicht inne hat. Eine Partie endet mit dem Verlust 
-- fuer den Spieler, dessen Zeitlimit zuerst aufgebraucht wurde, bevor die Partie auf anderem Wege (Matt, Remis, ...)
-- regulaer beendet wurde.
CREATE TABLE [Spiel].[Zeitmessung]
(
      [IstSpielerWeiss]         BIT			NOT NULL
    , [RestzeitInSek]           INTEGER		NOT NULL     
	, [StartZeitmessung]		DATETIME	NULL
	, CONSTRAINT PK_Zeitmessung_IstSpielerWeiss PRIMARY KEY CLUSTERED ([IstSpielerWeiss])
)
GO


-- Ein komplettes Spiel wird mit all seinen Zuegen in der richtigen Reihenfolge in dieser Tabelle "notiert".
-- Dabei findet sowohl die offizielle "lange Notation" aus dem Schach wie auch die interne Beschreibung durch 
-- die Eintraege aus der Tabelle [Spiel].[MoeglicheZuege] Anwendung.
CREATE TABLE [Spiel].[Notation](
	  [VollzugID]				INTEGER		NOT NULL						-- Primaerschluessel, Surrogatkey
	, [IstSpielerWeiss]			BIT			NOT NULL						-- 1 = TRUE
	, [TheoretischeAktionenID]	BIGINT		NOT NULL						-- Fremdschluessel auf [Infrastruktur].[TheoretischeAktionen]
	, [LangeNotation]			VARCHAR(20)	NOT NULL						-- Maximaleintrag ist bspw. Se7xg8# oder e7xd8D+
	, [KurzeNotationEinfach]	VARCHAR(8)					NULL			-- z.B.: (lang) Le3xg5 --> wird zu (kurz) Lxg5
	, [KurzeNotationKomplex]	VARCHAR(8)					NULL			-- z.B.: (lang) Sb3-e4 --> wird zu (kurz) Sbe4
																			--       wenn Se4 alleine nicht eindeutig wäre, da auch 
																			--		 auf c2 ein Springer steht, der ebenfalls e4 erreichen kann
	, [ZugIstSchachgebot]		BIT			NOT NULL						-- 1 = TRUE
	, CONSTRAINT [PK_Notation] PRIMARY KEY CLUSTERED
		(
			  [VollzugID] ASC, [IstSpielerWeiss] ASC
		)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, 
		ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- In die Spalte [TheoretischeAktionenID] duerfen nur Werte eingetragen werden, die 
-- auch in der Tabelle [Infrastruktur].[TheoretischeAktionen] vorkommen!
ALTER TABLE [Spiel].[Notation] 
	ADD CONSTRAINT [FK_Spiel_Notation_TheoretischeAktionen] 
	FOREIGN KEY ([TheoretischeAktionenID]) REFERENCES [Infrastruktur].[TheoretischeAktionen]([TheoretischeAktionenID]);
GO

-- -----------------------------------------------------------------------------------------------------------------

-- Dieses Programm kann Computergegner mit unterschiedlicher Spielstaerke simulieren. Die Stellschrauben fuer 
-- die Geschicklichkeit, mit der ein Computergegner agiert, finden sich zum einen natuelich in der Suchtiefe
-- der Vorausberechnung - zum anderen aber auch in der Antwort auf die Frage, welche Kriterien herangezogen 
-- werden, um eine Stellung zu bewerten. Detailliertere Stelllungsbewertungen fuehren zu einem staerkeren 
-- Spiel, verbrauchen aber auch deutlich mehr Ressourcen.
CREATE TABLE [Infrastruktur].[Spielstaerke](
	  [SpielstaerkeID]							INTEGER			NOT NULL
	, [Klartext]								VARCHAR(20)		NOT NULL	-- Name des Spielstaerke, bspw. "Kindergarten"
	, [GrossmeisterpartienAnzeigen]				BIT				NOT NULL	-- 1 = TRUE, darf die Eröffnungsbibliothek zum SPICKEN genutzt werden?
	, [ZuberechnenSummeFigurWert]				BIT				NOT NULL	-- 1 = TRUE, soll dieses Kriterium bei der Stellunsgbewertung einfliessen?
	, [ZuberechnenAnzahlAktionen]				BIT				NOT NULL	-- 1 = TRUE, soll dieses Kriterium bei der Stellunsgbewertung einfliessen?
	, [ZuberechnenAnzahlSchlagmoeglichkeiten]	BIT				NOT NULL	-- 1 = TRUE, soll dieses Kriterium bei der Stellunsgbewertung einfliessen?
	, [ZuberechnenAnzahlRochaden]				BIT				NOT NULL	-- 1 = TRUE, soll dieses Kriterium bei der Stellunsgbewertung einfliessen?
	, [ZuberechnenBauernvormarsch]				BIT				NOT NULL	-- 1 = TRUE, soll dieses Kriterium bei der Stellunsgbewertung einfliessen?
	, [ZuberechnenAnzahlFreibauern]				BIT				NOT NULL	-- 1 = TRUE, soll dieses Kriterium bei der Stellunsgbewertung einfliessen?
	, [ZuberechnenBauernkette]					BIT				NOT NULL	-- 1 = TRUE, soll dieses Kriterium bei der Stellunsgbewertung einfliessen?
	, CONSTRAINT [PK_Spielstaerke] PRIMARY KEY CLUSTERED
		(
			   [SpielstaerkeID] ASC
		)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, 
		ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY]
GO


-- Fuer das aktuelle Spiel wird hier abgelegt, welche Eigenschaften die Spieler
-- fuer WEISS und SCHWARZ haben
CREATE TABLE [Spiel].[Konfiguration]
(
      [IstSpielerWeiss]				BIT				NOT NULL
	, [Spielername]					NVARCHAR(30)	NOT NULL
    , [SpielstaerkeID]				INTEGER			NOT NULL     
	, [RestzeitInSekunden]			INTEGER			NOT NULL
	, [ZeitpunktLetzterZug]			DATETIME2		NULL
	, [ComputerSchritteAnzeigen]	BIT				NOT NULL
	, [IstKurzeRochadeErlaubt]		BIT				NOT NULL
	, [IstLangeRochadeErlaubt]		BIT				NOT NULL
	, CONSTRAINT PK_Konfiguration_IstSpielerWeiss PRIMARY KEY CLUSTERED ([IstSpielerWeiss])
)

-- In die Spalte [SpielstaerkeID] duerfen nur Werte eingetragen werden, die 
-- auch in der Tabelle [Infrastruktur].[Spielstaerke] vorkommen!
ALTER TABLE [Spiel].[Konfiguration]
	ADD CONSTRAINT [FK_Spiel_Konfiguration_SpielstaerkeID] 
	FOREIGN KEY ([SpielstaerkeID]) REFERENCES [Infrastruktur].[Spielstaerke]([SpielstaerkeID]);
GO
-- -----------------------------------------------------------------------------------------------------------------

-- Um eine Spielsituation realistisch einschaetzen und bewerten zu koennen, reicht es nicht den aktuellen
-- Spielstand zu analysieren. Gute Schachspieler (und -programme) "blicken" einige Zuege voraus. Das 
-- Programm benoetigt daher einen Suchbaum nach dem Minimax-Algorithmus, fuer den hier die notwendige 
-- Datenstruktur geschaffen wird
CREATE TABLE [Spiel].[Suchbaum](
	  [SuchbaumID]					BIGINT		IDENTITY(1,1)	NOT NULL
	, [VorgaengerID]				BIGINT						NULL			-- gibt den uebergeordneten Knoten des Suchbaumes an
		CONSTRAINT FK_Suchbaum_Suchbaum FOREIGN KEY ([VorgaengerID])
		REFERENCES [Spiel].[Suchbaum] ([SuchbaumID])
	, [TheoretischeAktionID]		BIGINT						NOT NULL		-- FK, gibt den durchgefuehrten Zug an
	, [Suchtiefe]					TINYINT						NOT NULL		-- je hoeher je genauer - aber auch je ressourcenhungriger, entspricht einem Halbzug
	, [Stellungsbewertung]			FLOAT						NULL			-- NULL solange unbewertet, positiv = Vorteil WEISS, je hoeher je besser
	, [IstNochRelevant]				BIT							NOT NULL		-- 1 = TRUE. Wennn FALSE, dann keine tiefere Suche mehr durchfuehren
	,
 CONSTRAINT [PK_Suchbaum] PRIMARY KEY CLUSTERED 
(
	    [SuchbaumID]		ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- In die Spalte [VorgaengerID] duerfen nur Werte eingetragen werden, die 
-- auch in der Tabelle [Spiel].[Suchbaum] als [SuchbaumID] vorkommen!
ALTER TABLE [Spiel].[Suchbaum]
	ADD CONSTRAINT [FK_Spiel_Suchbaum_Suchbaum] 
	FOREIGN KEY ([VorgaengerID]) REFERENCES [Spiel].[Suchbaum]([SuchbaumID]);
GO
-- -----------------------------------------------------------------------------------------------------------------

-- Das Programm bietet das Feature beliebige Schachpartien, die im PGN-Format vorliegen, einzulesen und so bspw. eine 
-- Eröffnungsbibliothek aufzubauen. Diese strukturierten Textdateien finden man zum (solange sie NICHT kommentiert sind)
-- kostenlosen Download im Internet bspw. mit den Grossmeisterpartien der Welt- und Europmeisterschaften.
-- Das arelium-TSQL-Schach ist in der Lage diese Dateien zu importieren. Jede Partie besteht dabei aus zwei Bloecken:
--     - die Metadaten wie bspw. das Veranstaltunsgdatum, die Spielernamen, deren ELO-Zahl (eine Spielstaerkeangabe), ...
--     - die Partie in der kurzen Notation

-- Die Tabelle [Bibliothek].[Partiemetadaten] soll nun die einzelnen Partien (pro Datei koennen dies schonmal einige 
-- tausend sein) durchnummerieren und die Metadaten aufnehmen. Die einzelnen Zuege werden separat in einer anderen
-- Tabelle gespeichert, der Link wird ueber die [BibliothekID] hergestellt.
CREATE TABLE [Bibliothek].[Partiemetadaten](
	  [PartiemetadatenID]		[BIGINT]		IDENTITY(1,1)		NOT NULL			-- Primaerschlüssel
	, [Quelle]					[NVARCHAR](50)						NOT NULL			-- benennt die IMPORT-Datei
	, [Seite]					[NVARCHAR](50)						NULL				--
	, [Veranstaltungsdatum]		[NVARCHAR](50)						NULL				-- Datum der Partie
	, [Runde]					[VARCHAR](4)						NULL				-- Rudne im Turnier
	, [Weiss]					[NVARCHAR](50)						NULL				-- Spielername WEISS
	, [Schwarz]					[NVARCHAR](50)						NULL				-- Spielername SCHWARZ
	, [Ergebnis]				[NVARCHAR](7)						NULL				-- 1:0 = Sieg WEISS, 0:1 = Sieg SCHWARZ, 1/2:1/2 = Remis
	, [EloWertWeiss]			[BIGINT]							NULL				-- Spielstaerkeindikator WEISS - je hoeher je besser
	, [EloWertSchwarz]			[BIGINT]							NULL				-- Spielstaerkeindikator SCHWARZ - je hoeher je besser
	, [ECO]						[NVARCHAR](30)						NULL				-- ECO = Encyclopaedia of Chess Openings, eine eindeutige ID der Schacheroeffnung, bspw. "Koenigsindisch"
	, [KurzeNotation]			[NVARCHAR](max)						NOT NULL
 CONSTRAINT [PK_Partiemetadaten] PRIMARY KEY CLUSTERED 
(
	[PartiemetadatenID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO



CREATE TABLE [Infrastruktur].[PNG_Stufe1]
(
    GanzeZeile		VARCHAR(MAX)
)
GO
 

CREATE TABLE [Infrastruktur].[PNG_Stufe2]
(
      ZeilenNr		BIGINT
	, GanzeZeile	VARCHAR(MAX)
)
GO




CREATE TABLE [Bibliothek].[Grossmeisterpartien]
(
	  [PartiemetadatenID]	BIGINT			NOT NULL
	, [Zugnummer]			INTEGER			NOT NULL
	, [ZugWeiss]			VARCHAR(12)		NULL
	, [ZugSchwarz]			VARCHAR(12)		NULL
)
GO

-- ---------------------------------------------------------------------------------
-- Archivfunktionen
-- ---------------------------------------------------------------------------------
-- Diese T-SQL-Eigenentwicklung wurde zur Ausbildung von Mitarbeitern der arelium GmbH aus Langenfeld geschaffen.
-- Ein Schwerpunkt soll die Abfrage grosser Datenmengen und ihre statistische Auswertung sein. Dazu protokolliert 
-- dieses Programm jedes Spiel detailliert mit. Spaeter koennen somit nur nur einfache Fragestellungen wie "War 
-- Weiss oder Schwarz in der Vergangenheit die ueber alle Partien siegreichere Farbe?" sondern auch komplexe 
-- Abfragen wie "bis zu welchem Zug muss Weiss spaetestens rochiert haben, um mit einer Wahrscheinlichkeit von 
-- 72% mindestens ein Remis zu erreichen, wenn Schwarz nicht 'koenigsindisch' eroeffnet?"


-- Diese Tabelle fuehrt die Statistik auf Partiebene. Sie gibt Aufschluss darueber, wer gegen wen mit welchem 
-- Ergebnis gespielt hat.
--CREATE TABLE [Archiv].[Partien](
--	  [PartieID]								BIGINT			IDENTITY(1,1)		NOT NULL
--	, [WeissSpielstaerkeID]						INTEGER								NOT NULL
--	, [SchwarzSpielstaerkeID]					INTEGER								NOT NULL
--	, [PunkteWeiss]								FLOAT									NULL		-- NULL = Partie laeuft noch
--	, [PunkteSchwarz]							FLOAT									NULL		-- NULL = Partie laeuft noch
--	, [Ergebnisbegruendung]						VARCHAR(7)								NULL		-- NULL = Partie laeuft noch
--	, CONSTRAINT [PK_Archivpartien] PRIMARY KEY CLUSTERED
--		(
--			   [PartieID] ASC
--		)
--	WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, 
--		ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
--	) ON [PRIMARY]
--GO

--ALTER TABLE [Archiv].[Partien] ADD CONSTRAINT chkPunkteWeiss CHECK ([PunkteWeiss] IN (0, 0.5, 1));  
--GO

--ALTER TABLE [Archiv].[Partien] ADD CONSTRAINT chkPunkteSchwarz CHECK ([PunkteSchwarz] IN (0, 0.5, 1));  
--GO

--ALTER TABLE [Archiv].[Partien] ADD CONSTRAINT chkErgebnisbegruendung CHECK ([Ergebnisbegruendung] IN ('Matt', 'Patt', 'Remis', 'Aufgabe', 'Timeout'));  
--GO

--ALTER TABLE [Archiv].[Partien] ADD CONSTRAINT [FK_Archiv_Partien_WeissSpielstaerkeID] FOREIGN KEY ([WeissSpielstaerkeID]) REFERENCES [Infrastruktur].[Spielstaerke]([SpielstaerkeID])
--GO

--ALTER TABLE [Archiv].[Partien] ADD CONSTRAINT [FK_Archiv_Partien_SchwarzSpielstaerkeID] FOREIGN KEY ([SchwarzSpielstaerkeID]) REFERENCES [Infrastruktur].[Spielstaerke]([SpielstaerkeID])
--GO


-- Diese Tabelle nimmt alle je durchgefuehrten Zuege auf. Sie wird stets am Ende einer Partie mit den Eintraegen aus der 
-- Tabelle [Spiel].[Notation] gefuellt
--CREATE TABLE [Archiv].[Zuege](
--	  [PartieID]				BIGINT		NOT NULL
--	, [VollzugID]				INTEGER		NOT NULL
--	, [IstSpielerWeiss]			BIT			NOT NULL			-- 1 = TRUE
--	, [TheoretischeAktionenID]	BIGINT		NOT NULL
--	, [LangeNotation]			VARCHAR(20)	NOT NULL			-- Maximaleintrag ist bspw. Se7xg8# oder e7xd8D+
--	, [ZugIstSchachgebot]		BIT			NOT NULL			-- 1 = TRUE
--	, CONSTRAINT [PK_ArchibZuege] PRIMARY KEY CLUSTERED
--		(
--			   [PartieID] ASC, [VollzugID] ASC
--		)
--	WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, 
--		ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
--	) ON [PRIMARY]
--GO

--ALTER TABLE [Archiv].[Zuege] ADD CONSTRAINT [FK_Archiv_Zuege_PartieID] FOREIGN KEY ([PartieID]) REFERENCES [Archiv].[Partien]([PartieID])
--GO




-- Diese Tabelle bildet das aktuelle Spielbrett zum Zeitpunkt jedes einzelnen Zuges 
-- ab. Fuer jedes Feld (Kombination aus Reihe und Spalte) wird festgehalten, ob und 
-- durch wen dieses Feld belegt ist. Die Tabelle wird beim Start jedes Spiels geleert,
-- ihr vollstaeniger Inhalt wird beim Spielende dauerhaft in die Tabelle 
-- [Archiv].[Zugarchiv] uebernommen!
--CREATE TABLE [Spiel].[Zugarchiv](
--	  [HalbzugID]				INTEGER		NOT NULL
--	, [Spalte]					CHAR(1)		NOT NULL			-- A-H
--	, [Reihe]					INTEGER		NOT NULL			-- 1-8
--	, [Feld]					INTEGER		NOT NULL			-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
--	, [IstSpielerWeiss]			BIT			NULL				-- 1 = TRUE
--	, [FigurBuchstabe]			CHAR(1)		NOT NULL			-- (B)auer, (L)aeufer, (S)pringer, (T)urm, (K)oenig, (D)ame
--	, [FigurUTF8]				BIGINT		NOT NULL			-- UTF8-Wert der Figurengrafik
--)
--GO

--ALTER TABLE [Spiel].[Zugarchiv] ADD CONSTRAINT [FK_Spiel_Zugarchiv_FigurUTF8] FOREIGN KEY ([FigurUTF8]) REFERENCES [Infrastruktur].[Figur]([FigurUTF8])
--GO





-- Diese Tabelle bildet das aktuelle Spielbrett zum Zeitpunkt jedes einzelnen Zuges 
-- ab - und das dauerhaft fuer jedes Spiel. Fuer jedes Feld (Kombination aus Reihe 
-- und Spalte) wird festgehalten, ob und durch wen dieses Feld belegt ist. Die Tabelle 
-- bleibt auch beim Start eines neuen Spiels bestehen!
--CREATE TABLE [Archiv].[Zugarchiv](
--	  [SpielID]					BIGINT		NOT NULL
--	, [HalbzugID]				INTEGER		NOT NULL
--	, [Spalte]					CHAR(1)		NOT NULL			-- A-H
--	, [Reihe]					INTEGER		NOT NULL			-- 1-8
--	, [Feld]					INTEGER		NOT NULL			-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
--	, [IstSpielerWeiss]			BIT			NULL				-- 1 = TRUE
--	, [FigurBuchstabe]			CHAR(1)		NOT NULL			-- (B)auer, (L)aeufer, (S)pringer, (T)urm, (K)oenig, (D)ame
--	, [FigurUTF8]				BIGINT		NOT NULL			-- UTF8-Wert der Figurengrafik
--)
--GO

--ALTER TABLE [Archiv].[Zugarchiv] ADD CONSTRAINT [FK_Archiv_Zugarchiv_FigurUTF8] FOREIGN KEY ([FigurUTF8]) REFERENCES [Infrastruktur].[Figur]([FigurUTF8])
--GO







------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '010 - Datenstrukturen aufbauen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO
