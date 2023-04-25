-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Erstellung der Funktion [Spiel].[fncMoeglicheTurmschlaege]                          ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Moechte man herausfinden, welche Moeglichkeiten man in einer bestimmten Stellung    ###
-- ### hat mit der Figur "Turm" zu schlaagen (nicht zu ziehen!), bemueht man diese         ###
-- ### Funktion. Dabei sind alle Felder als Rueckgabe gemeint, die ein Turm theoretisch    ###
-- ### angreifen kann. Die Funktion erwartet die Angabe einer Stellung (dies muss nicht    ###
-- ### zwingend [Infrastruktur].[Spielbrett] sein!) und des Feldes, fuer das die           ###
-- ### Schlagmoeglichkeiten abgefragt werden sollen. Dabei werden alle mit dieser Figur    ###
-- ### mit einer Schlagaktion erreichbaren Felder gelistet - unabhaengig ob dort wirklich  ###
-- ### eine gegnerische Figur steht. Tatsaechlich auf dem Brett befindliche Figuren        ###
-- ### begrenzen allerdings die Wirklinie der angreifenden Figur regelkonform.             ###
-- ###                                                                                     ###
-- ### Die Funktion gibt es in aehnlicher Ausfuehrung auch fuer die anderen Figuren. Wenn  ###
-- ### man die Rueckgaben fuer die Einzelaufrufe fuer alle Instanzen jeder Figur           ###
-- ### kombiniert, bekommt man eine vollstaendige Uebersicht alle moeglichen               ###
-- ### Schlaege.                                                                           ###
-- ###                                                                                     ###
-- ### Am Ende dieses Block gibt es eine (auskommentierte) Testroutine, mit der man fuer   ###
-- ### eine uebergebene Stellung testen kann, ob alle (und nur diese) gueltigen Zuege fuer ###
-- ### die genannte Figur zurueck kommen.                                                  ###
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

CREATE OR ALTER FUNCTION [Spiel].[fncMoeglicheTurmschlaege]
(
	   @IstSpielerWeiss		AS BIT									-- Information, ob es sich um einen weissen oder schwarzen Turm handelt
	 , @Bewertungsstellung	AS typStellung			READONLY		-- die komplette zu analysierende Stellung (dies muss nicht zwingend [Infrastruktur].[Spielbrett] sein!)
	 , @AktivesFeld			AS INTEGER								-- Angabe, welcher Turm gemeint ist. Kriterium ist die Nummer des feldes, auf dem der Turm steht
)
RETURNS @MoeglicheTurmschlaege TABLE 
	(
		  [TheoretischeAktionenID]		BIGINT			NOT NULL
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
		, [UmwandlungsfigurBuchstabe]	CHAR(1)			NULL
		, [LangeNotation]				VARCHAR(7)		NULL
		, [KurzeNotationEinfach]		VARCHAR(8)		NULL
		, [KurzeNotationKomplex]		VARCHAR(8)		NULL
	) AS
	BEGIN
		INSERT INTO @MoeglicheTurmschlaege
		(
			  [TheoretischeAktionenID]
			, [FigurName]
			, [IstSpielerWeiss]
			, [StartSpalte]
			, [StartReihe]
			, [Startfeld]
			, [ZielSpalte]
			, [ZielReihe]
			, [Zielfeld]
			, [Richtung]
			, [ZugIstSchlag]
			, [ZugIstEnPassant]
			, [ZugIstKurzeRochade]
			, [ZugIstLangeRochade]
			, [UmwandlungsfigurBuchstabe]
			, [LangeNotation]
			, [KurzeNotationEinfach]
			, [KurzeNotationKomplex]
		)
		SELECT DISTINCT
			  [MZU].[TheoretischeAktionenID]				AS [TheoretischeAktionenID]
			, [MZU].[FigurName]								AS [FigurName]			
			, [MZU].[IstSpielerWeiss]						AS [IstSpielerWeiss]
			, [MZU].[StartSpalte]							AS [StartSpalte]
			, [MZU].[StartReihe]							AS [StartReihe]
			, [MZU].[Startfeld]								AS [StartFeld]
			, [MZU].[ZielSpalte]							AS [ZielSpalte]
			, [MZU].[ZielReihe]								AS [ZielReihe]
			, [MZU].[Zielfeld]								AS [ZielFeld]
			, [MZU].[Richtung]								AS [Richtung]
			, [MZU].[ZugIstSchlag]							AS [ZugIstSchlag]
			, [MZU].[ZugIstEnPassant]						AS [ZugIstEnPassant]
			, [MZU].[ZugIstKurzeRochade]					AS [ZugIstKurzeRochade]
			, [MZU].[ZugIstLangeRochade]					AS [ZugIstLangeRochade]
			, NULL											AS [UmwandlungsfigurBuchstabe]
			, [LangeNotation]								AS [LangeNotation]
			, [KurzeNotationEinfach]						AS [KurzeNotationEinfach]
			, [KurzeNotationKomplex]						AS [KurzeNotationKomplex]
		FROM [Infrastruktur].[TheoretischeAktionen]			AS [MZU]						-- alle theoretisch dekbaren Zuege
		INNER JOIN @Bewertungsstellung						AS [SPB]						-- davon nur die, deren Startfeld in der aktuellen Stellung besetzt 
			ON 1 = 1
				AND [MZU].[ZielReihe]				= [SPB].[Reihe]
				AND [MZU].[ZielSpalte]				= [SPB].[Spalte]
		WHERE 1 = 1
			AND [MZU].[IstSpielerWeiss]				= @IstSpielerWeiss
			AND [MZU].[FigurName]					= 'Turm'
			AND [MZU].[StartFeld]					= @AktivesFeld

			-- ermittelt werden fuer jede Zugrichtung alle Felder bis zur
			-- ersten Figur (egal welcher Farbe), die im Weg steht

			-- erste Figur im Weg nach rechts
			AND [MZU].[ZielSpalte] <= ISNULL(
				(
					SELECT MIN([Innen].[Spalte])
					FROM @Bewertungsstellung				AS [Innen]
					WHERE 1 = 1
						AND [Innen].[FigurUTF8]		<> 160
						AND [Innen].[Spalte]		> [MZU].[StartSpalte]
						AND [Innen].[Reihe]			= [MZU].[StartReihe]
				), 'H')

			-- erste Figur im Weg nach links
			AND [MZU].[ZielSpalte] >= ISNULL(
				(
					SELECT MAX([Innen].[Spalte])
					FROM @Bewertungsstellung				AS [Innen]
					WHERE 1 = 1
						AND [Innen].[FigurUTF8]		<> 160
						AND [Innen].[Spalte]		< [MZU].[StartSpalte]
						AND [Innen].[Reihe]			= [MZU].[StartReihe]
				), 'A')

			-- erste Figur im Weg nach oben
			AND [MZU].[ZielReihe] <= ISNULL(
				(
					SELECT MIN([Innen].[Reihe])
					FROM @Bewertungsstellung				AS [Innen]
					WHERE 1 = 1
						AND [Innen].[FigurUTF8]		<> 160
						AND [Innen].[Spalte]		= [MZU].[StartSpalte]
						AND [Innen].[Reihe]			> [MZU].[StartReihe]
				), 8)

			-- erste Figur im Weg nach unten
			AND [MZU].[ZielReihe] >= ISNULL(
				(
					SELECT MAX([Innen].[Reihe])
					FROM @Bewertungsstellung				AS [Innen]
					WHERE 1 = 1
						AND [Innen].[FigurUTF8]		<> 160
						AND [Innen].[Spalte]		= [MZU].[StartSpalte]
						AND [Innen].[Reihe]			< [MZU].[StartReihe]
				), 1)

			-- es sind nur Schlaege auszugeben
			AND [MZU].[ZugIstSchlag] = 'TRUE'
		RETURN
	END
GO




------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '071 - Funktion [Spiel].[fncMoeglicheTurmschlaege] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO

/*
-- Test der Funktion [Spiel].[fncMoeglicheTurmschlaege]

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

DECLARE @AktivesFeld	AS INTEGER
SET @AktivesFeld = 1--(
	--SELECT TOP 1 [SB].[Feld]
	--FROM [Infrastruktur].[Spielbrett]	AS [SB]
	--WHERE 1 = 1
	--	AND [SB].[IstSpielerWeiss] = 'TRUE'
	--	AND [SB].[FigurBuchstabe] = 'T'
	--)

SELECT * FROM [Spiel].[fncMoeglicheTurmschlaege] (
	'True'
	, @ASpielbrett
	, @AktivesFeld)
ORDER BY 2,3,4,5,7

GO
*/




