# Matriz de pruebas. Todas las pruebas

El guion para el día de la demostración está en `ESCENARIO-3-LAPTOPS.md` y `ESCENARIO-4-LAPTOPS.md`.

**Datos de Linphone para todos.** Usuario y usuario de autenticación igual al número de extensión, contraseña desde `CREDENCIALES-ACTUALES.md` (copiar y pegar), dominio `172.16.20.10`, transporte UDP, AVPF y presencia apagados, códecs PCMU primero, PCMA, G722 y opus. En Windows permitir Linphone en redes privadas **y públicas**.

## Pruebas de VLAN (criterio B, §5.5)

| Id | Dónde | Qué hacer | Debe pasar | Qué mostrar |
|---|---|---|---|---|
| VLAN-01 | Winbox desde ether3 | *Bridge → VLANs* | VLAN 10, 20, 30 y 40 con su puerto sin etiqueta | La tabla en Winbox |
| VLAN-02 | Cada puerto | Conectar una laptop y `ipconfig` | IP del rango de la VLAN del puerto (tabla de conexiones del guion) | `ipconfig` en cada puerto |
| VLAN-03 | Winbox | *IP → DHCP Server → Leases* | PBX en .10, laptop host en .20, el resto en .100 a .199 | Los leases en Winbox |
| VLAN-04 | Laptop en ether4 | Linphone 4001 se registra en 172.16.20.10 | Registrada en verde. Prueba el enrutamiento entre VLAN 30 y 20 | Linphone en verde y *Reports → Asterisk Info → Peers* |
| VLAN-05 | Celular en CMH-Voz | Ver la IP en el Wi-Fi del celular | 172.16.20.1xx | La IP en el celular |
| VLAN-06 | Laptop en ether5 | `ipconfig` y navegar | 172.16.40.1xx con internet, velocidad limitada a 5 Mbps | `ipconfig` y un speedtest |

## Matriz de ACL (criterio B)

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

## Llamadas y funcionalidades (criterios D y E, §5.4 y §5.7)

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

Resultados del 26/10 (ACL, llamadas y QoS) en [`DOCUMENTACION.md`](../DOCUMENTACION.md), sección 13.
