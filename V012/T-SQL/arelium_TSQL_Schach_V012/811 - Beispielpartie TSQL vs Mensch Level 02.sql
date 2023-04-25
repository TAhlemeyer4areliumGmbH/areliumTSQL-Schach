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

SET @NameWeiss							= 'Computer'
SET @NameSchwarz						= 'Torsten'
SET @SpielstaerkeWeiss					= 2
SET @SpielstaerkeSchwarz				= 1
SET @RestzeitWeissInSekunden			= 5700
SET @RestzeitSchwarzInSekunden			= 5700
SET @ComputerSchritteAnzeigenWeiss		= 1
SET @ComputerSchritteAnzeigenSchwarz	= 1


EXECUTE @RC = [Spiel].[prcTSQL_vs_Mensch] 
   @NameWeiss
  ,@NameSchwarz
  ,@SpielstaerkeWeiss
  -- Spielstaerke WEISS ist der Festwert 1
  ,@RestzeitWeissInSekunden
  ,@RestzeitSchwarzInSekunden
  ,@ComputerSchritteAnzeigenWeiss
  ,@ComputerSchritteAnzeigenSchwarz
GO


-- Die Zeit fuer SCHWARZ laeuft...
EXECUTE [Spiel].[prcZugAusfuehren] 
		  @Startquadrat				= 'e7'
		, @Zielquadrat				= 'e5'
		, @Umwandlungsfigur			= NULL
		, @IstEnPassant				= 'FALSE'
		, @IstSpielerWeiss			= 'FALSE'
GO	

-- WEISS zieht automatsich!