-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Aufbau einer Vorgabestellung                                                        ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Dieses Skript leert das Spielfeld und baut alle Figuren eines Schachspiels derart   ###
-- ### auf, dass die laut Spielreglen einzunehmende Grundstellung erreicht wird.           ###
-- ###                                                                                     ###
-- ### Anschliessend wird einem Spieler ein Vorteil gewaehrt, indem dem Gegner eine Figur  ###
-- ### genommen wird. Dies ist in verschiedenen Schwierigkeitsstufen durchfuehrbar. Es     ###
-- ### beginnt mit einem minimalen Vorteil (Schwierigkeitsstufe 1) fuer einen a-Bauern     ###
-- ### und endet beim Entfernen der Dame.###
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

--------------------------------------------------------------------------------------------------
-- Aufbauarbeiten --------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

-- Die Prozedur nutzt die schon bestehende Prozedur [Infrastruktur].[prcGrunstellungAufbauen] und
-- loescht dann einzelne Figuren je nach Schwierigkeitsgrad wiexder heraus
CREATE OR ALTER PROCEDURE [Infrastruktur].[prcVorgabepartieAufbauen] 
	  @IstBenachteiligterSpielerWeiss		AS BIT
	, @Schwierigkeitsgrad					AS INTEGER
AS
BEGIN
	SET NOCOUNT ON;

	EXEC [Infrastruktur].[prcGrundstellungAufbauen]
	
	IF @Schwierigkeitsgrad = 1
	BEGIN
		-- ----------------------------------------------------
		-- Schwierigkeitsgrad 1: der a-Bauer wird entfernt
		-- ----------------------------------------------------
		UPDATE [Infrastruktur].[Spielbrett]	
		SET [FigurUTF8] = 160, [FigurBuchstabe] = ' ', [IstSpielerWeiss] = NULL
		WHERE 1 = 1
			AND [Spalte]	= 'A'
			AND [Reihe]		= CASE @IstBenachteiligterSpielerWeiss WHEN 'TRUE' THEN 2 ELSE 7 END
	END
	ELSE
	BEGIN
		IF @Schwierigkeitsgrad = 2
		BEGIN
			-- ----------------------------------------------------
			-- Schwierigkeitsgrad 2: der e-Bauer wird entfernt
			-- ----------------------------------------------------
			UPDATE [Infrastruktur].[Spielbrett]	
			SET [FigurUTF8] = 160, [FigurBuchstabe] = ' ', [IstSpielerWeiss] = NULL
			WHERE 1 = 1
				AND [Spalte]	= 'E'
				AND [Reihe]		= CASE @IstBenachteiligterSpielerWeiss WHEN 'TRUE' THEN 2 ELSE 7 END
		END
		ELSE
		BEGIN
			IF @Schwierigkeitsgrad = 3
			BEGIN
				-- ----------------------------------------------------
				-- Schwierigkeitsgrad 3: der b-Springer wird entfernt
				-- ----------------------------------------------------
				UPDATE [Infrastruktur].[Spielbrett]	
				SET [FigurUTF8] = 160, [FigurBuchstabe] = ' ', [IstSpielerWeiss] = NULL
				WHERE 1 = 1
					AND [Spalte]	= 'B'
					AND [Reihe]		= CASE @IstBenachteiligterSpielerWeiss WHEN 'TRUE' THEN 1 ELSE 8 END
			END
			ELSE
			BEGIN
				IF @Schwierigkeitsgrad = 4
				BEGIN
					-- ----------------------------------------------------
					-- Schwierigkeitsgrad 4: der g-Springer wird entfernt
					-- ----------------------------------------------------
					UPDATE [Infrastruktur].[Spielbrett]	
					SET [FigurUTF8] = 160, [FigurBuchstabe] = ' ', [IstSpielerWeiss] = NULL
					WHERE 1 = 1
						AND [Spalte]	= 'G'
						AND [Reihe]		= CASE @IstBenachteiligterSpielerWeiss WHEN 'TRUE' THEN 1 ELSE 8 END
				END
				ELSE
				BEGIN
					IF @Schwierigkeitsgrad = 5
					BEGIN
						-- ----------------------------------------------------
						-- Schwierigkeitsgrad 5: der c-Laeufer wird entfernt
						-- ----------------------------------------------------
						UPDATE [Infrastruktur].[Spielbrett]	
						SET [FigurUTF8] = 160, [FigurBuchstabe] = ' ', [IstSpielerWeiss] = NULL
						WHERE 1 = 1
							AND [Spalte]	= 'C'
							AND [Reihe]		= CASE @IstBenachteiligterSpielerWeiss WHEN 'TRUE' THEN 1 ELSE 8 END
					END
					ELSE
					BEGIN
						IF @Schwierigkeitsgrad = 6
						BEGIN
							-- ----------------------------------------------------
							-- Schwierigkeitsgrad 6: der f-Laeufer wird entfernt
							-- ----------------------------------------------------
							UPDATE [Infrastruktur].[Spielbrett]	
							SET [FigurUTF8] = 160, [FigurBuchstabe] = ' ', [IstSpielerWeiss] = NULL
							WHERE 1 = 1
								AND [Spalte]	= 'F'
								AND [Reihe]		= CASE @IstBenachteiligterSpielerWeiss WHEN 'TRUE' THEN 1 ELSE 8 END
						END
						ELSE
						BEGIN
							IF @Schwierigkeitsgrad = 6
							BEGIN
								-- ----------------------------------------------------
								-- Schwierigkeitsgrad 6: der a-Turm wird entfernt
								-- ----------------------------------------------------
								UPDATE [Infrastruktur].[Spielbrett]	
								SET [FigurUTF8] = 160, [FigurBuchstabe] = ' ', [IstSpielerWeiss] = NULL
								WHERE 1 = 1
									AND [Spalte]	= 'A'
									AND [Reihe]		= CASE @IstBenachteiligterSpielerWeiss WHEN 'TRUE' THEN 1 ELSE 8 END
							END
							ELSE
							BEGIN
								IF @Schwierigkeitsgrad = 7
								BEGIN
									-- ----------------------------------------------------
									-- Schwierigkeitsgrad 7: der h-Turm wird entfernt
									-- ----------------------------------------------------
									UPDATE [Infrastruktur].[Spielbrett]	
									SET [FigurUTF8] = 160, [FigurBuchstabe] = ' ', [IstSpielerWeiss] = NULL
									WHERE 1 = 1
										AND [Spalte]	= 'C'
										AND [Reihe]		= CASE @IstBenachteiligterSpielerWeiss WHEN 'TRUE' THEN 1 ELSE 8 END
								END
								ELSE
								BEGIN
									IF @Schwierigkeitsgrad = 8
									BEGIN
										-- ----------------------------------------------------
										-- Schwierigkeitsgrad 8: die Dame wird entfernt
										-- ----------------------------------------------------
										UPDATE [Infrastruktur].[Spielbrett]	
										SET [FigurUTF8] = 160, [FigurBuchstabe] = ' ', [IstSpielerWeiss] = NULL
										WHERE 1 = 1
											AND [Spalte]	= 'D'
											AND [Reihe]		= CASE @IstBenachteiligterSpielerWeiss WHEN 'TRUE' THEN 1 ELSE 8 END
									END
									ELSE
									BEGIN
										SELECT 'unbekannter Schwierigkeitsgrad - es wird die Grundstellung audfgebaut...'
									END
								END
							END
						END
					END
				END
			END
		END
	END
END
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '022 - Prozedur [Infrastruktur].[prcVorgabepartieAufbauen] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO





/*


-- Aufbau der Grundstellung:
-- Auf das leere Brett werden die einzelnen Figuren an ihre Startposition gesetzt. Dazu wird das 
-- passende Feld mit dem UTF-8-Wert der Spielfigur aktualisiert.

DECLARE @Schwierigkeitsgrad						AS INTEGER
DECLARE @IstBenachteiligterSpielerWeiss			AS BIT

SET @Schwierigkeitsgrad					= 3
SET @IstBenachteiligterSpielerWeiss		= 'TRUE'

EXEC [Infrastruktur].[prcVorgabepartieAufbauen] @IstBenachteiligterSpielerWeiss, @Schwierigkeitsgrad
GO

*/