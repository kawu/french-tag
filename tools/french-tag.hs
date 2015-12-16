{-# LANGUAGE RecordWildCards #-}


-- import           Data.Monoid (mempty)
import           Options.Applicative
import qualified Data.Char as C


-- import qualified NLP.FrenchTAG.Automat as A
import qualified NLP.FrenchTAG.Build as B
import qualified NLP.FrenchTAG.Parse as P
import qualified NLP.FrenchTAG.Gen as G
import qualified NLP.FrenchTAG.Stats as S


--------------------------------------------------
-- Global Options
--------------------------------------------------


data Options = Options {
    input :: FilePath
  , cmd   :: Command
  }


data Command
    = Build B.BuildCfg
    -- ^ Build an automaton
    | Parse -- ParseOptions
    -- ^ Only parse and show the input grammar
    | Gen Int
    -- ^ Generate size-bounded derived trees
    | GenParse G.GenConf
    -- ^ Generate and parse size-bounded derived trees
    | Stats S.StatCfg
    -- ^ Parse sentences from stdin (one sentence per line)


-- --------------------------------------------------
-- -- Build options
-- --------------------------------------------------
--
--
-- data BuildOptions
--     = Automat
--     | Trie
--     | List
--     deriving (Show, Read)
--
--
-- -- parseBuildOptions :: Monad m => String -> m BuildOptions
-- parseBuildOptions :: Monad m => String -> m BuildOptions
-- parseBuildOptions s = return $ case map C.toLower s of
--     'a':_       -> Automat
--     't':_       -> Trie
--     'l':_       -> List
--     _           -> Automat
--
--
-- buildOptions :: Parser Command
-- buildOptions = Build
--     <$> argument
--             -- auto
--             ( str >>= parseBuildOptions )
--             ( metavar "BUILD-TYPE"
--            <> value Automat
--            <> help "Possible values: automat(on), trie" )


parseCompression :: Monad m => String -> m B.Compress
parseCompression s = return $ case map C.toLower s of
    'a':_       -> B.Auto    -- Automaton
    't':_       -> B.Trie    -- Trie
    'l':_       -> B.List    -- List
    _           -> B.Auto


buildOptions :: Parser B.BuildCfg
buildOptions = B.BuildCfg
    <$> option
            ( str >>= parseCompression )
            ( metavar "COMPRESSION-METHOD"
           <> value B.Auto
           <> long "compression-method"
           <> short 'c' )
    <*> (not <$> switch
            ( long "no-subtree-sharing"
           <> short 'n' ))


--------------------------------------------------
-- Generation options
--------------------------------------------------


genOptions :: Parser Command
genOptions = Gen
    <$> option
            auto
            ( metavar "MAX-SIZE"
           <> value 5
           <> long "max-size"
           <> short 'm' )


--------------------------------------------------
-- Generation/parsing options
--------------------------------------------------


genParseOptions :: Parser Command
genParseOptions = fmap GenParse $ G.GenConf
    <$> option
            auto
            ( metavar "MAX-SIZE"
           <> value 5
           <> long "max-size"
           <> short 'm' )
    <*> option
            auto
            ( metavar "ADJOIN-PROB"
           <> value 0.1
           <> long "adjoin-prob"
           <> short 'a' )
    <*> option
            auto
            ( metavar "TREE-NUM"
           <> value 10
           <> long "tree-num"
           <> short 'n' )


--------------------------------------------------
-- Stats options
--------------------------------------------------


statsOptions :: Parser Command
statsOptions = fmap Stats $ S.StatCfg
    <$> option
            ( Just <$> auto )
            ( metavar "MAX-SIZE"
           <> value Nothing
           <> long "max-size"
           <> short 'm' )
    <*> buildOptions


--------------------------------------------------
-- Global options
--------------------------------------------------


opts :: Parser Options
opts = Options
    <$> strOption
       ( long "input"
      <> short 'i'
      <> metavar "FILE"
      <> help "Input .xml (e.g. valuation.xml) file" )
    <*> subparser
        ( command "build"
            (info (Build <$> buildOptions)
                (progDesc "Build automaton from the grammar")
                )
        <> command "parse"
            (info (pure Parse)
                (progDesc "Parse the input grammar file")
                )
        <> command "gen"
            (info genOptions
                (progDesc "Generate trees based on input grammar file")
                )
        <> command "gen-parse"
            (info genParseOptions
                (progDesc "Generate and parse trees")
                )
        <> command "stats"
            (info statsOptions
                (progDesc "Parse sentences from stdin")
                )
        )


-- | Run program depending on the cmdline arguments.
run :: Options -> IO ()
run Options{..} =
    case cmd of
         Build cfg ->
            B.printAuto cfg input
         Parse ->
            P.printGrammar input
         Gen sizeMax ->
            G.generateFrom input sizeMax
         GenParse cfg ->
            G.genAndParseFrom cfg input
         Stats cfg ->
            S.statsOn cfg input


main :: IO ()
main =
    execParser (info opts desc) >>= run
  where
    desc = progDesc "Manipulating FrenchTAG"
