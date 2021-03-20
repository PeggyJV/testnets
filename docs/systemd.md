# Systemd

The following are example systemd unit files to help you manage the variety of services we are running to support the network. Systemd unit files live in `/etc/systemd/system/` and any changes in that folder require a restart of the the systemd process to take effect: `sudo systemctl daemon-reload`

> NOTE: These files are all written for the `ubuntu` user. The user on your system may be different as well as having different `ExecStart` locations. Make sure the files are customized for your environment!!!

### `/etc/systemd/system/sommelier.service`

```
[Unit]
Description=Sommelier Node
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/home/ubuntu/go/bin/sommelier start
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
```

### `/etc/systemd/system/oracle-feeder.service`

```
[Unit]
Description=Oracle Feeder
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/home/ubuntu/go/bin/oracle-feeder start
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
```

### `/etc/systemd/system/orchestrator.service`

> NOTE: The orchestrator requires some arguements from the key generation step later in the setup. Make sure to save the phrase from the cosmos key generation as well as the private key from the ETH key generation and input them as arguements here. 

> NOTE: This also requires the peggy address on the ETH chain which will not be available until after network start.

```
[Unit]
Description=Sommelier Node
After=network.target

[Service]
Type=simple
User=ubuntu
Environment="RUST_LOG=INFO"
WorkingDirectory=/home/ubuntu
ExecStart=/usr/bin/orchestrator --cosmos-phrase="" --ethereum-key="" --cosmos-legacy-rpc="http://localhost:1317" --cosmos-grpc="http://localhost:9090" --ethereum-rpc="http://localhost:8545" --fees=stake --contract-address=""
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
```

### `/etc/systemd/system/geth.service`

```
[Unit]
Description=Sommelier Node
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/usr/bin/geth --syncmode "light" --goerli --http --cache 16
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
```
