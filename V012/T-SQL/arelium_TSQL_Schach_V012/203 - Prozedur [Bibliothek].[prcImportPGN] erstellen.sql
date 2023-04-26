-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Bulk Insert CSV-PNG-Datei                                                           ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Von der Festplatte wird eine Datei im PGN-Format (dies ist eine Textdatei)          ###
-- ### in einem mehrstufigen Verfahren eingelesen. http://www.pgnmentor.com/files.html     ###
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
 

CREATE OR ALTER PROCEDURE [Bibliothek].[prcImportPGN]
	  @KompletterDateiAblagepfad		AS VARCHAR(255)
	, @MaxZaehler						AS INTEGER
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQL						AS VARCHAR(MAX)
	DECLARE @Obergrenze					AS INTEGER
	DECLARE @Untergrenze				AS INTEGER
	DECLARE @Zaehler					AS INTEGER					-- Schleife fuer die einzulesenden Datensätze
	DECLARE @Schleifenzaehler			AS INTEGER					-- Schleife fuer die Notationszeilen
	DECLARE @Notationszeile				AS VARCHAR(MAX)

	DECLARE @Quelle						AS NVARCHAR(50)
	DECLARE @Veranstaltung				AS NVARCHAR(50)
	DECLARE @Seite						AS NVARCHAR(50)
	DECLARE @Veranstaltungsdatum		AS NVARCHAR(50)
	DECLARE @Runde						AS NVARCHAR(50)
	DECLARE @Weiss						AS NVARCHAR(50)
	DECLARE @Schwarz					AS NVARCHAR(50)
	DECLARE @Ergebnis					AS NVARCHAR(50)
	DECLARE @EloWertWeiss				AS NVARCHAR(50)
	DECLARE @EloWertSchwarz				AS NVARCHAR(50)
	DECLARE @ECO						AS NVARCHAR(30)

	TRUNCATE TABLE [Infrastruktur].[PNG_Stufe1]
	TRUNCATE TABLE [Infrastruktur].[PNG_Stufe2]

	SET @SQL = 'BULK INSERT [Infrastruktur].[PNG_Stufe1] FROM ''' 
		+ @KompletterDateiAblagepfad 
		+ ''' WITH (FIELDTERMINATOR = '','', ROWTERMINATOR = ''\n'')'
	PRINT @SQL
	EXEC(@SQL)
	
	INSERT INTO [Infrastruktur].[PNG_Stufe2]
	SELECT 
		ROW_NUMBER() OVER (ORDER BY GETDATE()) AS [ZeilenNr]
		, [GanzeZeile]
	FROM [Infrastruktur].[PNG_Stufe1]
	WHERE 1 = 1
		AND [GanzeZeile] IS NOT NULL

	-- Den Beginn des zweiten Blocks ermitteln. Es ist das zweite Vorkommen des 
	-- EVENT-Eintrages
	SET @Obergrenze = (	SELECT TOP 1
							[ZeilenNr]
						FROM [Infrastruktur].[PNG_Stufe2]
						WHERE 1 = 1
							AND [GanzeZeile] LIKE '%Event%'
							AND [ZeilenNr] > 1
						ORDER BY [ZeilenNr]
						)

	-- Den Beginn des ersten Notationsblocks ermitteln. Es ist das erste Vorkommen  
	-- nach dem ECO-Eintrages
	SET @Untergrenze = (SELECT TOP 1
							[ZeilenNr] 
						FROM [Infrastruktur].[PNG_Stufe2]
						WHERE 1 = 1
							AND [GanzeZeile] LIKE '%ECO%'
						ORDER BY [ZeilenNr] ASC
						)

	SET @Zaehler		= 1

	WHILE ((SELECT COUNT(*) FROM [Infrastruktur].[PNG_Stufe2] WHERE [GanzeZeile] LIKE '%White%') > 1) AND (@Zaehler <= @MaxZaehler)
	BEGIN

		SET @Schleifenzaehler		= @Untergrenze + 1
		SET @Notationszeile			= ''

		WHILE @Schleifenzaehler <= @Obergrenze
		BEGIN
			SET @Notationszeile = @Notationszeile + 
				(	SELECT [GanzeZeile]
					FROM [Infrastruktur].[PNG_Stufe2]
					WHERE 1 = 1
						AND [ZeilenNr] = @Schleifenzaehler
				)
			SET @Schleifenzaehler = @Schleifenzaehler + 1
		END

		SET @Quelle					= (SELECT RIGHT(@KompletterDateiAblagepfad, CHARINDEX('\', REVERSE(@KompletterDateiAblagepfad),1) - 1))
		SET @Seite					= (SELECT TOP (1) [GanzeZeile] FROM [Infrastruktur].[PNG_Stufe2] WHERE [ZeilenNr] < @Obergrenze AND [GanzeZeile] LIKE '%Site%'		ORDER BY [ZeilenNr] ASC)
		SET @Veranstaltungsdatum	= (SELECT TOP (1) [GanzeZeile] FROM [Infrastruktur].[PNG_Stufe2] WHERE [ZeilenNr] < @Obergrenze AND [GanzeZeile] LIKE '%Date%'		ORDER BY [ZeilenNr] ASC)
		SET @Runde					= (SELECT TOP (1) [GanzeZeile] FROM [Infrastruktur].[PNG_Stufe2] WHERE [ZeilenNr] < @Obergrenze AND [GanzeZeile] LIKE '%Round%'		ORDER BY [ZeilenNr] ASC)
		SET @Weiss					= (SELECT TOP (1) [GanzeZeile] FROM [Infrastruktur].[PNG_Stufe2] WHERE [ZeilenNr] < @Obergrenze AND [GanzeZeile] LIKE '%White%'		ORDER BY [ZeilenNr] ASC)
		SET @Schwarz				= (SELECT TOP (1) [GanzeZeile] FROM [Infrastruktur].[PNG_Stufe2] WHERE [ZeilenNr] < @Obergrenze AND [GanzeZeile] LIKE '%Black%'		ORDER BY [ZeilenNr] ASC)
		SET @Ergebnis				= (SELECT TOP (1) [GanzeZeile] FROM [Infrastruktur].[PNG_Stufe2] WHERE [ZeilenNr] < @Obergrenze AND [GanzeZeile] LIKE '%Result%'	ORDER BY [ZeilenNr] ASC)
		SET @EloWertWeiss			= (SELECT TOP (1) [GanzeZeile] FROM [Infrastruktur].[PNG_Stufe2] WHERE [ZeilenNr] < @Obergrenze AND [GanzeZeile] LIKE '%WhiteElo%'	ORDER BY [ZeilenNr] ASC)
		SET @EloWertSchwarz			= (SELECT TOP (1) [GanzeZeile] FROM [Infrastruktur].[PNG_Stufe2] WHERE [ZeilenNr] < @Obergrenze AND [GanzeZeile] LIKE '%BlackElo%'	ORDER BY [ZeilenNr] ASC)
		SET @ECO					= (SELECT TOP (1) [GanzeZeile] FROM [Infrastruktur].[PNG_Stufe2] WHERE [ZeilenNr] < @Obergrenze AND [GanzeZeile] LIKE '%ECO%'		ORDER BY [ZeilenNr] ASC)

		INSERT INTO [Bibliothek].[Partiemetadaten]
				   ( [Quelle]
				   , [Seite]
				   , [Veranstaltungsdatum]
				   , [Runde]
				   , [Weiss]
				   , [Schwarz]
				   , [Ergebnis]
				   , [EloWertWeiss]
				   , [EloWertSchwarz]
				   , [ECO]
				   , [KurzeNotation])
			 VALUES
				   (
			  @Quelle
			, (SUBSTRING(@Seite,				CHARINDEX ('"', @Seite ) + 1,				LEN(@Seite) -				CHARINDEX ('"', @Seite ) - 2))
			, (SUBSTRING(@Veranstaltungsdatum,	CHARINDEX ('"', @Veranstaltungsdatum ) + 1,	LEN(@Veranstaltungsdatum) -	CHARINDEX ('"', @Veranstaltungsdatum ) - 2))
			, (SUBSTRING(@Runde,				CHARINDEX ('"', @Runde ) + 1,				LEN(@Runde) -				CHARINDEX ('"', @Runde ) - 2))
			, (SUBSTRING(@Weiss,				CHARINDEX ('"', @Weiss ) + 1,				LEN(@Weiss) -				CHARINDEX ('"', @Weiss ) - 2))
			, (SUBSTRING(@Schwarz,				CHARINDEX ('"', @Schwarz ) + 1,				LEN(@Schwarz) -				CHARINDEX ('"', @Schwarz ) - 2))
			, (SUBSTRING(@Ergebnis,				CHARINDEX ('"', @Ergebnis ) + 1,			LEN(@Ergebnis) -			CHARINDEX ('"', @Ergebnis ) - 2))
			, (SUBSTRING(@EloWertWeiss,			CHARINDEX ('"', @EloWertWeiss ) + 1,		LEN(@EloWertWeiss) -		CHARINDEX ('"', @EloWertWeiss ) - 2))
			, (SUBSTRING(@EloWertSchwarz,		CHARINDEX ('"', @EloWertSchwarz ) + 1,		LEN(@EloWertSchwarz) -		CHARINDEX ('"', @EloWertSchwarz ) - 2))
			, (SUBSTRING(@ECO,					CHARINDEX ('"', @ECO ) + 1,					LEN(@ECO) -					CHARINDEX ('"', @ECO ) - 2))
			, @Notationszeile

				   )

		SELECT 'Verarbeite Satz ' + CONVERT(VARCHAR(9), @Zaehler) + '   ' + @Weiss + ' vs ' + @Schwarz + '    ' + @Notationszeile

		DELETE FROM [Infrastruktur].[PNG_Stufe2] WHERE [ZeilenNr] <= @Obergrenze

		-- Den Beginn des zweiten Blocks ermitteln. Es ist das zweite Vorkommen des 
		-- EVENT-Eintrages
		SET @Obergrenze = (	SELECT TOP 1
								[ZeilenNr]
							FROM [Infrastruktur].[PNG_Stufe2]
							WHERE 1 = 1
								AND [GanzeZeile] LIKE '%Event%'
								AND [ZeilenNr] > 1
							ORDER BY [ZeilenNr]
							)

		-- Den Beginn des ersten Notationsblocks ermitteln. Es ist das erste Vorkommen  
		-- nach dem ECO-Eintrages
		SET @Untergrenze = (SELECT TOP 1
								[ZeilenNr]
							FROM [Infrastruktur].[PNG_Stufe2]
							WHERE 1 = 1
								AND [GanzeZeile] LIKE '%ECO%'
							ORDER BY [ZeilenNr]
							)

		SET @Zaehler = @Zaehler + 1
	END

	DELETE FROM [Bibliothek].[Partiemetadaten]
	WHERE 1 = 2
		OR [Seite]					IS NULL
		OR [Veranstaltungsdatum]	IS NULL
		OR [Runde]					IS NULL
		OR [Weiss]					IS NULL
		OR [Schwarz]				IS NULL
		OR [Ergebnis]				IS NULL
		OR [EloWertWeiss]			IS NULL
		OR [EloWertSchwarz]			IS NULL
		OR [ECO]					IS NULL
		OR [KurzeNotation]			IS NULL
		OR LEN([KurzeNotation])		< 30

	UPDATE [Bibliothek].[Partiemetadaten]	SET [EloWertWeiss]		= NULL		WHERE [EloWertWeiss]	= 0
	UPDATE [Bibliothek].[Partiemetadaten]	SET [EloWertSchwarz]	= NULL		WHERE [EloWertSchwarz]	= 0
	UPDATE [Bibliothek].[Partiemetadaten]	SET [Runde]				= NULL		WHERE [Runde]			= '?'
	UPDATE [Bibliothek].[Partiemetadaten]	SET [Seite]				= NULL		WHERE [Seite]			= '?'
	UPDATE [Bibliothek].[Partiemetadaten]	SET [KurzeNotation]		= 
			CASE 
				WHEN LEFT([Ergebnis],3) = '1-0' THEN TRIM(LEFT([KurzeNotation], CHARINDEX('1-0', [KurzeNotation], 1) - 1))
				WHEN LEFT([Ergebnis],3) = '0-1' THEN TRIM(LEFT([KurzeNotation], CHARINDEX('0-1', [KurzeNotation], 1) - 1))
				WHEN LEFT([Ergebnis],3) = '1/2' THEN TRIM(LEFT([KurzeNotation], CHARINDEX('1/2', [KurzeNotation], 1) - 1))
				ELSE NULL
			END
END
GO

/*

USE [arelium_TSQL_Schach_V012]
GO


TRUNCATE TABLE [Bibliothek].[Partiemetadaten]
GO

DECLARE	@return_value int

EXEC	@return_value = [Bibliothek].[prcImportPGN]
		@KompletterDateiAblagepfad = N'D:\Beruf\arelium\Sessions\arelium_TSQL_Schach\V012\PNGs\Huebner.pgn'
--		@KompletterDateiAblagepfad = N'C:\arelium_Repos\arelium_TSQL_Schach\V012\PNGs\Kasparov.pgn'
--		@KompletterDateiAblagepfad = N'C:\arelium_Repos\arelium_TSQL_Schach\V012\PNGs\Karpov.pgn'
--		@KompletterDateiAblagepfad = N'C:\arelium_Repos\arelium_TSQL_Schach\V012\PNGs\Lasker.pgn'
		, @MaxZaehler = 502

SELECT	'Return Value' = @return_value

GO
*/