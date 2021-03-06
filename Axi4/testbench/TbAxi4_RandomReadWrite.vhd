--
--  File Name:         TbAxi4_RandomReadWrite.vhd
--  Design Unit Name:  Architecture of TestCtrl
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      Test transaction source
--
--
--  Developed by:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        http://www.SynthWorks.com
--
--  Revision History:
--    Date      Version    Description
--    09/2017   2017       Initial revision
--    01/2020   2020.01    Updated license notice
--
--
--  This file is part of OSVVM.
--  
--  Copyright (c) 2017 - 2020 by SynthWorks Design Inc.  
--  
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--  
--      https://www.apache.org/licenses/LICENSE-2.0
--  
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
--  

architecture RandomReadWrite of TestCtrl is

  signal TestDone : integer_barrier := 1 ;
  
  type OpType is (WRITE_OP_ENUM, READ_OP_ENUM) ;  -- Add TEST_DONE?
  -- constant NO_OP_INDEX    : integer := OpType'pos(NO_OP) ;
  constant WRITE_OP_INDEX : integer := OpType'pos(WRITE_OP_ENUM) ;
  constant READ_OP_INDEX  : integer := OpType'pos(READ_OP_ENUM) ;
  subtype OperationType is std_logic_vector(0 downto 0) ;
  constant WRITE_OP : OperationType := to_slv(WRITE_OP_INDEX, OperationType'length) ;
  constant READ_OP : OperationType := to_slv(READ_OP_INDEX, OperationType'length) ;

  shared variable OperationFifo  : osvvm.ScoreboardPkg_slv.ScoreboardPType ; 
  
  signal TestActive : boolean := TRUE ;
  
  signal OperationCount : integer := 0 ; 
 
begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetAlertLogName("TbAxi4_RandomReadWrite") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    SetLogEnable(INFO, TRUE) ;    -- Enable INFO logs

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen("./results/TbAxi4_RandomReadWrite.txt") ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;

    -- Wait for test to finish
    WaitForBarrier(TestDone, 1 ms) ;
    AlertIf(now >= 1 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ; 
    -- Printing differs in different simulators due to differences in process order execution
    -- AlertIfDiff("./results/TbAxi4_RandomReadWrite.txt", "../sim_shared/validated_results/TbAxi4_RandomReadWrite.txt", "") ; 
    
    print("") ;
    ReportAlerts ; 
    print("") ;
    std.env.stop ; 
    wait ; 
  end process ControlProc ; 

  
  ------------------------------------------------------------
  -- AxiSuperProc
  --   Generate transactions for AxiSuper
  ------------------------------------------------------------
  AxiSuperProc : process
    variable OpRV      : RandomPType ;   
    variable NoOpRV    : RandomPType ;   
    variable Operation : OperationType ; 
    variable Address   : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0) ;
    variable Data      : std_logic_vector(AXI_DATA_WIDTH-1 downto 0) ;    
    variable ReadData  : std_logic_vector(AXI_DATA_WIDTH-1 downto 0) ;    
    
    variable counts : integer_vector(0 to OpType'Pos(OpType'Right)) ; 
  begin
    -- Initialize Randomization Objects
    OpRV.InitSeed(OpRv'instance_name) ;
    NoOpRV.InitSeed(NoOpRV'instance_name) ;
    
    -- Find exit of reset
    wait until nReset = '1' ;  
    NoOp(AxiSuperTransRec, 2) ; 
    
    -- Distribution for Test Operations
    counts := (WRITE_OP_INDEX => 500, READ_OP_INDEX => 500) ;
    
    OperationLoop : loop
      -- Calculate Address and Data if Write or Read Operation
      Address   := OpRV.RandSlv(size => AXI_ADDR_WIDTH - 2) & "00" ;  -- Keep address word aligned
      Data      := OpRV.RandSlv(size => AXI_DATA_WIDTH) ;
      Operation := to_slv(OpRV.DistInt(counts), Operation'length) ;
      OperationFifo.push(Operation & Address & Data) ;
      Increment(OperationCount) ;
      
      -- 20 % of the time add a no-op cycle with a delay of 1 to 5 clocks
      if NoOpRV.DistInt((8, 2)) = 1 then 
        NoOp(AxiSuperTransRec, NoOpRV.RandInt(1, 5)) ; 
      end if ; 
      
      -- Do the Operation
      case Operation is
        when WRITE_OP =>  
          counts(WRITE_OP_INDEX) := counts(WRITE_OP_INDEX) - 1 ; 
          -- Log("Starting: Super Write with Address: " & to_hstring(Address) & "  Data: " & to_hstring(Data) ) ;
          Write(AxiSuperTransRec, Address, Data) ;
          
        when READ_OP =>  
          counts(READ_OP_INDEX) := counts(READ_OP_INDEX) - 1 ; 
          -- Log("Starting: Super Read with Address: " & to_hstring(Address) & "  Data: " & to_hstring(Data) ) ;
          Read(AxiSuperTransRec, Address, ReadData) ;
          AffirmIf(ReadData = Data, "AXI Super Read Data: "& to_hstring(ReadData), 
                   "  Expected: " & to_hstring(Data)) ;

        when others =>
          Alert("Invalid Operation Generated", FAILURE) ;
      end case ;
      
      exit when counts = (0, 0) ;
    end loop OperationLoop ; 
    
    TestActive <= FALSE ; 
    -- Allow Minion to catch up before signaling OperationCount (needed when WRITE_OP is last)
    -- wait for 0 ns ;  -- this is enough
    NoOp(AxiSuperTransRec, 2) ;
    Increment(OperationCount) ;
    
    -- Wait for outputs to propagate and signal TestDone
    NoOp(AxiSuperTransRec, 2) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process AxiSuperProc ;


  ------------------------------------------------------------
  -- AxiMinionProc
  --   Generate transactions for AxiMinion
  ------------------------------------------------------------
  AxiMinionProc : process
    variable NoOpRV         : RandomPType ;   
    variable Operation      : OperationType ; 
    variable Address        : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0) ;
    variable ActualAddress  : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0) ;
    variable Data           : std_logic_vector(AXI_DATA_WIDTH-1 downto 0) ;    
    variable WriteData      : std_logic_vector(AXI_DATA_WIDTH-1 downto 0) ;    
  begin
    NoOpRV.InitSeed(NoOpRV'instance_name) ;

    OperationLoop : loop   
      if OperationFifo.empty then
        WaitForToggle(OperationCount) ; 
      end if ; 
      
      exit OperationLoop when TestActive = FALSE ; 
      
      -- 20 % of the time add a no-op cycle with a delay of 1 to 5 clocks
      if NoOpRV.DistInt((8, 2)) = 1 then 
        NoOp(AxiMinionTransRec, NoOpRV.RandInt(1, 5)) ; 
      end if ; 
      
      -- Get the Operation
      (Operation, Address, Data) := OperationFifo.pop ; 
      
      -- Do the Operation
      case Operation is
        when WRITE_OP =>  
          -- Log("Starting: Minion Write with Expected Address: " & to_hstring(Address) & "  Data: " & to_hstring(Data) ) ;
          GetWrite(AxiMinionTransRec, ActualAddress, WriteData) ;
          AffirmIf(ActualAddress = Address, "AXI Minion Write Address: " & to_hstring(ActualAddress), 
                   "  Expected: " & to_hstring(Address)) ;
          AffirmIf(WriteData = Data, "AXI Minion Write Data: "& to_hstring(WriteData), 
                   "  Expected: " & to_hstring(Data)) ;
          
        when READ_OP =>  
          -- Log("Starting: Minion Read with Expected Address: " & to_hstring(Address) & "  Data: " & to_hstring(Data) ) ;
          SendRead(AxiMinionTransRec, ActualAddress, Data) ; 
          AffirmIf(ActualAddress = Address, "AXI Minion Read Address: " & to_hstring(ActualAddress), 
                   "  Expected: " & to_hstring(Address)) ;

        when others =>
          Alert("Invalid Operation Generated", FAILURE) ;
          
      end case ;
      
    end loop OperationLoop ; 

    -- Wait for outputs to propagate and signal TestDone
    -- NoOp(AxiMinionTransRec, 2) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process AxiMinionProc ;


end RandomReadWrite ;

Configuration TbAxi4_RandomReadWrite of TbAxi4 is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(RandomReadWrite) ; 
    end for ; 
  end for ; 
end TbAxi4_RandomReadWrite ; 