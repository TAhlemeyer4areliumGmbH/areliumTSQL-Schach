-- ###########################################################################################
-- ### arelium_TSQL_Schach_V014 ##############################################################
-- ### Das Spiel der Koenige - Projektversion ################################################
-- ###########################################################################################
-- ### Anlage der Datenbank                                                                ###
-- ### ----------------------------------------------------------------------------------- ###
-- ### Dieses Skript legt die Projektdatenbank an. Du solltest vor der Ausfuehrung in den  ###
-- ### Zeilen 97 + 99 die Ablagepfade an Dein System anpassen.                             ###
-- ###                                                                                     ###
-- ### Aktuell werden lediglich Standardeinstellungen gesetzt, die auch als Default von    ###
-- ### der grafischen Oberflaeche vorgeschlagen werden. Hier ist fuer weitere              ###
-- ### Optimierungen noch viel Potenzial.                                                  ###
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
-- ###      Ein grosser Dank geht an (MVP) Uwe Ricken, der dem Projekt mit Rat und         ###
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

-- auf die immer vorhandene MASTER-DB wechseln
USE [master]
GO

-- Gibt an, dass sich die Vergleichsoperatoren Gleich (=) und Ungleich (<>) bei Verwendung mit NULL-Werten in SQL Server 2019 (15.x) ISO-konform verhalten muessen.
-- ANSI NULLS ON ist neuer T-SQL Standard und wird in spaeteren Versionen festgeschrieben.
SET ANSI_NULLS ON
GO

-- Bewirkt, dass SQL Server die ISO-Regeln fuer Anfuehrungszeichen bei Bezeichnern und Literalzeichenfolgen befolgt.
SET QUOTED_IDENTIFIER ON
GO

--------------------------------------------------------------------------------------------------
-- Aufraeumarbeiten ------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

-- Sollte es schon eine Projektdatenbank geben, wird diese geloescht, um spaeter dann 
-- sauber aufsetzen zu koennen
IF EXISTS
	(
		SELECT 
			[name] 
		FROM master.dbo.sysdatabases 
		WHERE [name] = 'arelium_TSQL_Schach_V014'
	)
BEGIN
	ALTER DATABASE [arelium_TSQL_Schach_V014] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	DROP DATABASE [arelium_TSQL_Schach_V014]
END


-----------------------------
-- Aufbauarbeiten -----------
-----------------------------


CREATE DATABASE [arelium_TSQL_Schach_V014]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'arelium_TSQL_Schach_V014',		FILENAME = N'D:\Beruf\arelium\Datenbanken\arelium_TSQL_Schach_V014.mdf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'arelium_TSQL_Schach_V014_log',	FILENAME = N'D:\Beruf\arelium\Datenbanken\arelium_TSQL_Schach_V014_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET COMPATIBILITY_LEVEL = 150
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET ARITHABORT OFF 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET AUTO_CREATE_STATISTICS ON(INCREMENTAL = OFF)
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET  DISABLE_BROKER 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET  READ_WRITE 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET RECOVERY FULL 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET  MULTI_USER 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [arelium_TSQL_Schach_V014] SET DELAYED_DURABILITY = DISABLED 
GO


USE [arelium_TSQL_Schach_V014]
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

USE [arelium_TSQL_Schach_V014]
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
	ALTER DATABASE [arelium_TSQL_Schach_V014] MODIFY FILEGROUP [PRIMARY] DEFAULT
END
GO



------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistiken ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @Ende		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Zeit		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Skript		VARCHAR(100)	= '002 - Datenbank erstellen.sql'
PRINT ' '
PRINT 'Skript     :   ' + @Skript
PRINT 'Ende       :   ' + @Ende
PRINT 'Zeit       :   ' + @Zeit
SELECT @Skript AS Skript, @Ende AS Ende, @Zeit AS Zeit
GO