# Pruebas de entrega. Guion de la demostración

Es el único archivo que hay que seguir el día de la demostración. Leer de arriba hacia abajo. Cada paso dice en qué equipo, qué abrir y qué pegar.

**Web de la PBX.** Desde la laptop host, en el navegador. Todas las rutas empiezan con
```
http://127.0.0.1:18080/admin/
```

**Winbox.** Desde la laptop en **ether3** (Gestión). Conectar a `172.16.10.1` con el usuario `cmh-ti`. Los comandos se pegan en *New Terminal*.

---

## 0. Antes de que llegue el inge

**Qué llevar.** hEX con su fuente, AP Mercusys con su fuente, 3 cables de red, el Xiaomi con su cable USB, las laptops y los dos celulares con Linphone.

**Conectar en este orden.**
1. Xiaomi al USB del hEX, con datos móviles y *Anclaje USB* activado.
2. Encender el hEX y esperar un minuto.
3. Cable de ether2 del hEX a un puerto LAN del AP. Encender el AP.
4. Laptop A a otro puerto LAN del AP, con el Wi-Fi apagado.
5. Laptop B a ether4 y laptop C a ether3, con el Wi-Fi apagado. En cada una `ipconfig /renew`.
6. Celulares al Wi-Fi `CMH-Voz`.

**Quién lleva qué.**

| Laptop | Puerto | Lleva abierto |
|---|---|---|
| **A** Isaac (host) | LAN del AP | VM encendida, navegador en la web de la PBX, Linphone **5001**, 2 PowerShell para iperf3 |
| **B** compañero | **ether4** (Admin) | Linphone **4001**, PowerShell en la carpeta de `Probar-Vlan.ps1` |
| **C** cualquiera | **ether3** (Gestión) | Winbox conectado |
| Celular 1 | Wi-Fi `CMH-Voz` | Linphone **3001** |
| Celular 2 | Wi-Fi `CMH-Voz` | Linphone **5002** (y la cuenta de Tailscale para el E1) |

Con 3 o con 4 laptops, el reparto está en `ESCENARIOS-PRUEBAS.md`.

Si solo hay dos laptops, la B empieza en ether3 para el paso 2 y se pasa a ether4 en el paso 3. En el paso 5 vuelve a ether3 solo para cambiar las colas.

Encender la VM en la laptop A y esperar 4 minutos (antes de eso los teléfonos no registran).
```powershell
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" startvm CMH-FreePBX --type headless
```

Comprobar que todo registró, en la laptop A.
```powershell
ssh -t -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "sudo asterisk -rx 'pjsip show contacts'; sudo asterisk -rx 'pjsip show registrations'"
```
Deben salir 4001, 5001, 3001 y 5002 en *Avail* y `sip2sip` en *Registered*.

Contadores del firewall en cero, en Winbox de la laptop C.
```
/ip firewall filter reset-counters-all
```

---

## 1. Diagrama y conexiones

1. Mostrar el diagrama del informe y esta tabla.

| Puerto del hEX | VLAN | Equipo | IP que debe recibir | Extensión |
|---|---|---|---|---|
| USB | WAN | Celular Xiaomi 11T con anclaje USB | La que da el celular | |
| 1 | WAN alterna | Libre (internet por cable si hay) | | |
| 2 | 20 Voz | AP Mercusys. La laptop host va a un puerto LAN del AP | Laptop host 172.16.20.20, PBX 172.16.20.10, AP 172.16.20.2 | 5001 en la laptop host |
| 3 | 10 Gestión | Laptop de TI, solo para Winbox, evidencias y web de la PBX | 172.16.10.1xx | |
| 4 | 30 Admin | Laptop del compañero con Linphone, iperf3 y Wireshark | 172.16.30.1xx | 4001 |
| 5 | 40 Invitados | Cualquier laptop o celular de prueba | 172.16.40.1xx | Ninguna |
| Wi-Fi CMH-Voz | 20 Voz | Celulares | 172.16.20.1xx | 3001, 5002 y demás |

2. En cada laptop, para que vea la IP de su VLAN:
   ```powershell
   ipconfig | findstr IPv4
   ```
   | Laptop | Debe dar |
   |---|---|
   | A | 172.16.20.20 (VLAN 20 Voz) |
   | B | 172.16.30.1xx (VLAN 30 Admin) |
   | C | 172.16.10.1xx (VLAN 10 Gestión) |
3. En el celular, *Ajustes → Wi-Fi → CMH-Voz*. Debe dar 172.16.20.1xx.

**Decir.** Clase B 172.16.0.0/12, una /24 por VLAN y el tercer octeto es el número de VLAN. La VLAN 10 es la de administración. Internet entra por el celular conectado al USB del hEX.

---

## 2. Winbox. VLAN, DHCP, firewall y colas

Laptop C. Abrir cada pantalla o pegar el comando en *New Terminal*.

| Mostrar | Ruta en Winbox | Comando |
|---|---|---|
| Puertos y su VLAN | *Bridge → Ports* | `/interface bridge port print` |
| VLAN 10, 20, 30 y 40 | *Bridge → VLANs* | `/interface bridge vlan print` |
| Gateway de cada VLAN | *IP → Addresses* | `/ip address print` |
| Un DHCP por VLAN | *IP → DHCP Server → DHCP* | `/ip dhcp-server print` |
| Equipos conectados y reservas | *IP → DHCP Server → Leases* | `/ip dhcp-server lease print` |
| WAN por el celular | *IP → DHCP Client* | `/ip dhcp-client print` |
| Matriz entre VLAN (M1 a M6) | *IP → Firewall → Filter Rules* | `/ip firewall filter print where chain=forward` |
| NAT | *IP → Firewall → NAT* | `/ip firewall nat print` |
| Marcado DSCP de la voz | *IP → Firewall → Mangle* | `/ip firewall mangle print` |
| Colas de prioridad | *Queues → Queue Tree* | `/queue tree print` |
| SIP ALG apagado | *IP → Firewall → Service Ports* | `/ip firewall service-port print` |

**Decir.** M2 deja a Admin hablar con la PBX solo por SIP y RTP. M6 descarta todo lo demás. El audio se marca EF (46) y va en la cola de prioridad 1 con 512 kbps garantizados.

---

## 3. Matriz de ACL en vivo

Laptop B en **ether4**, Wi-Fi apagado:
```powershell
powershell -ExecutionPolicy Bypass -File .\Probar-Vlan.ps1 -Extension 4001
```
Debe dar **11 de 11 Cumple**.

Laptop A (Voz):
```powershell
cd C:\Users\Asus\Projects\cmh-horizonte\pruebas
powershell -ExecutionPolicy Bypass -File .\Probar-Vlan.ps1 -Extension 5001
```
Debe dar **8 de 8 Cumple**.

Opcional, una laptop en **ether5** (Invitados):
```powershell
powershell -ExecutionPolicy Bypass -File .\Probar-Vlan.ps1
```

**Si el inge no quiere ver el script.** Hacer la matriz a mano con el paso 2 de `ESCENARIOS-PRUEBAS.md` y dejar el script solo como respaldo.

**Decir.** El script prueba cada regla y compara lo esperado contra lo obtenido. Desde Admin llega a la PBX por SIP, pero no le hace ping ni entra a su web ni al router.

---

## 4. Llamadas

| Prueba | Quién marca | Qué hacer | Debe pasar |
|---|---|---|---|
| **TEL-01** entre VLAN | 4001 (laptop B) | Marcar `5002`, hablar. Luego 5002 marca `4001` | Audio en los dos sentidos |
| **TEL-04** espera | 4001 en la llamada | Botón de pausa en Linphone y retomar | 5002 escucha la música de CMH |
| **TEL-06** transferencia ciega | 5002 marca `4001` | 4001 toca *Transferir*, escribe `3001` y transfiere (o marca `##3001`) | 3001 queda hablando con 5002 |
| **TEL-11** IVR | 5002 | Marcar `7000`. Escuchar el menú y marcar `4` | Bienvenida en español y suena la 4001 |

Opciones del IVR. 1 Recepción, 2 Consulta Externa, 3 Enfermería (3001), 4 Administración (4001), 0 operadora.

Mientras hay una llamada, en la web:
```
http://127.0.0.1:18080/admin/config.php?display=asteriskinfo&module=peers
```
Ahí se ven las extensiones registradas con su IP 172.16.x.

---

## 5. QoS con y sin prioridad

**Laptop A**, dos PowerShell, una con cada servidor:
```powershell
iperf3 -s -p 5201
```
```powershell
iperf3 -s -p 5202
```

**Laptop C** (Winbox, terminal). Preparar:
```
/ip firewall filter enable [find comment~"^PRUEBA-QOS"]
/ip firewall mangle add chain=forward src-address-list=net-admin dst-address-list=iperf-srv protocol=udp dst-port=5202 action=change-dscp new-dscp=46 passthrough=yes comment="TEMP-PRUEBA-QOS: flujo de voz simulado -> EF" place-before=[find comment="QoS: marca INVITADOS"]
/queue tree reset-counters-all
```

### Ronda 1, con QoS

1. Llamada **4001 ↔ 5002** activa y en altavoz.
2. **Laptop B**, primera PowerShell (satura el enlace):
   ```powershell
   iperf3 -c 172.16.20.20 -p 5201 -u -b 20M -t 75
   ```
3. A los 5 segundos, segunda PowerShell (imita la voz):
   ```powershell
   iperf3 -c 172.16.20.20 -p 5202 -u -b 69k -l 172 -t 60 -i 10
   ```
4. En Winbox:
   ```
   /queue tree print stats where name~"q-voz"
   ```

Debe pasar. La llamada se escucha limpia y la segunda terminal marca cerca de **0 % de pérdida**. La cola `q-voz-ef` no descarta paquetes.

### Ronda 2, sin QoS

Winbox:
```
/queue tree disable [find comment="QOS-PRIO"]; /queue tree enable [find comment="QOS-FIFO"]; /queue tree reset-counters-all
```
Repetir los pasos 1 a 4 de la ronda 1.

Debe pasar. La llamada se corta o se escucha robótica y la pérdida sube (el 26/10 dio **9,4 %**, el límite del PDF es 1 %).

### Dejar el router como estaba

```
/queue tree disable [find comment="QOS-FIFO"]; /queue tree enable [find comment="QOS-PRIO"]
/ip firewall filter disable [find comment~"^PRUEBA-QOS"]
/ip firewall mangle remove [find comment~"TEMP-PRUEBA-QOS"]
```

**Decir.** El enlace de prueba se limitó a 2 Mbps para poder saturarlo. Con prioridad el router descarta la saturación y deja pasar la voz. Sin prioridad todo va a una sola cola y la voz se pierde junto con lo demás. Resultado del 26/10 en `pruebas/resultados/qos-20261026.md`.

---

## 6. Extras

### E1. Llamada desde red pública (8 pts)

1. Celular 2 (5002). **Apagar el Wi-Fi**, datos móviles encendidos, abrir **Tailscale** y conectarlo.
2. En Linphone activar la cuenta 5002 con dominio `100.91.176.16`.
3. 5002 marca `4001`. Contestar y hablar.
4. En la web:
   ```
   http://127.0.0.1:18080/admin/config.php?display=asteriskinfo&module=peers
   ```
   La 5002 aparece con una IP **100.x**, la de Tailscale.

**Decir.** El celular está fuera de la red del centro médico. Entra por un túnel cifrado WireGuard sin abrir puertos en el router.

### E3. Troncal SIP con sip2sip (5 pts)

Web, troncal y su registro:
```
http://127.0.0.1:18080/admin/config.php?display=trunks
```
```
http://127.0.0.1:18080/admin/config.php?display=asteriskinfo&module=registries
```
Debe decir **Registered**.

Llamada saliente. Desde la 4001 marcar:
```
9100
```
Suena el celular que tiene la cuenta externa `cmh-orizonte-ext`.

Llamada entrante. Desde la cuenta `cmh-orizonte-ext` (con datos móviles) llamar a:
```
cmh-horizonte@sip2sip.info
```
Contesta el IVR del centro médico.

Ruta entrante:
```
http://127.0.0.1:18080/admin/config.php?display=did
```

### E4. Una función avanzada (4 pts)

**Condición de horario.** El horario de atención es de lunes a viernes de 7:00 a 19:00 y el sábado de 7:00 a 12:00. Si la demo es dentro de ese horario, el `7000` contesta el menú normal y hay que cerrar el changarro a mano.

**Cerrar el changarro (forzar fuera de horario).** En la laptop A:
```powershell
ssh -t -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "sudo asterisk -rx 'database put TC 1 false_sticky'"
```
Marcar `7000` desde cualquier extensión. Contesta el menú de fuera de horario.

**Abrir otra vez (volver al horario normal).**
```powershell
ssh -t -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "sudo asterisk -rx 'database del TC 1'"
```

**Desde un teléfono.** Marcar `*271` cambia al estado contrario del que tiene en ese momento. Si está abierto lo cierra y si está cerrado lo abre. Marcar `*271` otra vez lo deja como estaba. Antes de cerrar, llamar al `7000` para saber en qué estado está.

Web:
```
http://127.0.0.1:18080/admin/config.php?display=timeconditions
```

Si piden otra:

| Función | Cómo | Ruta web |
|---|---|---|
| Música en espera | Ya se oyó en TEL-04 | `config.php?display=music` |
| Buzón por correo | 4001 marca `3001`, nadie contesta, dejar mensaje. Abrir el correo en el teléfono | `config.php?display=voicemail` |
| Escuchar el buzón | Desde 3001 marcar `*97` y el PIN | `config.php?display=asteriskinfo&module=voicemail` |
| Cola | Marcar `8010` (necesita 2001 y 2002 registradas) | `config.php?display=queues` |
| Grupo de timbrado | Marcar `8000` (necesita 1000 y 1001 registradas) | `config.php?display=ringgroups` |

---

## 7. Cierre. CDR y contadores

**CDR.** En la web, tocar **Search**:
```
http://127.0.0.1:18080/admin/config.php?display=cdr
```
Se ven todas las llamadas de la demostración con hora, origen, destino y duración.

**Contadores del firewall.** Winbox:
```
/ip firewall filter print stats where comment~"^M[1-6]"
```
Debe verse:
- **M2** y **M3** con paquetes. Son las llamadas entre Admin y la PBX.
- **M6** con paquetes. Son los bloqueos que probó `Probar-Vlan.ps1`.

---

## Si algo falla

| Problema | Solución |
|---|---|
| Un teléfono no registra después de varios intentos | Laptop A: `ssh -t -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "sudo fail2ban-client set asterisk-iptables unbanip IP_DEL_TELEFONO"` |
| La troncal no dice Registered | Laptop A: `ssh -t -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "sudo asterisk -rx 'pjsip send register sip2sip'"` |
| La web de la PBX no abre | Esperar a que termine de arrancar la VM (4 minutos) |
| `Probar-Vlan.ps1` avisa de otra salida a internet | Apagar el Wi-Fi de esa laptop y repetir |
| No hay internet en el router | Revisar en el Xiaomi que siga activo el *Anclaje USB* |

---

## Anexo. Todas las pruebas

**Datos de Linphone para todos.** Usuario y usuario de autenticación igual al número de extensión, contraseña desde `CREDENCIALES-ACTUALES.md` (copiar y pegar), dominio `172.16.20.10`, transporte UDP, AVPF y presencia apagados, códecs PCMU primero, PCMA, G722 y opus. En Windows permitir Linphone en redes privadas **y públicas**.

### Pruebas de VLAN (criterio B, §5.5)

| Id | Dónde | Qué hacer | Debe pasar | Qué mostrar |
|---|---|---|---|---|
| VLAN-01 | Winbox desde ether3 | *Bridge → VLANs* | VLAN 10, 20, 30 y 40 con su puerto sin etiqueta | La tabla en Winbox |
| VLAN-02 | Cada puerto | Conectar una laptop y `ipconfig` | IP del rango de la VLAN del puerto (tabla de la sección 1) | `ipconfig` en cada puerto |
| VLAN-03 | Winbox | *IP → DHCP Server → Leases* | PBX en .10, laptop host en .20, el resto en .100 a .199 | Los leases en Winbox |
| VLAN-04 | Laptop en ether4 | Linphone 4001 se registra en 172.16.20.10 | Registrada en verde. Prueba el enrutamiento entre VLAN 30 y 20 | Linphone en verde y *Reports → Asterisk Info → Peers* |
| VLAN-05 | Celular en CMH-Voz | Ver la IP en el Wi-Fi del celular | 172.16.20.1xx | La IP en el celular |
| VLAN-06 | Laptop en ether5 | `ipconfig` y navegar | 172.16.40.1xx con internet, velocidad limitada a 5 Mbps | `ipconfig` y un speedtest |

### Matriz de ACL (criterio B)

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

### Llamadas y funcionalidades (criterios D y E, §5.4 y §5.7)

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

Resultados del 26/10 (ACL, llamadas y QoS) en [`DOCUMENTACION.md`](DOCUMENTACION.md), sección 13.

---

## Al terminar

Apagar la VM antes de desconectar, para no dañar la base de datos.
```powershell
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" controlvm CMH-FreePBX acpipowerbutton
```
