-- ###########################################################################################
-- ### arelium_TSQL_Schach_V014 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Erstellung der Funktion [AktuellesSpiel].[fncMoeglicheBauernaktionen]		       ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Moechte man herausfinden, welche Moeglichkeiten man in einer bestimmten Stellung    ###
-- ### hat die Figur "Bauer" zu ziehen, bemueht man diese Funktion. Sie erwartet die       ###
-- ### Angabe einer Stellung (dies muss nicht zwingend [Infrastruktur].[Spielbrett] sein!) ###
-- ### und des Feldes, fuer den die Bewegungs- und Schlagmoeglichkeiten abgefragt werden   ###
-- ### sollen. So sind Aussagen zu beliebigen Stellungen denkbar.                          ###
-- ###                                                                                     ###
-- ### Die Funktion gibt es in aehnlicher Ausfuehrung auch fuer die anderen Figuren. Wenn  ###
-- ### man die Rueckgaben fuer die Einzelaufrufe fuer alle Instanzen jeder Figur           ###
-- ### kombiniert, bekommt man eine vollstaendige Uebersicht alle moeglichen Fortsezungen. ###
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
USE [arelium_TSQL_Schach_V014]
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

CREATE OR ALTER FUNCTION [AktuellesSpiel].[fncMoeglicheBauernaktionen]
(
	   @IstSpielerWeiss		AS BIT
	 , @Bewertungsstellung	AS typStellung			READONLY
	 , @AktivesFeld			AS INTEGER
)
RETURNS @MoeglicheBauernaktionen TABLE 
	(
		  [TheoretischeAktionenID]		BIGINT			NOT NULL
		, [FigurBuchstabe]				CHAR(1)			NOT NULL
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
		, [LangeNotation]				VARCHAR(11)		NULL
		, [KurzeNotationEinfach]		VARCHAR(8)		NULL
		, [KurzeNotationKomplex]		VARCHAR(8)		NULL
	) AS
	BEGIN
		INSERT INTO @MoeglicheBauernaktionen
		(
			  [TheoretischeAktionenID]
			, [FigurBuchstabe]
			, [IstSpielerWeiss]
			, [StartSpalte]
			, [StartReihe]
			, [StartFeld]
			, [ZielSpalte]
			, [ZielReihe]
			, [ZielFeld]
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
		, [MZU].[FigurBuchstabe]								AS [FigurBuchstabe]			
		, [MZU].[IstSpielerWeiss]						AS [IstSpielerWeiss]	
		, [MZU].[StartSpalte]							AS [StartSpalte]
		, [MZU].[StartReihe]							AS [StartReihe]
		, [MZU].[StartFeld]								AS [StartFeld]
		, [MZU].[ZielSpalte]							AS [ZielSpalte]
		, [MZU].[ZielReihe]								AS [ZielReihe]
		, [MZU].[ZielFeld]								AS [ZielFeld]
		, [MZU].[Richtung]								AS [Richtung]
		, [MZU].[ZugIstSchlag]							AS [ZugIstSchlag]
		, [MZU].[ZugIstEnPassant]						AS [ZugIstEnPassant]
		, [MZU].[ZugIstKurzeRochade]					AS [ZugIstKurzeRochade]
		, [MZU].[ZugIstLangeRochade]					AS [ZugIstLangeRochade]
		, [MZU].[UmwandlungsfigurBuchstabe]				AS [UmwandlungsfigurBuchstabe]
		, [LangeNotation]								AS [LangeNotation]
		, [KurzeNotationEinfach]						AS [KurzeNotationEinfach]
		, [KurzeNotationKomplex]						AS [KurzeNotationKomplex]
	FROM [Infrastruktur].[TheoretischeAktionen]			AS [MZU] 
	INNER JOIN @Bewertungsstellung						AS [SPB]
		ON 1 = 1
			AND [MZU].[ZielReihe]				= [SPB].[Reihe]
			AND [MZU].[ZielSpalte]				= [SPB].[Spalte]
	WHERE 1 = 1
		AND [MZU].[IstSpielerWeiss]				= @IstSpielerWeiss
		AND [MZU].[FigurBuchstabe]				= 'B'
		AND [MZU].[StartFeld]					= @AktivesFeld
		AND 
			(
				(									-- normaler Zug, kein Schlag
					    [SPB].[FigurUTF8]		= 160	
					AND [MZU].[ZugIstSchlag]	= 'FALSE'
					AND 
						(							-- beim Doppelzug muss auch das Zwischenfeld 
													-- leer sein
							SELECT [BS].[FigurUTF8]
							FROM @Bewertungsstellung		AS [BS]
							WHERE 1 = 1
								AND (
										(			-- WEISS zieht nach oben
											[BS].[Feld] = [MZU].[StartFeld] + 1
											AND
											@IstSpielerWeiss	= 'TRUE'
										)
										OR 
										(			-- SCHWARZ zieht nach unten
											[BS].[Feld] = [MZU].[StartFeld] - 1
											AND
											@IstSpielerWeiss	= 'FALSE'
										)
									)
						) = 160
				)
				
				OR
				
				(
					    [SPB].[FigurUTF8]		<> 160	
					AND [MZU].[ZugIstSchlag]	= 'TRUE'
					AND 
						-- schlagen, aber nicht die eigenen Figuren
						[SPB].[FigurUTF8] NOT IN (SELECT [FigurUTF8] 
											FROM [Infrastruktur].[Figuren]  
											WHERE [IstSpielerWeiss] = @IstSpielerWeiss)
				)
			)

	UNION
	
	-- Sonderbereich fuer den "en passant"-Fall
		SELECT DISTINCT
		  [MZU].[TheoretischeAktionenID]				AS [TheoretischeAktionenID]
		, [MZU].[FigurBuchstabe]						AS [FigurBuchstabe]			
		, [MZU].[IstSpielerWeiss]						AS [IstSpielerWeiss]	
		, [MZU].[StartSpalte]							AS [StartSpalte]
		, [MZU].[StartReihe]							AS [StartReihe]
		, [MZU].[StartFeld]								AS [StartFeld]
		, [MZU].[ZielSpalte]							AS [ZielSpalte]
		, [MZU].[ZielReihe]								AS [ZielReihe]
		, [MZU].[ZielFeld]								AS [ZielFeld]
		, [MZU].[Richtung]								AS [Richtung]
		, [MZU].[ZugIstSchlag]							AS [ZugIstSchlag]
		, [MZU].[ZugIstEnPassant]						AS [ZugIstEnPassant]
		, [MZU].[ZugIstKurzeRochade]					AS [ZugIstKurzeRochade]
		, [MZU].[ZugIstLangeRochade]					AS [ZugIstLangeRochade]
		, [MZU].[UmwandlungsfigurBuchstabe]				AS [UmwandlungsfigurBuchstabe]
		, LEFT([MZU].[LangeNotation], 11)				AS [LangeNotation]
		, [MZU].[KurzeNotationEinfach]					AS [KurzeNotationEinfach]
		, [MZU].[KurzeNotationKomplex]					AS [KurzeNotationKomplex]
	FROM [Infrastruktur].[TheoretischeAktionen]			AS [MZU] 
	INNER JOIN @Bewertungsstellung						AS [SPB]
		ON 1 = 1
			AND [MZU].[ZielReihe]				= [SPB].[Reihe]
			AND [MZU].[ZielSpalte]				= [SPB].[Spalte]
	WHERE 1 = 1
		AND [MZU].[ZugIstEnPassant]				= 'TRUE'
		AND [MZU].[IstSpielerWeiss]				= @IstSpielerWeiss
		AND (
				(
					[MZU].[IstSpielerWeiss]			= 'TRUE'
					AND [MZU].[StartReihe]			= 5
					AND (EXISTS (SELECT * FROM @Bewertungsstellung AS [Innen] WHERE 1 = 1
									AND ASCII([SPB].[Spalte])		= ASCII([Innen].[Spalte]) + 1
									AND [Innen].[Reihe]				= 5
									AND [Innen].[FigurBuchstabe]	= 'B'
									AND [Innen].[IstSpielerWeiss]	= @IstSpielerWeiss
								)
						)
					AND (EXISTS (SELECT * FROM [AktuellesSpiel].[Notation] AS [Innen] WHERE 1 = 1
									AND SUBSTRING([Innen].[LangeNotation], 2, 1)	= '7'
									AND SUBSTRING([Innen].[LangeNotation], 5, 1)	= '5'
									AND [Innen].[IstSpielerWeiss]					= ((@IstSpielerWeiss + 1) % 2)
									AND [Innen].[VollzugID]							= (SELECT MAX([VollzugID]) FROM [AktuellesSpiel].[Notation] WHERE [IstSpielerWeiss] = ((@IstSpielerWeiss + 1) % 2))
								)
						)
				)
				OR
				(
					[MZU].[IstSpielerWeiss]			= 'TRUE'
					AND [MZU].[StartReihe]			= 5
					AND (EXISTS (SELECT * FROM @Bewertungsstellung AS [Innen] WHERE 1 = 1
									AND ASCII([SPB].[Spalte])		= ASCII([Innen].[Spalte]) - 1
									AND [Innen].[Reihe]				= 5
									AND [Innen].[FigurBuchstabe]	= 'B'
									AND [Innen].[IstSpielerWeiss]	= ((@IstSpielerWeiss + 1) % 2)
								)
						)
					AND (EXISTS (SELECT * FROM [AktuellesSpiel].[Notation] AS [Innen] WHERE 1 = 1
									AND SUBSTRING([Innen].[LangeNotation], 2, 1)	= '7'
									AND SUBSTRING([Innen].[LangeNotation], 5, 1)	= '5'
									AND [Innen].[IstSpielerWeiss]					= ((@IstSpielerWeiss + 1) % 2)
									AND [Innen].[VollzugID]							= (SELECT MAX([VollzugID]) FROM [AktuellesSpiel].[Notation] WHERE [IstSpielerWeiss] = ((@IstSpielerWeiss + 1) % 2))
								)
						)
				)
			OR
				(
					[MZU].[IstSpielerWeiss]			= 'FALSE'
					AND [MZU].[StartReihe]			= 4
					AND (EXISTS (SELECT * FROM @Bewertungsstellung AS [Innen] WHERE 1 = 1
									AND ASCII([SPB].[Spalte])		= ASCII([Innen].[Spalte]) + 1
									AND [Innen].[Reihe]				= 4
									AND [Innen].[FigurBuchstabe]	= 'B'
									AND [Innen].[IstSpielerWeiss]	= ((@IstSpielerWeiss + 1) % 2)
								)
						)
					AND (EXISTS (SELECT * FROM [AktuellesSpiel].[Notation] AS [Innen] WHERE 1 = 1
									AND SUBSTRING([Innen].[LangeNotation], 2, 1)	= '2'
									AND SUBSTRING([Innen].[LangeNotation], 5, 1)	= '4'
									AND [Innen].[IstSpielerWeiss]					= ((@IstSpielerWeiss + 1) % 2)
									AND [Innen].[VollzugID]							= (SELECT MAX([VollzugID]) FROM [AktuellesSpiel].[Notation] WHERE [IstSpielerWeiss] = ((@IstSpielerWeiss + 1) % 2))
								)
						)
				)
				OR
				(
					[MZU].[IstSpielerWeiss]			= 'FALSE'
					AND [MZU].[StartReihe]			= 4
					AND (EXISTS (SELECT * FROM @Bewertungsstellung AS [Innen] WHERE 1 = 1
									AND ASCII([SPB].[Spalte])		= ASCII([Innen].[Spalte]) + 1
									AND [Innen].[Reihe]				= 4
									AND [Innen].[FigurBuchstabe]	= 'B'
									AND [Innen].[IstSpielerWeiss]	= ((@IstSpielerWeiss + 1) % 2)
								)
						)
					AND (EXISTS (SELECT * FROM [AktuellesSpiel].[Notation] AS [Innen] WHERE 1 = 1
									AND SUBSTRING([Innen].[LangeNotation], 2, 1)	= '2'
									AND SUBSTRING([Innen].[LangeNotation], 5, 1)	= '4'
									AND [Innen].[IstSpielerWeiss]					= ((@IstSpielerWeiss + 1) % 2)
									AND [Innen].[VollzugID]							= (SELECT MAX([VollzugID]) FROM [AktuellesSpiel].[Notation] WHERE [IstSpielerWeiss] = ((@IstSpielerWeiss + 1) % 2))
								)
						)
				)
			)				
		AND [MZU].[StartFeld]					= @AktivesFeld

	RETURN
	END
GO			



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '046 - Funktion [AktuellesSpiel].[fncMoeglicheBauernaktionen] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO

/*
-- Test der Funktion [AktuellesSpiel].[fncMoeglicheBauernaktionen]

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
SET @AktivesFeld = (
	SELECT TOP 1 [SB].[Feld]
	FROM [Infrastruktur].[Spielbrett]	AS [SB]
	WHERE 1 = 1
		AND [SB].[IstSpielerWeiss] = 'TRUE'
		AND [SB].[FigurBuchstabe] = 'B'
	)

SELECT * FROM [AktuellesSpiel].[fncMoeglicheBauernaktionen] (
	'True'
	, @ASpielbrett
	, @AktivesFeld)
ORDER BY 2,3,4,5,7
GO
*/
