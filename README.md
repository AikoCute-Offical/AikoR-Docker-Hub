# AikoR-DockerInstall
<p align="center"><img src="https://avatars.githubusercontent.com/u/91626055?v=4" width="128" /></p>

<div align="center">

# AikoR
AikoR Projects

[![](https://img.shields.io/badge/Telegram-group-green?style=flat-square)](https://t.me/AikoXrayR)
[![](https://img.shields.io/badge/Telegram-channel-blue?style=flat-square)](https://t.me/AikoCute_Support)
[![](https://img.shields.io/github/downloads/AikoCute-Offical/AikoR/total.svg?style=flat-square)](https://github.com/AikoCute-Offical/AikoR/releases)
[![](https://img.shields.io/github/v/release/AikoCute-Offical/AikoR?style=flat-square)](https://github.com/AikoCute-Offical/AikoR/releases)
[![docker](https://img.shields.io/docker/v/aikocute/aikor?label=Docker%20image&sort=semver)](https://hub.docker.com/r/aikocute/aikor)
[![Go-Report](https://goreportcard.com/badge/github.com/AikoCute-Offical/AikoR?style=flat-square)](https://goreportcard.com/report/github.com/AikoCute-Offical/AikoR)
</div>

# Multiple languages supported AikoR
- Comming Soon 

# Installation guide
1 : Install via docker

Step 1 : Install Docker

With Ubuntu/Debian

```
sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
systemctl start docker
systemctl enable docker
```
With CentOS

```
yum install -y yum-utils
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io -y
systemctl start docker
systemctl enable docker
```

Step 2 : Setting Config
    Create Config File ( the example is done in the root directory )
```
vi aiko.yml
```

Step 3 : Install
```
docker pull aikocute/aikor:latest && docker run --restart=always --name aikor -d -v /root/aiko.yml:/etc/AikoR/aiko.yml --network=host aikocute/aikor:latest
```

2 : Install With Docker_Compose ( Recomend Using )

Step 1 : Install Docker

With Ubuntu/Debian

```
sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
systemctl start docker
systemctl enable docker
```
With CentOS

```
yum install -y yum-utils
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io -y
systemctl start docker
systemctl enable docker
```

Step 2 : Install Docker Compose
```
curl -fsSL https://get.docker.com | bash -s docker
curl -L "https://github.com/docker/compose/releases/download/1.26.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

Step 3 : Custom Docker Compose

- Download the configuration library
```
git clone https://github.com/AikoCute-Offical/AikoR-Docker-Hub
```

- Library access
```
cd AikoR-DockerInstall
```

- Edit config aiko.json

- Run Docker Compose
```
docker-compose up -d
```

* Update AikoR
```
docker-compose pull
docker-compose up -d
```

* Stop AikoR
```
docker-compose down
```

