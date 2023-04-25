-- ###########################################################################################
-- ### Spiel der Koenige - Workshopversion ###################################################
-- ###########################################################################################
-- ### Erstellung der Prozedur [Bibliothek].[prcGrossmeisterpartienEinlesen]               ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### In einer sogenannten "*.PGN"-Datei werden mehrere Schachpartien mit diversen        ###
-- ### Metaangaben sowie der kurzen Notation der gesamten Partie gespeichert.              ###
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
-- ###     1.00.0	2022-02-04	Torsten Ahlemeyer                                          ###
-- ###              Initiale Erstellung                                                    ###
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
-- Nutzinhalt ------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

USE [arelium_TSQL_Schach_V012]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- ######################################################################################
-- ###                                                            ###
-- ######################################################################################

-- Es werden alle bisher noch nicht erfassten Partien aus der Tabelle
-- [Bibliothek].[Partiemetadaten] eingelesen
CREATE OR ALTER PROCEDURE [Bibliothek].[prcGrossmeisterpartienEinlesen]
AS
BEGIN
	DECLARE @AktuellePartiemetadatenID		AS BIGINT
	DECLARE @NotationsString				AS NVARCHAR(MAX)

	DECLARE curNeuePartien CURSOR FOR 
		SELECT DISTINCT [PartiemetadatenID], [KurzeNotation]
		FROM [Bibliothek].[Partiemetadaten]
		WHERE [PartiemetadatenID] NOT IN (SELECT DISTINCT [PartiemetadatenID] FROM [Bibliothek].[Grossmeisterpartien]) 

	OPEN curNeuePartien  
	FETCH NEXT FROM curNeuePartien INTO @AktuellePartiemetadatenID, @NotationsString

	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		EXEC [Bibliothek].[prcKurzeNotationAufbereiten]
			  @PartiemetadatenID	= @AktuellePartiemetadatenID
			, @NotationsString		= @NotationsString

		FETCH NEXT FROM curNeuePartien INTO @AktuellePartiemetadatenID, @NotationsString 
	END 

	CLOSE curNeuePartien  
	DEALLOCATE curNeuePartien 
END
GO			



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '204 - Prozedur [Bibliothek].[prcGrossmeisterpartienEinlesen] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO
/*
EXEC [Bibliothek].[prcGrossmeisterpartienEinlesen]

SELECT * FROM [Bibliothek].[Grossmeisterpartien]



*/
