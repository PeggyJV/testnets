# Systemd

The following are example systemd unit files to help you manage the variety of services we are running to support the network. Systemd unit files live in `/etc/systemd/system/` and any changes in that folder require a restart of the the systemd process to take effect: `sudo systemctl daemon-reload`

> NOTE: These files are all written for the `ubuntu` user. The user on your system may be different as well as having different `ExecStart` locations. Make sure the files are customized for your environment!!!

## `/etc/systemd/system/sommelier.service`

```
[Unit]
Description=Sommelier Node
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/usr/bin/sommelier start
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
```

## `/etc/systemd/system/orchestrator.service`

> NOTE: The cosmos-key and ethereum-key arguments are referencing keys we will be creating at a later step.

```
[Unit]
Description=Sommelier Node
After=network.target

[Service]
Type=simple
User=ubuntu
Environment="RUST_LOG=INFO"
WorkingDirectory=/home/ubuntu
ExecStart=/usr/bin/gorc --config /home/ubuntu/gorc/config.toml orchestrator start --cosmos-key orchestrator --ethereum-key signer
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
```

## `/etc/systemd/system/geth.service`

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
