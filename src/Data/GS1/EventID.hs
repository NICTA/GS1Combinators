{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE TypeOperators   #-}


module Data.GS1.EventID where

import           Control.Lens
import           Control.Monad (liftM)
import           Data.UUID
import           Data.Aeson
import           Data.Aeson.TH
import           GHC.Generics
import           Data.Swagger
import           Database.SQLite.Simple.ToField
import           Data.ByteString.Char8 (pack)
import           Web.HttpApiData

newtype EventID = EventID UUID
  deriving (Show, Eq, Generic)

instance FromHttpApiData EventID where
  parseQueryParam httpData = liftM EventID $ parseQueryParam httpData

instance ToField EventID where
  toField = toField . pack . show

$(deriveJSON defaultOptions ''UUID)
--instance ToSchema UUID
$(deriveJSON defaultOptions ''EventID)
instance ToSchema EventID

instance ToParamSchema EventID where
  toParamSchema _ = mempty
    & type_ .~ SwaggerString

makeClassy ''EventID
