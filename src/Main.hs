{-# LANGUAGE OverloadedStrings, ScopedTypeVariables  #-}
{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad.IO.Class (liftIO)
import Control.Monad (forM_, liftM)
import Control.Applicative
import Control.Concurrent (MVar, newMVar)
import qualified Data.Text as T
import qualified Data.Text.IO as T
import qualified Data.Text.Encoding as TE
import Data.List (foldl')

import Snap.Core
import Snap.Http.Server.Config
import Snap.Http.Server 
import Snap.Util.FileServe

import qualified Snap.Internal.Http.Types as Snap
import Network.WebSockets.Snap 

import Core

simpleConfig :: Config m a
simpleConfig = foldl' (\accum new -> new accum) emptyConfig base 
  where
    base = [hostName, accessLog, errorLog, locale, port, ip, verbose]
    hostName = setHostname "localhost"
    accessLog = setAccessLog (ConfigFileLog "log/access.log")
    errorLog = setErrorLog (ConfigFileLog "log/error.log")
    locale = setLocale "US"
    port = setPort 9160
    ip = setBind "127.0.0.1"
    verbose = setVerbose True

main :: IO ()
main = do
    httpServe simpleConfig $ site 

site :: Snap ()
site = ifTop (serveFile "public/index.html") <|> 
    -- route [ ("ws", liftIO (newMVar M.empty) >>= runWebSocketsSnap . wsApplication) ] <|>
    route [ ("", (serveDirectory "public")) ] 

{-
  todo
    - write JSON instances
    - draw json resource routes in snap

-}
