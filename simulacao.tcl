# defines
set opt(tr) "gtk10-rtc10.tr"
set opt(namtr) "gtk10-rtc10.nam"
set opt(ini) 0
set opt(stop) 1000
set opt(nnode) 180
set opt(snode) 7
set opt(principal) 6
set opt(transm) 30
set opt(dest) 10
set opt(bw) 10Mb
set opt(delay) 10ms
set opt(ifq) DropTail
set opt(pacotes) 1000
set opt(tamanho) 1000
set opt(intervalo) 1

# procedimento de fechamento da simulação (obrigatório)
proc finish {} {
	global ns opt trfd f0 f1 f2 f3 f4 f5 f6 f7 f8 f9

	$ns flush-trace

	# fechando arquivos
	close $trfd
	close $f0
	close $f1
	close $f2
	close $f3
	close $f4
	close $f5
	close $f6
	close $f7
	close $f8
	close $f9

	exit 0
}

# procedimento de criação dos arquivos da simulação
proc create-trace {} {
	global ns opt f0 f1 f2 f3 f4 f5 f6 f7 f8 f9
	
	# abrindo ou criando arquivo tr
	set trfd [open $opt(tr) w]
	set f0 [open out0.tr w]
	set f1 [open out1.tr w]
	set f2 [open out2.tr w]
	set f3 [open out3.tr w]
	set f4 [open out4.tr w]
	set f5 [open out5.tr w]
	set f6 [open out6.tr w]
	set f7 [open out7.tr w]
	set f8 [open out8.tr w]
	set f9 [open out9.tr w]

	$ns trace-all $trfd
	if {$opt(namtr) != ""} {
		# criando arquivo nam
		$ns namtrace-all [open $opt(namtr) w]
	}

	return $trfd
}

# cria as maquinas do barramento
proc create-topology {} {
	global ns opt nudp nnull sudp snull mnull
	global qtdpacotes nnode snode

	set qtdpacotes $opt(pacotes)

	# criando switchs
	for {set i 0} {$i < $opt(snode)} {incr i} {

		# criando um node
		set snode($i) [$ns node]

		# agente para enviar
		set sudp($i) [new Agent/UDP]
		# liga o agente ao node
		$ns attach-agent $snode($i) $sudp($i)

		# parametro do agente
		# fluxo de pacotes
        	$sudp($i) set fid_ $qtdpacotes
		$nudp($i) set packetSize_ 500
		$nudp($i) set ttl_ 64

		# agente para receber
		set snull($i) [new Agent/Null]
		# liga o agente ao node
		$ns attach-agent $snode($i) $snull($i)

		puts "criou switch $i"
	}

	# ligando os switchs no switch principal
	for {set i 0} {$i < [expr ($opt(snode) - 1)]} {incr i} {

		# link entre os nodes
		$ns duplex-link $snode($opt(principal)) $snode($i) $opt(bw) $opt(delay) $opt(ifq)
		# efetuando a conexão atraves dos agentes
		$ns connect $sudp($i) $snull($opt(principal))
		$ns connect $sudp($opt(principal)) $snull($i)

		puts "ligando switch 6 ao switch $i"
	}
	
	# criando as máquinas
	for {set i 0} {$i < $opt(nnode)} {incr i} {

		# crinado um node
		set nnode($i) [$ns node]

		# agente para enviar
		set nudp($i) [new Agent/UDP]
		# liga o agente ao node
		$ns attach-agent $nnode($i) $nudp($i)
		
		# parametro do agente
		# fluxo de pacotes
        	$nudp($i) set fid_ $qtdpacotes
		$nudp($i) set packetSize_ 500
		$nudp($i) set ttl_ 64


		# agente para receber
		set nnull($i) [new Agent/Null]
		# liga o agente ao node
		$ns attach-agent $nnode($i) $nnull($i)

		# agente para monitorar 
		set mnull($i) [new Agent/LossMonitor]

		puts "criou máquina $i"
	}

	# ligando as máquinas aos switchs
	for {set i 0} {$i < $opt(nnode)} {incr i} {

		# valor do switch que vai estar conectado com o node
		set vswitch [expr ($i % ($opt(snode) - 1))]
		# link entre o node e o switch escolhido
		$ns duplex-link $nnode($i) $snode($vswitch) $opt(bw) $opt(delay) $opt(ifq)
		# efetuando a conexão atraves dos agentes 
		$ns connect $sudp($vswitch) $nnull($i)
		$ns connect $nudp($i) $snull($vswitch)

		puts "ligou a máquina $i no switch $vswitch"
	}

}

# procedimento para verificar os pacotes
proc record {} {
	global mnull mon f0 f1 f2 f3 f4 f5 f6 f7 f8 f9
	# instancia de simulação
	set ns [Simulator instance]
	# tempo de chamada deste procedimento
	set time 100
	# quantidade de bytes que recebeu
	set bw0 [$mnull($mon(0)) set bytes_]
	set bw1 [$mnull($mon(1)) set bytes_]
	set bw2 [$mnull($mon(2)) set bytes_]
	set bw3 [$mnull($mon(3)) set bytes_]
	set bw4 [$mnull($mon(4)) set bytes_]
	set bw5 [$mnull($mon(5)) set bytes_]
	set bw6 [$mnull($mon(6)) set bytes_]
	set bw7 [$mnull($mon(7)) set bytes_]
	set bw8 [$mnull($mon(8)) set bytes_]
	set bw9 [$mnull($mon(9)) set bytes_]

	puts "$mon(0) pacotes $bw0"
	puts "$mon(1) pacotes $bw1"
	puts "$mon(2) pacotes $bw2"
	puts "$mon(3) pacotes $bw3"
	puts "$mon(4) pacotes $bw4"
	puts "$mon(5) pacotes $bw5"
	puts "$mon(6) pacotes $bw6"
	puts "$mon(7) pacotes $bw7"
	puts "$mon(8) pacotes $bw8"
	puts "$mon(9) pacotes $bw9"

	# tempo corrente
	set now [$ns now]

	# calcula bandwidth (em MBit/s) e escreve no arquivo
	puts $f0 "$now [expr $bw0/$time*8/1000000]"
	puts $f1 "$now [expr $bw1/$time*8/1000000]"
	puts $f2 "$now [expr $bw2/$time*8/1000000]"
	puts $f3 "$now [expr $bw3/$time*8/1000000]"
	puts $f4 "$now [expr $bw4/$time*8/1000000]"
	puts $f5 "$now [expr $bw5/$time*8/1000000]"
	puts $f6 "$now [expr $bw6/$time*8/1000000]"
	puts $f7 "$now [expr $bw7/$time*8/1000000]"
	puts $f8 "$now [expr $bw8/$time*8/1000000]"
	puts $f9 "$now [expr $bw9/$time*8/1000000]"

	# seta os valores para 0
	$mnull($mon(0)) set bytes_ 0
	$mnull($mon(1)) set bytes_ 0
	$mnull($mon(2)) set bytes_ 0
	$mnull($mon(3)) set bytes_ 0
	$mnull($mon(4)) set bytes_ 0
	$mnull($mon(5)) set bytes_ 0
	$mnull($mon(6)) set bytes_ 0
	$mnull($mon(7)) set bytes_ 0
	$mnull($mon(8)) set bytes_ 0
	$mnull($mon(9)) set bytes_ 0

	# re-calcula a chamada do procedimento
	$ns at [expr $now+$time] "record"
}

# tempos
proc tempo {} {
	global qtdpacotes interval
	# instancia de simulação
	set ns [Simulator instance]
	# tempo de chamada deste procedimento
	set time 0.5
	# aumenta quantidade de pacotes
	set qtdpacotes [expr ($qtdpacotes + 1)]
#	set interval [expr ($interval - 0.05)]
	# tempo corrente
	set now [$ns now]
	# re-calcula a chamada do procedimento
	$ns at [expr $now+$time] "tempo"
}

## MAIN ##
# criando o simulador
set ns [new Simulator]

# cores para ver aplicações no nam
$ns color 1 Blue
$ns color 2 Red

# criando os arquivos
set trfd [create-trace]

# criando o barramento entre as máquinas
create-topology

# esolhe as 30 nodes para enviar
for {set i 0} {$i < $opt(transm)} {incr i} {
	set n [expr {int(rand()*$opt(nnode))}]
    	set transm($i) $n

	puts "máquina transmissora $n $transm($i)"
}

# escolhe as 10 nodes para receber
for {set i 0} {$i < $opt(dest)} {incr i} {
	set n [expr {int(rand()*$opt(nnode))}]
    	set dest($i) $n
	set mon($i) $n

	puts "máquina receptora $n"
}

# criando o envio de pacotes
for {set i 0} {$i < $opt(transm)} {incr i} {

	# criando uma aplicação de trafego CRB ( BIT RATE)
	set cbr($i) [new Application/Traffic/CBR]

	# ligando a aplicação ao node
	$cbr($i) attach-agent $nudp($transm($i))

	# parametro do pacote
	$cbr($i) set packetSize_ 200
	$cbr($i) set interval_ 1

	# tempo de inicio do envio de pacotes
	$ns at $opt(ini) "$cbr($i) start"
	# tempo que para o envio de pacotes
	$ns at $opt(stop) "$cbr($i) stop"

	for {set j 0} {$j < $opt(dest)} {incr j} {
		# liga o agente ao node
		$ns attach-agent $nnode($dest($j)) $mnull($mon($j))
		$ns connect $nudp($transm($i)) $nnull($dest($j))
		$ns connect $nudp($transm($i)) $mnull($mon($j))

		puts "conectou a máquina $transm($i) com $dest($j)"
	}
}

$ns at $opt(ini) "tempo"
# inicia a gravação nos arquivos 
$ns at $opt(ini) "record"
# tempo de término do envio de pacotes
$ns at $opt(stop) "finish"
# rodando a simulação
$ns run
