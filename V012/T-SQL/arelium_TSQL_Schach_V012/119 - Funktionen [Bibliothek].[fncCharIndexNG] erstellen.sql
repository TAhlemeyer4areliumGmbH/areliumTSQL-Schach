-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Erstellung von Funktionen [Bibliothek].[fncCharIndexNG1] und                        ###
-- ### [Bibliothek].[fncCharIndexNG2]                                                      ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Diese Funktionen ermitteln das n-te Vorkommen eines Suchmusters in einem String     ###
-- ### und liefern seine Position zurück.                                                  ###
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
-- ###     1.00.0	2023-02-17	Torsten Ahlemeyer                                          ###
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

-- ######################################################################################
-- ###  Erstellung der Funktion [Bibliothek].[fncCharIndexNG1]                        ###
-- ######################################################################################
CREATE OR ALTER FUNCTION [Bibliothek].[fncCharIndexNG1] (
	  @Suchmuster			VARCHAR(8000)
	, @DurchsuchterString	VARCHAR(MAX)
	, @StartPunkt			INTEGER
	, @VorkommenID			TINYINT
)
RETURNS BIGINT
AS
BEGIN
	DECLARE @Pos				BIGINT

	IF ISNULL(@VorkommenID, 0) <= 0 OR ISNULL(@StartPunkt, 0) <= 0
	BEGIN
		SELECT @Pos = 0
	END 
	ELSE 
	BEGIN
		IF @VorkommenID = 1
		BEGIN
			SELECT @Pos = CHARINDEX(@Suchmuster, @DurchsuchterString, @StartPunkt)
		END 
		ELSE 
		BEGIN
			SELECT @Pos = [Bibliothek].[fncCharIndexNG1]
				(
					  @Suchmuster
					, @DurchsuchterString
					, NULLIF(CHARINDEX(@Suchmuster, @DurchsuchterString, @StartPunkt), 0) + 1
					, @VorkommenID - 1)
		END
	END
	RETURN @Pos
END
GO

-- ######################################################################################
-- ###  Erstellung der Funktion [Bibliothek].[fncCharIndexNG2]                        ###
-- ######################################################################################
CREATE OR ALTER FUNCTION [Bibliothek].[fncCharIndexNG2] (
	  @Suchmuster			VARCHAR(8000)
	, @DurchsuchterString	VARCHAR(MAX)
	, @VorkommenID			TINYINT
)
RETURNS BIGINT
AS
BEGIN
	RETURN [Bibliothek].[fncCharIndexNG1](@Suchmuster, @DurchsuchterString, 1, @VorkommenID)
END
GO

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '210 - Funktionen [Bibliothek].[fncCharIndexNG] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO
/*
-- Test der Funktion [Infrastruktur].[fncKurzeNotationKomplex]

DECLARE @VAL VARCHAR(MAX) = 'test_54_s_aw_2m.pcx'

SELECT [Bibliothek].[fncCharIndexNG2]('_', @val, 3) 
*/
