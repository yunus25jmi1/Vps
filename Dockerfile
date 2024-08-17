FROM python:alpine

WORKDIR /app

COPY ./app/requirements.txt /app/app/
RUN pip install --no-cache-dir -r /app/app/requirements.txt

RUN wget https://pkgs.tailscale.com/stable/$(wget -q -O- https://pkgs.tailscale.com/stable/ | grep 'amd64.tgz' | cut -d '"' -f 2) && \
    tar xzf tailscale* --strip-components=1
RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale

#ENV PORT 1229
#EXPOSE 1229

COPY . .
CMD /app/app/start.sh

FROM ubuntu

# install docker software  
RUN apt-get -y update && apt-get install --fix-missing && apt-get -y install docker.io snap snapd 
ARG NGROK_TOKEN
ARG REGION=ap
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt upgrade -y && apt install -y \
    ssh wget unzip vim curl python3 sudo ca-certificates curl gnupg lsb-release ufw iptables network-manager tmux net-tools iputils-ping netplan.io  ssh wget unzip vim curl python3 sudo ca-certificates curl gnupg lsb-release ufw

ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i  's/#user_allow_other/user_allow_other/g' /etc/fuse.conf
COPY rclone.conf /.config/rclone/    

# Use bash shell
ENV SHELL=/bin/bash

# Copy rclone tasks to /tmp, to potentially be used
COPY deploy-container/rclone-tasks.json /tmp/rclone-tasks.json

RUN wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz -O /ngrok-v3-stable-linux-amd64.tgz \
  && tar -xzf ngrok-v3-stable-linux-amd64.tgz
  && chmod +x ngrok 
RUN mkdir /run/sshd \
    && echo "/ngrok tcp --authtoken ${NGROK_TOKEN} --region ${REGION} 22 &" >>/openssh.sh \
    && echo "sleep 5" >> /openssh.sh \
    && echo "curl -s http://localhost:4040/api/tunnels | python3 -c \"import sys, json; print(\\\"ssh info:\\\n\\\",\\\"ssh\\\",\\\"root@\\\"+json.load(sys.stdin)['tunnels'][0]['public_url'][6:].replace(':', ' -p '),\\\"\\\nROOT Password:craxid\\\")\" || echo \"\nError：NGROK_TOKEN，Ngrok Token\n\"" >> /openssh.sh \
    && echo '/usr/sbin/sshd -D' >>/openssh.sh \
    && echo 'PermitRootLogin yes' >>  /etc/ssh/sshd_config  \
    && echo root:Yunus2512|chpasswd \
    && chmod 755 /openssh.sh 
EXPOSE 80 443 3306 4040 5432 5700 5701 5010 6800 6900 8080 8888 9000 7800 3000 80 9800
CMD tmux
     
CMD /openssh.sh
