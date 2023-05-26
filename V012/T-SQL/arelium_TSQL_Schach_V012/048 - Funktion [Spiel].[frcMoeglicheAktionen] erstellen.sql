-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Moegliche Aktionen zusammenstellen                                                  ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Diese Funktion durchlaeuft alle Figuren eines Spielers und notiert die damit laut   ###
-- ### Spielregeln gueltig durchzufuehrenden Aktionen. Es werden also alle Optionen        ###
-- ### erfasst, die der Spieler hat, um das Spiel regelkonform fortzusetzen.               ###
-- ###                                                                                     ###
-- ### Es werden alle Figurentypen per Cursor durchlaufen, da vorher nicht feststeht,      ###
-- ### wieviele Figuren dieses Typs noch auf dem Brett stehen. Durch Bauernumwandlung      ###
-- ### kann die Zahl der Schwerfiguren (T, S, D, L) erhoeht worden sein. Durch Schlaege    ###
-- ### im Spielverlauf kann die Zahl der Figuren jedes Typs mit Ausnahme des Koenigs       ###
-- ### reduziert worden sein.                                                              ###
-- ###                                                                                     ###
-- ### Am Ende dieses Block gibt es eine (auskommentierte) Testroutine, mit der man fuer   ###
-- ### eine uebergebene Stellung testen kann, ob alle (und nur diese) gueltigen Zuege fuer ###
-- ### die genannten Figuren zurueck kommen.                                               ###
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
-- Dank des "CREATE OR ALTER"-Befehls ist ein vorheriges Loeschen des Datenbankobjektes 
-- nicht mehr noetig.

-----------------------------
-- Aufbauarbeiten -----------
-----------------------------

-- Diese Funktion erstellt und fuellt eine Tabelle mit allen Aktionen, die von der uebergebenen Stellung aus unter 
-- Beruecksichtigung der Spielregeln genutzt werden koennen. Es werden Aktionen fuer beide Spieler ermittelt - die 
-- aufrufende Stelle muss auswerten, welcher Spieler am Zug ist
CREATE OR ALTER FUNCTION [Spiel].[fncMoeglicheAktionen]
(
	   @IstSpielerWeiss		AS BIT
	 , @Bewertungsstellung	AS typStellung			READONLY
)
RETURNS @MoeglicheAktionen TABLE 
	(
		  [TheoretischeAktionenID]		BIGINT			NOT NULL
		, [HalbzugNr]					INTEGER			NOT NULL
		, [FigurName]					NVARCHAR(20)	NOT NULL
		, [IstSpielerWeiss]				BIT				NOT NULL
		, [StartSpalte]					CHAR(1)			NOT NULL
		, [StartReihe]					TINYINT			NOT NULL
		, [StartFeld]					INTEGER			NOT NULL
		, [ZielSpalte]					CHAR(1)			NOT NULL
		, [ZielReihe]					TINYINT			NOT NULL
		, [ZielFeld]					INTEGER			NOT NULL
		, [Richtung]					CHAR(2)			NOT NULL
		, [ZugIstSchlag]				BIT				NOT NULL
		, [ZugIstEnPassant]				BIT				NOT NULL
		, [ZugIstKurzeRochade]			BIT				NOT NULL
		, [ZugIstLangeRochade]			BIT				NOT NULL
		, [UmwandlungsfigurBuchstabe]	NVARCHAR(20)	NULL
		, [LangeNotation]				VARCHAR(20)		NULL
		, [KurzeNotationEinfach]		VARCHAR(8)		NULL
		, [KurzeNotationKomplex]		VARCHAR(8)		NULL
	) AS
	BEGIN

		DECLARE @Damenfeld			AS INTEGER
		DECLARE @Turmfeld			AS INTEGER
		DECLARE @Springerfeld		AS INTEGER
		DECLARE @Laeuferfeld		AS INTEGER
		DECLARE @Koenigsfeld		AS INTEGER
		DECLARE @Bauernfeld			AS INTEGER
		DECLARE @Schachstellung		AS BIGINT
		DECLARE @Fesselstellung		AS BIGINT
		DECLARE @ZugIstSchachgebot	AS BIT
		DECLARE @BSpielbrett		AS [dbo].[typStellung]
		DECLARE @LangeNotation		AS VARCHAR(20)
		DECLARE @Umwandlungsfigur	AS CHAR(1)
		DECLARE @Startfeld			AS INTEGER
		DECLARE @Zielfeld			AS INTEGER


		---- --------------------------------------------------------------------------
		---- Damen
		---- --------------------------------------------------------------------------

		-- Es werden alle auf dem Brett befindlichen Damen ermittelt. fuer jede so gefundene Dame werden nun alle 
		-- denkbaren und regelkonforme Aktionen notiert. Somit ist selbst nach mehrfacher Bauernumwandlung jede Dame 
		-- beruecksichtigt.
		DECLARE curDamenaktionen CURSOR FOR   
			SELECT DISTINCT [Feld]
			FROM @Bewertungsstellung
			WHERE 1 = 1
				AND [FigurBuchstabe]	= 'D'
				AND [IstSpielerWeiss]	= @IstSpielerWeiss
			ORDER BY [Feld];  

		OPEN curDamenaktionen
  
		FETCH NEXT FROM curDamenaktionen INTO @Damenfeld
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
			INSERT INTO @MoeglicheAktionen
			(
				[TheoretischeAktionenID], [HalbzugNr], [FigurName], [IstSpielerWeiss], [StartSpalte],
				[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
				[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
				[ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex]
			)
			SELECT [TheoretischeAktionenID], 1, [FigurName], [IstSpielerWeiss], [StartSpalte],
				[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
				[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
				[ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex] 
			FROM [Spiel].[fncMoeglicheDamenaktionen] (@IstSpielerWeiss, @Bewertungsstellung, @Damenfeld)

			FETCH NEXT FROM curDamenaktionen INTO @Damenfeld 
		END
		CLOSE curDamenaktionen;  
		DEALLOCATE curDamenaktionen; 


		---- --------------------------------------------------------------------------
		---- Tuerme
		---- --------------------------------------------------------------------------

		-- Es werden alle auf dem Brett befindlichen Tuerme ermittelt. fuer jeden so gefundenen Turm werden nun alle 
		-- denkbaren und regelkonforme Aktionen notiert. Somit ist selbst nach mehrfacher Bauernumwandlung jeder Turm 
		-- beruecksichtigt.	
		DECLARE curTurmaktionen CURSOR FOR   
			SELECT DISTINCT [Feld]
			FROM @Bewertungsstellung
			WHERE 1 = 1
				AND [FigurBuchstabe]	= 'T'
				AND [IstSpielerWeiss]	= @IstSpielerWeiss
			ORDER BY [Feld];  
  
		OPEN curTurmaktionen
  
		FETCH NEXT FROM curTurmaktionen INTO @Turmfeld
  
		WHILE @@FETCH_STATUS = 0  
		BEGIN 

			INSERT INTO @MoeglicheAktionen
			(
				[TheoretischeAktionenID], [HalbzugNr], [FigurName], [IstSpielerWeiss], [StartSpalte],
				[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
				[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
				[ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex]
			)
			SELECT [TheoretischeAktionenID], 1, [FigurName], [IstSpielerWeiss], [StartSpalte],
				[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
				[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
				[ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex] 
			FROM [Spiel].[fncMoeglicheTurmaktionen] (@IstSpielerWeiss, @Bewertungsstellung, @Turmfeld)

			FETCH NEXT FROM curTurmaktionen INTO @Turmfeld 
		END
		CLOSE curTurmaktionen;  
		DEALLOCATE curTurmaktionen; 

		---- --------------------------------------------------------------------------
		---- Laeufer
		---- --------------------------------------------------------------------------

		-- Es werden alle auf dem Brett befindlichen Laeufer ermittelt. fuer jeden so gefundenen Laeufer werden nun alle 
		-- denkbaren und regelkonforme Aktionen notiert. Somit ist selbst nach mehrfacher Bauernumwandlung jeder Laeufer
		-- beruecksichtigt.	
		DECLARE curLaeuferaktionen CURSOR FOR   
			SELECT DISTINCT [Feld]
			FROM @Bewertungsstellung
			WHERE 1 = 1
				AND [FigurBuchstabe]	= 'L'
				AND [IstSpielerWeiss]	= @IstSpielerWeiss
			ORDER BY [Feld];  
  
		OPEN curLaeuferaktionen
  
		FETCH NEXT FROM curLaeuferaktionen INTO @Laeuferfeld
  
		WHILE @@FETCH_STATUS = 0  
		BEGIN 

			INSERT INTO @MoeglicheAktionen
			(
				[TheoretischeAktionenID], [HalbzugNr], [FigurName], [IstSpielerWeiss], [StartSpalte],
				[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
				[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
				[ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex]
			)
			SELECT [TheoretischeAktionenID], 1, [FigurName], [IstSpielerWeiss], [StartSpalte],
				[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
				[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
				[ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex] 
			FROM [Spiel].[fncMoeglicheLaeuferaktionen] (@IstSpielerWeiss, @Bewertungsstellung, @Laeuferfeld)

			FETCH NEXT FROM curLaeuferaktionen INTO @Laeuferfeld 
		END
		CLOSE curLaeuferaktionen;  
		DEALLOCATE curLaeuferaktionen; 

		-- --------------------------------------------------------------------------
		-- Springer
		-- --------------------------------------------------------------------------

		-- Es werden alle auf dem Brett befindlichen Springer ermittelt. fuer jeden so gefundenen Springer werden nun alle 
		-- denkbaren und regelkonforme Aktionen notiert. Somit ist selbst nach mehrfacher Bauernumwandlung jeder Springer
		-- beruecksichtigt.	
		DECLARE curSpringeraktionen CURSOR FOR   
			SELECT DISTINCT [Feld]
			FROM @Bewertungsstellung
			WHERE 1 = 1
				AND [FigurBuchstabe]	= 'S'
				AND [IstSpielerWeiss]	= @IstSpielerWeiss
			ORDER BY [Feld];  
  
		OPEN curSpringeraktionen
  
		FETCH NEXT FROM curSpringeraktionen INTO @Springerfeld
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
			INSERT INTO @MoeglicheAktionen
			(
				[TheoretischeAktionenID], [HalbzugNr], [FigurName], [IstSpielerWeiss], [StartSpalte],
				[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
				[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
				[ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex]
			)
			SELECT [TheoretischeAktionenID], 1, [FigurName], [IstSpielerWeiss], [StartSpalte],
				[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
				[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
				[ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex] 
			FROM [Spiel].[fncMoeglicheSpringeraktionen] (@IstSpielerWeiss, @Bewertungsstellung, @Springerfeld)

			FETCH NEXT FROM curSpringeraktionen INTO @Springerfeld 
		END
		CLOSE curSpringeraktionen;  
		DEALLOCATE curSpringeraktionen; 

		---- --------------------------------------------------------------------------
		---- Koenig
		---- --------------------------------------------------------------------------

		-- Es ist nur genau ein farblich passender Koenig auf den Spielfeld. Eine Bauernumwandlung ist nicht zu beruecksichtigen.	
		SET @Koenigsfeld = (SELECT [Feld] FROM @Bewertungsstellung WHERE [FigurBuchstabe] = 'K' AND [IstSpielerWeiss] = @IstSpielerWeiss)
		INSERT INTO @MoeglicheAktionen
		(
			[TheoretischeAktionenID], [HalbzugNr], [FigurName], [IstSpielerWeiss], [StartSpalte],
			[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
			[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
			[ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex]
		)
		SELECT [TheoretischeAktionenID], 1, [FigurName], [IstSpielerWeiss], [StartSpalte],
			[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
			[UmwandlungsfigurBuchstabe], [ZugIstSchlag],	[ZugIstKurzeRochade], [ZugIstLangeRochade],
			[ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex]
		FROM [Spiel].[fncMoeglicheKoenigsaktionen] (@IstSpielerWeiss, @Bewertungsstellung, @Koenigsfeld)



		---- --------------------------------------------------------------------------
		---- Bauern
		---- --------------------------------------------------------------------------

		-- Es sind maximal 16 Bauern auf den Spielfeld. Eine Bauernumwandlung ist nicht zu beruecksichtigen.	
		DECLARE curBauernaktionen CURSOR FOR   
			SELECT DISTINCT [Feld]
			FROM @Bewertungsstellung
			WHERE 1 = 1
				AND [FigurBuchstabe]	= 'B'
				AND [IstSpielerWeiss]	= @IstSpielerWeiss
			ORDER BY [Feld];  
  
		OPEN curBauernaktionen
  
		FETCH NEXT FROM curBauernaktionen INTO @Bauernfeld
  
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
			INSERT INTO @MoeglicheAktionen
			(
				[TheoretischeAktionenID], [HalbzugNr], [FigurName], [IstSpielerWeiss], [StartSpalte],
				[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
				[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
				[ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex]
			)
			SELECT [TheoretischeAktionenID], 1, [FigurName], [IstSpielerWeiss], [StartSpalte],
				[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
				[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
				[ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex] 
			FROM [Spiel].[fncMoeglicheBauernaktionen] (@IstSpielerWeiss, @Bewertungsstellung, @Bauernfeld)

			FETCH NEXT FROM curBauernaktionen INTO @Bauernfeld 
		END
		CLOSE curBauernaktionen;  
		DEALLOCATE curBauernaktionen; 




		---- --------------------------------------------------------------------------
		---- illegale Zuege werden wieder rausgefiltert
		---- --------------------------------------------------------------------------




		---- --------------------------------------------------------------------------
		---- Rochaden
		---- --------------------------------------------------------------------------

		-- es kann vorkommen, dass eine Rochade als "gueltiger" Koenigszug ermittelt 
		-- wird, auch wenn die Spielregeln in dieser Situation eine Rochade 
		-- eigentlich unterbinden. Dies liegt daran, dass die Rochade einer der 
		-- drei Zuege (die anderen sind "en passant" und die Bauerumwandlung) ist, 
		-- bei dem gleich zwei Figuren betroffen sind. Dies kann durch eine einfache 
		-- Anfrage gegen die Tabelle [Infrastruktur].[TheoretischeAktionen] nicht 
		-- sauber geprueft werden, da weitere Daten notwewndig sind. Somit sind 
		-- evtl. fehlerhaft erfasste Zugmoeglichkeiten wieder zu entfernen...

		-- ***************
		-- *** WEISS *****
		-- ***************
		IF (SELECT [IstKurzeRochadeErlaubt] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = 'TRUE') = 'TRUE'
			OR (SELECT [IstLangeRochadeErlaubt] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = 'TRUE') = 'TRUE'
		BEGIN

			-- --------------------------------------------------------------------------------------
			-- Eine Rochade ist nur moeglich, wenn der Koenig an der 
			-- "richtigen" Position steht (also auch nicht geschlagen wurden)
			-- --------------------------------------------------------------------------------------
			IF EXISTS (SELECT * FROM @Bewertungsstellung WHERE [Feld] = 33 AND [FigurBuchstabe] = 'K' AND [IstSpielerWeiss] = 'TRUE')
			BEGIN
				-- --------------------------------------------------------------------------------------
				-- eine Rochade ist nur dann moeglich, wenn der Koenig noch nie gezogen
				-- hat - selbst wenn er zwischenzeitlich auf das Ausgangsfeld zurueckgekehrt ist.  
				-- Es reicht also in der Notation zu ueberpruefen, ob es einen Zug/Schlag in 
				-- der Partiehistorie von dem Ausgangsfeld weg gegeben hat...
				-- --------------------------------------------------------------------------------------
				IF (SELECT COUNT(*) FROM [Spiel].[Notation] WHERE [LangeNotation] LIKE 'K%' AND [IstSpielerWeiss] = 'TRUE') = 0
				BEGIN
					-- --------------------------------------------------------------------------------------
					-- Eine Rochade ist nur moeglich, wenn der zugehoeriger Turm an der 
					-- "richtigen" Position steht (also auch nicht geschlagen wurden)
					 --------------------------------------------------------------------------------------

					IF (SELECT [IstKurzeRochadeErlaubt] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = @IstSpielerWeiss) = 'TRUE'
					BEGIN
					
						-- kurze Rochade
						IF EXISTS (SELECT * FROM @Bewertungsstellung WHERE [Feld] = 57 AND [FigurBuchstabe] = 'T' AND [IstSpielerWeiss] = 'TRUE')
						BEGIN
							-- --------------------------------------------------------------------------------------
							-- eine Rochade ist nur dann moeglich, wenn der Turm noch nie gezogen
							-- hat - selbst wenn er auf das Ausgangsfeld zurueckgekehrt ist. Es reicht also 
							-- in der Notation zu ueberpruefen, ob es einen Zug/Schlag in der Partiehistorie
							-- von dem Ausgangsfeld weg gegeben hat...
							-- --------------------------------------------------------------------------------------
							IF (SELECT COUNT(*) FROM [Spiel].[Notation] WHERE [LangeNotation] LIKE 'Th1%' AND [IstSpielerWeiss] = 'TRUE') = 0
							BEGIN
								DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'ABCDEFG'
							--	-- --------------------------------------------------------------------------------------
							--	-- eine Rochade ist nur dann moeglich, wenn der Koenig nicht ueber ein gerade angegriffenes
							--	-- Feld ziehen muss. Alle Felder (seinen aktuellen Standort, das Zielfeld und alle Felder 
							--	-- dazwischen - nicht jedoch Felder, die nur vom Turmzug betroffen sind) duerfen daher nicht
							--	-- im "Schach" stehen
							--	-- --------------------------------------------------------------------------------------
							--	IF EXISTS (SELECT * FROM [Spiel].[fncVirtuelleSchlaege] ((@IstSpielerWeiss + 1) % 2, @Bewertungsstellung, 33))			-- Feld E1 angegriffen
							--		OR EXISTS (SELECT * FROM [Spiel].[fncVirtuelleSchlaege] ((@IstSpielerWeiss + 1) % 2, @Bewertungsstellung, 41))		-- Feld F1 angegriffen
							--		OR EXISTS (SELECT * FROM [Spiel].[fncVirtuelleSchlaege] ((@IstSpielerWeiss + 1) % 2, @Bewertungsstellung, 49))		-- Feld G1 angegriffen
							--	BEGIN
							--		DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-o' AND [IstSpielerWeiss] = 'TRUE'				-- kurze Rochade unmoeglich
							--	END
							END
							ELSE
							BEGIN
								DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-o' AND [IstSpielerWeiss] = 'TRUE'				-- kurze Rochade unmoeglich
							END
						END
						ELSE
						BEGIN
							DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-o' AND [IstSpielerWeiss] = 'TRUE'					-- kurze Rochade unmoeglich
						END
					END
					ELSE
					BEGIN
						DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-o' AND [IstSpielerWeiss] = 'TRUE'					-- kurze Rochade unmoeglich
					END

					IF (SELECT [IstLangeRochadeErlaubt] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = @IstSpielerWeiss) = 'TRUE'
					BEGIN
					
						-- lange Rochade
						IF EXISTS (SELECT * FROM @Bewertungsstellung WHERE [Feld] =  1 AND [FigurBuchstabe] = 'T' AND [IstSpielerWeiss] = 'TRUE')
						BEGIN
							-- --------------------------------------------------------------------------------------
							-- eine Rochade ist nur dann moeglich, wenn der Turm noch nie gezogen
							-- hat - selbst wenn er auf das Ausgangsfeld zurueckgekehrt ist. Es reicht also 
							-- in der Notation zu ueberpruefen, ob es einen Zug/Schlag in der Partiehistorie
							-- von dem Ausgangsfeld weg gegeben hat...
							-- --------------------------------------------------------------------------------------
							IF (SELECT COUNT(*) FROM [Spiel].[Notation] WHERE [LangeNotation] LIKE 'Ta1%' AND [IstSpielerWeiss] = 'TRUE') > 0
							BEGIN
								-- --------------------------------------------------------------------------------------
								-- eine Rochade ist nur dann moeglich, wenn der Koenig nicht ueber ein gerade angegriffenes
								-- Feld ziehen muss. Alle Felder (seinen aktuellen Standort, das Zielfeld und alle Felder 
								-- dazwischen - nicht jedoch Felder, die nur vom Turmzug betroffen sind) duerfen daher nicht
								-- im "Schach" stehen
								-- --------------------------------------------------------------------------------------
								IF (SELECT COUNT(*) FROM [Spiel].[frcMoeglicheVirtuelleSchlaegeAufFeld] ((@IstSpielerWeiss + 1) % 2, @Bewertungsstellung, 33)) <> 0			-- Feld E1 angegriffen
									OR (SELECT COUNT(*) FROM [Spiel].[frcMoeglicheVirtuelleSchlaegeAufFeld] ((@IstSpielerWeiss + 1) % 2, @Bewertungsstellung, 25)) <> 0		-- Feld D1 angegriffen
									OR (SELECT COUNT(*) FROM [Spiel].[frcMoeglicheVirtuelleSchlaegeAufFeld] ((@IstSpielerWeiss + 1) % 2, @Bewertungsstellung, 17)) <> 0		-- Feld C1 angegriffen
								BEGIN
									DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-o-o' AND [IstSpielerWeiss] = 'TRUE'			-- lange Rochade unmoeglich
								END

							END
							ELSE
							BEGIN
								DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-o-o' AND [IstSpielerWeiss] = 'TRUE'			-- lange Rochade unmoeglich
							END
						END
						ELSE
						BEGIN
							DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-o-o' AND [IstSpielerWeiss] = 'TRUE'				-- lange Rochade unmoeglich
						END
					END
					ELSE
					BEGIN
						DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-o-o' AND [IstSpielerWeiss] = 'TRUE'				-- lange Rochade unmoeglich
					END
				END
				ELSE
				BEGIN
					DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-%' AND [IstSpielerWeiss] = 'TRUE'						-- lange und kurze Rochade unmoeglich
				END
			END
			ELSE
			BEGIN
				DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-%' AND [IstSpielerWeiss] = 'TRUE'							-- lange und kurze Rochade unmoeglich
			END
		END
		ELSE
		BEGIN
			DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-%' AND [IstSpielerWeiss] = 'TRUE'							-- lange und kurze Rochade unmoeglich
		END

		-- ***************
		-- *** SCHWARZ ***
		-- ***************

		IF (SELECT [IstKurzeRochadeErlaubt] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = 'FALSE') = 'TRUE'
			OR (SELECT [IstLangeRochadeErlaubt] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = 'FALSE') = 'TRUE'
		BEGIN

			-- --------------------------------------------------------------------------------------
			-- Eine Rochade ist nur moeglich, wenn der Koenig an der 
			-- "richtigen" Position steht (also auch nicht geschlagen wurden)
			-- --------------------------------------------------------------------------------------
			IF EXISTS (SELECT * FROM @Bewertungsstellung WHERE [Feld] = 40 AND [FigurBuchstabe] = 'K' AND [IstSpielerWeiss] = 'FALSE')
			BEGIN
				-- --------------------------------------------------------------------------------------
				-- eine Rochade ist nur dann moeglich, wenn der Koenig noch nie gezogen
				-- hat - selbst wenn er zwischenzeitlich auf das Ausgangsfeld zurueckgekehrt ist.  
				-- Es reicht also in der Notation zu ueberpruefen, ob es einen Zug/Schlag in 
				-- der Partiehistorie von dem Ausgangsfeld weg gegeben hat...
				-- --------------------------------------------------------------------------------------
				IF (SELECT COUNT(*) FROM [Spiel].[Notation] WHERE [LangeNotation] LIKE 'K%' AND [IstSpielerWeiss] = 'FALSE') = 0
				BEGIN
					-- --------------------------------------------------------------------------------------
					-- Eine Rochade ist nur moeglich, wenn der zugehoeriger Turm an der 
					-- "richtigen" Position steht (also auch nicht geschlagen wurden)
					 --------------------------------------------------------------------------------------

					IF (SELECT [IstKurzeRochadeErlaubt] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = @IstSpielerWeiss) = 'FALSE'
					BEGIN
					
						-- kurze Rochade
						IF EXISTS (SELECT * FROM @Bewertungsstellung WHERE [Feld] = 64 AND [FigurBuchstabe] = 'T' AND [IstSpielerWeiss] = 'FALSE')
						BEGIN
							-- --------------------------------------------------------------------------------------
							-- eine Rochade ist nur dann moeglich, wenn der Turm noch nie gezogen
							-- hat - selbst wenn er auf das Ausgangsfeld zurueckgekehrt ist. Es reicht also 
							-- in der Notation zu ueberpruefen, ob es einen Zug/Schlag in der Partiehistorie
							-- von dem Ausgangsfeld weg gegeben hat...
							-- --------------------------------------------------------------------------------------
							IF (SELECT COUNT(*) FROM [Spiel].[Notation] WHERE [LangeNotation] LIKE 'Th8%' AND [IstSpielerWeiss] = 'FALSE') = 0
							BEGIN
								-- --------------------------------------------------------------------------------------
								-- eine Rochade ist nur dann moeglich, wenn der Koenig nicht ueber ein gerade angegriffenes
								-- Feld ziehen muss. Alle Felder (seinen aktuellen Standort, das Zielfeld und alle Felder 
								-- dazwischen - nicht jedoch Felder, die nur vom Turmzug betroffen sind) duerfen daher nicht
								-- im "Schach" stehen
								-- --------------------------------------------------------------------------------------
								IF (SELECT COUNT(*) FROM [Spiel].[fncVirtuelleSchlaege] ((@IstSpielerWeiss + 1) % 2, @Bewertungsstellung, 40)) <> 0		-- Feld E8 angegriffen
									OR (SELECT COUNT(*) FROM [Spiel].[fncVirtuelleSchlaege] ((@IstSpielerWeiss + 1) % 2, @Bewertungsstellung, 48)) <> 0	-- Feld F8 angegriffen
									OR (SELECT COUNT(*) FROM [Spiel].[fncVirtuelleSchlaege] ((@IstSpielerWeiss + 1) % 2, @Bewertungsstellung, 56)) <> 0	-- Feld G8 angegriffen
								BEGIN
									DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-o' AND [IstSpielerWeiss] = 'FALSE'				-- kurze Rochade unmoeglich
								END
							END
							ELSE
							BEGIN
								DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-o' AND [IstSpielerWeiss] = 'FALSE'				-- kurze Rochade unmoeglich
							END
						END
						ELSE
						BEGIN
							DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-o' AND [IstSpielerWeiss] = 'FALSE'					-- kurze Rochade unmoeglich
						END
					END
					ELSE
					BEGIN
						DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-o' AND [IstSpielerWeiss] = 'FALSE'					-- kurze Rochade unmoeglich
					END


					IF (SELECT [IstLangeRochadeErlaubt] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = @IstSpielerWeiss) = 'FALSE'
					BEGIN
					
						-- lange Rochade
						IF EXISTS (SELECT * FROM @Bewertungsstellung WHERE [Feld] =  8 AND [FigurBuchstabe] = 'T' AND [IstSpielerWeiss] = 'FALSE')
						BEGIN
							-- --------------------------------------------------------------------------------------
							-- eine Rochade ist nur dann moeglich, wenn der Turm noch nie gezogen
							-- hat - selbst wenn er auf das Ausgangsfeld zurueckgekehrt ist. Es reicht also 
							-- in der Notation zu ueberpruefen, ob es einen Zug/Schlag in der Partiehistorie
							-- von dem Ausgangsfeld weg gegeben hat...
							-- --------------------------------------------------------------------------------------
							IF (SELECT COUNT(*) FROM [Spiel].[Notation] WHERE [LangeNotation] LIKE 'Ta8%' AND [IstSpielerWeiss] = 'FALSE') > 0
							BEGIN
								-- --------------------------------------------------------------------------------------
								-- eine Rochade ist nur dann moeglich, wenn der Koenig nicht ueber ein gerade angegriffenes
								-- Feld ziehen muss. Alle Felder (seinen aktuellen Standort, das Zielfeld und alle Felder 
								-- dazwischen - nicht jedoch Felder, die nur vom Turmzug betroffen sind) duerfen daher nicht
								-- im "Schach" stehen
								-- --------------------------------------------------------------------------------------
								IF EXISTS (SELECT * FROM [Spiel].[frcMoeglicheVirtuelleSchlaegeAufFeld] ((@IstSpielerWeiss + 1) % 2, @Bewertungsstellung, 40))			-- Feld E8 angegriffen
									OR EXISTS (SELECT * FROM [Spiel].[frcMoeglicheVirtuelleSchlaegeAufFeld] ((@IstSpielerWeiss + 1) % 2, @Bewertungsstellung, 32))		-- Feld D8 angegriffen
									OR EXISTS (SELECT * FROM [Spiel].[frcMoeglicheVirtuelleSchlaegeAufFeld] ((@IstSpielerWeiss + 1) % 2, @Bewertungsstellung, 24))		-- Feld C8 angegriffen
								BEGIN
									DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-o-o' AND [IstSpielerWeiss] = 'FALSE'			-- lange Rochade unmoeglich
								END

							END
							ELSE
							BEGIN
								DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-o-o' AND [IstSpielerWeiss] = 'FALSE'			-- lange Rochade unmoeglich
							END
						END
						ELSE
						BEGIN
							DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-o-o' AND [IstSpielerWeiss] = 'FALSE'				-- lange Rochade unmoeglich
						END
					END
					ELSE
					BEGIN
						DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-o-o' AND [IstSpielerWeiss] = 'FALSE'				-- lange Rochade unmoeglich
					END
				END
				ELSE
				BEGIN
					DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-%' AND [IstSpielerWeiss] = 'FALSE'						-- lange und kurze Rochade unmoeglich
				END
			END
			ELSE
			BEGIN
				DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-%' AND [IstSpielerWeiss] = 'FALSE'							-- lange und kurze Rochade unmoeglich
			END
		END
		ELSE
		BEGIN
			DELETE FROM @MoeglicheAktionen WHERE [LangeNotation] LIKE 'o-%' AND [IstSpielerWeiss] = 'FALSE'							-- lange und kurze Rochade unmoeglich
		END

	

		---- --------------------------------------------------------------------------
		---- en passant
		---- --------------------------------------------------------------------------

		-- es kann vorkommen, dass ein "en Passant"-Schlag als "gueltiger" Schlag ermittelt 
		-- wird, auch wenn die Spielregeln in dieser Situation einen "en Passant"-Schlag
		-- eigentlich unterbinden. Dies liegt daran, dass der "en Passant"-Schlag einer der 
		-- drei Zuege (die anderen sind Rochade und die Bauerumwandlung) ist, 
		-- bei dem gleich zwei Figuren betroffen sind. Dies kann durch eine einfache 
		-- Anfrage gegen die Tabelle [Infrastruktur].[TheoretischeAktionen] nicht 
		-- sauber geprueft werden, da weitere Daten notwewndig sind. Somit sind 
		-- evtl. fehlerhaft erfasste Zugmoeglichkeiten wieder zu entfernen...

		--DELETE FROM @MoeglicheAktionen
		--WHERE 1 = 1
		--	AND [LangeNotation] like '%e.p.'	
		--	AND [IstSpielerWeiss] = 'FALSE'
		--	AND (
		--			[Spiel].[fncIstFeldBedroht]([IstSpielerWeiss], @Bewertungsstellung, 24) = 'TRUE'
		--			OR
		--			[Spiel].[fncIstFeldBedroht]([IstSpielerWeiss], @Bewertungsstellung, 32) = 'TRUE'
		--		)
		--		-- WEITERE BEDINGUNGEN ZU IMPLEMENTIEREN

	RETURN
	END 
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '048 - Funktion [Spiel].[fncMoeglicheAktionen] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO



/*
-- Test der Funktion [Spiel].[fncMoeglicheAktionen]

DECLARE @Bewertungsstellung		AS [dbo].[typStellung]

INSERT INTO @Bewertungsstellung
	SELECT 
		  1								AS [VarianteNr]
		, 1								AS [Suchtiefe]
		, [SB].[Spalte]					AS [Spalte]
		, [SB].[Reihe]					AS [Reihe]
		, [SB].[Feld]					AS [Feld]
		, [SB].[IstSpielerWeiss]		AS [IstSpielerWeiss]
		, [FigurBuchstabe]				AS [FigurBuchstabe]
		, [SB].[FigurUTF8]				AS [FigurUTF8]
	FROM [Infrastruktur].[Spielbrett]	AS [SB]


SELECT * FROM [Spiel].[fncMoeglicheAktionen]('FALSE', @Bewertungsstellung)

GO
*/
