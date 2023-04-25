USE [arelium_TSQL_Schach_V012]
GO


-- ------------------------------------------------------------------------------
-- --- Gesammelte Grossmeisterpartien von Emanuel Lasker einlesen
-- ------------------------------------------------------------------------------
DECLARE @KompletterDateiAblagepfad		VARCHAR(255)
DECLARE @MaxZaehler						INTEGER

SET @KompletterDateiAblagepfad	= 'C:\arelium_Repos\arelium_TSQL_Schach\V012\PNGs\Lasker.pgn'
SET @MaxZaehler					= 150

EXECUTE [Bibliothek].[prcImportPGN] 
   @KompletterDateiAblagepfad
  ,@MaxZaehler
GO

-- ------------------------------------------------------------------------------
-- --- Gesammelte Grossmeisterpartien von Uwe Huebner einlesen
-- ------------------------------------------------------------------------------
DECLARE @KompletterDateiAblagepfad		VARCHAR(255)
DECLARE @MaxZaehler						INTEGER

SET @KompletterDateiAblagepfad	= 'C:\arelium_Repos\arelium_TSQL_Schach\V012\PNGs\Huebner.pgn'
SET @MaxZaehler					= 100

EXECUTE [Bibliothek].[prcImportPGN] 
   @KompletterDateiAblagepfad
  ,@MaxZaehler
GO

-- ------------------------------------------------------------------------------
-- --- Gesammelte Grossmeisterpartien von Gari Kasparov einlesen
-- ------------------------------------------------------------------------------
DECLARE @KompletterDateiAblagepfad		VARCHAR(255)
DECLARE @MaxZaehler						INTEGER

SET @KompletterDateiAblagepfad	= 'C:\arelium_Repos\arelium_TSQL_Schach\V012\PNGs\Kasparov.pgn'
SET @MaxZaehler					= 100

EXECUTE [Bibliothek].[prcImportPGN] 
   @KompletterDateiAblagepfad
  ,@MaxZaehler
GO


-- ------------------------------------------------------------------------------
-- --- Gesammelte Grossmeisterpartien von Anatoli Karpov einlesen
-- ------------------------------------------------------------------------------
DECLARE @KompletterDateiAblagepfad		VARCHAR(255)
DECLARE @MaxZaehler						INTEGER

SET @KompletterDateiAblagepfad	= 'C:\arelium_Repos\arelium_TSQL_Schach\V012\PNGs\Karpov.pgn'
SET @MaxZaehler					= 100

EXECUTE [Bibliothek].[prcImportPGN] 
   @KompletterDateiAblagepfad
  ,@MaxZaehler
GO

