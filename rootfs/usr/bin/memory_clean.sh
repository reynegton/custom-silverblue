echo “Limpando Cache e Swap…”
sync; echo 1 > /proc/sys/vm/drop_caches
swapoff -av ; swapon -av
echo “Limpeza do Cache e Swap efetuada com sucesso”


