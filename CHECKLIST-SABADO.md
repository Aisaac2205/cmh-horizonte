# Checklist del sábado. Armar, probar y capturar

**Centro Médico Horizonte, S.A. · PF-TEL-001-2026**
Preparado el 27/10/2026 para la réplica del sábado 31/10.

Todo lo de la PBX ya está listo y capturado. Lo único que falta depende del router armado. Esta lista dice en qué orden hacerlo para que salga a la primera. Las pruebas en detalle están en [`PRUEBAS-ENTREGA.md`](PRUEBAS-ENTREGA.md).

---

## 1. Qué llevar

| Equipo | Para qué |
|---|---|
| hEX RB750Gr3 con su fuente | Router, VLAN, firewall y QoS |
| AP Mercusys MW325R con su fuente | Wi-Fi `CMH-Voz` para los celulares |
| 3 cables de red | ether2 al AP, AP a la laptop host y ether4 a la laptop del compañero |
| Xiaomi 11T y su cable USB | Internet del router (anclaje USB) |
| Laptop host (Isaac) | VM de la PBX, Linphone 5001, iperf3 servidor y Winbox |
| Laptop del compañero | Linphone 4001, iperf3 cliente y `pruebas/Probar-Vlan.ps1` |
| 2 celulares con Linphone | Extensiones 3001 y 5002 con dominio `172.16.20.10` |

---

## 2. Encendido, en este orden

1. **Xiaomi.** Datos móviles encendidos y el cable al USB del hEX. Activar *Anclaje USB* en el celular.
2. **hEX.** Encenderlo y esperar un minuto. En Winbox se ve `lte1` con IP en *IP → DHCP Client*.
3. **AP.** Cable de ether2 del hEX a un puerto LAN del AP (en modo punto de acceso no se usa el WAN). Su IP es 172.16.20.2 y su DHCP sigue apagado.
4. **Laptop host.** Cable a un puerto LAN del AP, Wi-Fi apagado. `ipconfig` debe dar **172.16.20.20**.
5. **VM de la PBX.** En PowerShell:
   ```powershell
   & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" startvm CMH-FreePBX --type headless
   ```
   Tarda unos **4 minutos** en quedar lista (el servicio `freepbx` pasa de *activating* a *active*). Antes de eso los teléfonos no registran.
6. **Celulares.** Wi-Fi `CMH-Voz`, IP 172.16.20.1xx. Linphone en verde.
7. **Laptop del compañero.** Cable en **ether4**, Wi-Fi apagado, `ipconfig /renew`. IP 172.16.30.1xx. Linphone 4001 en verde.

**Revisión rápida (2 minutos).** Desde la laptop host:

```powershell
ping 172.16.20.10
ssh -t -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "sudo asterisk -rx 'pjsip show contacts'; sudo asterisk -rx 'pjsip show registrations'"
```

Deben salir los teléfonos con *Avail* y la troncal `sip2sip` en *Registered*. Si un teléfono no registra por contraseñas malas, está bloqueado por fail2ban (ver la nota de la sección 1 de `PRUEBAS-ENTREGA.md`).

---

## 3. Pruebas, en este orden

| Paso | Qué | Dónde está el detalle |
|---|---|---|
| 1 | Evidencia del router **antes**, con contadores en cero | `PRUEBAS-ENTREGA.md` sección 3, paso 1 |
| 2 | `Probar-Vlan.ps1` en ether4 (Admin), en la laptop host (Voz) y en ether5 (Invitados) | Sección 3 |
| 3 | Ronda de llamadas TEL-01 a TEL-11 | Sección 4 |
| 4 | Evidencia del router **después** | Sección 3, paso 3 |
| 5 | QoS con y sin prioridad | Sección 5 |
| 6 | Extras E1, E3 y una función del E4 | Sección 6 |

---

## 4. Capturas pendientes

Las capturas del hEX que hay en `capturas/` son del 20/10, todavía con 192.168.x. Se reemplazan con **el mismo nombre de archivo**, así la `GUIA-DEMO.md` las muestra sola sin editarla.

**Cómo capturar.** En la laptop conectada a **ether3** (Gestión), abrir la pantalla en Winbox y en PowerShell, desde la carpeta `pruebas`:

```powershell
.\Captura.ps1 34-hex-direcciones
```

El script espera 3 segundos para pasar a la ventana (Alt+Tab), captura solo esa ventana y la guarda en `capturas/` con ese nombre. Con `-PantallaCompleta` toma toda la pantalla.

### 4.1 Router hEX (Winbox desde ether3)

| Archivo | Ruta en Winbox | Qué debe verse |
|---|---|---|
| `30-hex-sistema-usuarios` | *New Terminal*: `/system resource print`, `/system routerboard print`, `/user print`, `/ip firewall service-port print where name=sip` | RouterOS 7.24.x, solo el usuario `cmh-ti` y SIP ALG con X |
| `31-hex-interfaces` | *Interfaces → Interface* | `br-lan`, las cuatro VLAN, ether1 a ether5 y **`lte1`** |
| `33-hex-bridge-vlan` | *Bridge → VLANs* | VLAN 10, 20, 30 y 40 con su puerto sin etiqueta (VLAN-01) |
| `34-hex-direcciones` | *IP → Addresses* | 172.16.10.1, 172.16.20.1, 172.16.30.1 y 172.16.40.1, todas /24 |
| `35a-hex-dhcp-servidores` | *IP → DHCP Server → DHCP* | Cuatro servidores, uno por VLAN |
| `35b-hex-dhcp-leases` | *IP → DHCP Server → Leases* | PBX 172.16.20.10, laptop host .20, celulares y laptop del compañero en .1xx (VLAN-03) |
| `36-hex-firewall-filter` | *IP → Firewall → Filter Rules*, después de las llamadas | M2 y M3 con paquetes, M6 con los bloqueos |
| `37-hex-nat` | *IP → Firewall → NAT* | Masquerade hacia la lista `WAN` (incluye `lte1`) |
| `38-hex-mangle` | *IP → Firewall → Mangle* | Marcado EF, CS3 y AF21 |
| `39-hex-queue-tree` | *Queues → Queue Tree* | `q-wan` con parent **`lte1`** y las colas de prioridad activas |
| `40-hex-servicios` | *IP → Services* | Winbox y SSH solo desde 172.16.10.0/24 |
| `42-hex-wan-lte1` (nueva) | *IP → DHCP Client* | `lte1` en *bound* con la IP que da el Xiaomi |

`30b`, `32` y `37b` no cambian con la migración y se pueden dejar.

### 4.2 Punto de acceso (navegador en `http://172.16.20.2`)

| Archivo | Pantalla | Qué debe verse |
|---|---|---|
| `41-ap-lan` | *Network → LAN* | IP fija 172.16.20.2, puerta de enlace 172.16.20.1 |
| `43-ap-wifi` (nueva) | *Wireless* | SSID `CMH-Voz`, WPA2-PSK AES, canal fijo, WPS apagado. **Contraseña oculta** |

### 4.3 PBX y teléfonos

| Archivo | Dónde | Qué debe verse |
|---|---|---|
| `20-telefonos-registrados` | FreePBX, *Reports → Asterisk Info → Peers* (en `http://127.0.0.1:18080` desde la laptop host) | Al menos 4 extensiones en *Avail* con IP 172.16.x (§5.7) |
| `55-sesion-cdr-sabado` (nueva) | FreePBX, *Reports → CDR Reports* con la fecha del sábado | Las llamadas de la ronda TEL-01 a TEL-11 |
| `56-linphone-4001` (nueva) | Linphone en la laptop del compañero | Cuenta 4001 en verde con dominio 172.16.20.10 (VLAN-04) |

### 4.4 Pruebas de red

| Archivo | Dónde | Qué debe verse |
|---|---|---|
| `60-acl-vlan30-admin` | Terminal de `Probar-Vlan.ps1` en ether4 | 11 de 11 *Cumple* |
| `61-acl-vlan20-voz` | Terminal de `Probar-Vlan.ps1` en la laptop host | 8 de 8 *Cumple* |
| `62-acl-vlan40-invitados` | Terminal de `Probar-Vlan.ps1` en ether5 | Todas *Cumple* |
| `63-qos-con-prioridad` | Terminal del iperf3 de 69k, ronda con QoS | Pérdida cercana a 0 % |
| `64-qos-sin-prioridad` | Terminal del iperf3 de 69k, ronda sin QoS | Pérdida alta |
| `65-qos-colas` | Winbox, `/queue tree print stats where name~"q-voz"` | Paquetes de voz sin descartes |

Las fotos de los celulares (IP del Wi-Fi para VLAN-05 y llamadas con la hora visible) se pasan a `capturas/` con nombres que empiecen en `57-`.

---

## 5. Archivos que hay que recoger

- El `.md` que deja `Probar-Vlan.ps1` en la laptop del compañero (carpeta `resultados` junto al script). Va a `pruebas/resultados/`. **El del 26/10 desde Admin (`vlan30-20261026-175225.md`) no se alcanzó a copiar**, así que el del sábado lo reemplaza.
- Las carpetas `pruebas/evidencias/router-...-antes` y `...-despues` que crea `Evidencia-Router.ps1`. Si la llave del hEX no está importada, el encabezado del script dice cómo hacerlo.

---

## 6. Al terminar

```powershell
cd C:\Users\Asus\Projects\cmh-horizonte
git add capturas pruebas
git commit -m "test: replica del 31/10 con capturas del hEX en clase B"
git push
```

Antes de salir, apagar la VM con `VBoxManage controlvm CMH-FreePBX acpipowerbutton` para no dañar la base de datos.
