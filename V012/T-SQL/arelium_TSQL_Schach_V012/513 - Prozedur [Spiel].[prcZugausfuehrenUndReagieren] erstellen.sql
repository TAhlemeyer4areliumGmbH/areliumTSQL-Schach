-- ###########################################################################################
-- ### Spiel der Koenige - Workshopversion ###################################################
-- ###########################################################################################
-- ### Erstellung der Prozedur [Spiel].[prcZugAusfuehrenUndReagieren]                      ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Dieses Skript erstellt oder aendert eine Prozedur, die dazu dient einen Zug         ###
-- ### auszufuehren. Dazu uebergibt der Spieler zwei Koordinaten (Start- und Zielfeld).    ###
-- ###                                                                                     ###
-- ### Die Prozedur ermittelt selbststaendig, welche Figur wie bewegt werden soll und ob   ###
-- ### dieser Zug/Schlag in der aktuellen Stellung erlaubt ist. Sollte dies nicht der Fall ###
-- ### sein, bricht der Vorgang mit einer Fehlermeldung ab. Dazu zaehlt bspw. auch die     ###
-- ### Ueberwachung der Einhaltung der Zugpflichtregel.                                    ###
-- ###                                                                                     ###
-- ### Einige Zuege bedingen eine spezielle Eingabeform:                                   ###
-- ###    - eine Rochade wird nur ueber die Bewegung des Koenigs codiert, also bspw.       ###
-- ###      EXEC [Spiel].[prcZugAusfuehren] 'e1', 'g1', NULL, 'TRUE' fuer die kurze        ###
-- ###      Rochade von Weiss.                                                             ###
-- ###    - eine Bauernumwandlung erwartet verpflichtend einen sonst mit NULL zu           ###
-- ###      belegenden dritten Parameter. Beispiel EXEC [Weiss].[prcZugAusfuehren] 'e7',   ###
-- ###      'e8', 'D', 'TRUE'                                                              ###
-- ###                                                                                     ###
-- ### Die Prozedur fuehrt auch das Spielprotokoll in der langen Notation und aktualisiert ###
-- ### die Darstellung des Spielbrettes. Je nach Konfiguration wird abschliessend nicht    ###
-- ### nur der Partieverlauf gezeichnet sondern es werden auch Zugempfehlungen mit oder    ###
-- ### ohne Bewertungsangabe aufgelistet.                                                  ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Sicherheitshinweis:                                                                 ###
-- ###      Ueber diese Befehlssammlung werden Datenbankobjekte angelegt, geaendert oder   ###
-- ###      geloescht. Auch koennen Inhalte hinzugefuegt, manipuliert oder entfernt        ###
-- ###      werden. In produktiven Umgebungen darf dieses Skript NICHT eingesetzt werden,  ###
-- ###      um versehentliche Auswirkungen auf sonstige Strukturen auszuschliessen.        ###
-- ###                                                                                     ###
-- ### Erstellung:                                                                         ###
-- ###      Torsten Ahlemeyer fuer arelium GmbH, www.arelium.de                            ###
-- ###      Kontakt: torsten.ahlemeyer@arelium.de                                          ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Aenderungsnachweis:                                                                 ###
-- ###     1.00.0	2023-02-27	Torsten Ahlemeyer                                          ###
-- ###              Initiale Erstellung                                                    ###
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
-- Nutzinhalt ------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

USE [arelium_TSQL_Schach_V012]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- -----------------------------------------------------------------------------------------
-- Erstellung der Prozedur [Spiel].[prcZugAusfuehrenUndReagieren]
-- -----------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [Spiel].[prcZugAusfuehrenUndReagieren] 
	(
		  @Startquadrat				AS CHAR(2)
		, @Zielquadrat				AS CHAR(2)
		, @Umwandlungsfigur			AS CHAR(1)
		, @IstEnPassant				AS BIT
		, @IstSpielerWeiss			AS BIT
	)
AS
BEGIN

	DECLARE @Startfeld				AS INTEGER
	DECLARE @Zielfeld				AS INTEGER
	DECLARE @FigurBuchstabe			AS CHAR(1)
	DECLARE @FigurFarbeIstWeiss		AS BIT
	DECLARE @WunschzugID			AS BIGINT
	DECLARE @ASpielbrett			AS [dbo].[typStellung]
	DECLARE @BSpielbrett			AS [dbo].[typStellung]
	DECLARE @IstStellungSchach		AS BIT
	DECLARE @VollzugId				AS BIGINT

	IF NOT EXISTS
		(	SELECT * FROM [Spiel].[Notation]
			WHERE 1 = 1
				AND ([LangeNotation] = '1-0' OR [LangeNotation] = '0-1' OR [LangeNotation] = CHAR(189) + '-' + CHAR(189))
		)
	BEGIN
		-- Das aktuelle Brett einlesen
		INSERT INTO @ASpielbrett
		SELECT 
			  1								AS [VarianteNr]
			, 1								AS [Suchtiefe]
			, [SB].[Spalte]					AS [Spalte]
			, [SB].[Reihe]					AS [Reihe]
			, [SB].[Feld]					AS [Feld]
			, [SB].[IstSpielerWeiss]		AS [IstSpielerWeiss]
			, [SB].[FigurBuchstabe]			AS [FigurBuchstabe]
			, [SB].[FigurUTF8]				AS [FigurUTF8]
		FROM [Infrastruktur].[Spielbrett]	AS [SB]

		-- Hat der Parameter @Startquadrat die richtige Laenge?
		IF 
			LEN(@Startquadrat)		<> 2
		BEGIN
			SELECT 'Das Startquadrat hat eine ungültige Länge. Erwartet wird die Angabe einer Spalte und einer Reihe wie bspw. <e2>'
			SELECT * FROM [Infrastruktur].[vSpielbrett]
		END
		ELSE
		BEGIN
			-- Hat der Parameter @Startquadrat das richtige Format?
			IF 
				   LEFT(@Startquadrat, 1)	NOT IN ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h')
				OR RIGHT(@Startquadrat, 1)	NOT IN ('1', '2', '3', '4', '5', '6', '7', '8')
			BEGIN
				SELECT 'Das Startquadrat hat ein ungültiges Format. Erwartet wird die Angabe einer Spalte und einer Reihe wie bspw. <e2>'
				SELECT * FROM [Infrastruktur].[vSpielbrett]
			END
			ELSE
			BEGIN
				-- Hat der Parameter @Zielquadrat die richtige Laenge?
				IF 
					LEN(@Zielquadrat)		<> 2
				BEGIN
					SELECT 'Das Zielquadrat hat eine ungültige Länge. Erwartet wird die Angabe einer Spalte und einer Reihe wie bspw. <e2>'
					SELECT * FROM [Infrastruktur].[vSpielbrett]
				END
				ELSE
				BEGIN
					-- Hat der Parameter @Zielfeld das richtige Format?
					IF 
						   LEFT(@Zielquadrat, 1)	NOT IN ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h')
						OR RIGHT(@Zielquadrat, 1)	NOT IN ('1', '2', '3', '4', '5', '6', '7', '8')
					BEGIN
						SELECT 'Das Zielquadrat hat ein ungültiges Format. Erwartet wird die Angabe einer Spalte und einer Reihe wie bspw. <e2>'
						SELECT * FROM [Infrastruktur].[vSpielbrett]
					END
					ELSE
					BEGIN
						-- Ist eine Umwandlungsfigur angegben und wenn ja, ist dies eine Dame, ein Turm, eine Laeufer oder ein Springer?
						IF (@Umwandlungsfigur IS NOT NULL) AND (@Umwandlungsfigur NOT IN ('S', 'L', 'D', 'T'))
						BEGIN
							SELECT 'Wenn eine Umwandlungsfigur angegeben wird, muss dies eine Dame (D), eine Turm (T), eine Läufer (L) oder ein Springer (S) sein!'
							SELECT * FROM [Infrastruktur].[vSpielbrett]
						END
						ELSE
						BEGIN
							-- Start- und Zielfeld auslesen
							SET @Startfeld		= (	SELECT [Feld] 
													FROM [Infrastruktur].[Spielbrett] 
													WHERE 1 = 1
														AND [Spalte]	= LEFT(@Startquadrat, 1) 
														AND [Reihe]		= CONVERT(INTEGER, RIGHT(@Startquadrat, 1))
												)
												
							SET @Zielfeld		= (	SELECT [Feld] 
													FROM [Infrastruktur].[Spielbrett] 
													WHERE 1 = 1
														AND [Spalte]	= LEFT(@Zielquadrat, 1) 
														AND [Reihe]		= CONVERT(INTEGER, RIGHT(@Zielquadrat, 1))
												)
							SET @FigurBuchstabe	= (	SELECT [FigurBuchstabe]
													FROM [Infrastruktur].[Spielbrett] 
													WHERE 1 = 1
														AND [Feld]				= @Startfeld
												)
							SET @FigurFarbeIstWeiss	= (	SELECT [IstSpielerWeiss]
													FROM [Infrastruktur].[Spielbrett] 
													WHERE 1 = 1
														AND [Feld]				= @Startfeld
												)
							-- Steht auf dem Startfeld ueberhaupt eine Figur?
							IF @FigurBuchstabe = ' '
							BEGIN
								SELECT 'Das Startfeld ist leer. Bitte ein Feld mit einer eigenen Figur wählen!'
								SELECT * FROM [Infrastruktur].[vSpielbrett]
							END
							ELSE
							BEGIN
								-- Steht auf dem Startfeld eine Figur der eigenen Farbe?
								IF @FigurFarbeIstWeiss <> @IstSpielerWeiss
								BEGIN
									SELECT 'Auf dem Startfeld steht keine eigene Figur. Bitte ein Feld mit einer eigenen Figur wählen!'
									SELECT * FROM [Infrastruktur].[vSpielbrett]
								END
								ELSE
								BEGIN
									-- Soll die "richtige" Farbe ziehen?
									IF [Spiel].[fncIstWeissAmZug]() <> @IstSpielerWeiss
									BEGIN
										SELECT 'Bitte beachten: Aktuell hat ' + CASE [Spiel].[fncIstWeissAmZug]() WHEN 'TRUE' THEN 'WEISS' ELSE 'SCHWARZ' END + ' das Zugrecht / die Zugpflicht!'
										SELECT * FROM [Infrastruktur].[vSpielbrett]
									END
									ELSE
									BEGIN
										-- ... der richtige Spieler und sowohl Start- wie Zielfeld, eigene Figur ... 
										--aber: Ist der Zug ueberhaupt erlaubt? (Zugzwang, Schachgebot, Fesselung, ...)
										IF NOT EXISTS
											(	SELECT * 
												FROM [Spiel].[MoeglicheAktionen]
												WHERE 1 = 1
													AND [StartFeld]		= @Startfeld
													AND [ZielFeld]		= @Zielfeld
											)
										BEGIN
											SELECT 'dieser Zug ist in dieser Situation nicht erlaubt! Liegt vielleicht eine Fesselung oder ein Zugzwang (aufgrund Schachgebot) vor?' AS [Fehlerhinweis]
											SELECT * FROM [Infrastruktur].[vSpielbrett]
										END
										ELSE
										BEGIN
											-- Ermitteln, ob es einen Zug gibt, der die Wunschparameter erfuellt - also vom Startfeld zum Zielfeld fuehrt
											-- VORSICHT: Es gibt einen Sonderfall, dass es zwei verschiedenen Züge des selben Spielers mit identischem 
											-- Start- und Zielfeld gibt: Der normale Bauernschlag und ein En-Passant-Schlag. Zur Unterscheidung der beiden 
											-- Faelle guckt man auf das Zielfeld. Steht hier ein Bauer, ist es ein normaler Bauernschlag - sonst die 
											-- En-Passant-Variante
											SET @WunschzugID = (
												SELECT [TheoretischeAktionenID]
												FROM [Spiel].[MoeglicheAktionen]
												WHERE 1 = 1
													AND [StartFeld]					= @Startfeld
													AND [ZielFeld]					= @Zielfeld
													AND (
															   @Umwandlungsfigur	IS NULL 
															OR @Umwandlungsfigur	= [UmwandlungsfigurBuchstabe]
														)
													AND [IstSpielerWeiss]			= @IstSpielerWeiss
													AND [ZugIstEnPassant]			= CASE 
																						WHEN (SELECT [FigurUTF8] 
																							FROM [Infrastruktur].[Spielbrett]
																							WHERE [Feld] = @Startfeld) = 160
																						THEN 'TRUE'
																						ELSE 'FALSE'
																						END
																)

											-- Gibt es einen solchen Zug?
											IF @WunschzugID IS NULL
											BEGIN
												SELECT 'es gibt (in der aktuellen Stellung) keinen gueltigen Zug, um von ' + @Startquadrat + ' nach ' + @Zielquadrat + ' zu ziehen'
												SELECT * FROM [Infrastruktur].[vSpielbrett]
											END
											ELSE
											BEGIN

												EXECUTE [Spiel].[prcZugAusfuehren] 
													  @Startquadrat				= @Startquadrat
													, @Zielquadrat				= @Zielquadrat
													, @Umwandlungsfigur			= @Umwandlungsfigur
													, @IstEnPassant				= @IstEnPassant
													, @IstSpielerWeiss			= @IstSpielerWeiss

												---- -----------------------------------------------------------------
												---- Gegenzug der Computerengine, falls hier Mensch gegen TSQL spielt
												---- -----------------------------------------------------------------

												IF (SELECT [SpielstaerkeID] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = ((@IstSpielerWeiss + 1) % 2)) BETWEEN 1 AND 2
													AND (SELECT [SpielstaerkeID] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = @IstSpielerWeiss) NOT BETWEEN 1 AND 2
												BEGIN
													DECLARE @Computerzug						AS [dbo].[typMoeglicheAktionen] 
													DECLARE @StartquadratComputerzug			AS CHAR(2)
													DECLARE @ZielquadratComputerzug				AS CHAR(2)
													DECLARE @UmwandlungsfigurComputerzug		AS CHAR(1)
													DECLARE @IstEnPassantComputerzug			AS BIT
													DECLARE @IstSpielerWeissComputer			AS BIT

													-- nun reagiert der Rechner als Gegenspieler
													IF (SELECT [SpielstaerkeID] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = @IstSpielerWeiss) BETWEEN 3 AND 4				-- zufaelliger Zug
													BEGIN
		
														INSERT INTO @Computerzug
															([TheoretischeAktionenID], [HalbzugNr], [FigurName], [IstSpielerWeiss], [StartSpalte], [StartReihe]
															,[StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung], [UmwandlungsfigurBuchstabe]
															,[ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade], [ZugIstEnPassant], [LangeNotation]
															,[KurzeNotationEinfach], [KurzeNotationKomplex], [Bewertung])
														SELECT TOP 1
															  [TheoretischeAktionenID]
															, [HalbzugNr]
															, [FigurName]
															, [IstSpielerWeiss]
															, [StartSpalte]
															, [StartReihe]
															, [StartFeld]
															, [ZielSpalte]
															, [ZielReihe]
															, [ZielFeld]
															, [Richtung]
															, [UmwandlungsfigurBuchstabe]
															, [ZugIstSchlag]
															, [ZugIstKurzeRochade]
															, [ZugIstLangeRochade]
															, [ZugIstEnPassant]
															, [LangeNotation]
															, [KurzeNotationEinfach]
															, [KurzeNotationKomplex]
															, [Bewertung]
														FROM [arelium_TSQL_Schach_V012].[Spiel].[MoeglicheAktionen]
														ORDER BY NEWID()

														-- diesen Zug jetzt ausfuehren
														SET @StartquadratComputerzug		= (SELECT TOP 1 [StartSpalte] + CONVERT(CHAR(1), [StartReihe]) FROM @Computerzug)
														SET @ZielquadratComputerzug			= (SELECT TOP 1 [ZielSpalte] + CONVERT(CHAR(1), [ZielReihe]) FROM @Computerzug)
														SET @UmwandlungsfigurComputerzug	= (SELECT TOP 1 [UmwandlungsfigurBuchstabe] FROM @Computerzug)
														SET @IstEnPassantComputerzug		= (SELECT TOP 1 [ZugIstEnPassant] FROM @Computerzug)
														SET @IstSpielerWeissComputer		= (SELECT ((@IstSpielerWeiss + 1) % 2))

														EXECUTE [Spiel].[prcZugAusfuehren] 
															  @StartquadratComputerzug
															, @ZielquadratComputerzug
															, @UmwandlungsfigurComputerzug
															, @IstEnPassantComputerzug
															, @IstSpielerWeissComputer

														SELECT 'Weitere Zuege gegen den Computergegner bitte mit EXEC [Spiel].[prcZugausfuehrenUndReagieren] beginnen'

													END
													ELSE
													BEGIN
														SELECT 'noch nicht implementiert'
													END
												END
											END
										END
									END
								END
							END
						END
					END
				END
			END
		END
	END
	ELSE
	BEGIN
		SELECT 'diese Partie ist schon entschieden!' AS [Fehlerhinweis]
		-- Das Amaturenbrett inklusive Spielbrett wird neu gezeichnet
												SELECT * FROM [Infrastruktur].[vSpielbrett]
	END
END
GO



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '513 - Prozedur [Spiel].[prcZugAusfuehren] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO


/*  TEST DER PROZEDUR


USE [arelium_TSQL_Schach_V012]
GO

DECLARE	@return_value int

EXEC	[Spiel].[prcInitialisierung]

EXEC	@return_value = [Spiel].[prcZugAusfuehrenUndReagieren]
		@Startquadrat = N'g1',
		@Zielquadrat = N'f3',
		@Umwandlungsfigur = NULL,
		@IstEnPassant = FALSE,
		@IstSpielerWeiss = TRUE

SELECT	'Return Value' = @return_value


*/