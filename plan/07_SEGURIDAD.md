# 07 · Seguridad de la solución (§5.8, transversal)
**Responsable:** Seguridad · **Apoyo:** Red y Telefonía
**Criterios:** C (seguridad de la plataforma) y parte de B y G · **Tiempo estimado:** 2–3 h
**Se puede adelantar YA:** el análisis de riesgos, la práctica con nmap en su propia red y el endurecimiento en la copia de la VM.

> ⚖️ **Uso ético (§11):** todas las pruebas se hacen **solo** contra los equipos del proyecto. Nunca escaneen la red de la universidad ni la de terceros.

---

## 1. Lista de verificación §5.8

### 1.1 Credenciales y configuraciones predeterminadas
- [ ] Router: usuario `admin` eliminado, usuario `cmh-ti` con contraseña robusta (archivo 02, paso 1.7).
- [ ] Router: contraseñas de Wi-Fi únicas por SSID (≥ 12 caracteres).
- [x] FreePBX: administrador web distinto de `admin` y con contraseña robusta. *(hecho 17/10)*
- [x] FreePBX: **secret de cada extensión generado por FreePBX** (aleatorio y único). *(hecho 17/10)*
- [x] FreePBX: **PIN de buzón distinto** en cada extensión (no `1234`, no igual a la extensión). *(hecho 17/10)*
- [x] Debian: contraseña de root robusta; SSH **sin login de root por contraseña**. *(hecho 17/10)*
- [ ] Todas las credenciales en un **gestor de contraseñas compartido** (Bitwarden u otro), nunca en el chat del grupo ni en el informe.

### 1.2 Servicios expuestos mínimos y firewall
**Router (ya aplicado con el script 2):**
- [ ] Telnet, FTP, www, API deshabilitados; Winbox y SSH solo desde 172.16.10.0/24 y el puerto de rescate.
- [ ] Input desde la WAN: todo descartado.
- [ ] Matriz de ACL entre VLAN (archivo 01, sección 3).

**FreePBX → Connectivity → Firewall:**
1. Pestaña **Interfaces**: las dos interfaces (`enp0s3` y `enp0s8`) en zona **"Internet (Default Firewall)"**.
   > ⚠️ Si queda como *Trusted (Excluded from Firewall)*, el firewall **no filtra nada**. Es el error más común.
2. Pestaña **Networks**:
   | Red | Zona |
   |---|---|
   | 172.16.10.0/24 (GESTION) | **Trusted** |
   | 10.0.2.2/32 (puerto interno de gestión, laptop host) | **Trusted** |
   | 172.16.20.0/24 (VOZ) | Local |
   | 172.16.30.0/24 (ADMIN) | Local |
   | 100.64.0.0/10 (Tailscale, E1) | Local |
3. Pestaña **Services**:
   | Servicio | Zonas permitidas |
   |---|---|
   | Admin (interfaz web) | **Solo Trusted** |
   | SSH | **Solo Trusted** |
   | SIP (chan_pjsip) | Local (y Trusted) |
   | UCP | Ninguna (no se usa) |
   | Provisioning / REST / WebRTC | Ninguna |
4. **Responsive Firewall**: activado, con *SIP Protocol (pjsip)* en **Disabled**. Así el SIP que llega de redes no confiables se rechaza siempre; los teléfonos entran solo por redes Local (verificado el 17/10).
   > **Orden recomendado:** agregar primero `10.0.2.2/32` como Trusted y después activar el firewall. Así no se pierde el acceso desde la laptop host. La misma regla sirve en casa (modo NAT) y en la integración.
5. Interfaz `tailscale0` (cuando exista, E1): zona **Local**.

- [ ] Captura de cada pestaña del firewall.

### 1.3 Protección contra intentos repetidos y escaneo
- [x] **Connectivity → Firewall → Intrusion Detection**: habilitado (fail2ban). *(17/10: la pestaña no existe en esta versión. Fail2ban está activo por consola, ver `CONFIG.md`, Paso 10)*
  - Ban time: 1800 s · Max retry: 5 · Find time: 600 s.
  - Whitelist: 172.16.10.0/24 y 10.0.2.2 (para que TI no se bloquee a sí mismo).
- [x] Verificar el servicio: `fail2ban-client status` (en la consola de la PBX). *(hecho 17/10)*
- [x] **Asterisk SIP Settings**: *Allow SIP Guests = No*, *Allow Anonymous Inbound SIP Calls = No* (archivo 03). *(hecho 17/10)*

### 1.4 SSH de la PBX
Editar `/etc/ssh/sshd_config`:
```
PermitRootLogin prohibit-password
PasswordAuthentication yes      # o "no" si usan llaves SSH
MaxAuthTries 3
```
```bash
systemctl restart ssh
```

### 1.5 Actualizaciones
- [ ] Router: RouterOS y firmware en la versión estable más reciente (archivo 02).
- [ ] Debian: `apt update && apt -y upgrade` (anotar fecha).
- [ ] FreePBX: Module Admin → Upgrade all (anotar fecha).
- [ ] Registrar en el informe las versiones finales de todo.

### 1.6 Respaldos
- [ ] Router: `/export` + `/system backup save` (archivo 02, paso 5).
- [x] FreePBX: Backup & Restore programado diario + copia descargada (archivo 03, paso 9). *(hecho 17/10)*
- [ ] VM completa exportada a `.ova` (respaldo para la demostración).
- [ ] **Prueba de restauración**: restaurar el respaldo de FreePBX en una copia de la VM y comprobar que las extensiones aparecen (evidencia de que el respaldo sirve).

### 1.7 Prevención de fraude telefónico (para E3)
- [ ] La troncal SIP solo se usa por la ruta de salida con prefijo **9**.
- [ ] Troncal con **Maximum Channels = 2**.
- [ ] Sin rutas de salida a números internacionales o de tarificación especial.
- [ ] La cuenta sip2sip es gratuita y **sin saldo**: no puede generar cargos.

---

## 2. Pruebas de seguridad básicas (documentar cada una)

| # | Prueba | Desde | Comando / acción | Resultado esperado |
|---|---|---|---|---|
| S1 | Descubrimiento desde invitados | Laptop en ether5 (VLAN 40) | `nmap -sn 172.16.20.0/24` y `172.16.30.0/24` | 0 hosts encontrados |
| S2 | Puertos de la PBX desde ADMIN | Laptop ADMIN | `nmap -Pn -p 22,80,443 172.16.20.10` | Todos *filtered* |
| S3 | SIP desde ADMIN | Laptop ADMIN | `nmap -Pn -sU -p 5060 172.16.20.10` | *open* o *open\|filtered* (permitido) |
| S4 | Administración web desde VOZ | Celular en CMH-Voz | Abrir `http://172.16.20.10` | No abre (lo bloquea el firewall de FreePBX) |
| S5 | Fuerza bruta SIP | Laptop ADMIN | Configurar un softphone con contraseña **incorrecta** y forzar 6 registros | La IP aparece **bloqueada** en Intrusion Detection; después se desbloquea |
| S6 | Router desde ADMIN | Laptop ADMIN | `nmap -Pn -p 21,22,23,80,8291 172.16.30.1` | Todos *filtered* |
| S7 | Router desde internet | Celular con datos móviles | Escanear la IP pública (si hay IP pública directa) o documentar que no se publica ningún puerto | Sin servicios expuestos |
| S8 | Auto-priorización de invitados | Laptop en VLAN 40 | Navegar o hacer un speedtest y revisar `/ip firewall mangle print stats` en el router | El contador de la regla "QoS: invitados DSCP=0" sube: todo lo de invitados se re-marca a 0 (frontera de confianza) |
| S9 | Puerto interno de gestión desde la red | Laptop GESTION o ADMIN | `nmap -Pn -p 2222,18080 172.16.20.20` | Todos *closed* o *filtered*: los reenvíos solo escuchan en 127.0.0.1 de la laptop host |

Para S5, revisar después:
```bash
fail2ban-client status
fail2ban-client set asterisk unbanip 172.16.30.1xx
```
(El nombre exacto de la *jail* aparece en `fail2ban-client status`.)

---

## 3. Análisis de riesgos (tabla para el informe)

| # | Riesgo | Probabilidad | Impacto | Mitigación aplicada |
|---|---|---|---|---|
| R1 | Acceso no autorizado a la administración de la PBX | Media | Alto | Web solo desde GESTION (router + firewall de FreePBX), usuario no predeterminado |
| R2 | Fuerza bruta de credenciales SIP | Alta | Alto | Secrets aleatorios, fail2ban, Responsive Firewall, sin invitados SIP |
| R3 | Fraude telefónico por la troncal | Media | Alto (costos reales) | Prefijo controlado, máx. 2 canales, cuenta sin saldo, sin rutas internacionales |
| R4 | Visitas acceden a la red interna | Media | Alto | VLAN 40 aislada por ACL, aislamiento de clientes Wi-Fi |
| R5 | Saturación de la red degrada la voz | Alta | Medio | QoS con prioridad EF y límite de invitados |
| R6 | Interceptación del audio en la LAN | Baja | Medio | Segmentación por VLAN; recomendación futura: SRTP/TLS |
| R7 | Pérdida de configuración | Media | Alto | Respaldos diarios del router y la PBX + prueba de restauración |
| R8 | Acceso remoto (E1) comprometido | Baja | Alto | Tailscale con 2FA, ACL de Tailscale solo SIP/RTP, firewall de FreePBX |
| R9 | Exposición de credenciales en documentos | Media | Alto | Gestor de contraseñas, capturas con datos tapados, `/export` sin datos sensibles |
| R10 | Uso indebido del puerto interno de gestión de la VM | Baja | Alto | Reenvíos solo en 127.0.0.1 (ningún equipo de la red llega), sin gateway en esa interfaz, solo `10.0.2.2/32` es Trusted, laptop host con contraseña y bloqueo de pantalla. Se puede desconectar en caliente: `VBoxManage controlvm CMH-FreePBX setlinkstate2 off` |

**Recomendaciones al cliente (sección 12 del informe):** SRTP/TLS para cifrar la voz, contraseñas rotadas cada 6 meses, monitoreo de los registros, UPS para el router y el servidor.

---

## Lista de verificación final (Seguridad)
- [ ] §1.1 a §1.7 completos
- [ ] Pruebas S1–S9 con capturas
- [ ] Tabla de riesgos en el informe
- [ ] Revisión final: ninguna captura ni anexo contiene contraseñas
