-- ###########################################################################################
-- ### Spiel der Koenige - Workshopversion ###################################################
-- ###########################################################################################
-- ### Erstellung der Funktion [Statistik].[fncFigurWertZaehlen]                           ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Ein Part der Stellungsbewertung ist die Frage, welche Partei noch wieviele Figuren  ###
-- ### welcher Art auf dem Brett hat. Hierzu haelt die Tabelle [Infrastruktur].[Figur]     ###
-- ### ein Punktesystem vor, mit dem jeder Figurenart ein Punktewert zugewiesen wird. Fuer ###
-- ### jedes Exemplar berechnet die Funktion den Einzelwert und addierte diese später zu   ###
-- ### einem Gesamtwert.                                                                   ###
-- ###                                                                                     ###
-- ### Die Funktion arbeite nicht mit der Tabelle [Infrastruktur].[Spielbrett] sondern     ###
-- ### bekommt eine Stellung ueber einen der Paramter mitgeliefert. So sind spaeter        ###
-- ### Bewertungen von hypothetischen Stellungen moeglich, so dass man mehrere Zuege in    ###
-- ### die Zukunft "gucken" kann.                                                          ###
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
-- ###     1.00.0	2022-12-14	Torsten Ahlemeyer                                          ###
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
-- Erstellung der Funktion [Statistik].[fncFigurWertZaehlen]
-- -----------------------------------------------------------------------------------------
-- Es werden die Figurwerte aller Steine einer Farbe aufaddiert. Dieser Wert ist einer der 
-- Bausteine fuer eine gute Stellungsbewertung. Eine Materialueberlegenheit ist allerdings nur
-- ein Indiz - es kommt auch auf die genaue Stellung der Figuren und ihre Aktivität (also auch 
-- die Stellung der gegnerischen Figuren) an. Diese Frage kann durch die [Statistik].[fncFigurWertZaehlen]
-- allerdings nicht beantwortet werden.
CREATE OR ALTER FUNCTION [Statistik].[fncFigurWertZaehlen]
(
	  @IstSpielerWeiss		AS BIT
	, @Bewertungsstellung	AS typStellung READONLY
)
RETURNS INTEGER
AS
BEGIN
	DECLARE @RueckgabeWert AS INTEGER

	SET @RueckgabeWert = 
		(
			SELECT ISNULL(SUM([FigurWert]), 0)
			FROM @Bewertungsstellung AS [SB]
			INNER JOIN [Infrastruktur].[Figur] AS [FI] 
				ON [SB].FigurUTF8 = [FI].FigurUTF8
					AND [SB].[IstSpielerWeiss] = @IstSpielerWeiss
					AND [FI].[IstSpielerWeiss] = @IstSpielerWeiss
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
DECLARE @Skript		VARCHAR(100)	= '100 - Funktion [Statistik].[fncFigurwertZaehlen] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO


/*
-- Test der Funktion [Statistik].[fncFigurWertZaehlen]

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



SELECT 
	  [Statistik].[fncFigurWertZaehlen] ('TRUE',	@ASpielbrett)		AS [Weiss]
	, [Statistik].[fncFigurWertZaehlen] ('FALSE',	@ASpielbrett)		AS [Schwarz]
GO
*/
