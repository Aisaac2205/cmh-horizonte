# 02 · Red: MikroTik RB750Gr3 (hEX) y AP Mercusys MW325R
**Responsable:** Red y VLAN · **Apoyo:** Seguridad
**Criterio:** B (17 pts) + parte de §5.8 · **Tiempo estimado:** 2 h
**Datos de diseño:** ver [01_DISENO_DE_LA_SOLUCION.md](01_DISENO_DE_LA_SOLUCION.md)

El 19/10 el grupo cambió el RB4011 por equipos que ya tenía. Este archivo reemplaza al plan del RB4011 (queda en el historial de git).

| Equipo | Función en el proyecto | Límites que cambian el diseño |
|---|---|---|
| **MikroTik RB750Gr3 (hEX)** | Router, switch de 5 puertos, VLAN, DHCP, NAT, firewall y QoS. RouterOS v7 | 5 puertos Gigabit y **sin Wi-Fi**. El chip MT7621 hace el filtrado de VLAN por hardware desde RouterOS v7 |
| **Mercusys MW325R** | Punto de acceso Wi-Fi en **modo AP** para la VLAN de Voz | Un solo SSID de 2.4 GHz (802.11n), **sin VLAN**. Sus 2 puertos LAN (100 Mbps) quedan en la misma VLAN que su enlace |

La configuración del router se carga con **3 scripts** (carpeta `router\`):

| Script | Qué hace | Cuándo |
|---|---|---|
| `01-base.rsc` | VLAN, bridge, IP, DHCP con reservas, DNS, NAT, hora | Integración 1 |
| `02-firewall-seguridad.rsc` | Matriz de ACL y endurecimiento del router | Integración 1 |
| `03-qos.rsc` | Marcado DSCP, colas por prioridad, límite de invitados | Integración 2 (archivo 06) |

---

## 1. Diseño físico

```
                    Internet (router de la casa o de la U)
                                  │
                               ether1 (WAN, NAT)
                    ┌─────────────┴─────────────┐
                    │   MikroTik RB750Gr3 (hEX) │
                    └──┬──────┬──────┬──────┬───┘
                  ether2  ether3  ether4  ether5
                  VLAN 20 VLAN 10 VLAN 30 VLAN 40
                   Voz   Gestión  Admin  Invitados
                    │      │       │       │
          AP Mercusys   Laptop  Laptop  Laptop de
          MW325R (AP)   de TI   softphone prueba
          SSID CMH-Voz          + iperf3
          puerto LAN ─► Laptop host (VM FreePBX 192.168.20.10)
```

| Puerto | Modo | VLAN | Conectado a |
|---|---|---|---|
| ether1 | WAN (ruteado) | — | Internet |
| ether2 | Acceso | 20 VOZ | AP MW325R. La laptop host va a un puerto LAN del AP |
| ether3 | Acceso | 10 GESTION | Laptop de TI (Winbox, web de FreePBX y del AP) |
| ether4 | Acceso | 30 ADMIN | Laptop con softphone. En la prueba de QoS también corre el cliente iperf3 |
| ether5 | Acceso | 40 INVITADOS | Laptop o equipo de prueba de invitados |

**Por qué así.**
- El MW325R no maneja VLAN, así que todo lo que entra por él queda en una sola VLAN. Se dedica a **Voz**, que es la VLAN que pide SSID según el PDF (§5.5).
- La laptop host va en un puerto LAN del AP y no en otro puerto del hEX. Así sobran puertos para las cuatro VLAN. Una llamada usa unos 87 kbps por sentido, muy por debajo de los 100 Mbps de ese puerto.
- La VLAN 50 (Médicos) era opcional y se elimina. El PDF pide cuatro como mínimo.
- No hay puerto de rescate como el ether10 del RB4011. Se usa **Safe Mode** de Winbox (si se pierde la conexión, el router deshace los cambios) y, en el peor caso, el botón de reset y volver a importar los scripts (unos 10 minutos).

**Limitaciones para el informe.**
- No hay SSID de invitados ni de administración, porque el AP tiene un solo SSID sin VLAN. Invitados y Administrativa se prueban por cable (ether5 y ether4).
- La QoS del router se aplica al tráfico **enrutado** (entre VLAN y hacia internet). Dentro de la VLAN de Voz el tráfico se conmuta por hardware y el AP solo ofrece WMM. Por eso las mediciones de QoS se hacen entre ADMIN y VOZ (archivo 06).
- El AP no tiene firewall propio. Su web queda alcanzable desde la VLAN de Voz y se protege con una contraseña robusta.

---

## 2. Preparación (en casa, 20 min)

- [ ] Descargar **Winbox** desde mikrotik.com (sección Software).
- [x] Scripts `01`, `02` y `03` adaptados al hEX, sin acentos y sin contraseñas. *(hecho 20/10)*
- [x] Reservas DHCP con las MAC reales de la VM (192.168.20.10) y de la tarjeta Ethernet de la laptop host (192.168.20.20). *(hecho 20/10)*
- [ ] Cables de red: ether1 (internet), ether2 (AP), laptop host al AP y uno por cada laptop en ether3, ether4 y ether5.
- [ ] Contraseñas en `CREDENCIALES-ACTUALES.md`. Usuario `cmh-ti` del router y Wi-Fi `CMH-Voz`.
---

## 3. Reset y actualización del hEX (30 min)

### 3.1 Conectarse
1. Laptop de TI → **ether3**. Internet → **ether1**.
2. Winbox → pestaña **Neighbors** → el hEX por su **dirección MAC** → usuario `admin` (contraseña de la etiqueta o vacía).

### 3.2 Reset sin configuración por defecto
```
/system reset-configuration no-defaults=yes skip-backup=yes
```
Volver a entrar **por MAC**.
- [ ] Captura: Winbox conectado por MAC después del reset.

### 3.3 Internet temporal y actualización (RouterOS v7, canal stable)
```
/ip dhcp-client add interface=ether1 disabled=no
/ip dns set servers=1.1.1.1,8.8.8.8
/ping 1.1.1.1 count=3
```
1. **System → Packages → Check For Updates** → `stable` → **Download & Install**. Si el hEX tiene RouterOS 6, este paso lo pasa a v7 (necesario para el filtrado de VLAN por hardware).
2. **System → RouterBOARD → Upgrade** y `/system reboot`.
3. `/system resource print` y `/system routerboard print`.
- [ ] Captura: versión 7.x de RouterOS y firmware actualizados.

### 3.4 Usuario nuevo y eliminar `admin`
Antes de importar se borra el cliente DHCP temporal (el script 1 lo vuelve a crear):
```
/ip dhcp-client remove [find]
/user add name=cmh-ti group=full password="CONTRASEÑA-DE-CREDENCIALES"
```
Entrar con **cmh-ti** (por MAC) y luego `/user remove admin`.
- [ ] Captura: `/user print` solo con `cmh-ti`.

---

## 4. Script 1: base (`01-base.rsc`)

1. Activar **Safe Mode** (botón en Winbox o `Ctrl+X` en la terminal).
2. Arrastrar `01-base.rsc` a **Files** y ejecutar:
```
/import file-name=01-base.rsc verbose=yes
```
3. Si todo responde, desactivar Safe Mode para guardar.

```
# =====================================================================
# 01-base.rsc - Centro Medico Horizonte - MikroTik RB750Gr3 hEX (RouterOS v7)
# Bridge con VLAN (filtrado por hardware, chip MT7621), IP, DHCP, DNS, NAT
# Wi-Fi: punto de acceso Mercusys MW325R en modo AP, conectado a ether2 (VLAN 20)
# =====================================================================
#
# Puertos:
#   ether1  WAN (internet de la casa o de la U)
#   ether2  VLAN 20 VOZ        -> AP MW325R. La laptop host va en un puerto LAN del AP
#   ether3  VLAN 10 GESTION    -> laptop de TI
#   ether4  VLAN 30 ADMIN      -> laptop con softphone (y cliente iperf3)
#   ether5  VLAN 40 INVITADOS  -> laptop de prueba de invitados
#
# Importar conectado a ether3, con Winbox por MAC y en Safe Mode (Ctrl+X).

# ---------- Identidad y hora (evidencias con hora correcta) ----------
/system identity set name=CMH-hEX
/system clock set time-zone-autodetect=no time-zone-name=America/Guatemala
/system ntp client set enabled=yes
/system ntp client servers add address=pool.ntp.org

# ---------- Comentarios de puertos ----------
/interface ethernet
set [find default-name=ether1] comment="WAN - internet"
set [find default-name=ether2] comment="VOZ - AP Mercusys MW325R y laptop host"
set [find default-name=ether3] comment="GESTION - laptop de TI"
set [find default-name=ether4] comment="ADMIN - laptop con softphone"
set [find default-name=ether5] comment="INVITADOS - laptop de prueba"

# ---------- Listas de interfaces ----------
/interface list
add name=WAN comment="Salida a internet"
add name=LAN comment="Redes internas (VLAN)"
add name=MGMT comment="Interfaces de administracion"
/interface list member
add list=WAN interface=ether1

# ---------- Bridge (el filtrado de VLAN se activa al FINAL) ----------
/interface bridge
add name=br-lan protocol-mode=rstp vlan-filtering=no frame-types=admit-only-vlan-tagged comment="Bridge LAN con VLAN"

# ---------- Puertos de acceso (pvid = VLAN del puerto) ----------
/interface bridge port
add bridge=br-lan interface=ether2 pvid=20 frame-types=admit-only-untagged-and-priority-tagged comment="VOZ - AP y laptop host"
add bridge=br-lan interface=ether3 pvid=10 frame-types=admit-only-untagged-and-priority-tagged comment="GESTION"
add bridge=br-lan interface=ether4 pvid=30 frame-types=admit-only-untagged-and-priority-tagged comment="ADMIN"
add bridge=br-lan interface=ether5 pvid=40 frame-types=admit-only-untagged-and-priority-tagged comment="INVITADOS"

# ---------- Tabla de VLAN del bridge ----------
/interface bridge vlan
add bridge=br-lan vlan-ids=10 tagged=br-lan untagged=ether3 comment="GESTION"
add bridge=br-lan vlan-ids=20 tagged=br-lan untagged=ether2 comment="VOZ"
add bridge=br-lan vlan-ids=30 tagged=br-lan untagged=ether4 comment="ADMIN"
add bridge=br-lan vlan-ids=40 tagged=br-lan untagged=ether5 comment="INVITADOS"

# ---------- Interfaces VLAN (puertas de enlace) ----------
/interface vlan
add name=vlan10-gestion interface=br-lan vlan-id=10
add name=vlan20-voz interface=br-lan vlan-id=20
add name=vlan30-admin interface=br-lan vlan-id=30
add name=vlan40-invitados interface=br-lan vlan-id=40

/interface list member
add list=LAN interface=vlan10-gestion
add list=LAN interface=vlan20-voz
add list=LAN interface=vlan30-admin
add list=LAN interface=vlan40-invitados
add list=MGMT interface=vlan10-gestion

/ip address
add address=192.168.10.1/24 interface=vlan10-gestion comment="GW GESTION"
add address=192.168.20.1/24 interface=vlan20-voz comment="GW VOZ"
add address=192.168.30.1/24 interface=vlan30-admin comment="GW ADMIN"
add address=192.168.40.1/24 interface=vlan40-invitados comment="GW INVITADOS"

# ---------- DHCP por VLAN ----------
/ip pool
add name=pool-gestion ranges=192.168.10.100-192.168.10.199
add name=pool-voz ranges=192.168.20.100-192.168.20.199
add name=pool-admin ranges=192.168.30.100-192.168.30.199
add name=pool-invitados ranges=192.168.40.100-192.168.40.199

/ip dhcp-server
add name=dhcp-gestion interface=vlan10-gestion address-pool=pool-gestion lease-time=8h disabled=no
add name=dhcp-voz interface=vlan20-voz address-pool=pool-voz lease-time=8h disabled=no
add name=dhcp-admin interface=vlan30-admin address-pool=pool-admin lease-time=8h disabled=no
add name=dhcp-invitados interface=vlan40-invitados address-pool=pool-invitados lease-time=2h disabled=no

/ip dhcp-server network
add address=192.168.10.0/24 gateway=192.168.10.1 dns-server=192.168.10.1 comment="GESTION"
add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=192.168.20.1 comment="VOZ"
add address=192.168.30.0/24 gateway=192.168.30.1 dns-server=192.168.30.1 comment="ADMIN"
add address=192.168.40.0/24 gateway=192.168.40.1 dns-server=192.168.40.1 comment="INVITADOS"

# ---------- Reservas DHCP ----------
# FreePBX: MAC del adaptador 1 de la VM CMH-FreePBX (VirtualBox)
/ip dhcp-server lease
add server=dhcp-voz address=192.168.20.10 mac-address=08:00:27:A5:DA:0A comment="FreePBX (VM CMH-FreePBX)"
# Laptop host, tarjeta Ethernet Realtek (servidor iperf3 en las pruebas de QoS)
add server=dhcp-voz address=192.168.20.20 mac-address=A0:36:BC:5F:4A:DE comment="Laptop host / iperf3"
# El AP MW325R usa IP fija 192.168.20.2, configurada en el propio AP (fuera del rango DHCP)
# Laptop de TI en GESTION: quitar el # y poner su MAC real
# add server=dhcp-gestion address=192.168.10.10 mac-address=AA:BB:CC:DD:EE:FF comment="Laptop de TI"

# ---------- WAN, DNS y NAT ----------
/ip dhcp-client remove [find]
/ip dhcp-client add interface=ether1 disabled=no comment="WAN"
/ip dns set allow-remote-requests=yes servers=1.1.1.1,8.8.8.8
/ip firewall nat add chain=srcnat out-interface-list=WAN action=masquerade comment="NAT salida a internet"

# SIP ALG desactivado: la PBX maneja el NAT por si misma (ver informe)
/ip firewall service-port set sip disabled=yes

# Proteccion temporal de la WAN (el script 2 la reemplaza)
/ip firewall filter
add chain=input connection-state=established,related action=accept comment="TEMP"
add chain=input in-interface-list=WAN action=drop comment="TEMP"

# ---------- ACTIVAR filtrado de VLAN (ultimo paso) ----------
/interface bridge set br-lan vlan-filtering=yes
```

### 4.1 Verificación
- [ ] `/interface bridge port print` → los puertos ether2 a ether5 con la bandera **H** (filtrado por hardware). Si no aparece, `/interface bridge set br-lan protocol-mode=none` y revisar de nuevo.
- [ ] `/interface bridge vlan print` → VLAN 10, 20, 30 y 40 con su puerto.
- [ ] Laptop en ether3 recibe **192.168.10.1xx**. En ether4, **192.168.30.1xx**. En ether5, **192.168.40.1xx**.
- [ ] `/ip dhcp-server lease print` → captura de las concesiones por VLAN (evidencia).

---

## 5. AP Mercusys MW325R en modo AP (20 min)

1. Reset del AP (botón 5 s) y conectar la laptop a un **puerto LAN** del AP, **sin** conectarlo todavía al hEX.
2. Entrar a `http://mwlogin.net` y crear la contraseña de administrador (guardarla en `CREDENCIALES-ACTUALES.md`).
3. **Sistema → Modo de operación → Punto de acceso** (*System → Operation Mode → Access Point*). Guardar y esperar el reinicio.
4. **Red → LAN**: IP **estática 192.168.20.2**, máscara 255.255.255.0, puerta de enlace 192.168.20.1.
5. **Inalámbrico**: SSID **`CMH-Voz`**, seguridad **WPA2-PSK (AES)** con la contraseña de `CREDENCIALES-ACTUALES.md`. **WPS desactivado**. Canal fijo 1, 6 u 11 (el menos ocupado), ancho 20 MHz.
6. Conectar un **puerto LAN** del AP a **ether2** del hEX (no el puerto WAN del AP).

> Si el firmware del AP no trae el menú **Modo de operación**, la guía oficial de Mercusys indica el método manual: IP fija de la LAN en la red del router principal y fuera de su rango DHCP (192.168.20.2), **servidor DHCP desactivado** y cable desde un puerto LAN del AP al router.

### 5.1 Verificación
- [ ] Celular conectado a **CMH-Voz** recibe **192.168.20.1xx** del hEX (no del AP).
- [ ] Desde la laptop de TI (ether3) abre `http://192.168.20.2`.
- [ ] Captura: pantalla del AP en modo AP y la lista de clientes Wi-Fi.

---

## 6. Laptop host y PBX en la VLAN de Voz

Los pasos exactos están en `CONFIG.md` sección 9. En resumen:

1. Apagar la VM y pasar el adaptador 1 a la tarjeta **Realtek PCIe GbE** (cable).
2. Conectar la laptop host por cable a un **puerto LAN del AP**.
3. Encender la VM. Por DHCP recibe **192.168.20.10** gracias a la reserva del script 1. Si el cable se conecta con la VM ya encendida, el vigilante de red de la VM pide la IP nueva en menos de un minuto.
4. Comprobar con `ip -br -4 addr` y `ip route` una sola ruta por defecto, por **192.168.20.1**.
5. Celulares conectados a **CMH-Voz**: dominio **192.168.20.10** en Linphone y Tailscale desactivado.

---

## 7. Script 2: firewall, ACL y seguridad (`02-firewall-seguridad.rsc`)

Con Safe Mode activo, igual que el script 1.

```
# =====================================================================
# 02-firewall-seguridad.rsc - Matriz de comunicacion entre VLAN + hardening (hEX RB750Gr3)
# =====================================================================

# ---------- Listas de direcciones ----------
/ip firewall address-list
add list=net-gestion address=192.168.10.0/24
add list=net-voz address=192.168.20.0/24
add list=net-admin address=192.168.30.0/24
add list=net-invitados address=192.168.40.0/24
add list=pbx address=192.168.20.10 comment="FreePBX"
add list=ap address=192.168.20.2 comment="AP Mercusys MW325R"
add list=iperf-srv address=192.168.20.20 comment="Servidor iperf3 (pruebas QoS)"

# ---------- Limpiar reglas anteriores ----------
/ip firewall filter remove [find dynamic=no]

/ip firewall filter
# ===== INPUT: trafico dirigido al router =====
add chain=input connection-state=established,related,untracked action=accept comment="IN: conexiones establecidas"
add chain=input connection-state=invalid action=drop comment="IN: descartar invalidas"
add chain=input in-interface-list=WAN protocol=udp dst-port=68 action=accept comment="IN: cliente DHCP de la WAN"
add chain=input src-address-list=net-gestion in-interface=vlan10-gestion action=accept comment="IN: GESTION administra el router"
add chain=input in-interface-list=LAN protocol=icmp action=accept comment="IN: ICMP desde LAN (diagnostico)"
add chain=input in-interface-list=LAN protocol=udp dst-port=53,67 action=accept comment="IN: DNS y DHCP"
add chain=input in-interface-list=LAN protocol=tcp dst-port=53 action=accept comment="IN: DNS TCP"
add chain=input action=drop comment="IN: descartar el resto (incluye WAN)"

# ===== FORWARD: trafico entre VLAN y hacia internet =====
add chain=forward connection-state=established,related,untracked action=accept comment="FWD: conexiones establecidas"
add chain=forward connection-state=invalid action=drop comment="FWD: descartar invalidas"
add chain=forward src-address-list=net-gestion action=accept comment="M1: GESTION -> todas las VLAN (TI)"
add chain=forward src-address-list=net-admin dst-address-list=pbx protocol=udp dst-port=5060,10000-20000 action=accept comment="M2: ADMIN -> PBX solo SIP y RTP"
add chain=forward src-address-list=pbx dst-address-list=net-admin protocol=udp action=accept comment="M3: PBX -> softphones ADMIN (SIP/RTP)"
add chain=forward src-address-list=pbx dst-address-list=net-gestion protocol=udp action=accept comment="M4: PBX -> softphones GESTION (SIP/RTP)"
add chain=forward src-address-list=net-admin dst-address-list=iperf-srv protocol=tcp dst-port=5201-5202 action=accept disabled=yes comment="PRUEBA-QOS: ADMIN -> iperf3 TCP (habilitar solo en pruebas)"
add chain=forward src-address-list=net-admin dst-address-list=iperf-srv protocol=udp dst-port=5201-5202 action=accept disabled=yes comment="PRUEBA-QOS: ADMIN -> iperf3 UDP (habilitar solo en pruebas)"
add chain=forward in-interface-list=LAN out-interface-list=WAN action=accept comment="M5: todas las VLAN -> Internet"
add chain=forward action=drop log=yes log-prefix="DROP-FWD " comment="M6: descartar todo lo demas (matriz)"

# ---------- Servicios del router: solo lo necesario ----------
/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set www-ssl disabled=yes
set api disabled=yes
set api-ssl disabled=yes
set ssh address=192.168.10.0/24
set winbox address=192.168.10.0/24
/ip ssh set strong-crypto=yes

# ---------- Descubrimiento y acceso por MAC solo en interfaces de gestion ----------
/tool mac-server set allowed-interface-list=MGMT
/tool mac-server mac-winbox set allowed-interface-list=MGMT
/tool mac-server ping set enabled=no
/ip neighbor discovery-settings set discover-interface-list=MGMT
/tool bandwidth-server set enabled=no
/ip proxy set enabled=no
/ip socks set enabled=no
/ip upnp set enabled=no

# ---------- IPv6 desactivado (el proyecto no lo usa y no tiene firewall IPv6) ----------
/ipv6 settings set disable-ipv6=yes

# ---------- Registro ----------
/system logging add topics=firewall action=memory
```
### 7.1 Verificación (= pruebas de la matriz, guardar capturas)

| # | Prueba | Desde | Resultado esperado |
|---|---|---|---|
| 1 | `ping 192.168.20.10` | Laptop ADMIN (ether4) | ❌ Falla (ADMIN solo llega a SIP y RTP) |
| 2 | Registrar un softphone a 192.168.20.10 | Laptop ADMIN (ether4) | ✅ Registrado |
| 3 | Llamada entre la laptop ADMIN y un celular en CMH-Voz | Laptop ADMIN | ✅ Audio en los dos sentidos (llamada entre VLAN) |
| 4 | `ping 192.168.30.1xx` (laptop ADMIN) | Laptop INVITADOS (ether5) | ❌ Falla |
| 5 | Abrir `http://192.168.20.10` | Laptop GESTION (ether3) | ✅ Abre FreePBX |
| 6 | Abrir `http://192.168.20.10` | Laptop ADMIN (ether4) | ❌ No abre |
| 7 | Winbox a 192.168.30.1 | Laptop ADMIN | ❌ No conecta |
| 8 | Winbox a 192.168.10.1 | Laptop GESTION | ✅ Conecta |
| 9 | Navegar a internet | Todas las VLAN | ✅ |
| 10 | `/log print where message~"DROP-FWD"` | Router | Se ven los intentos bloqueados (evidencia de ACL) |
| 11 | `/ipv6 address print` | Router | Sin direcciones IPv6 |

---

## 8. Script 3: QoS
Se aplica en la **Integración 2**. El script y la medición están en [06_QOS_Y_MEDICIONES.md](06_QOS_Y_MEDICIONES.md). Las colas van sobre `vlan20-voz`, `vlan30-admin` y `ether1`, que existen igual en el hEX.

> ⚠️ **No agregar FastTrack.** Con FastTrack los paquetes se saltan mangle y colas, y la QoS deja de funcionar. Con el reset sin configuración por defecto no existe.

---

## 9. Respaldos (anexos)
Después de cada sesión y al congelar la configuración:
```
/export file=cmh-hex-export
/system backup save name=cmh-hex-backup
```
- `/export` en RouterOS v7 oculta las contraseñas por defecto. Este es el archivo de los anexos.
- Descargar ambos desde **Files**.
- [ ] Revisar el `.rsc` exportado: **no debe tener** contraseñas.
- [ ] Del AP: **Sistema → Respaldo** y guardar el archivo.

---

## Problemas comunes

| Síntoma | Causa probable | Solución |
|---|---|---|
| Se perdió el acceso a Winbox durante un script | VLAN o firewall | Con Safe Mode, esperar unos segundos y el router deshace el cambio. Sin Safe Mode, reset y volver a importar |
| `/import` se detuvo a la mitad | Una línea con error | Leer la salida de `verbose=yes`, corregir y seguir desde esa sección |
| Celular en CMH-Voz recibe IP 192.168.0.x o 192.168.1.x | El AP sigue en modo router con DHCP | Revisar el modo AP y que el cable vaya a un puerto **LAN** del AP |
| Celular en CMH-Voz sin IP | El AP está conectado por su puerto WAN | Moverlo a un puerto LAN |
| La PBX no queda en 192.168.20.10 | El adaptador 1 sigue en Wi-Fi o la MAC cambió | `CONFIG.md` sección 9. Revisar `macaddress1` de la VM contra la reserva |
| Audio en un solo sentido | SIP ALG o firewall | `service-port sip` deshabilitado y reglas M2 y M3 |

---

## Lista de verificación final (Red)
- [ ] RouterOS v7 stable y firmware actualizados
- [ ] Usuario `admin` eliminado, servicios innecesarios apagados, IPv6 desactivado
- [ ] 4 VLAN con IP y DHCP, filtrado por hardware (bandera H)
- [ ] AP en modo AP con `CMH-Voz` (WPA2-AES, sin WPS) entregando IP de la VLAN 20
- [ ] Matriz de ACL verificada con las 11 pruebas
- [ ] NAT funcionando, SIP ALG desactivado
- [ ] Respaldos del router (sin contraseñas) y del AP descargados
- [ ] Capturas guardadas: E-RED-01 … E-RED-12

**Fuentes:** MikroTik, *Basic VLAN switching* (filtrado de VLAN por hardware del MT7621 desde RouterOS v7), https://help.mikrotik.com/docs/display/ROS/Basic+VLAN+switching · Mercusys, *How to configure the Mercusys router as an access point*, https://www.mercusys.com/faq-123/