# This script is created by P.L. Wu <wupl@cse.nsysu.edu.tw>
#===================================
#              定義模擬變數                           
#===================================

set val(chan)   Channel/WirelessChannel    ;# channel type
set val(prop)   Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)  Phy/WirelessPhy            ;# network interface type
set val(mac)    Mac/802_11            ;# MAC type
set val(ifq)    Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)     LL                         ;# link layer type
set val(ant)    Antenna/OmniAntenna        ;# antenna model
set val(ifqlen) 50                         ;# max packet in ifq
set val(nn)     3        ;# number of mobilenodes
set val(rp)     DSDV     ;# routing protocol
set val(x)      1000            ;# X dimension of topography
set val(y)      1000           ;# Y dimension of topography
set val(stop)   10.0 ;# time of simulation end

#===================================
#               建立相關檔案                         
#===================================

#設定trace file
set ns            [new Simulator]	;#產生ns simulator
set tracefd       [open lab6.tr w]	;#產生trace file
set namtrace       [open lab6.nam w]	;#產生產生nam trace file

$ns trace-all $tracefd
$ns namtrace-all-wireless $namtrace $val(x) $val(y)

set topo       [new Topography]	    ;#產生topography object
$topo load_flatgrid $val(x) $val(y)

create-god $val(nn)

#建立channel
set chan0 [new $val(chan)]

#===================================
#        設定MobileNode的參數                      
#===================================

#設定MobileNode的參數
$ns node-config -adhocRouting $val(rp) \
                -llType $val(ll) \
                -macType $val(mac) \
                -ifqType $val(ifq) \
                -ifqLen $val(ifqlen) \
                -antType $val(ant) \
                -propType $val(prop) \
                -phyType $val(netif) \
                -channel $chan0 \
                -topoInstance $topo \
                -agentTrace OFF \
                -routerTrace OFF \
                -macTrace ON \
                -movementTrace OFF

#===================================
#             產生Node              
#===================================

#建立第0個Node
set node_(0) [$ns node]
$node_(0) set X_ 600
$node_(0) set Y_ 798
$node_(0) set Z_ 0.0
$ns initial_node_pos $node_(0) 20

#建立第1個Node
set node_(1) [$ns node]
$node_(1) set X_ 802
$node_(1) set Y_ 798
$node_(1) set Z_ 0.0
$ns initial_node_pos $node_(1) 20

#建立第2個Node
set node_(2) [$ns node]
$node_(2) set X_ 600
$node_(2) set Y_ 600
$node_(2) set Z_ 0.0
$ns initial_node_pos $node_(2) 20

#===================================
#               設定連線                                 
#===================================

#設定第0個連線(CBR-UDP)
set udp0 [new Agent/UDP]
$ns attach-agent $node_(0) $udp0
set null0 [new Agent/Null]
$ns attach-agent $node_(1) $null0
$ns connect $udp0 $null0
$udp0 set fid_ 2	;#在NAM中，UDP的連線會以紅色表示
set cbr0 [new Application/Traffic/CBR]	;#在UDP連線之上建立CBR應用程式
$cbr0 attach-agent $udp0
$cbr0 set type_ CBR
$cbr0 set packet_size_ 1000;#設定封包大小
$cbr0 set rate_ 512Kb ;#設定傳輸速率
$cbr0 set random_ false
$ns at 0.0 "$cbr0 start"
$ns at 10.0 "$cbr0 stop"

#設定第1個連線(FTP-TCP)
set tcp1 [new Agent/TCP/Newreno]
$tcp1 set class_ 2
set sink1 [new Agent/TCPSink]
$ns attach-agent $node_(0) $tcp1
$ns attach-agent $node_(2) $sink1
$ns connect $tcp1 $sink1
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ns at 0.0 "$ftp1 start"
$ns at 10.0 "$ftp1 stop"

#===================================
#              結束模擬                                   
#===================================

#設定Ping專用的recv function
Agent/Ping instproc recv {from rtt} {
    $self instvar node_
    puts "node [$node_ id] received ping answer from $from with round-trip-time $rtt ms."
}

# 告訴MobileNode模擬已結束
for {set i 0} {$i < $val(nn) } { incr i } {
    $ns at $val(stop) "$node_($i) reset";
}

# 結束nam與模擬器
$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
$ns at $val(stop) "stop"
$ns at 10.1 "puts \"end simulation\" ; $ns halt"

# 設定模擬器用的stop function
proc stop {} {
    global ns tracefd namtrace
    $ns flush-trace
    close $tracefd
    close $namtrace
}

$ns run
