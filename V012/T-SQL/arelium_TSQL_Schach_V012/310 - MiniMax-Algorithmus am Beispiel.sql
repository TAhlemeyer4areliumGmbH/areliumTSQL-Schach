-- ###########################################################################################
-- ### arelium_TSQL_Schach_V012 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Beispielimplementation des MinMaxAlgorithmus                                        ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Im Schach planen fortgeschrittene Spieler ihre Aktionen fuer einige Zuege im        ###
-- ### Voraus. In einigen Situationen ist ein kurzfristiges Absenken der                   ###
-- ### Stellungsbewertung auch in einem drastischen Masse durchaus akzeptabel, bspw. bei   ###
-- ### einem Damenopfer, welches aber kurze Zeit spaeter ein Matt ermoeglicht.             ###
-- ###                                                                                     ###
-- ### Um jetzt ausgehend von der aktuellen Stellung auch Spielsituationen in einigen      ###
-- ### Zuegen Entfernung beurteilen zu koennen, wird der minimax-Algorithmus eingesetzt.   ###
-- ### Siehe: https://de.wikipedia.org/wiki/Minimax-Algorithmus                            ###
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


--------------------------------------------------------------------------------------------------
-- Kompatiblitaetsblock --------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
USE [arelium_TSQL_Schach_V012]
GO

-- Gibt an, dass sich die Vergleichsoperatoren Gleich (=) und Ungleich (<>) bei Verwendung mit NULL-Werten in SQL Server 2019 (15.x) ISO-konform verhalten muessen.
-- ANSI NULLS ON ist neuer T-SQL Standard und wird in spaeteren Versionen festgeschrieben.
SET ANSI_NULLS ON
GO

-- Bewirkt, dass SQL Server die ISO-Regeln fuer Anfuehrungszeichen bei Bezeichnern und Literalzeichenfolgen befolgt.
SET QUOTED_IDENTIFIER ON
GO


DROP TABLE IF EXISTS [Spiel].[Suchbaum]
GO

CREATE TABLE [Spiel].[Suchbaum](
      [ID]						[bigint]		NOT NULL
    , [VorgaengerID]			[bigint]		NULL
		CONSTRAINT FK_Suchbaum_Suchbaum FOREIGN KEY ([VorgaengerID]) REFERENCES [Spiel].[Suchbaum] ([ID])
    , [Halbzug]					[tinyint]		NOT NULL
    , [TheoretischeAktionID]	[bigint]		NOT NULL
    , [StellungID]				[bigint]		NOT NULL
    , [Bewertung]				[float]			NULL
    , [IstNochImFokus]			[bit]			NOT NULL
CONSTRAINT [PK_Suchbaum] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


/*
jeder Kasten stellt einen potentiellen Zug dar. Links im Kasten steht die Stellungsbewertung, rechts 
daneben steht die ID des Kastens. Schwarz versucht die Stellunsgbewertung zu minimieren, WEISS diese 
zu maximieren. Kann WEISS matt setzen (#) wird dies mit +99 bewertet. Setzt SCHWARZ matt (-#) mit -99

Im ersten Schritt wird die Datenstruktur in Form der Tabelle [Spiel].[Suchbaum] aufgebaut. Die 
einzelnen Kaesten werden dabei von oben nach unten (nach Suchtiefe) und von links nach rechts 
durchnummeriert.

Zu jeder Stellung wird dann ermittelt, wieviele moegliche Fortsetzungen es gibt. Der jeweils ermittelte 
Zug wird aus der Tabelle [Infrastruktur].[TheoretischeAktionen] notiert und der Suchbaum wird 
entsprechend bis zur maximalen Suchtiefe (hier 4 Halbzuege = 2 Zuege pro Spieler) ausgebaut. Die Bewertung 
der einzelnen Stellungen wird erst spaeter und nur fuer ausgewaehlte Stellungen durchgefuehrt!
                                                         
                                                      ???????
                                                      ? ?| 1?                                                aktuelle Position
                                                      ???????
                       ??????????????????????????????????????????????????????                                Zug von WEISS
                    ???????                           ???????            ???????
                    ? ?| 2?                           ? ?| 3?            ? ?| 4?                             1. Halbzug (nach Zug WEISS)
                    ???????                           ???????            ???????
         ??????????????????????????????????              ?          ??????????????????                       Zug von SCHWARZ
      ???????       ???????            ???????        ???????    ???????          ???????
      ? ?| 5?       ? ?| 6?            ? ?| 7?        ? ?| 8?    ? ?| 9?          ? ?|10?                    2. Halbzug (nach Zug SCHWARZ)
      ???????       ???????            ???????        ???????    ???????          ???????
         ?       ?????????????            ?        ?????????????               ?????????????                 Zug von WEISS
      ??????? ???????     ???????      ???????  ???????     ???????         ???????     ???????
      ? ?|11? ? ?|12?     ? ?|13?      ? ?|14?  ? ?|15?     ? ?|16?         ? ?|17?     ? ?|18?              3. Halbzug (nach Zug WEISS)
      ??????? ???????     ???????      ???????  ???????     ???????         ???????     ???????
    ???????????        ????????????????????        ?       ?????????       ?????????       ?                 Zug von SCHWARZ
 ???????   ???????  ???????   ???????  ???????  ??????? ??????? ??????? ??????? ??????? ???????
 ? ?|19?   ? ?|20?  ? ?|21?   ? ?|22?  ? ?|23?  ? ?|24? ? ?|25? ? ?|26? ? ?|27? ? ?|28? ? ?|29?              4. Halbzug (nach Zug SCHWARZ)
 ???????   ???????  ???????   ???????  ???????  ??????? ??????? ??????? ??????? ??????? ???????

*/

INSERT INTO [Spiel].[Suchbaum]
           ([ID], [VorgaengerID], [Halbzug], [TheoretischeAktionID], [StellungID], [Bewertung], [IstNochImFokus])
     VALUES
             (    1,  NULL, 0,  1234,  1,  NULL  , 'FALSE')

           , (    2,     1, 1,   773,  2,  NULL  , 'TRUE')
           , (    3,     1, 1,    23,  3,  NULL  , 'TRUE')
           , (    4,     1, 1,  4480,  4,  NULL  , 'TRUE')
                                                                                                                                                      
           , (    5,     2, 2,  2481,  5,  NULL  , 'TRUE')
           , (    6,     2, 2,  2482,  6,  NULL  , 'TRUE')
           , (    7,     2, 2,  1395,  7,  NULL  , 'TRUE')
           , (    8,     3, 2,  2481,  8,  NULL  , 'TRUE')
           , (    9,     4, 2,  2482,  9,  NULL  , 'TRUE')
           , (   10,     4, 2,  1395, 10,  NULL  , 'TRUE')
                                                                                                                                                          
           , (   11,     5, 3,  9035, 11,  NULL  , 'TRUE')
           , (   12,     6, 3,  6233, 12,  NULL  , 'TRUE')
           , (   13,     6, 3,  1220, 13,  NULL  , 'TRUE')
           , (   14,     7, 3, 10338, 14,  NULL  , 'TRUE')
           , (   15,     8, 3,  4722, 15,  NULL  , 'TRUE')
           , (   16,     8, 3,  4199, 16,  NULL  , 'TRUE')
           , (   17,    10, 3, 12310, 17,  NULL  , 'TRUE')
           , (   18,    10, 3,   667, 18,  NULL  , 'TRUE')
                                                                                                                                                           
           , (   19,    11, 4,  3025, 19,  NULL  , 'TRUE')
           , (   20,    11, 4,  2638, 20,  NULL  , 'TRUE')
           , (   21,    13, 4,  8722, 21,  NULL  , 'TRUE')
           , (   22,    13, 4, 10638, 22,  NULL  , 'TRUE')
           , (   23,    13, 4, 11384, 23,  NULL  , 'TRUE')
           , (   24,    15, 4,  3670, 24,  NULL  , 'TRUE')
           , (   25,    16, 4, 11221, 25,  NULL  , 'TRUE')
           , (   26,    16, 4,   477, 26,  NULL  , 'TRUE')
           , (   27,    17, 4,   638, 27,  NULL  , 'TRUE')
           , (   28,    17, 4, 12002, 28,  NULL  , 'TRUE')
           , (   29,    18, 4,   937, 29,  NULL  , 'TRUE')
GO


/*
nun werden von unten (hoechste Halbzugzahl) nach oben die Stellungen nach folgendem Schema bewertet:

- in der untersten Reihe (hoechste Halbzugzahl) werden alle Stellungen ueber die zueghoerige 
  Funktion (bspw [Spiel].[fncStellungBewerten]) bewertet. Die Ergebnisse werden jeweils in den 
  Kaesten dieser Ebene notiert
                                                      ???????
                                                      ? ?| 1?                                                aktuelle Position
                                                      ???????
                       ??????????????????????????????????????????????????????                                Zug von WEISS
                    ???????                           ???????            ???????
                    ? ?| 2?                           ? ?| 3?            ? ?| 4?                             1. Halbzug (nach Zug WEISS)
                    ???????                           ???????            ???????
         ??????????????????????????????????              ?          ??????????????????                       Zug von SCHWARZ
      ???????       ???????            ???????        ???????    ???????          ???????
      ? ?| 5?       ? ?| 6?            ? ?| 7?        ? ?| 8?    ? ?| 9?          ? ?|10?                    2. Halbzug (nach Zug SCHWARZ)
      ???????       ???????            ???????        ???????    ???????          ???????
         ?       ?????????????            ?        ?????????????               ?????????????                 Zug von WEISS
      ??????? ???????     ???????      ???????  ???????     ???????         ???????     ???????
      ? ?|11? ? ?|12?     ? ?|13?      ? ?|14?  ? ?|15?     ? ?|16?         ? ?|17?     ? ?|18?              3. Halbzug (nach Zug WEISS)
      ??????? ???????     ???????      ???????  ???????     ???????         ???????     ???????
    ???????????        ????????????????????        ?       ?????????       ?????????       ?                 Zug von SCHWARZ
 ???????   ???????  ???????   ???????  ???????  ??????? ??????? ??????? ??????? ??????? ???????
 ?-2|19?   ? 3|20?  ?-1|21?   ?-3|22?  ? 0|23?  ? 1|24? ? 1|25? ?-2|26? ?-#|27? ?12|28? ? 1|29?              4. Halbzug (nach Zug SCHWARZ)
 ???????   ???????  ???????   ???????  ???????  ??????? ??????? ??????? ??????? ??????? ???????

*/

UPDATE [Spiel].[Suchbaum] SET [Bewertung] =   -2 WHERE [ID] = 19
UPDATE [Spiel].[Suchbaum] SET [Bewertung] =    3 WHERE [ID] = 20
UPDATE [Spiel].[Suchbaum] SET [Bewertung] =   -1 WHERE [ID] = 21
UPDATE [Spiel].[Suchbaum] SET [Bewertung] =   -3 WHERE [ID] = 22
UPDATE [Spiel].[Suchbaum] SET [Bewertung] =    0 WHERE [ID] = 23
UPDATE [Spiel].[Suchbaum] SET [Bewertung] =    1 WHERE [ID] = 24
UPDATE [Spiel].[Suchbaum] SET [Bewertung] =    1 WHERE [ID] = 25
UPDATE [Spiel].[Suchbaum] SET [Bewertung] =   -2 WHERE [ID] = 26
UPDATE [Spiel].[Suchbaum] SET [Bewertung] =  -99 WHERE [ID] = 27
UPDATE [Spiel].[Suchbaum] SET [Bewertung] =   12 WHERE [ID] = 28
UPDATE [Spiel].[Suchbaum] SET [Bewertung] =    1 WHERE [ID] = 29

UPDATE [Spiel].[Suchbaum] SET [Bewertung] =    0 WHERE [ID] =  9
UPDATE [Spiel].[Suchbaum] SET [Bewertung] =  -99 WHERE [ID] = 12
UPDATE [Spiel].[Suchbaum] SET [Bewertung] =   99 WHERE [ID] = 14
GO

/*
nun werden von unten (hoechste Halbzugzahl) nach oben die Stellungen nach folgendem Schema bewertet:

- fuer jede weitere Ebene von unten nach oben gilt Folgendes:
  Die Bewertung findet NICHT ueber die Funktion [Spiel].[fncStellungBewerten] statt. Stattdessen werden 
  zur Bewertung alle an diesem Knoten haengenden direkten Nachfolger herangezogen. In unserem Fall
  haengen zum Beispiel die Knoten 21, 22 + 23 am Knoten 13. 

  - fuer WEISS gilt: es wird stets das MAXIMUM bzgl. der Stellungsbewertung der Nachfolger 
    uebernommen. Sollte es sich um einen Knoten ohne Nachfolger handeln, so lautet die 
                Stellungsbewertung entweder "+#" (Matt, 99 Punkte) oder "0" (Patt = ½, Punkteteilung). Steht 
                SCHWARZ nach diesem Zug im Schach, handelt es sich um Matt, sonst um Patt.
  - fuer SCHWARZ gilt: es wird stets das MINIMUM bzgl. der Stellungsbewertung der Nachfolger 
    uebernommen. Sollte es sich um einen Knoten ohne Nachfolger handeln, so lautet die 
                Stellungsbewertung entweder "-#" (Matt, -99 Punkte) oder "0" (Patt = ½, Punkteteilung). Steht 
                WEISS nach diesem Zug im Schach, handelt es sich um Matt, sonst um Patt.

                                                      ???????
                                                      ? 1| 1?                                                aktuelle Position
                                                      ???????
                       ??????????????????????????????????????????????????????                                Zug von WEISS
                    ???????                           ???????            ???????
                    ?-3| 2?                           ? 1| 3?            ? 0| 4?                             1. Halbzug (nach Zug WEISS)
                    ???????                           ???????            ???????
         ??????????????????????????????????              ?          ??????????????????                       Zug von SCHWARZ
      ???????       ???????            ???????        ???????    ???????          ???????
      ?-2| 5?       ?-3| 6?            ?+#| 7?        ? 1| 8?    ? 0| 9?          ? 1|10?                    2. Halbzug (nach Zug SCHWARZ)
      ???????       ???????            ???????        ???????    ???????          ???????
         ?       ?????????????            ?        ?????????????               ?????????????                 Zug von WEISS
      ??????? ???????     ???????      ???????  ???????     ???????         ???????     ???????
      ?-2|11? ?-#|12?     ?-3|13?      ?+#|14?  ? 1|15?     ?-2|16?         ?-#|17?     ? 1|18?              3. Halbzug (nach Zug WEISS)
      ??????? ???????     ???????      ???????  ???????     ???????         ???????     ???????
    ???????????        ????????????????????        ?       ?????????       ?????????       ?                 Zug von SCHWARZ
 ???????   ???????  ???????   ???????  ???????  ??????? ??????? ??????? ??????? ??????? ???????
 ?-2|19?   ? 3|20?  ?-1|21?   ?-3|22?  ? 0|23?  ? 1|24? ? 1|25? ?-2|26? ?-#|27? ?12|28? ? 1|29?              4. Halbzug (nach Zug SCHWARZ)
 ???????   ???????  ???????   ???????  ???????  ??????? ??????? ??????? ??????? ??????? ???????

*/

CREATE OR ALTER PROCEDURE [prcGuteAktionWaehlen]
  	  @AnziehenderSpielerIstWeiss	AS BIT
AS
BEGIN
	SET NOCOUNT ON;
       
	IF 
		(
			@AnziehenderSpielerIstWeiss             = 'TRUE' 
			AND
			(	SELECT MAX([Halbzug]) 
				FROM  [Spiel].[Suchbaum]
				WHERE [IstNochImFokus] = 'TRUE'
			) % 2 = 0
		)

		OR

		(
			@AnziehenderSpielerIstWeiss             = 'FALSE' 
			AND
			(	SELECT MAX([Halbzug]) 
				FROM  [Spiel].[Suchbaum]
				WHERE [IstNochImFokus] = 'TRUE'
			) % 2 = 1
		)
	BEGIN         -- WEISS versucht stets die Bewertung zu maximieren
        UPDATE [Spiel].[Suchbaum] 
        SET [Bewertung] =
            (
                SELECT MAX([Bewertung]) 
                FROM [Spiel].[Suchbaum] AS [Innen]
                WHERE 1 = 1
                    AND [Innen].[VorgaengerID] = 
                        (
                            SELECT MAX([VorgaengerID])
                            FROM [Spiel].[Suchbaum] 
                            WHERE 1 = 1
                                    AND [IstNochImFokus] = 'TRUE'
                                    AND [Bewertung] IS NOT NULL
                        )
            )
        WHERE 1 = 1
            AND [StellungID] = 
                (
                    SELECT MAX([VorgaengerID])
                    FROM [Spiel].[Suchbaum] 
                    WHERE [IstNochImFokus] = 'TRUE'
                )
    END
    ELSE
    BEGIN         -- SCHWARZ versucht stets die Bewertung zu minimieren
		UPDATE [Spiel].[Suchbaum] 
		SET [Bewertung] =
			(
				SELECT MIN([Bewertung]) 
				FROM [Spiel].[Suchbaum] AS [Innen]
				WHERE 1 = 1
					AND [Innen].[VorgaengerID] = 
						(
							SELECT MAX([VorgaengerID])
							FROM [Spiel].[Suchbaum] 
							WHERE 1 = 1
								AND [IstNochImFokus] = 'TRUE'
								AND [Bewertung] IS NOT NULL
						)
			)
		WHERE 1 = 1
			AND [StellungID] = 
				(
					SELECT MAX([VorgaengerID])
					FROM [Spiel].[Suchbaum] 
					WHERE [IstNochImFokus] = 'TRUE'
				)
	END

	-- Anschließend muessen die gerade abgearbeiteten Eintraege
	-- als "schon bearbeitet" markiert werden
	UPDATE [Spiel].[Suchbaum] 
	SET [IstNochImFokus] = 'FALSE'
	WHERE 1 = 1
		AND [VorgaengerID] = 
			(
				SELECT MAX([VorgaengerID])
				FROM [Spiel].[Suchbaum] 
				WHERE [IstNochImFokus] = 'TRUE'
			)
END
GO




DECLARE @AnziehenderSpielerIstWeiss bit
DECLARE @Suchtiefe tinyint

SET @Suchtiefe						= (SELECT MAX([Halbzug]) FROM [Spiel].[Suchbaum])
SET @AnziehenderSpielerIstWeiss		= 'TRUE'

WHILE @Suchtiefe >= 1
BEGIN
    WHILE (SELECT COUNT(*) FROM [Spiel].[Suchbaum] WHERE [IstNochImFokus] = 1) > 0
    BEGIN
        EXECUTE [dbo].[prcGuteAktionWaehlen] @AnziehenderSpielerIstWeiss
    END
    SET @Suchtiefe = @Suchtiefe - 1
END
GO
