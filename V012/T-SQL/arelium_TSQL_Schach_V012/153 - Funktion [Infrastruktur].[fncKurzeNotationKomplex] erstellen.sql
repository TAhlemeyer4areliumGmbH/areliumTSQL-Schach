-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Erstellung der Funktion [Infrastruktur].[fncKurzeNotationKomplex]                   ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Diese Funktion wandelt einen Zug dieses T-SQL-Algorithmus in die standardisierte    ###
-- ### Beschreibung eines Zuges in der Schachwelt um: die kurze Notation.                  ###
-- ### (Es gibt auch eine lange Notation - siehe gleichnamige Funktion)                    ###
-- ###                                                                                     ###
-- ### Dabei gilt:                                                                         ###
-- ###    - Zuerst wird die Nummer des Halbzugs genannt                                    ###
-- ###    - Da Weiss beginnt, wird sein Zug links, der von Schwarz weiter rechts notiert   ###
-- ###    - Figuren werden mit ihren Anfangsbuchstaben Symbolisiert (K, D, L, S, T)        ###
-- ###    - Ein Bauer bekommt keinen Anfangsbuchstaben als Symbol                          ###
-- ###    - Das Zeichen fuer einen Zug ist "-"                                             ###
-- ###    - Das Zeichen fuer einen Schlag ist "x"                                          ###
-- ###    - Felder werden als Koordinate aus Spalte (A-J) und Reihe (1-8) angegeben        ###
-- ###    - Angeben wird stets die Figur (außer beim Bauern!), dann bei Bedarf das Zeichen ###
-- ###      fuer "Schlag" und schliesslich das Zielfeld                                    ###
-- ###    - Koennen theoretisch mehrere Figuren das Zielfeld erreichen, ist zusätzlich     ###
-- ###      eine weitere Information voranzustellen, die die Aktion eindeutig macht.       ###
-- ###      Beispiel: Statt "Sxe2" (Springer schlaegt auf e2) heisst es dann "Sfxe2",      ###
-- ###      wenn es sowohl in der "f"-Spalte wie auch in der "d"-Spalte einen Springer     ###
-- ###      gibt, der auf "e2" schlagen kann.                                              ###
-- ###    - handelt es sich um eine Bauernumwandlung, folgt dann der Anfangsbuchstabe der  ###
-- ###      Umtauschfigur.                                                                 ###
-- ###    - Ist der Zug ein Schachgebot, wird dies mit "+" als Abschlusszeichen angezeigt  ###
-- ###    - Ist der Zug ein Mattzug, wird dies mit "#" als Abschlusszeichen angezeigt. Ein ###
-- ###      Matt ist höherwertiger als ein Schach, somit wird das Schachzeichen nicht auch ###
-- ###      noch angezeigt.                                                                ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Beispiele:                                                                          ###
-- ###    - 11. Txe7+                --> bedeutet, dass der weisse Turm im 11. Zug die     ###
-- ###                                   Figur auf E7 schlaegt und dabei Schach gibt.      ###
-- ###    - 11.          b5          --> bedeutet, dass der schwarze Bauer im 11. Zug      ###
-- ###                                   nach B5 zieht.                                    ###
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
-- ###  Erstellung der Funktion [Infrastruktur].[fncKurzeNotationKomplex]             ###
-- ######################################################################################

CREATE OR ALTER FUNCTION [Infrastruktur].[fncKurzeNotationKomplex] 
(
	  @MoeglicheZuegeID		AS BIGINT
	, @ZugStelltSchach		AS BIT  = 'FALSE'
	, @ZugStelltMatt		AS BIT	= 'FALSE'
)
RETURNS VARCHAR(7)
AS
BEGIN
	DECLARE @Ergebnis		AS VARCHAR(7)
	
	SET @Ergebnis = 
		(
			SELECT
				  [MZU].[KurzeNotationEinfach]
				+ CASE 
						WHEN [MZU].[ZugIstEnPassant] = 'TRUE' THEN 'ep'
						ELSE ''
				  END
				+ CASE 
						WHEN @ZugStelltSchach = 'TRUE' THEN '+'
						ELSE ''
					END
				+ CASE 
						WHEN @ZugStelltMatt = 'TRUE' THEN '#'
						ELSE ''
					END
			FROM [Infrastruktur].[TheoretischeAktionen] AS [MZU]
			WHERE 1 = 1
				AND [MZU].[TheoretischeAktionenID]		= @MoeglicheZuegeID
		)

	RETURN @Ergebnis
	END
GO



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '153 - Funktion [Infrastruktur].[fncKurzeNotationKomplex] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO
/*
-- Test der Funktion [Infrastruktur].[fncKurzeNotationKomplex]

SELECT [Infrastruktur].[fncKurzeNotationKomplex] (13879, 'TRUE', 'FALSE')
GO
*/
