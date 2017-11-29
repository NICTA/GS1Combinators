{-# LANGUAGE DataKinds #-}

module Tests.DWhat where

import           Data.Maybe
import           Test.Hspec

import           Data.GS1.DWhat
import           Data.GS1.EPC
import           Data.GS1.Object

testBizStep :: Spec
testBizStep = do
  describe "BusinessStep" $ do
    it "produces correct URI" $
      printURI Accepting `shouldBe` "urn:epcglobal:cbv:bizstep:accepting"
    it "produces correct URI" $
      printURI CycleCounting `shouldBe` "urn:epcglobal:cbv:bizstep:cycle_counting"
    it "produces correct URI" $
      printURI CreatingClassInstance `shouldBe` "urn:epcglobal:cbv:bizstep:creating_class_instance"
  
  describe "parseBizStep" $ do
    it "parse valid uri to bizstep" $
      readURI "urn:epcglobal:cbv:bizstep:void_shipping" `shouldBe` Just VoidShipping

    it "parse valid uri to bizstep" $
      readURI "urn:epcglobal:cbv:bizstep:accepting" `shouldBe` Just Accepting
  
  describe "Invalid urns" $ do
    it "parse valid uri but invalid step to Nothing" $
      (readURI :: String -> Maybe BizStep) "urn:epcglobal:cbv:bizstep:s" `shouldBe` Nothing

    it "parse invalid uri to Nothing" $
      (readURI :: String -> Maybe BizStep) "urn:invalidns:cbv:bizstep:void_shipping"
        `shouldBe` Nothing
    it "A component of the urn missing" $
      (readURI :: String -> Maybe BizStep) "urn:epc:cbv:bizstep"
        `shouldBe` Nothing
    it "empty" $
      (readURI :: String -> Maybe BizStep) "" `shouldBe` Nothing

testBizTransaction :: Spec
testBizTransaction = do
  describe "Parse BizTransactionID" $
    it "parse the valid uri to BizTransactionID" $
      readURI "urn:epcglobal:cbv:btt:po" `shouldBe` Just Po

  describe "Invalid urns" $ do
    it "parse the invalid uri to Nothing" $
      (readURI :: String -> Maybe BizTransactionType) "urn:epcglobal:cbv:btt:somethingelse"
        `shouldBe` Nothing
    it "parse the empty uri to Nothing" $
      (readURI :: String -> Maybe BizTransactionType) "" `shouldBe` Nothing
    it "parse a uri missing component with to Nothing" $
      (readURI :: String -> Maybe BizTransactionType) "urn:epcglobal:cbv:po" `shouldBe` Nothing
    it "parse a rubbish uri with no : to Nothing" $
      (readURI :: String -> Maybe BizTransactionType) "fooblahjaja" `shouldBe` Nothing

  describe "print BizTransaction" $ do
    it "print BizTransaction 1" $
      printURI Bol `shouldBe` "urn:epcglobal:cbv:btt:bol"
    it "print BizTransaction 2" $
      printURI Prodorder `shouldBe` "urn:epcglobal:cbv:btt:prodorder"

-- FIXME - ppDWhat needs a spec. These tests have been based on current output and checking ppDWhat preserves information in output.

-- TODO test for quantity
testPpDWhat :: Spec
testPpDWhat = do
  describe "create valid ObjectDWhat" $ do
    it "creates ObjectDWhat from valid input, Observe" $
      ppDWhat (ObjectDWhat Observe [IL (SGTIN "0614141" Nothing "107346" "2017"),
        IL (SGTIN "0614141" Nothing "107346" "2018")])
          `shouldBe`
            "OBJECT WHAT\nObserve\n" ++
            "[IL (SGTIN \"0614141\" Nothing \"107346\" \"2017\")," ++
            "IL (SGTIN \"0614141\" Nothing \"107346\" \"2018\")]\n"
            -- DELETEME
            --"OBJECT WHAT\nObserve\n[urn:epc:id:sgtin:0614141.107346.2017,urn:epc:id:sgtin:0614141.107346.2018]\n[]"

    it "creates ObjectDWhat from valid input, Add" $
      ppDWhat (ObjectDWhat Add [IL (SGTIN "0614141" Nothing "107346" "2017"),
        IL (SGTIN "0614141" Nothing "107346" "2018")])
          `shouldBe`
            "OBJECT WHAT\nAdd\n" ++
            "[IL (SGTIN \"0614141\" Nothing \"107346\" \"2017\")," ++
            "IL (SGTIN \"0614141\" Nothing \"107346\" \"2018\")]\n"
    it "creates ObjectDWhat from valid input, Delete" $
      ppDWhat (ObjectDWhat Delete [IL (SGTIN "0614141" Nothing "107346" "2017"),
        IL (SGTIN "0614141" Nothing "107346" "2018")])
          `shouldBe`
            "OBJECT WHAT\nDelete\n" ++
            "[IL (SGTIN \"0614141\" Nothing \"107346\" \"2017\")," ++
            "IL (SGTIN \"0614141\" Nothing \"107346\" \"2018\")]\n"

  describe "create from empty epcs" $ do
    it "creates DWhat from empty epc list, Add" $
      ppDWhat (ObjectDWhat Add []) `shouldBe` "OBJECT WHAT\nAdd\n[]\n"
    it "creates DWhat from empty epc list, Delete" $
      ppDWhat (ObjectDWhat Delete []) `shouldBe` "OBJECT WHAT\nDelete\n[]\n"
    it "creates DWhat from empty epc list Observe" $
      ppDWhat (ObjectDWhat Observe []) `shouldBe` "OBJECT WHAT\nObserve\n[]\n"
     
  describe "create valid AggregationDWhat" $ do
    it "creates AggregationDWhat from valid input, Observe" $
      ppDWhat (AggregationDWhat Observe 
        (Just (IL (SSCC "0614141" "1234567890")))
        [IL (SGTIN "0614141" Nothing "107346" "2017"),
        IL (SGTIN "0614141" Nothing "107346" "2018")])
          `shouldBe`
            "AGGREGATION WHAT\nObserve\nJust (IL (SSCC \"0614141\" \"1234567890\"))\n" ++
            "[IL (SGTIN \"0614141\" Nothing \"107346\" \"2017\")," ++
            "IL (SGTIN \"0614141\" Nothing \"107346\" \"2018\")]\n"
          -- DELETEME
          --"AGGREGATION WHAT\n" ++ "Observe\n" ++
          --"Just \"urn:epc:id:sscc:0614141.1234567890\"\n" ++ 
          --"[urn:epc:id:sgtin:0614141.107346.2017," ++
          --"urn:epc:id:sgtin:0614141.107346.2018]\n" ++
          --"[QuantityElement (EPCClass \"urn:epc:idpat:sgtin:4012345.098765.*\") 10.0 Nothing," ++
          --"QuantityElement (EPCClass \"urn:epc:class:lgtin:4012345.012345.998877\") 200.5 (Just \"KGM\")]"

    it "creates AggregationDWhat from valid input, Add" $
      ppDWhat (AggregationDWhat Add
        (Just (IL (SSCC "0614141" "1234567890")))
        [IL (SGTIN "0614141" Nothing "107346" "2017"),
        IL (SGTIN "0614141" Nothing "107346" "2018")])
          `shouldBe`
            "AGGREGATION WHAT\nAdd\nJust (IL (SSCC \"0614141\" \"1234567890\"))\n" ++
            "[IL (SGTIN \"0614141\" Nothing \"107346\" \"2017\")," ++
            "IL (SGTIN \"0614141\" Nothing \"107346\" \"2018\")]\n"

    it "creates AggregationDWhat from valid input, Delete" $
      ppDWhat (AggregationDWhat Delete
        (Just (IL (SSCC "0614141" "1234567890")))
        [IL (SGTIN "0614141" Nothing "107346" "2017"),
        IL (SGTIN "0614141" Nothing "107346" "2018")])
          `shouldBe`
            "AGGREGATION WHAT\nDelete\nJust (IL (SSCC \"0614141\" \"1234567890\"))\n" ++
            "[IL (SGTIN \"0614141\" Nothing \"107346\" \"2017\")," ++
            "IL (SGTIN \"0614141\" Nothing \"107346\" \"2018\")]\n"

    it "createAggregationDWhat from empty, Delete" $
      ppDWhat (AggregationDWhat Delete Nothing [])
        `shouldBe` "AGGREGATION WHAT\nDelete\nNothing\n[]\n"
    it "createAggregationDWhat from empty, Add" $
      ppDWhat (AggregationDWhat Add Nothing [])
        `shouldBe` "AGGREGATION WHAT\nAdd\nNothing\n[]\n"
    it "createAggregationDWhat from empty, Observe" $
      ppDWhat (AggregationDWhat Observe Nothing [])
        `shouldBe` "AGGREGATION WHAT\nObserve\nNothing\n[]\n"
  

  describe "work with a TransactionDWhat" $ do
    it "create TransactionDWhat from valid input, Add" $
      ppDWhat (TransactionDWhat Add
        (Just (IL (SSCC "0614141" "1234567890")))
        [BizTransaction{_btid="12345", _bt=Bol}]
        [IL (SGTIN "0614141" Nothing "107346" "2017"),
        IL (SGTIN "0614141" Nothing "107346" "2018")])
          `shouldBe`
            "TRANSACTION WHAT\nAdd\n" ++
            "Just (IL (SSCC \"0614141\" \"1234567890\"))\n" ++
            "[BizTransaction {_btid = \"12345\", _bt = Bol}]\n" ++
            "[IL (SGTIN \"0614141\" Nothing \"107346\" \"2017\")," ++
            "IL (SGTIN \"0614141\" Nothing \"107346\" \"2018\")]\n"
    it "create TransactionDWhat from valid input, Observe" $
      ppDWhat (TransactionDWhat Observe
        (Just (IL (SSCC "0614141" "1234567890")))
        [BizTransaction{_btid="12345", _bt=Bol}]
        [IL (SGTIN "0614141" Nothing "107346" "2017"),
        IL (SGTIN "0614141" Nothing "107346" "2018")])
          `shouldBe`
            "TRANSACTION WHAT\nObserve\n" ++
            "Just (IL (SSCC \"0614141\" \"1234567890\"))\n" ++
            "[BizTransaction {_btid = \"12345\", _bt = Bol}]\n" ++
            "[IL (SGTIN \"0614141\" Nothing \"107346\" \"2017\")," ++
            "IL (SGTIN \"0614141\" Nothing \"107346\" \"2018\")]\n"
    it "create TransactionDWhat from valid input, Delete" $
      ppDWhat (TransactionDWhat Delete
        (Just (IL (SSCC "0614141" "1234567890")))
        [BizTransaction{_btid="12345", _bt=Bol}]
        [IL (SGTIN "0614141" Nothing "107346" "2017"),
        IL (SGTIN "0614141" Nothing "107346" "2018")])
          `shouldBe`
            "TRANSACTION WHAT\nDelete\n" ++
            "Just (IL (SSCC \"0614141\" \"1234567890\"))\n" ++
            "[BizTransaction {_btid = \"12345\", _bt = Bol}]\n" ++
            "[IL (SGTIN \"0614141\" Nothing \"107346\" \"2017\")," ++
            "IL (SGTIN \"0614141\" Nothing \"107346\" \"2018\")]\n"

    it "empty TransactionDWhat with empty, Add" $
      ppDWhat (TransactionDWhat Add Nothing [] [])
        `shouldBe` "TRANSACTION WHAT\nAdd\nNothing\n[]\n[]\n"
    it "empty TransactionDWhat with empty, Delete" $
      ppDWhat (TransactionDWhat Delete Nothing [] [])
        `shouldBe` "TRANSACTION WHAT\nDelete\nNothing\n[]\n[]\n"
    it "empty TransactionDWhat with empty, Observe" $
      ppDWhat (TransactionDWhat Observe Nothing [] [])
        `shouldBe` "TRANSACTION WHAT\nObserve\nNothing\n[]\n[]\n"

         
  describe "work with a TransformationDWhat" $ do
    it "create TransformationDWhat" $
      ppDWhat (TransformationDWhat (Just "12345")
        [IL (SGTIN "0614141__" Nothing "107346__" "2017__"),
        IL (SGTIN "0614141__" Nothing "107346__" "2018__")]
        [IL (SGTIN "0614141" Nothing "107346" "2017"),
        IL (SGTIN "0614141" Nothing "107346" "2018")])
          `shouldBe`
          "TRANSFORMATION WHAT\nJust \"12345\"\n" ++
          "[IL (SGTIN \"0614141__\" Nothing \"107346__\" \"2017__\")," ++
          "IL (SGTIN \"0614141__\" Nothing \"107346__\" \"2018__\")]\n" ++
          "[IL (SGTIN \"0614141\" Nothing \"107346\" \"2017\")," ++
          "IL (SGTIN \"0614141\" Nothing \"107346\" \"2018\")]\n"
    
    it "create TransformationDWhat, empty" $
      ppDWhat (TransformationDWhat Nothing [] [])
        `shouldBe` "TRANSFORMATION WHAT\nNothing\n[]\n[]\n"
