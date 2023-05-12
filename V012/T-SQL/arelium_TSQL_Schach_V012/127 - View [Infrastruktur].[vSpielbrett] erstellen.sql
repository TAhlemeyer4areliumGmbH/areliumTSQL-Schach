-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### VIEW [Spiel].[vBrettansicht]                                                        ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Dieses Skript erstellt oder aendert eine Sicht, die ein Spielbrett mit der          ###
-- ### aktuellen Stellung grafisch abbildet.                                               ###
-- ###                                                                                     ###
-- ### Da in Views der "ORDER BY"-Befehl verboten ist, muss die Sortierung im Aufruf       ###
-- ### ausserhalb erfolgen. Hierzu stellt die Sicht eine zusaetzliche Spalte bereit, die   ###
-- ### nur der Sortierung dient und nicht angezeigt werden muss!                           ###
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

CREATE OR ALTER VIEW [Infrastruktur].[vSpielbrett]
AS
SELECT 
	  CASE 
		WHEN (SELECT COUNT(*) FROM [Spiel].[vTeilnotationAnzeigen]) = 0 THEN '' 
		ELSE ISNULL([LN].[VollzugID], '')
	  END 												AS [Zug#]
	, ISNULL([LN].ZugWEISS, '')							AS [ZugWeiss]
	, ISNULL([LN].ZugSCHWARZ, '')						AS [ZugSchwarz]
	, '|'												AS [?]
	, [SichtWeiss].[.]									AS [,.]
	, [SichtWeiss].[A]									AS [A.]
	, [SichtWeiss].[B]									AS [B.]
	, [SichtWeiss].[C]									AS [C.]
	, [SichtWeiss].[D]									AS [D.]
	, [SichtWeiss].[E]									AS [E.]
	, [SichtWeiss].[F]									AS [F.]
	, [SichtWeiss].[G]									AS [G.]
	, [SichtWeiss].[H]									AS [H.]
	, [SichtWeiss].[..]									AS [.]
	, '|'												AS [..]
	, CASE [SichtWeiss].[OrderNr]
		WHEN 1 THEN N'WEISS ' 
			+ CASE (SELECT [SpielstaerkeID] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = 'TRUE') WHEN 1 THEN '' ELSE '(Comp)'
			+ ':'
			END
		WHEN 2 THEN N'Restzeit:'
		WHEN 3 THEN N'50-Züge-Regel:'
		WHEN 4 THEN N'Zugrecht/-pflicht:'
		WHEN 5 THEN N'en-passant-Möglichkeit:'
		WHEN 6 THEN N'Bewertung:'
		WHEN 7 THEN N'50-Züge-Regel:'
		WHEN 8 THEN N'SCHWARZ'
			+ CASE (SELECT [SpielstaerkeID] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = 'FALSE') WHEN 1 THEN N'' ELSE '(Comp)'
			+ ':'
			END
		WHEN 9 THEN N'Restzeit:'
		ELSE ''
	END													AS [ ]
	, CASE [SichtWeiss].[OrderNr]
		WHEN 1 THEN (SELECT [Spielername] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = 'TRUE')
		WHEN 2 THEN [Infrastruktur].[fncSekundenAlsUhrzeitFormatieren]((SELECT [RestzeitInSekunden] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = 'TRUE'))
		WHEN 3 THEN (SELECT CONVERT(CHAR(3), [Anzahl50ZugRegel]) FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = 'TRUE')
		WHEN 4 THEN CASE [Spiel].[fncIstWeissAmZug]() WHEN 'TRUE' THEN 'WEISS' ELSE 'SCHWARZ' END
		WHEN 5 THEN ISNULL((SELECT [EnPassant] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = (([Spiel].[fncIstWeissAmZug]() + 1) % 2)), '')
		WHEN 6 THEN CONVERT(VARCHAR(8), [Statistik].[fncAktuelleStellungBewerten]())
		WHEN 7 THEN (SELECT CONVERT(CHAR(3), [Anzahl50ZugRegel]) FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = 'FALSE')
		WHEN 8 THEN (SELECT [Spielername] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = 'FALSE')
		WHEN 9 THEN [Infrastruktur].[fncSekundenAlsUhrzeitFormatieren]((SELECT [RestzeitInSekunden] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = 'FALSE'))
		ELSE ''
	END													AS [_]
	, '|'												AS [,,]
	, [SichtSchwarz].[.]								AS [,]
	, [SichtSchwarz].[H]								AS [H,]
	, [SichtSchwarz].[G]								AS [G,]
	, [SichtSchwarz].[F]								AS [F,]
	, [SichtSchwarz].[E]								AS [E,]
	, [SichtSchwarz].[D]								AS [D,]
	, [SichtSchwarz].[C]								AS [C,]
	, [SichtSchwarz].[B]								AS [B,]
	, [SichtSchwarz].[A]								AS [A,]
	, [SichtSchwarz].[..]								AS [.,]
	, ISNULL([GF].[geschlagene Figur(en)], '')			AS [geschlagene Figuren]
	, '|'												AS [;]
	, CASE (SELECT [ComputerSchritteAnzeigen] FROM [Spiel].[Konfiguration] WHERE [IstSpielerWeiss] = (([Spiel].[fncIstWeissAmZug]() + 1) % 2)) 
			WHEN 'TRUE' THEN ISNULL([MA].[LangeNotation], '')
			ELSE '---'									
		END												AS [Zugideen]
	, '|'												AS [:]
	, ISNULL([BE].[Label], '')							AS [Kriterium]
	, ISNULL([BE].[Weiss], '')							AS [Weiss]
	, CASE [BE].[Label] 
		WHEN 'Gesamtbewertung:' THEN FORMAT(CONVERT(FLOAT, ISNULL([BE].[Schwarz], '')), '0.0#')	
		ELSE ISNULL([BE].[Schwarz], '')
	   END												AS [Schwarz]
	, ISNULL([GMP].[Wert], '')							AS [Bibliothek]
FROM
	(
		-- Dies ist das Brett aus Sicht von WEISS
		-- Das PIVOT macht aus der langen Feldliste ein 8x8 Schachbrett. Da, wo die 
		-- Aggregation einen Wert <> 0 zurueckliefert, wird die passende Figur gemalt.
		-- Alle anderen Felder werden mit Leerzeichen gefuellt. Die Brettbeschriftung
		-- werden abhaengig von der Spielerfarbe generiert (WEISS = A-H und 8-1, 
		-- SCHWARZ = H-A und 1-8). Damit beide Bretter (und spaeter der Rest des 
		-- "Amaturenbrettes") ordentlich verjoint werden koennen, liefern die Unterabfragen
		-- jeweils eine [OrderNr], die in der Hauptabfrage nicht angezeigt wird
		SELECT
			  [ID]													AS [OrderNr]
			, CONVERT(CHAR(1), [Reihe])								AS [.]
			, CASE WHEN [A] = 0 THEN ' ' ELSE NCHAR([A]) END		AS [A]
			, CASE WHEN [B] = 0 THEN ' ' ELSE NCHAR([B]) END		AS [B]
			, CASE WHEN [C] = 0 THEN ' ' ELSE NCHAR([C]) END		AS [C]
			, CASE WHEN [D] = 0 THEN ' ' ELSE NCHAR([D]) END		AS [D]
			, CASE WHEN [E] = 0 THEN ' ' ELSE NCHAR([E]) END		AS [E]
			, CASE WHEN [F] = 0 THEN ' ' ELSE NCHAR([F]) END		AS [F]
			, CASE WHEN [G] = 0 THEN ' ' ELSE NCHAR([G]) END		AS [G]
			, CASE WHEN [H] = 0 THEN ' ' ELSE NCHAR([H]) END		AS [H]
			, CONVERT(CHAR(1), [Reihe])								AS [..]
		FROM
		(
			SELECT [Reihe], [A], [B], [C], [D], [E], [F], [G], [H]
			FROM  
			(SELECT [Spalte], [Reihe], [FigurUTF8]
				FROM [Infrastruktur].[Spielbrett]) AS SourceTable  
			PIVOT  
			(  
			MAX([FigurUTF8])  
			FOR [Spalte] IN ([A], [B], [C], [D], [E], [F], [G], [H])  
			) AS PivotTable  
		) AS aussen
		INNER JOIN (SELECT 8 AS [ID] UNION SELECT 7 UNION SELECT 6 UNION SELECT 5 UNION SELECT 4 UNION SELECT 3 UNION SELECT 2 UNION SELECT 1) AS [Umkehr]
			ON [Umkehr].[ID] = 9 - [Reihe]
		UNION
		SELECT 9, ' ', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', ' '
	) AS [SichtWeiss]

	INNER JOIN 

	(
		-- Dies ist das Brett aus Sicht von SCHWARZ
		SELECT 
			  [Reihe]												AS [OrderNr]
			, CONVERT(CHAR(1), [Reihe])								AS [.]
			, CASE WHEN [H] = 0 THEN ' ' ELSE NCHAR([H]) END		AS [H]
			, CASE WHEN [G] = 0 THEN ' ' ELSE NCHAR([G]) END		AS [G]
			, CASE WHEN [F] = 0 THEN ' ' ELSE NCHAR([F]) END		AS [F]
			, CASE WHEN [E] = 0 THEN ' ' ELSE NCHAR([E]) END		AS [E]
			, CASE WHEN [D] = 0 THEN ' ' ELSE NCHAR([D]) END		AS [D]
			, CASE WHEN [C] = 0 THEN ' ' ELSE NCHAR([C]) END		AS [C]
			, CASE WHEN [B] = 0 THEN ' ' ELSE NCHAR([B]) END		AS [B]
			, CASE WHEN [A] = 0 THEN ' ' ELSE NCHAR([A]) END		AS [A]
			, CONVERT(CHAR(1), [Reihe])								AS [..]
		FROM
		(
			SELECT [Reihe], [A], [B], [C], [D], [E], [F], [G], [H]
			FROM  
			(SELECT [Spalte], [Reihe], [FigurUTF8]
				FROM [Infrastruktur].[Spielbrett]) AS SourceTable  
			PIVOT  
			(  
			MAX([FigurUTF8])  
			FOR [Spalte] IN ([A], [B], [C], [D], [E], [F], [G], [H])  
			) AS PivotTable  
		) AS aussen
		UNION
		SELECT 9, ' ', 'H', 'G', 'F', 'E', 'D', 'C', 'B', 'A', ' '
	) AS [SichtSchwarz]
		ON [SichtWeiss].[OrderNr] = [SichtSchwarz].[OrderNr]

	-- hier wird nun die Uebersicht ueber die geschlagenen Figuren hinzugejoint
	-- Pro Farbe werden die Bauern und die sonstigen Figuren grafisch dargestellt
	LEFT JOIN [Spiel].[vGeschlageneFiguren] AS [GF]
		ON [GF].[ID] = [SichtWeiss].[OrderNr]

	-- hier werden nun zufaellig die ersten 9 erlaubten Zuege aus dieser Stellung
	-- heraus fuer den naechsten aktiven Spieler angezeigt
	--    (hierzu muss VORHER die Prozedur [Spiel].[prcAktionenFuerAktuelleStellungWegschreiben]
	--    korrekt aufgerufen worden sein!)
	LEFT JOIN 
		(
			SELECT TOP 9 
				  ROW_NUMBER() OVER(ORDER BY NEWID() ASC) AS [OrderNr]
				, *
			FROM [Spiel].[MoeglicheAktionen] 
		) AS [MA]
	ON [MA].[OrderNr] = [SichtWeiss].[OrderNr]

	-- Es werden nun noch die Bewertungen entsprechend der konfigurierten 
	-- Kriterien eingeblendet:
	LEFT JOIN 
		( 
			SELECT 
				  [ID]																			AS [ID]
				, [Label]																		AS [Label]
				,	CASE [Label]	
						WHEN 'Gesamtbewertung:' THEN ' '
						ELSE ISNULL(CONVERT(VARCHAR(10), [Weiss]), N' ')
					END																			AS [Weiss]
				, ISNULL(CONVERT(VARCHAR(10), [Schwarz])	, N' ')								AS [Schwarz]
			  FROM [Statistik].[Stellungsbewertung]
		) AS [BE]
	ON [SichtWeiss].[OrderNr] = [BE].[ID]

	-- Es wird nun noch der bisherige Partieverlauf in der langen Notation eingeblendet
	LEFT JOIN 
		( 
			SELECT
				  [OrderID]				AS [OrderID]
				, [VollzugID]			AS [VollzugID] 
				, [WEISS]				AS [ZugWEISS]
				, [SCHWARZ] 			AS [ZugSCHWARZ]
			FROM [Spiel].[vTeilnotationAnzeigen]
		) AS [LN]
	ON [SichtWeiss].[OrderNr] = [LN].[OrderID]

	-- Es wird nun noch in den Grossmeisterpartien nachgeschlagen, ob so eine Partie schonmal 
	-- gespielt wurde
	LEFT JOIN 
		( 
			SELECT
				  [Wert]				AS [Wert]
				  , [ID]				AS [ID]
			FROM [Bibliothek].[vSchonmalgespielt]
		) AS [GMP]
	ON [SichtWeiss].[OrderNr] = [GMP].[ID]
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '119 - Sicht [Infrastruktur].[vSpielbrett] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO


/*
SELECT * FROM [Infrastruktur].[vSpielbrett]


*/