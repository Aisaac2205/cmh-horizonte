# CONFIG · Trazabilidad de la configuración de la VM (PBX)
**Centro Médico Horizonte, S.A. · PBX IP con VLAN, QoS y acceso seguro**
Última actualización: 19/10/2026

Este archivo es la **trazabilidad paso a paso de la VM** de la PBX (proyecto PF-TEL-001-2026): qué se configuró, en qué orden, con qué comandos y valores, y qué requisito del PDF cubre. Sirve para repetirlo en otra VM, repararlo o explicarlo en la defensa. Cómo encender la VM y recorrerla en la demostración está en `GUIA-DEMO.md`.

> **Contraseñas.** Ninguna aparece aquí. Todas están en `CREDENCIALES-ACTUALES.md`, que solo existe en la laptop host y nunca va al informe, a los anexos ni a Canvas (§11 del PDF).

**Cómo leerlo:** la **Parte A** es el resumen. La **Parte B** es el paso a paso de la VM. La **Parte C** tiene el código de los scripts, la trazabilidad con el PDF, los pendientes y la reparación rápida.

## Índice

- **Parte A. Resumen:** A1 Dónde está cada cosa · A2 Estado actual de la VM · A3 Estado frente al PDF · A4 Bitácora de la VM
- **Parte B. Paso a paso:** 1 Importación · 2 Llave SSH · 3 Contraseñas · 4 Revisión · 5 Asistente FreePBX · 6 Ajustes SIP · 7 Extensiones · 8 Firewall · 9 Idioma, audios e IVR · 10 Respaldo · 11 Modo puente y softphones · 12 Extras E4 · 13 Saludos de buzón · 14 E1 Tailscale · 15 Exportar la .ova · 16 Scripts del router
- **Parte C. Referencias:** C1 Código de scripts · C2 Trazabilidad · C3 Pendientes · C4 Reparación rápida

---

# Parte A. Resumen

## A1. Dónde está cada cosa

Carpeta del proyecto en la laptop host: `C:\Users\Asus\Projects\cmh-horizonte\`. En el repositorio de GitHub solo está la documentación. Lo que dice **Sí** en la columna *¿Sensible?*, las `.ova` y los audios se piden al responsable técnico por un canal privado.

| Ruta | Qué es | ¿Sensible? |
|---|---|---|
| `CONFIG.md` | Este archivo | No |
| `GUIA-DEMO.md` | Cómo encender la VM, entrar a FreePBX y recorrer lo hecho en la demostración, con las pruebas de llamadas | No |
| `CREDENCIALES-ACTUALES.md` | Todas las contraseñas vigentes (Linux, FreePBX, extensiones, buzones, router y Wi-Fi) | **Sí** |
| `README.md` | Portada del repositorio: qué es el proyecto y por dónde empezar | No |
| `.gitignore` | Lo que no se sube a GitHub (contraseñas, VM, audios) | No |
| `CMH-FreePBX-final.ova` | VM completa con toda la configuración (Paso 15) | **Sí**, tiene contraseñas |
| `cmh-freepbx-debian12-autoinstall.iso`, `crear-vm-cmh.ps1` | Instalación desde cero | No |
| `plan\00` a `plan\10` | Plan del grupo, validado contra el PDF | No |
| `router\` | Scripts del RB4011 listos para cargar (instrucciones en el Paso 16) | **Sí** (Wi-Fi) |
| `audios\` | Los 4 audios del IVR, la música en espera propia y los saludos de los buzones en `audios\buzones\` (WAV 8 kHz) | No |
| `capturas\` | 24 capturas de FreePBX que usa `GUIA-DEMO.md`, sin contraseñas visibles | No |
| `respaldos\` | Respaldo completo de FreePBX (`.tar.gz`) | **Sí** |

Fuera de esta carpeta:

| Ruta | Qué es |
|---|---|
| `C:\Users\Asus\VirtualBox VMs\CMH-FreePBX\` | Disco y configuración de la VM · snapshots `02-antes-de-config-sip` y `03-antes-de-modo-puente` |
| `C:\Users\Asus\.ssh\cmh_pbx_ed25519` | Llave SSH de la laptop hacia la VM (**no compartir**) |

**Accesos rápidos (desde la laptop host):**
- Web de FreePBX: `http://127.0.0.1:18080` (usuario `cmh-ti`)
- SSH a la VM: `ssh -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1`
- Los dos funcionan en cualquier red, porque usan el **puerto interno de gestión** de la VM.
- **IP de la PBX para los softphones:** cambia según la red. En el hotspot del iPhone es `172.20.10.7`. Para verla: `ssh -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "ip -br -4 addr show enp0s3"`

## A2. Estado actual de la VM (19/10/2026)

| Componente | Estado |
|---|---|
| Laptop host | Windows 11 · VirtualBox **7.2.20** |
| VM | `CMH-FreePBX` · Debian **12.15** (kernel 6.1.0-53) · hostname `cmh-pbx` · zona horaria America/Guatemala · **4 vCPU**, 3 GB de RAM · disco `CMH-FreePBX-disk001.vdi` |
| PBX | FreePBX **17.0.33** + Asterisk **22.11.0** · corre con el servicio `freepbx` (`fwconsole start`) |
| Red de la VM | **Adaptador 1 en puente al Wi-Fi** (Intel AX211) · IP por DHCP de la red donde esté la laptop (en el hotspot del iPhone: **172.20.10.7**) · **Adaptador 2 = puerto interno de gestión** (NAT, 10.0.2.15/24 sin gateway) con reenvíos `127.0.0.1:2222 → 22` y `127.0.0.1:18080 → 80` (Paso 11) |
| Acceso | SSH con **llave** (`cmhadmin`) · web de FreePBX con el usuario **`cmh-ti`** |
| Credenciales | Contraseñas de Linux y de FreePBX **cambiadas**. Las que traía la VM base ya no sirven |
| Ajustes SIP | Redes locales 192.168.0.0/16, 100.64.0.0/10 y 172.16.0.0/12 (hotspot) · RTP 10000–20000 · códecs ulaw, alaw, g722, opus · sin invitados ni anónimos · solo UDP 5060 (Paso 6) |
| Extensiones | **9 creadas** (1000 a 5002) con Direct Media = No · buzón en 1000, 2001, 3001 y 4001 (Paso 7) |
| Protección | **Firewall de FreePBX activo** con Responsive Firewall (el SIP de redes no confiables se rechaza) · administración y SSH solo para redes confiables · **fail2ban activo** (jails `ssh-iptables`, `asterisk-iptables`, `pbx-gui`, `recidive` y otras) (Paso 8) |
| Tailscale (E1) | Servicio habilitado en la VM. Falta autorizar el equipo con una cuenta personal (Paso 14) |
| Idioma | **Español latino (`es_419`)** por defecto, con respaldo en `es` para lo que le falte (Paso 9) |
| IVR | `IVR-Principal` con bienvenida en español, opciones 1 a 4, 0 a la operadora, manejo de inválida y sin respuesta · número interno **7000** (Paso 9) |
| Extras E4 | Grupo 8000, cola 8010, horarios con `TC-Horario` (código **\*271**), grabación forzada en la 1000 y música propia `CMH` en la cola (Paso 12) |
| Buzones | Saludos personalizados (no disponible, ocupado y nombre) en 1000, 2001, 3001 y 4001, voz es-MX (Paso 13) |
| Respaldo | Tarea `CMH-diario` (todos los días a las 2:00, guarda 7) · primera copia descargada a la laptop (Paso 10) |
| Módulos | **Sin actualizar** (requiere Wi-Fi, ver C3) |
| Snapshots | `02-antes-de-config-sip` (14:50) y `03-antes-de-modo-puente` (15:45), ambos con la VM apagada |

## A3. Estado frente al PDF

Cada criterio se mira en dos partes. **Configuración** es si ya está hecho en la PBX o en el router. **Evidencia** es si ya está probado y documentado como pide la rúbrica (§9), con capturas y en la matriz de pruebas. Los puntos se ganan con las dos.

| Criterio | Puntos | Configuración | Evidencia | Qué falta |
|---|---|---|---|---|
| A. Investigación y selección | 8 | 🟢 Modalidad y tecnologías elegidas (`plan\01` §1) | 🟡 Tablas comparativas listas | Costos y fuentes en APA |
| B. Diseño y segmentación | 17 | 🟡 Diseño completo y scripts del router listos, sin cargar | 🔴 | Cargar los scripts en el RB4011 y probar la matriz de ACL |
| C. PBX virtual | 15 | 🟢 Instalada, 9 extensiones, códecs, CDR, firewall, fail2ban y respaldo diario | 🟢 Versiones documentadas y capturas en `capturas\` | Solo actualizar módulos (Wi-Fi), es menor |
| D. Funcionalidades | 18 | 🟢 Marcación de 4 dígitos, espera, transferencia ciega y atendida, 4 buzones con saludo e IVR | 🟡 IVR probado desde el iPhone y capturas de toda la configuración | Probar espera, transferencias (3 teléfonos) y dejar y escuchar un mensaje, y anotarlo en la matriz (archivo 09) |
| E. Terminales | 10 | 🟢 MicroSIP (laptop, 1000) y Linphone (iPhone, 2001) registrados | 🟡 Llamada iPhone → IVR con audio | Llamada laptop ↔ iPhone y llamadas entre VLAN (requiere router) |
| F. QoS | 15 | 🟡 Script `03-qos.rsc` listo y método de medición definido | 🔴 | Aplicar y medir con y sin QoS en la Integración 2 |
| G. Documentación | 12 | No aplica | 🟡 Plan, `CONFIG.md` y `GUIA-DEMO.md` con capturas | Informe, resumen ejecutivo, guía de usuario de 1 página y matriz de pruebas llena |
| H. Presentación | 5 | No aplica | 🔴 | Ensayo y video de respaldo |
| E1. Red pública | 8 | 🟡 Tailscale habilitado en la VM | 🔴 | Autorizar con cuenta personal, `tailscale0` en zona Local y extensión 5002 por datos móviles |
| E3. Troncal SIP | 5 | 🔴 | 🔴 | Cuentas sip2sip, troncal y rutas |
| E4. Funciones avanzadas | 4 | 🟢 Grupo 8000, cola 8010, horarios (\*271), grabación y música propia (4 de 5) | 🟡 Capturas de todo | Probar con llamadas. Buzón por correo opcional (falta Gmail) |

🟢 listo · 🟡 avanzado · 🔴 por empezar

**En resumen:** la PBX está terminada (C en verde y D y E4 configurados). Lo que falta es probarla con llamadas y anotarlo, y todo lo que depende del router (B, F y la parte de VLAN de E).

## A4. Bitácora de la VM

### Viernes 16/10
| Hora | Qué se hizo | Detalle |
|---|---|---|
| Sin hora | Un compañero armó la VM base (Debian 12.15 + FreePBX 17) y la OVA | `README.md` |

### Sábado 17/10
| Hora | Qué se hizo | Detalle |
|---|---|---|
| Mañana | Importación de la OVA en VirtualBox 7.2.20 | Paso 1 |
| 11:50 | Llave SSH de la laptop instalada en la VM | Paso 2 |
| 11:54 | Contraseñas de Linux cambiadas (§5.8 del PDF) | Paso 3 |
| 12:20 | Asistente inicial de FreePBX: administrador `cmh-ti`, actualizaciones en "solo correo" | Paso 5 |
| 14:50 | Snapshot `02-antes-de-config-sip` con la VM apagada | Paso 6 |
| 14:55 | Ajustes SIP: redes locales, códecs, solo UDP 5060 | Paso 6 |
| 15:00 | 9 extensiones con Direct Media = No y 4 buzones | Paso 7 |
| 15:05 | Firewall de FreePBX y Responsive Firewall | Paso 8 |
| 15:08 | Lista blanca de fail2ban y endurecimiento de SSH | Paso 8 |
| 15:15 | Audios del IVR generados con la voz es-MX de Windows | Paso 9.2 |
| 15:20 | Sonidos del sistema en español (`es`, 13 MB) | Paso 9.1 |
| 15:25 | Español latino (`es_419`) como idioma por defecto | Paso 9.1 |
| 15:28 | Grabaciones, `IVR-Principal` y número 7000 | Pasos 9.3 y 9.4 |
| 15:30 | Respaldo `CMH-diario` ejecutado y copiado a la laptop | Paso 10 |
| 15:45 | Red del hotspot en FreePBX, snapshot `03`, VM en **modo puente** al Wi-Fi + puerto interno de gestión | Paso 11 |
| 15:52 | Verificado: VM en 172.20.10.7, web bloqueada desde el hotspot, SIP llega a Asterisk | Paso 11 |
| 16:00 | MicroSIP 3.22.19 instalado en la laptop (winget, sitio oficial) con la cuenta 1000 | Paso 11 |
| 16:01 | **Primer registro real:** Linphone en el iPhone como 2001 (35 ms) | Paso 11 |
| 16:05 | **Primera llamada real:** iPhone → 7000, IVR en español funcionando | Paso 11 |
| 16:06 | MicroSIP registrado como 1000 (2 ms) | Paso 11 |
| 16:12 | Feature codes y opciones de marcado verificados · grupo 8000 · cola 8010 | Paso 12 |
| 16:16 | `Horario-Atencion`, `IVR-FueraHorario`, `TC-Horario` (\*271), 7000 → horario, IVR principal 1 → 8000 y 2 → 8010, PHP en hora de Guatemala | Paso 12 |
| 16:18 | Grabación forzada en la 1000 | Paso 12 |
| 16:20 | Música en espera original compuesta con código, categoría `CMH` en la cola | Paso 12 |
| 16:52 | Saludos de los buzones 1000, 2001, 3001 y 4001 generados con voz es-MX e instalados | Paso 13 |
| 16:55 | Tailscale habilitado en la VM, pendiente de autorizar | Paso 14 |

### Lunes 19/10
| Hora | Qué se hizo | Detalle |
|---|---|---|
| 09:20 | VM exportada completa en `CMH-FreePBX-final.ova` | Paso 16 |

---

# Parte B. Paso a paso

Cada paso dice **qué** se hizo, **por qué** y **cómo** (comandos o ruta en FreePBX con sus valores). Están en el orden en que se hicieron. Las rutas de la laptop son las de la laptop host (`C:\Users\Asus\...`).

## Paso 1. Importación de la VM

Se partió de la **VM base** que armó un compañero del grupo el 16/10: Debian 12.15 con FreePBX 17 ya instalado (`CMH-FreePBX-instalada.ova`).

1. VirtualBox → **Archivo → Importar servicio virtualizado** → `CMH-FreePBX-instalada.ova` → Importar.
2. Huella del archivo (recomendado antes de importar):
   ```powershell
   Get-FileHash .\CMH-FreePBX-instalada.ova
   ```
   Debe dar `5cda391fe11a5343ada91fca610217d2a0506ff3c04407ca1c56a55bd72ad98e`.
3. Se encendió la VM y se comprobó que la web responde en `http://127.0.0.1:18080`.

**Por qué el puerto 18080 y no 80.** La VM está en NAT, así que la laptop no ve su IP directamente. VirtualBox reenvía el puerto 18080 de la laptop al 80 de la VM, y el 2222 al 22 (SSH). Los reenvíos solo escuchan en `127.0.0.1`, o sea que ningún otro equipo de la red llega a ellos.

## Paso 2. Acceso por llave SSH (laptop → VM)

**Para qué.** Entrar a la VM sin escribir contraseña y poder pegar comandos desde PowerShell. La consola de VirtualBox no permite copiar y pegar.

1. Crear la llave en la laptop (presionar Enter dos veces cuando pida *passphrase*):
   ```powershell
   ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -C "cmh-pbx-laptop"
   ```
2. Instalar la llave pública en la VM (pide la contraseña de `cmhadmin` una sola vez):
   ```powershell
   Get-Content "$env:USERPROFILE\.ssh\cmh_pbx_ed25519.pub" | ssh -p 2222 cmhadmin@127.0.0.1 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && tr -d '\r' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
   ```
   El `tr -d '\r'` quita el fin de línea de Windows, que haría inválida la llave.
3. Probar:
   ```powershell
   ssh -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "hostname"
   ```
   Debe responder `cmh-pbx` sin pedir contraseña.

| Archivo | Dónde | Permisos |
|---|---|---|
| Llave privada | `C:\Users\Asus\.ssh\cmh_pbx_ed25519` | No compartir nunca |
| Llave pública | `C:\Users\Asus\.ssh\cmh_pbx_ed25519.pub` | Se puede copiar |
| Llaves autorizadas | `/home/cmhadmin/.ssh/authorized_keys` en la VM | Carpeta 700, archivo 600 |

## Paso 3. Cambio de contraseñas de Linux (§5.8 del PDF)

**Por qué.** Todas las copias de la VM base traen las mismas contraseñas. Cualquiera que tenga esa `.ova` podría entrar.

1. Se generaron contraseñas aleatorias de 20 caracteres (letras, números y `-_.`) con el módulo `secrets` de Python. No llevan símbolos que cambien de lugar entre teclados.
2. Se guardaron en `CREDENCIALES-ACTUALES.md`, junto a la del administrador web.
3. Se aplicaron en la VM con un script de un solo uso que se **borró a sí mismo** al terminar:
   ```bash
   chpasswd <<'EOF'
   cmhadmin:<contraseña nueva>
   root:<contraseña nueva>
   EOF
   ```
4. Se borró también la copia del script en la laptop, porque tenía las contraseñas.

**Forma manual equivalente** (por si hay que repetirlo en otra copia de la VM):
```bash
sudo passwd cmhadmin
sudo passwd root
```

**Decisión de seguridad.** Se evaluó dejar `sudo` sin contraseña para automatizar la configuración, y **se descartó** porque debilita la VM. `sudo` sigue pidiendo la contraseña de `cmhadmin`.

## Paso 4. Revisión de la VM

Se comprobó lo siguiente (con SSH y `sudo`):

| Qué | Comando | Resultado |
|---|---|---|
| Versión de FreePBX | `sudo fwconsole --version` | 17.0.33 |
| Versión de Asterisk | `/usr/sbin/asterisk -V` | Asterisk 22.11.0 |
| Módulos del proyecto | `sudo fwconsole ma list` | Instalados: framework, core, sipsettings, firewall, userman, voicemail, ivr, ringgroups, queues, timeconditions, backup |
| Servicios | `systemctl is-active freepbx apache2 mariadb ssh fail2ban` | Todos `active` |
| Scripts de red | `sudo ls /root/cmh-ip-*.sh` | `cmh-ip-estatica.sh` y `cmh-ip-dhcp.sh` presentes |
| Herramientas | `command -v sngrep tcpdump htop tailscale` | Todas instaladas |

> `systemctl status asterisk` aparece **inactive** y es normal. En FreePBX 17, Asterisk lo arranca el servicio `freepbx`. Para comprobar que corre: `pgrep -c asterisk` (debe dar 1 o más).

## Paso 5. Asistente inicial de FreePBX

Se completó en `http://127.0.0.1:18080`:

| Campo | Valor | Motivo |
|---|---|---|
| Usuario administrador | `cmh-ti` | §5.8 del PDF: no usar `admin` |
| Contraseña | La de `CREDENCIALES-ACTUALES.md` | Aleatoria, 20 caracteres |
| Identificador del sistema | `CMH-PBX Centro Medico Horizonte` | Se ve en la barra de FreePBX y en las evidencias |
| Correo de notificaciones | `ti@cmh-horizonte.local` | De laboratorio. Se cambia si se configura el correo de E4 |
| Actualizaciones automáticas (módulos y seguridad) | **Email Only** | Solo avisan, no descargan solas. Se actualiza a mano con Wi-Fi |
| Activación con Sangoma | **Omitida** | Solo sirve para módulos comerciales |
| Anuncios (PBXact Cloud, SIPStation, softphones, teléfonos y revendedores de Sangoma) | Omitidos | No aplican |
| Idioma | Inglés (por defecto) | El español descarga audios. Más tarde se puso español latino (Paso 9) |
| Asistente del firewall | **Cancelado** | Con valores por defecto bloquea la administración desde la laptop host. Se configura completo con el archivo 07 |

Se comprobó que `cmh-ti` inicia sesión correctamente.

## Paso 6. Ajustes SIP (17/10, 14:55)

Antes de empezar se tomó el snapshot `02-antes-de-config-sip` **con la VM apagada**:
```powershell
$vbm = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
& $vbm controlvm CMH-FreePBX acpipowerbutton      # apagado limpio
& $vbm snapshot CMH-FreePBX take "02-antes-de-config-sip"
& $vbm startvm CMH-FreePBX
```

En **Settings → Asterisk SIP Settings**:

| Campo | Valor | Estado previo | Motivo |
|---|---|---|---|
| Allow Anonymous Inbound SIP Calls | No | Ya venía en No | Nadie llama sin autenticarse |
| Allow SIP Guests | No | Ya venía en No | Igual que el anterior |
| Local Networks | `192.168.0.0/16` y `100.64.0.0/10` | Vacío | Asterisk no reescribe el SDP para las VLAN del proyecto ni para Tailscale (E1) |
| External Address | Vacío por ahora | Vacío | Se detecta cuando se configure la troncal E3 (usa internet) |
| RTP Port Ranges | 10000 – 20000 | Ya venía así | Coincide con las reglas del router y la QoS |
| Codecs (en orden) | ulaw, alaw, g722, opus | ulaw, alaw, gsm, g726, g722 | Se quitaron gsm y g726, se agregó opus (archivo 01, §5.1) |
| Transportes pjsip | Solo `udp` en 5060 | tcp, tls, ws y wss ya venían apagados | Menor superficie de ataque |

Se guardó con **Submit** y se aplicó con **Apply Config**.

## Paso 7. Extensiones (17/10, 15:00)

**Connectivity → Extensions → Add Extension → Add New SIP [chan_pjsip] Extension**, una por una:

| Ext. | Nombre | Buzón | Ring Time |
|---|---|---|---|
| 1000 | Operadora Recepcion | ✅ | 20 s |
| 1001 | Recepcion Movil | No | Por defecto |
| 2001 | Clinica 1 | ✅ | 20 s |
| 2002 | Clinica 2 | No | Por defecto |
| 3001 | Enfermeria | ✅ | 20 s |
| 3002 | Emergencias | No | Por defecto |
| 4001 | Administracion | ✅ | 20 s |
| 5001 | TI Gerencia | No | Por defecto |
| 5002 | TI Remoto | No | Por defecto |

En **todas**:
- **Secret:** el que genera FreePBX (32 caracteres aleatorios). Se anotó en `CREDENCIALES-ACTUALES.md`.
- **Advanced → Direct Media: No.** El audio pasa por la PBX, así atraviesa la QoS del router y funciona con NAT.
- **Call Waiting: Enabled** y **Max Contacts: 1** (ya venían así).

En las de buzón:
- **Voicemail: Enabled** con un PIN de 6 dígitos **distinto por extensión**, aleatorio, sin secuencias ni repeticiones y sin contener el número de la extensión. También quedó en `CREDENCIALES-ACTUALES.md`.
- El desvío al buzón por ocupado o sin respuesta queda activo por defecto al habilitar el buzón.

> **Ojo al crear buzones.** Primero se hace clic en **Voicemail: Enabled** y después se escribe el PIN. Si no, el campo del PIN queda deshabilitado, no se envía y FreePBX muestra *"Undefined array key vmpwd"*.

Verificación: las 9 aparecen en Connectivity → Extensions, con Direct Media = No, y luego se aplicó con **Apply Config**.

## Paso 8. Firewall de FreePBX (17/10, 15:05)

**Connectivity → Firewall → Enable Firewall.** El firewall detecta la IP de la laptop host (`10.0.2.2/32`) y la pone en **Trusted**, así la administración sigue funcionando.

**Interfaces:** `enp0s3` en zona **Internet (Default Firewall)**. Cuando exista `enp0s8` (día de la integración), va en la misma zona.

**Networks:**

| Red | Zona | Descripción |
|---|---|---|
| 10.0.2.2/32 | Trusted | Laptop host (puerto interno de gestión) |
| 192.168.10.0/24 | Trusted | VLAN 10 GESTION (TI) |
| 192.168.20.0/24 | Local | VLAN 20 VOZ |
| 192.168.30.0/24 | Local | VLAN 30 ADMIN |
| 100.64.0.0/10 | Local | Tailscale (E1) |

**Services.** Las redes *Trusted* quedan fuera del firewall, así que no aparecen como columna. Se dejó marcado solo lo que el proyecto usa:

| Servicio | Zonas | Efecto |
|---|---|---|
| SIP (pjsip) | Local | Teléfonos de las VLAN y de Tailscale |
| SSH, web de administración (http y https) | Ninguna | **Solo** desde Trusted (Gestión y laptop host) |
| UCP, aprovisionamiento, API, REST apps, WebRTC, IAX, VPN, FTP, TFTP, XMPP, NTP, Sangoma Phone | Ninguna | Cerrados, no se usan |
| NFS y SMB | Reject | Ya venían así |

**Responsive Firewall:** activado en general, pero con *SIP Protocol (pjsip)* en **Disabled**. Con eso, el SIP que llega por la zona Internet se rechaza siempre, en vez de recibir unos pocos intentos de registro. Es la opción más estricta y no afecta a los teléfonos, porque todos entran por redes Local (voz, ADMIN, Tailscale y hotspot). Fail2ban sigue activo.

**Intrusion Detection (fail2ban).** La pestaña no aparece en esta versión del módulo de firewall. Fail2ban ya trae `bantime 1800`, `findtime 600` y `maxretry 5`, como pide el archivo 07. La lista blanca y el endurecimiento de SSH se aplicaron con un script corrido como administrador:
```powershell
ssh -t -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "sudo bash ~/cmh-endurecer.sh"
```
El script crea `/etc/fail2ban/jail.d/cmh-whitelist.local` con `ignoreip = 127.0.0.1/8 ::1 10.0.2.2 192.168.10.0/24`. Va en `jail.d` porque `jail.local` lo reescribe el módulo de firewall. En el SSH deja `PermitRootLogin prohibit-password` y `MaxAuthTries 3`. Al terminar se borra solo.

Resultado (17/10, 15:08): `ENDURECIMIENTO-OK`. Fail2ban ignora `127.0.0.0/8`, `192.168.10.0/24`, `10.0.2.2` y `::1`. `sshd -T` muestra `maxauthtries 3` y `permitrootlogin without-password` (es el nombre antiguo de `prohibit-password` y significa lo mismo). Después del cambio, la web y el SSH con llave siguen funcionando desde la laptop host.

> Al recargar fail2ban salen avisos como *"No filter set for jail sshd"*. Vienen del archivo `defaults-debian.conf` que trae Debian y ya estaban antes. No afectan, porque la protección de SSH la hace el jail `ssh-iptables`, que sí está completo.

**Prueba de que funciona.** Después de activar el firewall, la web y el SSH siguen abriendo desde la laptop host, porque es Trusted. Las pruebas S1 a S9 del archivo 07 se hacen cuando esté el router.

## Paso 9. Idioma, audios del IVR e IVR (17/10, 15:15 a 15:30)

#### 11.1 Sonidos del sistema en español
**Admin → Sound Languages.** Son los mensajes que dice la PBX ("deje su mensaje", "opción no válida", los números).
1. **Settings → Formats:** solo **ulaw** (venía con g722 y ulaw, eso duplicaba la descarga).
2. Se instaló **Spanish (es)**, voz de Allison Smith, licencia Creative Commons. Bajó unos 13 MB.
3. Por pedido del grupo (español latino) se instaló también **Spanish (es_419)**, voz de Andreina Faria, licencia Creative Commons Atribución 3.0. Ocupa unos 19 MB.
4. **Settings → Language:** `es_419`.

**Por qué quedan los dos paquetes.** Con el idioma `es_419`, Asterisk busca cada audio en `sounds/es_419`, luego en `sounds/es` y al final en `sounds` (documentación oficial de Asterisk, *Sound Prompt Searching based on Channel Language*). El paquete latino no trae los números (`digits` vacío), así que esos salen del paquete `es`. Los audios propios del IVR están en `es/custom` y también se encuentran.

#### 11.2 Audios del IVR
Se generaron en la laptop con la voz **Microsoft Sabina (español de México)** que trae Windows, sin descargar nada. Formato telefónico: WAV, 8 kHz, mono, 16 bits. Están en `C:\Users\Asus\Projects\cmh-horizonte\audios\`.

| Archivo | Duración | Texto |
|---|---|---|
| `ivr-bienvenida.wav` | 28 s | Bienvenida y opciones 1 a 4, 0 para operadora (archivo 04, §5.1) |
| `ivr-invalida.wav` | 7 s | "La opción que marcó no es válida..." |
| `ivr-fuera-horario.wav` | 24 s | Horario de atención (para E4, condiciones horarias) |
| `aviso-grabacion.wav` | 5 s | "Para mejorar nuestro servicio, esta llamada puede ser grabada" (para E4) |

> El PDF pide una locución "clara en español". Una voz sintética lo cumple, pero si el catedrático prefiere voz humana se puede regrabar desde un teléfono con **Admin → System Recordings → Record via phone**, usando los mismos nombres.

**Cómo se subieron.** Se copiaron por SSH a `/home/cmhadmin/audios` y un script de un solo uso los instaló como administrador:
```powershell
ssh -t -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "sudo bash ~/cmh-audios.sh"
```
El script los deja en `/var/lib/asterisk/sounds/es/custom/` con dueño `asterisk`. Después, en **Admin → System Recordings → Add Recording**, se creó una grabación por archivo eligiéndolo en *System Recordings* (idioma `es`, sin conversión de códecs).

#### 11.3 IVR principal
**Applications → IVR → Add IVR:**

| Campo | Valor |
|---|---|
| IVR Name | `IVR-Principal` |
| Announcement | `ivr-bienvenida` |
| Enable Direct Dial | Extensions (se puede marcar la extensión directo) |
| Timeout | 7 s |
| Invalid Retries | 2 · Invalid Retry Recording: `ivr-invalida` |
| Invalid Destination | Extension 1000 (Operadora) |
| Timeout Retries | 1 · Timeout Destination: Extension 1000 |

| Dígito | Destino |
|---|---|
| 1 | Extension 1000 (Recepción) |
| 2 | Extension 2001 (Consulta Externa) |
| 3 | Extension 3001 (Enfermería) |
| 4 | Extension 4001 (Administración) |
| 0 | Extension 1000 (Operadora) |

Con E4, la opción 1 pasa al grupo de timbrado 8000 y la 2 a la cola 8010 (archivo 08).

#### 11.4 Número interno 7000
**Applications → Misc Applications → Add:** descripción `IVR`, extensión **7000**, destino **IVR → IVR-Principal**. Se aplicó con **Apply Config**.

> **Nota sobre los enlaces de FreePBX.** Abrir a mano una dirección con `&action=...` muestra *"Potential Security Breach"*. Pasa porque la VM ve el puerto 80 y el navegador usa el 18080 (reenvío de NAT). Entrando desde los menús y botones de FreePBX no ocurre.

## Paso 10. Respaldo de FreePBX (17/10, 15:30)

**Admin → Backup & Restore → Add Backup:**

| Campo | Valor |
|---|---|
| Nombre | `CMH-diario` |
| Módulos | Todos (96) |
| Almacenamiento | Local (`/var/spool/asterisk/backup/`) |
| Programación | Todos los días a las 2:00 (`0 2 * * *`) |
| Mantenimiento | Guarda los últimos 7 |

Se ejecutó a mano (botón ▶). Salieron avisos de módulos sin datos (callback, callerid, conferencespro y otros), que son normales porque esos módulos no se usan. La copia se descargó a la laptop:
```powershell
scp -P 2222 -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" "cmhadmin@127.0.0.1:/var/spool/asterisk/backup/<archivo>.tar.gz" C:\Users\Asus\Projects\cmh-horizonte\respaldos\
```
> El respaldo **contiene las contraseñas** de las extensiones. Para los anexos del informe se entrega la documentación de configuración, no este archivo (archivo 03, paso 9).

## Paso 11. Modo puente para pruebas fuera del router (17/10, 15:45)

**Objetivo.** Registrar softphones reales (laptop y celular) sin esperar al RB4011. La VM se conecta a la misma red Wi-Fi que la laptop (casa u hotspot) y toma su propia IP. Las llamadas viajan solo por la red local, así que en el hotspot **no gastan datos móviles**.

**Antes de cambiar (con la VM en NAT):**
1. **Asterisk SIP Settings → Local Networks:** se agregó `172.16.0.0/12` (incluye el hotspot del iPhone, `172.20.10.0/28`).
2. **Connectivity → Firewall → Main → Networks:** `172.20.10.0/28` en zona **Local** ("Hotspot iPhone (pruebas fuera del router)"). SIP sí, web y SSH no.
3. Script de un solo uso que declara el puerto interno de gestión en Linux:
   ```powershell
   ssh -t -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "sudo bash ~/cmh-red-gestion.sh"
   ```
   Crea `/etc/network/interfaces.d/cmh-gestion` con `enp0s8` en `10.0.2.15/24`, **sin gateway y sin IPv6**. Así todo el tráfico de la PBX sale por `enp0s3` y la QoS del router se puede medir. `enp0s3` ya estaba por DHCP y no se tocó.

**Cambio en VirtualBox (VM apagada, después del snapshot `03-antes-de-modo-puente`):**
```powershell
$vbm = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
& $vbm modifyvm CMH-FreePBX --nat-pf1 delete ssh
& $vbm modifyvm CMH-FreePBX --nat-pf1 delete http
& $vbm modifyvm CMH-FreePBX --nic1 bridged --bridgeadapter1 "Intel(R) Wi-Fi 6E AX211 160MHz"
& $vbm modifyvm CMH-FreePBX --nic2 nat --nictype2 82540EM --natnet2 "10.0.2.0/24"
& $vbm modifyvm CMH-FreePBX --nat-pf2 "ssh,tcp,127.0.0.1,2222,,22" --nat-pf2 "http,tcp,127.0.0.1,18080,,80"
```

**Resultado verificado:**

| Prueba | Resultado |
|---|---|
| IP de `enp0s3` | 172.20.10.7/28 (DHCP del iPhone) |
| IP de `enp0s8` | 10.0.2.15/24 |
| Ruta por defecto | Una sola, por 172.20.10.1 |
| Web y SSH por `127.0.0.1:18080` y `:2222` | Abren (puerto interno, zona Trusted) |
| Web por `http://172.20.10.7` desde la laptop | **Bloqueada** (zona Local) |
| SIP desde la laptop a 172.20.10.7:5060 | Llega a Asterisk (visto en `/var/log/asterisk/full`) |
| Linphone en el iPhone (ext. 2001) | Registrado desde 172.20.10.1, 35 ms |
| Llamada iPhone → 7000 | IVR en español, funciona (16:05) |
| MicroSIP 3.22.19 en la laptop (ext. 1000) | Registrado desde 172.20.10.4, 2 ms |

> **Modo seguro del firewall.** Después de cada reinicio, el firewall de FreePBX espera **5 minutos** antes de aplicar sus reglas (`/var/run/firewalld.safemode`). Durante ese tiempo todo está abierto. Es una protección contra bloqueos y es normal.

**Softphones.** MicroSIP se instaló con `winget install --id MicroSIP.MicroSIP` (9 MB, sitio oficial). La cuenta quedó en `%APPDATA%\MicroSIP\microsip.ini`: servidor y dominio 172.20.10.7, usuario 1000, UDP. La contraseña la escribe el usuario en *Editar cuenta*. En Linphone (iPhone): *Usar cuenta SIP*, usuario 2001, dominio 172.20.10.7, UDP. En iOS, Linphone solo recibe llamadas con la app abierta, porque el servidor es propio y no tiene notificaciones push.

**Cuando la laptop cambie de red**, la VM toma otra IP. Para verla:
```powershell
ssh -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "ip -br -4 addr show enp0s3"
```
Si la nueva red no es `192.168.x.x` ni `172.16–31.x.x`, hay que agregarla en Local Networks y en el firewall (zona Local). En redes públicas (universidad, cafés) es común que los equipos no se puedan hablar entre sí, y ahí no funciona.

**Día de la integración con el RB4011:** solo cambia el puente del adaptador 1 a la tarjeta Ethernet (`--bridgeadapter1 "Realtek PCIe GbE Family Controller"`) y se fija la IP 192.168.20.10 (archivo 03, paso 5). El puerto interno de gestión ya queda listo.

## Paso 12. Extras E4 sin router (17/10, 16:10 a 16:25)

**Revisión previa.** En **Admin → Feature Codes** ya estaban activos \*97, \*98, \*43, ## (transferencia ciega), \*2 (atendida), \*70 y \*71. En **Advanced Settings**, *Asterisk Dial Options* = `HhTtr` (incluye `T` y `t`, así los dos lados pueden transferir).

#### 14.1 Grupo de timbrado 8000 (Recepción)
**Applications → Ring Groups:** número 8000, descripción `Recepcion`, extensiones 1000 y 1001, estrategia **ringall**, 20 s. Si nadie contesta pasa al **buzón de la 1000 (no disponible)**.

#### 14.2 Cola 8010 (Consulta Externa)
**Applications → Queues:**

| Campo | Valor |
|---|---|
| Número / nombre | 8010 · `Consulta-Externa` |
| Agentes estáticos | `2001,0` y `2002,0` |
| Estrategia | **rrmemory** (reparto rotativo con memoria: reparte la carga entre las dos clínicas) |
| Anuncio al entrar | `aviso-grabacion` |
| Anunciar posición | Sí, cada 30 s |
| Espera máxima | 120 s, luego buzón de la 1000 |
| Música en espera | `CMH` (Paso 12.5) |

**IVR-Principal actualizado:** opción 1 → grupo 8000 y opción 2 → cola 8010. Las demás quedan igual.

#### 14.3 Condiciones horarias
1. **Applications → Time Groups → `Horario-Atencion`:** lunes a viernes de 7:00 a 19:00 y sábado de 7:00 a 12:00.
2. **Applications → IVR → `IVR-FueraHorario`:** anuncio `ivr-fuera-horario`, opción 3 → extensión 3001 (Emergencias), opción 1 → buzón de la 1000. Inválida o sin respuesta → buzón de la 1000.
3. **Applications → Time Conditions → `TC-Horario`:** zona horaria **America/Guatemala**, grupo `Horario-Atencion`. Si coincide → `IVR-Principal`. Si no → `IVR-FueraHorario`.
4. El número **7000** (Misc Applications) ahora apunta a `TC-Horario`.
5. **Código para forzar el modo** en la demostración: **\*271**. Se marca una vez para cambiar de horario normal a fuera de horario, y otra vez para volver.

Además, en **Advanced Settings** se cambió *PHP Timezone* de UTC a **America/Guatemala**, para que la hora que muestra FreePBX y los reportes coincidan con la hora local.

#### 14.4 Grabación de llamadas
Extensión **1000 → Advanced → Recording Options:** entrantes y salientes, internas y externas, en **Force**. Las grabaciones se escuchan en **Reports → CDR Reports** (ícono de reproducir) o en **Reports → Call Recordings**, y solo entra quien llega a la administración web (Gestión o el puerto interno). La cola anuncia la grabación con `aviso-grabacion`.

#### 14.5 Música en espera propia
- La pista `moh-cmh-tema1.wav` (57 s) se compuso con código: progresión Do–La menor–Fa–Sol con melodía, sonido suave tipo piano eléctrico, WAV 8 kHz mono. Es **original**, así que no tiene problemas de derechos de autor. Está en `audios\`.
- **Settings → Music on Hold → Add Category:** `CMH` (tipo *files*). FreePBX crea `/var/lib/asterisk/moh/CMH/`.
- La pista se instala con un script de un solo uso:
  ```powershell
  ssh -t -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "sudo bash ~/cmh-moh.sh"
  ```
- Se usa en la cola 8010. En FreePBX 17 las extensiones no tienen campo propio de música, así que la espera entre extensiones usa la categoría `default`. Cuando exista la troncal E3, la ruta de entrada también usará `CMH`.

#### 14.6 Pendiente de E4
- **Buzón por correo:** falta la cuenta de Gmail del proyecto con contraseña de aplicación (archivo 08, E4.5).

#### 14.7 Pruebas sugeridas (con MicroSIP y Linphone)
| Prueba | Esperado |
|---|---|
| Marcar 8000 | Suenan la 1000 y la 1001 a la vez |
| Marcar 8010 con 2001 registrada | Aviso de grabación, música CMH y luego suena la 2001 |
| Marcar 7000 en horario | IVR principal; opción 1 → grupo 8000 |
| Marcar \*271 y luego 7000 | IVR de fuera de horario; volver con \*271 |
| Llamada desde o hacia la 1000 | Aparece grabada en Reports → CDR Reports |

## Paso 13. Saludos personalizados de los buzones (17/10, 16:50)

El PDF pide buzón "con saludo personalizado" en al menos 2 extensiones (§5.4). Se hicieron en las 4 que tienen buzón.

1. En la laptop se generaron 12 audios con la voz **Microsoft Sabina (es-MX)** de Windows, en formato telefónico (WAV 8 kHz, mono, 16 bits). El código está en C1.9. Quedaron en `audios\buzones\<extensión>\`.

| Archivo | Cuándo suena | Ejemplo (1000) |
|---|---|---|
| `unavail.wav` | Nadie contesta | "Ha llamado a Recepción del Centro Médico Horizonte. En este momento no podemos atenderle..." |
| `busy.wav` | La extensión está ocupada | "...En este momento estamos atendiendo otra llamada..." |
| `greet.wav` | Nombre del buzón | "Recepción" |

2. Se copiaron a la VM y se instalaron con un script de un solo uso:
   ```powershell
   scp -r -P 2222 -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" C:\Users\Asus\Projects\cmh-horizonte\audios\buzones\* cmhadmin@127.0.0.1:/home/cmhadmin/vm-saludos/
   ssh -t -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "sudo bash ~/cmh-saludos.sh"
   ```
   El script los deja en `/var/spool/asterisk/voicemail/default/<extensión>/` con dueño `asterisk`.
3. Verificado: las 4 carpetas tienen `unavail.wav`, `busy.wav` y `greet.wav`.

> Los saludos no dicen "después del tono" porque Asterisk agrega solo el aviso de dejar el mensaje después del tono, en español latino.

**Cómo se graba a mano (para la defensa).** Desde la extensión se marca **\*97**, el PIN y **0** (opciones). Luego **1** para no disponible, **2** para ocupado o **3** para el nombre. Se habla, se marca **#** y **1** para aceptar. Para un buzón sin teléfono se usa **\*98**, el número del buzón y su PIN. Grabar a mano reemplaza el archivo generado.

## Paso 14. E1: Tailscale (en curso)

1. Se habilita el servicio y se pide el enlace de inicio de sesión. Este comando lo ejecuta un integrante, porque abre un acceso remoto permanente a la PBX:
   ```powershell
   ssh -t -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "sudo systemctl enable --now tailscaled && sudo tailscale up --hostname=cmh-pbx --accept-dns=false"
   ```
   `--accept-dns=false` evita que Tailscale cambie el DNS de la PBX.
2. Se abre el enlace que aparece, se inicia sesión con una cuenta **personal** (Gmail no institucional o GitHub) y se autoriza el equipo **cmh-pbx**. Con una cuenta de la universidad, el equipo cae en la red de Tailscale de la UMG y queda esperando la aprobación de su administrador.
3. Estado al 17/10: el servicio está habilitado en la VM y falta la autorización.
4. Lo que sigue (archivo 08, E1): `tailscale0` en zona **Local** del firewall de FreePBX, desactivar el vencimiento de la llave, política de acceso (solo SIP y RTP) y registrar la 5002 en el iPhone por datos móviles.

## Paso 15. Exportar la VM completa (.ova)

Copia completa de la VM con todo lo de los pasos 1 a 14, para llevar a la demostración o pasar a otra laptop.

1. Apagar la VM limpiamente:
   ```powershell
   $vbm = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
   & $vbm controlvm CMH-FreePBX acpipowerbutton
   ```
2. Exportar con manifiesto (el `.mf` guarda las huellas SHA para comprobar que el archivo no se dañó):
   ```powershell
   & $vbm export CMH-FreePBX --output "C:\Users\Asus\Projects\cmh-horizonte\CMH-FreePBX-final.ova" --options manifest --vsys 0 --product "CMH-FreePBX"
   ```
   También se puede hacer desde VirtualBox: **Archivo → Exportar servicio virtualizado**.
3. Sacar la huella del archivo para comprobarlo después de copiarlo:
   ```powershell
   Get-FileHash C:\Users\Asus\Projects\cmh-horizonte\CMH-FreePBX-final.ova
   ```
4. Encender de nuevo la VM.

**Importarla en otra laptop.** VirtualBox → **Archivo → Importar servicio virtualizado** → elegir la `.ova` → Importar. Trae la configuración de red de esta laptop. En otra máquina hay que revisar en *Configuración → Red* que el **adaptador 1** esté en puente a su propia tarjeta (Wi-Fi o Ethernet). El **adaptador 2** (puerto interno de gestión) funciona igual.

> La `.ova` **contiene las contraseñas** de Linux, de FreePBX y de las extensiones. No va a Canvas ni a los anexos, y solo se comparte dentro del grupo.

Esta `.ova` reemplaza a la de la VM base (`CMH-FreePBX-instalada.ova`), que no trae nada de los pasos 2 a 14.

## Paso 16. Scripts del router (preparados, sin probar)

Carpeta `router\`. Son los scripts de los archivos 02 y 06 con las contraseñas de Wi-Fi ya puestas. El orden de carga y los avisos están abajo.

| Archivo | Contenido | Se carga |
|---|---|---|
| `01-base.rsc` | VLAN 10 a 50, bridge, Wi-Fi (5 SSID), IP, DHCP, DNS, NAT, SIP ALG apagado | Antes de la Integración 1 |
| `02-firewall-seguridad.rsc` | Matriz de ACL, servicios mínimos, IPv6 apagado | Antes de la Integración 1 |
| `03-qos.rsc` | Marcado DSCP, colas por prioridad, límite de invitados | Integración 2 |

El usuario `cmh-ti` del router se crea a mano (paso 1.7 del archivo 02). El comando con su contraseña está en `CREDENCIALES-ACTUALES.md`.

---

**Cómo se generaron (17/10, 15:17).** Se copiaron los bloques de código de los archivos 02 (`01-base.rsc`, `02-firewall-seguridad.rsc`) y 06 (`03-qos.rsc`) tal cual. Se reemplazaron los textos `CAMBIAR-...` por contraseñas aleatorias (16 caracteres para el Wi-Fi, 20 para el usuario del router, sin letras confusas como `0/O` o `l/1`). Después se revisó que no quedara ningún `CAMBIAR-` ni caracteres con tilde, porque RouterOS los rechaza.

**Antes de importar `01-base.rsc`:**
- Si `country=guatemala` da error, cambiarlo por `country=no_country_set` (archivo 02, §1.6).
- La reserva DHCP de la laptop de TI está comentada (`#`). Para activarla, quitar el `#` y poner la MAC real de esa laptop.
- Si un `/import` se detiene, `verbose=yes` muestra la línea exacta. Se corrige y se vuelve a importar desde esa sección.
- Los `.rsc` tienen las contraseñas de Wi-Fi reales: **no van a los anexos**. Para los anexos se usa el `/export` del router, que las oculta (archivo 02, paso 5).

**Cargarlos el día del router** (detalle completo en el archivo 02):
```
# 1. Laptop al ether10 (puerto de rescate), Winbox por MAC, reset sin configuracion:
/system reset-configuration no-defaults=yes skip-backup=yes
# 2. Actualizar RouterOS, revisar paquete wireless, renombrar radios a wifi24 y wifi5 (archivo 02, paso 1)
# 3. Crear el usuario cmh-ti (comando con su contrasena en CREDENCIALES-ACTUALES.md) y borrar admin:
/user remove admin
# 4. Arrastrar los .rsc a Files en Winbox e importar en orden:
/import file-name=01-base.rsc verbose=yes
/import file-name=02-firewall-seguridad.rsc verbose=yes
# 5. En la Integracion 2:
/import file-name=03-qos.rsc verbose=yes
```

---

# Parte C. Referencias

## C1. Código de los scripts y herramientas usados

Todos se ejecutaron una sola vez y se borraron solos al terminar. Se copian aquí para poder repetirlos en otra copia de la VM o explicarlos en la defensa. Los que llevan `sudo` piden la contraseña de `cmhadmin`.

### C1.1 Cambio de contraseñas de Linux (Paso 3)
Las contraseñas se generaron con Python (`secrets`, 20 caracteres de `A-Z a-z 0-9 - _ .`). El script que las aplicó en la VM hacía esto:
```bash
#!/bin/bash
# Cambia las contrasenas por defecto de la VM CMH (requisito de seguridad 5.8).
set -e
chpasswd <<'EOF'
cmhadmin:<contraseña nueva>
root:<contraseña nueva>
EOF
echo "CONTRASENAS-CAMBIADAS-OK"
shred -u "$0" 2>/dev/null || rm -f "$0"
```
Forma manual equivalente: `sudo passwd cmhadmin` y `sudo passwd root`.

### C1.2 `cmh-endurecer.sh` (Paso 8)
```bash
#!/bin/bash
# Lista blanca de fail2ban y endurecimiento de SSH (archivo 07, 1.3 y 1.4)
set -e
# 1. Lista blanca: laptop host (puerto interno) y VLAN de Gestion.
#    Va en jail.d/*.local porque jail.local lo reescribe el modulo de firewall de FreePBX.
cat > /etc/fail2ban/jail.d/cmh-whitelist.local <<'EOF'
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 10.0.2.2 192.168.10.0/24
EOF
fail2ban-client reload >/dev/null
# 2. SSH: root solo con llave y maximo 3 intentos por conexion.
if grep -qE '^\s*Include\s+/etc/ssh/sshd_config.d' /etc/ssh/sshd_config; then
  mkdir -p /etc/ssh/sshd_config.d
  printf 'PermitRootLogin prohibit-password\nMaxAuthTries 3\n' > /etc/ssh/sshd_config.d/cmh.conf
else
  printf '\n# CMH (archivo 07, 1.4)\nPermitRootLogin prohibit-password\nMaxAuthTries 3\n' >> /etc/ssh/sshd_config
fi
sshd -t && systemctl reload ssh
echo "--- verificacion ---"
echo "ignoreip ssh-iptables: $(fail2ban-client get ssh-iptables ignoreip | tr '\n' ' ')"
sshd -T | grep -E '^(permitrootlogin|maxauthtries)'
echo "ENDURECIMIENTO-OK"
rm -f "$0"
```

### C1.3 Audios del IVR con la voz de Windows (Paso 9)
PowerShell en la laptop. No descarga nada: usa la voz **Microsoft Sabina (es-MX)** que trae Windows.
```powershell
Add-Type -AssemblyName System.Speech
$out = "C:\Users\Asus\Projects\cmh-horizonte\audios"; New-Item -ItemType Directory -Force -Path $out | Out-Null
$fmt = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(8000, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
function Say($name, $ssmlBody) {
  $s = New-Object System.Speech.Synthesis.SpeechSynthesizer
  $s.SelectVoice("Microsoft Sabina"); $s.Rate = -1
  $s.SetOutputToWaveFile("$out\$name.wav", $fmt)
  $s.SpeakSsml("<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='es-MX'>$ssmlBody</speak>")
  $s.SetOutputToNull(); $s.Dispose()
}
$p = "<break time='600ms'/>"
Say "ivr-bienvenida" "Gracias por llamar al Centro Médico Horizonte. $p Para Recepción y citas, marque 1. $p Para Consulta Externa, marque 2. $p Para Enfermería y Emergencias, marque 3. $p Para Administración y Contabilidad, marque 4. $p Para hablar con una operadora, marque 0, o permanezca en la línea."
Say "ivr-invalida" "La opción que marcó no es válida. $p Por favor, intente de nuevo."
Say "ivr-fuera-horario" "Gracias por llamar al Centro Médico Horizonte. $p Nuestro horario de atención es de lunes a viernes, de siete de la mañana a siete de la noche, y sábados, de siete de la mañana a doce del mediodía. $p Si se trata de una emergencia, marque 3. $p Para dejarnos un mensaje, marque 1."
Say "aviso-grabacion" "Para mejorar nuestro servicio, esta llamada puede ser grabada."
```
Para ver qué voces hay: `(New-Object System.Speech.Synthesis.SpeechSynthesizer).GetInstalledVoices().VoiceInfo.Name`

### C1.4 `cmh-audios.sh` (Paso 9)
Antes se copiaron los WAV a la VM: `scp -P 2222 -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" C:\Users\Asus\Projects\cmh-horizonte\audios\*.wav cmhadmin@127.0.0.1:/home/cmhadmin/audios/` (con `ssh ... "mkdir -p ~/audios"` primero).
```bash
#!/bin/bash
# Copia los audios del IVR a la carpeta de sonidos de Asterisk (idioma es)
set -e
DEST=/var/lib/asterisk/sounds/es/custom
mkdir -p "$DEST"
install -o asterisk -g asterisk -m 644 /home/cmhadmin/audios/*.wav "$DEST/"
chown asterisk:asterisk "$DEST"
ls -l "$DEST"
rm -rf /home/cmhadmin/audios
echo "AUDIOS-OK"
rm -f "$0"
```

### C1.5 `cmh-red-gestion.sh` (Paso 11)
```bash
#!/bin/bash
# Declara el puerto interno de gestion (adaptador 2, NAT de VirtualBox)
# enp0s8: 10.0.2.15/24, SIN gateway y sin IPv6, para que todo el trafico de la PBX salga por enp0s3.
set -e
cat > /etc/network/interfaces.d/cmh-gestion <<'EOF'
# Puerto interno de gestion (adaptador 2, NAT de VirtualBox). Solo lo alcanza la laptop host.
allow-hotplug enp0s8
iface enp0s8 inet static
    address 10.0.2.15/24
    pre-up sysctl -q -w net.ipv6.conf.enp0s8.disable_ipv6=1
EOF
cat /etc/network/interfaces.d/cmh-gestion
echo "RED-GESTION-OK"
rm -f "$0"
```

### C1.6 Música en espera original (Paso 12)
Se generó con Python (numpy) en lugar de bajar música de internet, así es original y sin derechos de autor:
```python
import numpy as np, wave
sr = 8000; bpm = 72; beat = 60/bpm
def hz(n): return 440.0 * 2**((n-69)/12)                      # nota MIDI -> Hz
chords = [[48,52,55,60],[45,52,57,60],[41,48,53,57],[43,50,55,59]]   # Do, Lam, Fa, Sol
melody = [72,76,74,72, 72,71,69,67, 69,72,74,72, 71,74,76,79]
def tone(f, dur, amp, decay):
    t = np.arange(int(sr*dur))/sr
    env = np.exp(-t*decay) * np.minimum(1, t/0.02)
    w = np.sin(2*np.pi*f*t) + 0.25*np.sin(2*np.pi*2*f*t) + 0.08*np.sin(2*np.pi*3*f*t)
    return amp*env*w
bars = []
for rep in range(4):
    for ci, ch in enumerate(chords):
        bar = np.zeros(int(sr*beat*4))
        for k, n in enumerate(ch):                                    # acorde arpegiado
            s = int(sr*beat*k*0.5); x = tone(hz(n), beat*4 - beat*k*0.5, 0.10, 0.9)
            bar[s:s+len(x)] += x[:len(bar)-s]
        if rep in (1, 3):                                             # melodia en 2a y 4a vuelta
            for b in range(4):
                s = int(sr*beat*b); x = tone(hz(melody[(ci*4+b) % 16]), beat*1.2, 0.12, 2.2)
                bar[s:s+len(x)] += x[:len(bar)-s]
        bars.append(bar)
end = np.zeros(int(sr*beat*4))
for n in [48,52,55,60,64]:
    x = tone(hz(n), beat*4, 0.09, 0.7); end[:len(x)] += x
audio = np.concatenate(bars + [end])
fade = int(sr*1.5); audio[:fade] *= np.linspace(0,1,fade); audio[-fade:] *= np.linspace(1,0,fade)
audio = audio / np.max(np.abs(audio)) * 0.7
with wave.open('moh-cmh-tema1.wav','wb') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes((audio*32767).astype('<i2').tobytes())
```

### C1.7 `cmh-moh.sh` (Paso 12)
Antes: `scp -P 2222 -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" C:\Users\Asus\Projects\cmh-horizonte\audios\moh-cmh-tema1.wav cmhadmin@127.0.0.1:/home/cmhadmin/`
```bash
#!/bin/bash
# Instala la musica en espera propia en la categoria CMH de FreePBX
set -e
install -o asterisk -g asterisk -m 644 /home/cmhadmin/moh-cmh-tema1.wav /var/lib/asterisk/moh/CMH/
rm -f /home/cmhadmin/moh-cmh-tema1.wav
ls -l /var/lib/asterisk/moh/CMH/
asterisk -rx "moh reload" >/dev/null && echo "moh recargado"
echo "MOH-OK"
rm -f "$0"
```

### C1.8 Cómo se suben los scripts a la VM
Todos siguieron el mismo patrón desde PowerShell:
```powershell
$k = "$env:USERPROFILE\.ssh\cmh_pbx_ed25519"
scp -P 2222 -i $k .\script.sh cmhadmin@127.0.0.1:/home/cmhadmin/      # copiar
ssh -i $k -p 2222 cmhadmin@127.0.0.1 "bash -n ~/script.sh"            # revisar sintaxis
ssh -t -i $k -p 2222 cmhadmin@127.0.0.1 "sudo bash ~/script.sh"       # ejecutar como administrador
```
> Al escribir el script en Windows hay que guardarlo con fin de línea Unix (`LF`) y sin BOM. Si no, bash falla con `$'\r': command not found`.

### C1.9 Saludos de los buzones (Paso 13)
PowerShell en la laptop, con la misma voz del IVR:
```powershell
Add-Type -AssemblyName System.Speech
$base = "C:\Users\Asus\Projects\cmh-horizonte\audios\buzones"
$fmt = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(8000, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
function Say($path, $body) {
  $s = New-Object System.Speech.Synthesis.SpeechSynthesizer
  $s.SelectVoice("Microsoft Sabina Desktop"); $s.Rate = -1
  $s.SetOutputToWaveFile($path, $fmt)
  $s.SpeakSsml("<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='es-MX'>$body</speak>")
  $s.SetOutputToNull(); $s.Dispose()
}
$areas = [ordered]@{ "1000"="Recepción del Centro Médico Horizonte"; "2001"="la Clínica uno de Consulta Externa del Centro Médico Horizonte"; "3001"="Enfermería del Centro Médico Horizonte"; "4001"="Administración y Contabilidad del Centro Médico Horizonte" }
$names = @{ "1000"="Recepción"; "2001"="Clínica uno, Consulta Externa"; "3001"="Enfermería"; "4001"="Administración y Contabilidad" }
$p = "<break time='500ms'/>"
foreach ($e in $areas.Keys) {
  $d = "$base\$e"; New-Item -ItemType Directory -Force -Path $d | Out-Null
  Say "$d\unavail.wav" "Ha llamado a $($areas[$e]). $p En este momento no podemos atenderle. $p Por favor, deje su nombre, su número de teléfono y el motivo de su llamada, y le devolveremos la llamada lo antes posible."
  Say "$d\busy.wav" "Ha llamado a $($areas[$e]). $p En este momento estamos atendiendo otra llamada. $p Por favor, deje su nombre y su número de teléfono, y le devolveremos la llamada en cuanto nos desocupemos."
  Say "$d\greet.wav" $names[$e]
}
```
`cmh-saludos.sh` en la VM:
```bash
#!/bin/bash
# Instala los saludos personalizados de los buzones 1000, 2001, 3001 y 4001
set -e
for e in 1000 2001 3001 4001; do
  d=/var/spool/asterisk/voicemail/default/$e
  install -d -o asterisk -g asterisk -m 755 "$d" "$d/INBOX"
  for g in unavail busy greet; do
    install -o asterisk -g asterisk -m 644 "/home/cmhadmin/vm-saludos/$e/$g.wav" "$d/$g.wav"
  done
done
rm -rf /home/cmhadmin/vm-saludos
echo "SALUDOS-OK"
rm -f "$0"
```

## C2. Trazabilidad con el PDF (lo ya hecho)

| Sección del PDF | Requisito | Cómo se cumple | Dónde |
|---|---|---|---|
| 5.3 | PBX operativa con versiones documentadas | FreePBX 17.0.33.2 + Asterisk 22.11.0 en Debian 12.15 | Paso 4 |
| 5.3 | Administración solo desde la red de gestión | Firewall de FreePBX: web y SSH solo para `192.168.10.0/24` y el puerto interno de gestión | Paso 8 |
| 5.3 | ≥ 5 extensiones con nombres y contraseñas robustas | 9 extensiones, secretos aleatorios de 32 caracteres | Paso 7 |
| 5.3 | Códecs justificados | ulaw, alaw, g722, opus · cálculo de 87.2 kbps | Paso 6 · plan 01 §5 |
| 5.4 | Llamada en espera | Call Waiting activo en las 9 extensiones | Paso 7 |
| 5.4 | Buzón en ≥ 2 extensiones con código de acceso | 4 buzones (1000, 2001, 3001, 4001) con PIN distinto | Paso 7 |
| 5.4 | IVR en español, ≥ 3 opciones, operadora, inválida y sin respuesta | `IVR-Principal`: 4 opciones + 0, 2 reintentos, pasa a 1000 | Paso 9.3 |
| 6.4 | E4: ≥ 2 funciones avanzadas | Grupo y cola, condiciones horarias, música propia y grabación (4 de 5) | Paso 12 |
| 5.8 | Sin credenciales predeterminadas | Linux, FreePBX y router con contraseñas nuevas; usuario `admin` no se usa | Pasos 3 y 5 · Paso 16 |
| 5.8 | Firewall en la PBX | Firewall de FreePBX con zonas y servicios mínimos | Paso 8 |
| 5.8 | Protección contra intentos repetidos | fail2ban (30 min de bloqueo, 5 intentos) y firewall que rechaza el SIP de redes no confiables | Paso 8 |
| 5.8 | Respaldos | Tarea diaria `CMH-diario`, copia en la laptop, snapshots y `.ova` completa | Pasos 10 y 15 |
| 11 | Credenciales fuera del informe | Todo en `CREDENCIALES-ACTUALES.md`, solo en la laptop | Este archivo |

## C3. Pendientes, en orden

| # | Tarea | Necesita | Archivo |
|---|---|---|---|
| 1 | Actualizar módulos de FreePBX | **Wi-Fi** (~100 MB) | 03, paso 3.2 |
| 2 | Pruebas con llamadas: espera, transferencia (3 teléfonos), dejar y escuchar un mensaje, IVR y E4 (Paso 12.7). Los saludos ya están (Paso 13) | MicroSIP y Linphone ya registrados (Paso 11) | 04 |
| 3 | E4: buzón por correo (lo demás ya está, Paso 12) | La cuenta de Gmail del proyecto | 08, E4.5 |
| 4 | E1: autorizar Tailscale y probar la 5002 por datos móviles (Paso 14) | Cuenta personal de Tailscale | 08, E1 |
| 5 | Día de la integración: cambiar el puente del adaptador 1 a la tarjeta **Realtek PCIe GbE** y fijar la IP 192.168.20.10 (el puerto interno ya está, Paso 11) | El RB4011 | 03, paso 5 |

Ya hechos: pasos 1 a 13 y 15. Los scripts del router están en `router\` (Paso 16).

## C4. Reparación rápida

| Síntoma | Qué hacer |
|---|---|
| Me quedé sin acceso a la web o al SSH después del firewall | En la consola de VirtualBox: `sudo fwconsole firewall trust 10.0.2.2` o, de emergencia, `sudo fwconsole firewall disable`. También se puede volver al snapshot `02-antes-de-config-sip` |
| El SSH se queda colgado y la web sí abre | Bloqueo de fail2ban. En la consola de VirtualBox: `sudo fail2ban-client banned` y `sudo fail2ban-client set ssh-iptables unbanip 10.0.2.2` |
| SSH pide contraseña aunque hay llave | Revisar permisos en la VM: `chmod 700 ~/.ssh` y `chmod 600 ~/.ssh/authorized_keys` |
| La web no abre | `sudo fwconsole restart` y luego `systemctl status freepbx apache2` |
| ¿Asterisk está corriendo? | `pgrep -c asterisk` y `sudo asterisk -rx "core show version"` |
| La VM no responde | `VBoxManage controlvm CMH-FreePBX poweroff` y `VBoxManage startvm CMH-FreePBX`. Si se repite, bajar a 2 vCPU con la VM apagada: `VBoxManage modifyvm CMH-FreePBX --cpus 2` |
| Snapshots | Siempre con la VM **apagada**. Con la VM encendida, VirtualBox puede trabarla |
| La web o el SSH por `127.0.0.1` no abren después de cambiar adaptadores | Revisar en VirtualBox que el **adaptador 2** sea NAT con red `10.0.2.0/24` y los reenvíos 2222 y 18080. En la consola: `ip -br a` debe mostrar `enp0s8` con 10.0.2.15. Último recurso: volver al snapshot `03-antes-de-modo-puente` |
| Se olvidó la contraseña de root | Entrar con `cmhadmin` y ejecutar `sudo passwd root` |
| Se olvidó la contraseña de `cmh-ti` | Por SSH: `sudo mysql asterisk -e "UPDATE ampusers SET password_sha1=SHA1('NUEVA') WHERE username='cmh-ti';"` y anotar la nueva en `CREDENCIALES-ACTUALES.md` |
| Todo falla | Importar `CMH-FreePBX-final.ova` (Paso 15), o volver a un snapshot |
