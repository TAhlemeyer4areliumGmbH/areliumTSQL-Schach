-- ###########################################################################################
-- ### Spiel der Koenige - Workshopversion ###################################################
-- ###########################################################################################
-- ### Erstellung der Funktion [Statistik].[fncFreibauern]                                 ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Der Bauer ist nominell in der Regel (in diesem Programm ist das konfigurierbar!)    ###
-- ### die Figur mit dem schwaechsten Wert. Normalerweise werden alle Figuren in           ###
-- ### Bauerneinheiten gemessen, so dass der Bauer den Wert 1 hat.                         ###
-- ###                                                                                     ###
-- ### Jetzt muss man aber fuer eine fortgeschrittene Bewertung feststellen, dass Bauer    ###
-- ### nicht gleich Bauer ist. Ein Kriterium bei der genaueren Betrachtung eines Bauern    ###
-- ### ist die Frage, ob er auf seinem Weg zur gegnerischen Grundlinie noch von einem      ###
-- ### feindlichen Bauern geblockt oder geschlagen werden kann.                            ###
-- ###                                                                                     ###
-- ### Diese Funktion errechnet anhand seiner Position einen Wert fuer jeden Bauern und    ###
-- ### addiert die Einzelwerte fuer alle Bauern einer Farbe auf.                           ###
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
-- ###     1.00.0	2023-05-08	Torsten Ahlemeyer                                          ###
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

-- -----------------------------------------------------------------------------------------
-- Erstellung der Funktion [Statistik].[fncFreibauern]
-- -----------------------------------------------------------------------------------------
-- Es werden die Fortschrittswerte aller Bauern einer Farbe aufaddiert. Dieser Wert ist einer der 
-- Bausteine fuer eine gute Stellungsbewertung. 
CREATE OR ALTER FUNCTION [Statistik].[fncFreibauern]
(
	  @IstSpielerWeiss			AS BIT
	, @Bewertungsstellung		AS typStellung READONLY
)
RETURNS INTEGER
AS
BEGIN
	DECLARE @RueckgabeWert AS INTEGER

	SET @RueckgabeWert = 
		(
			SELECT 	
				SUM(ABS((([IstSpielerWeiss] + 1) % 2)	* 8 - [Reihe] + [IstSpielerWeiss])) AS [Fortschritt]
			FROM @Bewertungsstellung
			WHERE 1 = 1
				AND [IstSpielerWeiss]	= @IstSpielerWeiss
				AND [FigurBuchstabe]	= 'B'
		)

	RETURN @RueckgabeWert 

END
GO

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '105 - Funktion [Statistik].[fncFreibauern] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO


/*
-- Test der Funktion 104 - Funktion [Statistik].[fncFreibauern] erstellen

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



SELECT [Statistik].[fncFreibauern]('TRUE', @ASpielbrett)
SELECT [Statistik].[fncFreibauern]('FALSE', @ASpielbrett)
GO
*/
