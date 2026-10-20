# CONFIG · Operación de la PBX
**Centro Médico Horizonte, S.A. · PF-TEL-001-2026**
Última actualización: 20/10/2026

Instrucciones directas para operar la PBX desde la laptop host. Lo realizado, con capturas, está en `GUIA-DEMO.md`. El historial completo de cómo se construyó la VM está en el primer commit del repositorio.

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
| IP local de la PBX | Cambia según la red (sección 3). Con el router será **192.168.20.10** |
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
| Teléfonos registrados | *Reports → Asterisk Info* | Sección PJSIP, líneas *Contact* |
| Llamadas y grabaciones | *Reports → CDR Reports* · *Reports → Call Recordings* | |
| Registros del sistema | *Reports → System Logfiles* | |
| Consola de Asterisk | *Admin → Asterisk CLI* | |

> Navegar siempre con los menús. Escribir a mano una dirección con `&action=` muestra *"Potential Security Breach"*. Después de guardar cambios, tocar **Apply Config** (botón rojo arriba).

---

## 5. Teléfonos

| Extensión | Integrante | Buzón |
|---|---|---|
| 1000 | Isaac Sarceño (MicroSIP en la laptop host) | Sí |
| 1001 | José Arnaldo | No |
| 2001 | Leonardo Zepeda | Sí |
| 2002 | Omar Godoy (Android) | No |
| 3001 | Ernesto Grijalva | Sí |
| 3002 | Reginaldo | No |
| 4001 | Anthony | Sí |
| 5001 | Romeo | No |
| 5002 | Isaac Sarceño (iPhone, E1) | No |

- **Dominio por Tailscale:** `100.91.176.16`. **Con el router:** `192.168.20.10`. Transporte UDP.
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

**Exportar la VM completa** (apagada, unos 45 minutos, laptop encendida todo el tiempo)
```powershell
& "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" export CMH-FreePBX --output "C:\Users\Asus\Projects\cmh-horizonte\CMH-FreePBX-final.ova" --options manifest
```
Si el archivo ya existe, moverlo antes o usar otro nombre.

**Importar la VM en otra laptop.** VirtualBox → *Archivo → Importar servicio virtualizado* → `.ova`. Después, en *Configuración → Red*, poner el adaptador 1 en puente a la tarjeta de esa laptop.

> Los snapshots `02-antes-de-config-sip` y `03-antes-de-modo-puente` son del 17/10 y no tienen la configuración posterior. Para volver a un estado completo, usar la `.ova`.

---

## 9. Día de la integración con el router

1. Apagar la VM.
2. Pasar el adaptador 1 del Wi-Fi al cable:
   ```powershell
   & "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" modifyvm CMH-FreePBX --bridgeadapter1 "Realtek PCIe GbE Family Controller"
   ```
3. Conectar la laptop host por cable a un **puerto LAN del AP MW325R**, que cuelga de ether2 del hEX (VLAN 20, Voz). Encender la VM.
4. La PBX recibe **192.168.20.10** por la reserva DHCP del hEX (MAC `08:00:27:A5:DA:0A`). No hace falta IP fija. Si el cable se conecta con la VM encendida, el vigilante de red pide la IP nueva en menos de un minuto.
5. Comprobar con `ip -br -4 addr` y `ip route` que hay **una sola** ruta por defecto, por `192.168.20.1`.
6. En MicroSIP y en los celulares conectados a `CMH-Voz`, cambiar el dominio a **`192.168.20.10`** y desactivar Tailscale.
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
| B. Diseño y segmentación | 17 | 🟡 Scripts del hEX y procedimiento del AP listos (`plan/02`) | 🔴 | Cargar en el hEX y el AP, probar la matriz de ACL |
| C. PBX virtual | 15 | 🟢 | 🟢 | Nada. Módulos y sistema al día (20/10) |
| D. Funcionalidades | 18 | 🟢 | 🟡 IVR probado | Sesión de pruebas conjunta (`GUIA-CELULARES.md`, sección 6) |
| E. Terminales | 10 | 🟢 Extensiones asignadas | 🟡 | Sesión de pruebas y llamadas entre VLAN con el router |
| F. QoS | 15 | 🟡 Script listo | 🔴 | Aplicar y medir con y sin QoS |
| G. Documentación | 12 | No aplica | 🟡 | Informe, resumen ejecutivo, guía de usuario de 1 página, matriz llena |
| H. Presentación | 5 | No aplica | 🔴 | Ensayo y video de respaldo |
| E1. Red pública | 8 | 🟢 | 🟡 Llamada 5002 → 1000 | Captura del celular sin Wi-Fi y llamada 1000 → 5002 |
| E3. Troncal SIP | 5 | 🟢 Troncal registrada, entrante y 9100 | 🟡 Llamadas probadas el 20/10 | Capturas de la troncal y del CDR |
| E4. Funciones avanzadas | 4 | 🟢 5 de 5 (buzón por correo el 20/10) | 🟡 | Capturas del correo y pruebas de grupo y cola con el equipo |

🟢 listo · 🟡 avanzado · 🔴 por empezar

---

## 12. Pendientes, en orden

| # | Tarea | Necesita |
|---|---|---|
| 1 | Router hEX y AP MW325R: cargar los scripts, configurar el AP, probar la matriz de ACL y medir QoS (`plan/02` y `plan/06`) | Los equipos y las laptops en ether3, ether4 y ether5 |
| 2 | Sesión de pruebas conjunta y matriz (archivo 09), ya con el router, para incluir las llamadas entre VLAN | Los 8 integrantes con su extensión (`GUIA-CELULARES.md`) |
| 3 | E1: captura del celular sin Wi-Fi y llamada 1000 → 5002. Confirmar *Disable key expiry* en Tailscale | iPhone |
| 4 | Capturas de E3 (troncal, ruta entrante, CDR) y de E4 (correo recibido) para `GUIA-DEMO.md` | FreePBX y la cuenta de Gmail |
| 5 | Informe, resumen ejecutivo, guía de usuario y presentación | Todo lo anterior |

Hecho el 20/10: actualizar módulos, E4 por correo, E3 con sip2sip y adaptar el plan 02 y los scripts al hEX y al AP.
