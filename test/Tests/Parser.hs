{-# LANGUAGE OverloadedStrings #-}
-- {-# LANGUAGE TemplateHaskell #-}

module Tests.Parser where

import           Test.Hspec
import           Text.XML
import           Text.XML.Cursor

import qualified Data.Text              as T
import           Data.Time.LocalTime
import           Data.Either.Combinators

import           Data.GS1.DWhat
import           Data.GS1.DWhen
import           Data.GS1.DWhere
import           Data.GS1.DWhy
import           Data.GS1.EPC
import           Data.GS1.Event
import           Data.GS1.Parser.Parser


testParser :: Spec
testParser = do

  describe "parse XML to obtain DWhen" $ do
    it "creates DWhen from valid XML" $ do
      doc <- Text.XML.readFile def "test/test-xml/ObjectEvent.xml"
      let cursor = fromDocument doc
      let oeCursors = getCursorsByName "ObjectEvent" cursor
      --mapM_ print $ parseDWhen <$> oeCursors
      let et = "2005-04-03T20:33:31.116-06:00"
      let et1 = "2005-04-04T20:33:31.116-06:00"
      let t = parseStr2Time et :: Either EPCISTimeError EPCISTime
      let t1 = parseStr2Time et1 :: Either EPCISTimeError EPCISTime
      let tz = parseStr2TimeZone et :: Either EPCISTimeError TimeZone
      let tz1 = parseStr2TimeZone et1 :: Either EPCISTimeError TimeZone
      parseDWhen <$> oeCursors `shouldBe`
        [Right (DWhen (fromRight' t) (Just (fromRight' t)) (fromRight' tz)),
        Right (DWhen (fromRight' t1) Nothing (fromRight' tz1))]

    it "creates Nothing from Single ObjectEvent XML without Event Time" $ do
      doc <- Text.XML.readFile def "test/test-xml/ObjectEventNoEventTime.xml"
      let cursor = fromDocument doc
      let oeCursors = getCursorsByName "ObjectEvent" cursor
      parseDWhen <$> oeCursors `shouldBe` [Left TimeZoneError]

  describe "parse XML to obtain Action" $
    it "finds action from Single ObjectEvent XML" $ do
      doc <- Text.XML.readFile def "test/test-xml/ObjectEventNoEventTime.xml"
      let cursor = fromDocument doc
      let actions = cursor $// element "action" &/ content
      parseAction actions `shouldBe` Right Observe

  -- describe "parse XML to obtain EPC List" $ do
  --   it "finds all epcs" $ do
  --     doc <- Text.XML.readFile def "test/test-xml/ObjectEventNoEventTime.xml"
  --     let cursor = fromDocument doc
  --     let epcs = cursor $// element "epc" &/ content
  --     --show <$> parseEPCList epcs Nothing `shouldBe`
  --     parseEPCList epcs [Just (ItemCount 1), Just (ItemCount 1)] `shouldBe`
  --       [Right $ IL $ SGTIN "0614141" Nothing "107346" "2017",
  --       Right $ IL $ SGTIN "0614141" Nothing "107346" "2018"]

  --   it "finds all child epcs" $ do
  --     doc <- Text.XML.readFile def "test/test-xml/AggregationEvent.xml"
  --     let cursor = fromDocument doc
  --     let epcs = cursor $// element "epc" &/ content
  --     parseChildEPCList epcs [Just (ItemCount 1), Just (ItemCount 1)] `shouldBe`
  --       [Right $ IL $ SGTIN "0614141" Nothing "107346" "2017",
  --       Right $ IL $ SGTIN "0614141" Nothing "107346" "2018"]
        --["urn:epc:id:sgtin:0614141.107346.2017",
        -- "urn:epc:id:sgtin:0614141.107346.2018"]

  describe "parse XML to get BizStep" $ do
    it "find all the BizStep in multiple events XML" $ do
      doc <- Text.XML.readFile def "test/test-xml/ObjectEvent.xml"
      let cursor = fromDocument doc
      let bizStepText = cursor $// element "ObjectEvent" &/ element "bizStep" &/ content
      parseBizStep bizStepText `shouldBe` Right Shipping

    it "find the first BizStep in single Event XML" $ do
      doc2 <- Text.XML.readFile def "test/test-xml/ObjectEvent2.xml"
      let cursor = fromDocument doc2
      let bizStepText = cursor $// element "ObjectEvent" &/ element "bizStep" &/ content
      parseBizStep bizStepText `shouldBe` Right Shipping

  describe "parse XML to get Disposition" $
    it "find all the Disposition in single XML" $ do
      doc2 <- Text.XML.readFile def "test/test-xml/ObjectEvent2.xml"
      let cursor = fromDocument doc2
      let dispText = cursor $// element "ObjectEvent" &/ element "disposition" &/ content
      parseDisposition dispText `shouldBe` Right InTransit

  describe "parse DWhy" $
    it "find the bizStep or disposition and creates a DWhy" $ do
      doc2 <- Text.XML.readFile def "test/test-xml/ObjectEvent2.xml"
      let cursor = fromDocument doc2
      let oeCursors = cursor $// element "ObjectEvent"
      parseDWhy <$> oeCursors `shouldBe`
        [Right $ DWhy (Just Shipping) (Just InTransit)]

  -- the Nothing extension used because a value of 0 indicates no extension
  describe "parse XML to obtain DWhere" $
    it "finds all the dwhere" $ do
      doc2 <- Text.XML.readFile def "test/test-xml/ObjectEvent.xml"
      let cursor = fromDocument doc2
      let oeCursors = getCursorsByName "ObjectEvent" cursor
      --mapM_ print $ parseDWhere <$> oeCursors
      parseDWhere <$> oeCursors `shouldBe`
        [Right DWhere {
          _readPoint =
              [SGLN "0614141" (LocationReferenceNum "07346") (Just "1234")]
          , _bizLocation = []
          , _srcType = []
          , _destType = []
        }, Right DWhere {
          _readPoint =
              [SGLN "0012345" (LocationReferenceNum "11111") (Just "400")]
          , _bizLocation =
              [SGLN "0012345" (LocationReferenceNum "11111") Nothing]
          , _srcType = []
          , _destType = []
        }]

  describe "parse QuantityElement" $
    it "parses quantity elements" $ do
      doc <- Text.XML.readFile def "test/test-xml/ObjectEvent2.xml"
      let cursor = fromDocument doc
      let oeCursors = getCursorsByName "quantityElement" cursor
      parseQuantity <$> oeCursors `shouldBe` [Just $ MeasuredQuantity 200 "KGM"]

      -- TODO = check... may be incorrect!
  describe "parse BizTransaction" $ do
    it "parse BizTransaction element" $ do
      doc <- Text.XML.readFile def "test/test-xml/ObjectEvent.xml"
      let cursor = fromDocument doc
      let btCursor = cursor $// element "bizTransactionList"
      parseBizTransaction <$> btCursor `shouldBe`
        [
          [Right BizTransaction {
            _btid = "http://transaction.acme.com/po/12345678",
            _bt = Po}],
          [
            Right BizTransaction {
              _btid = "http://transaction.acme.com/po/12345678",
              _bt = Po},
            Right BizTransaction {
              _btid = "urn:epcglobal:cbv:bt:0614141073467:1152",
              _bt = Desadv}]
        ]

    it "get all attrs" $ do
      doc2 <- Text.XML.readFile def "test/test-xml/ObjectEvent.xml"
      let cursor = fromDocument doc2
      let btCursor = cursor $// element "bizTransactionList"
      let c = head btCursor
      let attrs = c $/ element "bizTransaction" &| attribute "type"
      readURI . T.unpack <$> foldMap id attrs `shouldBe` [Right Po]

  describe "parse DWhat" $ do
    it "parses a valid ObjectDWhat" $ do
      doc <- Text.XML.readFile def "test/test-xml/ObjectEvent2.xml"
      let cursor = fromDocument doc
      let oeCursors = getCursorsByName "ObjectEvent" cursor
      -- TODO = CHECK whether Nothing is appropriate below
      parseObjectDWhat <$> oeCursors `shouldBe`
        [Right $ ObjectDWhat Observe
          [
            IL $ SGTIN "0614141" Nothing "107346" "2017",
            IL $ SGTIN "0614141" Nothing "107346" "2018",
            CL (LGTIN "4012345" "012345" "998877")
                (Just $ MeasuredQuantity 200 "KGM")
          ]
        ]

    it "parses a valid AggregationDWhat" $ do
      doc <- Text.XML.readFile def "test/test-xml/AggregationEvent.xml"
      let cursor = fromDocument doc
      let aeCursors = getCursorsByName "AggregationEvent" cursor
      -- TODO = check Nothings are appropriate below
      parseAggregationDWhat <$> aeCursors `shouldBe`
        [
          Right $ AggregationDWhat Observe (Just $ SSCC "0614141" "1234567890")
            [
              IL $ SGTIN "0614141" Nothing "107346" "2017",
              IL $ SGTIN "0614141" Nothing "107346" "2018",
              CL (CSGTIN "4012345" Nothing "098765") (Just $ ItemCount 10),
              CL (LGTIN "4012345" "012345" "998877")
                  (Just $ MeasuredQuantity 200.5 "KGM")
            ]
        ]

    -- TODO = check... may be incorrect!
    it "parses a valid TransactionDWhat" $ do
      doc <- Text.XML.readFile def "test/test-xml/TransactionEvent.xml"
      let cursor = fromDocument doc
      let teCursors = getCursorsByName "TransactionEvent" cursor
      -- TODO = check Nothings are appropriate in below
      parseTransactionDWhat <$> teCursors `shouldBe`
        [Right (TransactionDWhat Observe Nothing
          [BizTransaction {
            _btid = "http://transaction.acme.com/po/12345678",
            _bt = Po}]
          [IL $ SGTIN "0614141" Nothing "107346" "2017",
          IL $ SGTIN "0614141" Nothing "107346" "2018"]),
        Right (TransactionDWhat Observe Nothing
          [BizTransaction {
            _btid = "http://transaction.acme.com/po/12345678",
            _bt = Po},
          BizTransaction {
            _btid = "urn:epcglobal:cbv:bt:0614141073467:1152",
            _bt = Desadv}]
          [IL $ SGTIN "0614141" Nothing "107346" "2018"])]

  describe "parse ObjectEvent" $
    it "parses a valid object event" $ do
      doc <- Text.XML.readFile def "test/test-xml/ObjectEvent2.xml"
      let cursor = fromDocument doc
      let parsedEvents = parseEventByType cursor ObjectEventT
      length parsedEvents `shouldBe` 1
      isRight (head parsedEvents) `shouldBe` True

  -- TODO = CHECK. COPIED FROM OUTPUT. Manually checked looks correct
  -- describe "run parseTransformationDWhat" $
  --   it "parses valid DWhat" $ do
  --     doc <- Text.XML.readFile def "test/test-xml/TransformationEvent.xml"
  --     let cursor = fromDocument doc
  --     let tCursors = getCursorsByName "TransformationEvent" cursor
  --     parseTransformationDWhat <$> tCursors `shouldBe`
  --       [Right (TransformationDWhat Nothing
  --         [IL (SGTIN "4012345" Nothing "011122" "25"),
  --          IL (SGTIN "4000001" Nothing "065432" "99886655"),
  --          CL (LGTIN "4012345" "011111" "4444") (Just (MeasuredQuantity 10.0 "KGM")),
  --          CL (LGTIN "0614141" "077777" "987") (Just (ItemCount 30)),
  --          CL (CSGTIN "4012345" Nothing "066666") (Just (ItemCount 220))] 
  --         [IL (SGTIN "4012345" Nothing "077889" "25"),
  --          IL (SGTIN "4012345" Nothing "077889" "26"),
  --          IL (SGTIN "4012345" Nothing "077889" "27"),
  --          IL (SGTIN "4012345" Nothing "077889" "28")])]
