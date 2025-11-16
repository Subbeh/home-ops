# Flush ARP on all k8s nodes
for node in k8s-nuc k8s-opti-01 k8s-opti-02; do
  echo "Flushing ARP on $node..."
  kubectl run "arp-flush-$node" --image=nicolaka/netshoot --rm -i \
    --restart=Never --overrides="{\"spec\":{\"hostNetwork\":true,\"nodeName\":\"$node\"}}" \
    -- sh -c "ip -s -s neigh flush all; echo done" 2>/dev/null ||
    true
done

# Send gratuitous ARP from local machine
arping -c 3 -A -I $(ip route get 10.11.10.1 | grep -oP '(?<=dev )\S+') \
  $(ip -4 addr show $(ip route get 10.11.10.1 | grep -oP '(?<=dev)\S+') | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
