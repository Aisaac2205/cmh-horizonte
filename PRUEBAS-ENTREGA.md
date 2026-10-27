# Pruebas de entrega. VLAN, ACL, llamadas, QoS y extras

**Qué se ejecuta y qué se muestra.** Las secciones 2 a 5 (VLAN, ACL, llamadas y QoS) se **ejecutan** en vivo el día de la entrega, igual que el 26/10. La sección 6 (extras E1, E3 y E4) ya está implementada y solo se **muestra** con una llamada de ejemplo y su pantalla en FreePBX.

**Resultados del 26/10, ya con clase B.** Matriz de ACL desde Admin 11 de 11 y desde Voz 8 de 8 (`pruebas/resultados/vlan30-*.md` y `vlan20-*.md`). QoS con 0 % de pérdida de voz frente a 9,4 % sin QoS (`pruebas/resultados/qos-20261026.md`).

Guía corta para hacer las pruebas igual hoy y el día de la entrega. Cada prueba dice dónde se hace, qué se hace, qué debe pasar y qué se muestra o captura. Las referencias (§) son del documento del proyecto PF-TEL-001-2026.

Direccionamiento clase B. VLAN 10 Gestión 172.16.10.0/24, VLAN 20 Voz 172.16.20.0/24, VLAN 30 Admin 172.16.30.0/24, VLAN 40 Invitados 172.16.40.0/24. La PBX está en **172.16.20.10**.

---

## 1. Dónde se conecta cada cosa

| Puerto del hEX | VLAN | Equipo | IP que debe recibir | Extensión |
|---|---|---|---|---|
| USB | WAN | Celular Xiaomi 11T con anclaje USB | La que da el celular | |
| 1 | WAN alterna | Libre (internet por cable si hay) | | |
| 2 | 20 Voz | AP Mercusys. La laptop host va a un puerto LAN del AP | Laptop host 172.16.20.20, PBX 172.16.20.10, AP 172.16.20.2 | 5001 en la laptop host |
| 3 | 10 Gestión | Laptop de TI, solo para Winbox, evidencias y web de la PBX | 172.16.10.1xx | |
| 4 | 30 Admin | Laptop del compañero con Linphone, iperf3 y Wireshark | 172.16.30.1xx | 4001 |
| 5 | 40 Invitados | Cualquier laptop o celular de prueba | 172.16.40.1xx | Ninguna |
| Wi-Fi CMH-Voz | 20 Voz | Celulares | 172.16.20.1xx | 3001, 5002 y demás |

**Antes de cada prueba en una laptop.** Apagar el Wi-Fi y Tailscale, conectar el cable, correr `ipconfig /renew` y revisar con `ipconfig` que la IP sea la de la tabla.

**Datos de Linphone para todos.** Usuario y usuario de autenticación igual al número de extensión, contraseña desde `CREDENCIALES-ACTUALES.md` (copiar y pegar), dominio `172.16.20.10`, transporte UDP, AVPF y presencia apagados, códecs PCMU primero, PCMA, G722 y opus. En Windows permitir Linphone en redes privadas **y públicas**.

> Cinco contraseñas malas seguidas bloquean la IP por 30 minutos (fail2ban). Para desbloquear, en la VM: `sudo fail2ban-client set asterisk-iptables unbanip <IP>`.

---

## 2. Pruebas de VLAN (criterio B, §5.5)

| Id | Dónde | Qué hacer | Debe pasar | Qué mostrar |
|---|---|---|---|---|
| VLAN-01 | Winbox desde ether3 | *Bridge → VLANs* | VLAN 10, 20, 30 y 40 con su puerto sin etiqueta | Captura de la tabla |
| VLAN-02 | Cada puerto | Conectar una laptop y `ipconfig` | IP del rango de la VLAN del puerto (tabla de la sección 1) | Captura de `ipconfig` en cada puerto |
| VLAN-03 | Winbox | *IP → DHCP Server → Leases* | PBX en .10, laptop host en .20, el resto en .100 a .199 | Captura de leases |
| VLAN-04 | Laptop en ether4 | Linphone 4001 se registra en 172.16.20.10 | Registrada en verde. Prueba el enrutamiento entre VLAN 30 y 20 | Captura de Linphone y de *Reports → Asterisk Info → Peers* |
| VLAN-05 | Celular en CMH-Voz | Ver la IP en el Wi-Fi del celular | 172.16.20.1xx | Captura del celular |
| VLAN-06 | Laptop en ether5 | `ipconfig` y navegar | 172.16.40.1xx con internet, velocidad limitada a 5 Mbps | Captura de `ipconfig` y de un speedtest |

---

## 3. Pruebas de ACL (criterio B, matriz de comunicación)

**Automáticas.** En cada laptop, desde la carpeta donde esté `Probar-Vlan.ps1` (en una laptop ajena se pasa el archivo por USB o WhatsApp y se corre con `powershell -ExecutionPolicy Bypass -File .\Probar-Vlan.ps1 -Extension 4001`):

```powershell
.\Probar-Vlan.ps1 -Extension 4001     # ether4, Admin
.\Probar-Vlan.ps1 -Extension 5001     # laptop host, Voz
.\Probar-Vlan.ps1                     # ether3 Gestión o ether5 Invitados
```

El script detecta la VLAN, prueba cada regla y deja un informe en `pruebas/resultados/`. Todas las filas deben decir **Cumple**. Si sale un aviso amarillo de otras salidas a internet, apagar el Wi-Fi y repetir.

**Lo que se verifica y por qué.**

| Desde | Hacia | Debe | Regla |
|---|---|---|---|
| Gestión | Router (Winbox, SSH), PBX (web, SSH), AP | Permitido | Entrada desde Gestión y M1 |
| Admin | PBX por SIP 5060 y RTP 10000 a 20000 | Permitido | M2 |
| Admin | PBX por ping, web o SSH | Bloqueado | M6 |
| Admin | Router por Winbox o SSH | Bloqueado | Entrada, descartar el resto |
| Admin | AP y otros equipos de Voz | Bloqueado | M6 |
| Voz | Web de la PBX | Bloqueado | Firewall de FreePBX (web solo desde Gestión) |
| Invitados | PBX, AP, Admin, Gestión | Bloqueado | M6, invitados aislados |
| Todas | Internet | Permitido | M5 y NAT por lte1 |

**Prueba de contadores (lo que convence al catedrático).** Desde la laptop en ether3:

1. `.\Evidencia-Router.ps1 -Usuario cmh-ti -Etiqueta antes -ReiniciarContadores`
2. Llamada de un minuto entre 4001 y 5002, y un `ping 172.16.20.10` desde la laptop de ether4.
3. `.\Evidencia-Router.ps1 -Usuario cmh-ti -Etiqueta despues`
4. Abrir `pruebas/evidencias/router-...-despues/11-firewall-filter.txt`. Las reglas **M2** y **M3** deben tener paquetes por la llamada y la **M6** por el ping bloqueado.

---

## 4. Llamadas y funcionalidades (criterios D y E, §5.4 y §5.7)

Mínimo cuatro extensiones registradas a la vez, con al menos una laptop y un celular (§5.7). Hoy son 4001 (laptop en Admin), 5001 (laptop host en Voz), 3001 y 5002 (celulares en Voz).

| Id | Prueba | Cómo | Debe pasar |
|---|---|---|---|
| TEL-01 | Laptop ↔ celular entre VLAN | 4001 llama a 5002 y luego 5002 llama a 4001 | Audio en los dos sentidos |
| TEL-02 | Laptop ↔ laptop | 4001 llama a 5001 | Audio en los dos sentidos |
| TEL-03 | Celular ↔ celular | 3001 llama a 5002 | Audio en los dos sentidos |
| TEL-04 | Espera | En TEL-01, 4001 pone en espera y retoma | Quien espera escucha la música de CMH |
| TEL-05 | Segunda llamada | 4001 habla con 5002 y la 3001 llama a 4001 | 4001 ve la segunda llamada, pone a 5002 en espera, contesta y regresa |
| TEL-06 | Transferencia ciega | 5002 llama a 4001 y 4001 transfiere a 3001 sin anunciar (`##` o el botón de la app) | 3001 queda hablando con 5002 |
| TEL-07 | Transferencia atendida | 5002 llama a 4001, 4001 consulta a 3001 y completa (`*2` o el botón de la app) | 3001 queda hablando con 5002 |
| TEL-08 | Buzón por no contestar | 4001 llama a 3001 y nadie contesta | Saludo personalizado y se deja un mensaje |
| TEL-09 | Buzón por ocupado | 3001 en llamada y 4001 la llama | Cae al buzón con el saludo de ocupado |
| TEL-10 | Escuchar el buzón | Desde 3001 marcar `*97` y el PIN | Se escucha el mensaje de TEL-08 |
| TEL-11 | IVR | Desde un celular marcar `7000` | Bienvenida en español. 1 Recepción, 2 Consulta Externa, 3 a la 3001, 4 a la 4001, 0 operadora. Una tecla inválida repite el menú y sin respuesta vuelve a preguntar |

**Qué mostrar.** El CDR en *Reports → CDR Reports* con todas las llamadas de la ronda (captura con fecha y hora) y la lista de teléfonos registrados.

---

## 5. QoS bajo congestión (criterio F, §5.6)

Se hizo y midió el 26/10 (resultados en `pruebas/resultados/qos-20261026.md`). Para repetirla igual:

**Equipos.** Laptop host en el AP (servidor iperf3, 172.16.20.20), laptop del compañero en ether4 (cliente iperf3) y una laptop en ether3 con Winbox para cambiar el router. iperf3 se instala con `winget install ar51an.iPerf3`.

**1. Router, preparar (Winbox desde ether3, terminal).**
```
/ip firewall filter enable [find comment~"^PRUEBA-QOS"]
/ip firewall mangle add chain=forward src-address-list=net-admin dst-address-list=iperf-srv protocol=udp dst-port=5202 action=change-dscp new-dscp=46 passthrough=yes comment="TEMP-PRUEBA-QOS: flujo de voz simulado -> EF" place-before=[find comment="QoS: marca INVITADOS"]
/queue tree reset-counters-all
```
La regla de mangle marca como EF el flujo que imita la llamada, igual que el router marca el RTP real. Windows no deja que iperf3 ponga el DSCP por su cuenta.

**2. Laptop host, servidores (PowerShell, dos ventanas).**
```
iperf3 -s -p 5201
iperf3 -s -p 5202
```
Si es la primera vez, en PowerShell de administrador abrir el firewall de Windows:
```
New-NetFirewallRule -DisplayName "CMH iperf3 TCP" -Direction Inbound -Protocol TCP -LocalPort 5201,5202 -Action Allow -Profile Any
New-NetFirewallRule -DisplayName "CMH iperf3 UDP" -Direction Inbound -Protocol UDP -LocalPort 5201,5202 -Action Allow -Profile Any
```

**3. Ronda con QoS.** Llamada 4001 ↔ 5002 activa. En la laptop de ether4, dos terminales:
```
iperf3 -c 172.16.20.20 -p 5201 -u -b 20M -t 75
iperf3 -c 172.16.20.20 -p 5202 -u -b 69k -l 172 -t 60 -i 10
```
La primera satura el enlace de 2 Mbps. La segunda, arrancada 5 segundos después, imita G.711 (50 paquetes por segundo de 172 bytes). Captura de la terminal de la segunda y, en Winbox, `/queue tree print stats where name~"q-voz"`.

**4. Ronda sin QoS.**
```
/queue tree disable [find comment="QOS-PRIO"]; /queue tree enable [find comment="QOS-FIFO"]; /queue tree reset-counters-all
```
Repetir el paso 3 con las mismas capturas.

**5. Dejar el router como estaba.**
```
/queue tree disable [find comment="QOS-FIFO"]; /queue tree enable [find comment="QOS-PRIO"]
/ip firewall filter disable [find comment~"^PRUEBA-QOS"]
/ip firewall mangle remove [find comment~"TEMP-PRUEBA-QOS"]
```

**Resultado del 26/10.**

| | Con QoS | Sin QoS |
|---|---|---|
| Pérdida del flujo de voz | 0 % (0 de 3010) | 9,4 % (283 de 3009) |
| Jitter | 0,148 ms | 0,105 ms |
| Voz descartada por el router | 0 paquetes | Mezclada con la saturación en la FIFO |
| Saturación descartada | 117 269 paquetes | 118 866 paquetes |

Para la defensa. El jitter sale bajo en los dos casos porque la cola se mantiene llena y el retardo es parejo. Lo que daña la llamada sin QoS es la pérdida (casi diez veces el límite del 1 %) y el retardo de cola, que con 50 paquetes de 1470 bytes a 2 Mbps se estima en unos 300 ms.

---

## 6. Extras

| Extra | Qué mostrar | Cómo se valida |
|---|---|---|
| **E1** Red pública (8 pts) | Celular de 5002 con **datos móviles**, sin Wi-Fi, con Tailscale encendido y la cuenta con dominio `100.91.176.16` | 5002 llama a 4001 y 4001 llama a 5002, audio en ambos sentidos. Mostrar *Asterisk Info → Peers* con 5002 en una IP 100.x y el CDR |
| **E2** SDN | No se implementa | En el informe se explica que la VLAN 10 Gestión cumple el papel de VLAN de administración centralizada |
| **E3** Troncal SIP (5 pts) | Troncal sip2sip en estado registrada (*Connectivity → Trunks*) | Salida: desde 4001 marcar `9cmh_externo` y suena la cuenta externa. Entrada: desde la cuenta externa llamar a `cmh_troncal@sip2sip.info` y entra al IVR. Mostrar el CDR con la troncal |
| **E4** Funciones avanzadas (4 pts) | | |
| Grupo de timbrado | Llamar al `8000` | Suenan 1000 y 1001 a la vez |
| Cola | Llamar al `8010` | Música de espera y reparte entre 2001 y 2002 |
| Condición horaria | Marcar `*271` para forzar fuera de horario y llamar al `7000` | Mensaje de fuera de horario. Volver a marcar `*271` para regresar |
| Música en espera | Durante TEL-04 | Se escucha la música propia de CMH |
| Buzón por correo | Después de TEL-08 | Llega el correo con el mensaje adjunto. Mostrarlo en el teléfono |
| Grabación | Una llamada a la 1000 | Aviso de grabación al inicio y la grabación aparece en el CDR, solo accesible para el administrador |

Para el grupo 8000 y la cola 8010 hacen falta las extensiones 1000, 1001, 2001 y 2002 registradas en los celulares de los integrantes.

---

## 7. Orden para la demostración (unos 20 minutos)

1. Diagrama y tabla de conexiones (sección 1).
2. Winbox. VLAN, DHCP, firewall y colas (VLAN-01 y VLAN-03).
3. `Probar-Vlan.ps1` en ether4 en vivo (sección 3).
4. TEL-01, TEL-04, TEL-06 y TEL-11.
5. QoS con y sin prioridad, escuchando la llamada (sección 5).
6. Extras E1 y E3, y una función del E4.
7. CDR y contadores del firewall como cierre.

Si falla la conexión en clase, usar el video de respaldo grabado con estas mismas pruebas.
