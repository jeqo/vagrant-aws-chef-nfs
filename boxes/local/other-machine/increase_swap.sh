#!/bin/sh
 
# size of swapfile in megabytes
swapsize=2048
 
# does the swap file already exist?
grep -q "/var/swap.1" /etc/fstab
 
# if not then create it
if [ $? -ne 0 ]; then
	echo 'swapfile not found. Adding swapfile.'
	sudo /bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=${swapsize}
	chmod 600 /var/swap.1
	sudo mkswap /var/swap.1
	sudo swapon /var/swap.1
	echo '/var/swap.1 swap swap defaults 0 0' >> /etc/fstab
else
	echo 'swapfile found. No changes made.'
fi
 
# output results to terminal
df -h
cat /proc/swaps
cat /proc/meminfo | grep Swap



