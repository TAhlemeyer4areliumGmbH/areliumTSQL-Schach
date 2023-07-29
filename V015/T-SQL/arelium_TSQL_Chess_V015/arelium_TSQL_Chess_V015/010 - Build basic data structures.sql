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

-- All objects that are created or changed by this script are listed here. Since some DDL
-- commands do not have an IF-EXISTS syntax, this is the first place to clean up the list. Existing 
-- objects are deleted by DROP, so that they can be re-created later in an orderly fashion.

-- Constraints
	IF EXISTS (SELECT 1 FROM SYS.OBJECTS WHERE NAME = 'FK_PossibleAction_TheoreticalAction' AND TYPE='F')
		ALTER TABLE [CurrentGame].[PossibleAction] DROP CONSTRAINT [FK_PossibleAction_TheoreticalAction]

	IF EXISTS (SELECT 1 FROM SYS.OBJECTS WHERE NAME = 'FK_Notation_TheoreticalAction' AND TYPE='F')
		ALTER TABLE [CurrentGame].[Notation] DROP CONSTRAINT [FK_Notation_TheoreticalAction]
	
	IF EXISTS (SELECT 1 FROM SYS.OBJECTS WHERE NAME = 'FK_Configuration_LevelID' AND TYPE='F')
		ALTER TABLE [CurrentGame].[Configuration] DROP CONSTRAINT [FK_Configuration_LevelID]
	
	IF EXISTS (SELECT 1 FROM SYS.OBJECTS WHERE NAME = 'FK_SearchTree_SearchTree' AND TYPE='F')
		ALTER TABLE [CurrentGame].[SearchTree] DROP CONSTRAINT [FK_SearchTree_SearchTree]

	IF EXISTS (SELECT 1 FROM SYS.OBJECTS WHERE NAME = 'FK_Infrastructure_GameBoard_FigurUTF8' AND TYPE='F')
		ALTER TABLE [Infrastructure].[GameBoard] DROP CONSTRAINT [FK_Infrastructure_GameBoard_FigurUTF8]


	
-- Tables
	DROP TABLE IF EXISTS [Infrastructure].[TheoreticalAction]
	DROP TABLE IF EXISTS [Infrastructure].[Figure]
	DROP TABLE IF EXISTS [Infrastructure].[GameBoard]
	DROP TABLE IF EXISTS [Infrastructure].[Level]
	DROP TABLE IF EXISTS [Infrastructure].[Logo]

	DROP TABLE IF EXISTS [CurrentGame].[Notation]
	DROP TABLE IF EXISTS [CurrentGame].[SearchTree]
	DROP TABLE IF EXISTS [CurrentGame].[PossibleAction]
	DROP TABLE IF EXISTS [CurrentGame].[Configuration]
	DROP TABLE IF EXISTS [CurrentGame].[ActionTracing]

	DROP TABLE IF EXISTS [Library].[GameMetadata]
	DROP TABLE IF EXISTS [Library].[GrandmasterGame]

	DROP TABLE IF EXISTS [Infrastructure].[PNG_Stage1]
	DROP TABLE IF EXISTS [Infrastructure].[PNG_Stage2]
	
	DROP TABLE IF EXISTS [Statistic].[PositionEvaluation]
GO



-----------------------------
-- Construction work --------
-----------------------------

-- Schemes
-- ------------------------------------------------------------------------------------------------
-- Schemas are order structures that serve the purpose of clarity. The project creates in the 
-- course of the time a multiplicity of objects. In order to keep the overview, these are grouped 
-- according to their technical use. So they appear also sorted in the object explorer...
-- In addition schemes facilitate the assignment of rights, since no longer individual objects but only
-- the superordinate schemas have to be authorized. So it can be prevented that 
-- e.g. the player BLACK calls a function, which is meant for player WHITE.

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Infrastructure')	EXEC('CREATE SCHEMA [Infrastructure]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Puzzle')			EXEC('CREATE SCHEMA [Puzzle]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Statistic')			EXEC('CREATE SCHEMA [Statistic]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'CurrentGame')		EXEC('CREATE SCHEMA [CurrentGame]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Archiv')			EXEC('CREATE SCHEMA [Archiv]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Library')			EXEC('CREATE SCHEMA [Library]');
GO 



-- Typs
-- ------------------------------------------------------------------------------------------------
-- User-defined data types allow custom memory objects. In this project they are 
-- mainly used to pass table contents to procedures and functions



-- in this data structure the criteria for the position evaluation are to be stored.
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = N'typeValuation')
	CREATE TYPE typeValuation 
		AS TABLE ( 
			  [ID]							INTEGER			NOT NULL
			, [Label]						NVARCHAR(20)	NOT NULL
			, [White]						FLOAT			NULL
			, [Black]						FLOAT			NULL
			, [Comment]						NVARCHAR(200)	NOT NULL
		)
GO




-- the user-defined type [typePosition] takes a complete (fictitious) board position
-- consisting of 64 fields. It is used e.g. in position evaluation/analysis.
-- Therefore it has also the columns [VariantNo] and [SearchDepth] with which 
-- the search trees are managed.
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = N'typePosition')
	CREATE TYPE typePosition 
		AS TABLE ( 
			  [PositionID]					BIGINT						NOT NULL
			, [SearchDepth]					INTEGER						NOT NULL
			, [Column]						CHAR(1)						NOT NULL
			, [Row]							TINYINT						NOT NULL
			, [Field]						TINYINT						NOT NULL
			, [IsPlayerWhite] 				BIT							NULL
			, [FigureLetter]				CHAR(1)						NOT NULL
			, [FigureUTF8]					BIGINT						NOT NULL
		)
GO

-- In the user-defined type [typeNotation] a single move is logged. The
-- long notation is displayed on the interface, the short one is used in the EFN protocol.
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = N'typeNotation')
	CREATE TYPE typeNotation 
		AS TABLE ( 
			  [MoveID]						INTEGER						NOT NULL
			, [IsPlayerWhite] 				BIT							NOT NULL
			, [TheoreticalActionID]			BIGINT						NOT NULL
			, [LongNotation]				VARCHAR(20)					NOT NULL   -- e.g. Ne7xg8# or e7xd8Q+
			, [ShortNotationSimple]			VARCHAR(8)					NOT NULL   -- (long) Be3xg5 --> becomes (short) Bxg5
			, [ShortNotationComplex]		VARCHAR(8)					NOT NULL   -- (long) Nb3-e4 --> becomes (short) Nbe4
			, [IsMoveChessBid]				BIT							NOT NULL
		)
GO

-- the user-defined type [typePossibleAction] corresponds in its column definition to the identically named 
-- table [Infrastructure].[TheoreticalAction]. Here all actions which can be played out of a certain board 
-- position can be stored in a structured way
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = N'typePossibleAction' )
	CREATE TYPE typePossibleAction
		AS TABLE ( 
			  [PossibleActionID]			BIGINT		IDENTITY(1,1)	NOT NULL
			, [TheoreticalActionID]			BIGINT						NOT NULL
			, [HalfMoveNo]					INTEGER						NOT NULL		-- State of the game, moreover, the analysis should start
			, [FigureLetter]				CHAR(1)						NOT NULL		-- (P)awn, (R)ook, K(n)ight,(B)ishop, (Q)ueen, (K)ing
			, [IsPlayerWhite] 				BIT							NULL			-- 1 = TRUE
			, [StartColumn] 				CHAR(1)						NOT NULL		-- A-H
			, [StartRow]					TINYINT						NOT NULL		-- 1-8
			, [StartField]					TINYINT						NOT NULL		-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
			, [TargetColumn]				CHAR(1)						NOT NULL		-- A-H
			, [TargetRow]					TINYINT						NOT NULL		-- 1-8
			, [TargetField]					TINYINT						NOT NULL		-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
			, [Direction]					CHAR(2)						NOT NULL		-- Left (LE), Right (RI), Up (UP) and Down (DO) and all 
																						-- Combinations like Right-Down (RD) or Left-Up (LU)
			, [TransformationFigureLetter]	CHAR(1)						NULL			-- (R)ook, K(n)ight, (B)ishop, (Q)ueen
			, [IsActionCapture]				BIT							NOT NULL		-- 1 = TRUE
			, [IsActionCastlingKingsside]	BIT							NOT NULL		-- 1 = TRUE
			, [IsActionCastlingQueensside]	BIT							NOT NULL		-- 1 = TRUE
			, [IsActionEnPassant]			BIT							NOT NULL		-- 1 = TRUE
			, [LongNotation]				VARCHAR(20)					NULL			-- e.g. Ne7xg8# or e7xd8Q+
			, [ShortNotationSimple]			VARCHAR(8)					NULL			-- (long) Be3xg5 --> becomes (short) Bxg5
			, [ShortNotationComplex]		VARCHAR(8)					NULL			-- (long) Nb3-e4 --> becomes (short) Nbe4
			, [Rating]						FLOAT						NULL			-- the bigger, the better. positive = advantage white 
			)
GO



-- Tables
-- ------------------------------------------------------------------------------------------------
-- Tables are used for permanent storage of data - 


-- This table takes data of type GEOGRAPHY to paint the game logo with it
CREATE TABLE [Infrastructure].[Logo]
  (
         [ID]					INTEGER				IDENTITY(1, 1)	NOT NULL Primary Key
       , [AreaName]				NVARCHAR(50)
       , [Area]					GEOGRAPHY); 
 GO 


-- This table is intended to represent all states that represent the occupancy of a single field.
-- Every existing figure as well as the condition "no figure" (empty field)can occur. The UTF-8 
-- value can be used to simulate graphical representations of figures. 
-- simulate (--> SELECT NCHAR(9812))
CREATE TABLE [Infrastructure].[Figure](
	  [FigureUTF8]				BIGINT			NOT NULL					-- UTF8 value of the figure graphic
	, [IsPlayerWhite] 			BIT				NULL						-- 1 = TRUE
	, [FigureName]				NVARCHAR(20)	NOT NULL					-- Pawn, Rook, Knight, Bishop, Queen, King
	, [FigureLetter]			CHAR(1)			NOT NULL					-- (P)awn, (R)ook, K(n)ight,(B)ishop, (Q)ueen, (K)ing
	, [FigureIcon] 				NCHAR(1)		NOT NULL					-- e.g. SELECT NCHAR(9812)
	, [FigureValue] 			TINYINT			NOT NULL					-- Standard: Pawn=1, Bishop=3, Knight=3, Rook=5, Queen=10
																			-- the king is priceless. Tactical behavior is enforceable 
																			-- via these values 
	,
 CONSTRAINT [PK_Figure] PRIMARY KEY CLUSTERED 
(
	    [FigureUTF8]			ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- -----------------------------------------------------------------------------------------------------------------

-- This table should contain all theoretically conceivable moves independent of the actual board situation. 
-- So we consider, on which squares a certain piece can (according to the rules, a white pawn can never occupy 
-- the square "e1", for example) and which squares this piece can legally reach from there. 
-- (if the board would otherwise be empty). We distinguish moves and captures, because 
-- some pieces, e.g. the pawn, move differently than they capture...
CREATE TABLE [Infrastructure].[TheoreticalAction](
	  [TheoreticalActionID]			BIGINT		IDENTITY(1,1)	NOT NULL
	, [FigureLetter]				CHAR(1)						NOT NULL		
		CHECK ([FigureLetter] IN ('P', 'B', 'N', 'R', 'K', 'Q'))
	, [IsPlayerWhite] 				BIT							NOT NULL		-- 1 = TRUE
	, [StartColumn] 				CHAR(1)						NOT NULL		-- A-H
	, [StartRow]					TINYINT						NOT NULL		-- 1-8
	, [StartField]					TINYINT						NOT NULL		-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
	, [TargetColumn]				CHAR(1)						NOT NULL		-- A-H
	, [TargetRow]					TINYINT						NOT NULL		-- 1-8
	, [TargetField]					TINYINT						NOT NULL		-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
	, [Direction]					CHAR(2)						NOT NULL		-- Left (LE), Right (RI), Up (UP) and Down (DO) and all 
		CHECK ([Direction] IN ('UP', 'RU', 'RI', 'RD', 'DO', 'LD', 'LE', 'LU')) -- Combinations like Right-Down (RD) or Left-Up (LU)
	, [TransformationFigureLetter]	CHAR(1)						NULL			-- NULL, 'B', 'N', 'R', 'Q'
		CHECK ([TransformationFigureLetter] IN (NULL, 'B', 'N', 'R', 'Q'))
	, [IsActionCapture]				BIT							NOT NULL		-- 1 = TRUE
	, [IsActionCastlingKingsside]	BIT							NOT NULL		-- 1 = TRUE
	, [IsActionCastlingQueensside]	BIT							NOT NULL		-- 1 = TRUE
	, [IsActionEnPassant]			BIT							NOT NULL		-- 1 = TRUE
	, [LongNotation]				VARCHAR(20)					NULL			-- e.g. Ne7xg8# or e7xd8Q+
	, [ShortNotationSimple]			VARCHAR(8)					NULL			-- (long) Be3xg5 --> becomes (short) Bxg5
	, [ShortNotationComplex]		VARCHAR(8)					NULL			-- (long) Nb3-e4 --> becomes (short) Nbe4
	,
 CONSTRAINT [PK_TheoreticalAction] PRIMARY KEY CLUSTERED 
(
	    [TheoreticalActionID]		ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- -----------------------------------------------------------------------------------------------------------------

-- in order to plan several moves in advance, positions and their evaluations have to be stored and analysed
-- in different search depths 
CREATE TABLE [CurrentGame].[SearchTree](
      [ID]						BIGINT			NOT NULL
    , [PredecessorID]			BIGINT			NULL
		CONSTRAINT FK_SearchTree_SearchTree FOREIGN KEY ([PredecessorID] ) REFERENCES [CurrentGame].[SearchTree] ([ID])
	, [SearchDepth]				TINYINT			NOT NULL
    , [HalfMoveNo]				TINYINT			NOT NULL
    , [TheoreticalActionID]		BIGINT			NOT NULL
	, [LongNotation]			VARCHAR(20)		NULL			-- e.g. Ne7xg8# or e7xd8Q+
    , [PositionID]				BIGINT			NOT NULL
    , [Rating]					FLOAT			NULL
    , [IsStillInFocus]			BIT				NOT NULL
	, [EFNAfterAction]			VARCHAR(100)	NULL
CONSTRAINT [PK_SearchTree] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO




-- This table should contain all possible actions in the actual board situation. 
-- These can only be moves which are
--    * are in the table [Infrastructure].[TheoreticalAction].
--    * have a [StartField], which in the current board situation is occupied by 
--      a piece of the appropriate color
--    * where the rules of the game do not prevent an action (e.g. where other pieces are
--      are in the way between the [StartField] and the [TargetField])
--    * move a piece that is not tied up
-- Structurally, the table [CurrentGame].[PossibleAction] is similar to the 
-- table [Infrastructure].[TheoreticalAction].
CREATE TABLE [CurrentGame].[PossibleAction](
	  [PossibleActionID]			BIGINT		IDENTITY(1,1)	NOT NULL
	, [TheoreticalActionID]			BIGINT						NOT NULL		-- Foreign key on [Infrastructure].[TheoreticalAction].
	, [HalfMoveNo]					INTEGER						NOT NULL		-- State of the game for which this action is executable
	, [FigureLetter]				CHAR(1)						NOT NULL		-- 'P', 'B', 'N', 'R', 'K', 'Q' 
		CHECK ([FigureLetter] IN ('P', 'B', 'N', 'R', 'K', 'Q'))
	, [IsPlayerWhite] 				BIT							NULL			-- 1 = TRUE
	, [StartColumn] 				CHAR(1)						NOT NULL		-- A-H
	, [StartRow]					TINYINT						NOT NULL		-- 1-8
	, [StartField]					TINYINT						NOT NULL		-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
	, [TargetColumn]				CHAR(1)						NOT NULL		-- A-H
	, [TargetRow]					TINYINT						NOT NULL		-- 1-8
	, [TargetField]					TINYINT						NOT NULL		-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
	, [Direction]					CHAR(2)						NOT NULL		-- Left (LE), Right (RI), Up (UP) and Down (DO) and all 
		CHECK ([Direction] IN ('UP', 'RU', 'RI', 'RD', 'DO', 'LD', 'LE', 'LU')) -- Combinations like Right-Down (RD) or Left-Up (LU)
	, [TransformationFigureLetter]	CHAR(1)						NULL			-- NULL, 'B', 'N', 'R', 'Q'
		CHECK ([TransformationFigureLetter] IN (NULL, 'B', 'N', 'R', 'Q'))
	, [IsActionCapture]				BIT							NOT NULL		-- 1 = TRUE
	, [IsActionCastlingKingsside]	BIT							NOT NULL		-- 1 = TRUE
	, [IsActionCastlingQueensside]	BIT							NOT NULL		-- 1 = TRUE
	, [IsActionEnPassant]			BIT							NOT NULL		-- 1 = TRUE
	, [LongNotation]				VARCHAR(20)					NULL			-- e.g. Ne7xg8# or e7xd8Q+
	, [ShortNotationSimple]			VARCHAR(8)					NULL			-- (long) Be3xg5 --> becomes (short) Bxg5
	, [ShortNotationComplex]		VARCHAR(8)					NULL			-- (long) Nb3-e4 --> becomes (short) Nbe4
	, [Rating]						FLOAT						NULL			-- Equivalent in pawn units, positive = WHITE has advantage, negative = BLACK has advantage
	,
 CONSTRAINT [PK_PossibleAction] PRIMARY KEY CLUSTERED 
(
	    [PossibleActionID]		ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- In the column [TheoreticalActionID] only values may be entered, that 
-- also occur in the [Infrastructure].[TheoreticalAction] table!
ALTER TABLE [CurrentGame].[PossibleAction] 
	ADD CONSTRAINT [FK_PossibleAction_TheoreticalAction] 
	FOREIGN KEY ([TheoreticalActionID]) REFERENCES [Infrastructure].[TheoreticalAction]([TheoreticalActionID]);
GO

-- -----------------------------------------------------------------------------------------------------------------

-- This table represents the current game board. For each field (combination of row 
-- and column) is recorded whether and by whom this field is occupied.
CREATE TABLE [Infrastructure].[GameBoard](
	  [Column]					CHAR(1)		NOT NULL						-- A-H
	, [Row]						TINYINT		NOT NULL						-- 1-8
	, [Field]					TINYINT		NOT NULL						-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
	, [IsPlayerWhite] 			BIT			NULL							-- 1 = TRUE
	, [FigureLetter]			CHAR(1)						NOT NULL		-- ' ', 'P', 'B', 'N', 'R', 'K', 'Q' 
		CHECK ([FigureLetter] IN (CHAR(160), ' ', 'P', 'B', 'N', 'R', 'K', 'Q'))
	, [FigureUTF8]				BIGINT		NOT NULL						-- UTF8 value of the figure graphic
	, CONSTRAINT [PK_GameBoard] PRIMARY KEY CLUSTERED
		(
			  [Field]			ASC
		)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, 
		ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY]
GO

ALTER TABLE [Infrastructure].[GameBoard] ADD CONSTRAINT [FK_Infrastructure_GameBoard_FigurUTF8] FOREIGN KEY ([FigureUTF8]) REFERENCES [Infrastructure].[Figure]([FigureUTF8]);
GO

-- -----------------------------------------------------------------------------------------------------------------





-- The action tracing is a collection of all historical positions of the current game. So 
-- all positions are stored in their order and every position can be easily restored if needed. 
-- For example a "take back move" function can be realized this way...
CREATE TABLE [CurrentGame].[ActionTracing]
(
	  [ActionTracingID]			BIGINT		NOT NULL
	, [MoveNo]					INTEGER		NOT NULL
	, [Column]					CHAR(1)		NOT NULL						-- A-H
	, [Row]						TINYINT		NOT NULL						-- 1-8
	, [Field]					TINYINT		NOT NULL						-- A1 = 1, A2 = 2, ..., B1 = 9, ...,  H8 = 64
	, [IsPlayerWhite] 			BIT			NOT NULL						-- 1 = TRUE
	, [FigureLetter]			CHAR(1)						NOT NULL		-- 'P', 'B', 'N', 'R', 'K', 'Q' 
		CHECK ([FigureLetter] IN ('P', 'B', 'N', 'R', 'K', 'Q'))
	, [FigureUTF8]				BIGINT		NOT NULL						-- UTF8 value of the figure graphic
	, CONSTRAINT [PK_ActionTracing] PRIMARY KEY CLUSTERED
		(
			  [ActionTracingID] ASC, [MoveNo] ASC, [IsPlayerWhite] ASC, [Column] ASC, [Row]	ASC
		)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, 
		ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO





-- A complete game is "notated" with all its actions in the correct order in this table.
-- Both the official "long notation" from chess as well as the internal description by 
-- the entries from the table [CurrentGame].[PossibleAction] are used.
CREATE TABLE [CurrentGame].[Notation](
	  [MoveID]					INTEGER			NOT NULL						
	, [IsPlayerWhite] 			BIT				NOT NULL				-- 1 = TRUE
	, [TheoreticalActionID]		BIGINT			NOT NULL				-- Foreignkey [Infrastructure].[TheoreticalAction]
	, [LongNotation]			VARCHAR(20)		NULL					-- e.g. Ne7xg8# or e7xd8Q+
	, [ShortNotationSimple]		VARCHAR(8)		NULL					-- (long) Be3xg5 --> becomes (short) Bxg5
	, [ShortNotationComplex]	VARCHAR(8)		NULL					-- (long) Nb3-e4 --> becomes (short) Nbe4
	, [IsMoveChessBid]			BIT				NOT NULL				-- 1 = TRUE
	, CONSTRAINT [PK_Notation] PRIMARY KEY CLUSTERED
		(
			  [MoveID] ASC, [IsPlayerWhite] ASC
		)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, 
		ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- In the column [TheoreticalActionID] only values may be entered, which 
-- also occur in the [Infrastructure].[TheoreticalAction] table!
ALTER TABLE [CurrentGame].[Notation] 
	ADD CONSTRAINT [FK_Notation_TheoreticalAction] 
	FOREIGN KEY ([TheoreticalActionID]) REFERENCES [Infrastructure].[TheoreticalAction]([TheoreticalActionID]);
GO

-- -----------------------------------------------------------------------------------------------------------------

-- This program can simulate computer opponents with different playing strength. The adjusting screws for 
-- the skill, with which a computer opponent acts, are found on the one hand of course in the search depth
-- calculation - but also in the answer to the question, which criteria are used to evaluate a position. 
-- More detailed positional evaluations lead to a stronger game, but also consume significantly more resources.
CREATE TABLE [Infrastructure].[Level](
	  [LevelID]							INTEGER			NOT NULL
	, [PlainText]						VARCHAR(80)		NOT NULL	-- Name of the level, e.g. "amateur player, 6 years old".
	, [IsActionPreviewVisible]			BIT				NOT NULL
	, [IsGrandmasterSupportVisible] 	BIT				NOT NULL	-- 1 = TRUE
	, [CalculateTotalFigureValue]		BIT				NOT NULL	-- 1 = TRUE
	, [CalculateNumberOfActions]		BIT				NOT NULL	-- 1 = TRUE
	, [CalculateNumberOfCaptures]		BIT				NOT NULL	-- 1 = TRUE
	, [CalculateNumberOfCastles]		BIT				NOT NULL	-- 1 = TRUE
	, [CalculateStatusPawnProgress]		BIT				NOT NULL	-- 1 = TRUE
	, [CalculateNumberOfYeomen]			BIT				NOT NULL	-- 1 = TRUE
	, [CalculateStatusOfPawnChains]		BIT				NOT NULL	-- 1 = TRUE
	, CONSTRAINT [PK_Level] PRIMARY KEY CLUSTERED
		(
			   [LevelID] ASC
		)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, 
		ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY]
GO


-- For the current game is stored here, which properties the players 
-- have for WHITE and BLACK
CREATE TABLE [CurrentGame].[Configuration]
(
      [IsPlayerWhite] 					BIT				NOT NULL
	, [NameOfPlayer]					NVARCHAR(30)	NOT NULL
	, [IsPlayerHuman]					BIT				NOT NULL
    , [LevelID]							INTEGER			NOT NULL     
	, [RemainingTimeInSeconds]			INTEGER			NOT NULL
	, [TimestampLastMove]				DATETIME2		NULL
	, [IsShortCastlingStillAllowed]		BIT				NOT NULL
	, [IsLongCastlingStillAllowed]		BIT				NOT NULL
	, [Number50ActionsRule]				TINYINT			NOT NULL
	, [IsEnPassantPossible]				CHAR(2)			NULL			-- Coordinate of pawn,who may be captured using "en passant" rule 
	, CONSTRAINT PK_Configuration_IsPlayerWhite PRIMARY KEY CLUSTERED ([IsPlayerWhite])
)

-- In the column [LevelID] only values may be entered that 
-- also occur in the [Infrastructure].[Level] table!
ALTER TABLE [CurrentGame].[Configuration]
	ADD CONSTRAINT [FK_Configuration_LevelID] 
	FOREIGN KEY ([LevelID]) REFERENCES [Infrastructure].[Level]([LevelID]);
GO

-- -----------------------------------------------------------------------------------------------------------------


-- The values determined for the position evaluation are to be temporarily stored in this object.
-- In this way, they do not have to be calculated several times over, but can simply be read out. 
-- This table refers exclusively to the current position.
CREATE TABLE [Statistic].[PositionEvaluation]
(
	  [PositionEvaluationID]	INTEGER			NOT NULL
	, [Label]					NVARCHAR(50)	NOT NULL
    , [White]					FLOAT			NULL
    , [Black]					FLOAT			NULL
	, [Comment]					NVARCHAR(200)	NOT NULL
	, CONSTRAINT PK_PositionEvealuation PRIMARY KEY CLUSTERED ([PositionEvaluationID])
)
GO

-- -----------------------------------------------------------------------------------------------------------------

-- The program offers the feature to read in arbitrary chess games, which are available in the PGN format, and 
-- so to build up e.g. a opening library. These structured text files can be found for (as long as they are 
-- NOT annotated) free download on the Internet, e.g. with the grandmaster games of the World and European 
-- Championships.
-- The arelium-TSQL-Chess is able to import these files. Each game consists of two blocks:
--    * the metadata like the date of the event, the player names, their ELO-number (a strength of play), ...
--    * the game in the short notation

-- The table [Library].[GameMetadata] is now to number the individual games (per file this can be already some 
-- thousand) and record the metadata. The single moves will be stored separately in a different
-- table, the link is made by the [LibraryID].
CREATE TABLE [Library].[GameMetadata](
	  [GameMetadataID]			BIGINT			IDENTITY(1,1)		NOT NULL			-- PK
	, [Source]					NVARCHAR(50)						NOT NULL			-- name of file to import 
	, [EventLocation]			NVARCHAR(50)						NULL				-- 
	, [Date]					NVARCHAR(20)						NULL				-- Dateof game
	, [Round]					VARCHAR(4)							NULL				-- Round in tournament
	, [White]					NVARCHAR(50)						NULL				-- Spielername WEISS
	, [Black]					NVARCHAR(50)						NULL				-- Spielername SCHWARZ
	, [Result]					NVARCHAR(7)							NULL				-- 1:0 = win white, 0:1 = win black, 1/2:1/2 = draw, stalemate
	, [EloValueWhite]			BIGINT								NULL				-- Play strength indicator WHITE - the higher the better
	, [EloValueBlack]			BIGINT								NULL				-- Play strength indicator BLACK - the higher the better
	, [ECO]						NVARCHAR(30)						NULL				-- ECO = Encyclopaedia of Chess Openings, a unique ID of the chess opening, bspw. "Koenigsindisch"
	, [ShortNotation]			NVARCHAR(max)						NOT NULL
 CONSTRAINT [PK_GameMetadata] PRIMARY KEY CLUSTERED 
(
	[GameMetadataID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO



CREATE TABLE [Infrastructure].[PNG_Stage1]
(
    EntireLine		VARCHAR(MAX)
)
GO
 

CREATE TABLE [Infrastructure].[PNG_Stage2]
(
      RowNo			BIGINT
	, EntireLine	VARCHAR(MAX)
)
GO




CREATE TABLE [Library].[GrandmasterGame]
(
	  [GameMetadataID]		BIGINT			NOT NULL
	, [ActionNo]			INTEGER			NOT NULL
	, [ActionWhite]			VARCHAR(12)		NULL
	, [ActionBlack]			VARCHAR(12)		NULL
)
GO





------------------------------------------------------------------------------------------------------------------------------------------------------
-- Statistics ---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @StartTime	DATETIME		= (SELECT StartTime FROM #Start)
DECLARE @End		VARCHAR(25)		= CONVERT(VARCHAR(25), GETDATE(), 104) + '   ' +CONVERT(VARCHAR(25), GETDATE(), 114)
DECLARE @Time		VARCHAR(500)	= CAST(DATEDIFF(SS, @StartTime, GETDATE()) AS VARCHAR(10)) + ',' + CAST(DATEPART(MS, GETDATE() - @StartTime) AS VARCHAR(10)) + ' sek.'
DECLARE @Script		VARCHAR(100)	= '010 - Build basic data structures.sql'
PRINT ' '
PRINT 'Script     :   ' + @Script
PRINT 'End        :   ' + @End
PRINT 'Time       :   ' + @Time
SELECT @Script AS Skript, @End AS Ende, @Time AS Zeit
GO
