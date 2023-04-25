USE [arelium_TSQL_Schach_V012]
GO

DECLARE @RC int
DECLARE @NameWeiss nvarchar(30)
DECLARE @NameSchwarz nvarchar(30)
DECLARE @SpielstaerkeWeiss tinyint
DECLARE @SpielstaerkeSchwarz tinyint
DECLARE @RestzeitWeissInSekunden int
DECLARE @RestzeitSchwarzInSekunden int
DECLARE @ComputerSchritteAnzeigenWeiss bit
DECLARE @ComputerSchritteAnzeigenSchwarz bit

SET @NameWeiss							= 'Computer1'
SET @NameSchwarz						= 'Computer2'
SET @SpielstaerkeWeiss					= 3
SET @SpielstaerkeSchwarz				= 3
SET @RestzeitWeissInSekunden			= 5700
SET @RestzeitSchwarzInSekunden			= 5700
SET @ComputerSchritteAnzeigenWeiss		= 1
SET @ComputerSchritteAnzeigenSchwarz	= 1


EXECUTE @RC = [Spiel].[prcTSQL_vs_TSQL] 
   @NameWeiss
  ,@NameSchwarz
  ,@SpielstaerkeWeiss
  ,@SpielstaerkeSchwarz
  ,@RestzeitWeissInSekunden
  ,@RestzeitSchwarzInSekunden
  ,@ComputerSchritteAnzeigenWeiss
  ,@ComputerSchritteAnzeigenSchwarz
GO

-- WEISS zieht automatisch!
-- SCHWARZ zieht automatisch!
