-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### Measures for runtime optimisation                                                   ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### The chess computer must constantly evaluate, look up and aggregate data. This       ###
-- ### requires a lot of system resources and takes an uncomfortably long time. To shorten ###
-- ### runtimes, there are countermeasures such as indexing.                               ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Security note:                                                                      ###
-- ###    This collection of commands is used to create, alter oder drop objects or insert ###
-- ###    update or delete content. This script must NOT be used in productive             ###
-- ###    environments, to avoid accidental effects on other structures.                   ###
-- ###                                                                                     ###
-- ### Creation:                                                                           ###
-- ###   Torsten Ahlemeyer for arelium GmbH, (https://www.arelium.de)                      ###
-- ###   Contact: torsten.ahlemeyer@arelium.de                                             ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### A big thank you goes to (MVP) Uwe Ricken, who helped the project with motivation,   ###
-- ### advice and especially (but not only) in the area of runtime optimisation and        ###
-- ### continues to do so (https://www.db-berater.de/).                                    ###
-- ###                                                                                     ###
-- ### Another thank you goes to Ralph Kemperdick, who supports the project in an advisory ###
-- ### capacity. With his large network, especially in the Microsoft world, he makes many  ###
-- ### problem-solving approaches possible in the first place.                             ###
-- ###                                                                                     ###
-- ### Also extremely helpful is Buck Woody. The long-time Microsoft employee was          ###
-- ### persuaded by this project at a conference and has since supported it with his       ###
-- ### enormous reach and experience in adult education. Buck knows the perfect contacts   ###
-- ### to make the chess programme known worldwide.                                        ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Changelog:                                                                          ###
-- ###     15.00.0   2023-07-07 Torsten Ahlemeyer                                          ###
-- ###               Initial creation with default values                                  ###
-- ###########################################################################################
-- ### COPYRIGHT notice  (see https://creativecommons.org/licenses/by-nc-sa/3.0/de/)       ###
-- ###                    or https://creativecommons.org/licenses/by-nc-sa/3.0/de/deed.en) ###
-- ###########################################################################################
-- ### This work is licensed under the CC-BY-NC-SA licence, i.e. it may be freely          ###
-- ### downloaded, in any format or medium, and redistributed under the same licence       ###
-- ### conditions.                                                                         ###
-- ### However, commercial use is excluded. The work may be modified and you may base your ###
-- ### own projects on this code. Appropriate copyright and rights information must be     ###
-- ### provided, a link to the licence must be included and changes must be indicated.     ###
-- ###########################################################################################

--------------------------------------------------------------------------------------------------
-- Runtime statistics for this script ------------------------------------------------------------
--------------------------------------------------------------------------------------------------

-- Create a temporary table to remember the start time
BEGIN TRY
	DROP TABLE #Start
END TRY
BEGIN CATCH
END CATCH

CREATE TABLE #Start (StartTime DATETIME)
INSERT INTO #Start (StartTime) VALUES (GETDATE())

--------------------------------------------------------------------------------------------------
-- Compatibility block ---------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

-- Switch to the project database
USE [arelium_TSQL_Chess_V015]
GO

-- Specifies that the equal (=) and unequal (<>) comparison operators must behave in an 
-- ISO-compliant manner when used with NULL values in SQL Server 2019 (15.x).
-- ANSI NULLS ON is a new T-SQL standard and will be fixed in later versions.
SET ANSI_NULLS ON
GO

-- Causes SQL Server to obey the ISO rules for leading characters in identifiers and literal strings.
SET QUOTED_IDENTIFIER ON
GO


--------------------------------------------------------------------------------------------------
-- Clean-up --------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

DROP INDEX IF EXISTS [Infrastructure].[TheoreticalAction].[id_nc_Infrastructure_TheoreticalAction__FigureLetter]
GO

DROP INDEX IF EXISTS [Infrastructure].[TheoreticalAction].[id_nc_Infrastructure_TheoreticalAction__FigureLetter_plus]
GO

DROP INDEX IF EXISTS [Infrastructure].[TheoreticalAction].[id_nc_Infrastructure_TheoreticalAktion_FigureLetterIsPlayerWhiteStartFieldTargetFieldDirection_plus]
GO

--------------------------------------------------------------------------------------------------
-- Construction work -----------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------


CREATE NONCLUSTERED INDEX [id_nc_Infrastructure_TheoreticalAction__FigureLetter]
ON [Infrastructure].[TheoreticalAction] ([FigureLetter])
GO


CREATE NONCLUSTERED INDEX [id_nc_Infrastructure_TheoreticalAction__FigureLetter_plus]
ON [Infrastructure].[TheoreticalAction] ([FigureLetter])
INCLUDE ([IsPlayerWhite],[StartColumn],[StartRow],[StartField],[TargetColumn],[TargetRow],[TargetField],[Direction],[IsActionCapture],[LongNotation],[ShortNotationSimple],[ShortNotationComplex])
GO


CREATE NONCLUSTERED INDEX [id_nc_Infrastructure_TheoreticalAktion_FigureLetterIsPlayerWhiteStartFieldTargetFieldDirection_plus]
ON [Infrastructure].[TheoreticalAction] ([FigureLetter],[IsPlayerWhite],[StartField],[TargetField],[Direction])
INCLUDE ([TargetColumn])
