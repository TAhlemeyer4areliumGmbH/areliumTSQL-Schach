-- ###########################################################################################
-- ### Spiel der Koenige - Workshopversion ###################################################
-- ###########################################################################################
-- ### Erstellung der Funktion [Infrastruktur].[fncSekundenAlsUhrzeitFormatieren]          ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Eine uebergebene Zahl an Sekudnen wird in eine Angabe von Stunden, Minuten und      ###
-- ### Sekunden umgewandelt. Das Rueckgabeformat ist eine String der Form hh:mm:ss.        ###
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
-- Erstellung der Funktion [Infrastruktur].[fncSekundenAlsUhrzeitFormatieren]
-- -----------------------------------------------------------------------------------------
CREATE OR ALTER VIEW [Bibliothek].[vSchonmalGespielt]
AS

WITH [CTEBucheintrag]
AS (
	SELECT TOP 1
	*
	FROM [Bibliothek].[Partiemetadaten] AS [PMD]
	WHERE 1 = 1
		AND [PMD].[KurzeNotation] LIKE
			(
				SELECT
					STRING_AGG([Vollzug], ' ') + '%'
				FROM
				(
					SELECT TOP 100  PERCENT
						  [WEISS].[VollzugID]
						, [WEISS].[KurzeNotationEinfach]
						, CONVERT(VARCHAR(3), [WEISS].[VollzugID]) + '.' + [WEISS].[KurzeNotationEinfach]
						  + ' ' + ISNULL([SCHWARZ].[KurzeNotationEinfach], '') AS [Vollzug]
					FROM [Spiel].[Notation] AS [WEISS]
					LEFT JOIN [Spiel].[Notation] AS [SCHWARZ]
						ON [WEISS].[VollzugID]				= [SCHWARZ].[VollzugID]
						AND [SCHWARZ].[IstSpielerWeiss]		= 'FALSE'
					WHERE 1 = 1
						AND [WEISS].[IstSpielerWeiss]		= 'TRUE'
					ORDER BY [WEISS].[VollzugID] ASC
				) AS [Vorlage]
			)
	ORDER BY NEWID()--[PartiemetadatenID]
	)

	SELECT 1 AS [ID],	CASE (SELECT COUNT([PartiemetadatenID]) FROM [CTEBucheintrag])
							WHEN 1 THEN
								(SELECT 'Partie [' + CONVERT(VARCHAR(8), [PartiemetadatenID]) + '] wurde schon gespielt im Jahr ' + ISNULL(LEFT([Veranstaltungsdatum], 4), '????') FROM [CTEBucheintrag])
							ELSE 
								CASE
									WHEN (SELECT COUNT(*) FROM [Spiel].[Notation]) > 0 THEN 'diese Zugfolge steht nicht in der Bibliothek'
									ELSE 'Startaufstellung'
								END
						END AS [Wert] 
	UNION
	SELECT 2, ' von ' + [Weiss] + ' (Weiss' + ISNULL(CONVERT(VARCHAR(6), [EloWertWeiss]), '') +  ')' FROM [CTEBucheintrag] 
	UNION
	SELECT 3, ' und ' + [Schwarz] + ' (Schwarz' + ISNULL(CONVERT(VARCHAR(6), [EloWertSchwarz]), '') +  ')' FROM [CTEBucheintrag]
	UNION
	SELECT 4, ' Ergebnis: ' + [Ergebnis] FROM [CTEBucheintrag]
	UNION
	SELECT 5, ' '
	UNION
	SELECt 6, 'Grossmeisterfortsetzung:'
	UNION
	SELECT 7, CASE (
				SELECT [GrossmeisterpartienAnzeigen] 
				FROM [Infrastruktur].[Spielstaerke] AS [SST]
				INNER JOIN [Spiel].[Konfiguration] AS [KON] ON [SST].[SpielstaerkeID] = [KON].[SpielstaerkeID]
				WHERE [KON].[IstSpielerWeiss] = [Spiel].[fncIstWeissAmZug]()
				)
				WHEN 1 THEN 
					(SELECT SUBSTRING([KurzeNotation]
					, (--1.e4 c6 2.d4 d5 3.e5 Bf5 4.Nf3 e6 5.Be2 c5 6.O-O Nc6 7.Be3 cxd4
							-- Start: 
		SELECT [Bibliothek].[fncCharIndexNG2](
						' '
						, [KurzeNotation]
						, 2 * (SELECT MAX([VollzugID]) FROM [Spiel].[Notation])	- 1
					) FROM [CTEBucheintrag]
		)
, 
	(
		(SELECT [Bibliothek].[fncCharIndexNG2](
						' '
						, [KurzeNotation]
						, 4 + 2 * (SELECT MAX([VollzugID]) FROM [Spiel].[Notation])	
		) FROM [CTEBucheintrag])
		-
		(SELECT [Bibliothek].[fncCharIndexNG2](
						' '
						, [KurzeNotation]
						, 2 * (SELECT MAX([VollzugID]) FROM [Spiel].[Notation])	- 1
					) FROM [CTEBucheintrag])
		
		)
	) FROM [CTEBucheintrag])
				ELSE
					'nicht konfiguriert'
				END
	
	
		
		
		
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '117 - View [Bibliothek].[vSchonmalGespielt] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO


/*
USE [arelium_TSQL_Schach_V012]
GO

SELECT * FROM [Bibliothek].[vSchonmalGespielt]
GO

*/