-- ###########################################################################################
-- ### Spiel der Koenige - Workshopversion ###################################################
-- ###########################################################################################
-- ### Prozedur [Spiel].[prcAktionsvorschau]                                               ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Dieses Skript erstellt oder aendert eine Prozedur, die 9 der naechsten moeglichen   ###
-- ### Zuege auflistet. Es werden nur regelkonforme Fortsetzungsmoeglichkeiten             ###
-- ### aufgefuehrt. Sollte eine entsprechende Spielstufe eingestellt sein, so ist die      ###
-- ### Liste entsprechend sortiert - die beste Variante steht oben. Ansonsten werden       ###
-- ### zufaellig 9 potentielle Zuege ausgewaehlt und in beliebiger Reihenfolge angezeigt.  ###
-- ###                                                                                     ###
-- ### Da in Views der "ORDER BY"-Befehl verboten ist, muss die Sortierung im Aufruf       ###
-- ### ausserhalb erfolgen. Hierzu stellt die Sicht eine zusaetzliche Spalte bereit, die   ###
-- ### nur der Sortierung dient und nicht angezeigt werden muss!                           ###
-- ###                                                                                     ###
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
-- ###     1.00.0	2022-04-19	Torsten Ahlemeyer                                          ###
-- ###              Initiale Erstellung                                                    ###
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

USE [Workshop_SpielDerKoenige_V004]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





-- ######################################################################################
-- ### Sichten erstellen                                                              ###
-- ######################################################################################

CREATE OR ALTER PROCEDURE [Spiel].[prcBrettansicht]
(
	  @Bewertungsstellung			AS typStellung			READONLY
	, @IstNaechsterSpielerWeiss		AS [BIT]
)
AS
BEGIN
	SET NOCOUNT ON;

	-- Der Spieler, der als naechstes am Zug ist, soll unten dargestellt werden.
	-- Wird das Spielbrett gedreht, aendert sich natuerlich auch die Reihenfolge der 
	-- Spalten und Zeilenbeschriftung. Daher ist hier eine Fallunterscheidung vorzunehmen.
	IF @IstNaechsterSpielerWeiss = 'TRUE'
	BEGIN
		SELECT 
			  9														AS [LinkID]
			, 0														AS [OrderNr]
			, ' '													AS [.]
			, 'A'													AS [ ]
			, 'B'													AS [ ]
			, 'C'													AS [ ]
			, 'D'													AS [ ]
			, 'E'													AS [ ]
			, 'F'													AS [ ]
			, 'G'													AS [ ]
			, 'H'													AS [ ]
			, ' '													AS [.]
		UNION
		SELECT
			  9 - ROW_NUMBER() OVER(ORDER BY [Reihe] ASC)
			, [Reihe]
			, CONVERT(CHAR(1), [Reihe])								
			, CASE WHEN [A] = 0 THEN ' ' ELSE NCHAR([A]) END		
			, CASE WHEN [B] = 0 THEN ' ' ELSE NCHAR([B]) END		
			, CASE WHEN [C] = 0 THEN ' ' ELSE NCHAR([C]) END		
			, CASE WHEN [D] = 0 THEN ' ' ELSE NCHAR([D]) END		
			, CASE WHEN [E] = 0 THEN ' ' ELSE NCHAR([E]) END		
			, CASE WHEN [F] = 0 THEN ' ' ELSE NCHAR([F]) END		
			, CASE WHEN [G] = 0 THEN ' ' ELSE NCHAR([G]) END		
			, CASE WHEN [H] = 0 THEN ' ' ELSE NCHAR([H]) END		
			, CONVERT(CHAR(1), [Reihe])								
		FROM
		(
			SELECT [Reihe], [A], [B], [C], [D], [E], [F], [G], [H]
			FROM  
			(	SELECT [Spalte], [Reihe], [FigurUTF8]
				FROM @Bewertungsstellung) AS SourceTable 
			PIVOT  
			(  
			MAX([FigurUTF8])  
			FOR [Spalte] IN ([A], [B], [C], [D], [E], [F], [G], [H])  
			) AS PivotTable  
		) AS aussen
		UNION
		SELECT 0, 9, ' ', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', ' '
		ORDER BY [OrderNr] DESC
	END

	ELSE

	BEGIN
		SELECT 
			  0														AS [LinkID]
			, 0														AS [OrderNr]
			, ' '													AS [.]
			, 'H'													AS [ ]
			, 'G'													AS [ ]
			, 'F'													AS [ ]
			, 'E'													AS [ ]
			, 'D'													AS [ ]
			, 'C'													AS [ ]
			, 'B'													AS [ ]
			, 'A'													AS [ ]
			, ' '													AS [.]
		UNION
		SELECT
			  ROW_NUMBER() OVER(ORDER BY [Reihe] ASC)
			, [Reihe]												
			, CONVERT(CHAR(1), [Reihe])								
			, CASE WHEN [A] = 0 THEN ' ' ELSE NCHAR([A]) END		
			, CASE WHEN [B] = 0 THEN ' ' ELSE NCHAR([B]) END		
			, CASE WHEN [C] = 0 THEN ' ' ELSE NCHAR([C]) END		
			, CASE WHEN [D] = 0 THEN ' ' ELSE NCHAR([D]) END		
			, CASE WHEN [E] = 0 THEN ' ' ELSE NCHAR([E]) END		
			, CASE WHEN [F] = 0 THEN ' ' ELSE NCHAR([F]) END		
			, CASE WHEN [G] = 0 THEN ' ' ELSE NCHAR([G]) END		
			, CASE WHEN [H] = 0 THEN ' ' ELSE NCHAR([H]) END		
			, CONVERT(CHAR(1), [Reihe])								
		FROM
		(
			SELECT [Reihe], [A], [B], [C], [D], [E], [F], [G], [H]
			FROM  
			(SELECT [Spalte], [Reihe], [FigurUTF8]
				FROM @Bewertungsstellung) AS SourceTable 
			PIVOT  
			(  
			MAX([FigurUTF8])  
			FOR [Spalte] IN ([A], [B], [C], [D], [E], [F], [G], [H])  
			) AS PivotTable  
		) AS aussen
		UNION
		SELECT 9, 9, ' ', 'H', 'G', 'F', 'E', 'D', 'C', 'B', 'A', ' '
		ORDER BY [OrderNr] ASC
	END

	RETURN
END
GO




------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '025 - Prozedur [Spiel].[prcBrettansicht] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO



/*
-- Test der Prozedur [Spiel].[prcAktionsvorschau] 

DECLARE @ASpielbrett	AS [dbo].[typStellung]
DECLARE @BSpielbrett	AS [dbo].[typSpielbrett]

INSERT INTO @ASpielbrett
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
	WHERE 1 = 1
		AND [SpielID] = 1

INSERT @BSpielbrett EXEC [Spiel].[prcBrettansicht] @ASpielbrett, 'TRUE'

SELECT * FROM @BSpielbrett
GO
*/
