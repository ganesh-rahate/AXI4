#  File Name:         Axi4.pro
#  Revision:          OSVVM MODELS STANDARD VERSION
#
#  Maintainer:        Jim Lewis      email:  jim@synthworks.com
#  Contributor(s):
#     Jim Lewis      jim@synthworks.com
#
#
#  Description:
#        Script to compile the Axi4 Lite models  
#
#  Developed for:
#        SynthWorks Design Inc.
#        VHDL Training Classes
#        11898 SW 128th Ave.  Tigard, Or  97223
#        http://www.SynthWorks.com
#
#  Revision History:
#    Date      Version    Description
#     1/2019   2019.01    Compile Script for OSVVM
#     1/2020   2020.01    Updated Licenses to Apache
#
#
#  This file is part of OSVVM.
#  
#  Copyright (c) 2019 - 2020 by SynthWorks Design Inc.  
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#      https://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
library osvvm_axi4
analyze ./src/Axi4MasterComponentPkg.vhd
analyze ./src/Axi4ResponderComponentPkg.vhd
analyze ./src/Axi4MemoryComponentPkg.vhd
analyze ./src/Axi4MonitorComponentPkg.vhd
analyze ./src/Axi4Context.vhd
analyze ./src/Axi4Master.vhd
analyze ./src/Axi4Monitor_dummy.vhd
analyze ./src/Axi4Responder_Transactor.vhd
analyze ./src/Axi4Memory.vhd
