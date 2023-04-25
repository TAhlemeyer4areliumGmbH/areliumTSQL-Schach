-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Ueberpruefen, ob eine Feld aktuell bedroht ist                                      ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Diese Funktion prueft fuer einen Spieler, ob er im naechste Zug ein vergegebenes    ###
-- ### Feld regelkonform erreichen (im Sinen von "schlagen" - nicht "ziehen"!) kann.       ###
-- ###                                                                                     ###
-- ### Hierzu wird die Funktion [Spiel].[frcMoeglicheAktionen] genutzt. Uebergeben wird    ###
-- ### der Spieler, der evtl. das Feld bedroht. Eine positive Antwort bedeutet, dass das   ###
-- ### Feld bedroht ist. Diese Funktion ist zur Funktion [Spiel].[frcSpielerStehtImSchach] ###
-- ### weiterzuentwickeln, indem das zu ueberprufende Feld zwingend das Feld des eigenen   ###
-- ### Koenigs ist.                                                                        ###
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

-- Diese Funktion erstellt und fuellt eine Tabelle mit allen Aktionen, die von der uebergebenen Stellung aus unter 
-- Beruecksichtigung der Spielregeln genutzt werden koennen. Es werden Aktionen fuer beide Spieler ermittelt - die 
-- aufrufende Stelle muss auswerten, welcher Spieler am Zug ist
CREATE OR ALTER FUNCTION [Spiel].[fncIstFeldBedroht]
(
	   @IstAngriffsspielerWeiss			AS BIT
	 , @Bewertungsstellung				AS typStellung			READONLY
	 , @ZuBeurteilendesFeld				AS TINYINT
)
RETURNS BIT
AS
BEGIN
	DECLARE @Ergebnis					AS BIT

	IF EXISTS (
		SELECT * 
		FROM [Spiel].[fncMoeglicheAktionen](@IstAngriffsspielerWeiss, @Bewertungsstellung)
		WHERE 1 = 1
			AND [ZielFeld] = @ZuBeurteilendesFeld
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
DECLARE @Skript		VARCHAR(100)	= '085 - Funktion [Spiel].[fncMoeglicheAktionen] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO



/*
-- Test der Funktion [Spiel].[fncIstFeldBedroht]

DECLARE @IstAngriffsspielerWeiss		AS BIT
DECLARE @Bewertungsstellung				AS [dbo].[typStellung]
DECLARE @Zielfeld						AS TINYINT

SET IstAngriffsspielerWeiss				= 'FALSE'
SET Zielfeld							= 22

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


SELECT * FROM [Spiel].[fncIstFeldBedroht](IstAngriffsspielerWeiss, @Bewertungsstellung, Zielfeld)

GO
*/
