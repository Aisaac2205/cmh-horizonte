# Plan de ejecución: Proyecto Final PF-TEL-001-2026
**Centro Médico Horizonte, S.A.: PBX IP con VLAN, QoS y acceso seguro**

> Decisiones tomadas por el grupo
> - Red: **MikroTik RB4011iGS+5HacQ2HnD-IN** (router, switch, Wi-Fi, firewall y QoS en un solo equipo).
> - PBX: **FreePBX 17 (Asterisk)** en una máquina virtual, en modalidad **Stand-alone (local)**.
> - Extras: **E1** (Tailscale), **E3** (troncal sip2sip) y **E4** (funciones avanzadas). **E2 (SDN) no se realiza.**
> - Nota máxima posible: **100 base + 17 extra = 117 puntos**.
> - Administración de la PBX: desde la VLAN de Gestión y desde un **puerto interno de gestión** de la VM, visible solo en la laptop anfitriona (archivo 03, paso 1, y archivo 07).
> - Entrega: **miércoles 28 de octubre de 2026, 23:30, en Canvas** (carga a cargo del coordinador).

---

## 1. Archivos de este plan

| # | Archivo | Responsable principal | Criterio que cubre |
|---|---|---|---|
| 00 | `00_INDICE_Y_CRONOGRAMA.md` (este archivo) | Coordinador | G, H |
| 01 | [01_DISENO_DE_LA_SOLUCION.md](01_DISENO_DE_LA_SOLUCION.md) | Documentación + Red | A, B |
| 02 | [02_RED_MIKROTIK_RB4011.md](02_RED_MIKROTIK_RB4011.md) | Red y VLAN | B |
| 03 | [03_PBX_FREEPBX_INSTALACION.md](03_PBX_FREEPBX_INSTALACION.md) | Telefonía (PBX) | C |
| 04 | [04_PBX_FUNCIONALIDADES.md](04_PBX_FUNCIONALIDADES.md) | Telefonía / Funcionalidades | D |
| 05 | [05_TERMINALES_Y_GUIA_USUARIO.md](05_TERMINALES_Y_GUIA_USUARIO.md) | Terminales y UX | E, RN-06 |
| 06 | [06_QOS_Y_MEDICIONES.md](06_QOS_Y_MEDICIONES.md) | QoS y mediciones | F |
| 07 | [07_SEGURIDAD.md](07_SEGURIDAD.md) | Seguridad | C, §5.8 |
| 08 | [08_EXTRAS_E1_E3_E4.md](08_EXTRAS_E1_E3_E4.md) | Componentes extra | E1, E3, E4 |
| 09 | [09_PRUEBAS_Y_TRAZABILIDAD.md](09_PRUEBAS_Y_TRAZABILIDAD.md) | Documentación y calidad | D, G |
| 10 | [10_DOCUMENTACION_Y_PRESENTACION.md](10_DOCUMENTACION_Y_PRESENTACION.md) | Documentación + Coordinador | G, H |

**Bitácora global y guía de configuración:** `..\CONFIG.md` (en la carpeta de arriba) tiene todo lo hecho: dónde quedó cada cosa, el estado frente al PDF y el paso a paso con comandos.

**Cómo usar el plan:** cada archivo trae casillas `- [ ]`. Márquenlas al terminar cada paso y guarden una captura **con fecha y hora visibles** en la carpeta de evidencias (ver archivo 10).

---

## 2. Arquitectura en una imagen

```
                         INTERNET
                            │
                     (router de casa / U)
                            │
                        ether1 (WAN, DHCP, NAT)
              ┌─────────────┴─────────────────────────────┐
              │           MikroTik RB4011 (Wi-Fi)          │
              │  bridge br-lan con filtrado de VLAN        │
              │  firewall/ACL · DHCP · DNS · QoS (colas)   │
              └─┬──────┬──────┬──────┬──────┬──────┬──────┬┘
          ether2│ ether3│ ether4│ ether5│ ether6│ ether7│ ether10 (rescate 192.168.88.1)
         VLAN 20│VLAN 10│VLAN 30│VLAN 30│VLAN 40│VLAN 50│
           Voz  │Gestión│ Admin │ Admin │Invit. │Médicos│
                │       │       │       │       │       │
   Laptop host  │ Laptop│  PC / │Laptop │Laptop │(opc.) │
   ├ VM FreePBX │  TI   │ laptop│(iperf)│prueba │       │
   │ 192.168.20.10       softph.                         
   ├ iperf3 srv 192.168.20.20
   └ Puerto interno de gestión de la VM (NAT de VirtualBox, solo 127.0.0.1 de la laptop host)

   Wi-Fi 2.4 GHz: CMH-Admin (V30) · CMH-Voz (V20) · CMH-Invitados (V40)
   Wi-Fi 5 GHz  : CMH-Voz-5G (V20) · CMH-Admin-5G (V30)

   E1: celular con datos móviles ──Tailscale──► VM FreePBX (100.x.y.z)
   E3: FreePBX ──troncal SIP──► sip2sip.info
```

---

## 3. Roles (8 integrantes)

El grupo tiene 8 integrantes, así que Telefonía y Funcionalidades se combinan en un solo rol (§7.2 permite combinar roles en grupos de menos de 9).

| # | Rol | Nombre | Archivos a cargo | Respaldo de |
|---|---|---|---|---|
| 1 | Coordinador | | 00, 10 (carga) | 8 |
| 2 | Red y VLAN | | 01 (red), 02 | 6 |
| 3 | Telefonía (PBX) y funcionalidades | | 03, 04 | 4 |
| 4 | Terminales y experiencia de usuario | | 05 | 3 |
| 5 | QoS y mediciones | | 06 | 2 |
| 6 | Seguridad | | 07 | 2 |
| 7 | Componentes extra | | 08 | 3 |
| 8 | Documentación y calidad | | 01 (investigación), 09, 10 | 1 |

> **Regla del grupo:** cada integrante debe poder explicar **toda** la solución (§7.2 y §11). Cada quien lee los 11 archivos al menos una vez; el detalle de su rol lo domina.

---

## 4. Trabajo en paralelo (para ahorrar tiempo)

Casi todo se puede adelantar **sin tener el router configurado**. Los únicos momentos donde se necesita a todo el equipo junto son las **dos sesiones de integración**.

### 4.1 Lo que cada rol puede adelantar YA (antes de la integración)

| Rol | Trabajo independiente (en su casa) | Necesita |
|---|---|---|
| Red y VLAN | Leer el archivo 02, preparar los scripts con contraseñas propias, practicar en el RB4011 con el puerto de rescate | RB4011 + laptop + cable |
| Telefonía | Instalar la VM de FreePBX en su laptop (en la red de su casa), actualizar módulos, crear extensiones | Laptop de 16 GB |
| Funcionalidades | Grabar los audios del IVR, configurar IVR, buzones, espera y transferencias **en la misma VM** | Acceso a la VM |
| Terminales | Instalar MicroSIP, Linphone y Zoiper; probar registrándose a la VM en la red de su casa; redactar la guía de usuario | Celular y laptop |
| QoS | Instalar iperf3 y Wireshark, preparar la hoja de mediciones, practicar `iperf3` entre dos PC de su casa | 2 equipos |
| Seguridad | Preparar la lista de verificación, practicar nmap en su red, redactar el análisis de riesgos | Laptop |
| Extras | Crear la cuenta sip2sip, la cuenta de Tailscale (con 2FA), la cuenta Gmail del proyecto con contraseña de aplicación, buscar música libre de derechos | Internet |
| Documentación | Plantilla del informe, investigación de alternativas (criterio A), diagramas en draw.io, bitácora | — |
| Coordinador | Cronograma, grupo de chat, carpeta compartida (Drive), revisar avances diarios | — |

### 4.2 Dependencias (qué espera a qué)

```
Diseño (01) ──► Scripts del router (02) ──┐
                                          ├──► INTEGRACIÓN 1 ──► Funcionalidades en red real (04)
VM FreePBX (03) ──► Extensiones (03) ─────┘          │            Terminales entre VLAN (05)
                                                     │            Seguridad (07)
                                                     ▼
                                           INTEGRACIÓN 2 ──► QoS (06) ──► Pruebas (09) ──► Informe (10)
                                                     ▲
                       Cuentas extras (08) ──────────┘
```

### 4.3 Consejo clave: **una sola PBX "oficial"**
- El responsable de Telefonía instala la VM. Cuando ya tenga las extensiones creadas, **exporta la VM (`.ova`)** y la comparte (Drive) para que Funcionalidades, Terminales y Extras **practiquen en copias**.
- Los cambios **definitivos** se hacen solo en la VM oficial (o se pasan con *Backup & Restore* de FreePBX). Así no se pierden configuraciones.

---

## 5. Cronograma (15 al 28 de octubre)

> Si el RB4011 todavía no está con el grupo el sábado 17, la Integración 1 pasa al primer día en que llegue y las fases siguientes se corren igual. La entrega del miércoles 28 no se mueve, así que la Integración 2 no debe pasar del jueves 22.

| Fecha | Fase | Qué se hace | Quién | Entregable del día |
|---|---|---|---|---|
| **Jue 15** | 0. Arranque | Asignar roles, crear carpeta compartida y bitácora, leer el plan | Todos | Roles en tabla §3 |
| **Jue 15 – Vie 16** | 1. Preparación en paralelo | Ver tabla §4.1 | Cada rol | VM FreePBX funcionando; scripts listos; cuentas creadas |
| **Sáb 17** | **INTEGRACIÓN 1** (presencial, ~4 h) | Router configurado (scripts 1 y 2), PBX a 192.168.20.10, softphones registrados en distintas VLAN, primeras llamadas | Todos | Llamadas entre VLAN funcionando |
| **Dom 18 – Mar 20** | 2. Funciones y extras | IVR, buzón, transferencias, seguridad, E1, E3, E4 | Roles 3, 4, 5, 7, 8 | Funciones demostrables |
| **Mié 21** | **INTEGRACIÓN 2** (presencial, ~4 h) | Script 3 (QoS), mediciones con y sin QoS, prueba E1 con datos móviles, pruebas de seguridad | Todos | Tabla de mediciones completa |
| **Jue 22 – Vie 23** | 3. Pruebas y evidencias | Ejecutar la matriz de pruebas completa, capturas, respaldos finales. **Congelar la configuración el viernes 23** | Roles 9 + todos | Matriz de pruebas 100 % |
| **Sáb 24 – Lun 26** | 4. Informe | Redacción del informe, guía rápida, anexos, video de respaldo | Rol 9 + todos | Borrador completo del informe |
| **Mar 27** | 5. Ensayo | Ensayo general de la demostración de 20 min, revisión final del PDF | Todos | PDF final + ZIP de anexos |
| **Mié 28** | 6. Entrega | **Carga en Canvas antes de las 20:00** (límite real: 23:30) | Coordinador | Comprobante de carga |

---

## 6. Lista de compras y recursos

| Recurso | Cantidad | Estado |
|---|---|---|
| MikroTik RB4011iGS+5HacQ2HnD-IN | 1 | ✅ Disponible |
| Cables UTP Cat5e/Cat6 (1–3 m) | 6 | [ ] |
| Laptop host (16 GB RAM, puerto Ethernet) para la VM FreePBX | 1 | [ ] |
| Laptop de TI (VLAN Gestión) | 1 | [ ] |
| Laptops/PC con softphone (VLAN Admin) | 2–3 | [ ] |
| Celulares Android/iOS con Linphone o Zoiper | 3–4 | [ ] |
| Celular con datos móviles (para E1) | 1 | [ ] |
| Audífonos con micrófono | 2–3 | [ ] |
| Adaptador USB-Ethernet (si alguna laptop no tiene puerto) | 0–2 | [ ] |
| Regleta eléctrica | 1 | [ ] |

**Software (todo gratuito):** VirtualBox 7, Debian 12, FreePBX 17, Winbox, MicroSIP, Linphone, Zoiper, Wireshark, iperf3, nmap, draw.io, Tailscale.

---

## 7. Definición de "terminado" por área

| Área | Está terminada cuando… |
|---|---|
| Red | Cada puerto y SSID entrega IP de su VLAN; la matriz de ACL se cumple; existe el `/export` sin contraseñas |
| PBX | FreePBX en 192.168.20.10, actualizada, administración solo desde Gestión y el puerto interno de gestión, ≥ 8 extensiones, CDR activo, respaldo descargado |
| Funcionalidades | Las 5 funciones (4 dígitos, espera, transferencia ciega y atendida, buzón, IVR) probadas desde laptop **y** móvil |
| Terminales | ≥ 4 extensiones registradas a la vez, llamadas escritorio↔móvil, escritorio↔escritorio, móvil↔móvil y entre VLAN; guía rápida lista |
| QoS | Tabla con latencia, jitter y pérdida en 3 escenarios (base, sin QoS, con QoS), con la pérdida medida **en la PBX**, + capturas de Wireshark con DSCP EF/CS3 |
| Seguridad | Lista de §5.8 completa + 5 pruebas de seguridad documentadas |
| Extras | E1, E3 y las 5 funciones de E4 de la §6.4 (incluida la grabación de llamadas) demostradas con evidencia y análisis de riesgos |
| Documentación | Informe con las 13 secciones, matriz de pruebas, trazabilidad RN-01..RN-10, guía, respaldos y bitácora |

---

## 8. Reglas de oro
1. **Capturas desde el día 1**, con el reloj de Windows visible y las contraseñas tapadas.
2. **Nada de contraseñas reales en el informe ni en los respaldos.** Usen un gestor de contraseñas compartido (por ejemplo Bitwarden) para el grupo.
3. **Probar en orden:** red → PBX → terminales → QoS → extras (§13 del enunciado).
4. **Guardar respaldo después de cada sesión** (router: `/export`; FreePBX: Backup & Restore; VM: exportar `.ova`).
5. Toda duda de alcance se consulta **por el canal oficial del curso** (§12).
