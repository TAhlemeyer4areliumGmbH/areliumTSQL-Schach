-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Importieren einer Stellung ueber die EFN-Notation                                   ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Es wird ein EFN-String eingelesen und die dort enhaltenen Informationen werden in   ###
-- ### eine konkrete Stellung ueberfuehrt. Die EFN Notation enthaelt dabei nicht nur die   ###
-- ### Positionen der einzelnen Figuren sondern auch weitere Meta-Angaben. So kann man     ###
-- ### anhand der EFN-Notation auch beurteilen, ob ein "en passant"-Schlag als naechste    ###
-- ### Aktion erlaubt ist, ob man noch das Recht zu einer langen/kurzen Rochade hat oder   ###
-- ### er am Zug ist. Einzelheiten: https://www.embarc.de/fen-forsyth-edwards-notation/    ###
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

-- -----------------------------------------------------------------------------------------
-- Aufbauarbeiten
-- -----------------------------------------------------------------------------------------
 

CREATE OR ALTER PROCEDURE [Infrastruktur].[prcImportEFN]
	  @EFN								AS VARCHAR(255)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @StellungsString		AS VARCHAR(64)
	DECLARE @Schleife				AS TINYINT
	DECLARE @Stringteil				AS VARCHAR(8)
	DECLARE @ID						AS TINYINT
	DECLARE @Zeichen				AS CHAR(1)
	DECLARE @IstSpielerWeiss		AS BIT
	DECLARE @EnPassantFeld			AS TINYINT
	DECLARE @FuenfzigZuegeRegel		AS TINYINT
	DECLARE @Zugzahl				AS INTEGER

	-- --------------------------------------------------------------
	-- Schritt 1: 8 Reihen im EFN-String 
	-- --------------------------------------------------------------

	-- aus dem EFN-String werden die Brettangaben extrahiert
	SET @StellungsString	= LEFT(@EFN, CHARINDEX(' ', @EFN))
	SET @EFN				= TRIM(RIGHT(@EFN, LEN(@EFN) - LEN(@StellungsString)))

	-- Brett mit Grundtsellung aufbauen
	EXECUTE [Spiel].[prcInitialisierung] 
		@NameWeiss							= 'WEISS'
	  , @NameSchwarz						= 'SCHWARZ'
	  , @IstSpielerMenschWeiss				= 'TRUE'
	  , @IstSpielerMenschSchwarz			= 'TRUE'
	  , @SpielstaerkeWeiss					= 2
	  , @SpielstaerkeSchwarz				= 2
	  , @RestzeitWeissInSekunden			= 5400
	  , @RestzeitSchwarzInSekunden			= 7200
	  , @ComputerSchritteAnzeigenWeiss		= 'TRUE'
	  , @ComputerSchritteAnzeigenSchwarz	= 'FALSE'
	  , @BedienungsanleitungAnzeigen		= 'FALSE'

	
	-- ueber die SPLIT-Funktion werden die Reihen aufgeteilt
	SELECT 
		  9 - ROW_NUMBER() OVER (ORDER BY GETDATE()) AS [ID]
		, [Value]
	INTO #TempStellung
	FROM STRING_SPLIT(@StellungsString, '/');


	-- --------------------------------------------------------------
	-- Schritt 2: 8 Felder je Reihe
	-- --------------------------------------------------------------

	CREATE TABLE #TempStellung2([ID] TINYINT NOT NULL, [Stellung] [VARCHAR](8) NOT NULL) 

	DECLARE curEFN CURSOR FOR   
		SELECT [ID], [Value]
		FROM #TempStellung
		ORDER BY [ID] DESC;  

	OPEN curEFN
  
	FETCH NEXT FROM curEFN INTO @ID, @Stringteil
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		SET @StellungsString	= ''
		SET @Schleife			= 1
		WHILE @Schleife <= 8
		BEGIN
			SET @Zeichen			= SUBSTRING(@Stringteil, 1, 1)

			IF ISNUMERIC(@Zeichen) = 1
			BEGIN
				SET @StellungsString	= @StellungsString + REPLICATE('$', CONVERT(TINYINT, @Zeichen))
				SET @Schleife			= @Schleife + CONVERT(TINYINT, @Zeichen) 
			END
			ELSE
			BEGIN
				SET @StellungsString	= @StellungsString + @Zeichen
				SET @Schleife			= @Schleife + 1
			END

			SET @Stringteil = RIGHT(@Stringteil, LEN(@Stringteil) - 1)

		END		

		INSERT INTO #TempStellung2([ID], [Stellung])
		SELECT @ID, @StellungsString

		FETCH NEXT FROM curEFN INTO @ID, @Stringteil
	END
	CLOSE curEFN;  
	DEALLOCATE curEFN; 


	-- --------------------------------------------------------------
	-- Schritt 3: Positionsangaben der Figuren auswerten
	-- --------------------------------------------------------------

	-- Jetzt werden die Angaben aus dem EFN-String in UPDATE-Statements gewandelt
	DECLARE curImoprt CURSOR FOR   
		SELECT [ID], [Stellung]
		FROM #TempStellung2
		ORDER BY [ID] DESC;  

	OPEN curImoprt
  
	FETCH NEXT FROM curImoprt INTO @ID, @Stringteil
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		SET @StellungsString	= ''
		SET @Schleife			= 1
		WHILE @Schleife <= 8
		BEGIN
			SET @Zeichen			= LEFT(@Stringteil, 1)

			IF @Zeichen = '$'
			BEGIN
				SET @IstSpielerWeiss = NULL
			END
			ELSE
			BEGIN
				IF @Zeichen <> @Zeichen COLLATE Latin1_General_CS_AI
				BEGIN
					SET @IstSpielerWeiss = 'TRUE'
				END
				ELSE
				BEGIN
					SET @IstSpielerWeiss = 'FALSE'
				END
			END

			UPDATE [Infrastruktur].[Spielbrett]
			SET	  [IstSpielerWeiss]		= @IstSpielerWeiss
				, [FigurBuchstabe]		= (SELECT	CASE @Zeichen
														WHEN '$' COLLATE Latin1_General_CS_AI THEN '?'
														WHEN 'r' COLLATE Latin1_General_CS_AI THEN 'T'
														WHEN 'R' COLLATE Latin1_General_CS_AI THEN 'T'
														WHEN 'n' COLLATE Latin1_General_CS_AI THEN 'S'
														WHEN 'N' COLLATE Latin1_General_CS_AI THEN 'S'
														WHEN 'b' COLLATE Latin1_General_CS_AI THEN 'L'
														WHEN 'B' COLLATE Latin1_General_CS_AI THEN 'L'
														WHEN 'q' COLLATE Latin1_General_CS_AI THEN 'D'
														WHEN 'Q' COLLATE Latin1_General_CS_AI THEN 'D'
														WHEN 'k' COLLATE Latin1_General_CS_AI THEN 'K'
														WHEN 'K' COLLATE Latin1_General_CS_AI THEN 'K'
														WHEN 'p' COLLATE Latin1_General_CS_AI THEN 'B'
														WHEN 'P' COLLATE Latin1_General_CS_AI THEN 'B'
													END
											)
				, [FigurUTF8]			= (SELECT	CASE @Zeichen
														WHEN '$' COLLATE Latin1_General_CS_AI THEN 160
														WHEN 'r' COLLATE Latin1_General_CS_AI THEN 9820
														WHEN 'R' COLLATE Latin1_General_CS_AI THEN 9814
														WHEN 'n' COLLATE Latin1_General_CS_AI THEN 9822
														WHEN 'N' COLLATE Latin1_General_CS_AI THEN 9816
														WHEN 'b' COLLATE Latin1_General_CS_AI THEN 9821
														WHEN 'B' COLLATE Latin1_General_CS_AI THEN 9815
														WHEN 'q' COLLATE Latin1_General_CS_AI THEN 9819
														WHEN 'Q' COLLATE Latin1_General_CS_AI THEN 9813
														WHEN 'k' COLLATE Latin1_General_CS_AI THEN 9818
														WHEN 'K' COLLATE Latin1_General_CS_AI THEN 9812
														WHEN 'p' COLLATE Latin1_General_CS_AI THEN 9823
														WHEN 'P' COLLATE Latin1_General_CS_AI THEN 9817
													END
											)
			WHERE [Feld] = (@Schleife - 1) * 8 + @ID
			SET @Schleife			= @Schleife + 1
			SET @Stringteil = RIGHT(@Stringteil, LEN(@Stringteil) - 1)

		END		

		INSERT INTO #TempStellung2([ID], [Stellung])
		SELECT @ID, @StellungsString

		FETCH NEXT FROM curImoprt INTO @ID, @Stringteil
	END
	CLOSE curImoprt;  
	DEALLOCATE curImoprt; 
	
	DROP TABLE #TempStellung
	DROP TABLE #TempStellung2

	-- --------------------------------------------------------------
	-- Schritt 4: Notation und damit das Zugrecht anpassen
	-- --------------------------------------------------------------

	INSERT INTO [Spiel].[Notation]
        ([VollzugID]
        ,[IstSpielerWeiss]
        ,[TheoretischeAktionenID]
        ,[LangeNotation]
        ,[KurzeNotationEinfach]
        ,[KurzeNotationKomplex]
        ,[ZugIstSchachgebot])
	VALUES
        (0, 1, (SELECT MIN([TheoretischeAktionenID]) FROM [Infrastruktur].[TheoretischeAktionen]), 'EFN', 'EFN', 'EFN', 'FALSE')

	IF LEFT(@EFN, 1) = 'w'
	BEGIN
		INSERT INTO [Spiel].[Notation]
           ([VollzugID]
           ,[IstSpielerWeiss]
           ,[TheoretischeAktionenID]
           ,[LangeNotation]
           ,[KurzeNotationEinfach]
           ,[KurzeNotationKomplex]
           ,[ZugIstSchachgebot])
		VALUES
           (0, 0, (SELECT MIN([TheoretischeAktionenID]) FROM [Infrastruktur].[TheoretischeAktionen]), 'EFN', 'EFN', 'EFN', 'FALSE')
	END

	-- --------------------------------------------------------------
	-- Schritt 5: Rochaderecht beachten
	-- --------------------------------------------------------------

	SET @EFN			= RIGHT(@EFN, LEN(@EFN) - 2)
	SET @Stringteil		= TRIM(LEFT(@EFN, CHARINDEX(' ', @EFN, 1)))
	SET @EFN			= RIGHT(@EFN, LEN(@EFN) - CHARINDEX(' ', @EFN, 1))

	UPDATE [Spiel].[Konfiguration]
	SET   [IstKurzeRochadeErlaubt] = 'FALSE'
		, [IstLangeRochadeErlaubt] = 'FALSE'

	IF CHARINDEX('k' COLLATE Latin1_General_CS_AI, @Stringteil, 1) <> 0
	BEGIN
		UPDATE [Spiel].[Konfiguration]
		SET   [IstKurzeRochadeErlaubt]	= 'TRUE'
		WHERE [IstSpielerWeiss]			= 'FALSE'
	END

	IF CHARINDEX('K' COLLATE Latin1_General_CS_AI, @Stringteil, 1) <> 0
	BEGIN
		UPDATE [Spiel].[Konfiguration]
		SET   [IstKurzeRochadeErlaubt]	= 'TRUE'
		WHERE [IstSpielerWeiss]			= 'TRUE'
	END

	IF CHARINDEX('q' COLLATE Latin1_General_CS_AI, @Stringteil, 1) <> 0
	BEGIN
		UPDATE [Spiel].[Konfiguration]
		SET   [IstLangeRochadeErlaubt]	= 'TRUE'
		WHERE [IstSpielerWeiss]			= 'FALSE'
	END

	IF CHARINDEX('Q' COLLATE Latin1_General_CS_AI, @Stringteil, 1) <> 0
	BEGIN
		UPDATE [Spiel].[Konfiguration]
		SET   [IstLangeRochadeErlaubt]	= 'TRUE'
		WHERE [IstSpielerWeiss]			= 'TRUE'
	END
	
	-- --------------------------------------------------------------
	-- Schritt 6: en-passant beachten
	---- --------------------------------------------------------------

	SET @Stringteil		= TRIM(LEFT(@EFN, CHARINDEX(' ', @EFN, 1)))
	SET @EFN			= RIGHT(@EFN, LEN(@EFN) - CHARINDEX(' ', @EFN, 1))

	IF @Stringteil = '-'
	BEGIN
		SET @EnPassantFeld = NULL
	END
	ELSE
	BEGIN
		SET @EnPassantFeld = (	SELECT [Feld]
								FROM [Infrastruktur].[Spielbrett]
								WHERE 1 = 1
									AND [Spalte]	= LEFT(@Stringteil, 1)
									AND [Reihe]		= RIGHT(@Stringteil, 1)
							)
	END
	
	-- --------------------------------------------------------------
	-- Schritt 7: 50-Zuege-Regel
	---- --------------------------------------------------------------

	SET @Stringteil		= TRIM(LEFT(@EFN, CHARINDEX(' ', @EFN, 1)))
	SET @EFN			= RIGHT(@EFN, LEN(@EFN) - CHARINDEX(' ', @EFN, 1))

	SET @FuenfzigZuegeRegel = CONVERT(TINYINT, @Stringteil)
	
	-- --------------------------------------------------------------
	-- Schritt 8: Zugzahl
	---- --------------------------------------------------------------

	SET @Stringteil		= TRIM(LEFT(@EFN, CHARINDEX(' ', @EFN, 1)))

	SET @Zugzahl		= CONVERT(INTEGER, @Stringteil)

	SELECT @Zugzahl
	SELECT * FROM [Infrastruktur].[vSpielbrett]
	SELECT @EFN
	SELECT @Stringteil

END
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '610 - Prozedur [Infrastruktur].[prcImportEFN] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO


/*

USE [arelium_TSQL_Schach_V012]
GO

DECLARE @EFN varchar(255)

--SET @EFN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
SET @EFN = '6r1/6pp/7r/1B5K/1P3k2/N7/3R4/8 w - - 30 79'

EXECUTE [Infrastruktur].[prcImportEFN] @EFN
GO

*/
 