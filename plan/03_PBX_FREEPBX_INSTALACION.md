# 03 · PBX: instalación y configuración base de FreePBX 17
**Responsable:** Telefonía (PBX) · **Apoyo:** Seguridad
**Criterio:** C (15 pts) · **Tiempo estimado:** 3–4 h (la instalación tarda ~1 h sola)
**Se puede hacer YA**, en la red de su casa, sin el router del proyecto.

---

## Paso 1. Crear la máquina virtual (VirtualBox 7)

| Parámetro | Valor |
|---|---|
| Nombre | `CMH-FreePBX` |
| Tipo / versión | Linux / Debian (64-bit) |
| CPU | 2 vCPU |
| RAM | 3 GB (mínimo 2 GB) |
| Disco | 30 GB VDI dinámico |
| Red (adaptador 1) | **Adaptador puente** → la tarjeta Ethernet de la laptop |
| Red (adaptador 2) | **NAT** con reenvío de puertos solo en `127.0.0.1`: `2222 → 22` (SSH) y `18080 → 80` (web). Es el **puerto interno de gestión** |
| Audio, USB | Deshabilitados (no se necesitan) |

- En casa: el puente puede ir a la tarjeta Wi-Fi o Ethernet de la laptop (la VM recibe IP del router de su casa).
- En el proyecto: el puente va a la **tarjeta Ethernet**, conectada a un puerto LAN del AP MW325R, que cuelga de ether2 del hEX (VLAN 20). Windows no necesita manejar VLAN, porque ether2 es un puerto de acceso.
- **Puerto interno de gestión (adaptador 2).** La laptop host queda en la VLAN 20, donde el firewall de FreePBX no permite administrar. Por eso la VM tiene un segundo adaptador NAT cuyos reenvíos solo escuchan en `127.0.0.1` de la laptop host. Desde ahí se abre `http://127.0.0.1:18080` y `ssh -p 2222 cmhadmin@127.0.0.1`. Ningún otro equipo de la red llega a ese adaptador.
- Con la VM apagada, se agrega así (PowerShell):
  ```powershell
  $vbm = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
  & $vbm modifyvm CMH-FreePBX --nic1 bridged --bridgeadapter1 "<nombre de la tarjeta Ethernet>"
  & $vbm modifyvm CMH-FreePBX --nic2 nat --nictype2 82540EM --natnet2 "10.0.2.0/24"
  & $vbm modifyvm CMH-FreePBX --nat-pf2 "ssh,tcp,127.0.0.1,2222,,22" --nat-pf2 "http,tcp,127.0.0.1,18080,,80"
  ```
  Antes, quitar los reenvíos del adaptador 1 si existen: `--nat-pf1 delete ssh` y `--nat-pf1 delete http`.
  `--natnet2` es necesario porque VirtualBox le da al segundo adaptador NAT la red 10.0.3.0/24 por defecto. Así la VM queda en 10.0.2.15 y la laptop host se ve como 10.0.2.2, igual que en el modo NAT de casa.
  Este cambio se hace **el día de la integración**. En casa se sigue usando el adaptador 1 en NAT, como viene.

- [ ] Captura: configuración de la VM.

---

## Paso 2. Instalar Debian 12 (bookworm), mínimo

FreePBX 17 se instala **sobre Debian 12** con el script oficial de Sangoma. (Verifiquen en el wiki de FreePBX si hay una versión más reciente del procedimiento.)

1. Descargar `debian-12.x.x-amd64-netinst.iso` desde debian.org y montarla en la VM.
2. Instalación gráfica, idioma Español, zona horaria **America/Guatemala**.
3. Hostname: `cmh-pbx` · Dominio: vacío.
4. Contraseña de root robusta → al gestor de contraseñas.
5. Usuario normal: `cmhadmin`.
6. Particionado: guiado, todo en una partición.
7. En **Selección de programas**: desmarcar todo el entorno de escritorio; marcar solo **Servidor SSH** y **utilidades estándar del sistema**.
8. Reiniciar y entrar como root.

---

## Paso 3. Instalar FreePBX 17

```bash
apt update && apt -y upgrade
apt -y install wget
cd /tmp
wget https://github.com/FreePBX/sng_freepbx_debian_install/raw/master/sng_freepbx_debian_install.sh -O sng_freepbx_debian_install.sh
bash sng_freepbx_debian_install.sh
```
- Tarda entre 30 y 60 minutos. **No cierren la ventana.**
- Al terminar, anotar la IP: `ip -4 addr`.
- [ ] Captura: final de la instalación y versión (`fwconsole --version`, `asterisk -V`).

### 3.1 Asistente inicial (navegador)
1. Abrir `http://IP-DE-LA-VM` desde la laptop.
2. Crear el usuario administrador (**no usar `admin`**, por ejemplo `cmh-ti`) con contraseña robusta y el correo del proyecto.
3. Idioma de sonidos: **Español** (si aparece; si no, ver paso 6.3).
4. Asistente de Firewall: **se canceló a propósito**. Activarlo con valores por defecto bloquea la administración desde la laptop host. El firewall se configura completo con el archivo 07.
5. La activación comercial y los módulos comerciales: **omitir**.

### 3.2 Actualizar módulos
**Admin → Module Admin → Check Online → Upgrade all → Process → Apply Config.**
- [ ] Captura: módulos al día.

---

## Paso 4. Exportar la VM para el equipo (ahorro de tiempo)
Con la PBX instalada y actualizada (antes de crear extensiones):
- VirtualBox → **Archivo → Exportar servicio virtualizado** → `CMH-FreePBX-base.ova` → subir a Drive.
- Funcionalidades, Terminales y Extras importan su copia para **practicar**. La VM **oficial** la mantiene el responsable de Telefonía.

---

## Paso 5. IP estática en la VLAN de voz (al integrar)

Opción de respaldo. Lo normal es que la PBX reciba **192.168.20.10** por la reserva DHCP del hEX (archivo 02). Si se prefiere IP fija, cuando la laptop host ya esté en la VLAN 20, editar `/etc/network/interfaces` (ver los nombres con `ip link`; suelen ser `enp0s3` para el adaptador 1 y `enp0s8` para el adaptador 2):

```
auto enp0s3
iface enp0s3 inet static
    address 192.168.20.10/24
    gateway 192.168.20.1
    dns-nameservers 192.168.20.1

# Puerto interno de gestion (adaptador 2, NAT de VirtualBox). SIN gateway.
auto enp0s8
iface enp0s8 inet static
    address 10.0.2.15/24
```
> El adaptador 2 **no lleva gateway**. Si lo tuviera, la PBX sacaría su tráfico por el NAT de VirtualBox y no por el router, y la QoS dejaría de verse. Si usan `/root/cmh-ip-estatica.sh`, revisen con `ip -4 addr` y `ip route` que queden las dos interfaces y una sola ruta por defecto (por 192.168.20.1).
```bash
systemctl restart networking
ping -c 3 192.168.20.1
ping -c 3 1.1.1.1
```
Si `dns-nameservers` no aplica, editar `/etc/resolv.conf` con `nameserver 192.168.20.1`.

- [ ] La interfaz web abre en `http://192.168.20.10` **desde la laptop de GESTION** (ether3).
- [x] La interfaz web abre en `http://127.0.0.1:18080` **desde la laptop host** (puerto interno de gestión). *(hecho 17/10)*
- [ ] `ip route` en la VM muestra **una sola** ruta por defecto, por 192.168.20.1.

**Laptop host (Windows):** a su tarjeta Ethernet asignarle IP fija **192.168.20.20/24**, gateway 192.168.20.1, DNS 192.168.20.1. Será el servidor iperf3 en las pruebas de QoS.

---

## Paso 6. Ajustes SIP y de audio

### 6.1 Settings → Asterisk SIP Settings → pestaña **General SIP Settings**
| Campo | Valor |
|---|---|
| External Address | Botón **Detect Network Settings** (necesario para la troncal E3) |
| Local Networks | `192.168.0.0/16` y `100.64.0.0/10` (red de Tailscale, E1) |
| RTP Port Ranges | Start `10000` · End `20000` |
| Allow Anonymous Inbound SIP Calls | **No** |
| Allow SIP Guests | **No** |
| Codecs (orden) | ✅ ulaw, ✅ alaw, ✅ g722, ✅ opus (si aparece). Desmarcar el resto |

### 6.2 Pestaña **SIP Settings [chan_pjsip]**
- Transports: dejar `0.0.0.0 - udp` habilitado en el puerto 5060.
- Deshabilitar transportes que no usen (tcp/tls/ws) para reducir la superficie de ataque.

**Submit → Apply Config.**

### 6.3 Idioma español
**Admin → Sound Languages** → instalar **Spanish (es)** → en Settings, poner el idioma por defecto en `es`.
(Los mensajes del sistema, como "por favor deje su mensaje", quedan en español.)

### 6.4 Marcado DSCP desde la PBX (verificación)
El router clasifica el tráfico por IP y puerto (archivo 06), así que la QoS funciona aunque la PBX no marque. Aun así, verifiquen qué marca Asterisk:
```bash
asterisk -rx "pjsip show endpoint 1000" | grep -i tos
```
- Si muestra `tos_audio: 184` (EF) y `tos` de transporte `96` (CS3), la PBX ya marca. Documentarlo.
- Si muestra 0, agregar en **Settings → Asterisk SIP Settings → SIP Settings [chan_pjsip] → Other PJSIP Settings** (o en `/etc/asterisk/pjsip.endpoint_custom_post.conf`) los valores `tos_audio=ef` y `cos_audio=5`, y en el transporte `tos=cs3`. Si la interfaz no lo permite, documenten que la marcación la hace el router (frontera de confianza).

---

## Paso 7. Extensiones (mínimo 5; implementamos 9)

**Connectivity → Extensions → Add Extension → Add New SIP [chan_pjsip] Extension.**

| Ext. | Display Name | Buzón | Notas |
|---|---|---|---|
| 1000 | Operadora Recepcion | ✅ | Destino del 0 del IVR |
| 1001 | Recepcion Movil | — | Celular |
| 2001 | Clinica 1 | ✅ | Celular |
| 2002 | Clinica 2 | — | Laptop |
| 3001 | Enfermeria | ✅ | Celular |
| 3002 | Emergencias | — | Laptop |
| 4001 | Administracion | ✅ | PC |
| 5001 | TI Gerencia | — | Laptop GESTION |
| 5002 | TI Remoto | — | Celular por Tailscale (E1) |

Para **cada** extensión:
1. Pestaña **General**: User Extension, Display Name y **Secret**. Dejen la contraseña generada por FreePBX (larga y aleatoria) y anótenla en el gestor de contraseñas.
2. Pestaña **Voicemail** (solo las marcadas): Enabled = Yes, Voicemail Password = PIN de 4–6 dígitos **distinto por extensión**. El correo se configura en el archivo 08 (E4).
3. Pestaña **Advanced**:
   - **Direct Media: No.** El audio pasa por la PBX y así atraviesa la política de QoS y funciona con NAT.
   - **Call Waiting: Enable.**
   - **Max Contacts: 1.**
4. **Submit** → al terminar todas, **Apply Config**.

- [x] Captura: lista de extensiones (Connectivity → Extensions). *(hecho 17/10)*

### 7.1 Verificar registros (cuando los softphones estén configurados, archivo 05)
```bash
asterisk -rx "pjsip show contacts"
```
Deben aparecer **≥ 4 contactos `Avail`** al mismo tiempo (requisito de §5.7).

---

## Paso 8. Registro de eventos y CDR (auditoría)

- **Reports → CDR Reports**: verificar que se registran las llamadas (origen, destino, duración, disposición).
- **Reports → System Logfiles**: registro `full`.
- Por consola:
```bash
tail -f /var/log/asterisk/full           # eventos en vivo
asterisk -rx "core show channels"        # llamadas activas
asterisk -rx "pjsip show channelstats"   # jitter, pérdida y RTT por llamada (QoS)
```
- [x] Captura: CDR con varias llamadas de prueba. *(hecho 17/10)*
- [ ] Para el informe: explicar cuánto tiempo se conservan los registros y quién puede verlos (solo administradores desde GESTION).

---

## Paso 9. Respaldo de FreePBX
**Admin → Backup & Restore → Add Backup**
- Nombre: `CMH-diario` · Items: todos · Storage: local · Schedule: diario.
- Ejecutar **Run** ahora y **descargar** el `.tar.gz`.
- Para los anexos, el respaldo **no debe exponer contraseñas**: entreguen el respaldo comprimido con contraseña o, mejor, una **exportación de configuración documentada** (capturas + tablas) indicando que las credenciales fueron retiradas.

---

## Lista de verificación final (PBX)
- [ ] Debian 12 + FreePBX 17 instalados; versiones documentadas
- [ ] Módulos actualizados; idioma español *(idioma listo el 17/10: español latino `es_419`. Faltan los módulos, requieren Wi-Fi)*
- [ ] IP estática 192.168.20.10; navegación y DNS funcionando
- [x] Ajustes SIP: redes locales, RTP 10000–20000, códecs, sin invitados anónimos *(hecho 17/10)*
- [x] 9 extensiones con contraseñas robustas y Direct Media = No *(hecho 17/10)*
- [x] CDR y logs funcionando *(hecho 17/10)*
- [ ] Seguridad de la plataforma aplicada (archivo 07)
- [x] Respaldo ejecutado y descargado *(hecho 17/10)*
- [ ] VM exportada (`.ova`) como respaldo de la demostración
