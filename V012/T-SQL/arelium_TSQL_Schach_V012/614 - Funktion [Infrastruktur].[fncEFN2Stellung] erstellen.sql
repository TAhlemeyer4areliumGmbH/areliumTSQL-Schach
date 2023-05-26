-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### wandeln eines EFN-Strings in eine tabellarische Stellung                            ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Es wird ein EFN-String eingelesen und die dort enhaltenen Informationen werden in   ###
-- ### eine konkrete Stellung ueberfuehrt. In dieser Funktion ist nur ein Teil des         ###
-- ### EFN-Strings relevant - die Notation enthaelt zusaetzlich auch weitere Meta-Angaben. ###
-- ### So kann man anhand der EFN-Notation auch beurteilen, ob ein "en passant"-Schlag als ###
-- ### naechste Aktion erlaubt ist, ob man noch das Recht zu einer langen/kurzen Rochade   ###
-- ### hat oder er am Zug ist.                                                             ###
-- ### Einzelheiten: https://www.embarc.de/fen-forsyth-edwards-notation/                   ###
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
 

CREATE OR ALTER FUNCTION [Infrastruktur].[fncEFN2Stellung]
	(
		  @EFN						AS VARCHAR(255)
	)
RETURNS @EFN2Stellung TABLE
	(
	  [Spalte]					CHAR(1)		NOT NULL						-- A-H
	, [Reihe]					INTEGER		NOT NULL						-- 1-8
	, [Feld]					INTEGER		NOT NULL						-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
	, [IstSpielerWeiss]			BIT			NULL							-- 1 = TRUE
	, [FigurBuchstabe]			CHAR(1)		NOT NULL						-- (L)aeufer, (S)pringer, (T)urm, (K)oenig, (D)ame, (B)auer / ? = leer
		CHECK ([FigurBuchstabe] IN (NULL, 'L', 'S', 'T', 'K', 'D'))
	, [FigurUTF8]				BIGINT		NOT NULL		
	)

BEGIN
	DECLARE @StellungsString		AS VARCHAR(64)
	DECLARE @Schleife				AS TINYINT
	DECLARE @Stringteil				AS VARCHAR(8)
	DECLARE @ID						AS TINYINT
	DECLARE @Zeichen				AS CHAR(1)

	-- --------------------------------------------------------------
	-- Schritt 1: mehrere leere Felder hintereinander aufloesen
	-- --------------------------------------------------------------

	-- aus dem EFN-String werden die Brettangaben extrahiert
	SET @EFN				= LEFT(@EFN, CHARINDEX(' ', @EFN))
	SET @EFN				= TRIM(@EFN)
	SET @EFN				= REPLACE(@EFN, '/', '')
	SET @EFN				= REPLACE(@EFN, '1', '?')
	SET @EFN				= REPLACE(@EFN, '2', '??')
	SET @EFN				= REPLACE(@EFN, '3', '???')
	SET @EFN				= REPLACE(@EFN, '4', '????')
	SET @EFN				= REPLACE(@EFN, '5', '?????')
	SET @EFN				= REPLACE(@EFN, '6', '??????')
	SET @EFN				= REPLACE(@EFN, '7', '???????')
	SET @EFN				= REPLACE(@EFN, '8', '????????')

	-- --------------------------------------------------------------
	-- Schritt 2: Positionsangaben der Figuren auswerten
	-- --------------------------------------------------------------
	SET @Schleife = 1

	WHILE @Schleife <= 64
	BEGIN

		INSERT INTO @EFN2Stellung
			( [Spalte]
			, [Reihe]
			, [Feld]
			, [IstSpielerWeiss]
			, [FigurBuchstabe]
			, [FigurUTF8])
		 VALUES
			( CHAR(64 + (((@Schleife - 1) % 8) + 1))
			, ((65 - @Schleife + 7) / 8)
			, ((((65 - @Schleife + 7) / 8) - 1) * 8) + (((@Schleife - 1) % 8) + 1)
			, (SELECT
				CASE SUBSTRING(@EFN, @Schleife, 1)
					WHEN 'r' COLLATE Latin1_General_CS_AI THEN 'FALSE'
					WHEN 'R' COLLATE Latin1_General_CS_AI THEN 'TRUE'
					WHEN 'n' COLLATE Latin1_General_CS_AI THEN 'FALSE'
					WHEN 'N' COLLATE Latin1_General_CS_AI THEN 'TRUE'
					WHEN 'b' COLLATE Latin1_General_CS_AI THEN 'FALSE'
					WHEN 'B' COLLATE Latin1_General_CS_AI THEN 'TRUE'
					WHEN 'q' COLLATE Latin1_General_CS_AI THEN 'FALSE'
					WHEN 'Q' COLLATE Latin1_General_CS_AI THEN 'TRUE'
					WHEN 'k' COLLATE Latin1_General_CS_AI THEN 'FALSE'
					WHEN 'K' COLLATE Latin1_General_CS_AI THEN 'TRUE'
					WHEN 'p' COLLATE Latin1_General_CS_AI THEN 'FALSE'
					WHEN 'P' COLLATE Latin1_General_CS_AI THEN 'TRUE'
					ELSE NULL
				END
				)
			, (SELECT
				CASE SUBSTRING(@EFN, @Schleife, 1)
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
					ELSE '?'
				END
				)
			, (SELECT	
				CASE SUBSTRING(@EFN, @Schleife, 1)
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
					ELSE 160
				END
				)
			)

		-- Reihe:		((65 - @Schleife + 7) / 8)
		-- Spalte:		CHAR(64 + (((@Schleife - 1) % 8) + 1))
		-- Feld:		((((65 - @Schleife + 7) / 8) - 1) * 8) + (((@Schleife - 1) % 8) + 1)

		SET @Schleife = @Schleife + 1
	END

	RETURN
END
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '614 - Funktion [Infrastruktur].[fncEFN2Stellung] erstellen.sql'
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

SET @EFN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
--SET @EFN = '6r1/6pp/7r/1B5K/1P3k2/N7/3R4/8 w - - 30 79'

SELECT * FROM [Infrastruktur].[fncEFN2Stellung](@EFN)
GO

*/
 