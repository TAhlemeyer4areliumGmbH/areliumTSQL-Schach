-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Moegliche Schlaege zusammenstellen                                                  ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Diese Funktion durchlaeuft alle Figuren eines Spielers und notiert die damit laut   ###
-- ### Spielregeln gueltig durchzufuehrenden Aktionen, die zu einem Schlag fuehren wuerde, ###
-- ### wenn auf dem Zielfeld eine gegenerische Figur stehen wuerde.                        ###
-- ###                                                                                     ###
-- ### Es werden alle Figurentypen per Cursor durchlaufen, da vorher nicht feststeht,      ###
-- ### wieveiel Figuren dieses Typs noch auf dem Brett stehen. Durch Bauernumwandlung      ###
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
-- ###     1.00.0	2023-02-21	Torsten Ahlemeyer                                          ###
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
CREATE OR ALTER FUNCTION [Spiel].[fncMoeglicheSchlaege]
(
	   @IstAngreifenderspielerWeiss		AS BIT
	 , @Bewertungsstellung				AS typStellung			READONLY
)
RETURNS @MoeglicheSchlaege TABLE 
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
		, [LangeNotation]    VARCHAR(20)		NULL
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
		DECLARE @LangeNotation		AS VARCHAR(7)
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
				AND [IstSpielerWeiss]	= @IstAngreifenderspielerWeiss
			ORDER BY [Feld];  

		OPEN curDamenaktionen
  
		FETCH NEXT FROM curDamenaktionen INTO @Damenfeld
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
			INSERT INTO @MoeglicheSchlaege
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
			FROM [Spiel].[fncMoeglicheDamenschlaege] (@IstAngreifenderspielerWeiss, @Bewertungsstellung, @Damenfeld)

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
				AND [IstSpielerWeiss]	= @IstAngreifenderspielerWeiss
			ORDER BY [Feld];  
  
		OPEN curTurmaktionen
  
		FETCH NEXT FROM curTurmaktionen INTO @Turmfeld
  
		WHILE @@FETCH_STATUS = 0  
		BEGIN 

			INSERT INTO @MoeglicheSchlaege
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
			FROM [Spiel].[fncMoeglicheTurmschlaege] (@IstAngreifenderspielerWeiss, @Bewertungsstellung, @Turmfeld)

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
				AND [IstSpielerWeiss]	= @IstAngreifenderspielerWeiss
			ORDER BY [Feld];  
  
		OPEN curLaeuferaktionen
  
		FETCH NEXT FROM curLaeuferaktionen INTO @Laeuferfeld
  
		WHILE @@FETCH_STATUS = 0  
		BEGIN 

			INSERT INTO @MoeglicheSchlaege
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
			FROM [Spiel].[fncMoeglicheLaeuferschlaege] (@IstAngreifenderspielerWeiss, @Bewertungsstellung, @Laeuferfeld)

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
				AND [IstSpielerWeiss]	= @IstAngreifenderspielerWeiss
			ORDER BY [Feld];  
  
		OPEN curSpringeraktionen
  
		FETCH NEXT FROM curSpringeraktionen INTO @Springerfeld
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
			INSERT INTO @MoeglicheSchlaege
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
			FROM [Spiel].[fncMoeglicheSpringerschlaege] (@IstAngreifenderspielerWeiss, @Bewertungsstellung, @Springerfeld)

			FETCH NEXT FROM curSpringeraktionen INTO @Springerfeld 
		END
		CLOSE curSpringeraktionen;  
		DEALLOCATE curSpringeraktionen; 

		---- --------------------------------------------------------------------------
		---- Koenig
		---- --------------------------------------------------------------------------

		-- Es ist nur genau ein farblich passender Koenig auf den Spielfeld. Eine Bauernumwandlung ist nicht zu beruecksichtigen.	
		SET @Koenigsfeld = (SELECT [Feld] FROM @Bewertungsstellung WHERE [FigurBuchstabe] = 'K' AND [IstSpielerWeiss] = @IstAngreifenderspielerWeiss)
		INSERT INTO @MoeglicheSchlaege
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
		FROM [Spiel].[fncMoeglicheKoenigsschlaege] (@IstAngreifenderspielerWeiss, @Bewertungsstellung, @Koenigsfeld)



		---- --------------------------------------------------------------------------
		---- Bauern
		---- --------------------------------------------------------------------------

		-- Es sind maximal 16 Bauern auf den Spielfeld. Eine Bauernumwandlung ist nicht zu beruecksichtigen.	
		DECLARE curBauernaktionen CURSOR FOR   
			SELECT DISTINCT [Feld]
			FROM @Bewertungsstellung
			WHERE 1 = 1
				AND [FigurBuchstabe]	= 'B'
				AND [IstSpielerWeiss]	= @IstAngreifenderspielerWeiss
			ORDER BY [Feld];  
  
		OPEN curBauernaktionen
  
		FETCH NEXT FROM curBauernaktionen INTO @Bauernfeld
  
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
			INSERT INTO @MoeglicheSchlaege
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
			FROM [Spiel].[fncMoeglicheBauernschlaege] (@IstAngreifenderspielerWeiss, @Bewertungsstellung, @Bauernfeld)

			FETCH NEXT FROM curBauernaktionen INTO @Bauernfeld 
		END
		CLOSE curBauernaktionen;  
		DEALLOCATE curBauernaktionen; 




		---- --------------------------------------------------------------------------
		---- illegale Zuege werden wieder rausgefiltert
		---- --------------------------------------------------------------------------

		-- es kann vorkommen, dass eine Rochade als "gueltiger" Koenigszug ermittelt 
		-- wird, auch wenn die Spielregeln in dieser Situation eine Rochade 
		-- eigentlich unterbinden. Dies liegt daran, dass die Rochade einer der 
		-- drei Zuege (die anderen sind "en passant" und die Bauerumwandlung) ist, 
		-- bei dem gleich zwei Figuren betroffen sind. Dies kann durch eine einfache 
		-- Anfrage gegen die Tabelle [Infrastruktur].[TheoretischeAktionen] nicht 
		-- sauber geprueft werden, da weitere Daten notwewndig sind. Somit sind 
		-- evtl. fehlerhaft erfasste Zugmoeglichkeiten wieder zu entfernen...

		-- Eine Rochade ist nur moeglich, wenn der Koenig an der "richtigen 
		-- Position steht
		DELETE FROM @MoeglicheSchlaege
		WHERE 1 = 1
			AND [LangeNotation] LIKE 'o-%'												-- gilt fuer lange und kurze Rochade


		-- es kann vorkommen, dass ein "en Passant"-Schlag als "gueltiger" Schlag ermittelt 
		-- wird, auch wenn die Spielregeln in dieser Situation einen "en Passant"-Schlag
		-- eigentlich unterbinden. Dies liegt daran, dass der "en Passant"-Schlag einer der 
		-- drei Zuege (die anderen sind Rochade und die Bauerumwandlung) ist, 
		-- bei dem gleich zwei Figuren betroffen sind. Dies kann durch eine einfache 
		-- Anfrage gegen die Tabelle [Infrastruktur].[TheoretischeAktionen] nicht 
		-- sauber geprueft werden, da weitere Daten notwewndig sind. Somit sind 
		-- evtl. fehlerhaft erfasste Zugmoeglichkeiten wieder zu entfernen...

		-- **** Noch zu implementieren! ****

	RETURN
	END 
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '059 - Funktion [Spiel].[fncMoeglicheSchlaege] erstellen.sql'
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


SELECT * FROM [Spiel].[fncMoeglicheSchlaege]('TRUE', @Bewertungsstellung)

GO
*/
