

-- ********************************************************************************
-- *** Datenbank im Status "Wiederherstellung steht aus" korrigieren            ***
-- ********************************************************************************

-- 1. Abfrage der Datenbanken und Status (Ermittlung der Problemfälle)
SELECT name, state_desc from sys.databases
GO

-- 2. Datenbank in Notfallmodus setzen
ALTER DATABASE [arelium_TSQL_Schach_V012] SET EMERGENCY;
GO

--3. Datenbank in Single User Mode setzen
ALTER DATABASE [arelium_TSQL_Schach_V012] set single_user;
GO

-- 4. Log Datei im Pfad entfernen oder umbenennen
--  zB.: ...MSSQL\DATA\_log.ldf in ...MSSQL\DATA\_log2.ldf umbenennen

-- 5. DB Check ausführen
DBCC CHECKDB ([arelium_TSQL_Schach_V012], REPAIR_ALLOW_DATA_LOSS) WITH ALL_ERRORMSGS;
GO

-- 6. Datenbank wieder in normalen Modus setzen
ALTER DATABASE [arelium_TSQL_Schach_V012] set multi_user;
GO
