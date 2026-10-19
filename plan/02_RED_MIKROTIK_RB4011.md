# 02 · Red: MikroTik RB4011 (VLAN, DHCP, NAT, ACL, Wi-Fi y seguridad)
**Responsable:** Red y VLAN · **Apoyo:** Seguridad
**Criterio:** B (17 pts) + parte de §5.8 · **Tiempo estimado:** 2–3 h
**Datos de diseño:** ver [01_DISENO_DE_LA_SOLUCION.md](01_DISENO_DE_LA_SOLUCION.md)

La configuración se carga con **3 scripts**, uno por etapa:

| Script | Qué hace | Cuándo |
|---|---|---|
| `01-base.rsc` | VLAN, bridge, Wi-Fi, IP, DHCP, DNS, NAT, hora | Antes de la Integración 1 |
| `02-firewall-seguridad.rsc` | Matriz de ACL, endurecimiento del router | Antes de la Integración 1 |
| `03-qos.rsc` | Marcado DSCP, colas por prioridad, límite de invitados | Integración 2 (ver archivo 06) |

> **Puerto de rescate:** `ether10` queda **fuera del bridge** con IP fija 192.168.88.1. Si una VLAN queda mal, siempre se puede entrar por ahí. Durante toda la configuración, la laptop va conectada a **ether10**.

---

## Paso 0. Preparación (en su casa, 30 min)

- [ ] Descargar **Winbox** desde mikrotik.com (sección Software).
- [x] Copiar los scripts de este archivo en archivos de texto (`01-base.rsc`, `02-firewall-seguridad.rsc`, `03-qos.rsc`) con **codificación UTF-8 sin acentos** dentro del script. *(hecho 17/10)*
- [x] Reemplazar en los scripts **todas** las contraseñas que empiezan con `CAMBIAR-` por contraseñas robustas (≥ 12 caracteres). Guardarlas en el gestor de contraseñas del grupo, **nunca** en el informe. *(hecho 17/10)*
- [ ] Tener un cable de red para ether1 (internet) y otro para ether10 (laptop).

---

## Paso 1. Reset y actualización (30–40 min)

### 1.1 Conectarse
1. Laptop → **ether10** del RB4011. Router de casa → **ether1**.
2. Abrir Winbox → pestaña **Neighbors** → seleccionar el RB4011 por su **dirección MAC** → usuario `admin` (contraseña: la de la etiqueta del equipo o vacía si es antiguo).

### 1.2 Reset sin configuración por defecto
En **New Terminal**:
```
/system reset-configuration no-defaults=yes skip-backup=yes
```
Esperar a que reinicie y volver a entrar **por MAC** (Neighbors).

- [ ] Captura: Winbox conectado por MAC después del reset.

### 1.3 Internet temporal para actualizar
```
/ip dhcp-client add interface=ether1 disabled=no
/ip dns set servers=1.1.1.1,8.8.8.8
/ping 1.1.1.1 count=3
```

### 1.4 Actualizar RouterOS (v7, canal stable) y el firmware
1. **System → Packages → Check For Updates** → Channel: `stable` → **Download & Install** (reinicia).
2. Volver a entrar por MAC → **System → RouterBOARD → Upgrade** → reiniciar (`/system reboot`).
3. Verificar:
```
/system resource print
/system routerboard print
```
- [ ] Captura: versión de RouterOS y firmware actualizados.

### 1.5 Revisar el paquete de Wi-Fi
**System → Packages**: debe estar instalado **`wireless`**.
- Si además aparece **`wifi-qcom-ac`**, desinstálenlo (*Uninstall* → reiniciar). Ese paquete cambia la radio de 5 GHz al menú `/interface wifi` y los scripts de este plan usan el menú clásico `/interface wireless`.

### 1.6 Identificar las radios y renombrarlas
```
/interface wireless print
```
Observen la columna **BAND** / **FREQUENCY** de `wlan1` y `wlan2`. Renombren según corresponda (ejemplo: si `wlan1` es la de 5 GHz):
```
/interface wireless set [find default-name=wlan1] name=wifi5
/interface wireless set [find default-name=wlan2] name=wifi24
```
Verificar que el país exista en la lista:
```
/interface wireless info country-info guatemala
```
Si da error, en el script 1 cambien `country=guatemala` por `country=no_country_set`.

### 1.7 Crear un usuario nuevo y eliminar `admin`
```
/user add name=cmh-ti group=full password="CAMBIAR-Usuario-Router"
```
Cerrar Winbox, entrar con **cmh-ti** (por MAC) y luego:
```
/user remove admin
```
- [ ] Captura: `/user print` mostrando solo `cmh-ti`.

---

## Paso 2. Script 1: base (`01-base.rsc`)

Cómo cargarlo: arrastrar el archivo a la ventana **Files** de Winbox y ejecutar:
```
/import file-name=01-base.rsc verbose=yes
```
(`verbose=yes` muestra la línea exacta si algo falla.) Alternativa: copiar y pegar el contenido en **New Terminal**.

```
# =====================================================================
# 01-base.rsc - Centro Medico Horizonte - MikroTik RB4011 (RouterOS v7)
# Bridge con VLAN, Wi-Fi multi-SSID, IP, DHCP, DNS, NAT
# Antes de importar: radios renombradas a wifi24 y wifi5 (paso 1.6)
# =====================================================================

# ---------- Identidad y hora (evidencias con hora correcta) ----------
/system identity set name=CMH-RB4011
/system clock set time-zone-autodetect=no time-zone-name=America/Guatemala
/system ntp client set enabled=yes
/system ntp client servers add address=pool.ntp.org

# ---------- Listas de interfaces ----------
/interface list
add name=WAN comment="Salida a internet"
add name=LAN comment="Redes internas (VLAN)"
add name=MGMT comment="Interfaces de administracion"
/interface list member
add list=WAN interface=ether1

# ---------- Puerto de rescate (fuera del bridge) ----------
/interface ethernet set [find default-name=ether10] comment="RESCATE 192.168.88.1 (solo TI)"
/ip address add address=192.168.88.1/24 interface=ether10 comment="Puerto de rescate"
/interface list member add list=MGMT interface=ether10

# ---------- Bridge (filtrado de VLAN se activa al FINAL) ----------
/interface bridge
add name=br-lan protocol-mode=rstp vlan-filtering=no frame-types=admit-only-vlan-tagged comment="Bridge LAN con VLAN"

# ---------- Wi-Fi: perfiles de seguridad ----------
/interface wireless security-profiles
add name=sp-voz mode=dynamic-keys authentication-types=wpa2-psk unicast-ciphers=aes-ccm group-ciphers=aes-ccm wpa2-pre-shared-key="CAMBIAR-WifiVoz-2026"
add name=sp-admin mode=dynamic-keys authentication-types=wpa2-psk unicast-ciphers=aes-ccm group-ciphers=aes-ccm wpa2-pre-shared-key="CAMBIAR-WifiAdmin-2026"
add name=sp-inv mode=dynamic-keys authentication-types=wpa2-psk unicast-ciphers=aes-ccm group-ciphers=aes-ccm wpa2-pre-shared-key="CAMBIAR-WifiInvitados"

# ---------- Wi-Fi: radios principales ----------
/interface wireless
set [find name=wifi24] mode=ap-bridge band=2ghz-b/g/n channel-width=20mhz frequency=auto country=guatemala installation=indoor wireless-protocol=802.11 wmm-support=enabled wps-mode=disabled ssid=CMH-Admin security-profile=sp-admin disabled=no
set [find name=wifi5] mode=ap-bridge band=5ghz-a/n/ac channel-width=20/40/80mhz-XXXX frequency=auto country=guatemala installation=indoor wireless-protocol=802.11 wmm-support=enabled wps-mode=disabled ssid=CMH-Voz-5G security-profile=sp-voz disabled=no

# ---------- Wi-Fi: SSID virtuales ----------
add name=wifi24-voz master-interface=wifi24 ssid=CMH-Voz security-profile=sp-voz wps-mode=disabled disabled=no
add name=wifi24-inv master-interface=wifi24 ssid=CMH-Invitados security-profile=sp-inv wps-mode=disabled default-forwarding=no disabled=no
add name=wifi5-admin master-interface=wifi5 ssid=CMH-Admin-5G security-profile=sp-admin wps-mode=disabled disabled=no

# ---------- Puertos del bridge (acceso = pvid de su VLAN) ----------
/interface bridge port
add bridge=br-lan interface=ether2 pvid=20 frame-types=admit-only-untagged-and-priority-tagged comment="VOZ - Laptop host FreePBX"
add bridge=br-lan interface=ether3 pvid=10 frame-types=admit-only-untagged-and-priority-tagged comment="GESTION - Laptop TI"
add bridge=br-lan interface=ether4 pvid=30 frame-types=admit-only-untagged-and-priority-tagged comment="ADMIN - PC softphone"
add bridge=br-lan interface=ether5 pvid=30 frame-types=admit-only-untagged-and-priority-tagged comment="ADMIN - Laptop iperf"
add bridge=br-lan interface=ether6 pvid=40 frame-types=admit-only-untagged-and-priority-tagged comment="INVITADOS - prueba"
add bridge=br-lan interface=ether7 pvid=50 frame-types=admit-only-untagged-and-priority-tagged comment="MEDICOS (opcional)"
add bridge=br-lan interface=ether8 pvid=20 frame-types=admit-only-untagged-and-priority-tagged comment="VOZ - equipo cableado"
add bridge=br-lan interface=ether9 frame-types=admit-only-vlan-tagged comment="TRONCAL reservada (AP/switch futuro)"
add bridge=br-lan interface=wifi24 pvid=30 frame-types=admit-only-untagged-and-priority-tagged comment="SSID CMH-Admin"
add bridge=br-lan interface=wifi24-voz pvid=20 frame-types=admit-only-untagged-and-priority-tagged comment="SSID CMH-Voz"
add bridge=br-lan interface=wifi24-inv pvid=40 frame-types=admit-only-untagged-and-priority-tagged comment="SSID CMH-Invitados"
add bridge=br-lan interface=wifi5 pvid=20 frame-types=admit-only-untagged-and-priority-tagged comment="SSID CMH-Voz-5G"
add bridge=br-lan interface=wifi5-admin pvid=30 frame-types=admit-only-untagged-and-priority-tagged comment="SSID CMH-Admin-5G"

# ---------- Tabla de VLAN del bridge ----------
# (los puertos Wi-Fi se agregan solos como untagged segun su pvid)
/interface bridge vlan
add bridge=br-lan vlan-ids=10 tagged=br-lan,ether9 untagged=ether3 comment="GESTION"
add bridge=br-lan vlan-ids=20 tagged=br-lan,ether9 untagged=ether2,ether8 comment="VOZ"
add bridge=br-lan vlan-ids=30 tagged=br-lan,ether9 untagged=ether4,ether5 comment="ADMIN"
add bridge=br-lan vlan-ids=40 tagged=br-lan,ether9 untagged=ether6 comment="INVITADOS"
add bridge=br-lan vlan-ids=50 tagged=br-lan,ether9 untagged=ether7 comment="MEDICOS"

# ---------- Interfaces VLAN (gateways) ----------
/interface vlan
add name=vlan10-gestion interface=br-lan vlan-id=10
add name=vlan20-voz interface=br-lan vlan-id=20
add name=vlan30-admin interface=br-lan vlan-id=30
add name=vlan40-invitados interface=br-lan vlan-id=40
add name=vlan50-medicos interface=br-lan vlan-id=50

/interface list member
add list=LAN interface=vlan10-gestion
add list=LAN interface=vlan20-voz
add list=LAN interface=vlan30-admin
add list=LAN interface=vlan40-invitados
add list=LAN interface=vlan50-medicos
add list=MGMT interface=vlan10-gestion

/ip address
add address=192.168.10.1/24 interface=vlan10-gestion comment="GW GESTION"
add address=192.168.20.1/24 interface=vlan20-voz comment="GW VOZ"
add address=192.168.30.1/24 interface=vlan30-admin comment="GW ADMIN"
add address=192.168.40.1/24 interface=vlan40-invitados comment="GW INVITADOS"
add address=192.168.50.1/24 interface=vlan50-medicos comment="GW MEDICOS"

# ---------- DHCP por VLAN ----------
/ip pool
add name=pool-gestion ranges=192.168.10.100-192.168.10.199
add name=pool-voz ranges=192.168.20.100-192.168.20.199
add name=pool-admin ranges=192.168.30.100-192.168.30.199
add name=pool-invitados ranges=192.168.40.100-192.168.40.199
add name=pool-medicos ranges=192.168.50.100-192.168.50.199

/ip dhcp-server
add name=dhcp-gestion interface=vlan10-gestion address-pool=pool-gestion lease-time=8h disabled=no
add name=dhcp-voz interface=vlan20-voz address-pool=pool-voz lease-time=8h disabled=no
add name=dhcp-admin interface=vlan30-admin address-pool=pool-admin lease-time=8h disabled=no
add name=dhcp-invitados interface=vlan40-invitados address-pool=pool-invitados lease-time=2h disabled=no
add name=dhcp-medicos interface=vlan50-medicos address-pool=pool-medicos lease-time=8h disabled=no

# Reserva de la laptop de TI (192.168.10.10): quitar el # y poner su MAC real
# /ip dhcp-server lease add server=dhcp-gestion address=192.168.10.10 mac-address=AA:BB:CC:DD:EE:FF comment="Laptop de TI"

/ip dhcp-server network
add address=192.168.10.0/24 gateway=192.168.10.1 dns-server=192.168.10.1 comment="GESTION"
add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=192.168.20.1 comment="VOZ"
add address=192.168.30.0/24 gateway=192.168.30.1 dns-server=192.168.30.1 comment="ADMIN"
add address=192.168.40.0/24 gateway=192.168.40.1 dns-server=192.168.40.1 comment="INVITADOS"
add address=192.168.50.0/24 gateway=192.168.50.1 dns-server=192.168.50.1 comment="MEDICOS"

# ---------- WAN, DNS y NAT ----------
/ip dhcp-client remove [find]
/ip dhcp-client add interface=ether1 disabled=no comment="WAN"
/ip dns set allow-remote-requests=yes servers=1.1.1.1,8.8.8.8
/ip firewall nat add chain=srcnat out-interface-list=WAN action=masquerade comment="NAT salida a internet"

# SIP ALG desactivado: la PBX maneja NAT por si misma (ver informe)
/ip firewall service-port set sip disabled=yes

# Proteccion temporal de la WAN (el script 2 la reemplaza)
/ip firewall filter
add chain=input connection-state=established,related action=accept comment="TEMP"
add chain=input in-interface-list=WAN action=drop comment="TEMP"

# ---------- ACTIVAR filtrado de VLAN (ultimo paso) ----------
/interface bridge set br-lan vlan-filtering=yes
```

### 2.1 Verificación del script 1
- [ ] `/interface bridge vlan print` → aparecen las VLAN 10–50 con sus puertos (los `wifi*` como *dynamic untagged*).
- [ ] Laptop en **ether4** recibe IP **192.168.30.1xx**; en **ether3** recibe **192.168.10.1xx** (la laptop de TI, **192.168.10.10** si se activó su reserva).
- [ ] Celular conectado a **CMH-Voz-5G** recibe **192.168.20.1xx**; a **CMH-Invitados**, **192.168.40.1xx**.
- [ ] Todos navegan a internet.
- [ ] `/ip dhcp-server lease print` → captura de las concesiones por VLAN (evidencia).

---

## Paso 3. Script 2: firewall, ACL y seguridad (`02-firewall-seguridad.rsc`)

```
# =====================================================================
# 02-firewall-seguridad.rsc - Matriz de comunicacion entre VLAN + hardening
# =====================================================================

# ---------- Listas de direcciones ----------
/ip firewall address-list
add list=net-gestion address=192.168.10.0/24
add list=net-voz address=192.168.20.0/24
add list=net-admin address=192.168.30.0/24
add list=net-invitados address=192.168.40.0/24
add list=net-medicos address=192.168.50.0/24
add list=net-rescate address=192.168.88.0/24
add list=pbx address=192.168.20.10 comment="FreePBX"
add list=iperf-srv address=192.168.20.20 comment="Servidor iperf3 (pruebas QoS)"

# ---------- Limpiar reglas anteriores ----------
/ip firewall filter remove [find dynamic=no]

/ip firewall filter
# ===== INPUT: trafico dirigido al router =====
add chain=input connection-state=established,related,untracked action=accept comment="IN: conexiones establecidas"
add chain=input connection-state=invalid action=drop comment="IN: descartar invalidas"
add chain=input in-interface-list=WAN protocol=udp dst-port=68 action=accept comment="IN: cliente DHCP de la WAN"
add chain=input in-interface=ether10 action=accept comment="IN: puerto de rescate"
add chain=input src-address-list=net-gestion in-interface=vlan10-gestion action=accept comment="IN: GESTION administra el router"
add chain=input in-interface-list=LAN protocol=icmp action=accept comment="IN: ICMP desde LAN (diagnostico)"
add chain=input in-interface-list=LAN protocol=udp dst-port=53,67 action=accept comment="IN: DNS y DHCP"
add chain=input in-interface-list=LAN protocol=tcp dst-port=53 action=accept comment="IN: DNS TCP"
add chain=input action=drop comment="IN: descartar el resto (incluye WAN)"

# ===== FORWARD: trafico entre VLAN y hacia internet =====
add chain=forward connection-state=established,related,untracked action=accept comment="FWD: conexiones establecidas"
add chain=forward connection-state=invalid action=drop comment="FWD: descartar invalidas"
add chain=forward src-address-list=net-gestion action=accept comment="M1: GESTION -> todas las VLAN (TI)"
add chain=forward src-address-list=net-rescate action=accept comment="M1b: RESCATE -> todas"
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
set ssh address=192.168.10.0/24,192.168.88.0/24
set winbox address=192.168.10.0/24,192.168.88.0/24
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

### 3.1 Verificación del script 2 (= pruebas de la matriz, guardar capturas)
| # | Prueba | Desde | Resultado esperado |
|---|---|---|---|
| 1 | `ping 192.168.20.10` | Laptop ADMIN (ether4) | ❌ Falla (ADMIN solo puede SIP/RTP) |
| 2 | Registrar softphone 4001 a 192.168.20.10 | Laptop ADMIN | ✅ Registrado |
| 3 | `ping 192.168.30.1xx` (laptop ADMIN) | Celular en CMH-Invitados (app de ping) | ❌ Falla |
| 4 | Abrir `http://192.168.20.10` | Laptop GESTION | ✅ Abre FreePBX |
| 5 | Abrir `http://192.168.20.10` | Laptop ADMIN | ❌ No abre |
| 6 | Winbox a 192.168.30.1 | Laptop ADMIN | ❌ No conecta |
| 7 | Winbox a 192.168.10.1 | Laptop GESTION | ✅ Conecta |
| 8 | Navegar a internet | Todas las VLAN | ✅ |
| 9 | `/log print where message~"DROP-FWD"` | Router | Se ven los intentos bloqueados (evidencia de ACL) |
| 10 | `/ipv6 address print` | Router | Sin direcciones IPv6 (IPv6 desactivado) |

---

## Paso 4. Script 3: QoS
Se aplica en la **Integración 2**. El script completo y el procedimiento de medición están en [06_QOS_Y_MEDICIONES.md](06_QOS_Y_MEDICIONES.md).

> ⚠️ **No agreguen reglas de FastTrack.** FastTrack hace que los paquetes se salten mangle y las colas, y la QoS dejaría de funcionar. Con el reset sin configuración por defecto no existe; no la creen.

---

## Paso 5. Respaldos (para los anexos)
Ejecutar después de cada sesión y al congelar la configuración (viernes 23):
```
/export file=cmh-rb4011-export
/system backup save name=cmh-rb4011-backup
```
- `/export` en RouterOS v7 **oculta las contraseñas por defecto** (no usen `show-sensitive`). Este es el archivo que va en los anexos.
- Descargar ambos archivos desde **Files** (arrastrar a la PC).
- [ ] Revisar el `.rsc` exportado con un editor: **no debe contener** `wpa2-pre-shared-key` ni contraseñas.

---

## Problemas comunes

| Síntoma | Causa probable | Solución |
|---|---|---|
| Me quedé sin acceso a Winbox | Filtrado de VLAN o firewall | Conectar a **ether10**, IP manual 192.168.88.2/24, Winbox a 192.168.88.1 |
| `/import` se detuvo a la mitad | Una línea con error | Leer la salida de `verbose=yes`, corregir y volver a importar **desde esa sección** (o reset y empezar) |
| Un SSID no entrega IP | El puerto `wifi*` no está en el bridge con su `pvid` | `/interface bridge port print` y revisar el `pvid` |
| Error con `country=guatemala` | País no reconocido | Usar `country=no_country_set` |
| El celular no ve la red 5 GHz | Canal DFS o país | Fijar `frequency=5180` (canal 36) en `wifi5` |
| Audio en un solo sentido | SIP ALG o firewall | Verificar `service-port sip` deshabilitado y reglas M2/M3 |

---

## Lista de verificación final (Red)
- [ ] RouterOS v7 stable y firmware actualizados
- [ ] Usuario `admin` eliminado; servicios innecesarios deshabilitados; IPv6 desactivado
- [ ] 5 VLAN con IP, DHCP y SSID funcionando
- [ ] Matriz de ACL verificada con las 10 pruebas
- [ ] NAT funcionando; SIP ALG desactivado
- [ ] Respaldo `/export` sin contraseñas descargado
- [ ] Capturas guardadas: E-RED-01 … E-RED-12
