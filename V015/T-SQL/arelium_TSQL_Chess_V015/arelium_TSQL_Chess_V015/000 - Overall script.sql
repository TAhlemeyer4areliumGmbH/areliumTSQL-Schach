-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### Overall script to automatically import all technical scripts one after the other    ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### This script creates a fully executable version of the chess application from        ###
-- ### downstream scripts that are called and executed according to their numbering.       ###
-- ###                                                                                     ###
-- ###               **********************************************                        ###
-- ###               ***     This script requires CMD mode!     ***                        ###
-- ###               **********************************************                        ###
-- ###                                                                                     ###
-- ### (in SSMS the subitem <SQLCMD Mode> must be activated in the menu item <Query>)      ###
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
-- List of scripts -------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

-- With CTRL-H you can call up the "Search and Replace" dialogue and adjust the storage path of the files throughout the script
-- My private test system:			D:**\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015
-- My professional test system:		C:**\arelium_Repos\areliumTSQL-Schach\V012\T-SQL\arelium_TSQL_Schach_V012

:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\002 - Create Database.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\010 - Build basic data structures.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\012 - Insert content initially.sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\031 - Procedure [Infrastructure].[prcInitialisationOfTheoreticalActions].sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\041 - Functions [CurrentGame].[fncPossibleActions_xxx].sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\042 - Function [CurrentGame].[fncIsPinnedByXXX].sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\043 - Procedure [CurrentGame].[prcPossibleActions].sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\083 - Function [CurrentGame].[fncIsNextMoveWhite].sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\084 - Function [Infrastructure].[fncCastlingPossibilities].sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\085 - Function [CurrentGame].[fncIsFieldThreatened].sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\086 - Function [CurrentGame].[fncIsMate].sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\110 - View [Infrastructure].[vLogo].sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\111 - View [CurrentGame].[vCapturedFigures].sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\112 - View [CurrentGame].[vDisplayNotation].sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\115 - Functions [Library].[fncCharIndexNG].sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\116 - Function [Infrastructure].[fncSecondsAsTimeFormatting].sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\117 - View [Library].[vPlayedBefore].sql"
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\119 - View [Infrastructure].[vDashboard].sql"		
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\500 - Function [CurrentGame].[prcInitialisation].sql"		
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\610 - Procedure [Infrastruktur].[prcImportEFN].sql"		
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\612 - Function [Infrastructure].[fncPosition2EFN].sql"		
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\614 - Function [Infrastructure].[fncEFN2Position].sql"		
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\620 - Procedure [Infrastructure].[prcSetUpBasicPosition].sql"		
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\708 - Procedure [CurrentGame].[prcMovePieces].sql"		
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\710 - Procedure [CurrentGame].[prcPerformAnAction].sql"		
:r "D:\Beruf\arelium\GitHub_global\areliumTSQL-Schach\V015\T-SQL\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015\800 - Indexing for runtime optimisation.sql"		






PRINT 'All scripts for the workshop <T-SQL Chess Computer> were successfully processed...'
GO