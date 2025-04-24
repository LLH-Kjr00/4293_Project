sudo apt-get update

# Install
sudo apt-get install sysbench  # Debian/Ubuntu

# CPU Test (Prime number calculation)
sysbench cpu --cpu-max-prime=20000 run

# Memory Test (Throughput)

 memory --memory-block-size=1K --memory-total-size=100G run

# File I/O Test (Sequential & Random)
sysbench fileio --threads=16 --file-total-size=3G --file-test-mode=rndrw prepare
sysbench fileio --threads=16 --file-total-size=3G --file-test-mode=rndrw run
sysbench fileio --threads=16 --file-total-size=3G --file-test-mode=rndrw cleanup