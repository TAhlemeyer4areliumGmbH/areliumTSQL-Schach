-- ###########################################################################################
-- ### arelium_TSQL_Chess_V015 ###############################################################
-- ### the royal SQL game - project version ##################################################
-- ###########################################################################################
-- ### creation of the database                                                            ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### This script creates the project database. You should check the lines 97 + 99 to     ###
-- ### adapt the storage paths to your system.                                             ###
-- ###                                                                                     ###
-- ### Currently, only the default settings are set, which are also used as default by the ###
-- ### the graphical user interface. There is still a lot of potential for further         ###
-- ### optimisations.                                                                      ###
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
-- ### ----------------------------------------------------------------------------------- ###
-- ### Proof of amendment:                                                                 ###
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

-- Switch to the MASTER DB that is always present
USE [master]
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

-- If there is already a project database, it will be deleted so that you can later set it up cleanly
IF EXISTS
	(
		SELECT 
			[name] 
		FROM master.dbo.sysdatabases 
		WHERE [name] = 'arelium_TSQL_Chess_V015'
	)
BEGIN
	ALTER DATABASE [arelium_TSQL_Chess_V015] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	DROP DATABASE [arelium_TSQL_Chess_V015]
END


-----------------------------
-- Construction work --------
-----------------------------


CREATE DATABASE [arelium_TSQL_Chess_V015]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'arelium_TSQL_Chess_V015',		FILENAME = N'C:\TAH_Bewegtdaten\Datenbanken\Projekte\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015.mdf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'arelium_TSQL_Chess_V015_log',	FILENAME = N'C:\TAH_Bewegtdaten\Datenbanken\Projekte\arelium_TSQL_Chess_V015\arelium_TSQL_Chess_V015_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET COMPATIBILITY_LEVEL = 150
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET ARITHABORT OFF 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET AUTO_CREATE_STATISTICS ON(INCREMENTAL = OFF)
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET  DISABLE_BROKER 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET  READ_WRITE 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET RECOVERY FULL 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET  MULTI_USER 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [arelium_TSQL_Chess_V015] SET DELAYED_DURABILITY = DISABLED 
GO


USE [arelium_TSQL_Chess_V015]
GO
ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = Off;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET LEGACY_CARDINALITY_ESTIMATION = Primary;
GO
ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET MAXDOP = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = On;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET PARAMETER_SNIFFING = Primary;
GO
ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = Off;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET QUERY_OPTIMIZER_HOTFIXES = Primary;
GO

USE [arelium_TSQL_Chess_V015]
GO

IF NOT EXISTS 
	(
		SELECT 
			[name] 
		FROM sys.filegroups 
		WHERE 1 = 1
			AND [is_default]	= 1 
			AND [name]			= N'PRIMARY'
	) 
BEGIN
	ALTER DATABASE [arelium_TSQL_Chess_V015] MODIFY FILEGROUP [PRIMARY] DEFAULT
END
GO



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '002 - Create Database.sql'
PRINT ' '
PRINT 'Script     :   ' + @Script
PRINT 'End        :   ' + @End
PRINT 'Time       :   ' + @Time
SELECT @Script AS Skript, @End AS Ende, @Time AS Zeit
GO