-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Erstellung der Funktion [Infrastruktur].[fncStellungIstSchach]                      ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Diese Funktion prueft, ob in der vorgegebene Stellung ein Schachgebot vorliegt. Es  ###
-- ### wird in einer Tabellenwertvariablen die aktuelle Stellung und separat die           ###
-- ### Information, welcher Spieler gerade aktiv ist, uebergeben...                        ###
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
-- ###     1.00.0	2023-02-17	Torsten Ahlemeyer                                          ###
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

-- ######################################################################################
-- ###  Erstellung der Funktion [Infrastruktur].[fncStellungIstSchach]                ###
-- ######################################################################################

CREATE OR ALTER FUNCTION [Infrastruktur].[fncStellungIstSchach] 
(
	  @Bewertungsstellung			AS [dbo].[typStellung] READONLY
	, @IstAngreifenderspielerWeiss	AS BIT
)
RETURNS BIT
AS
BEGIN
	DECLARE @Ergebnis		AS BIT
	DECLARE @Koenigsfeld	AS TINYINT
	DECLARE @Damenfeld		AS INTEGER
	DECLARE @Turmfeld		AS INTEGER
	DECLARE @Springerfeld	AS INTEGER
	DECLARE @Laeuferfeld	AS INTEGER
	DECLARE @Bauernfeld		AS INTEGER

	SET @Koenigsfeld = (SELECT [Feld] FROM @Bewertungsstellung WHERE [IstSpielerWeiss] <> @IstAngreifenderspielerWeiss AND [FigurBuchstabe] = 'K')
	SET @Ergebnis = 'FALSE'

	---- --------------------------------------------------------------------------
	---- Damen
	---- --------------------------------------------------------------------------

	-- Es werden alle auf dem Brett befindlichen Damen ermittelt. Fuer jede so gefundene Dame werden nun alle 
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
		IF EXISTS
			(
				SELECT [TheoretischeAktionenID], 1, [FigurName], [IstSpielerWeiss], [StartSpalte],
					[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
					[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
					[ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex] 
				FROM [Spiel].[fncMoeglicheDamenschlaege] (@IstAngreifenderspielerWeiss, @Bewertungsstellung, @Damenfeld)
				WHERE [ZielFeld] = @Koenigsfeld
			)
		BEGIN
			SET @Ergebnis = 'TRUE'
		END

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
	IF @Ergebnis = 'FALSE'
	BEGIN
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
			IF EXISTS
				(
					SELECT [TheoretischeAktionenID], 1, [FigurName], [IstSpielerWeiss], [StartSpalte],
						[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
						[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
						[ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex] 
					FROM [Spiel].[fncMoeglicheTurmschlaege] (@IstAngreifenderspielerWeiss, @Bewertungsstellung, @Turmfeld)
					WHERE [ZielFeld] = @Koenigsfeld
				)
			BEGIN
				SET @Ergebnis = 'TRUE'
			END

			FETCH NEXT FROM curTurmaktionen INTO @Turmfeld 
		END
		CLOSE curTurmaktionen;  
		DEALLOCATE curTurmaktionen; 
	END


	---- --------------------------------------------------------------------------
	---- Laeufer
	---- --------------------------------------------------------------------------

	-- Es werden alle auf dem Brett befindlichen Laeufer ermittelt. fuer jeden so gefundenen Laeufer werden nun alle 
	-- denkbaren und regelkonforme Aktionen notiert. Somit ist selbst nach mehrfacher Bauernumwandlung jeder Laeufer
	-- beruecksichtigt.	
	IF @Ergebnis = 'FALSE'
	BEGIN
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
			IF EXISTS
				(
					SELECT [TheoretischeAktionenID], 1, [FigurName], [IstSpielerWeiss], [StartSpalte],
						[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
						[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
						[ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex] 
					FROM [Spiel].[fncMoeglicheLaeuferschlaege] (@IstAngreifenderspielerWeiss, @Bewertungsstellung, @Laeuferfeld)
					WHERE [ZielFeld] = @Koenigsfeld
				)
			BEGIN
				SET @Ergebnis = 'TRUE'
			END

			FETCH NEXT FROM curLaeuferaktionen INTO @Laeuferfeld 
		END
		CLOSE curLaeuferaktionen;  
		DEALLOCATE curLaeuferaktionen; 
	END

	-- --------------------------------------------------------------------------
	-- Springer
	-- --------------------------------------------------------------------------

	-- Es werden alle auf dem Brett befindlichen Springer ermittelt. fuer jeden so gefundenen Springer werden nun alle 
	-- denkbaren und regelkonforme Aktionen notiert. Somit ist selbst nach mehrfacher Bauernumwandlung jeder Springer
	-- beruecksichtigt.	
	IF @Ergebnis = 'FALSE'
	BEGIN
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
			IF EXISTS
				(
					SELECT [TheoretischeAktionenID], 1, [FigurName], [IstSpielerWeiss], [StartSpalte],
						[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
						[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
						[ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex] 
					FROM [Spiel].[fncMoeglicheSpringerschlaege] (@IstAngreifenderspielerWeiss, @Bewertungsstellung, @Springerfeld)
					WHERE [ZielFeld] = @Koenigsfeld
				)
			BEGIN
				SET @Ergebnis = 'TRUE'
			END

			FETCH NEXT FROM curSpringeraktionen INTO @Springerfeld 
		END
		CLOSE curSpringeraktionen;  
		DEALLOCATE curSpringeraktionen; 
	END

	---- --------------------------------------------------------------------------
	---- Bauern
	---- --------------------------------------------------------------------------

	-- Es sind maximal 16 Bauern auf den Spielfeld. Eine Bauernumwandlung ist nicht zu beruecksichtigen.	
	IF @Ergebnis = 'FALSE'
	BEGIN
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
			IF EXISTS
				(
					SELECT [TheoretischeAktionenID], 1, [FigurName], [IstSpielerWeiss], [StartSpalte],
						[StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung],
						[UmwandlungsfigurBuchstabe], [ZugIstSchlag], [ZugIstKurzeRochade], [ZugIstLangeRochade],
						[ZugIstEnPassant], [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex] 
					FROM [Spiel].[fncMoeglicheBauernschlaege] (@IstAngreifenderspielerWeiss, @Bewertungsstellung, @Bauernfeld)
					WHERE [ZielFeld] = @Koenigsfeld
				)
			BEGIN
				SET @Ergebnis = 'TRUE'
			END

			FETCH NEXT FROM curBauernaktionen INTO @Bauernfeld 
		END
		CLOSE curBauernaktionen;  
		DEALLOCATE curBauernaktionen; 
	END

	RETURN @Ergebnis
	END
GO



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '121 - Funktion [Infrastruktur].[fncStellungIstSchach] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO
/*
-- Test der Funktion [Infrastruktur].[fncStellungIstSchach]
USE [arelium_TSQL_Schach_V012]

DECLARE @ASpielbrett	AS [dbo].[typStellung]
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

SELECT [Infrastruktur].[fncStellungIstSchach] (@ASpielbrett, 'TRUE')
GO
*/
