{-# LANGUAGE DeriveGeneric   #-}
{-# LANGUAGE TemplateHaskell #-}

module Data.GS1.DWhat where

import           Control.Lens
import           GHC.Generics

import           Data.List.Split
import           Data.Semigroup

import           Data.Aeson
import           Data.Aeson.TH

import           Data.Swagger
import           Database.SQLite.Simple.ToField
import           Data.Aeson.Text
import           Data.ByteString.Char8 (pack)
import qualified Data.Text.Lazy as TxtL

import           Data.GS1.EPC

data LabelEPC = CL 
                {
                  _clClassLabelEpc :: ClassLabelEPC
                , _clQuantity      :: Maybe Quantity
                }
              | IL
                {
                  _ilInstanceLabelEpc :: InstanceLabelEPC
                }
              deriving (Show, Read, Eq, Generic)

$(deriveJSON defaultOptions ''LabelEPC)
instance ToSchema LabelEPC

instance ToField LabelEPC where
    toField = toField . pack . show

type ParentID  = InstanceLabelEPC
type InputEPC  = LabelEPC
type OutputEPC = LabelEPC

-- applies the string to the correct readURI function
-- i.e, figures out whether to return InstanceLabel or ClassLabel
-- @todo deprecate this function
readLabelEPC :: Maybe Quantity -> String -> Either ParseFailure LabelEPC
readLabelEPC mQt epcStr =
  fmap (`CL` mQt) (readURIClassLabelEPC epcTokens)
    <>
      fmap IL (readURIInstanceLabelEPC epcTokens)
  where
    epcTokens = splitOn ":" epcStr

-- |The What dimension specifies what physical or digital objects
-- participated in the event
data DWhat = -- ObjectDWhat action epcList
            ObjectDWhat
            { 
              _objAction  :: Action
            , _objEpcList :: [LabelEPC]
            }
          -- AggregationDWhat action parentID childEPC
          | AggregationDWhat
            {
              _aggAction       :: Action
            , _aggParentId     :: Maybe ParentID
            , _aggChildEpcList :: [LabelEPC]
            }
          -- TransactionDWhat action parentID(URI) bizTransactionList epcList
          -- EPCIS-Standard-1.2-r-2016-09-29.pdf Page 56
          | TransactionDWhat
            {
              _transactionAction             :: Action 
            , _transactionParentIdURI        :: Maybe ParentID
            , _transactionBizTransactionList :: [BizTransaction]
            , _transactionEpcList            :: [LabelEPC]
            }
          -- TransformationDWhat transformationID inputEPCList outputEPCList
          | TransformationDWhat
            {
              _TransformationId            :: Maybe TransformationID
            , _TransformationInputEpcList  :: [InputEPC]
            , _TransformationOutputEpcList :: [OutputEPC]
            }
          deriving (Show, Eq, Generic)

$(deriveJSON defaultOptions ''DWhat)
instance ToSchema DWhat

instance ToField DWhat where
  toField = toField . TxtL.toStrict . encodeToLazyText

ppDWhat :: DWhat -> String
ppDWhat (ObjectDWhat a epcs) =
  "OBJECT WHAT\n" ++ show a ++ "\n" ++ show epcs ++ "\n"
ppDWhat (AggregationDWhat a pid epcs ) =
  "AGGREGATION WHAT\n" ++ show a ++ "\n" ++ show pid ++ "\n" ++ show epcs ++ "\n"
ppDWhat (TransactionDWhat a s bizT epcs ) =
  "TRANSACTION WHAT\n" ++ show a ++ "\n" ++ show s ++ "\n" ++ show bizT ++ "\n" ++ show epcs ++ "\n"
ppDWhat (TransformationDWhat tid inputEpcs outputEpcs ) =
  "TRANSFORMATION WHAT\n" ++ show tid ++ "\n" ++ show inputEpcs ++ "\n" ++ show outputEpcs ++ "\n"

makeClassy ''DWhat
