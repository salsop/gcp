#!/bin/bash
while true; do
  if ping -c 5 8.8.8.8 &> /dev/null
  then
    echo "Outbound access avaiable."
    break
  else
    echo "Waiting for Outbound access..."
    sleep 30
  fi
done

apt update
apt -y install hping3 nginx net-tools siege
dd if=/dev/zero of=/var/www/html/10M count=1024 bs=10240
curl -L https://the.earth.li/~sgtatham/putty/latest/w64/putty.zip -o /var/www/html/putty.zip


cat > /usr/local/bin/downloads.sh << EOF
#!/bin/bash
while true; do
  for i in \$(seq 1 6); do
    curl --insecure --connect-timeout 2 http://172.16.\$i.80/putty.zip -O /dev/null &>/dev/null
    sleep 20
  done
done
EOF
chmod +x /usr/local/bin/downloads.sh

echo -e '[Unit]\nDescription=downloads\n[Service]\nExecStart=/usr/local/bin/downloads.sh \n[Install]\nWantedBy=multi-user.target' > /etc/systemd/system/downloads.service
systemctl enable --now downloads


