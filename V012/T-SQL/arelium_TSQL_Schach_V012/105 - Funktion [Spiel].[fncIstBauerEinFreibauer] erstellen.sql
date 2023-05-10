-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Ueberpruefen, ob eine Bauer ein Freibauer ist                                       ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Diese Funktion prueft fuer einen Spieler, ob ein bestimmter seiner Bauern ein       ###
-- ### Freibauer ist. Dabei handelt es sich um Figuren, die nicht mher durch gegnerische   ###
-- ### Bauern auf ihrem Weg zur feindlichen Grundlinie aufgehalten werden koennen. Sie     ###
-- ### haben also keinen andersfarbigen Bauern mehr vor sich (wuerde den Bauern blocken)   ###
-- ### oder diagonal nach vorne in den direkt benachbarten Spalten.                        ###
-- ###                                                                                     ###
-- ### Freibauern sind sehr maechtig. Sie verwandeln sich oft in andere Figuren, bspw.     ###
-- ### eine Dame. Oft ist der Gegner daher gezwungen eine wertvolle Figur zu opfern, um    ###
-- ### den Bauern noch rechtzeitig abzufangen.                                             ###
-- ###                                                                                     ###
-- ### Am Ende dieses Block gibt es eine (auskommentierte) Testroutine, mit der man fuer   ###
-- ### eine uebergebene Stellung testen kann, ob ein (nicht) angegriffenes Feld korrekt    ###
-- ### (nicht) erkannt wird.                                                               ###
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
-- ###     1.00.0	2023-02-21	Torsten Ahlemeyer                                          ###
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

-- Diese Funktion prueft fuer einen uebergebenen Bauern, ob in seinem Weg oder diagonal
-- nach vorne gerichtet in einer Spalte Abstand ein gegnerischer Bauer steht
CREATE OR ALTER FUNCTION [Spiel].[fncIstBauerEinFreibauer]
(
	   @IstSpielerWeiss					AS BIT
	 , @Bewertungsstellung				AS typStellung			READONLY
	 , @ZuBeurteilendesFeld				AS TINYINT
)
RETURNS BIT
AS
BEGIN
	DECLARE @Ergebnis					AS BIT

	IF 
		(
			NOT EXISTS (
				SELECT * 
				FROM @Bewertungsstellung
				WHERE 1 = 1
					AND [Spalte] BETWEEN 
						(SELECT CHAR(ASCII([Spalte]) - 1) FROM @Bewertungsstellung WHERE [Feld] = @ZuBeurteilendesFeld)
						AND 
						(SELECT CHAR(ASCII([Spalte]) + 1) FROM @Bewertungsstellung WHERE [Feld] = @ZuBeurteilendesFeld)
					AND [Reihe] BETWEEN 
						(SELECT ([Reihe] + 1) FROM @Bewertungsstellung WHERE [Feld] = @ZuBeurteilendesFeld)
						AND 7
					AND [IstSpielerWeiss]	= 'FALSE'
					AND [FigurBuchstabe]	= 'B'
				)
			AND @IstSpielerWeiss = 'TRUE'
		)
		OR
		(
			NOT EXISTS (
				SELECT * 
				FROM @Bewertungsstellung
				WHERE 1 = 1
					AND [Spalte] BETWEEN 
						(SELECT CHAR(ASCII([Spalte]) - 1) FROM @Bewertungsstellung WHERE [Feld] = @ZuBeurteilendesFeld)
						AND 
						(SELECT CHAR(ASCII([Spalte]) + 1) FROM @Bewertungsstellung WHERE [Feld] = @ZuBeurteilendesFeld)
					AND [Reihe] BETWEEN 
						2 AND 
						(SELECT ([Reihe] - 1) FROM @Bewertungsstellung WHERE [Feld] = @ZuBeurteilendesFeld)
					AND [IstSpielerWeiss]	= 'TRUE'
					AND [FigurBuchstabe]	= 'B'
				)
			AND @IstSpielerWeiss = 'FALSE'
		)
	BEGIN
		SET @Ergebnis = 'TRUE'
	END
	ELSE
	BEGIN
		SET @Ergebnis = 'FALSE'
	END

RETURN @Ergebnis
END 
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '105 - Funktion [Spiel].[fncIstBauerEinFreibauer] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO



/*
-- Test der Funktion [Spiel].[fncIstBauerEinFreibauer]()
use [arelium_TSQL_Schach_V012]
go

DECLARE @IstSpielerWeiss				AS BIT
DECLARE @Bewertungsstellung				AS [dbo].[typStellung]
DECLARE @ZuBeurteilendesFeld			AS TINYINT

SET @IstSpielerWeiss					= 'FALSE'
SET @ZuBeurteilendesFeld				= 55
INSERT INTO @Bewertungsstellung
	SELECT 
		  1								AS [VarianteNr]
		, 1								AS [Suchtiefe]
		, [SB].[Spalte]					AS [Spalte]
		, [SB].[Reihe]					AS [Reihe]
		, [SB].[Feld]					AS [Feld]
		, [SB].[IstSpielerWeiss]		AS [IstSpielerWeiss]
		, [FigurBuchstabe]				AS [FigurBuchstabe]
		, [SB].[FigurUTF8]				AS [FigurUTF8]
	FROM [Infrastruktur].[Spielbrett]	AS [SB]


SELECT [Spiel].[fncIstBauerEinFreibauer](@IstSpielerWeiss, @Bewertungsstellung, @ZuBeurteilendesFeld)

GO
*/
