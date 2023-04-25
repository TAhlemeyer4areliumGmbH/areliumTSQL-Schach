--###########################################################################################
-- ### Spiel der Koenige - Workshopversion ###################################################
-- ###########################################################################################
-- ### Moegliche Aktionen zusammenstellen                                                  ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Diese Prozedur durchlaeuft alle Figuren eines Spielers und notiert die damit laut   ###
-- ### Spielregeln gueltig durchzufuehrenden Aktionen. Es werden also alle Optionen        ###
-- ### erfasst, die der Spieler hat, um das Spiel regelkonform fortzusetzen.               ###
-- ###                                                                                     ###
-- ### Es werden alle Figurentypen per Cursor durchlaufen, da vorher nicht feststeht,      ###
-- ### wieveiel Figuren dieses Typs noch auf dem Brett stehen. Durch Bauernumwandlung      ###
-- ### kann die Zahl der Schwerfiguren (T, S, D, L) erhoeht worden sein. Durch Schlaege    ###
-- ### im Spielverlauf kann die Zahl der Figuren jedes Typs mit Ausnahme des Koenigs       ###
-- ### reduziert worden sein.                                                              ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Sicherheitshinweis:                                                                 ###
-- ###      Ueber diese Befehlssammlung werden Datenbankobjekte angelegt, geaendert oder   ###
-- ###      geloescht. Auch koennen Inhalte hinzugefuegt, manipuliert oder entfernt        ###
-- ###      werden. In produktiven Umgebungen darf dieses Skript NICHT eingesetzt werden,  ###
-- ###      um versehentliche Auswirkungen auf sonstige Strukturen auszuschliessen.        ###
-- ###                                                                                     ###
-- ### Erstellung:                                                                         ###
-- ###      Torsten Ahlemeyer fuer arelium GmbH, www.arelium.de                            ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Aenderungsnachweis:                                                                 ###
-- ###     1.00.0	2022-04-22	Torsten Ahlemeyer                                          ###
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


USE [Workshop_SpielDerKoenige_V004]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Diese Prozedur erstellt und fuellt eine Tabelle mit allen Aktionen, die von der uebergebenen Stellung aus unter 
-- Beruecksichtigung der Spielregeln genutzt werden koennen. Es werden Aktionen fuer beide Spieler ermittelt - die 
-- aufrufende Stelle muss auswerten, welcher Spieler am Zug ist
CREATE OR ALTER PROCEDURE [Spiel].[prcMoeglicheaktionenZusammenstellen]
	(
		  @ASpielbrett			AS [dbo].[typStellung]			READONLY
		, @SpielID				AS [BIGINT]
		, @StartZugNr			AS [INTEGER]
		, @Suchtiefe			AS [TINYINT]
	)
AS
BEGIN
	SET NOCOUNT ON;
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
	DECLARE @LangeNotation		AS VARCHAR(7)
	DECLARE @Umwandlungsfigur	AS CHAR(1)
	DECLARE @IstSpielerWeiss	AS BIT
	DECLARE @Startfeld			AS INTEGER
	DECLARE @Zielfeld			AS INTEGER


	-- --------------------------------------------------------------------------
	-- Damen
	-- --------------------------------------------------------------------------

	-- Es werden alle auf dem Brett befindlichen Damen ermittelt. Für jede so gefundene Dame werden nun alle 
	-- denkbaren und regelkonforme Aktionen notiert. Somit ist selbst nach mehrfacher Bauernumwandlung jede Dame 
	-- beruecksichtigt.
	DECLARE curDamenaktionen CURSOR FOR   
		SELECT DISTINCT [Feld]
		FROM @ASpielbrett
		WHERE 1 = 1
			AND [FigurBuchstabe]	= 'D'
		ORDER BY [Feld];  

	OPEN curDamenaktionen
  
	FETCH NEXT FROM curDamenaktionen INTO @Damenfeld
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		INSERT INTO [Spiel].[MoeglicheAktionen]
			([TheoretischeAktionenID], [SpielID], [StartZugNr], [Suchtiefe], [FigurName], [IstSpielerWeiss], [StartSpalte],
			[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
			[UmwandlungsfigurBuchstabe], [ZugIstSchlag],	[ZugIstKurzeRochade], [ZugIstLangeRochade],
			[ZugIstEnPassant], [LangeNotation])
		SELECT [TheoretischeAktionenID], @SpielID, @StartZugNr, @Suchtiefe, [FigurName], [IstSpielerWeiss], [StartSpalte],
			[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
			[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
			[ZugIstEnPassant], [LangeNotation] 
		FROM [Spiel].[fncMoeglicheDamenaktionen] (
														(	SELECT [IstSpielerWeiss] 
															FROM @ASpielbrett 
															WHERE 1 = 1
																AND [Feld]		= @Damenfeld)
														, @ASpielbrett
														, @Damenfeld)

		FETCH NEXT FROM curDamenaktionen INTO @Damenfeld 
	END
	CLOSE curDamenaktionen;  
	DEALLOCATE curDamenaktionen; 


	-- --------------------------------------------------------------------------
	-- Tuerme
	-- --------------------------------------------------------------------------

	-- Es werden alle auf dem Brett befindlichen Tuerme ermittelt. Für jeden so gefundenen Turm werden nun alle 
	-- denkbaren und regelkonforme Aktionen notiert. Somit ist selbst nach mehrfacher Bauernumwandlung jeder Turm 
	-- beruecksichtigt.	
	DECLARE curTurmaktionen CURSOR FOR   
		SELECT DISTINCT [Feld]
		FROM @ASpielbrett
		WHERE 1 = 1
			AND [FigurBuchstabe]	= 'T'
		ORDER BY [Feld];  
  
	OPEN curTurmaktionen
  
	FETCH NEXT FROM curTurmaktionen INTO @Turmfeld
  
	WHILE @@FETCH_STATUS = 0  
	BEGIN 

		INSERT INTO [Spiel].[MoeglicheAktionen]
			([TheoretischeAktionenID], [SpielID], [StartZugNr], [Suchtiefe], [FigurName], [IstSpielerWeiss], [StartSpalte],
			[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
			[UmwandlungsfigurBuchstabe], [ZugIstSchlag],	[ZugIstKurzeRochade], [ZugIstLangeRochade],
			[ZugIstEnPassant], [LangeNotation])
		SELECT [TheoretischeAktionenID], @SpielID, @StartZugNr, @Suchtiefe, [FigurName], [IstSpielerWeiss], [StartSpalte],
			[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
			[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
			[ZugIstEnPassant], [LangeNotation] 
		FROM [Spiel].[fncMoeglicheTurmaktionen] (
														(	SELECT [IstSpielerWeiss] 
															FROM @ASpielbrett 
															WHERE 1 = 1
																AND [Feld]		= @Turmfeld)
														, @ASpielbrett
														, @Turmfeld)

		FETCH NEXT FROM curTurmaktionen INTO @Turmfeld 
	END
	CLOSE curTurmaktionen;  
	DEALLOCATE curTurmaktionen; 

	-- --------------------------------------------------------------------------
	-- Laeufer
	-- --------------------------------------------------------------------------

	-- Es werden alle auf dem Brett befindlichen Laeufer ermittelt. Für jeden so gefundenen Laeufer werden nun alle 
	-- denkbaren und regelkonforme Aktionen notiert. Somit ist selbst nach mehrfacher Bauernumwandlung jeder Laeufer
	-- beruecksichtigt.	
	DECLARE curLaeuferaktionen CURSOR FOR   
		SELECT DISTINCT [Feld]
		FROM @ASpielbrett
		WHERE 1 = 1
			AND [FigurBuchstabe]	= 'L'
		ORDER BY [Feld];  
  
	OPEN curLaeuferaktionen
  
	FETCH NEXT FROM curLaeuferaktionen INTO @Laeuferfeld
  
	WHILE @@FETCH_STATUS = 0  
	BEGIN 

		INSERT INTO [Spiel].[MoeglicheAktionen]
			([TheoretischeAktionenID], [SpielID], [StartZugNr], [Suchtiefe], [FigurName], [IstSpielerWeiss], [StartSpalte],
			[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
			[UmwandlungsfigurBuchstabe], [ZugIstSchlag],	[ZugIstKurzeRochade], [ZugIstLangeRochade],
			[ZugIstEnPassant], [LangeNotation])
		SELECT [TheoretischeAktionenID], @SpielID, @StartZugNr, @Suchtiefe, [FigurName], [IstSpielerWeiss], [StartSpalte],
			[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
			[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
			[ZugIstEnPassant], [LangeNotation] 
		FROM [Spiel].[fncMoeglicheLaeuferaktionen] (
														(	SELECT [IstSpielerWeiss] 
															FROM @ASpielbrett 
															WHERE 1 = 1
																AND [Feld]		= @Laeuferfeld)
														, @ASpielbrett
														, @Laeuferfeld)

		FETCH NEXT FROM curLaeuferaktionen INTO @Laeuferfeld 
	END
	CLOSE curLaeuferaktionen;  
	DEALLOCATE curLaeuferaktionen; 

	-- --------------------------------------------------------------------------
	-- Springer
	-- --------------------------------------------------------------------------

	-- Es werden alle auf dem Brett befindlichen Springer ermittelt. Für jeden so gefundenen Springer werden nun alle 
	-- denkbaren und regelkonforme Aktionen notiert. Somit ist selbst nach mehrfacher Bauernumwandlung jeder Springer
	-- beruecksichtigt.	
	DECLARE curSpringeraktionen CURSOR FOR   
		SELECT DISTINCT [Feld]
		FROM @ASpielbrett
		WHERE 1 = 1
			AND [FigurBuchstabe]	= 'S'
		ORDER BY [Feld];  
  
	OPEN curSpringeraktionen
  
	FETCH NEXT FROM curSpringeraktionen INTO @Springerfeld
	WHILE @@FETCH_STATUS = 0  
	BEGIN 

		INSERT INTO [Spiel].[MoeglicheAktionen]
			([TheoretischeAktionenID], [SpielID], [StartZugNr], [Suchtiefe], [FigurName], [IstSpielerWeiss], [StartSpalte],
			[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
			[UmwandlungsfigurBuchstabe], [ZugIstSchlag],	[ZugIstKurzeRochade], [ZugIstLangeRochade],
			[ZugIstEnPassant], [LangeNotation])
		SELECT [TheoretischeAktionenID], @SpielID, @StartZugNr, @Suchtiefe, [FigurName], [IstSpielerWeiss], [StartSpalte],
			[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
			[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
			[ZugIstEnPassant], [LangeNotation] 
		FROM [Spiel].[fncMoeglicheSpringeraktionen] (
														(	SELECT [IstSpielerWeiss] 
															FROM @ASpielbrett 
															WHERE 1 = 1
																AND [Feld]		= @Springerfeld)
														, @ASpielbrett
														, @Springerfeld)

		FETCH NEXT FROM curSpringeraktionen INTO @Springerfeld 
	END
	CLOSE curSpringeraktionen;  
	DEALLOCATE curSpringeraktionen; 

	-- --------------------------------------------------------------------------
	-- Koenig
	-- --------------------------------------------------------------------------

	-- Es sind genau zwei Koenige auf den Spielfeld. Eine Bauernumwandlung ist nicht zu beruecksichtigen.	
	IF 
		(SELECT [IstSpielerWeiss] FROM @ASpielbrett WHERE [Feld] = @Koenigsfeld) = 'TRUE'
	BEGIN
		SET @Koenigsfeld = (SELECT [Feld] FROM @ASpielbrett WHERE [FigurBuchstabe] = 'K' AND [IstSpielerWeiss] = 'TRUE')
		INSERT INTO [Spiel].[MoeglicheAktionen]
			([TheoretischeAktionenID], [FigurName], [IstSpielerWeiss], [StartSpalte],
			[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
			[UmwandlungsfigurBuchstabe], [ZugIstSchlag],	[ZugIstKurzeRochade], [ZugIstLangeRochade],
			[ZugIstEnPassant], [LangeNotation])
		SELECT [TheoretischeAktionenID], [FigurName], [IstSpielerWeiss], [StartSpalte],
			[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
			[UmwandlungsfigurBuchstabe], [ZugIstSchlag],	[ZugIstKurzeRochade], [ZugIstLangeRochade],
			[ZugIstEnPassant], [LangeNotation] 
		FROM [Spiel].[fncMoeglicheKoenigsaktionen] ('TRUE', @ASpielbrett, @Koenigsfeld)
	END
	ELSE
	BEGIN
		SET @Koenigsfeld = (SELECT [Feld] FROM @ASpielbrett WHERE [FigurBuchstabe] = 'K' AND [IstSpielerWeiss] = 'FALSE')
		INSERT INTO [Spiel].[MoeglicheAktionen]
			([TheoretischeAktionenID], [FigurName], [IstSpielerWeiss], [StartSpalte],
			[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
			[UmwandlungsfigurBuchstabe], [ZugIstSchlag],	[ZugIstKurzeRochade], [ZugIstLangeRochade],
			[ZugIstEnPassant], [LangeNotation])
		SELECT [TheoretischeAktionenID], [FigurName], [IstSpielerWeiss], [StartSpalte],
			[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
			[UmwandlungsfigurBuchstabe], [ZugIstSchlag],	[ZugIstKurzeRochade], [ZugIstLangeRochade],
			[ZugIstEnPassant], [LangeNotation] 
		FROM [Spiel].[fncMoeglicheKoenigsaktionen] ('FALSE', @ASpielbrett, @Koenigsfeld)
	END



	-- --------------------------------------------------------------------------
	-- Bauern
	-- --------------------------------------------------------------------------

	-- Es sind maximal 16 Bauern auf den Spielfeld. Eine Bauernumwandlung ist nicht zu beruecksichtigen.	
	DECLARE curBauernaktionen CURSOR FOR   
		SELECT DISTINCT [Feld]
		FROM @ASpielbrett
		WHERE 1 = 1
			AND [FigurBuchstabe]	= 'B'
		ORDER BY [Feld];  
  
	OPEN curBauernaktionen
  
	FETCH NEXT FROM curBauernaktionen INTO @Bauernfeld
  
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		INSERT INTO [Spiel].MoeglicheAktionen
			([TheoretischeAktionenID], [SpielID], [StartZugNr], [Suchtiefe], [FigurName], [IstSpielerWeiss], [StartSpalte],
			[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
			[UmwandlungsfigurBuchstabe], [ZugIstSchlag],	[ZugIstKurzeRochade], [ZugIstLangeRochade],
			[ZugIstEnPassant], [LangeNotation])
		SELECT [TheoretischeAktionenID], @SpielID, @StartZugNr, @Suchtiefe, [FigurName], [IstSpielerWeiss], [StartSpalte],
			[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
			[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
			[ZugIstEnPassant], [LangeNotation] 
		FROM [Spiel].[fncMoeglicheBauernaktionen] (
														(	SELECT [IstSpielerWeiss] 
															FROM @ASpielbrett 
															WHERE 1 = 1
																AND [Feld]		= @Bauernfeld)
														, @ASpielbrett
														, @Bauernfeld)

		FETCH NEXT FROM curBauernaktionen INTO @Bauernfeld 
	END
	CLOSE curBauernaktionen;  
	DEALLOCATE curBauernaktionen; 

	-- --------------------------------------------------------------------------
	-- Rochaden
	-- --------------------------------------------------------------------------

	-- Fuer die Frage, ob eine Rochade (kurz/lang) noch moeglich ist, gibt es eine eigene 
	-- Funktion [Spiel].[fncMoeglicheRochaden]. Gefuettert mit der Spielerfarbe, der Stellung und 
	-- den bisherigen Aktionen gibt sie Auskunft, welche Rochade die Spielregeln noch erlauben.
	--INSERT INTO [Spiel].[MoeglicheAktionen]
	--	([TheoretischeAktionenID], [FigurName], [IstSpielerWeiss], [StartSpalte],
	--	[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
	--	[UmwandlungsfigurBuchstabe], [ZugIstSchlag],	[ZugIstKurzeRochade], [ZugIstLangeRochade],
	--	[ZugIstEnPassant], [LangeNotation])
	--SELECT [TheoretischeAktionenID], [FigurName], [IstSpielerWeiss], [StartSpalte],
	--	[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
	--	[UmwandlungsfigurBuchstabe], [ZugIstSchlag],	[ZugIstKurzeRochade], [ZugIstLangeRochade],
	--	[ZugIstEnPassant], [LangeNotation] 
	--FROM [Spiel].[fncMoeglicheRochaden] ('TRUE', @ASpielbrett, @Notation)

	--INSERT INTO [Spiel].[MoeglicheAktionen]
	--	([TheoretischeAktionenID], [FigurName], [IstSpielerWeiss], [StartSpalte],
	--	[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
	--	[UmwandlungsfigurBuchstabe], [ZugIstSchlag],	[ZugIstKurzeRochade], [ZugIstLangeRochade],
	--	[ZugIstEnPassant], [LangeNotation])
	--SELECT [TheoretischeAktionenID], [FigurName], [IstSpielerWeiss], [StartSpalte],
	--	[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
	--	[UmwandlungsfigurBuchstabe], [ZugIstSchlag],	[ZugIstKurzeRochade], [ZugIstLangeRochade],
	--	[ZugIstEnPassant], [LangeNotation] 
	--FROM [Spiel].[fncMoeglicheRochaden] ('FALSE', @ASpielbrett, @Notation)



	-- Gefesselte Figuren duerfen nicht ziehen. Als "gefesselt" gilt eine Figur, wenn sie aktiv eine Schachdrohung 
	-- einer Dame, eines Turmes oder eines Laeufers unterbricht, in dem sie in der Wirklinie steht. Aus dieser 
	-- darf sie nicht wegziehen, da sie sonst den eigenen Koenig einem Schach aussetzen wuerde.
	--DELETE FROM [Spiel].[MoeglicheAktionen]
	--WHERE [Startfeld] IN
	--	(
	--		SELECT DISTINCT [Startfeld]
	--		FROM [Spiel].[MoeglicheAktionen]
	--		WHERE 1 = 1
	--			AND [FigurName]				<> 'Koenig'
	--			AND [IstSpielerWeiss]		= @IstSpielerWeiss
	--			AND [StartFeld]				IN (
	--												SELECT [Feld] 
	--												FROM @ASpielbrett 
	--												WHERE 1 = 1
	--													AND [IstSpielerWeiss]		= @IstSpielerWeiss 
	--													AND [FigurUTF8]				<> 160
	--											)
	--			AND [Spiel].[fncFeldIstGefesselt](@ASpielbrett, [Startfeld], @IstSpielerWeiss) = 'TRUE'

	--	)

	-- --------------------------------------------------------------------------
	-- Schachstellungen
	-- --------------------------------------------------------------------------

	-- Nun muessen fuer den Fall, dass der aktive Spieler im Schach steht, alle Aktionen entfernt 
	-- werden, die das Schach nicht aufheben

	--SET @IstSpielerWeiss = [Spiel].[fncIstWeissAmZug] ()
	--SET @Koenigsfeld		= (SELECT [Feld] FROM @ASpielbrett WHERE [FigurBuchstabe] = 'K' AND [IstSpielerWeiss] = @IstSpielerWeiss)
	--SET @ZugIstSchachgebot	= CASE @IstSpielerWeiss 
	--								WHEN 1 THEN (SELECT [Spiel].[fncIstFeldUnterBeschuss] (@ASpielbrett, @Koenigsfeld, 'FALSE'))
	--								ELSE (SELECT [Spiel].[fncIstFeldUnterBeschuss] (@ASpielbrett, @Koenigsfeld, 'TRUE'))
	--							END

	--IF @ZugIstSchachgebot = 'TRUE'
	--BEGIN
	--	-- Es wird ein Cursor gebildet, der alle bisher ermittelten potentiellen Aktionen beinhaltet
	--	DECLARE curSchachstellung CURSOR FOR   
	--		SELECT [TheoretischeAktionenID]
	--		FROM [Spiel].[MoeglicheAktionen]
	--		WHERE 1 = 1
	--			AND [ZugIstKurzeRochade]	= 'FALSE'
	--			AND [ZugIstLangeRochade]	= 'FALSE'
	--			AND [IstSpielerWeiss]		= @IstSpielerWeiss
	--		ORDER BY [TheoretischeAktionenID];  

	--	OPEN curSchachstellung
  
	--	FETCH NEXT FROM curSchachstellung INTO @Schachstellung
  
	--	WHILE @@FETCH_STATUS = 0  
	--	BEGIN 

	--		DELETE FROM @BSpielbrett

	--		INSERT INTO @BSpielbrett
	--		SELECT 
	--			  1									AS [VarianteNr]
	--			, 1									AS [Suchtiefe]
	--			, [SB].[Spalte]						AS [Spalte]
	--			, [SB].[Reihe]						AS [Reihe]
	--			, [SB].[Feld]						AS [Feld]
	--			, [SB].[IstSpielerWeiss]			AS [IstSpielerWeiss]
	--			, [SB].[FigurBuchstabe]				AS [FigurBuchstabe]
	--			, [SB].[FigurUTF8]					AS [FigurUTF8]
	--		FROM @ASpielbrett AS [SB]

	--		-- hier wird der Wunschzug durchgefuehrt. Im Falle einer Bauernumwandlung oder eines "en passant" 
	--		-- sind evtl. mehr als nur eine Figur betroffen. Rochaden sind kein moeglicher Zug zur Abwehr
	--		-- eines Schachgebotes

	--		-- Hier ist bewusst das 'FALSE' nicht durch den eigentlich korrekten Aufruf 
	--		-- "ZugIstSchach" bzw. "ZugIstMatt" ersetzt. Spaeter wird mit RIGHT() auf das Stringende von 
	--		-- @LangeNotation geprueft, um Bauernumwandlungen korrekt erkennen zu koennen.
	--		SET @LangeNotation		= (SELECT [Infrastruktur].[fncLangeNotation] (@Schachstellung, 'FALSE', 'FALSE'))

	--		SET @Startfeld		= (	SELECT [StartFeld] 
	--						FROM [Infrastruktur].[TheoretischeAktionen]
	--						WHERE 1 = 1
	--							AND [TheoretischeAktionenID] = @Schachstellung)
			
	--		SET @Zielfeld		= (	SELECT [ZielFeld] 
	--						FROM [Infrastruktur].[TheoretischeAktionen]
	--						WHERE 1 = 1
	--							AND [TheoretischeAktionenID] = @Schachstellung)

	--		IF RIGHT(@LangeNotation, 1) IN ('T', 'S', 'L', 'D') -- Bauernumwandlung
	--		BEGIN
	--			UPDATE @BSpielbrett
	--			SET   [FigurUTF8]			= (SELECT [FigurUTF8] FROM [Infrastruktur].[Figur] WHERE [FigurBuchstabe] = @Umwandlungsfigur)
	--				, [FigurBuchstabe]		= @Umwandlungsfigur
	--				, [IstSpielerWeiss]		= @IstSpielerWeiss
	--			WHERE [Feld] = @Zielfeld
	--		END
	--		ELSE
	--		BEGIN
	--			IF RIGHT(@LangeNotation, 1) IN ('p')			-- en passant
	--			BEGIN
	--				IF @IstSpielerWeiss = 'TRUE'				-- Weiss schlaegt Schwarz
	--				BEGIN
	--					UPDATE @BSpielbrett
	--					SET   [FigurUTF8]			= 160
	--						, [FigurBuchstabe]		= ' '
	--						, [IstSpielerWeiss]		= NULL
	--					WHERE [Feld] = @Zielfeld - 1			-- entfernt wird der gegenerische Bauer unter dem Zielfeld
	--				END
	--				ELSE
	--				BEGIN										-- Schwarz schlaegt Weiss
	--					UPDATE @BSpielbrett
	--					SET   [FigurUTF8]			= 160
	--						, [FigurBuchstabe]		= ' '
	--						, [IstSpielerWeiss]		= NULL
	--					WHERE [Feld] = @Zielfeld + 1			-- entfernt wird der gegenerische Bauer ueber dem Zielfeld
	--				END
	--			END

	--			UPDATE @BSpielbrett
	--			SET   [FigurUTF8]			= (SELECT [FigurUTF8]		FROM [Infrastruktur].[Spielbrett] WHERE [Feld] = @Startfeld)
	--				, [FigurBuchstabe]		= (SELECT [FigurBuchstabe]	FROM [Infrastruktur].[Spielbrett] WHERE [Feld] = @Startfeld)
	--				, [IstSpielerWeiss]		= @IstSpielerWeiss
	--			WHERE [Feld] = @Zielfeld
	--		END

	--		-- altes Startfeld leeren
	--		UPDATE @BSpielbrett
	--		SET	  [FigurUTF8]			= 160
	--			, [FigurBuchstabe]		= ' '
	--			, [IstSpielerWeiss]		= NULL
	--		WHERE [Feld] = @Startfeld

	--		SET @Koenigsfeld		= (SELECT [Feld] FROM @BSpielbrett WHERE [FigurBuchstabe] = 'K' AND [IstSpielerWeiss] = @IstSpielerWeiss)
	--		SET @ZugIstSchachgebot	= CASE @IstSpielerWeiss 
	--										WHEN 'TRUE' THEN (SELECT [Spiel].[fncIstFeldUnterBeschuss] (@BSpielbrett, @Koenigsfeld, 'FALSE'))
	--										ELSE (SELECT [Spiel].[fncIstFeldUnterBeschuss] (@BSpielbrett, @Koenigsfeld, 'TRUE'))
	--									END
	--		IF @ZugIstSchachgebot = 'TRUE'
	--		BEGIN
	--			DELETE FROM [Spiel].[MoeglicheAktionen]
	--			WHERE [TheoretischeAktionenID] = @Schachstellung
	--		END

	--		FETCH NEXT FROM curSchachstellung INTO @Schachstellung 
	--	END
	--	CLOSE curSchachstellung;  
	--	DEALLOCATE curSchachstellung; 
	--END

	-- wenn es keine moeglichen Aktionen mehr gibt, kann das zwei Ursachen haben: Der Spieler wurde matt gesetzt (dann 
	-- steht er im Schach) oder die Partie endet in einem Patt (dabei gibt es kein Schachgebot)
	--IF (SELECT COUNT(*) FROM [Spiel].[MoeglicheAktionen] WHERE [IstSpielerWeiss] = @IstSpielerWeiss) = 0
	--BEGIN

	--	-- So oder so, die Partie ist vorbei. Somit kann [Spiel].[Zugarchiv] in [Archiv].[Zugarchiv] umkopiert
	--	-- werden
	--	INSERT INTO [Archiv].[Zugarchiv]
	--		([SpielID], [HalbzugID], [Spalte], [Reihe], [Feld], [IstSpielerWeiss], [FigurBuchstabe], [FigurUTF8])
	--	SELECT 
	--		(SELECT ISNULL(MAX([SpielID]), 0) + 1 FROM [Archiv].[Zugarchiv])
	--		, [HalbzugID], [Spalte], [Reihe], [Feld], [IstSpielerWeiss], [FigurBuchstabe], [FigurUTF8]
	--	FROM [Spiel].[Zugarchiv]


	--	-- Matt oder Patt?
	--	IF	(
	--			SELECT TOP 1 RIGHT([LangeNotation], 1)
	--			FROM [Spiel].[Notation]
	--			WHERE 1 = 1
	--				AND [VollzugID]			= (SELECT MAX([VollzugID]) FROM [Spiel].[Notation])
	--				AND [IstSpielerWeiss]	= ((SELECT COUNT(*) FROM  [Spiel].[Notation]) % 2)			-- ungerade Halbzuganzahl = WEISS
	--		) = '+'
	--	BEGIN
	--		-- In die aktuell leere Tabelle [Spiel].[MoeglicheAktionen] werden nun zwei FAKE-Datensaetze geschrieben, die (einmal fuer 
	--		-- Weiss, einmal fuer Schwarz) ueber das MATT informieren
	--		INSERT INTO [Spiel].[MoeglicheAktionen]
	--				   ([TheoretischeAktionenID], [FigurName], [IstSpielerWeiss], [StartSpalte], [StartReihe], [StartFeld], [ZielSpalte]
	--				   , [ZielReihe], [ZielFeld], [Richtung], [UmwandlungsfigurBuchstabe] ,[ZugIstSchlag],[ZugIstKurzeRochade], [ZugIstLangeRochade]
	--				   , [ZugIstEnPassant],[LangeNotation])
	--			 VALUES
	--					 (99998, '#', 'TRUE',  'A', 1, 1, 'A', 2, 2, 'OB', NULL, 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'MATT')
	--				   , (99999, '#', 'FALSE', 'A', 1, 1, 'A', 2, 2, 'OB', NULL, 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'MATT')

	--		UPDATE [Archiv].[Partien]
	--		SET	  [PunkteWeiss]				=    ((SELECT COUNT(*) FROM  [Spiel].[Notation]) % 2)
	--			, [PunkteSchwarz]			= 1- ((SELECT COUNT(*) FROM  [Spiel].[Notation]) % 2)
	--			, [Ergebnisbegruendung]		= 'Matt'
			
	--		-- Das "Schach" (+) in der langen Notation des letzten Zuges durch eine Matt (#) ersetzen. Theoretisch kann der 
	--		-- entscheidene letzte Zug auch eine Doppelschach gewesen sein, daher das verschachtelte REPLACE
	--		UPDATE [Spiel].[Notation]
	--		SET [LangeNotation] = REPLACE(REPLACE([LangeNotation], '+', '#'), '##', '#')
	--		WHERE 1 = 1
	--			AND [VollzugID]			= (SELECT MAX([VollzugID]) FROM [Spiel].[Notation])
	--			AND [IstSpielerWeiss]	= ((SELECT COUNT(*) FROM  [Spiel].[Notation]) % 2)			-- ungerade Halbzuganzahl = WEISS
	--	END
	--	ELSE
	--	BEGIN
	--		-- In die aktuell leere Tabelle [Spiel].[MoeglicheAktionen] werden nun zwei FAKE-Datensaetze geschrieben, die (einmal fuer 
	--		-- Weiss, einmal fuer Schwarz) ueber das PATT informieren
	--		INSERT INTO [Spiel].[MoeglicheAktionen]
	--				   ([TheoretischeAktionenID], [FigurName], [IstSpielerWeiss], [StartSpalte], [StartReihe], [StartFeld], [ZielSpalte]
	--				   , [ZielReihe], [ZielFeld], [Richtung], [UmwandlungsfigurBuchstabe] ,[ZugIstSchlag],[ZugIstKurzeRochade], [ZugIstLangeRochade]
	--				   , [ZugIstEnPassant],[LangeNotation])
	--			 VALUES
	--					 (99996, '#', 'TRUE',  'A', 1, 1, 'A', 2, 2, 'OB', NULL, 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'Patt')
	--				   , (99997, '#', 'FALSE', 'A', 1, 1, 'A', 2, 2, 'OB', NULL, 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'Patt')

	--		UPDATE [Archiv].[Partien]
	--		SET	  [PunkteWeiss]				= 0.5
	--			, [PunkteSchwarz]			= 0.5
	--			, [Ergebnisbegruendung]		= 'Patt'

	--	END
	--END
END 
GO

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '070 - Prozedur [Spiel].[prcMoeglicheaktionenZusammenstellen] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO



/*
-- Test der Prozedur [Spiel].[prcMoeglicheaktionenZusammenstellen]

DECLARE @ASpielbrett		AS [dbo].[typStellung]
DECLARE @MoeglicheAktionen	AS [dbo].[typMoeglicheAktionen]

INSERT INTO @ASpielbrett
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
	WHERE 1 = 1
		AND [SpielID] = 1

INSERT @MoeglicheAktionen EXEC [Spiel].[prcMoeglicheaktionenZusammenstellen] @ASpielbrett, 1, 1, 1

SELECT * FROM @MoeglicheAktionen
GO
*/
-- truncate table [Spiel].[MoeglicheAktionen]
--close curTurmaktionen
--close curSpringeraktionen
--close curLaeuferaktionen
--close curDamenaktionen
