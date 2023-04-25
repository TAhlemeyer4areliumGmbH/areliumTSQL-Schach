-- ###########################################################################################
-- ### Spiel der Koenige - Workshopversion ###################################################
-- ###########################################################################################
-- ### Erstellung der Prozedur [Bibliothek].[prcKurzeNotationAufbereiten]                  ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### In einer sogenannten "*.PGN"-Datei werden mehrere Schachpartien mit diversen        ###
-- ### Metaangaben sowie der kurzen Notation der gesamten Partie gespeichert.              ###
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

CREATE OR ALTER PROCEDURE [Bibliothek].[prcKurzeNotationAufbereiten]
(
	  @NotationsString		AS VARCHAR(MAX)
	, @PartiemetadatenID	AS BIGINT
)
AS
BEGIN
	DECLARE @Zaehler	AS INTEGER
	DECLARE @Start		AS INTEGER
	DECLARE @Ende		AS INTEGER
	SET @Zaehler = 1

	CREATE TABLE #KurzeNotationEinspaltig
	(
		  [PartiemetadatenID]	BIGINT			NOT NULL
		, [Zugnummer]			INTEGER			NOT NULL
		, [KompletteSpalte]		VARCHAR(24)		NOT NULL
		, [ZugWeiss]			VARCHAR(12)		NULL
		, [ZugSchwarz]			VARCHAR(12)		NULL
	)

	WHILE LEN(@NotationsString) > 0 AND @Zaehler < 10
	BEGIN
		SET @Start	= CHARINDEX('.', @NotationsString, 1) + 1
		SET @Ende	= CHARINDEX(CONVERT(VARCHAR(3), @Zaehler + 1) + '.',	@NotationsString, 1) - (LEN(CONVERT(VARCHAR(3), @Zaehler + 1)) +2)
		INSERT INTO #KurzeNotationEinspaltig ([PartiemetadatenID], [Zugnummer], [KompletteSpalte]) VALUES(@PartiemetadatenID, @Zaehler, (SELECT TRIM(SUBSTRING(@NotationsString, @Start, @Ende))))
		SET @Zaehler = @Zaehler + 1
		SET @NotationsString = TRIM(RIGHT(@NotationsString, (LEN(@NotationsString) - CHARINDEX(SUBSTRING(@NotationsString, @Start, @Ende), @NotationsString, 1) - LEN(SUBSTRING(@NotationsString, @Start, @Ende)))))
	END

	UPDATE #KurzeNotationEinspaltig
	SET [ZugWeiss]		= TRIM(LEFT([KompletteSpalte], CHARINDEX(' ', [KompletteSpalte])))

	UPDATE #KurzeNotationEinspaltig
	SET [ZugSchwarz]	= TRIM(RIGHT([KompletteSpalte], LEN([KompletteSpalte]) - LEN([ZugWeiss])))

	INSERT INTO [Bibliothek].[Grossmeisterpartien] ([PartiemetadatenID], [Zugnummer], [ZugWeiss], [ZugSchwarz])
	SELECT 
	  [PartiemetadatenID]
	, [Zugnummer]		
	, [ZugWeiss]
	, [ZugSchwarz]
	FROM #KurzeNotationEinspaltig

	DROP TABLE #KurzeNotationEinspaltig
END
GO			



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '203 - Prozedur [Bibliothek].[prcKurzeNotationAufbereiten] erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO
/*
EXEC [Bibliothek].[prcKurzeNotationAufbereiten]
	  @PartiemetadatenID	= 1
	, @NotationsString	= N'1.e4 d6 2.d4 Nf6 3.Nc3 g6 4.Nf3 Bg7 5.Be2 Nbd7 6.O-O O-O 7.e5 dxe5 8.dxe5 Ng49.e6 Nde5 10.Qxd8 Rxd8 11.Nxe5 Nxe5 12.Nb5 c6 13.Nc7 Rb8 14.f4 Ng4 15.Bxg4 Bd4+16.Kh1 Bb6 17.f5 Bxc7 18.fxg6 fxg6 19.Bh6 Be5 20.Rad1 Rxd1 21.Rxd1 Bd6 22.Rf1'

SELECT * FROM [Bibliothek].[Grossmeisterpartien]



*/
