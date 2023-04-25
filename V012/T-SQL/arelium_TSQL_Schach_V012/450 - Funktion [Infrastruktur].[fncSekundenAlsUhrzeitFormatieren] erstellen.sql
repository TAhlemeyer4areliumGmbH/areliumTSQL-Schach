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
CREATE OR ALTER FUNCTION [Infrastruktur].[fncSekundenAlsUhrzeitFormatieren]
(
    @AnzahlSekunden AS INTEGER
)
RETURNS CHAR(8)
AS
BEGIN
	DECLARE @Rueckgabe		AS CHAR(19)
	SET @Rueckgabe = CASE WHEN @AnzahlSekunden >= 86400
                THEN CONVERT(VARCHAR(5), @AnzahlSekunden/86400) 
                + ' Tage ' 
                ELSE ''
                END
       + CONVERT(VARCHAR(8), DATEADD(SECOND, @ANZAHLSEKUNDEN, 0), 108)

	RETURN @Rueckgabe
END
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '450 - Funktion [Infrastruktur].[fncSekundenAlsUhrzeitFormatieren] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO


/*
USE [arelium_TSQL_Schach_V012]
GO

SELECT [Infrastruktur].[fncSekundenAlsUhrzeitFormatieren](5390)
GO

*/