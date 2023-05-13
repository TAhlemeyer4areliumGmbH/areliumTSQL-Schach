-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Exportieren einer Stellung in die EFN-Notation                                      ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Es gilt ein EFN-String aus einer uebergebenen Stellung zu generieren. Diser soll    ###
-- ### entsprechend dem Protokoll alle notwendigen Informationen ueber alle Figuren und    ###
-- ### ihrer Platzierung sowie ihre´Farbe beinhalten. Ausserdem werden Angaben zu den noch ###
-- ### moeglichen Rochaden erwartet. Auch die Information, ob in dieser Stellung aktuell   ###
-- ### ein "en passant"-Schlag moeglich ist, ist genauso zu geben wie der Zaehler fuer die ###
-- ### 50-Zuege-Regel. Abschliessend wird mitgeteilt, welche Zugnummer als naechstes       ###
-- ### kommt. Einzelheiten unter https://www.embarc.de/fen-forsyth-edwards-notation/       ###
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
CREATE OR ALTER FUNCTION [Infrastruktur].[fncStellung2EFN]
(
	  @IstSpielerWeiss				AS BIT
	, @MoeglicheRochaden			AS VARCHAR(4)
	, @WoIstEnPassantMoeglich		AS CHAR(2)
	, @NaechsteZugNummer			AS INTEGER
	, @Bewertungsstellung			AS typStellung			READONLY
)
RETURNS VARCHAR(256)
AS
BEGIN
	DECLARE @Rueckgabewert			AS VARCHAR(256)
	DECLARE @Reihe					AS VARCHAR(8)
	DECLARE @Spaltenzaehler			AS CHAR(1)
	DECLARE @Reihenzaehler			AS TINYINT

	-- --------------------------------------------------------------------------
	-- Schritt 1: 
	-- je Reihe alle Felder umkonvertieren, hintereinanderhängen und dann
	-- alle Reihen mit "/" getrennt aneinanderfuegen
	-- --------------------------------------------------------------------------
	SET @Reihenzaehler		= 1
	SEt @Rueckgabewert		= ''
	SET @Reihe				= ''

	WHILE @Reihenzaehler <= 8
	BEGIN
		SET @Reihe = ''
		SET @Spaltenzaehler		= 'A'
		WHILE @Spaltenzaehler <= 'H'
		BEGIN
			SET @Reihe = @Reihe + 
			(
				SELECT 
					CASE [IstSpielerWeiss]
						WHEN 1 THEN	
							CASE [FigurBuchstabe]
								WHEN 'B'	THEN 'P'
								WHEN 'T'	THEN 'R'
								WHEN 'S'	THEN 'N'
								WHEN 'L'	THEN 'B'
								WHEN 'D'	THEN 'Q'
								WHEN 'K'	THEN 'K'
								ELSE '?'
							END
						WHEN 0 THEN
							CASE [FigurBuchstabe]
								WHEN 'B'	THEN 'p'
								WHEN 'T'	THEN 'r'
								WHEN 'S'	THEN 'n'
								WHEN 'L'	THEN 'b'
								WHEN 'D'	THEN 'q'
								WHEN 'K'	THEN 'k'
								ELSE '?'
							END
						ELSE  -- kann auch NULL sein!
							'?'
					END
				FROM @Bewertungsstellung
				WHERE 1 = 1
					AND [Reihe]		= @Reihenzaehler
					AND [Spalte]	= @Spaltenzaehler
			)
			
			SET @Spaltenzaehler = CHAR(ASCII(@Spaltenzaehler) + 1)
		END
		SET @Rueckgabewert = @Rueckgabewert + @Reihe + '/'
		SET @Reihenzaehler = @Reihenzaehler + 1
	END

	-- --------------------------------------------------------------------------
	-- Schritt 2: 
	-- mehrfach hintereinander vorkommende Leerfelder durch ihre Anzahl ersetzen.
	-- --------------------------------------------------------------------------

	-- das letzte Trennzeichen wieder entfernen
	SET @Rueckgabewert = LEFT(@Rueckgabewert, LEN(@Rueckgabewert) - 1)

	SET @Rueckgabewert = 
		REPLACE(
			REPLACE(
				REPLACE(
					REPLACE(
						REPLACE(
							REPLACE(
								REPLACE(
									REPLACE(@Rueckgabewert, '????????', 8)
								, '???????', 7)
							, '??????', 6)
						, '?????', 5)
					, '????', 4)
				, '???', 3)
			, '??', 2)
		, '?', 1)

	-- --------------------------------------------------------------------------
	-- Schritt 3: 
	-- Die weiteren Metaangaben in der richtigen Reihenfolge anhaengen. Falls 
	-- nicht angegeben wurden, ist ein "-" zu notieren
	-- --------------------------------------------------------------------------

	SET @Rueckgabewert = @Rueckgabewert + ' ' + CASE @IstSpielerWeiss WHEN 'TRUE' THEN 'w' ELSE 'b' END
	SET @Rueckgabewert = @Rueckgabewert + ' ' + CASE @MoeglicheRochaden WHEN NULL THEN '-' ELSE @MoeglicheRochaden END
	SET @Rueckgabewert = @Rueckgabewert + ' ' + CASE @WoIstEnPassantMoeglich WHEN NULL THEN '-' ELSE @WoIstEnPassantMoeglich END
	SET @Rueckgabewert = @Rueckgabewert + ' ' + CONVERT(VARCHAR(5), @NaechsteZugNummer)

	RETURN @Rueckgabewert
END
GO			



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '612 - Funktion [Infrastruktur].[fncStellung2EFN] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO

/*
-- Test der Funktion [Spiel].[fncMoeglicheBauernaktionen]

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

SELECT [Infrastruktur].[fncStellung2EFN] 
	('TRUE', 'kKq', 'a3', 3, @ASpielbrett)
GO
*/
