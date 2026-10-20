#!/bin/bash
# CMH Horizonte · E4 buzon por correo
# Configura postfix para enviar correo por Gmail (smtp.gmail.com:587, TLS) con una
# contrasena de aplicacion. Pide los datos en pantalla: la contrasena no queda en
# el historial ni en este archivo. Uso: sudo bash configurar-correo-gmail.sh
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Ejecutar con sudo"; exit 1; }

read -rp "Cuenta de Gmail del proyecto: " CUENTA
for intento in 1 2 3; do
  read -rsp "Contrasena de aplicacion (16 letras, no se ve al escribir): " CLAVE; echo
  CLAVE="${CLAVE//[[:space:]]/}"
  [ "${#CLAVE}" -eq 16 ] && break
  echo "Tiene ${#CLAVE} letras y deben ser 16. Vuelve a copiarla y pegala con clic derecho."
  [ "$intento" -eq 3 ] && exit 1
done

if ! dpkg-query -W -f='${Status}' libsasl2-modules 2>/dev/null | grep -q "ok installed"; then
  echo "Instalando libsasl2-modules..."
  apt-get install -y -q libsasl2-modules >/dev/null
fi

umask 077
printf '[smtp.gmail.com]:587 %s:%s\n' "$CUENTA" "$CLAVE" > /etc/postfix/sasl_passwd
unset CLAVE
chmod 600 /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd.db

postconf -e \
  "relayhost = [smtp.gmail.com]:587" \
  "smtp_sasl_auth_enable = yes" \
  "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" \
  "smtp_sasl_security_options = noanonymous" \
  "smtp_tls_security_level = encrypt" \
  "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt" \
  "inet_interfaces = loopback-only"
systemctl restart postfix

echo "Enviando correo de prueba a $CUENTA ..."
/usr/sbin/sendmail -t <<EOF
From: PBX Centro Medico Horizonte <$CUENTA>
To: $CUENTA
Subject: Prueba de correo de la PBX CMH

Si llega este correo, el buzon de voz ya puede enviar los mensajes por correo.
EOF
sleep 8
echo
echo "Cola de correo (vacia = enviado):"
postqueue -p
echo
journalctl -u postfix --no-pager -n 5 -o cat 2>/dev/null | grep -E "status=|error|warning" || tail -n 5 /var/log/mail.log 2>/dev/null || true