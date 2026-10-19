# 09 · Matriz de pruebas y matriz de trazabilidad
**Responsable:** Documentación y calidad · **Ejecutan:** todos los roles
**Criterios:** D (las funciones se verifican "una por una en la matriz de pruebas") y G (12 pts)
**Cuándo:** se llena durante las integraciones y se completa **el jueves 22 y el viernes 23**.

**Cómo llenarla:** cada prueba lleva **Resultado obtenido**, **Estado** (✅ / ❌ / ⚠️) y el **ID de la evidencia** (nombre del archivo de captura, ver archivo 10). Si una prueba falla, se anota la causa y la corrección, y se repite.

---

## 1. Matriz de pruebas

### 1.1 Red y segmentación (criterio B)
| ID | Requisito | Procedimiento | Resultado esperado | Resultado obtenido | Estado | Evidencia |
|---|---|---|---|---|---|---|
| RED-01 | 4+ VLAN definidas | `/interface bridge vlan print` | VLAN 10, 20, 30, 40, 50 | | | |
| RED-02 | DHCP por VLAN | Conectar un equipo en cada puerto/SSID | IP del rango correcto | | | |
| RED-03 | Enrutamiento entre VLAN | Softphone ADMIN se registra en la PBX (VOZ) | Registro exitoso | | | |
| RED-04 | ACL ADMIN → PBX solo voz | `ping 192.168.20.10` desde ADMIN | Falla | | | |
| RED-05 | Invitados aislados | `nmap -sn 192.168.30.0/24` desde VLAN 40 | 0 hosts | | | |
| RED-06 | Gestión administra | Winbox y web de la PBX desde GESTION | Acceso permitido | | | |
| RED-07 | Gestión restringida | Winbox y web de la PBX desde ADMIN | Acceso denegado | | | |
| RED-08 | NAT a internet | Navegar desde cada VLAN | Navegación correcta | | | |
| RED-09 | SIP ALG desactivado | `/ip firewall service-port print` | `sip` deshabilitado | | | |
| RED-10 | Wi-Fi por VLAN | Celular en cada SSID | IP de su VLAN | | | |
| RED-11 | Registro de bloqueos | `/log print where message~"DROP-FWD"` | Intentos bloqueados registrados | | | |

### 1.2 PBX (criterio C)
| ID | Requisito | Procedimiento | Resultado esperado | Resultado obtenido | Estado | Evidencia |
|---|---|---|---|---|---|---|
| PBX-01 | Plataforma operativa | `fwconsole --version`, `asterisk -V` | Versiones documentadas | | | |
| PBX-02 | Extensiones ≥ 5 | Connectivity → Extensions | 9 extensiones con nombre descriptivo | | | |
| PBX-03 | Contraseñas robustas | Revisar los secrets (sin mostrarlos) | Aleatorios y únicos | | | |
| PBX-04 | Códecs | `pjsip show endpoint 1000` | ulaw, alaw, g722 (opus) | | | |
| PBX-05 | Registro de eventos | Reports → CDR Reports y System Logfiles | Llamadas registradas | | | |
| PBX-06 | Respaldo | Backup & Restore → Run + restauración en una copia | Respaldo restaurable | | | |

### 1.3 Funcionalidades de telefonía (criterio D)
| ID | Función | Procedimiento | Terminal | Resultado esperado | Resultado obtenido | Estado | Evidencia |
|---|---|---|---|---|---|---|---|
| FUN-01 | 4 dígitos | 1000 → 2001, 3001 → 4001, 5001 → 1001 | Laptop y móvil | Conectan entre áreas | | | |
| FUN-02 | Espera y reanudar | 1000 pone en espera a 2001 y reanuda | Laptop | Música y retorno | | | |
| FUN-03 | Espera desde móvil | 2001 pone en espera a 1000 y reanuda | Móvil | Música y retorno | | | |
| FUN-04 | Segunda llamada entrante | 3001 llama a 1000 en llamada activa | Laptop | Aviso y alternancia | | | |
| FUN-05 | Transferencia ciega (T1) | 3001 → 1000 → `##` 2002 | Móvil → laptop → laptop | Llega a 2002 | | | |
| FUN-06 | Transferencia atendida (T2) | 4001 → 1000 → `*2` 2001 | PC → laptop → móvil | Consulta y transfiere | | | |
| FUN-07 | Transferencia ciega (T3) | 1000 → 1001 → 3002 | Laptop → móvil → laptop | Llega a 3002 | | | |
| FUN-08 | Transferencia atendida (T4) | 2002 → 2001 → 3001 | Laptop → móvil → móvil | Consulta y transfiere | | | |
| FUN-09 | Buzón: no contesta | 4001 → 1000 sin contestar | PC | Saludo personalizado y mensaje grabado | | | |
| FUN-10 | Buzón: ocupado | 1000 ocupado, `*71`, 3001 llama | Móvil | Saludo de ocupado | | | |
| FUN-11 | Buzón: consultar | `*97` + PIN en 1000; `*98` desde 2001 | Laptop y móvil | Reproduce el mensaje | | | |
| FUN-12 | IVR bienvenida | Llamar al 7000 | Laptop | Mensaje claro en español | | | |
| FUN-13 | IVR opciones 1–4 | Recorrer cada opción | Laptop y móvil | Destino correcto | | | |
| FUN-14 | IVR operadora | Marcar 0 | Móvil | Llega a 1000 | | | |
| FUN-15 | IVR opción inválida | Marcar 8 dos veces | Laptop | Mensaje de error → operadora | | | |
| FUN-16 | IVR sin respuesta | No marcar | Móvil | Pasa a la operadora | | | |

### 1.4 Terminales (criterio E)
| ID | Requisito | Procedimiento | Resultado esperado | Resultado obtenido | Estado | Evidencia |
|---|---|---|---|---|---|---|
| TER-01 | ≥ 4 registros simultáneos | `pjsip show contacts` | ≥ 4 Avail (laptop + móvil) | | | |
| TER-02 | Escritorio ↔ móvil | L1, L6 (archivo 05) | Audio en ambos sentidos | | | |
| TER-03 | Escritorio ↔ escritorio | L2, L4 | Audio en ambos sentidos | | | |
| TER-04 | Móvil ↔ móvil | L3 | Audio en ambos sentidos | | | |
| TER-05 | Entre VLAN distintas | L1, L4, L5 | Audio en ambos sentidos | | | |
| TER-06 | Calidad de audio | Calificación 1–5 en cada llamada | ≥ 4 | | | |
| TER-07 | Guía de usuario | Persona no técnica configura un softphone con la guía | Lo logra sin ayuda | | | |

### 1.5 QoS (criterio F)
| ID | Requisito | Procedimiento | Resultado esperado | Resultado obtenido | Estado | Evidencia |
|---|---|---|---|---|---|---|
| QOS-01 | 4+ clases definidas | Tabla del archivo 06 | 5 clases documentadas | | | |
| QOS-02 | Marcado EF | Wireshark en laptop ADMIN durante una llamada | RTP con DSCP 46 | | | |
| QOS-03 | Marcado CS3 | Wireshark: paquetes SIP | DSCP 24 | | | |
| QOS-04 | Límite a invitados | Speedtest desde CMH-Invitados | ≤ 5 Mbps | | | |
| QOS-05 | Base | Escenario 1 (pérdida y jitter medidos en la PBX) | Dentro de las metas | | | |
| QOS-06 | Sin QoS + saturación | Escenario 2 (saturación en los dos sentidos, medición en la PBX) | Degradación medible | | | |
| QOS-07 | Con QoS + saturación | Escenario 3 (saturación en los dos sentidos, medición en la PBX) | ≤ 150 ms, jitter < 30 ms, pérdida < 1 % | | | |
| QOS-08 | Estadísticas del equipo | `queue tree print stats` en ambos escenarios | EF sin descartes con QoS | | | |

### 1.6 Seguridad (§5.8)
| ID | Prueba | Resultado esperado | Resultado obtenido | Estado | Evidencia |
|---|---|---|---|---|---|
| SEG-01 | S1: descubrimiento desde invitados | 0 hosts | | | |
| SEG-02 | S2: puertos de la PBX desde ADMIN | 22/80/443 filtrados | | | |
| SEG-03 | S4: web de la PBX desde VLAN VOZ | No abre | | | |
| SEG-04 | S5: fuerza bruta SIP | IP bloqueada por fail2ban | | | |
| SEG-05 | S6: servicios del router desde ADMIN | Filtrados | | | |
| SEG-06 | Credenciales por defecto | `admin` no existe en el router ni en FreePBX | | | |
| SEG-07 | Respaldos | Router y PBX respaldados, sin contraseñas | | | |
| SEG-08 | S9: puerto interno de gestión desde la red | 2222 y 18080 no responden en 192.168.20.20 | | | |

### 1.7 Extras
| ID | Extra | Procedimiento | Resultado esperado | Resultado obtenido | Estado | Evidencia |
|---|---|---|---|---|---|---|
| EXT-01 | E1 | 5002 con datos móviles llama a 1000 | Audio en ambos sentidos | | | |
| EXT-02 | E1 | 1000 llama a 5002 remoto | Audio en ambos sentidos | | | |
| EXT-03 | E3 | `pjsip show registrations` | Registered | | | |
| EXT-04 | E3 | Salida: 1000 marca `9` + cuenta B | Suena el teléfono externo | | | |
| EXT-05 | E3 | Entrada: cuenta B llama a la troncal | IVR → extensión | | | |
| EXT-06 | E4 | Ring group 8000 | Suenan 1000 y 1001 | | | |
| EXT-07 | E4 | Cola 8010 con 3 llamadas | Reparto + espera con posición | | | |
| EXT-08 | E4 | Condición horaria con código de anulación | IVR normal ↔ fuera de horario | | | |
| EXT-09 | E4 | Música personalizada en espera | Se escucha la pista CMH | | | |
| EXT-10 | E4 | Buzón por correo | Correo con el audio adjunto | | | |
| EXT-11 | E4 | Grabación de llamada | Grabación en el CDR, solo accesible desde GESTION | | | |

---

## 2. Matriz de trazabilidad (RN-01 a RN-10)

| Requerimiento | Descripción | Componente que lo implementa | Pruebas que lo validan | Evidencias | Estado |
|---|---|---|---|---|---|
| **RN-01** | Extensiones de 4 dígitos, espera y transferencia | FreePBX: plan de numeración, call waiting, feature codes | FUN-01 a FUN-08 | | |
| **RN-02** | Telefonía desde escritorio, laptop y móvil | MicroSIP, Linphone y Zoiper en VLAN ADMIN, VOZ y GESTION | TER-01 a TER-05 | | |
| **RN-03** | Separación de voz, administrativo, gestión e invitados | VLAN 10/20/30/40/50 + ACL en el RB4011 | RED-01 a RED-11 | | |
| **RN-04** | Calidad de voz con tráfico intenso | Marcado DSCP + colas por prioridad (RB4011) | QOS-01 a QOS-08 | | |
| **RN-05** | Seguridad de la plataforma | Firewall del router + firewall/fail2ban de FreePBX + respaldos | SEG-01 a SEG-07, PBX-03, PBX-06 | | |
| **RN-06** | Facilidad de uso y capacitación | Guía rápida, IVR claro, softphones sencillos | TER-07, FUN-12 | | |
| **RN-07** | IVR y buzón de voz | IVR-Principal + buzones en 4 extensiones | FUN-09 a FUN-16 | | |
| **RN-08** | Acceso desde fuera de la sede (E1) | Tailscale (VPN de usuario hacia la PBX) | EXT-01, EXT-02 | | |
| **RN-09** | Administración centralizada SDN (E2) | **No implementado.** No se cuenta con una arquitectura SDN (controladora que aprovisione los equipos). Justificación: decisión del grupo por costo y alcance. Se recomienda al cliente como mejora futura (por ejemplo, TP-Link Omada) | — | — | No aplica |
| **RN-10** | Troncal SIP y funciones avanzadas (E3/E4) | Troncal sip2sip, rutas, ring group, cola, condiciones horarias, música, buzón por correo | EXT-03 a EXT-11 | | |
