# CONFIG · Operación de la PBX
**Centro Médico Horizonte, S.A. · PF-TEL-001-2026**
Última actualización: 20/10/2026

Instrucciones directas para operar la PBX desde la laptop host. Lo realizado, con capturas, está en `DOCUMENTACION.md`. El historial completo de cómo se construyó la VM está en el primer commit del repositorio.

> **Contraseñas.** Todas están en `CREDENCIALES-ACTUALES.md`, que solo existe en la laptop host. Nunca van al repositorio, al informe ni a las capturas.

---

## 1. Datos clave

| Qué | Valor |
|---|---|
| Carpeta del proyecto | `C:\Users\Asus\Projects\cmh-horizonte\` |
| VM | `CMH-FreePBX` (Debian 12.15, 4 vCPU, 3 GB) en VirtualBox 7.2.20 |
| PBX | FreePBX 17.0.33.2 y Asterisk 22.11.0 |
| Web de FreePBX | **http://127.0.0.1:18080/admin** · usuario `cmh-ti` |
| SSH | `ssh -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1` |
| `sudo` en la VM | Pide la contraseña de `cmhadmin` |
| IP por Tailscale (fija) | **100.91.176.16** |
| IP local de la PBX | Cambia según la red (sección 3). Con el router será **172.16.20.10** |
| Adaptador 1 de la VM | Puente a la tarjeta de red de la laptop (Wi-Fi o Ethernet) |
| Adaptador 2 de la VM | Puerto interno de gestión (NAT 10.0.2.0/24). Da el acceso por `127.0.0.1:18080` y `127.0.0.1:2222` en cualquier red |
| Respaldo completo | `CMH-FreePBX-final.ova` (19/10, SHA-256 `2ced3421c486248875cf927fd29bdd010fb0d96829dd4e31769afe0097513d21`) |

---

## 2. Encender y apagar la VM

**Encender**
```powershell
& "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" startvm CMH-FreePBX --type headless
```
O en VirtualBox: **CMH-FreePBX → Start → Headless Start**.

1. Esperar **2 minutos** y abrir http://127.0.0.1:18080/admin.
2. El firewall de FreePBX aplica sus reglas **5 minutos** después de encender. Antes de eso todo está abierto.
3. Abrir **MicroSIP** (extensión 1000) y revisar que diga *En línea*.

**Apagar**
```powershell
& "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" controlvm CMH-FreePBX acpipowerbutton
```
O en VirtualBox: **Stop → ACPI Shutdown**. Usar *Power Off* solo si la VM no responde.

**Estado de la VM**
```powershell
& "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" showvminfo CMH-FreePBX --machinereadable | Select-String '^VMState='
```

---

## 3. Cambiar de red (casa, hotspot, universidad)

1. Ver la IP que recibió la PBX:
   ```powershell
   ssh -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "ip -br -4 addr show enp0s3"
   ```
2. Poner esa IP como **servidor y dominio** en MicroSIP (**▼ → Editar cuenta**) y en los celulares que no usan Tailscale.
3. Si la red nueva no es `192.168.x.x`, `172.16.x.x` a `172.31.x.x` ni `100.64.x.x`, agregarla en los dos lugares:
   - **Settings → Asterisk SIP Settings → Local Networks** → *Add Local Network Field* → Submit → Apply Config.
   - **Connectivity → Firewall → Networks** → nueva red en zona **Local** → Save.
4. La red de casa (`192.168.1.0/24`) y el hotspot del iPhone (`172.20.10.0/28`) ya están agregados.

> Los celulares por Tailscale (dominio `100.91.176.16`) no cambian nada. En Wi-Fi públicos los equipos a veces no pueden comunicarse entre sí. Ahí solo funciona Tailscale.

---

## 4. Rutas de FreePBX

| Qué | Ruta | Valor actual |
|---|---|---|
| Estado general | *Dashboard* | Servicios en verde |
| Extensiones | *Connectivity → Extensions* | 1000, 1001, 2001, 2002, 3001, 3002, 4001, 5001, 5002 |
| Direct Media y grabación | *Extensión → Advanced* | Direct Media = No · grabación Force en la 1000 |
| Ajustes SIP y redes locales | *Settings → Asterisk SIP Settings* | RTP 10000 a 20000 · ulaw, alaw, g722, opus |
| Códigos de servicio | *Admin → Feature Codes* | \*43, \*70, \*71, ##, \*2, \*97, \*98, \*271 |
| Grabaciones | *Admin → System Recordings* | ivr-bienvenida, ivr-invalida, ivr-fuera-horario, aviso-grabacion |
| Idioma | *Admin → Sound Languages* | es_419 por defecto |
| IVR | *Applications → IVR* | IVR-Principal y IVR-FueraHorario |
| Número 7000 | *Applications → Misc Applications* | 7000 → TC-Horario |
| Grupo de timbrado | *Applications → Ring Groups* | 8000 (1000 y 1001, ringall, 20 s) |
| Cola | *Applications → Queues* | 8010 (2001 y 2002, rrmemory, música CMH) |
| Horario | *Applications → Time Groups / Time Conditions* | L a V 7:00 a 19:00, sábado 7:00 a 12:00 · TC-Horario (\*271) |
| Música en espera | *Settings → Music on Hold* | Categoría CMH |
| Firewall | *Connectivity → Firewall* | Networks, Interfaces, Services, Responsive Firewall |
| Respaldo | *Admin → Backup & Restore* | CMH-diario (2:00, guarda 7) |
| Teléfonos registrados | *Reports → Asterisk Info → Peers* | Líneas *Contact* con estado Avail |
| Llamadas y grabaciones | *Reports → CDR Reports* (columna *Recording*) | *Call Recordings* es un módulo de pago, no se usa |
| Registros del sistema | *Reports → System Logfiles* | |
| Consola de Asterisk | *Admin → Asterisk CLI* | |

### 4.1 Recorrido para la demostración, en orden

Abrir cada dirección en el navegador con la sesión iniciada. Todas empiezan con `http://127.0.0.1:18080/admin/`. El orden sigue al de la DOCUMENTACION.

| # | Dirección | Menú | Qué se muestra |
|---|---|---|---|
| 1 | `config.php?display=index` | Dashboard | Versión de FreePBX y servicios en verde (Asterisk, base de datos, fail2ban, firewall) |
| 2 | `config.php?display=extensions` | Connectivity → Extensions | Las 9 extensiones de 4 dígitos. El primer dígito es el área |
| 3 | `config.php?display=extensions&extdisplay=1000` | Extensions → 1000 | Pestaña *Advanced* con Direct Media en No. Pestaña *Voicemail* con el buzón activo |
| 4 | `config.php?display=sipsettings` | Settings → Asterisk SIP Settings | Redes locales, rango de audio RTP 10000 a 20000 y códecs |
| 5 | `config.php?display=featurecodeadmin` | Admin → Feature Codes | Códigos de espera (\*70, \*71), transferencia (##, \*2), buzón (\*97, \*98) y horario (\*271) |
| 6 | `config.php?display=recordings` | Admin → System Recordings | Los 4 audios en español del IVR |
| 7 | `config.php?display=soundlang` | Admin → Sound Languages | Español latinoamericano (es_419) por defecto |
| 8 | `config.php?display=voicemail` | Settings → Voicemail Admin | Ajustes generales del buzón de voz |
| 9 | `config.php?display=ivr` | Applications → IVR | IVR-Principal y IVR-FueraHorario. Al abrir uno se ven sus opciones 1, 2, 3, 4 y 0 |
| 10 | `config.php?display=miscapps` | Applications → Misc Applications | El número 7000 que entra al IVR |
| 11 | `config.php?display=timegroups` | Applications → Time Groups | Horario de atención, L a V 7:00 a 19:00 y sábado 7:00 a 12:00 |
| 12 | `config.php?display=timeconditions` | Applications → Time Conditions | TC-Horario. Dentro de horario va al IVR principal y fuera al de fuera de horario |
| 13 | `config.php?display=ringgroups` | Applications → Ring Groups | Grupo 8000, suenan 1000 y 1001 a la vez |
| 14 | `config.php?display=queues` | Applications → Queues | Cola 8010 con los agentes 2001 y 2002 |
| 15 | `config.php?display=music` | Settings → Music on Hold | Categoría CMH con la música propia |
| 16 | `config.php?display=trunks` | Connectivity → Trunks | Troncal sip2sip (extra E3) |
| 17 | `config.php?display=did` | Connectivity → Inbound Routes | La llamada que entra por la troncal va al IVR |
| 18 | `config.php?display=routing` | Connectivity → Outbound Routes | Ruta de salida por la troncal |
| 19 | `config.php?display=firewall` | Connectivity → Firewall | Pestañas Networks, Interfaces, Services y Responsive Firewall |
| 20 | `config.php?display=weakpasswords` | Reports → Weak Password Detection | Sin contraseñas débiles |
| 21 | `config.php?display=backup` | Admin → Backup & Restore | Respaldo diario CMH-diario |
| 22 | `config.php?display=asteriskinfo&module=peers` | Reports → Asterisk Info → Peers | Teléfonos registrados con su IP. En el menú de la derecha también están *Voicemail* (mensajes por buzón) y *Registries* (troncal sip2sip) |
| 23 | `config.php?display=cdr` | Reports → CDR Reports | Historial de llamadas. Tocar *Search* para ver las del día. Las llamadas de la 1000 se escuchan con el botón de la columna *Recording* |
| 24 | `config.php?display=asteriskinfo&module=queues` | Reports → Asterisk Info → Queues | Estadísticas de la cola 8010, llamadas atendidas por agente |
| 25 | `config.php?display=logfiles` | Reports → System Logfiles | Registros para auditoría. `full` tiene todo lo de Asterisk y `fail2ban` los intentos de registro |
> Las direcciones de la tabla 4.1 se pueden escribir a mano. Lo que no se debe escribir es una dirección con `&action=`, porque muestra *"Potential Security Breach"*. Para editar algo, entrar desde la lista con el ícono de lápiz. Después de guardar cambios, tocar **Apply Config** (botón rojo arriba).

---

## 5. Teléfonos

| Extensión | Integrante | Buzón |
|---|---|---|
| 1000 | Isaac Sarceño (MicroSIP en la laptop host) | Sí |
| 1001 | Anthony | No |
| 2001 | Leonardo Zepeda | Sí |
| 2002 | Omar Godoy (Android) | No |
| 3001 | Ernesto Grijalva | Sí |
| 3002 | Reginaldo | No |
| 4001 | José Arnaldo | Sí |
| 5001 | Romeo | No |
| 5002 | Isaac Sarceño (iPhone, E1) | No |

- **Dominio por Tailscale:** `100.91.176.16`. **Con el router:** `172.16.20.10`. Transporte UDP.
- **MicroSIP:** la cuenta está en `%APPDATA%\MicroSIP\microsip.ini`.
- **Linphone en iOS** solo recibe llamadas con la app abierta en pantalla.
- Configuración de los celulares y guion de pruebas en `GUIA-CELULARES.md`.

---

## 6. Tailscale

| Acción | Comando o ruta |
|---|---|
| Ver estado y equipos conectados | `ssh ... "tailscale status"` |
| Reconectar si dice *Logged out* | `ssh -t ... "sudo tailscale up --hostname=cmh-pbx --accept-dns=false"` y abrir el enlace en incógnito con la cuenta del proyecto |
| Consola web | https://login.tailscale.com/admin/machines |
| Evitar que venza la sesión | Consola → **cmh-pbx → ⋯ → Disable key expiry** |
| Quitar un equipo perdido | Consola → equipo → **⋯ → Remove** |

En los comandos, `ssh ...` es el comando SSH de la sección 1.

---

## 7. Comandos de consola

Entrar con el SSH de la sección 1. Los que llevan `sudo` piden la contraseña de `cmhadmin`.

| Para qué | Comando |
|---|---|
| Teléfonos registrados | `sudo asterisk -rx "pjsip show contacts"` |
| Llamadas en curso | `sudo asterisk -rx "core show channels"` |
| Jitter, pérdida y RTT de llamadas activas | `sudo asterisk -rx "pjsip show channelstats"` |
| Ver la actividad en vivo | `sudo tail -f /var/log/asterisk/full` (salir con Ctrl+C) |
| Equipos bloqueados por fail2ban | `sudo fail2ban-client status asterisk-iptables` |
| Desbloquear un equipo | `sudo fail2ban-client set asterisk-iptables unbanip <IP>` (para SSH, `ssh-iptables`) |
| Reiniciar FreePBX | `sudo fwconsole restart` |
| Aplicar la configuración | `sudo fwconsole reload` |
| IPs de la VM | `ip -br -4 addr` |

---

## 8. Respaldos

**Ejecutar el respaldo de FreePBX ahora.** *Admin → Backup & Restore → CMH-diario → ▶*

**Descargarlo a la laptop**
```powershell
ssh -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "ls -t /var/spool/asterisk/backup/ | head -1"
scp -P 2222 -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" "cmhadmin@127.0.0.1:/var/spool/asterisk/backup/<archivo>.tar.gz" C:\Users\Asus\Projects\cmh-horizonte\respaldos\
```

**Snapshot de la VM** (siempre con la VM **apagada**)
```powershell
& "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" snapshot CMH-FreePBX take "<nombre>"
```

**Exportar la VM completa** (apagada, unos 20 minutos, laptop encendida todo el tiempo)
```powershell
& "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" export CMH-FreePBX --output "C:\Users\Asus\Projects\cmh-horizonte\CMH-FreePBX-AAAAMMDD.ova" --options manifest
```
Si el archivo ya existe, moverlo antes o usar otro nombre.

**Importar la VM en otra laptop.** VirtualBox → *Archivo → Importar servicio virtualizado* → `.ova`. Después, en *Configuración → Red*, poner el adaptador 1 en puente a la tarjeta de esa laptop.

**Puntos de restauración**

| Punto | Fecha | Contenido |
|---|---|---|
| `CMH-FreePBX-20261020.ova` (5.67 GB) | 20/10, 15:42 | **El más completo.** Todo hasta E1, E3 y E4 completos, módulos al día y vigilante de red. SHA-256 `E018398DF4F2A3EDE0B9BB45A3AE0BD6BC735EAD9E45ECF8CCBA44E66239DB63` |
| Snapshot `05-antes-del-router` | 20/10, 15:30 | Lo mismo que la OVA del 20/10, dentro de VirtualBox |
| Snapshot `04-antes-de-actualizar` | 20/10, 14:10 | Antes de E3, E4 por correo y la revisión de módulos |
| `CMH-FreePBX-final.ova` | 19/10 | Hasta E1. Sin E3, sin correo y sin vigilante de red |
| Snapshots `02` y `03` | 17/10 | Primeras etapas. No usarlos salvo emergencia |

> El respaldo de FreePBX se ejecuta desde la pestaña de **trabajos de respaldo**. La lista de archivos guardados tiene un botón ▶ que **restaura**, no respalda. Revisar la fila antes de hacer clic.

---

## 9. Día de la integración con el router

1. Apagar la VM.
2. Pasar el adaptador 1 del Wi-Fi al cable:
   ```powershell
   & "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" modifyvm CMH-FreePBX --bridgeadapter1 "Realtek PCIe GbE Family Controller"
   ```
3. Conectar la laptop host por cable a un **puerto LAN del AP MW325R**, que cuelga de ether2 del hEX (VLAN 20, Voz). Encender la VM.
4. La PBX recibe **172.16.20.10** por la reserva DHCP del hEX (MAC `08:00:27:A5:DA:0A`). No hace falta IP fija. Si el cable se conecta con la VM encendida, el vigilante de red pide la IP nueva en menos de un minuto.
5. Comprobar con `ip -br -4 addr` y `ip route` que hay **una sola** ruta por defecto, por `172.16.20.1`.
6. En MicroSIP y en los celulares conectados a `CMH-Voz`, cambiar el dominio a **`172.16.20.10`** y desactivar Tailscale.
7. Respaldo, solo si la reserva DHCP falla: `sudo bash /root/cmh-ip-estatica.sh` fija la IP y `sudo bash /root/cmh-ip-dhcp.sh` la devuelve a DHCP.

> **Router y AP.** Puertos del hEX: ether1 internet, ether2 Voz (AP y, detrás del AP, la laptop host), ether3 Gestión, ether4 Administrativa, ether5 Invitados. Procedimiento completo en `plan\02_RED_MIKROTIK_HEX_Y_AP.md`.

---

## 10. Reparación rápida

| Síntoma | Qué hacer |
|---|---|
| `127.0.0.1:18080` no abre | Esperar 2 o 3 minutos después de encender. Revisar que la VM diga *running* |
| Sin acceso a la web o al SSH después de un cambio en el firewall | En la consola de VirtualBox: `sudo fwconsole firewall trust 10.0.2.2`. Emergencia: `sudo fwconsole firewall disable` |
| El SSH se queda colgado y la web sí abre | Bloqueo de fail2ban. En la consola de VirtualBox: `sudo fail2ban-client set ssh-iptables unbanip 10.0.2.2` |
| SSH pide contraseña aunque hay llave | En la VM: `chmod 700 ~/.ssh` y `chmod 600 ~/.ssh/authorized_keys` |
| La web no abre pero la VM corre | `sudo fwconsole restart` |
| ¿Asterisk está corriendo? | `pgrep -c asterisk` (1 o más) |
| La VM no responde | `VBoxManage controlvm CMH-FreePBX poweroff` y volver a encender. Si se repite, con la VM apagada: `VBoxManage modifyvm CMH-FreePBX --cpus 2` |
| Un teléfono no registra | IP o dominio correcto (sección 3), Tailscale conectado y app abierta. Si falló 5 veces, desbloquearlo (sección 7) |
| "Servicio no disponible" al llamar | La extensión de destino no está registrada |
| Audio en un solo sentido | La red del teléfono debe estar en *Local Networks* (sección 3) |
| Se olvidó la contraseña de `cmh-ti` | `sudo mysql asterisk -e "UPDATE ampusers SET password_sha1=SHA1('NUEVA') WHERE username='cmh-ti';"` y anotarla en `CREDENCIALES-ACTUALES.md` |
| Se olvidó la contraseña de root | Entrar con `cmhadmin` y `sudo passwd root` |
| Todo falla | Importar `CMH-FreePBX-final.ova` (sección 8) |

---

## 11. Estado frente al PDF

| Criterio | Puntos | Configuración | Evidencia | Qué falta |
|---|---|---|---|---|
| A. Investigación y selección | 8 | 🟢 | 🟡 Tablas comparativas | Costos y fuentes en APA |
| B. Diseño y segmentación | 17 | 🟢 VLAN, DHCP, NAT y firewall cargados en el hEX. AP con `CMH-Voz` (20/10) | 🟡 iPhone en la VLAN 20 | Probar la matriz de ACL con equipos en ether3, ether4 y ether5 |
| C. PBX virtual | 15 | 🟢 | 🟢 | Nada. Módulos y sistema al día (20/10) |
| D. Funcionalidades | 18 | 🟢 | 🟢 Sesión de pruebas del 23/10 (DOCUMENTACION, sección 12) | Nada |
| E. Terminales | 10 | 🟢 Extensiones asignadas | 🟡 9 extensiones y llamadas entre laptop y celulares (23/10) | Llamadas entre VLAN con el router |
| F. QoS | 15 | 🟢 Marcado DSCP y colas cargados en el hEX (20/10) | 🔴 | Medir con y sin QoS. Ajustar `q-wan` a la subida real |
| G. Documentación | 12 | No aplica | 🟡 | Informe, resumen ejecutivo, guía de usuario de 1 página, matriz llena |
| H. Presentación | 5 | No aplica | 🔴 | Ensayo y video de respaldo |
| E1. Red pública | 8 | 🟢 | 🟡 Llamada 5002 → 1000 | Captura del celular sin Wi-Fi y llamada 1000 → 5002 |
| E3. Troncal SIP | 5 | 🟢 Troncal registrada, entrante y 9100 | 🟢 Figuras 27a a 27d | Nada |
| E4. Funciones avanzadas | 4 | 🟢 5 de 5 (buzón por correo el 20/10) | 🟡 Grupo y cola probados el 23/10 | Captura del correo recibido |

🟢 listo · 🟡 avanzado · 🔴 por empezar

---

## 12. Pendientes, en orden

| # | Tarea | Necesita |
|---|---|---|
| 1 | Probar la matriz de ACL y medir la QoS con y sin prioridad (`plan/02` y `plan/06`). Ajustar `q-wan` con un speedtest | Internet en ether1 (tercer cable), una laptop de TI en ether3 y un equipo en ether4 |
| 2 | Llamadas entre VLAN con el router. Las demás pruebas ya se hicieron el 23/10 | Isaac y un compañero con laptop en ether4 |
| 3 | E1: captura del celular sin Wi-Fi y llamada 1000 → 5002. Confirmar *Disable key expiry* en Tailscale | iPhone |
| 4 | Captura del correo del buzón (E4). Los avisos del 23/10 están en cola porque la red de casa bloquea el puerto 587. Salen solos al conectar la laptop al hotspot | Hotspot y la cuenta de Gmail |
| 5 | Informe, resumen ejecutivo, guía de usuario y presentación | Todo lo anterior |

Hecho el 23/10: sesión de pruebas con el equipo (pruebas 1 a 17) y capturas de E3. Hecho el 20/10: actualizar módulos, E4 por correo, E3 con sip2sip, adaptar el plan 02 y los scripts al hEX y al AP, cargar los tres scripts en el hEX, configurar el AP y respaldar el router.
