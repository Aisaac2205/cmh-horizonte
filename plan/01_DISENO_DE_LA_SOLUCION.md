# 01 · Diseño de la solución
**Responsables:** Documentación (investigación) + Red y VLAN (diseño técnico)
**Criterios:** A (8 pts) y B (17 pts) · Secciones 4 y 5 del informe

Este archivo es la **fuente única de datos** del proyecto: todos los demás archivos usan estas IP, VLAN y números. Si algo cambia, se cambia **aquí primero** y se avisa al grupo.

---

## 1. Investigación y selección tecnológica (Criterio A)

### 1.1 Comparación de modalidades de despliegue (§5.2)

Completen la tabla con fuentes citadas (APA). Los costos son **referenciales; verifíquenlos** en las páginas oficiales con la fecha de consulta.

| Criterio | A. Stand-alone (local) | B. Nube pública | C. Híbrida | D. Hospedada comercial (solo análisis) |
|---|---|---|---|---|
| Rendimiento / latencia interna | Muy baja (LAN) | Depende de internet | Mixta | Depende del proveedor |
| Seguridad | Sin exposición directa a internet | Expuesta: requiere endurecimiento fuerte | Exposición parcial | Delegada al proveedor |
| Integración con VLAN y QoS | **Total** (la QoS se mide en la LAN) | Limitada (el audio viaja por internet) | Parcial | Ninguna |
| Licenciamiento | FreePBX: gratuito (GPL) | Igual + costo de instancia | Igual + troncal | Suscripción mensual por usuario |
| Costo recurrente | Q0 (energía) | Mensual por VM + IP pública | Mensual por troncal | Mensual por extensión |
| Mantenimiento | Del equipo de TI del cliente | Del cliente | Del cliente | Del proveedor |
| Acceso remoto | Requiere VPN (resuelto con E1) | Nativo | Nativo | Nativo |
| **Decisión** | ✅ **Seleccionada** | Descartada | Descartada | Referencia |

**Justificación sugerida (redáctenla con sus palabras):** el requerimiento central del cliente (RN-03 y RN-04) es separar y priorizar la voz **dentro de su red**. La modalidad local permite medir la QoS de forma real, no tiene costos recurrentes y mantiene la PBX sin exposición directa a internet. La necesidad de acceso remoto (RN-08) se cubre con una VPN de usuario (E1) sin abrir puertos.

### 1.2 Comparación de plataformas PBX

| Criterio | **FreePBX 17 (Asterisk)** | Issabel | FreeSWITCH + FusionPBX | Wazo | 3CX |
|---|---|---|---|---|---|
| Licencia | GPL, gratuita | GPL, gratuita | MPL / gratuita | GPL | Comercial (planes gratuitos limitados, verificar) |
| Interfaz web | Completa | Completa | Completa | Completa | Muy pulida |
| Comunidad / documentación | **La más amplia** | Media (LatAm) | Media | Baja | Alta |
| IVR, buzón, colas, condiciones horarias | ✅ módulos incluidos | ✅ | ✅ | ✅ | ✅ |
| Firewall y anti-fuerza-bruta integrados | ✅ Firewall + Intrusion Detection | ✅ fail2ban | Manual | Manual | ✅ |
| **Decisión** | ✅ **Seleccionada** | Alternativa | Descartada (curva) | Descartada | Descartada (licencia) |

### 1.3 Comparación de equipos de red (resumen de lo investigado)

| Opción | Costo aprox. | VLAN | QoS medible | Wi-Fi multi-SSID | SDN | Decisión |
|---|---|---|---|---|---|---|
| MikroTik RB4011 Wi-Fi | Disponible en el grupo | ✅ | ✅ colas por prioridad | ✅ 2.4 + 5 GHz | ❌ | Primera elección, cambiado el 19/10 |
| **MikroTik RB750Gr3 (hEX) + AP Mercusys MW325R** | Ya los tiene el grupo | ✅ (filtrado por hardware en RouterOS v7) | ✅ colas por prioridad | Un SSID de 2.4 GHz, sin VLAN | ❌ | ✅ **Seleccionado** |
| MikroTik hAP ac lite | Q588 (Kemik) | ✅ | ✅ | ✅ | ❌ | Alternativa económica |
| Kit TP-Link Omada (ER605 + SG2008P + EAP) | ≈ Q1,721 | ✅ | Parcial | ✅ | ✅ | Descartado (costo; E2 no se hará) |
| Router virtual (OPNsense) + switch + AP | ≈ Q300–600 | ✅ | ✅ | Depende | ❌ | Descartado (más puntos de falla) |

---

## 2. Plan de VLAN y direccionamiento (Criterio B)

| VLAN | Nombre | Propósito | Red | Gateway | Rango DHCP | Reservas / estáticas |
|---|---|---|---|---|---|---|
| 10 | GESTION | Equipos de red, administración de la PBX y del router (solo TI) | 192.168.10.0/24 | 192.168.10.1 | .100 – .199 | .10 Laptop de TI (reserva DHCP opcional, script 1) |
| 20 | VOZ | PBX, teléfonos y celulares de voz | 192.168.20.0/24 | 192.168.20.1 | .100 – .199 | .2 AP MW325R (fija) · **.10 FreePBX** (reserva DHCP) · .20 Laptop host / servidor iperf3 (reserva DHCP) |
| 30 | ADMIN | PC y laptops del personal | 192.168.30.0/24 | 192.168.30.1 | .100 – .199 | — |
| 40 | INVITADOS | Internet para visitas | 192.168.40.0/24 | 192.168.40.1 | .100 – .199 | — |
| — | GESTION-VM (interna) | Puerto interno de gestión de la VM, solo alcanzable desde la laptop host (adaptador 2, NAT de VirtualBox) | 10.0.2.0/24 | sin gateway | sin DHCP | .15 VM FreePBX · .2 laptop host (NAT de VirtualBox) |

**Escalabilidad:** cada /24 admite 253 hosts; el cliente tiene 31 colaboradores. El rango DHCP (100 IP) cubre el total con holgura y deja .2–.99 para reservas.

### 2.1 Asignación de puertos del RB750Gr3 (hEX)

| Puerto | Modo | VLAN | Conectado a |
|---|---|---|---|
| ether1 | WAN (ruteado) | — | Internet (router de casa o de la U) |
| ether2 | Acceso | 20 VOZ | AP Mercusys MW325R en modo AP. La laptop host con la VM FreePBX va en un puerto LAN del AP |
| ether3 | Acceso | 10 GESTION | Laptop de TI |
| ether4 | Acceso | 30 ADMIN | Laptop con softphone (y cliente iperf3 en las pruebas de QoS) |
| ether5 | Acceso | 40 INVITADOS | Laptop de prueba |

La VLAN 50 (Médicos, opcional) y el puerto de rescate del RB4011 se eliminan. El hEX tiene 5 puertos y el PDF pide cuatro VLAN como mínimo. Detalle y limitaciones en el archivo 02.

### 2.2 SSID

| SSID | Banda | VLAN | Seguridad | Uso |
|---|---|---|---|---|
| CMH-Voz | 2.4 GHz (AP MW325R) | 20 | WPA2-PSK (AES), sin WPS | Celulares con softphone |

El MW325R no maneja VLAN, así que da un solo SSID. Administrativa e Invitados se conectan por cable (ether4 y ether5).

---

## 3. Matriz de comunicación entre VLAN (Criterio B)

Lectura: fila = **origen**, columna = **destino**. Las reglas exactas están en el script 2 del archivo 02.

| Origen ↓ / Destino → | GESTION (10) | VOZ (20) | ADMIN (30) | INVITADOS (40) | Router (input) | Internet |
|---|---|---|---|---|---|---|
| **GESTION (10)** | ✅ | ✅ todo (web PBX, SSH) | ✅ | ✅ | ✅ Winbox/SSH | ✅ |
| **VOZ (20)** | ❌ (solo la PBX responde a softphones) | ✅ (mismo segmento) | ❌ (solo la PBX: SIP/RTP UDP) | ❌ | DNS, DHCP, ICMP | ✅ |
| **ADMIN (30)** | ❌ | ⚠️ **solo hacia 192.168.20.10: UDP 5060 y 10000–20000** | ✅ | ❌ | DNS, DHCP, ICMP | ✅ |
| **INVITADOS (40)** | ❌ | ❌ | ❌ | ❌ (aislamiento) | DNS, DHCP | ✅ (5 Mbps) |
| **Internet** | ❌ | ❌ (salvo tráfico de retorno) | ❌ | ❌ | ❌ | — |

Notas para el informe:
- La administración web de FreePBX la bloquean **dos capas**: el router (ADMIN solo llega a SIP/RTP) y el firewall de FreePBX (web solo desde 192.168.10.0/24). La segunda capa protege incluso contra equipos de la misma VLAN 20.
- **Puerto interno de gestión (fuera de banda).** La VM tiene un segundo adaptador en NAT de VirtualBox, con reenvío solo en `127.0.0.1` de la laptop host (web 18080 y SSH 2222). Ningún equipo de la red llega a él. Permite entrar a administrar la PBX aunque la red falle. En el firewall de FreePBX solo se confía en `10.0.2.2/32` (archivo 07).
- Reglas de prueba **deshabilitadas por defecto**: ADMIN → servidor iperf3 (192.168.20.20, puerto 5201) solo durante la prueba de QoS.

---

## 4. Plan de numeración de 4 dígitos (Criterio D)

| Rango / Número | Uso | Crecimiento |
|---|---|---|
| **1000** | Operadora (Recepción) | — |
| 1001 – 1099 | Recepción y Admisión (4 colaboradores) | 99 extensiones |
| 2001 – 2099 | Consulta Externa (10) | 99 |
| 3001 – 3099 | Enfermería y Emergencias (8) | 99 |
| 4001 – 4099 | Administración y Contabilidad (6) | 99 |
| 5001 – 5099 | Gerencia y TI (3) | 99 |
| 6000 – 6999 | Reservado para crecimiento (nuevas áreas) | — |
| **7000** | IVR principal (con condiciones horarias) | — |
| **8000** | Grupo de timbrado Recepción (E4) | 8001–8009 |
| **8010** | Cola Consulta Externa (E4) | 8011–8019 |
| ***97** | Consultar mi buzón de voz | código de servicio |
| ***98** | Consultar cualquier buzón | código de servicio |
| ***43** | Prueba de eco (usada en mediciones de QoS) | código de servicio |
| **9** + número | Prefijo de llamadas externas por la troncal SIP (E3) | — |

Sin traslapes: ningún rango empieza con 9, y los códigos de servicio usan `*`.

### 4.1 Extensiones a implementar (muestra representativa: 5 áreas, 9 extensiones)

| Ext. | Nombre | Área | Terminal | Red | Buzón |
|---|---|---|---|---|---|
| 1000 | Operadora Recepcion | Recepción | Laptop host (MicroSIP) | VOZ, puerto LAN del AP | ✅ |
| 1001 | Recepcion Movil | Recepción | Celular (Linphone) | Wi-Fi CMH-Voz | — |
| 2001 | Clinica 1 | Consulta Externa | Celular | Wi-Fi CMH-Voz | ✅ |
| 2002 | Clinica 2 | Consulta Externa | Celular | Wi-Fi CMH-Voz | — |
| 3001 | Enfermeria | Enfermería | Celular | Wi-Fi CMH-Voz | ✅ |
| 3002 | Emergencias | Emergencias | Celular | Wi-Fi CMH-Voz | — |
| 4001 | Administracion | Administración | Laptop con softphone | ADMIN, ether4 | ✅ |
| 5001 | TI Gerencia | Gerencia y TI | Laptop de TI con softphone | GESTION, ether3 | — |
| 5002 | TI Remoto | Gerencia y TI | Celular con datos móviles | Tailscale (E1) | — |

---

## 5. Códecs y dimensionamiento de ancho de banda

### 5.1 Códecs seleccionados

| Prioridad | Códec | Tasa | Motivo |
|---|---|---|---|
| 1 | G.711 µ-law / a-law | 64 kbps | Calidad de referencia, sin transcodificación, mínimo uso de CPU; en LAN el ancho de banda sobra |
| 2 | G.722 | 64 kbps | Banda ancha (HD voice) con el mismo ancho de banda que G.711 |
| 3 | Opus (si el módulo está disponible) | 6–64 kbps variable | Para móviles por internet (E1), resistente a pérdida |

### 5.2 Cálculo por llamada (G.711, paquetización de 20 ms)

| Capa | Bytes por paquete |
|---|---|
| Carga de voz (64 kbps × 20 ms) | 160 |
| RTP | 12 |
| UDP | 8 |
| IP | 20 |
| **Subtotal IP** | **200 B → 200 × 8 × 50 pps = 80 kbps** |
| Ethernet (14 + 4 FCS) | 18 → 218 B → **87.2 kbps por sentido** |
| (+ 802.1Q en enlaces troncales: 4 B) | 222 B → 88.8 kbps |

### 5.3 Dimensionamiento para el cliente (31 colaboradores)

| Supuesto | Valor |
|---|---|
| Llamadas simultáneas en hora pico (≈ 30 % de usuarios) | 10 |
| Ancho de banda de voz LAN | 10 × 87.2 ≈ **0.87 Mbps por sentido** |
| Llamadas externas simultáneas (troncal) | 4 → ≈ **0.35 Mbps por sentido en la WAN** |
| Reserva para voz en la política de QoS (cola EF) | 512 kbps garantizados en el enlace de prueba de 2 Mbps (≈ 5 llamadas) |

(Opcional: justificar las 10 llamadas con Erlang B: con 31 usuarios a ~0.15 Erl cada uno, ≈ 4.65 Erl; 10 canales dan una probabilidad de bloqueo < 1 %.)

---

## 6. Política de QoS (resumen; el detalle está en el archivo 06)

| Clase | Identificación (en el router) | DSCP | Prioridad en cola | Garantía |
|---|---|---|---|---|
| Medios de voz | UDP 10000–20000 hacia o desde 192.168.20.10 | **EF (46)** | 1 (máxima) | 512 kbps |
| Señalización | UDP 5060 hacia o desde 192.168.20.10 | **CS3 (24)** | 2 | 64 kbps |
| Datos críticos | Tráfico de GESTION | AF21 (18) | 5 | — |
| Mejor esfuerzo | Todo lo demás (ADMIN) | 0 | 8 | — |
| Invitados | VLAN 40 (DSCP re-escrito a 0) | 0 | 8 + límite de 5 Mbps | — |

**Por qué CS3 y no CS5 para la señalización:** RFC 4594 recomienda CS5 para señalización, pero muchas guías de fabricantes (Cisco) usan CS3 y Asterisk usa `cs3` por defecto en `tos` para SIP. Se adopta CS3 por compatibilidad con Asterisk y se documenta la diferencia.

**Frontera de confianza:** el router **re-marca** el DSCP según IP y puerto, sin confiar en lo que marquen los dispositivos. Así un invitado no puede marcar su tráfico como EF para ganar prioridad, y los softphones de otras VLAN (que muchas veces no marcan) quedan clasificados correctamente.

---

## 7. Diagramas para el informe
- [ ] **Diagrama lógico** (draw.io): VLAN, redes, gateway, PBX, flujos permitidos.
- [ ] **Diagrama físico**: puertos del hEX, AP, cables, equipos y SSID (usar la tabla 2.1).
- [ ] **Diagrama de flujo de llamada**: entrada → condición horaria → IVR → grupo/cola/extensión → buzón.
- [ ] Exportar en PNG y guardar el `.drawio` en los anexos.
