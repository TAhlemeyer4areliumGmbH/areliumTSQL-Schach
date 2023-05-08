-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Inhalte initial einfuegen                                                           ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Dieses Skript fuellt die Tabellen mit initialen Werten. Hierbei handelt es sich     ###
-- ### hauptsaechlich um Nachschlagewerte, die bei jeder Partie identisch sind.            ###
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


-----------------------------
-- Aufbauarbeiten -----------
-----------------------------

-- Zuerst wird die Logo-Tabelle gefuellt. Man kann sich das Logo spaeter mit einem 
-- SELECT * FROM [Infrastruktur].[Logo] ansehen. Hierzu einfach auf den zusaetzlichen 
-- Reiter "spatial results" im Ergebnisbereich klicken.
-- Die Figuren werden durch die Angabe der Koordinaten gezeichnet, die direkt miteinander 
-- verbunden werden. Es muss ich um eine geschlossene Flaeche handeln!
TRUNCATE TABLE [Infrastruktur].[Logo] 
GO

INSERT INTO [Infrastruktur].[Logo] 
VALUES (N'Turm', geography::STGeomFromText( 
            'POLYGON((0 0, 0 2, 2 2, 2 4, 6 10, 6 20, 1 26, 1 32, 7 32, 7 28, 10 28, 10 32, 16 32
                                , 16 28, 19 28, 19 32, 25 32, 25 26, 20 20, 20 10, 24 4, 24 2, 26 2, 26 0, 0 0 
                        )'  
             -- Ab hier der Abschnitt "T-SQL", pro Zeile ein Zeichen
             + '    , (      28 18, 34 18, 34 17, 32 17, 32  9, 30  9, 30 17, 28 17, 28 18 ) 
                    , (      34 14, 38 14, 38 13, 34 13, 34 14 ) 
                    , (      40 18, 46 18, 46 17, 42 17, 42 14, 46 14, 46 9, 40 9, 40 10, 44 10, 44 13, 40 13, 40 18 ) 
                    , (      50 18, 56 18, 56 12, 54 12, 54 17, 52 17, 52 10, 54 10, 53 11, 54 12, 57 9, 56 8, 55 9, 54 9, 50  9, 50 18 ) 
                    , (      60 18, 62 18, 62 10, 66 10, 66 9, 60 9, 60 18 )'

			-- ab hier der Abschnitt "Schach", pro Zeile ein Buchstabe
			 + '
                    , (      36 6, 46 6, 46 4, 38 4, 38 0, 46 0, 46 -8, 36 -8, 36 -6, 44 -6, 44 -2, 36 -2, 36 6 ) 
                    , (      48 6, 58 6, 58 4, 50 4, 50 -6, 58 -6, 58 -8, 48 -8, 48 6 ) 
                    , (      60 6, 62 6, 62 0, 68 0, 68 6, 70 6, 70 -8, 68 -8, 68 -2, 62 -2, 62 -8, 60 -8, 60 6 ) 
                    , (      72 -8, 76 6, 78 6, 82 -8, 80 -8, 78 -3, 76 -3, 76 -2, 77.5 -2, 77 -1, 76 -1, 75 -3, 74 -8, 72 -8) 
                    , (      84 6, 94 6, 94 4, 86 4, 86 -6, 94 -6, 94 -8, 84 -8, 84 6 ) 
                    , (      96 6, 98 6, 98 0, 104 0, 104 6, 106 6, 106 -8, 104 -8, 104 -2, 98 -2, 98 -8, 96 -8, 96 6 ) 
             )' 
  ,4326) 
  );






-- Initiale Befuellung der Tabelle [Infrastruktur].[Figur]:
-- Je Figur sowie das Leerfeld werden mit ihrer UTF-8-ID, einer KLartextbezeichnung, 
-- einer Abkuerzung, einem grafischen Symbol und einem Punktwret einmal fuer WEISS und
-- einmal fuer SCHWARZ angelegt
-- --------------------------------------------
-- Hinweis: Der ASCII-Wert 160 entspricht einem geschuetzen Leerzeichen. Da der Bauer in der 
-- kuzen Notation keinen fuehrenden Buchstaben traegt, wird hier das normale Leerzeichen (32) 
-- genutzt. Folglich muss fuer das unbelegte Feld ein anderes Zeichen genommen werden.
INSERT INTO [Infrastruktur].[Figur] ([FigurUTF8], [IstSpielerWeiss], [FigurName], [FigurBuchstabe], [FigurSymbol], [FigurWert])
     VALUES (9812, 'TRUE',  'Koenig',			'K',		NCHAR(9812),  0)
	 ,		(9813, 'TRUE',  'Dame',				'D',		NCHAR(9813), 10)
	 ,		(9815, 'TRUE',  'Laeufer',			'L',		NCHAR(9815),  3)
	 ,		(9816, 'TRUE',  'Springer',			'S',		NCHAR(9816),  3)
	 ,		(9814, 'TRUE',  'Turm',				'T',		NCHAR(9814),  5)
	 ,		(9817, 'TRUE',  'Bauer',			'B',		NCHAR(9817),  1)
	 ,		( 160, NULL,	'unbelegtes Feld',	CHAR(160),	NCHAR(160) ,  0)
     ,		(9818, 'FALSE', 'Koenig',			'K',		NCHAR(9818),  0)
	 ,		(9819, 'FALSE', 'Dame',				'D',		NCHAR(9819), 10)
	 ,		(9821, 'FALSE', 'Laeufer',			'L',		NCHAR(9821),  3)
	 ,		(9822, 'FALSE', 'Springer',			'S',		NCHAR(9822),  3)
	 ,		(9820, 'FALSE', 'Turm',				'T',		NCHAR(9820),  5)
	 ,		(9823, 'FALSE', 'Bauer',			'B',		NCHAR(9823),  1)
GO


-- Initiale Befuellung der Tabelle [Infrastruktur].[Spielstaerke]:
-- Die einzelnen Level definieren sich durch die Frage, welche Kriterien fuer die 
-- Stellungsbewertung herangezogen werden sollen. Hier koennen jederzeit Ergaenzungen
-- in Form neuer Spalten (zusaetzliche Kriterien, dann bitte die zugehoerige Funktion
-- [Spiel].[fncStatistikauswertungen] anpassen!) oder Zeilen (neue Level) vorgenommen werden
INSERT INTO [Infrastruktur].[Spielstaerke]
           ( [SpielstaerkeID]
           , [Klartext]
		   , [GrossmeisterpartienAnzeigen]
           , [ZuberechnenSummeFigurWert]
           , [ZuberechnenAnzahlAktionen]
           , [ZuberechnenAnzahlSchlagmoeglichkeiten]
           , [ZuberechnenAnzahlRochaden]
           , [ZuberechnenBauernvormarsch]
           , [ZuberechnenAnzahlFreibauern]
           , [ZuberechnenBauernkette])
     VALUES
             ( 1, 'Kindergarten',		0, 0,  0,  0,  0,  0,  0,  0)
           , ( 2, 'Kindergarten+',		1, 0,  0,  0,  0,  0,  0,  0)
		   , ( 3, 'Grundschule',		0, 1,  0,  0,  0,  0,  0,  0)
		   , ( 4, 'Grundschule+',		1, 1,  0,  0,  0,  0,  0,  0)
		   , ( 5, 'Sekundarstufe',		0, 1,  0,  0,  0,  0,  0,  0)
		   , ( 6, 'Sekundarstufe+',		1, 1,  0,  0,  0,  0,  0,  0)
		   , ( 7, 'Hobbyspielerin',		0, 1,  0,  1,  0,  0,  0,  0)
		   , ( 8, 'Hobbyspielerin+',	1, 1,  0,  1,  0,  0,  0,  0)
		   , ( 9, 'Kreisklasse',		0, 1,  1,  1,  1,  0,  0,  0)
		   , (10, 'Kreisklasse+',		1, 1,  1,  1,  1,  0,  0,  0)
		   , (11, 'Landesmeister',		0, 1,  1,  1,  1,  0,  1,  0)
		   , (12, 'Landesmeister+',		1, 1,  1,  1,  1,  0,  1,  0)
		   , (13, 'Weltmeisterin',		0, 1,  1,  1,  1,  1,  1,  1)
		   , (14, 'Weltmeisterin+',		1, 1,  1,  1,  1,  1,  1,  1)
GO








TRUNCATE TABLE [Statistik].[Stellungsbewertung]
GO

INSERT INTO [Statistik].[Stellungsbewertung]
           ([ID], [Label], [Weiss], [Schwarz], [Kommentar])
     VALUES
             (	1,	'Figurwert:'			,	40, 40, 'Summe der Werte noch aktiver Figuren je Farbe')
           , (	2,	'Anzahl Aktionen:'		,	20, 20, 'wieviele legale Zuege kann jede Farbe im naechsten Zug machen?')
           , (	3,	'Anzahl Schlaege:'		,	16, 16, 'wieviele Felder werden aktuell bedroht/geschuetzt?')
           , (	4,	'Anzahl Rochaden:'		,	 2,  2, 'Wieviele der zwei theoretischen Rochaden stehen grundsaetzlich (nicht nur aktuell) noch zur Verfuegung?')
           , (	5,	'Bauernvormarsch:'		,	 0,  0, 'Wie weit sind die eigenen Bauern schon vorgerueckt? Je weiter, je wertvoller...')
           , (	6,	'Anzahl Freibauern:'	,	 0,  0, 'Wieviele der eigenen Bauern sind Freibauern? Je mehr, je besser...')
           , (	7,	'Laenge Bauernketten:'	,	 8,  8, 'Sind Bauern in der Lage sich selber gegenseitig zu schuetzen?')
		   , (  8,  'Gesamtbewertung:'		, NULL,  0, 'posive Werte bedeuten ein Vorteil fuer Weiss, negative fuer Schwarz')
GO





------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '012 - Stammdaten initial einfuegen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO