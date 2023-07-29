-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Beispielimplementation des MinMaxAlgorithmus                                        ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Im Schach planen fortgeschrittene Spieler ihre Aktionen fuer einige Zuege im        ###
-- ### Voraus. In einigen Situationen ist ein kurzfristiges Absenken der                   ###
-- ### Stellungsbewertung auch in einem drastischen Masse durchaus akzeptabel, bspw. bei   ###
-- ### einem Damenopfer, welches aber kurze Zeit spaeter ein Matt ermoeglicht.             ###
-- ###                                                                                     ###
-- ### Um jetzt ausgehend von der aktuellen Stellung auch Spielsituationen in einigen      ###
-- ### Zuegen Entfernung beurteilen zu koennen, wird der minimax-Algorithmus eingesetzt.   ###
-- ### Siehe: https://de.wikipedia.org/wiki/Minimax-Algorithmus                            ###
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




/*
jeder Kasten stellt einen potentiellen Zug dar. Links im Kasten steht die Stellungsbewertung, rechts 
daneben steht die ID des Kastens. Schwarz versucht die Stellunsgbewertung zu minimieren, WEISS diese 
zu maximieren. Kann WEISS matt setzen (#) wird dies mit +99 bewertet. Setzt SCHWARZ matt (-#) mit -99

Im ersten Schritt wird die Datenstruktur in Form der Tabelle [Spiel].[Suchbaum] aufgebaut. Die 
einzelnen Kaesten werden dabei von oben nach unten (nach Suchtiefe) und von links nach rechts 
durchnummeriert.

Zu jeder Stellung wird dann ermittelt, wieviele moegliche Fortsetzungen es gibt. Der jeweils ermittelte 
Zug wird aus der Tabelle [Infrastruktur].[TheoretischeAktionen] notiert und der Suchbaum wird 
entsprechend bis zur maximalen Suchtiefe (hier 4 Halbzuege = 2 Zuege pro Spieler) ausgebaut. Die Bewertung 
der einzelnen Stellungen wird erst spaeter und nur fuer ausgewaehlte Stellungen durchgefuehrt!
                                                         
                                                      ┌──┴──┐
                                                      │ ?| 1│                                                aktuelle Position
                                                      └──┬──┘
                       ┌─────────────────────────────────┼──────────────────┐                                Zug von WEISS
                    ┌──┴──┐                           ┌──┴──┐            ┌──┴──┐
                    │ ?| 2│                           │ ?| 3│            │ ?| 4│                             1. Halbzug (nach Zug WEISS)
                    └──┬──┘                           └──┬──┘            └──┬──┘
         ┌─────────────┼──────────────────┐              │          ┌───────┴────────┐                       Zug von SCHWARZ
      ┌──┴──┐       ┌──┴──┐            ┌──┴──┐        ┌──┴──┐    ┌──┴──┐          ┌──┴──┐
      │ ?| 5│       │ ?| 6│            │ ?| 7│        │ ?| 8│    │ ?| 9│          │ ?|10│                    2. Halbzug (nach Zug SCHWARZ)
      └──┬──┘       └──┬──┘            └──┬──┘        └──┬──┘    └─────┘          └──┬──┘
         │       ┌─────┴─────┐            │        ┌─────┴─────┐               ┌─────┴─────┐                 Zug von WEISS
      ┌──┴──┐ ┌──┴──┐     ┌──┴──┐      ┌──┴──┐  ┌──┴──┐     ┌──┴──┐         ┌──┴──┐     ┌──┴──┐
      │ ?|11│ │ ?|12│     │ ?|13│      │ ?|14│  │ ?|15│     │ ?|16│         │ ?|17│     │ ?|18│              3. Halbzug (nach Zug WEISS)
      └──┬──┘ └─────┘     └──┬──┘      └─────┘  └──┬──┘     └──┬──┘         └──┬──┘     └──┬──┘
    ┌────┴────┐        ┌─────┴───┬────────┐        │       ┌───┴───┐       ┌───┴───┐       │                 Zug von SCHWARZ
 ┌──┴──┐   ┌──┴──┐  ┌──┴──┐   ┌──┴──┐  ┌──┴──┐  ┌──┴──┐ ┌──┴──┐ ┌──┴──┐ ┌──┴──┐ ┌──┴──┐ ┌──┴──┐ 
 │ ?|19│   │ ?|20│  │ ?|21│   │ ?|22│  │ ?|23│  │ ?|24│ │ ?|25│ │ ?|26│ │ ?|27│ │ ?|28│ │ ?|29│              4. Halbzug (nach Zug SCHWARZ)
 └─────┘   └─────┘  └─────┘   └─────┘  └─────┘  └─────┘ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘
*/

CREATE OR ALTER PROCEDURE [Spiel].[prcMinimax]
(
	  @MaxSuchtiefe					AS TINYINT
	, @EFN_Bewertungsstellung		AS VARCHAR(100)
)
AS
BEGIN
	DECLARE @EFN_Notation				AS VARCHAR(70)
	DECLARE @Metadaten					AS VARCHAR(30)
	DECLARE @IstSpielerWeiss			AS BIT
	DECLARE @RochadeMoeglichkeiten		AS VARCHAR(4)
	DECLARE @EnPassantMoeglichkeit		AS VARCHAR(2)
	DECLARE @TempString					AS VARCHAR(10)
	DECLARE @HalbzugAnzahl				AS INTEGER
	DECLARE @Zugnummer					AS INTEGER
	DECLARE @Halbzugzaehler				AS TINYINT

	--DECLARE @AktuellesSpielbrett		AS [dbo].[typStellung]
	--DECLARE @CSpielbrett				AS [dbo].[typStellung]
	--DECLARE @ID						AS BIGINT
	--DECLARE @TheoretischeAktionID		AS BIGINT
	--DECLARE @LangeNotation			AS VARCHAR(20)
	
	-- die EFN_Bewertungsstellung wird in zwei Bereiche aufgebrochen
	SET @EFN_Notation				= TRIM(LEFT(@EFN_Bewertungsstellung, CHARINDEX(' ', @EFN_Bewertungsstellung, 1)))
	SET @Metadaten					= TRIM(RIGHT(@EFN_Bewertungsstellung, LEN(@EFN_Bewertungsstellung) - CHARINDEX(' ', @EFN_Bewertungsstellung, 1)))
	
	-- welcher Spieler ist als naechstes dran?
	IF LEFT(@Metadaten, 1) = 'w'
	BEGIN
		SET @IstSpielerWeiss		= 'TRUE'
	END
	ELSE
	BEGIN
		SET @IstSpielerWeiss		= 'FALSE'
	END
	SET @Metadaten					= TRIM(RIGHT(@Metadaten, LEN(@Metadaten) - 2))
	
	-- Welche Rochadenmoeglichkeiten sind noch vorhanden?
	SET @RochadeMoeglichkeiten		= TRIM(LEFT(@Metadaten, CHARINDEX(' ', @Metadaten, 1)))
	SET @Metadaten					= TRIM(RIGHT(@Metadaten, LEN(@Metadaten) - LEN(@RochadeMoeglichkeiten) - 1))

	-- gibt die Stellung ein "en passant"-Schlag als naechste Aktion her?
	SET @EnPassantMoeglichkeit		= TRIM(LEFT(@Metadaten, CHARINDEX(' ', @Metadaten, 1)))
	SET @Metadaten					= TRIM(RIGHT(@Metadaten, LEN(@Metadaten) - LEN(@EnPassantMoeglichkeit) - 1))
	SET @EnPassantMoeglichkeit		= REPLACE(@EnPassantMoeglichkeit, '-', '')

	-- Zaehler fuer die 50-Zuege-Regel
	SET @TempString					= TRIM(LEFT(@Metadaten, CHARINDEX(' ', @Metadaten, 1)))
	SET @Metadaten					= TRIM(RIGHT(@Metadaten, LEN(@Metadaten) - LEN(@TempString) - 1))
	SET @HalbzugAnzahl				= CONVERT(INTEGER, @TempString)

	-- welches ist die naechste Zugnummer
	SET @Zugnummer					= CONVERT(INTEGER, TRIM(@Metadaten))

	-- Inhalt des Suchbaums loeschen
	SET @Halbzugzaehler				= 1
	TRUNCATE TABLE [Spiel].[Suchbaum]

	-- alle moeglichen Zuege aus der aktuellen Stellung erfassen
	INSERT INTO [Spiel].[Suchbaum] ([ID], [VorgaengerID], [Suchtiefe], [Halbzug], [TheoretischeAktionID], [LangeNotation], [StellungID], [Bewertung], [IstNochImFokus], [EFNnachZug])
	SELECT 
		  ROW_NUMBER() OVER (ORDER BY GETDATE())		AS [ID]
		, 1												AS [VorgaengerID]
		, @MaxSuchtiefe									AS [MaxSuchtiefe]
		, @Halbzugzaehler								AS [Halbzug]
		, [TheoretischeAktionenID]						AS [TheoretischeAktionenID]
		, [LangeNotation]								AS [LangeNotation]
		, 1												AS [StellungID]
		, NULL											AS [Bewertung]
		, 'TRUE'										AS [IstNochImFokus]
		, NULL											AS [EFNnachZug]
	FROM [Spiel].[MoeglicheAktionen]

	---- Die EFN-Notation wird zusaetzlich in eine Stellung ueberfuehrt
	INSERT INTO @BSpielbrett
	SELECT 1, 1, * FROM [Infrastruktur].[fncEFN2Stellung](@EFN_Bewertungsstellung)

	-- Es werden alle noch nicht EFN-codierten Stellungen gesucht und nach und nach
	-- untersucht. Dazu wird die Stellung virtuell geladen und genau der eine moegliche
	-- Zug wird (ebenfalls virtuell) ausgefuehrt. Anschliessend wird die dann neu erreichte
	-- Stellung ins das EFN-Format ueberfuehrt, welches dann im Datensatz dauerhaft
	-- gespeichert wird.
	DECLARE curEFN CURSOR FOR   
		SELECT DISTINCT [ID], [TheoretischeAktionID], [LangeNotation]
		FROM [Spiel].[Suchbaum]
		WHERE 1 = 1
			AND [EFNnachZug]		IS NULL
		ORDER BY [ID];  

	OPEN curEFN
  
		FETCH NEXT FROM curEFN INTO @ID, @TheoretischeAktionID, @LangeNotation
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
			SELECT @ID, @TheoretischeAktionID, @LangeNotation
			DROP TABLE IF EXISTS #TempSpielsituation

			-- eine neue (leere) temporaere Tabelle aus dem Nichts erschaffen
			SELECT *
			INTO #TempSpielsituation
			FROM [Infrastruktur].[Spielbrett]
			WHERE 1 = 0

						EXECUTE [Spiel].[prcZugSimulieren] @BSpielbrett, @TheoretischeAktionID

			-- Den Zug ausfuehren
			INSERT INTO #TempSpielsituation
					([Spalte], [Reihe], [Feld], [IstSpielerWeiss], [FigurBuchstabe], [FigurUTF8])  
			EXECUTE [Spiel].[prcZugSimulieren] @BSpielbrett, @TheoretischeAktionID

						--SELECT * FROM #TempSpielsituation
						--SELECT * FROM @BSpielbrett

	--		-- Die Spielvariante wegschreiben
	--		INSERT INTO @BSpielbrett
	--				([VarianteNr], [Suchtiefe], [Spalte], [Reihe], [Feld], [IstSpielerWeiss], [FigurBuchstabe], [FigurUTF8])  
	--		SELECT
	--			  (SELECT ISNULL(MAX([VarianteNr]), 0) + 1 FROM @BSpielbrett)
	--			, @Halbzugzaehler
	--			, [Spalte]
	--			, [Reihe]
	--			, [Feld]
	--			, [IstSpielerWeiss]
	--			, [FigurBuchstabe]
	--			, [FigurUTF8]
	--		FROM #TempSpielsituation


	--		-- den EFN-String ermitteln und speichern
	--		UPDATE [Spiel].[Suchbaum]
	--		SET [EFNnachZug] = (SELECT [Infrastruktur].[fncStellung2EFN] (@IstSpielerWeiss, @RochadeMoeglichkeiten, @EnPassantMoeglichkeit, @HalbzugAnzahl, @Zugnummer, @BSpielbrett))
	--		WHERE 1 = 1
	--			AND [ID] = @ID
				

			FETCH NEXT FROM curEFN INTO @ID, @TheoretischeAktionID, @LangeNotation
		END
	CLOSE curEFN;  
	DEALLOCATE curEFN; 







	-- SELECT [Infrastruktur].[fncStellung2EFN] (@IstSpielerWeiss, @RochadeMoeglichkeiten, @EnPassantMoeglichkeit, @HalbzugAnzahl, @Zugnummer, @BSpielbrett)
	-- SELECT @EFN_Bewertungsstellung
	-- SELECT * FROM @BSpielbrett
	-- SELECT * FROM [Spiel].[Suchbaum]
	

	
	-- wiederholt nun alle Zugmoeglichkeiten abarbeiten. Dabei in die Tiefe
	-- bis zur maximalen Suchtiefe gehen
	--WHILE @Halbzugzaehler <= @MaxSuchtiefe
	--BEGIN

	--	UPDATE [Spiel].[Suchbaum] 
	--	SET [Bewertung]		= 2
	--	WHERE [Bewertung]	IS NULL

	--	SET @Halbzugzaehler = @Halbzugzaehler + 1
	--END

	
END


/*
USE [arelium_TSQL_Schach_V012]
GO

DECLARE @MaxSuchtiefe tinyint
DECLARE @EFN_Bewertungsstellung varchar(100)

SET @MaxSuchtiefe = 2
SET @EFN_Bewertungsstellung = '6r1/6pp/7r/1B5K/1P3k2/N7/3R4/8 w - - 30 79'


EXECUTE [Spiel].[prcMinimax] 
   @MaxSuchtiefe
  ,@EFN_Bewertungsstellung
GO



*/





/*

	-- alle moeglichen Zuege aus der aktuellen Stellung erfassen
	INSERT INTO [Spiel].[Suchbaum] ([ID], [VorgaengerID], [Suchtiefe], [Halbzug], [TheoretischeAktionID], [LangeNotation], [StellungID], [Bewertung], [IstNochImFokus], [EFNnachZug])
	SELECT 
		  ROW_NUMBER() OVER (ORDER BY GETDATE())		AS [ID]
		, 1												AS [VorgaengerID]
		, @MaxSuchtiefe									AS [MaxSuchtiefe]
		, @Halbzugzaehler								AS [Halbzug]
		, [TheoretischeAktionenID]						AS [TheoretischeAktionenID]
		, [LangeNotation]								AS [LangeNotation]
		, 1												AS [StellungID]
		, NULL											AS [Bewertung]
		, 'TRUE'										AS [IstNochImFokus]
		, NULL											AS [EFNnachZug]
	FROM [Spiel].[MoeglicheAktionen]

	---- Die EFN-Notation wird zusaetzlich in eine Stellung ueberfuehrt
	INSERT INTO @BSpielbrett
	SELECT 1, 1, * FROM [Infrastruktur].[fncEFN2Stellung](@EFN_Bewertungsstellung)

	-- Es werden alle noch nicht EFN-codierten Stellungen gesucht und nach und nach
	-- untersucht. Dazu wird die Stellung virtuell geladen und genau der eine moegliche
	-- Zug wird (ebenfalls virtuell) ausgefuehrt. Anschliessend wird die dann neu erreichte
	-- Stellung ins das EFN-Format ueberfuehrt, welches dann im Datensatz dauerhaft
	-- gespeichert wird.
	DECLARE curEFN CURSOR FOR   
		SELECT DISTINCT [ID], [TheoretischeAktionID], [LangeNotation]
		FROM [Spiel].[Suchbaum]
		WHERE 1 = 1
			AND [EFNnachZug]		IS NULL
		ORDER BY [ID];  

	OPEN curEFN
  
		FETCH NEXT FROM curEFN INTO @ID, @TheoretischeAktionID, @LangeNotation
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
			SELECT @ID, @TheoretischeAktionID, @LangeNotation
			DROP TABLE IF EXISTS #TempSpielsituation

			-- eine neue (leere) temporaere Tabelle aus dem Nichts erschaffen
			SELECT *
			INTO #TempSpielsituation
			FROM [Infrastruktur].[Spielbrett]
			WHERE 1 = 0

						EXECUTE [Spiel].[prcZugSimulieren] @BSpielbrett, @TheoretischeAktionID

			-- Den Zug ausfuehren
			INSERT INTO #TempSpielsituation
					([Spalte], [Reihe], [Feld], [IstSpielerWeiss], [FigurBuchstabe], [FigurUTF8])  
			EXECUTE [Spiel].[prcZugSimulieren] @BSpielbrett, @TheoretischeAktionID

						--SELECT * FROM #TempSpielsituation
						--SELECT * FROM @BSpielbrett

	--		-- Die Spielvariante wegschreiben
	--		INSERT INTO @BSpielbrett
	--				([VarianteNr], [Suchtiefe], [Spalte], [Reihe], [Feld], [IstSpielerWeiss], [FigurBuchstabe], [FigurUTF8])  
	--		SELECT
	--			  (SELECT ISNULL(MAX([VarianteNr]), 0) + 1 FROM @BSpielbrett)
	--			, @Halbzugzaehler
	--			, [Spalte]
	--			, [Reihe]
	--			, [Feld]
	--			, [IstSpielerWeiss]
	--			, [FigurBuchstabe]
	--			, [FigurUTF8]
	--		FROM #TempSpielsituation


	--		-- den EFN-String ermitteln und speichern
	--		UPDATE [Spiel].[Suchbaum]
	--		SET [EFNnachZug] = (SELECT [Infrastruktur].[fncStellung2EFN] (@IstSpielerWeiss, @RochadeMoeglichkeiten, @EnPassantMoeglichkeit, @HalbzugAnzahl, @Zugnummer, @BSpielbrett))
	--		WHERE 1 = 1
	--			AND [ID] = @ID
				

			FETCH NEXT FROM curEFN INTO @ID, @TheoretischeAktionID, @LangeNotation
		END
	CLOSE curEFN;  
	DEALLOCATE curEFN; 







	-- SELECT [Infrastruktur].[fncStellung2EFN] (@IstSpielerWeiss, @RochadeMoeglichkeiten, @EnPassantMoeglichkeit, @HalbzugAnzahl, @Zugnummer, @BSpielbrett)
	-- SELECT @EFN_Bewertungsstellung
	-- SELECT * FROM @BSpielbrett
	-- SELECT * FROM [Spiel].[Suchbaum]
	

	
	-- wiederholt nun alle Zugmoeglichkeiten abarbeiten. Dabei in die Tiefe
	-- bis zur maximalen Suchtiefe gehen
	--WHILE @Halbzugzaehler <= @MaxSuchtiefe
	--BEGIN

	--	UPDATE [Spiel].[Suchbaum] 
	--	SET [Bewertung]		= 2
	--	WHERE [Bewertung]	IS NULL

	--	SET @Halbzugzaehler = @Halbzugzaehler + 1
	--END
*/