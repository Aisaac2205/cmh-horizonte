# 06 · Clasificación de tráfico, QoS y mediciones
**Responsable:** QoS y mediciones · **Apoyo:** Red y VLAN
**Criterio:** F (15 pts) · **Tiempo estimado:** 1 h de configuración + 2–3 h de mediciones
**Se aplica en la Integración 2** (requiere red, PBX y softphones funcionando).
**Se puede adelantar YA:** instalar iperf3 y Wireshark, practicar iperf3 entre dos PC de su casa y preparar la hoja de resultados.

---

## 1. Idea de la prueba (explicarla así en el informe)

1. Se crea un **cuello de botella artificial de 2 Mbps** en la salida del router hacia la VLAN de voz (y otro hacia la VLAN ADMIN para el sentido contrario).
2. Una laptop de la VLAN ADMIN hace una **llamada de voz** (prueba de eco `*43`, el audio va y vuelve por la PBX).
3. La misma laptop de la VLAN ADMIN (el hEX tiene un solo puerto ADMIN) **satura los dos sentidos** con iperf3: 20 Mbps UDP hacia 172.16.20.20 y 20 Mbps de regreso (`-R`).
4. Se mide **latencia, jitter y pérdida** en 3 escenarios: **base** (sin saturación), **saturado sin QoS** y **saturado con QoS**.
5. **La pérdida se mide en la PBX**, no en la laptop. El eco (`*43`) devuelve el audio con su propia numeración RTP. Si se pierden paquetes de ida, el flujo de vuelta llega sin huecos y Wireshark en la laptop marcaría 0 % de pérdida aunque la voz se corte. Por eso se usan `pjsip show channelstats` (columna RX) y una captura con `tcpdump` en la VM.

```
 Laptop ADMIN (4001, llamada *43) ──┐                        ┌──► VM FreePBX 172.16.20.10
                                    ├──► hEX ─────[2 Mbps]───┤
 misma laptop (iperf3 cliente) ─────┘   (cola por prioridad)  └──► Host iperf3 172.16.20.20
```
> ¿Por qué entre VLAN? El tráfico **dentro** de la misma VLAN se conmuta en el bridge y no pasa por las colas IP del router. El tráfico **entre** VLAN sí se enruta, se marca y se encola. Por eso la llamada medida sale de la VLAN ADMIN.

---

## 2. Clases de tráfico (≥ 4, requisito §5.6)

| Clase | Identificación | DSCP (marca) | Packet-mark | Prioridad | Garantía (limit-at) |
|---|---|---|---|---|---|
| 1. Medios de voz | UDP 10000–20000 desde/hacia 172.16.20.10 | **EF (46)** | `pm-ef` | **1** | 512 kbps |
| 2. Señalización | UDP 5060 desde/hacia 172.16.20.10 | **CS3 (24)** | `pm-cs3` | 2 | 64 kbps |
| 3. Datos críticos | Origen VLAN GESTION | AF21 (18) | `pm-af21` | 5 | — |
| 4. Mejor esfuerzo | Todo lo demás | 0 | `pm-be` | 8 | — |
| 5. Invitados | Origen VLAN 40 (DSCP re-escrito a 0) | 0 | `pm-guest` | 8 + **límite de 5 Mbps** | — |

Justificación de valores: EF (RFC 3246) da reenvío acelerado con baja latencia para los medios; CS3 se usa para la señalización por compatibilidad con Asterisk (RFC 4594 sugiere CS5; documentar la elección); AF21 para datos de gestión de baja latencia (RFC 4594).

---

## 3. Script 3: `03-qos.rsc`

```
# =====================================================================
# 03-qos.rsc - Clasificacion, marcado DSCP, colas por prioridad
# Marcado en chain=forward: solo trafico enrutado (entre VLAN / WAN)
# =====================================================================

/ip firewall mangle
# --- Frontera de confianza: invitados no pueden auto-priorizarse ---
add chain=forward src-address-list=net-invitados action=change-dscp new-dscp=0 passthrough=yes comment="QoS: invitados DSCP=0"

# --- Clase 1: medios de voz (RTP) -> EF ---
add chain=forward protocol=udp dst-address-list=pbx dst-port=10000-20000 action=change-dscp new-dscp=46 passthrough=yes comment="QoS: RTP hacia PBX -> EF"
add chain=forward protocol=udp src-address-list=pbx src-port=10000-20000 action=change-dscp new-dscp=46 passthrough=yes comment="QoS: RTP desde PBX -> EF"

# --- Clase 2: senalizacion (SIP) -> CS3 ---
add chain=forward protocol=udp dst-address-list=pbx dst-port=5060 action=change-dscp new-dscp=24 passthrough=yes comment="QoS: SIP hacia PBX -> CS3"
add chain=forward protocol=udp src-address-list=pbx src-port=5060 action=change-dscp new-dscp=24 passthrough=yes comment="QoS: SIP desde PBX -> CS3"

# --- Clase 3: datos criticos (GESTION) -> AF21 ---
add chain=forward src-address-list=net-gestion dscp=0 action=change-dscp new-dscp=18 passthrough=yes comment="QoS: GESTION -> AF21"

# --- Marcas de paquete para las colas ---
add chain=forward src-address-list=net-invitados action=mark-packet new-packet-mark=pm-guest passthrough=no comment="QoS: marca INVITADOS"
add chain=forward dscp=46 action=mark-packet new-packet-mark=pm-ef passthrough=no comment="QoS: marca EF"
add chain=forward dscp=24 action=mark-packet new-packet-mark=pm-cs3 passthrough=no comment="QoS: marca CS3"
add chain=forward dscp=18 action=mark-packet new-packet-mark=pm-af21 passthrough=no comment="QoS: marca AF21"
add chain=forward action=mark-packet new-packet-mark=pm-be passthrough=no comment="QoS: marca mejor esfuerzo"

# --- Colas: salida hacia VLAN VOZ (cuello de botella de 2 Mbps) ---
# queue=default (pfifo de 50 paquetes) en las colas FIFO y de mejor esfuerzo:
# con 2 Mbps, 50 paquetes de ~1470 B son ~300 ms de cola. El valor por defecto
# del queue tree (default-small, 10 paquetes) daria mucha perdida pero poca latencia.
/queue tree
add name=q-voz parent=vlan20-voz max-limit=2M comment="Enlace de prueba hacia VOZ"
add name=q-voz-ef parent=q-voz packet-mark=pm-ef priority=1 limit-at=512k max-limit=2M comment=QOS-PRIO
add name=q-voz-cs3 parent=q-voz packet-mark=pm-cs3 priority=2 limit-at=64k max-limit=2M comment=QOS-PRIO
add name=q-voz-af21 parent=q-voz packet-mark=pm-af21 priority=5 max-limit=2M comment=QOS-PRIO
add name=q-voz-be parent=q-voz packet-mark=pm-be,pm-guest priority=8 max-limit=2M queue=default comment=QOS-PRIO
add name=q-voz-fifo parent=q-voz packet-mark=pm-ef,pm-cs3,pm-af21,pm-be,pm-guest priority=8 max-limit=2M queue=default disabled=yes comment=QOS-FIFO

# --- Colas: salida hacia VLAN ADMIN (sentido contrario) ---
add name=q-admin parent=vlan30-admin max-limit=2M comment="Enlace de prueba hacia ADMIN"
add name=q-admin-ef parent=q-admin packet-mark=pm-ef priority=1 limit-at=512k max-limit=2M comment=QOS-PRIO
add name=q-admin-cs3 parent=q-admin packet-mark=pm-cs3 priority=2 limit-at=64k max-limit=2M comment=QOS-PRIO
add name=q-admin-af21 parent=q-admin packet-mark=pm-af21 priority=5 max-limit=2M comment=QOS-PRIO
add name=q-admin-be parent=q-admin packet-mark=pm-be,pm-guest priority=8 max-limit=2M queue=default comment=QOS-PRIO
add name=q-admin-fifo parent=q-admin packet-mark=pm-ef,pm-cs3,pm-af21,pm-be,pm-guest priority=8 max-limit=2M queue=default disabled=yes comment=QOS-FIFO

# --- Colas: salida a internet (proteger llamadas externas E1/E3) ---
# Ajustar max-limit al 85-90% de la subida real medida (speedtest)
add name=q-wan parent=ether1 max-limit=5M comment="Salida WAN"
add name=q-wan-ef parent=q-wan packet-mark=pm-ef priority=1 limit-at=512k max-limit=5M
add name=q-wan-cs3 parent=q-wan packet-mark=pm-cs3 priority=2 limit-at=64k max-limit=5M
add name=q-wan-af21 parent=q-wan packet-mark=pm-af21 priority=5 max-limit=5M
add name=q-wan-be parent=q-wan packet-mark=pm-be,pm-guest priority=8 max-limit=5M

# --- Invitados: limite de ancho de banda ---
/queue simple
add name=q-invitados target=172.16.40.0/24 max-limit=5M/5M comment="INVITADOS max 5 Mbps"
```

### 3.1 Interruptor "sin QoS / con QoS" (pegar en New Terminal)
**Sin QoS** (una sola cola FIFO, mismo límite de 2 Mbps):
```
/queue tree disable [find comment="QOS-PRIO"]; /queue tree enable [find comment="QOS-FIFO"]
```
**Con QoS** (colas por prioridad):
```
/queue tree disable [find comment="QOS-FIFO"]; /queue tree enable [find comment="QOS-PRIO"]
```
El marcado DSCP sigue activo en ambos casos. Lo único que cambia es si la cola respeta la prioridad, y eso es exactamente lo que se quiere comparar.

### 3.2 Verificación rápida
- [ ] `/ip firewall mangle print stats` → los contadores de "marca EF" y "marca CS3" suben durante una llamada ADMIN ↔ PBX.
- [ ] `/queue tree print stats` → `q-voz-ef` muestra bytes durante la llamada.

---

## 4. Preparación de las pruebas

| Equipo | Rol | Configuración |
|---|---|---|
| Laptop host (puerto LAN del AP, 172.16.20.20) | Servidor iperf3 | Dos servidores, uno por sentido: `iperf3 -s -p 5201` y `iperf3 -s -p 5202` en dos ventanas (permitir en el Firewall de Windows) |
| Laptop ADMIN (ether4), ext. **4001** | Llamada medida y generador de saturación | MicroSIP + Wireshark + iperf3 cliente |
| Laptop GESTION (ether3) | Control | Winbox (interruptor de QoS) + SSH a la PBX |
| Laptop host (puerto interno) | Captura en la PBX | `ssh -p 2222 cmhadmin@127.0.0.1` para `tcpdump` y `channelstats` |

1. En Winbox **habilitar** las 2 reglas `PRUEBA-QOS` del firewall:
   ```
   /ip firewall filter enable [find comment~"PRUEBA-QOS"]
   ```
2. Descargar iperf3 para Windows (iperf.fr) en la laptop host y en la laptop B. La versión de iperf.fr es antigua y no trae `--bidir`; por eso se usan dos instancias, una normal y otra con `-R`.
3. Abrir Wireshark en la **laptop A**, interfaz Ethernet, filtro de captura `udp`.

---

## 5. Procedimiento de medición (repetir 3 veces cada escenario)

### Escenario 1: BASE (sin saturación)
1. En la PBX (desde la laptop host, por el puerto interno), iniciar la captura antes de llamar:
   ```bash
   sudo tcpdump -i enp0s3 -w /tmp/qos-esc1-rep1.pcap udp portrange 10000-20000
   ```
2. Laptop A llama a **`*43`** (eco) y habla o reproduce audio continuo 60 s.
3. Durante la llamada, en otra sesión SSH a la PBX:
   ```bash
   sudo asterisk -rx "pjsip show channelstats"
   ```
   Anotar **RX Jitter, RX Loss % y RTT**. Las columnas **RX** son el audio que llega a la PBX desde la laptop, que es el que cruza la cola `q-voz`.
4. Colgar y detener `tcpdump` (Ctrl+C). Copiar la captura a la laptop host: `scp -P 2222 cmhadmin@127.0.0.1:/tmp/qos-esc1-rep1.pcap .`
5. En Wireshark, abrir esa captura: **Telefonía → RTP → Flujos RTP** → elegir el flujo **de la laptop A hacia 172.16.20.10** → **Analizar** → anotar *Max Jitter, Mean Jitter, Lost (%), Max Delta*.
6. La captura de la laptop A se usa como evidencia del **marcado DSCP** (sección 7), no para la pérdida.

### Escenario 2: SATURADO SIN QoS
1. Pegar el comando **Sin QoS** (3.1).
2. Laptop B, en dos ventanas a la vez:
   - `iperf3 -c 172.16.20.20 -p 5201 -u -b 20M -t 90` (satura hacia VOZ)
   - `iperf3 -c 172.16.20.20 -p 5202 -u -b 20M -t 90 -R` (satura hacia ADMIN)
3. Mientras corren, laptop A llama a `*43` 60 s y se mide igual que en el escenario 1 (captura en la PBX con nombre `qos-esc2-repN.pcap`).
4. Durante la prueba: captura de `/queue tree print stats` (se ve todo en `q-voz-fifo` y `q-admin-fifo` con *dropped*).

### Escenario 3: SATURADO CON QoS
1. Pegar el comando **Con QoS** (3.1).
2. Repetir exactamente el escenario 2.
3. Captura de `/queue tree print stats`: `q-voz-ef` sin descartes y `q-voz-be` con descartes.

### Al terminar
```
/ip firewall filter disable [find comment~"PRUEBA-QOS"]
```

---

## 6. Hoja de resultados (copiar al informe)

| Escenario | Repetición | Latencia (RTT/2) ms | Jitter medio ms | Jitter máx. ms | Pérdida % | Calidad percibida (1–5) | ¿Cumple? |
|---|---|---|---|---|---|---|---|
| Base | 1 | | | | | | |
| Base | 2 | | | | | | |
| Base | 3 | | | | | | |
| Sin QoS + saturación | 1 | | | | | | |
| Sin QoS + saturación | 2 | | | | | | |
| Sin QoS + saturación | 3 | | | | | | |
| Con QoS + saturación | 1 | | | | | | |
| Con QoS + saturación | 2 | | | | | | |
| Con QoS + saturación | 3 | | | | | | |
| **Meta (ITU-T G.114 / enunciado)** | — | **≤ 150** | **< 30** | — | **< 1** | ≥ 4 | — |

**Resultado esperado:** sin QoS, la cola FIFO de 2 Mbps (50 paquetes) se llena con iperf3 (unos 300 ms de cola y mucha pérdida), así que la voz se entrecorta. Con QoS, la clase EF sale primero y la voz queda dentro de las metas. Si los resultados no muestran diferencia, revisen que la llamada realmente cruce entre VLAN y que el contador `q-voz-ef` suba.

**Gráfico sugerido para el informe:** barras de jitter y pérdida por escenario (promedio de las 3 repeticiones).

---

## 7. Evidencias obligatorias
- [ ] Wireshark: paquete RTP con **DSCP = EF (46)** visible (Detalles → Internet Protocol → Differentiated Services Field).
- [ ] Wireshark: paquete SIP con **DSCP = CS3 (24)**.
- [ ] Wireshark: análisis de flujo RTP en los 3 escenarios.
- [ ] Winbox: `mangle print stats` y `queue tree print stats` durante las pruebas.
- [ ] Salida de `pjsip show channelstats` en los 3 escenarios.
- [ ] Capturas `qos-escN-repN.pcap` tomadas en la PBX y su análisis de flujo RTP (pérdida real del audio que cruza la cola).
- [ ] Prueba de invitados: speedtest desde CMH-Invitados ≈ 5 Mbps máximo.
- [ ] Tabla de resultados completa con análisis.

> **Para la captura de DSCP:** capturen en la **laptop A** (recibe RTP ya re-marcado por el router). La marca la pone el router al reenviar entre VLAN.
