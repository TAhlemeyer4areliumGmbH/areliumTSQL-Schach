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
DECLARE @Startquadrat char(2)
DECLARE @Zielquadrat char(2)
DECLARE @Umwandlungsfigur char(1)
DECLARE @IstEnPassant bit

SET @NameWeiss							= 'Torsten'
SET @NameSchwarz						= 'Compi'
SET @SpielstaerkeWeiss					= 1
SET @SpielstaerkeSchwarz				= 2
SET @RestzeitWeissInSekunden			= 5700
SET @RestzeitSchwarzInSekunden			= 5700
SET @ComputerSchritteAnzeigenWeiss		= 1
SET @ComputerSchritteAnzeigenSchwarz	= 1
SET @Startquadrat						= 'e2'
SET @Zielquadrat						= 'e4'
SET @Umwandlungsfigur					= NULL
SET @IstEnPassant						= 'FALSE'


EXECUTE @RC = [Spiel].[prcMensch_vs_TSQL] 
   @NameWeiss
  ,@NameSchwarz
  ,@SpielstaerkeWeiss
  ,@SpielstaerkeSchwarz
  ,@RestzeitWeissInSekunden
  ,@RestzeitSchwarzInSekunden
  ,@ComputerSchritteAnzeigenWeiss
  ,@ComputerSchritteAnzeigenSchwarz
  ,@Startquadrat
  ,@Zielquadrat
  ,@Umwandlungsfigur
  ,@IstEnPassant
GO


