#!/bin/bash
# CMH Horizonte · Instalador del vigilante de red de la PBX
# Renueva la IP de enp0s3 (adaptador puente) cuando la laptop host cambia de red.
# Desinstalar: systemctl disable --now cmh-red-vigilante.timer && rm /etc/systemd/system/cmh-red-vigilante.* /usr/local/sbin/cmh-red-vigilante.sh && systemctl daemon-reload
set -e

cat > /usr/local/sbin/cmh-red-vigilante.sh <<'EOF'
#!/bin/bash
IF=enp0s3
GW=$(ip -4 route show default dev "$IF" | awk '{print $3; exit}')

hay_salida() {
  [ -n "$GW" ] && ping -c1 -W2 -I "$IF" "$GW" >/dev/null 2>&1 && return 0
  ping -c1 -W2 -I "$IF" 1.1.1.1 >/dev/null 2>&1 && return 0
  timeout 3 bash -c '</dev/tcp/1.1.1.1/443' >/dev/null 2>&1
}

hay_salida && exit 0
sleep 3
hay_salida && exit 0

ANT=$(ip -4 -br addr show "$IF" | awk '{print $3}')
logger -t cmh-red "Sin salida por $IF (${ANT:-sin IP}, gw ${GW:-ninguno}). Renovando DHCP."
/usr/sbin/ifdown --force "$IF" >/dev/null 2>&1 || true
ip -4 addr flush dev "$IF"
/usr/sbin/ifup "$IF" >/dev/null 2>&1 || true
NUE=$(ip -4 -br addr show "$IF" | awk '{print $3}')
logger -t cmh-red "Nueva IP en $IF: ${NUE:-ninguna}"
EOF
chmod 755 /usr/local/sbin/cmh-red-vigilante.sh

cat > /etc/systemd/system/cmh-red-vigilante.service <<'EOF'
[Unit]
Description=CMH, renueva la IP de la PBX si cambia la red de la laptop host
After=network.target

[Service]
Type=oneshot
TimeoutStartSec=90
ExecStart=/usr/local/sbin/cmh-red-vigilante.sh
EOF

cat > /etc/systemd/system/cmh-red-vigilante.timer <<'EOF'
[Unit]
Description=Revisa la red de la PBX cada 30 segundos

[Timer]
OnBootSec=60
OnUnitActiveSec=30
AccuracySec=5

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now cmh-red-vigilante.timer
echo
echo "Vigilante de red instalado:"
systemctl list-timers cmh-red-vigilante.timer --no-pager