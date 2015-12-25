{-# LANGUAGE RecordWildCards #-}


-- Extract selected sentences. 


module NLP.FrenchTAG.Select
( select
) where


import           Control.Monad (unless, forM_)
import qualified Control.Monad.State.Strict   as E

import           System.Random (randomRIO)
import qualified Data.Set as S
import qualified Data.Map.Strict as M
import qualified Pipes.Prelude as Pipes
import           Pipes

import qualified NLP.FrenchTAG.Gen as G


--------------------------------------------------
-- Std input
--------------------------------------------------


-- | Produce sentence in the given file.
sentPipe :: Producer [G.Term] IO ()
sentPipe = Pipes.stdinLn >-> Pipes.map read


--------------------------------------------------
-- Selection
--------------------------------------------------


-- | Read sentences to parse from stdin and select the given number
-- of sentences per sentence length.
select :: Int -> IO ()
select n = do
    let thePipe = hoist lift sentPipe
    sentMap <- flip E.execStateT M.empty . runEffect . for thePipe $
        \sent -> E.modify $ M.insertWith S.union
            (length sent) (S.singleton sent)
    forM_ (M.toList sentMap) $ \(sentLen, sentSet) -> do
        putStr (show sentLen) >> putStr " -> " >> print (S.size sentSet)
    print "############"
    forM_ (M.elems sentMap) $ \sentSet0 -> do
        sentSet <- subset n sentSet0
        forM_ (S.toList sentSet) print


-- | Take a random subset from the given set (unless empty) of the
-- given size (at max).
subset :: Ord a => Int -> S.Set a -> IO (S.Set a)
subset n s
    | n > 0 = do
        x <- draw s
        r <- subset (n - 1) s
        return $ S.insert x r
    | otherwise = return S.empty


-- | Draw a random element from the given set.
draw :: Ord a => S.Set a -> IO a
draw s = if S.null s
    then error "cannot draw from empty set"
    else do
        i <- randomRIO (0, S.size s - 1)
        return $ S.toList s !! i
