-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Moegliche Aktionen zusammenstellen                                                  ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Diese Funktion durchlaeuft alle Figuren eines Spielers und notiert die damit laut   ###
-- ### Spielregeln gueltig durchzufuehrenden Aktionen. Es werden also alle Optionen        ###
-- ### erfasst, die der Spieler hat, um das Spiel regelkonform fortzusetzen.               ###
-- ###                                                                                     ###
-- ### Es werden alle Figurentypen per Cursor durchlaufen, da vorher nicht feststeht,      ###
-- ### wieviele Figuren dieses Typs noch auf dem Brett stehen. Durch Bauernumwandlung      ###
-- ### kann die Zahl der Schwerfiguren (T, S, D, L) erhoeht worden sein. Durch Schlaege    ###
-- ### im Spielverlauf kann die Zahl der Figuren jedes Typs mit Ausnahme des Koenigs       ###
-- ### reduziert worden sein.                                                              ###
-- ###                                                                                     ###
-- ### Am Ende dieses Block gibt es eine (auskommentierte) Testroutine, mit der man fuer   ###
-- ### eine uebergebene Stellung testen kann, ob alle (und nur diese) gueltigen Zuege fuer ###
-- ### die genannten Figuren zurueck kommen.                                               ###
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
-- Dank des "CREATE OR ALTER"-Befehls ist ein vorheriges Loeschen des Datenbankobjektes 
-- nicht mehr noetig.

-----------------------------
-- Aufbauarbeiten -----------
-----------------------------

-- Diese Tabnellenwertfunktion erstellt und fuellt eine Rueckgabetabelle mit allen Aktionen, die von der 
-- uebergebenen Stellung (im EFN-Format) aus unter Beruecksichtigung der Spielregeln genutzt werden koennen. Es werden 
-- nur Aktionen fuer den aktiven Spieler ermittelt
CREATE OR ALTER FUNCTION [Spiel].[fncMoeglicheAktionenEFN]
(
	 @EFN_Bewertungsstellung	AS typStellung			READONLY
)
RETURNS @MoeglicheAktionenEFN TABLE 
	(
		  [EFN]							VARCHAR(100)	NOT NULL
		, [TheoretischeAktionenID]		BIGINT			NOT NULL
		, [HalbzugNr]					INTEGER			NOT NULL
		, [FigurName]					NVARCHAR(20)	NOT NULL
		, [IstSpielerWeiss]				BIT				NOT NULL
		, [StartSpalte]					CHAR(1)			NOT NULL
		, [StartReihe]					TINYINT			NOT NULL
		, [StartFeld]					INTEGER			NOT NULL
		, [ZielSpalte]					CHAR(1)			NOT NULL
		, [ZielReihe]					TINYINT			NOT NULL
		, [ZielFeld]					INTEGER			NOT NULL
		, [Richtung]					CHAR(2)			NOT NULL
		, [ZugIstSchlag]				BIT				NOT NULL
		, [ZugIstEnPassant]				BIT				NOT NULL
		, [ZugIstKurzeRochade]			BIT				NOT NULL
		, [ZugIstLangeRochade]			BIT				NOT NULL
		, [UmwandlungsfigurBuchstabe]	NVARCHAR(20)	NULL
		, [LangeNotation]				VARCHAR(20)		NULL
		, [KurzeNotationEinfach]		VARCHAR(8)		NULL
		, [KurzeNotationKomplex]		VARCHAR(8)		NULL
	) AS
	BEGIN

	-- aus dem EFN-String ein virtuelles Brett besetzen

		INSERT INTO @MoeglicheAktionenEFN 
			(
				  [EFN], [TheoretischeAktionenID], [HalbzugNr], [FigurName], [IstSpielerWeiss], [StartSpalte]
				, [StartReihe], [StartFeld], [ZielSpalte], [ZielReihe], [ZielFeld], [Richtung], [ZugIstSchlag]
				, [ZugIstEnPassant], [ZugIstKurzeRochade], [ZugIstLangeRochade], [UmwandlungsfigurBuchstabe]
				, [LangeNotation], [KurzeNotationEinfach], [KurzeNotationKomplex]
			)
		SELECT 1, * FROM [Spiel].[fncMoeglicheAktionen]('FALSE', @EFN_Bewertungsstellung)

	RETURN
	END 
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '049 - Funktion [Spiel].[fncMoeglicheAktionenEFN] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO



/*
-- Test der Funktion [Spiel].[fncMoeglicheAktionenEFN]

DECLARE @EFN varchar(255)

--SET @EFN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
SET @EFN = '6r1/6pp/7r/1B5K/1P3k2/N7/3R4/8 w - - 30 79'

SELECT * FROM [Spiel].[fncMoeglicheAktionenEFN]


GO
*/
