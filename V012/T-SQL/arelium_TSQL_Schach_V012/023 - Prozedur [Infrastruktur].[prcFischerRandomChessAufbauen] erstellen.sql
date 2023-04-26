-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Aufbau einer Partie Fischer-Random-Chess                                            ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Dieses Skript leert das Spielfeld und baut alle Figuren eines Schachspiels nach     ###
-- ### der Spielvariante Fischer-Random-Chess auf.                                         ###
-- ### (siehe https://de.wikipedia.org/wiki/Chess960)                                      ###
-- ###                                                                                     ###
-- ### Dabei werden die Figuren der Grundlinie bei beiden Spieler auf die selbe Art        ###
-- ### zufaellig miteinander vertauscht. Regeln:                                           ###
-- ### * Die weissen Bauern stehen auf ihren ueblichen Positionen.                         ###
-- ### * Alle uebrigen weissen Figuren stehen in der ersten Reihe.                         ###
-- ### * Der weisse König steht zwischen den weissen Tuermen.                              ###
-- ### * Ein weisser Laeufer steht auf einem weißen, der andere auf einem schwarzen Feld.  ###
-- ### * Die schwarzen Figuren werden entsprechend den weissen spiegelsymmetrisch          ###
-- ###   platziert. Steht zum Beispiel der weisse König auf f1, so wird der schwarze       ###
-- ###   Koenig auf f8 gestellt.                                                           ###
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
CREATE OR ALTER PROCEDURE [Infrastruktur].[prcFischerRandomChessAufbauen] 
AS
BEGIN
	SET NOCOUNT ON;

	EXEC [Infrastruktur].[prcGrundstellungAufbauen]

	DECLARE @ZufallsSpalte		AS CHAR(1)

	-- ----------------------------------------------------
	-- Alle Felder der Grundreihe(n) leeren
	-- ----------------------------------------------------
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 160, [FigurBuchstabe] = ' ', [IstSpielerWeiss] = NULL
	WHERE [Reihe] IN (1,8)

	-- ----------------------------------------------------
	-- linken Turm aufbauen
	-- ----------------------------------------------------
	-- die Spielregeln geben vor, dass der Koenig ZWISCHEN beiden Tuermen stehen
	-- soll. Demnach kann der linke Turm nur auf den Spalten A-F stehen.
	SET @ZufallsSpalte = (	SELECT TOP 1 [Spalte] FROM [Infrastruktur].[Spielbrett] 
								WHERE [Reihe] = 1 AND [FigurUTF8] = 160 AND [Spalte] < 'G'
								ORDER BY NEWID()
							)

	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9814 , [FigurBuchstabe] = 'T', [IstSpielerWeiss] = 'TRUE'
	WHERE	1 = 1
		AND [Reihe]		= 1
		AND [Spalte]	= @ZufallsSpalte

	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9820, [FigurBuchstabe] = 'T', [IstSpielerWeiss] = 'FALSE'
	WHERE	1 = 1
		AND [Reihe]		= 8
		AND [Spalte]	= @ZufallsSpalte

	-- ----------------------------------------------------
	-- rechter Turm
	-- ----------------------------------------------------
	-- die Spielregeln geben vor, dass der Koenig ZWISCHEN beiden Tuermen stehen
	-- soll. 
	SET @ZufallsSpalte = (	SELECT TOP 1 [Spalte] FROM [Infrastruktur].[Spielbrett] 
								WHERE [Reihe] = 1 AND [FigurUTF8] = 160 
								AND [Spalte] > (SELECT CHAR(ASCII([Spalte]) + 1) FROM [Infrastruktur].[Spielbrett]	
									WHERE [FigurUTF8] = 9814)
								ORDER BY NEWID()
							)

	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9814 , [FigurBuchstabe] = 'T', [IstSpielerWeiss] = 'TRUE'
	WHERE	1 = 1
		AND [Reihe]		= 1
		AND [Spalte]	= @ZufallsSpalte

	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9820, [FigurBuchstabe] = 'T', [IstSpielerWeiss] = 'FALSE'
	WHERE	1 = 1
		AND [Reihe]		= 8
		AND [Spalte]	= @ZufallsSpalte	UPDATE [Infrastruktur].[Spielbrett]	
	
	-- ----------------------------------------------------
	-- Koenig
	-- ----------------------------------------------------
	-- der Koenig steht laut Regeln zwischen den beiden Tuermen
	SET @ZufallsSpalte = (	SELECT TOP 1 [Spalte] FROM [Infrastruktur].[Spielbrett] 
								WHERE [Reihe] = 1 AND [FigurUTF8] = 160 
								AND [Spalte] BETWEEN 
												(SELECT CHAR(ASCII(MIN([Spalte])) + 1) FROM [Infrastruktur].[Spielbrett] WHERE [FigurUTF8] = 9814)
												AND 
												(SELECT CHAR(ASCII(MAX([Spalte])) - 1) FROM [Infrastruktur].[Spielbrett] WHERE [FigurUTF8] = 9814)
								ORDER BY NEWID()
							)

	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9812, [FigurBuchstabe] = 'K', [IstSpielerWeiss] = 'TRUE'
	WHERE	1 = 1
		AND [Reihe]		= 1
		AND [Spalte]	= @ZufallsSpalte

	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9818, [FigurBuchstabe] = 'K', [IstSpielerWeiss] = 'FALSE' 
	WHERE 1 = 1
		AND [Reihe]		= 8
		AND [Spalte]	= @ZufallsSpalte
		
	-- ----------------------------------------------------
	-- schwarzfeldriger Laeufer
	-- ----------------------------------------------------
	-- es gilt jeweils einen weissfeldrigen und einen schwarzfeldrigen Laeufer pro 
	-- Spieler zu besetzen
	
	SET @ZufallsSpalte = (	SELECT TOP 1 [Spalte] FROM [Infrastruktur].[Spielbrett] 
								WHERE [Reihe] = 1 AND [FigurUTF8] = 160 
								AND [Spalte] IN ('A', 'C', 'E', 'G')
								ORDER BY NEWID()
							)

	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9815, [FigurBuchstabe] = 'L', [IstSpielerWeiss] = 'TRUE'
	WHERE	1 = 1
		AND [Reihe]		= 1
		AND [Spalte]	= @ZufallsSpalte
	
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9821, [FigurBuchstabe] = 'L', [IstSpielerWeiss] = 'FALSE'
	WHERE	1 = 1
		AND [Reihe]		= 8
		AND [Spalte]	= @ZufallsSpalte

	-- ----------------------------------------------------
	-- weissfeldriger Laeufer
	-- ----------------------------------------------------
	-- es gilt jeweils einen weissfeldrigen und einen schwarzfeldrigen Laeufer pro 
	-- Spieler zu besetzen
	
	SET @ZufallsSpalte = (	SELECT TOP 1 [Spalte] FROM [Infrastruktur].[Spielbrett] 
								WHERE [Reihe] = 1 AND [FigurUTF8] = 160 
								AND [Spalte] IN ('B', 'D', 'F', 'H')
								ORDER BY NEWID()
							)

	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9815, [FigurBuchstabe] = 'L', [IstSpielerWeiss] = 'TRUE'
	WHERE	1 = 1
		AND [Reihe]		= 1
		AND [Spalte]	= @ZufallsSpalte
	
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9821, [FigurBuchstabe] = 'L', [IstSpielerWeiss] = 'FALSE'
	WHERE	1 = 1
		AND [Reihe]		= 8
		AND [Spalte]	= @ZufallsSpalte


	---- ----------------------------------------------------
	---- erster Springer 
	---- ----------------------------------------------------
	SET @ZufallsSpalte = (	SELECT TOP 1 [Spalte] FROM [Infrastruktur].[Spielbrett] 
								WHERE [Reihe] = 1 AND [FigurUTF8] = 160 
								ORDER BY NEWID()
							)

	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9816, [FigurBuchstabe] = 'S', [IstSpielerWeiss] = 'TRUE'
	WHERE	1 = 1
		AND [Reihe]		= 1
		AND [Spalte]	= @ZufallsSpalte
	
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9822, [FigurBuchstabe] = 'S', [IstSpielerWeiss] = 'FALSE'
	WHERE	1 = 1
		AND [Reihe]		= 8
		AND [Spalte]	= @ZufallsSpalte

	---- ----------------------------------------------------
	---- zweiter Springer 
	---- ----------------------------------------------------
	SET @ZufallsSpalte = (	SELECT TOP 1 [Spalte] FROM [Infrastruktur].[Spielbrett] 
								WHERE [Reihe] = 1 AND [FigurUTF8] = 160 
								ORDER BY NEWID()
							)

	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9816, [FigurBuchstabe] = 'S', [IstSpielerWeiss] = 'TRUE'
	WHERE	1 = 1
		AND [Reihe]		= 1
		AND [Spalte]	= @ZufallsSpalte
	
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9822, [FigurBuchstabe] = 'S', [IstSpielerWeiss] = 'FALSE'
	WHERE	1 = 1
		AND [Reihe]		= 8
		AND [Spalte]	= @ZufallsSpalte



	---- ----------------------------------------------------
	---- Dame
	---- ----------------------------------------------------
	SET @ZufallsSpalte = (	SELECT TOP 1 [Spalte] FROM [Infrastruktur].[Spielbrett] 
								WHERE [Reihe] = 1 AND [FigurUTF8] = 160 
								ORDER BY NEWID()
							)

	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9813, [FigurBuchstabe] = 'D', [IstSpielerWeiss] = 'TRUE'
	WHERE	1 = 1
		AND [Reihe]		= 1
		AND [Spalte]	= @ZufallsSpalte
	
	UPDATE [Infrastruktur].[Spielbrett]	
	SET [FigurUTF8] = 9819, [FigurBuchstabe] = 'D', [IstSpielerWeiss] = 'FALSE'
	WHERE	1 = 1
		AND [Reihe]		= 8
		AND [Spalte]	= @ZufallsSpalte
	
END
GO


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '023 - Prozedur [Infrastruktur].[prcFischerRandomChessAufbauen] erstellen.sql'
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

EXEC [Infrastruktur].[prcFischerRandomChessAufbauen]
GO

*/