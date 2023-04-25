-- ###########################################################################################
-- ### Spiel der Koenige - Workshopversion ###################################################
-- ###########################################################################################
-- ### Erstellung der Funktion [Spiel].[fncIstFeldUnterBeschuss]                           ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Diese Funktion dient dazu herauszufinden, ob der Gegner die Moeglichkeit hat, in    ###
-- ### seinem naechsten Zug das angegebene Feld zu erreichen - worunter man sowohl einen   ###
-- ### Zug wie auch einen Schlag versteht. Auch dieser Funktion kann man einen beliebige   ###
-- ### (auch virtuelle) Stellung als Parameter zufuehren - es muss nicht der Inhalt von    ###
-- ### [Infrastruktur].[Spielbrett] sein.                                                  ###
-- ###                                                                                     ###
-- ### Benutzt wird diese Funktion bspw. um festzustellen, ob jemand "im Schach" steht     ###
-- ### oder ob eine Rochade durchgeführt werden darf (die ja nicht ueber durch den Gegener ###
-- ### beherrschte Felder fuehren darf).                                                   ###
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
-- ###     1.00.0	2022-02-04	Torsten Ahlemeyer                                          ###
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

USE [arelium_TSQL_Schach_V012]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- ######################################################################################
-- ###                                                            ###
-- ######################################################################################

CREATE OR ALTER FUNCTION [Spiel].[fncIstFeldUnterBeschuss]
(
	  @Bewertungsstellung	AS typStellung			READONLY
	, @AbfrageFeld			AS INTEGER								-- welches Feld wird angegriffen?
	, @IstSpielerWeiss		AS BIT									-- gemeint ist der Spieler, der das Feld bedroht
)
RETURNS BIT
AS
BEGIN
	DECLARE @Ergebnis		AS BIT
	IF EXISTS
		(
			SELECT [Innen].[TheoretischeAktionenID]
			FROM [Infrastruktur].[TheoretischeAktionen]		AS [Innen]
			INNER JOIN [Infrastruktur].[Figur]				AS [Figur]
				ON 1 = 1
					AND [Innen].[FigurName]			= [Figur].[FigurName]
					AND [Innen].[IstSpielerWeiss]	= [Figur].[IstSpielerWeiss]
			INNER JOIN @Bewertungsstellung
					AS [InnenSB]
				ON [Innen].[StartFeld] = [InnenSB].[Feld]
			WHERE 1 = 1
				AND [Figur].[FigurUTF8]					= [InnenSB].[FigurUTF8]
				AND [Innen].[ZielFeld]					= @AbfrageFeld
				AND [Innen].[IstSpielerWeiss]			= @IstSpielerWeiss
				AND 
					-- Wenn auf dem Zielfeld eine Figur steht, dann
					-- werden nur "Schläge" genutzt - sonst "Züge"
					(
						(
							(
							SELECT COUNT(*)
							FROM @Bewertungsstellung
								AS [Dummy]
							WHERE 1 = 1
								AND [Dummy].[Feld]			= @AbfrageFeld
								AND [Dummy].[FigurUTF8]		= 160
							) = 0
							AND 
							(
								[Innen].[ZugIstSchlag] = 'FALSE'
							)
						)
						OR
						(
							(
							SELECT COUNT(*)
							FROM @Bewertungsstellung
								AS [Dummy]
							WHERE 1 = 1
								AND [Dummy].[Feld]			= @AbfrageFeld
								AND [Dummy].[FigurUTF8]		<> 160
							) <> 0
							AND 
							(
								[Innen].[ZugIstSchlag] = 'TRUE'
							)
						)
					)

					AND

					(
						(
							[Innen].[Richtung]			= 'LU'
							AND ([Innen].[FigurName]	= 'Laeufer' OR [Innen].[FigurName]	= 'Dame')
							AND 
							(
								SELECT COUNT([Feld])
								FROM @Bewertungsstellung
									AS [Dummy]
								WHERE 1 = 1
									AND [Dummy].[Reihe]									< [Innen].[StartReihe]
									AND [Dummy].[Spalte]								< [Innen].[StartSpalte]
									AND [Dummy].[Reihe]									> [Innen].[ZielReihe]
									AND [Dummy].[Spalte]								> [Innen].[ZielSpalte]
									AND ABS([Dummy].[Reihe] - [Innen].[StartReihe])		= ABS(ASCII([Dummy].[Spalte]) - ASCII([Innen].[StartSpalte]))
									AND [Dummy].[FigurUTF8]								= 160
							)	= (ABS([Innen].[ZielReihe] - [Innen].[StartReihe]) - 1)
						)
						OR
						(
							[Innen].[Richtung]			= 'LO'
							AND ([Innen].[FigurName]	= 'Laeufer' OR [Innen].[FigurName]	= 'Dame')
							AND 
							(
								SELECT COUNT([Feld])
								FROM @Bewertungsstellung
									AS [Dummy]
								WHERE 1 = 1
									AND [Dummy].[Reihe]									> [Innen].[StartReihe]
									AND [Dummy].[Spalte]								< [Innen].[StartSpalte]
									AND [Dummy].[Reihe]									< [Innen].[ZielReihe]
									AND [Dummy].[Spalte]								> [Innen].[ZielSpalte]
									AND ABS([Dummy].[Reihe] - [Innen].[StartReihe])		= ABS(ASCII([Dummy].[Spalte]) - ASCII([Innen].[StartSpalte]))
									AND [Dummy].[FigurUTF8]								= 160
							)	= (ABS([Innen].[ZielReihe] - [Innen].[StartReihe]) - 1)
						)
						OR
						(
							[Innen].[Richtung]			= 'RO'
							AND ([Innen].[FigurName]	= 'Laeufer' OR [Innen].[FigurName]	= 'Dame')
							AND 
							(
								SELECT COUNT([Feld])
								FROM @Bewertungsstellung
									AS [Dummy]
								WHERE 1 = 1
									AND [Dummy].[Reihe]									> [Innen].[StartReihe]
									AND [Dummy].[Spalte]								> [Innen].[StartSpalte]
									AND [Dummy].[Reihe]									< [Innen].[ZielReihe]
									AND [Dummy].[Spalte]								< [Innen].[ZielSpalte]
									AND ABS([Dummy].[Reihe] - [Innen].[StartReihe])		= ABS(ASCII([Dummy].[Spalte]) - ASCII([Innen].[StartSpalte]))
									AND [Dummy].[FigurUTF8]								= 160
							)	= (ABS([Innen].[ZielReihe] - [Innen].[StartReihe]) - 1)
						)
						OR
						(
							[Innen].[Richtung]			= 'RU'
							AND ([Innen].[FigurName]	= 'Laeufer' OR [Innen].[FigurName]	= 'Dame')
							AND 
							(
								SELECT COUNT([Feld])
								FROM @Bewertungsstellung
									AS [Dummy]
								WHERE 1 = 1
									AND [Dummy].[Reihe]									< [Innen].[StartReihe]
									AND [Dummy].[Spalte]								> [Innen].[StartSpalte]
									AND [Dummy].[Reihe]									> [Innen].[ZielReihe]
									AND [Dummy].[Spalte]								< [Innen].[ZielSpalte]
									AND ABS([Dummy].[Reihe] - [Innen].[StartReihe])		= ABS(ASCII([Dummy].[Spalte]) - ASCII([Innen].[StartSpalte]))
									AND [Dummy].[FigurUTF8]								= 160
							)	= (ABS([Innen].[ZielReihe] - [Innen].[StartReihe]) - 1)
						)

						OR

						(
							[Innen].[Richtung]			= 'RE'
							AND ([Innen].[FigurName]	= 'Dame' OR [Innen].[FigurName]		= 'Turm')
							AND 
							(
								SELECT COUNT([Feld])
								FROM @Bewertungsstellung
									AS [Dummy]
								WHERE 1 = 1
									AND [Dummy].[Reihe]									= [Innen].[StartReihe]
									AND [Dummy].[Spalte]								> [Innen].[StartSpalte]
									AND [Dummy].[Spalte]								< [Innen].[ZielSpalte]
									AND [Dummy].[FigurUTF8]								= 160
							)	= (ABS(ASCII([Innen].[ZielSpalte]) - ASCII([Innen].[StartSpalte])) - 1)
						)
						OR
						(
							[Innen].[Richtung]			= 'LI'
							AND ([Innen].[FigurName]	= 'Dame' OR [Innen].[FigurName]		= 'Turm')
							AND 
							(
								SELECT COUNT([Feld])
								FROM @Bewertungsstellung
									AS [Dummy]
								WHERE 1 = 1
									AND [Dummy].[Reihe]									= [Innen].[StartReihe]
									AND [Dummy].[Spalte]								< [Innen].[StartSpalte]
									AND [Dummy].[Spalte]								> [Innen].[ZielSpalte]
									AND [Dummy].[FigurUTF8]								= 160
							)	= (ABS(ASCII([Innen].[ZielSpalte]) - ASCII([Innen].[StartSpalte])) - 1)
						)
						OR
						(
							[Innen].[Richtung]			= 'OB'
							AND ([Innen].[FigurName]	= 'Dame' OR [Innen].[FigurName]		= 'Turm')
							AND 
							(
								SELECT COUNT([Feld])
								FROM @Bewertungsstellung
									AS [Dummy]
								WHERE 1 = 1
									AND [Dummy].[Spalte]								= [Innen].[StartSpalte]
									AND [Dummy].[Reihe]									> [Innen].[StartReihe]
									AND [Dummy].[Reihe]									< [Innen].[ZielReihe]
									AND [Dummy].[FigurUTF8]								= 160
							)	= (ABS([Innen].[ZielReihe] - [Innen].[StartReihe]) - 1)
						)
						OR
						(
							[Innen].[Richtung]			= 'UN'
							AND ([Innen].[FigurName]	= 'Dame' OR [Innen].[FigurName]		= 'Turm')
							AND 
							(
								SELECT COUNT([Feld])
								FROM @Bewertungsstellung
									AS [Dummy]
								WHERE 1 = 1
									AND [Dummy].[Spalte]								= [Innen].[StartSpalte]
									AND [Dummy].[Reihe]									< [Innen].[StartReihe]
									AND [Dummy].[Reihe]									> [Innen].[ZielReihe]
									AND [Dummy].[FigurUTF8]								= 160
							)	= (ABS([Innen].[ZielReihe] - [Innen].[StartReihe]) - 1)
						)



						OR
						[Innen].[FigurName]	= 'Springer'

						OR

						[Innen].[FigurName]	= 'Bauer'
					)

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
DECLARE @Skript		VARCHAR(100)	= '050 - Funktion [Spiel].[fncistFeldUnterBeschuss] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO

/*
-- Test der Funktion [Spiel].[fncIstFeldUnterBeschuss]

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
	  [Spiel].[fncIstFeldUnterBeschuss] (@ASpielbrett, 39, 'TRUE')	
GO
*/
