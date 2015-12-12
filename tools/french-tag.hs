{-# LANGUAGE RecordWildCards #-}


-- import           Data.Monoid (mempty)
import           Options.Applicative
import qualified Data.Char as C


import qualified NLP.FrenchTAG.Automat as A
import qualified NLP.FrenchTAG.Parse as P
import qualified NLP.FrenchTAG.Gen as G


--------------------------------------------------
-- Global Options
--------------------------------------------------


data Options = Options {
    input :: FilePath
  , cmd   :: Command
  }


data Command
    = Build BuildOptions
    -- ^ Build an automaton
    | Parse -- ParseOptions
    -- ^ Only parse and show the input grammar
    | Gen G.GenConf
    -- ^ Generate size-bounded derived trees
    | GenParse G.GenConf
    -- ^ Generate and parse size-bounded derived trees


--------------------------------------------------
-- Build options
--------------------------------------------------


data BuildOptions
    = Base
    | Share
    | AutoBase
    | AutoShare
    deriving (Show, Read)


-- parseBuildOptions :: Monad m => String -> m BuildOptions
parseBuildOptions :: Monad m => String -> m BuildOptions
parseBuildOptions s = return $ case map C.toLower s of
    'b':_       -> Base
    's':_       -> Share
    'a':'u':'t':'o':'b':_
                -> AutoBase
    _           -> AutoShare


buildOptions :: Parser Command
buildOptions = Build
    <$> argument
            -- auto
            ( str >>= parseBuildOptions )
            ( metavar "BUILD-TYPE"
           <> value AutoShare
           <> help "Possible values: base, share, autob(ase), auto(share)" )
--            <> long "build-type"
--            <> short 'b' )


--------------------------------------------------
-- Generation options
--------------------------------------------------


genOptions :: Parser Command
genOptions = fmap Gen $ G.GenConf
    <$> option
            auto
            ( metavar "MAX-SIZE"
           <> value 5
           <> long "max-size"
           <> short 'm' )
    <*> option
            auto
            ( metavar "PROB-RETAIN"
           <> value 1
           <> long "prob-retain"
           <> short 'p' )
--     <*> pure 1


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
            ( metavar "PROB-RETAIN"
           <> value 1
           <> long "prob-retain"
           <> short 'p' )
--     <*> option
--             auto
--             ( metavar "REPEAT"
--            <> value 1
--            <> long "repeat"
--            <> short 'r' )


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
            (info buildOptions
                (progDesc "Build different automaton versions")
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
        )


-- | Run program depending on the cmdline arguments.
run :: Options -> IO ()
run Options{..} =
    case cmd of
         Build Base ->
            A.baseLineRules input
         Build Share ->
            A.shareRules input
         Build AutoBase ->
            A.baseAutomatRules input
         Build AutoShare ->
            A.automatRules input
         Parse ->
            P.printGrammar input
         Gen cfg ->
            G.generateFrom input cfg
         GenParse cfg ->
            G.genAndParseFrom input cfg


main :: IO ()
main =
    execParser (info opts desc) >>= run
  where
    desc = progDesc "Manipulating FrenchTAG"
