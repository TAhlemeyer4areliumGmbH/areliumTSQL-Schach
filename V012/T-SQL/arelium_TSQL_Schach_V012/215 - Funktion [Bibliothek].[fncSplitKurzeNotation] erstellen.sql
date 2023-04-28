-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Erstellung der Funktion [Bibliothek].[fncSplitKurzeNotation]                        ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### In den PGN-Dateien befinden sich Mitschriften von Grossmeisterpartien, die dieses   ###
-- ### Programm als Eroeffnungsbibliothek nutzen moechte. Hierzu muss die kurze Notation,  ###
-- ### die als ein langer String die gesamte Partie abbildet, aufgesplittet werden.        ###
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

CREATE OR ALTER FUNCTION [Bibliothek].[fncSplitKurzeNotation]
(
	  @StringKurzeNotation		AS VARCHAR(MAX)
	, @PartiemetadatenID		AS BIGINT
)
RETURNS @Split TABLE
	( 
		  [PartiemetadatenID]				BIGINT			NOT NULL
		, [VollzugID]					INTEGER			NOT NULL
		, [Weiss]						VARCHAR(20)		NOT NULL
		, [Schwarz]						VARCHAR(20)		NULL
	)
AS
BEGIN
	DECLARE @VollzugChar		AS VARCHAR(5)
	DECLARE @VollzugID			AS INTEGER
	DECLARE @Weiss				AS VARCHAR(20)
	DECLARE @Schwarz			AS VARCHAR(20)

	WHILE CHARINDEX('.', @StringKurzeNotation, 1) <> 0
	BEGIN
		SET @VollzugChar			= LEFT(@StringKurzeNotation, CHARINDEX('.', @StringKurzeNotation, 1) - 1)
		SET @VollzugID				= CONVERT(INTEGER, @VollzugChar)
		SET @StringKurzeNotation	= TRIM(RIGHT(@StringKurzeNotation, LEN(@StringKurzeNotation) - LEN(@VollzugChar) - 1))
		SET @Weiss					= LEFT(@StringKurzeNotation, CHARINDEX(' ', @StringKurzeNotation))
		SET @StringKurzeNotation	= TRIM(RIGHT(@StringKurzeNotation, LEN(TRIM(@StringKurzeNotation)) - LEN(@Weiss)))
		SET @Schwarz				=	CASE CHARINDEX(' ', @StringKurzeNotation)
											WHEN 0 THEN @StringKurzeNotation
											ELSE LEFT(@StringKurzeNotation, CHARINDEX(' ', @StringKurzeNotation))
										END
		SET @StringKurzeNotation	= TRIM(RIGHT(@StringKurzeNotation, LEN(TRIM(@StringKurzeNotation)) - LEN(@Schwarz)))

		INSERT INTO @Split
			( 
				  [PartiemetadatenID]
				, [VollzugID]
				, [Weiss]
				, [Schwarz]
			)
		VALUES
			(
				  @PartiemetadatenID
				, @VollzugID
				, @Weiss
				, @Schwarz
			)
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
DECLARE @Skript		VARCHAR(100)	= '215 - Funktion [Bibliothek].[fncSplitKurzeNotation] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO

/*
-- Test der Funktion [Bibliothek].[fncSplitKurzeNotation]

USE [arelium_TSQL_Schach_V012]
GO

SELECT * FROM [Bibliothek].[fncSplitKurzeNotation] (
   '1.e4 g6 2.d4 Bg7 3.f4 c5 4.dxc5 Qa5+ 5.Bd2 Qxc5 6.Bc3 Nf6 7.Qd4 Qc7 8.e5 Nc6 9.Qd3 Nh5'-- 10.Ne2 f5 11.Nd2 O-O 12.g3 b6 13.Bg2 Bb7 14.O-O Nd8 15.Rad1 Bxg216.Kxg2 Ne6 17.Nb3 Rfd8 18.Qd5 Kh8 19.Rd2 Bf8 20.Rfd1 Nhg7 21.a4 a6 22.h4 Qc623.a5 b5 24.Bb4 Qc4 25.c3 Rac8 26.Na1 Qc6 27.Nc2 Ne8 28.Ne3 N8c7 29.Qf3 Qxf3+30.Kxf3 Kg7 31.Rxd7 Kf7 32.Rxd8 Rxd8 33.Rxd8 Nxd8 34.Bc5 Nb7 35.Bb6 Na8 36.Nd5 Ke637.Nb4 Nxb6 38.axb6 Kd7 39.Nxa6 e6 40.Nd4 b4 41.cxb4 Nd8 42.Nc5+ Kc8 43.Ke3 Be744.Kd3 h6 45.Kc4 g5 46.hxg5 hxg5 47.Ndxe6')
   , 12342)
GO*/
