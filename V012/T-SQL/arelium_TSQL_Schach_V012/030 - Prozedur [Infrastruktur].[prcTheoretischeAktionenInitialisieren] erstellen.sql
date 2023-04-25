-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Befuellung der Tabelle [Infrastruktur].[TheoretischeAktionen]                       ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Es werden alle Zuege aller Figuren in die Tabelle geschrieben, die theoretisch      ###
-- ### innerhalb eines Schachspiels vorkommen koennen. Hierzu zaehlen nicht nur alle       ###
-- ### Zuege von Turm, Springer, Laeufer, Dame oder Koenig von jedem potentiellen          ###
-- ### Startfeld auf jedes von diesem Feld aus in einem Zug erreichbare Zielfeld - sondern ###
-- ### auch die normalen und besonderen Bauernzuege (Doppelschritt, en passant,            ###
-- ### Bauernumwandlung) sowie all diese Zuege auch als Schlagbewegung, soweit sie denn    ###
-- ### mit den Zugbewegungen identisch sind. Hinzu kommen die Sonderschlaege der Bauern.   ###
-- ### Ausserdem wird die Liste um die beiden Rochadearten ergaenzt.                       ###
-- ###                                                                                     ###
-- ### Jeden dieser Eintraege gibt es einmal fuer Weiss und einmal fuer Schwarz. Auch wird ###
-- ### bei jedem Zug die Richtung (bspw. nach rechts oben = RO) festgehalten, mit der der  ###
-- ### Zug ausgefuehrt wird.                                                               ###
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





CREATE OR ALTER PROCEDURE [Infrastruktur].[prcTheoretischeAktionenInitialisieren]
AS
BEGIN
	SET NOCOUNT ON;

	-- Statt einem einfachen TRUNCATE TABLE [Infrastruktur].[TheoretischeAktionen], was alle 
	-- Datensaetze der Tabelle loeschen wuerde, werden hier die Figuren in einzelnen Statements 
	-- geloescht. So kann man auch einzelne Datensaetze gezielt ansprechen.
	DELETE FROM [Infrastruktur].[TheoretischeAktionen]				-- Umfasst alle Zuege und Schlaege des Turms
	WHERE [FigurName] = 'Turm'

	DELETE FROM [Infrastruktur].[TheoretischeAktionen]				-- Umfasst alle Zuege und Schlaege des Laeufers
	WHERE [FigurName] = 'Laeufer'

	DELETE FROM [Infrastruktur].[TheoretischeAktionen]				-- Umfasst alle Zuege und Schlaege der Dame
	WHERE [FigurName] = 'Dame'

	DELETE FROM [Infrastruktur].[TheoretischeAktionen]				-- Umfasst alle Zuege und Schlaege des Koenigs
	WHERE [FigurName] = 'Koenig'									-- inklusive der Rochade

	DELETE FROM [Infrastruktur].[TheoretischeAktionen]				-- Umfasst alle Zuege und Schlaege des Springers
	WHERE [FigurName] = 'Springer'

	DELETE FROM [Infrastruktur].[TheoretischeAktionen]				-- Umfasst alle Zuege und Schlaege des Bauern
	WHERE [FigurName] = 'Bauer'										-- inklusive des Bauerndoppelschrittes, der "en passant"-Schlaege

	-- -----------------------------------------------------------------------------------------
	-- Moegliche Turmzuege, moegliche Turmschlaege
	-- -----------------------------------------------------------------------------------------
	-- Ein Turm zieht nur waagerecht oder senkrecht beliebig weit innerhalb der Brettgrenzen
	-- und schlägt auch auf diese Art und Weise

	-- Das Insert soll fuer beide Spieler (CROSS JOIN "JaNeinSpieler") gelten. Bei einem Turm sind 
	-- die Zug- und die Schlagbewegungen identisch (CROSS JOIN "JaNeinZug"). Hinterlegt werden 
	-- sowohl waagerechte ([SB].[Reihe] = [SJ].[Reihe] AND [SB].[Spalte] <> [SJ].[Spalte]) als
	-- auch senkrechte ([SB].[Reihe] <> [SJ].[Reihe] AND [SB].[Spalte] = [SJ].[Spalte]) Bewegungen.

	INSERT INTO [Infrastruktur].[TheoretischeAktionen] 
		(     [FigurName], [IstSpielerWeiss], [StartSpalte], [StartReihe], [Startfeld]
			, [ZielSpalte], [ZielReihe], [Zielfeld], [Richtung], [UmwandlungsFigurBuchstabe], [ZugIstSchlag]
			, [ZugIstKurzeRochade], [ZugIstLangeRochade], [ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex])
	(
		SELECT DISTINCT
			  'Turm'																	AS [Figurname]
			, [CS].[JaNeinSpieler]														AS [IstSpielerWeiss]
			, [SB].[Spalte]																AS [StartSpalte] 
			, [SB].[Reihe]																AS [StartReihe]
			, [SB].[Feld]																AS [StartFeld]
			, [SJ].[Spalte]																AS [ZielSpalte]
			, [SJ].[Reihe]																AS [ZielReihe]
			, [SJ].[Feld]																AS [ZielFeld]
			, CASE
					WHEN [SB].[Spalte]	< [SJ].[Spalte]		THEN		'RE'
					WHEN [SB].[Spalte]	> [SJ].[Spalte]		THEN		'LI'
					WHEN [SB].[Reihe]	< [SJ].[Reihe]		THEN		'OB'
					WHEN [SB].[Reihe]	> [SJ].[Reihe]		THEN		'UN'
				END																		AS [Richtung]
			, NULL																		AS [UmwandlungsfigurBuchstabe]
			, [CZ].[JaNeinSchlag]														AS [ZugIstSchlag]
			, 'FALSE'																	AS [ZugIstKurzeRocharde]
			, 'FALSE'																	AS [ZugIstLangeRocharde]
			, 'FALSE'																	AS [ZugIstEnPassant]
			, 'T'	+ LOWER([SB].[Spalte]) + CONVERT(CHAR(1), [SB].[Reihe])
					+ CASE WHEN [CZ].[JaNeinSchlag] = 'TRUE' THEN 'x' ELSE '-' END
					+ LOWER([SJ].[Spalte]) + CONVERT(CHAR(1), [SJ].[Reihe])				AS [LangeNotation]
			, 'T'	+ CASE WHEN [CZ].[JaNeinSchlag] = 'TRUE' THEN 'x' ELSE '' END
					+ LOWER([SJ].[Spalte]) + CONVERT(CHAR(1), [SJ].[Reihe])				AS [KurzeNotationEingfach]
			, 'T'	+ CASE WHEN [SB].[Spalte] = [SJ].[Spalte] 
							THEN CONVERT(CHAR(1), [SB].[Reihe]) 
							ELSE LOWER([SB].[Spalte]) END
					+ CASE WHEN [CZ].[JaNeinSchlag] = 'TRUE' THEN 'x' ELSE '' END
					+ LOWER([SJ].[Spalte]) + CONVERT(CHAR(1), [SJ].[Reihe])				AS [KurzeNotationKomplex]
		FROM [Infrastruktur].[Spielbrett]				AS [SB]
		LEFT JOIN [Infrastruktur].[Spielbrett]			AS [SJ]
			ON 1 = 1
				AND 
					(
						([SB].[Reihe] = [SJ].[Reihe] AND [SB].[Spalte] <> [SJ].[Spalte])
					OR
						([SB].[Reihe] <> [SJ].[Reihe] AND [SB].[Spalte] = [SJ].[Spalte])
					)
		CROSS JOIN (SELECT 'TRUE' AS [JaNeinSchlag] 
					UNION SELECT 'FALSE')				AS [CZ]
		CROSS JOIN (SELECT 'TRUE' AS [JaNeinSpieler] 
					UNION SELECT 'FALSE')				AS [CS]
	)



	-- -----------------------------------------------------------------------------------------
	-- Moegliche Laeuferzuege, moegliche Laeuferschlaege
	-- -----------------------------------------------------------------------------------------
	-- Ein Laeufer zieht nur diagonal in jede Richtung beliebig weit innerhalb der Brettgrenzen
	-- und schlägt auch auf diese Art und Weise

	-- Das Insert soll fuer beide Spieler (CROSS JOIN "JaNeinSpieler") gelten. Bei einem Laeufer sind 
	-- die Zug- und die Schlagbewegungen identisch (CROSS JOIN "JaNeinZug"). Hinterlegt werden 
	-- alle diagonalen (ABS(ASCII([SJ].[Spalte]) - ASCII([SB].[Spalte])) = 
	-- ABS(CONVERT(INTEGER, [SJ].[Reihe]) - CONVERT(INTEGER, [SB].[Reihe]))) Bewegungen.

	INSERT INTO [Infrastruktur].[TheoretischeAktionen] 
		(     [FigurName], [IstSpielerWeiss], [StartSpalte], [StartReihe], [StartFeld]
			, [ZielSpalte], [ZielReihe], [Zielfeld], [Richtung], [UmwandlungsfigurBuchstabe], [ZugIstSchlag]
			, [ZugIstKurzeRochade], [ZugIstLangeRochade], [ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex])
	(
		SELECT DISTINCT
			  'Laeufer'									AS [Figurname]
			, [CF].[JaNeinFarbe]						AS [IstSpielerWeiss]
			, [SB].[Spalte]								AS [StartSpalte] 
			, [SB].[Reihe]								AS [StartReihe]
			, [SB].[Feld]								AS [StartFeld]
			, [SJ].[Spalte]								AS [ZielSpalte]
			, [SJ].[Reihe]								AS [ZielReihe]
			, [SJ].[Feld]								AS [ZielFeld]
			, CASE
					WHEN [SB].[Spalte]	< [SJ].[Spalte]	AND [SB].[Reihe]	< [SJ].[Reihe]		THEN		'RO'
					WHEN [SB].[Spalte]	< [SJ].[Spalte]	AND [SB].[Reihe]	> [SJ].[Reihe]		THEN		'RU'
					WHEN [SB].[Spalte]	> [SJ].[Spalte]	AND [SB].[Reihe]	< [SJ].[Reihe]		THEN		'LO'
					WHEN [SB].[Spalte]	> [SJ].[Spalte]	AND [SB].[Reihe]	> [SJ].[Reihe]		THEN		'LU'
				END										AS [Richtung]
			, NULL										AS [UmwandlungsfigurBuchstabe]
			, [CZ].[JaNeinSchlag]						AS [ZugIstSchlag]
			, 'FALSE'									AS [ZugIstKurzeRocharde]
			, 'FALSE'									AS [ZugIstLangeRocharde]
			, 'FALSE'									AS [ZugIstEnPassant]
			, 'L'	+ LOWER([SB].[Spalte]) + CONVERT(CHAR(1), [SB].[Reihe])
					+ CASE WHEN [CZ].[JaNeinSchlag] = 'TRUE' THEN 'x' ELSE '-' END
					+ LOWER([SJ].[Spalte]) + CONVERT(CHAR(1), [SJ].[Reihe])				AS [LangeNotation]
			, 'L'	+ CASE WHEN [CZ].[JaNeinSchlag] = 'TRUE' THEN 'x' ELSE '' END
					+ LOWER([SJ].[Spalte]) + CONVERT(CHAR(1), [SJ].[Reihe])				AS [KurzeNotationEingfach]
			, 'L'	+ LOWER([SB].[Spalte])
					+ CASE WHEN [CZ].[JaNeinSchlag] = 'TRUE' THEN 'x' ELSE '' END
					+ LOWER([SJ].[Spalte]) + CONVERT(CHAR(1), [SJ].[Reihe])				AS [KurzeNotationKomplex]
		FROM [Infrastruktur].[Spielbrett]				AS [SB]
		LEFT JOIN [Infrastruktur].[Spielbrett]			AS [SJ]
			ON 1 = 1
				AND ABS(ASCII([SJ].[Spalte]) - ASCII([SB].[Spalte])) = ABS(CONVERT(INTEGER, [SJ].[Reihe]) - CONVERT(INTEGER, [SB].[Reihe]))
				AND [SJ].[Spalte]	<> [SB].[Spalte]
				AND [SJ].[Reihe]	<> [SB].[Reihe]
		CROSS JOIN (SELECT 'TRUE' AS [JaNeinFarbe] 
					UNION SELECT 'FALSE')				AS [CF]
		CROSS JOIN (SELECT 'TRUE' AS [JaNeinSchlag] 
					UNION SELECT 'FALSE')				AS [CZ]
	)



	-- -----------------------------------------------------------------------------------------
	-- Moegliche Damenzuege, moegliche Damenschlaege
	-- -----------------------------------------------------------------------------------------
	-- Eine Dame ist zugtechnisch vergleichbar mit einer Kombination aus Turm und Laeufer: Sie kann 
	-- beliebig weit diagonal, waagerecht oder senkrecht ziehen und schlagen

		INSERT INTO [Infrastruktur].[TheoretischeAktionen] ([FigurName], [IstSpielerWeiss], [StartSpalte], [StartReihe], 
															[StartFeld], [ZielSpalte], [ZielReihe], [Zielfeld], [Richtung], 
															[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], 
															[ZugIstLangeRochade], [ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex])
		SELECT DISTINCT
			  'Dame'
			, [IstSpielerWeiss]
			, [StartSpalte]
			, [StartReihe]
			, [StartFeld]
			, [ZielSpalte]
			, [ZielReihe]
			, [ZielFeld]
			, [Richtung]
			, NULL
			, [ZugIstSchlag]
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, 'D' + RIGHT([LangeNotation], LEN([LangeNotation]) - 1) 
			, 'D' + RIGHT([KurzeNotationEinfach], LEN([KurzeNotationEinfach]) - 1) 
			, 'D' + RIGHT([KurzeNotationKomplex], LEN([KurzeNotationKomplex]) - 1)
		FROM  [Infrastruktur].[TheoretischeAktionen]
		WHERE 1 = 1
			AND 
			(
				[FigurName]= 'Laeufer'
			OR
				[FigurName]= 'Turm'
			)

	-- -----------------------------------------------------------------------------------------
	-- Moegliche Koenigszuege, moegliche Koenigschlaege
	-- -----------------------------------------------------------------------------------------
	-- Ein Koenig ist zugtechnisch vergleichbar mit einer Dame, darf sich aber stets nur 1 Feld weit 
	-- bewegen: Er kann diagonal, waagerecht oder senkrecht ziehen und schlagen

		INSERT INTO [Infrastruktur].[TheoretischeAktionen] ([FigurName], [IstSpielerWeiss], [StartSpalte]
													, [StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld]
													, [Richtung], [UmwandlungsfigurBuchstabe], [ZugIstSchlag]
													, [ZugIstKurzeRochade], [ZugIstLangeRochade]
													, [ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex])
		SELECT DISTINCT
			  'Koenig'
			, [IstSpielerWeiss]
			, [StartSpalte]
			, [StartReihe]
			, [StartFeld]
			, [ZielSpalte]
			, [ZielReihe]
			, [ZielFeld]
			, [Richtung]
			, NULL
			, [ZugIstSchlag]
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, 'K' + RIGHT([LangeNotation], LEN([LangeNotation]) - 1) 
			, 'K' + RIGHT([KurzeNotationEinfach], LEN([KurzeNotationEinfach]) - 1) 
			, 'K' + RIGHT([KurzeNotationKomplex], LEN([KurzeNotationKomplex]) - 1)
		FROM  [Infrastruktur].[TheoretischeAktionen]
		WHERE 1 = 1
			AND [FigurName]= 'Dame'
			AND ABS(ASCII([ZielSpalte]) - ASCII([StartSpalte]))							<= 1
			AND ABS(CONVERT(INTEGER, [ZielReihe]) - CONVERT(INTEGER, [StartReihe]))		<= 1

	-- -----------------------------------------------------------------------------------------
	-- Moegliche Rochadezuege (es gibt keine Rochadeschlaege!)
	-- -----------------------------------------------------------------------------------------
	-- Eine Rochade ist eine Kombination aus zwei Zuegen - da zwei Figuren gleichzeitig bewegt
	-- werden. Allerdings setzt eine Rochade, die es in einer kurzen und in einer langen Variante
	-- gibt, eine Reihe von Kriterien voraus:
	-- 1) der beteiligte Koenig darf noch nicht gezogen haben
	-- 2) der beteiligte Turm darf noch nicht gezogen haben
	-- 3) es darf keine Figur zwischen Turm und Koenig stehen
	-- 4) der Koenig darf nicht im Schach stehen
	-- 5) Das Zielfeld des Koenigs und alle Felder, ueber die er hinweggeht, duerfen nicht 
	--    angegriffen sein.
	-- intern notiert wird der Zug, indem nur die Koenigsbewegung niedergeschrieben wird! Der 
	-- Spielalgorithmus ueberwacht an anderer Stelle, dass die Vorbedingungen (s.o.) eingehalten und
	-- die Rochade korrekt nach langer/kurzer Notation protokolliert wird!

		INSERT INTO [Infrastruktur].[TheoretischeAktionen] ([FigurName], [IstSpielerWeiss], [StartSpalte], [StartReihe], [StartFeld]
															, [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung], [UmwandlungsfigurBuchstabe]
															, [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade], [ZugIstEnPassant]
															, [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex])
		-- kurze Rochade weiss
		VALUES	  ('Koenig', 'TRUE',  'E', 1, 33, 'G', 1, 49, 'RE', NULL, 'FALSE', 'TRUE', 'FALSE', 'FALSE', 'o-o',		'o-o',		'o-o')
		-- lange Rochade weiss
				, ('Koenig', 'TRUE',  'E', 1, 33, 'C', 1, 17, 'LI', NULL, 'FALSE', 'FALSE', 'TRUE', 'FALSE', 'o-o-o',	'o-o-o',	'o-o-o')
		-- kurze Rochade schwarz
				, ('Koenig', 'FALSE', 'E', 8, 40, 'G', 8, 56, 'RE', NULL, 'FALSE', 'TRUE', 'FALSE', 'FALSE', 'o-o',		'o-o',		'o-o')
		-- lange Rochade schwarz
				, ('Koenig', 'FALSE', 'E', 8, 40, 'C', 8, 24, 'LI', NULL, 'FALSE', 'FALSE', 'TRUE', 'FALSE', 'o-o-o',	'o-o-o',	'o-o-o')




	-- -----------------------------------------------------------------------------------------
	-- Moegliche Springerzuege, moegliche Spingerschlaege
	-- -----------------------------------------------------------------------------------------
	-- Ein Springer zieht zwei Felder waagerecht oder senkrecht und anschließend im selben Zug sofort 
	-- genau ein Zug in 90°-Winkel innerhalb der Brettgrenzen. Die Schlagbewegung ist identisch.

	-- CTE als Kurzform, um eine Tabelle mit den Zahlen von 1 bis 64 zu erstellen und zu fuellen
	;WITH Spielfeld(XKoordinate, YKoordinate, Feld)
		 AS (	SELECT 
					  CHAR(([number] / 8) +	65)		AS [XKoordinate]
					, ([number] % 8) + 1			AS [YKoordinate]
					, [number] + 1					AS [Feld]
				FROM  master..spt_values
				WHERE 1 = 1
					AND [type] = 'P'
					AND [number] BETWEEN 0 AND 63
	)

	-- ziehen
	INSERT INTO [Infrastruktur].[TheoretischeAktionen] 
													([FigurName], [IstSpielerWeiss], [StartSpalte]
													, [StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld]
													, [Richtung], [UmwandlungsfigurBuchstabe], [ZugIstSchlag]
													, [ZugIstKurzeRochade], [ZugIstLangeRochade]
													, [ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex])
	SELECT DISTINCT
		  'Springer'								AS [FigurName]
		, [CS].[JaNeinSpieler]						AS [IstSpielerWeiss]
		, [S1].[XKoordinate]						AS [StartSpalte]
		, [S1].[YKoordinate]						AS [StartReihe]
		, [S1].[Feld]								AS [StartFeld]
		, [S2].[XKoordinate]						AS [ZielSpalte]
		, [S2].[YKoordinate]						AS [ZielReihe]
		, [S2].[Feld]								AS [ZielFeld]
		, CASE
				WHEN ASCII([S1].[XKoordinate]) - 2 = ASCII([S2].[XKoordinate]) 	
						AND [S1].[YKoordinate] - 1	= [S2].[YKoordinate]		THEN		'LU'
				WHEN ASCII([S1].[XKoordinate]) - 2 = ASCII([S2].[XKoordinate]) 	
						AND [S1].[YKoordinate] + 1	= [S2].[YKoordinate]		THEN		'LO'
				WHEN ASCII([S1].[XKoordinate]) + 2 = ASCII([S2].[XKoordinate]) 	
						AND [S1].[YKoordinate] - 1	= [S2].[YKoordinate]		THEN		'RU'
				WHEN ASCII([S1].[XKoordinate]) + 2 = ASCII([S2].[XKoordinate]) 	
						AND [S1].[YKoordinate] + 1	= [S2].[YKoordinate]		THEN		'RO'
				WHEN ASCII([S1].[XKoordinate]) - 1 = ASCII([S2].[XKoordinate]) 	
						AND [S1].[YKoordinate] - 2	= [S2].[YKoordinate]		THEN		'LU'
				WHEN ASCII([S1].[XKoordinate]) - 1 = ASCII([S2].[XKoordinate]) 	
						AND [S1].[YKoordinate] + 2	= [S2].[YKoordinate]		THEN		'LO'
				WHEN ASCII([S1].[XKoordinate]) + 1 = ASCII([S2].[XKoordinate]) 	
						AND [S1].[YKoordinate] - 2	= [S2].[YKoordinate]		THEN		'RU'
				WHEN ASCII([S1].[XKoordinate]) + 1 = ASCII([S2].[XKoordinate]) 	
						AND [S1].[YKoordinate] + 2	= [S2].[YKoordinate]		THEN		'RO'
			END										AS [Richtung]
		, NULL										AS [UmwandlungsfigurBuchstabe]
		, [CZ].[JaNeinSchlag]						AS [ZugIstSchlag]
		, 'FALSE'									AS [ZugIstKurzeRocharde]
		, 'FALSE'									AS [ZugIstLangeRocharde]
		, 'FALSE'									AS [ZugIstEnPassant]
		, 'S'	+ LOWER([S1].[XKoordinate]) + CONVERT(CHAR(1), [S1].[YKoordinate])
				+ CASE WHEN [CZ].[JaNeinSchlag] = 'TRUE' THEN 'x' ELSE '-' END
				+ LOWER([S2].[XKoordinate]) + CONVERT(CHAR(1), [S2].[YKoordinate])				AS [LangeNotation]
		, 'S'	+ CASE WHEN [CZ].[JaNeinSchlag] = 'TRUE' THEN 'x' ELSE '' END
				+ LOWER([S2].[XKoordinate]) + CONVERT(CHAR(1), [S2].[YKoordinate])				AS [KurzeNotationEingfach]
		, 'S'	+ LOWER([S1].[XKoordinate])
				+ CASE WHEN [CZ].[JaNeinSchlag] = 'TRUE' THEN 'x' ELSE '' END
				+ LOWER([S2].[XKoordinate]) + CONVERT(CHAR(1), [S2].[YKoordinate])				AS [KurzeNotationKomplex]
	FROM   [Spielfeld] AS [S1]
		CROSS JOIN [Spielfeld] AS [S2]
		CROSS JOIN (SELECT 'TRUE' AS [JaNeinSchlag] 
					UNION SELECT 'FALSE')			AS [CZ]
		CROSS JOIN (SELECT 'TRUE' AS [JaNeinSpieler] 
					UNION SELECT 'FALSE')			AS [CS]
	WHERE 1 = 1
		AND 
			(
				(
					(ABS(ASCII([S1].[XKoordinate]) - ASCII([S2].[XKoordinate])) = 1)
					AND
					(ABS([S1].[YKoordinate] - [S2].[YKoordinate]) = 2)
				)
			OR
				(
					(ABS(ASCII([S1].[XKoordinate]) - ASCII([S2].[XKoordinate])) = 2)
					AND
					(ABS([S1].[YKoordinate] - [S2].[YKoordinate]) = 1)
				)
			)



	-- -----------------------------------------------------------------------------------------
	-- Moegliche Bauernzuege
	-- -----------------------------------------------------------------------------------------
	-- Sonderregel fuer Bauern: im ersten Zug sind auch zwei Felder auf einmal möglich

	INSERT INTO [Infrastruktur].[TheoretischeAktionen] 
		(     [FigurName], [IstSpielerWeiss], [StartSpalte], [StartReihe], [StartFeld]
			, [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung], [UmwandlungsfigurBuchstabe], [ZugIstSchlag]
			, [ZugIstKurzeRochade], [ZugIstLangeRochade], [ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex])
	(
		SELECT DISTINCT
			  'Bauer'															AS [Figurname]
			, 'TRUE'															AS [IstSpielerWeiss]
			, [Spalte]															AS [StartSpalte] 
			, [Reihe]															AS [StartReihe]
			, [Feld]															AS [Startfeld]
			, [Spalte]															AS [ZielSpalte]
			, [Reihe] + 2														AS [ZielReihe]
			, [Feld] + 2														AS [ZielFeld]
			, 'OB'																AS [Richtung]
			, NULL																AS [UmwandlungsfigurBuchstabe]
			, 'FALSE'															AS [ZugIstSchlag]
			, 'FALSE'															AS [ZugIstKurzeRochade]
			, 'FALSE'															AS [ZugIstLangeRochade]
			, 'FALSE'															AS [ZugIstEnPassant]
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + '-'
				+ LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] + 2)				AS [LangeNotation]
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] + 2)					AS [KurzeNotationEingfach]
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] + 2)					AS [KurzeNotationKomplex]
		FROM [Infrastruktur].[Spielbrett]
		WHERE 1 = 1
			AND [Reihe]		= 2

		UNION

		SELECT
			  'Bauer'
			, 'FALSE'
			, [Spalte]
			, [Reihe]
			, [Feld]
			, [Spalte]
			, [Reihe] - 2
			, [Feld] - 2
			, 'UN'
			, NULL
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + '-'
				+ LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] - 2)
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] - 2)
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] - 2)
		FROM [Infrastruktur].[Spielbrett]
		WHERE 1 = 1
			AND [Reihe]		= 7

	)



	-- WEISS:	Bauer in Zeile 2 bis 6 kann 1 Feld nach oben ziehen
	-- SCHWARZ:	Bauer in Zeile 7 bis 3 kann 1 Feld nach unten ziehen
	INSERT INTO [Infrastruktur].[TheoretischeAktionen] 
		(     [FigurName], [IstSpielerWeiss], [StartSpalte], [StartReihe], [StartFeld]
			, [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung], [UmwandlungsfigurBuchstabe], [ZugIstSchlag]
			, [ZugIstKurzeRochade], [ZugIstLangeRochade], [ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex])
	(
		SELECT DISTINCT
			  'Bauer'									AS [Figurname]
			, 'TRUE'									AS [IstSpielerWeiss]
			, [Spalte]									AS [StartSpalte] 
			, [Reihe]									AS [StartReihe]
			, [Feld]									AS [StartFeld]
			, [Spalte]									AS [ZielSpalte]
			, [Reihe] + 1								AS [ZielReihe]
			, [Feld] + 1								AS [StartFeld]
			, 'OB'										AS [Richtung]
			, NULL										AS [UmwandlungsfigurBuchstabe]
			, 'FALSE'									AS [ZugIstSchlag]
			, 'FALSE'									AS [ZugIstKurzeRochade]
			, 'FALSE'									AS [ZugIstLangeRochade]
			, 'FALSE'									AS [ZugIstEnPassant]
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + '-'
				+ LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] + 1)				AS [LangeNotation]
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] + 1)					AS [KurzeNotationEingfach]
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] + 1)					AS [KurzeNotationKomplex]
		FROM [Infrastruktur].[Spielbrett]
		WHERE 1 = 1
			AND [Reihe]		BETWEEN 2 AND 6

		UNION

		SELECT DISTINCT
			  'Bauer'
			, 'FALSE'
			, [Spalte]
			, [Reihe]
			, [Feld]
			, [Spalte]
			, [Reihe] - 1
			, [Feld] - 1
			, 'UN'
			, NULL
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + '-'
				+ LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] - 1)				AS [LangeNotation]
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] - 1)					AS [KurzeNotationEingfach]
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] - 1)					AS [KurzeNotationKomplex]
		FROM [Infrastruktur].[Spielbrett]
		WHERE 1 = 1
			AND [Reihe]		BETWEEN 3 AND 7
	)



	-- WEISS:	Bauer in Zeile 7 kann 1 Feld nach oben ziehen und wandelt sich in eine neue Figur
	-- SCHWARZ:	Bauer in Zeile 2 kann 1 Feld nach unten ziehen und wandelt sich in eine neue Figur
	INSERT INTO [Infrastruktur].[TheoretischeAktionen] 
		(     [FigurName], [IstSpielerWeiss], [StartSpalte], [StartReihe], [StartFeld]
			, [ZielSpalte], [ZielReihe], [Zielfeld], [Richtung], [UmwandlungsfigurBuchstabe], [ZugIstSchlag]
			, [ZugIstKurzeRochade], [ZugIstLangeRochade], [ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex])
	(
		SELECT DISTINCT
			  'Bauer'															AS [Figurname]
			, 'TRUE'															AS [IstSpielerWeiss]
			, [SB].[Spalte]														AS [StartSpalte] 
			, [SB].[Reihe]														AS [StartReihe]
			, [SB].[Feld]														AS [StartFeld]
			, [SB].[Spalte]														AS [ZielSpalte]
			, [SB].[Reihe] + 1													AS [ZielReihe]
			, [SB].[Feld] + 1													AS [ZielFeld]
			, 'OB'																AS [Richtung]
			, [CJ].[UmwandlungsfigurBuchstabe]									AS [UmwandlungsfigurBuchstabe]
			, 'FALSE'															AS [ZugIstSchlag]
			, 'FALSE'															AS [ZugIstKurzeRochade]
			, 'FALSE'															AS [ZugIstLangeRochade]
			, 'FALSE'															AS [ZugIstEnPassant]
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + '-'
				+ LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] + 1)
				+ UPPER([CJ].[UmwandlungsfigurBuchstabe])						AS [LangeNotation]
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] + 1)					
				+ UPPER([CJ].[UmwandlungsfigurBuchstabe])						AS [KurzeNotationEingfach]
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] + 1)
				+ UPPER([CJ].[UmwandlungsfigurBuchstabe])						AS [KurzeNotationKomplex]
		FROM [Infrastruktur].[Spielbrett]				AS [SB]
		CROSS JOIN (SELECT 'S' AS [UmwandlungsfigurBuchstabe] 
					UNION SELECT 'D'
					UNION SELECT 'L'
					UNION SELECT 'T')				AS [CJ]
		WHERE 1 = 1
			AND [SB].[Reihe]		= 7

		UNION

		SELECT DISTINCT
			  'Bauer'
			, 'FALSE'
			, [SB].[Spalte]
			, [SB].[Reihe]
			, [SB].[Feld]
			, [SB].[Spalte]
			, [SB].[Reihe] - 1
			, [SB].[Feld] - 1
			, 'UN'
			, [CJ].[UmwandlungsfigurBuchstabe]
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + '-'
				+ LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] - 1)
				+ UPPER([CJ].[UmwandlungsfigurBuchstabe])
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] - 1)					
				+ UPPER([CJ].[UmwandlungsfigurBuchstabe])
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe] - 1)
				+ UPPER([CJ].[UmwandlungsfigurBuchstabe])
		FROM [Infrastruktur].[Spielbrett]				AS [SB]
		CROSS JOIN (SELECT 'S' AS [UmwandlungsfigurBuchstabe] 
					UNION SELECT 'D'
					UNION SELECT 'L'
					UNION SELECT 'T')				AS [CJ]
		WHERE 1 = 1
			AND [SB].[Reihe]		= 2

	)


	-- -----------------------------------------------------------------------------------------
	-- Moegliche Bauernschlaege
	-- -----------------------------------------------------------------------------------------
	-- Geschlagen wird diagonal ein Feld nach vorne, also in Laufrichtung. 
	-- WEISS:   Es koennen nur Bauern auf den Reihen 2-6 schlagen. Bauernschlaege von Reihe 7 
	--          werden unten separat behandelt, da mit ihnen eine Figurenumwandlung einher geht.
	-- SCHWARZ: Es koennen nur Bauern auf den Reihen 7-3 schlagen. Bauernschlaege von Reihe 2 
	--          werden unten separat behandelt, da mit ihnen eine Figurenumwandlung einher geht.

	INSERT INTO [Infrastruktur].[TheoretischeAktionen] 
		(     [FigurName], [IstSpielerWeiss], [StartSpalte], [StartReihe], [StartFeld]
			, [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung], [UmwandlungsfigurBuchstabe], [ZugIstSchlag]
			, [ZugIstKurzeRochade], [ZugIstLangeRochade], [ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex])
	(
		-- WEISS: Schlag nach rechts
		SELECT DISTINCT
			  'Bauer'									AS [Figurname]
			, 'TRUE'									AS [IstSpielerWeiss]
			, [Spalte]									AS [StartSpalte] 
			, [Reihe]									AS [StartReihe]
			, [Feld]									AS [StartFeld]
			, CHAR(ASCII([Spalte]) + 1)					AS [ZielSpalte]
			, [Reihe] + 1								AS [ZielReihe]
			, [Feld] + 9								AS [ZielFeld]
			, 'RO'										AS [Richtung]
			, NULL										AS [UmwandlungsfigurBuchstabe]
			, 'TRUE'									AS [ZugIstSchlag]
			, 'FALSE'									AS [ZugIstKurzeRochade]
			, 'FALSE'									AS [ZugIstLangeRochade]
			, 'FALSE'									AS [ZugIstEnPassant]
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] + 1)	AS [LangeNotation]
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] + 1)	AS [KurzeNotationEingfach]
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] + 1)	AS [KurzeNotationKomplex]
		FROM [Infrastruktur].[Spielbrett]
		WHERE 1 = 1
			AND [Spalte]	<= 'G'
			AND [Reihe]		BETWEEN 2 AND 6

		UNION

		-- WEISS: Schlag nach links
		SELECT DISTINCT
			  'Bauer'
			, 'TRUE'
			, [Spalte]
			, [Reihe]
			, [Feld]
			, CHAR(ASCII([Spalte]) - 1)
			, [Reihe] + 1
			, [Feld] - 7
			, 'LO'
			, NULL
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] + 1)
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] + 1)
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] + 1)
		FROM [Infrastruktur].[Spielbrett]
		WHERE 1 = 1
			AND [Spalte]	>= 'B'
			AND [Reihe]		BETWEEN 2 AND 6

		UNION

		-- SCHWARZ: Schlag nach rechts
		SELECT DISTINCT
			  'Bauer'
			, 'FALSE'
			, [Spalte]
			, [Reihe]
			, [Feld]		
			, CHAR(ASCII([Spalte]) + 1)
			, [Reihe] - 1
			, [Feld] + 7
			, 'RU'
			, NULL
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] - 1)
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] - 1)
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] - 1)
		FROM [Infrastruktur].[Spielbrett]
		WHERE 1 = 1
			AND [Spalte]	<= 'G'
			AND [Reihe]		BETWEEN 3 AND 7

		UNION

		-- SCHWARZ: Schlag nach links
		SELECT DISTINCT
			  'Bauer'
			, 'FALSE'
			, [Spalte]
			, [Reihe]
			, [Feld]
			, CHAR(ASCII([Spalte]) - 1)
			, [Reihe] - 1
			, [Feld] - 9
			, 'LU'
			, NULL
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] - 1)
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] - 1)
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] - 1)
		FROM [Infrastruktur].[Spielbrett]
		WHERE 1 = 1
			AND [Spalte]	>= 'B'
			AND [Reihe]		BETWEEN 3 AND 7
	)





	-- schlagen & umwandeln: Geschlagen wird diagonal ein Feld nach vorne, also in Laufrichtung. 
	-- WEISS:   Es koennen nur Bauern auf der Reihen 7 schlagen. Bauernschlaege von den Reihen 2-6 
	--          werden oben separat behandelt, da mit ihnen keine Figurenumwandlung einher geht.
	-- SCHWARZ: Es koennen nur Bauern auf der Reihen 2 schlagen. Bauernschlaege von den Reihen 7-3 
	--          werden oben separat behandelt, da mit ihnen keine Figurenumwandlung einher geht.
	INSERT INTO [Infrastruktur].[TheoretischeAktionen] 
		(     [FigurName], [IstSpielerWeiss], [StartSpalte], [StartReihe], [StartFeld]
			, [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung], [UmwandlungsfigurBuchstabe], [ZugIstSchlag]
			, [ZugIstKurzeRochade], [ZugIstLangeRochade], [ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex])
	(
		SELECT DISTINCT
			  'Bauer'																AS [Figurname]
			, 'TRUE'																AS [IstSpielerWeiss]
			, [SB].[Spalte]															AS [StartSpalte] 
			, [SB].[Reihe]															AS [StartReihe]
			, [SB].[Feld]															AS [StartFeld]
			, CHAR(ASCII([Spalte]) + 1)												AS [ZielSpalte]
			, [SB].[Reihe] + 1														AS [ZielReihe]
			, [SB].[Feld] + 9														AS [ZielFeld]
			, 'RO'																	AS [Richtung]
			, [CJ].[UmwandlungsfigurBuchstabe]										AS [UmwandlungsfigurBuchstabe]
			, 'TRUE'																AS [ZugIstSchlag]
			, 'FALSE'																AS [ZugIstKurzeRochade]
			, 'FALSE'																AS [ZugIstLangeRochade]
			, 'FALSE'																AS [ZugIstEnPassant]
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] + 1)
				+ [CJ].[UmwandlungsfigurBuchstabe]									AS [LangeNotation]
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] + 1)	
				+ [CJ].[UmwandlungsfigurBuchstabe]									AS [KurzeNotationEingfach]
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] + 1)	
				+ [CJ].[UmwandlungsfigurBuchstabe]									AS [KurzeNotationKomplex]
		FROM [Infrastruktur].[Spielbrett]				AS [SB]
		CROSS JOIN (SELECT 'S' AS [UmwandlungsfigurBuchstabe] 
					UNION SELECT 'D'
					UNION SELECT 'L'
					UNION SELECT 'T')				AS [CJ]
		WHERE 1 = 1
			AND [SB].[Reihe]		= 7
			AND [SB].[Spalte]		< 'H'

		UNION

		SELECT DISTINCT
			  'Bauer'
			, 'TRUE'
			, [SB].[Spalte]
			, [SB].[Reihe]
			, [SB].[Feld]
			, CHAR(ASCII([Spalte]) - 1)
			, [SB].[Reihe] + 1
			, [SB].[Feld] - 7
			, 'LO'
			, [CJ].[UmwandlungsfigurBuchstabe]
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] + 1)
				+ [CJ].[UmwandlungsfigurBuchstabe]									AS [LangeNotation]
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] + 1)
				+ [CJ].[UmwandlungsfigurBuchstabe]									AS [KurzeNotationEingfach]
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] + 1)	
				+ [CJ].[UmwandlungsfigurBuchstabe]									AS [KurzeNotationKomplex]
		FROM [Infrastruktur].[Spielbrett]				AS [SB]
		CROSS JOIN (SELECT 'S' AS [UmwandlungsfigurBuchstabe] 
					UNION SELECT 'D'
					UNION SELECT 'L'
					UNION SELECT 'T')				AS [CJ]
		WHERE 1 = 1
			AND [SB].[Reihe]		= 7
			AND [SB].[Spalte]		> 'A'
	
		UNION

		SELECT DISTINCT
			  'Bauer'
			, 'FALSE'
			, [SB].[Spalte]
			, [SB].[Reihe]
			, [SB].[Feld]
			, CHAR(ASCII([Spalte]) + 1)
			, [SB].[Reihe] - 1
			, [SB].[Feld] + 7
			, 'RU'
			, [CJ].[UmwandlungsfigurBuchstabe]
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] - 1)
				+ [CJ].[UmwandlungsfigurBuchstabe]
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] - 1)	
				+ [CJ].[UmwandlungsfigurBuchstabe]
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] - 1)	
				+ [CJ].[UmwandlungsfigurBuchstabe]
		FROM [Infrastruktur].[Spielbrett]				AS [SB]
		CROSS JOIN (SELECT 'S' AS [UmwandlungsfigurBuchstabe] 
					UNION SELECT 'D'
					UNION SELECT 'L'
					UNION SELECT 'T')				AS [CJ]
		WHERE 1 = 1
			AND [SB].[Reihe]		= 2
			AND [SB].[Spalte]		< 'H'


		UNION

		SELECT DISTINCT
			  'Bauer'
			, 'FALSE'
			, [SB].[Spalte]
			, [SB].[Reihe]
			, [SB].[Feld]
			, CHAR(ASCII([Spalte]) - 1)
			, [SB].[Reihe] - 1
			, [SB].[Feld] -9
			, 'LU'
			, [CJ].[UmwandlungsfigurBuchstabe]
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'FALSE'
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] - 1)
				+ [CJ].[UmwandlungsfigurBuchstabe]
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] - 1)
				+ [CJ].[UmwandlungsfigurBuchstabe]
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] - 1)
				+ [CJ].[UmwandlungsfigurBuchstabe]
		FROM [Infrastruktur].[Spielbrett]				AS [SB]
		CROSS JOIN (SELECT 'S' AS [UmwandlungsfigurBuchstabe] 
					UNION SELECT 'D'
					UNION SELECT 'L'
					UNION SELECT 'T')				AS [CJ]
		WHERE 1 = 1
			AND [SB].[Reihe]		= 2
			AND [SB].[Spalte]		> 'A'
	)




	-- Moegliche En-Passant-Schlaege:
	-- Es koennen nur Bauern direkt nach ihrem Doppelschritt geschlagen werden. Dazu muss sich 
	-- der schlagende Bauer auf der 4ten (SCHWARZ schlaegt WEISS) bzw.auf der 6ten Reihe (WEISS 
	-- schlaegt SCHWARZ) befinden.

	INSERT INTO [Infrastruktur].[TheoretischeAktionen] 
		(     [FigurName], [IstSpielerWeiss], [StartSpalte], [StartReihe], [StartFeld]
			, [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung], [UmwandlungsfigurBuchstabe], [ZugIstSchlag]
			, [ZugIstKurzeRochade], [ZugIstLangeRochade], [ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex])
	(
		SELECT DISTINCT			-- Weiss schlaegt en passant nach rechts oben
			  'Bauer'																AS [Figurname]
			, 'TRUE'																AS [IstSpielerWeiss]
			, [Spalte]																AS [StartSpalte] 
			, [Reihe]																AS [StartReihe]
			, [Feld]																AS [StartFeld]
			, CHAR(ASCII([Spalte]) + 1)												AS [ZielSpalte]
			, [Reihe] + 1															AS [ZielReihe]
			, [Feld] + 9															AS [ZielFeld]
			, 'RO'																	AS [Richtung]
			, NULL																	AS [UmwandlungsfigurBuchstabe]
			, 'TRUE'																AS [ZugIstSchlag]
			, 'FALSE'																AS [ZugIstKurzeRochade]
			, 'FALSE'																AS [ZugIstLangeRochade]
			, 'TRUE'																AS [ZugIstEnPassant]
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] + 1)
				+ 'e.p.'															AS [LangeNotation]
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] + 1)	
				+ 'e.p.'															AS [KurzeNotationEingfach]
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] + 1)	
				+ 'e.p.'															AS [KurzeNotationKomplex]
		FROM [Infrastruktur].[Spielbrett]
		WHERE 1 = 1
			AND [Spalte]	< 'H'
			AND [Reihe]		= 6

		UNION

		SELECT DISTINCT			-- Weiss schlaegt en passant nach links oben
			  'Bauer'
			, 'TRUE'
			, [Spalte]
			, [Reihe]
			, [Feld]
			, CHAR(ASCII([Spalte]) - 1)
			, [Reihe] + 1
			, [Feld] - 7
			, 'LO'
			, NULL
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'TRUE'
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] + 1)
				+ 'e.p.'
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] + 1)
				+ 'e.p.'
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] + 1)
				+ 'e.p.'
		FROM [Infrastruktur].[Spielbrett]
		WHERE 1 = 1
			AND [Spalte]	> 'A'
			AND [Reihe]		= 6

		UNION
	
		SELECT DISTINCT			-- Schwarz schlaegt en passant nach rechts unten
			  'Bauer'
			, 'FALSE'
			, [Spalte]
			, [Reihe]
			, [Feld]
			, CHAR(ASCII([Spalte]) + 1)
			, [Reihe] - 1
			, [Feld] + 7
			, 'RU'
			, NULL
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'TRUE'
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] - 1)
				+ 'e.p.'
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] - 1)
				+ 'e.p.'
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) + 1)) + CONVERT(CHAR(1), [Reihe] - 1)
				+ 'e.p.'	FROM [Infrastruktur].[Spielbrett]
		WHERE 1 = 1
			AND [Spalte]	< 'H'
			AND [Reihe]		= 4

		UNION

		SELECT DISTINCT			-- Schwarz schlaegt en passant nach links oben
			  'Bauer'
			, 'FALSE'
			, [Spalte]
			, [Reihe]
			, [Feld]
			, CHAR(ASCII([Spalte]) - 1)
			, [Reihe] - 1
			, [Feld] - 9
			, 'LU'
			, NULL
			, 'TRUE'
			, 'FALSE'
			, 'FALSE'
			, 'TRUE'
			, LOWER([Spalte]) + CONVERT(CHAR(1), [Reihe]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] - 1)
				+ 'e.p.'
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] - 1)
				+ 'e.p.'
			, LOWER([Spalte]) + 'x'
				+ LOWER(CHAR(ASCII([Spalte]) - 1)) + CONVERT(CHAR(1), [Reihe] - 1)
				+ 'e.p.'	
		FROM [Infrastruktur].[Spielbrett]
		WHERE 1 = 1
			AND [Spalte]	> 'A'
			AND [Reihe]		= 4
	)
END
GO







------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '030 - Prozedur [Infrastruktur].[prcTheoretischeAktionenInitialisieren] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO

