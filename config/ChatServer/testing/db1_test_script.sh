cd "/tmp/Chat Server/bin64"
chmod +x chat_server
pkill chat_server
pkill --signal 9 chat_server
ulimit -n 99999
sysctl -w net.ipv4.ip_local_port_range="1024 65535"

for i in {6..11}
do
	begin=$((i*10000+1))
	end=$(((i+1)*10000))
	./chat_server -autoexec "cs_masterServerAddress test.s2ogi.strife.com; MultiClientTester $begin $end 173.192.114.57" &
	echo "Spawned $begin to $end"
done
