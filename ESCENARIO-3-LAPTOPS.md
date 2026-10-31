# Demostración con 3 laptops

Equipo en esta versión. Isaac, José y Regi.

Este es el único guion para el día de la demostración. Se lee de arriba hacia abajo. Cada paso dice quién lo hace, qué hace y qué debe pasar.

**Palabras que se usan**
- **VLAN.** Una red separada dentro del mismo router. Son 4: Gestión (10), Voz (20), Admin (30) e Invitados (40).
- **ACL.** Las reglas del router que dicen quién puede hablar con quién.
- **QoS.** Hace que la voz tenga prioridad y no se corte cuando la red está llena.
- **IVR.** El menú de voz que contesta cuando se marca el `7000`.

---

## 1. Quién es quién

| Equipo | Quién | Cómo se conecta | Qué lleva abierto | Extensión |
|---|---|---|---|---|
| **A** laptop host | Isaac | Cable al puerto LAN del AP. Usa el puerto de red de su laptop | La VM encendida, la web de la PBX, Linphone y 2 PowerShell para iperf3 | **5001** |
| **B** laptop | José (reemplaza a Anthony, de Lima) | Cable a **ether4** del hEX, con el puerto de red de su laptop. Red Admin | Linphone y PowerShell | **4001** |
| **C** laptop | Regi | Adaptador y cable a **ether3** del hEX. Red Gestión | Winbox | Ninguna |
| **Celular 1** | Un compañero con celular | Wi-Fi `CMH-Voz` | Linphone | **3001** |
| **Celular 2** | iPhone de Isaac, lo puede tener otro compañero | Wi-Fi `CMH-Voz` | Linphone y Tailscale | **5002** |

Isaac y José tienen puerto de red en su laptop. Solo Regi usa un adaptador. La 4001 es la extensión de Anthony (Lima) y José la usa como su reemplazo. Si además llega Romeo con laptop, usar `ESCENARIO-4-LAPTOPS.md`.

---

## 2. Qué llevar y cómo conectar

**Qué llevar.** El hEX con su fuente, el AP Mercusys con su fuente, el Xiaomi con su cable USB, 4 cables de red, 2 adaptadores Ethernet (Regi usa uno, el otro es de repuesto), las laptops y los celulares con Linphone.

**Instalar antes (esta noche o mañana temprano).** Cada laptop con extensión necesita Linphone para Windows. Se descarga de linphone.org (editor Belledonne Communications). Winbox se descarga de mikrotik.com y iperf3 para Windows de iperf.fr.

| Equipo | Instalar |
|---|---|
| **A** (Isaac) | Linphone e iperf3 |
| **B** | Linphone e iperf3 |
| **C** | Winbox |

**Conectar en este orden.**
1. Xiaomi al puerto USB del hEX, con datos móviles y *Anclaje USB* activado.
2. Encender el hEX y esperar un minuto.
3. Cable de **ether2** del hEX a un puerto LAN del AP. Encender el AP.
4. **A** (Isaac). Cable de su laptop a otro puerto LAN del AP. Wi-Fi apagado.
5. **B** (José). Cable a **ether4**, en el puerto de su laptop. Wi-Fi apagado. Escribir `ipconfig /renew`.
6. **C** (Regi). Adaptador y cable a **ether3**. Wi-Fi apagado. Escribir `ipconfig /renew`.

**Celulares.** Conectarse al Wi-Fi `CMH-Voz`.

---

## 3. Antes de empezar (10 minutos)

**Configurar Linphone en la PC.** Se hace una vez en cada laptop que usa Linphone (A y B). Los nombres de los menús pueden cambiar un poco según la versión.

1. Abrir Linphone. Si ya tiene una cuenta vieja (con otro dominio, como `100.91.176.16` o `192.168.x.x`), **borrarla**. Una cuenta vieja guarda la contraseña vieja y la autenticación falla.
2. Elegir *Usar una cuenta SIP* y llenar los datos de la tabla.
3. Esperar a que la cuenta salga en **verde**.
4. Probar marcando `*43`. Debe oírse la propia voz con un pequeño retraso.

| Dato | Qué poner |
|---|---|
| Usuario | El número de extensión, por ejemplo `4001` |
| Usuario de autenticación | El mismo número |
| Contraseña | La de esa extensión en `CREDENCIALES-ACTUALES.md` (copiar y pegar) |
| Dominio o servidor SIP | `172.16.20.10` |
| Transporte | UDP |
| AVPF y presencia | Apagados |
| Códecs | PCMU primero, luego PCMA, G722 y opus |

**La IP de la laptop no se configura.** Se queda en automático (DHCP) y el router le da la de su red. El dominio de Linphone es siempre `172.16.20.10`, aunque la laptop esté en otra red (Admin, Gestión o Voz). Si va con cable, el Wi-Fi va apagado. En Windows hay que permitir Linphone en redes privadas y públicas.

**Paso 3.1. A (Isaac) enciende la VM.** Después esperar 4 minutos. Antes de eso los teléfonos no se registran.
```powershell
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" startvm CMH-FreePBX --type headless
```

**Paso 3.2. A (Isaac) comprueba que todos se registraron.**
```powershell
ssh -t -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "sudo asterisk -rx 'pjsip show contacts'; sudo asterisk -rx 'pjsip show registrations'"
```
Deben salir 4001, 5001, 3001 y 5002 en *Avail* y `sip2sip` en *Registered*.

**Paso 3.3. C (Regi) abre Winbox y pone los contadores en cero.** Conectar a `172.16.10.1` con el usuario `cmh-ti`. Si no entra, elegir el router por su MAC en la pestaña *Neighbors*. Abrir *New Terminal* y pegar:
```
/ip firewall filter reset-counters-all
```

**La web de la PBX** se abre solo desde la laptop A, en el navegador. Todas las rutas empiezan con
```
http://127.0.0.1:18080/admin/
```

---

## 4. Prueba 1. Cada quien ve su red

Cada laptop escribe esto en PowerShell.
```powershell
ipconfig | findstr IPv4
```

| Equipo | Debe dar |
|---|---|
| A (Isaac) | 172.16.20.20 (red Voz) |
| B (José) | 172.16.30.1xx (red Admin) |
| C (Regi) | 172.16.10.1xx (red Gestión) |
| Celular | 172.16.20.1xx (en *Ajustes, Wi-Fi, CMH-Voz*) |

**Decir.** Usamos direcciones clase B 172.16.0.0/12, una red /24 por cada VLAN. El tercer número es el número de la VLAN. La VLAN 10 es la de administración. Internet entra por el celular conectado al USB del hEX.

---

## 5. Prueba 2. Winbox muestra la configuración

**C (Regi)** abre cada pantalla en Winbox o pega el comando en *New Terminal*.

| Mostrar | Ruta en Winbox | Comando |
|---|---|---|
| Puertos y su VLAN | *Bridge → Ports* | `/interface bridge port print` |
| VLAN 10, 20, 30 y 40 | *Bridge → VLANs* | `/interface bridge vlan print` |
| Gateway de cada VLAN | *IP → Addresses* | `/ip address print` |
| Un DHCP por VLAN | *IP → DHCP Server → DHCP* | `/ip dhcp-server print` |
| Equipos conectados y reservas | *IP → DHCP Server → Leases* | `/ip dhcp-server lease print` |
| Internet por el celular | *IP → DHCP Client* | `/ip dhcp-client print` |
| Reglas entre VLAN (M1 a M6) | *IP → Firewall → Filter Rules* | `/ip firewall filter print where chain=forward` |
| NAT | *IP → Firewall → NAT* | `/ip firewall nat print` |
| Marcado de la voz | *IP → Firewall → Mangle* | `/ip firewall mangle print` |
| Colas de prioridad | *Queues → Queue Tree* | `/queue tree print` |
| SIP ALG apagado | *IP → Firewall → Service Ports* | `/ip firewall service-port print` |

**Decir.** M2 deja a Admin hablar con la PBX solo por SIP y audio. M6 descarta todo lo demás. El audio se marca EF (46) y va en la cola de prioridad 1 con 512 kbps garantizados.

---

## 6. Prueba 3. Llamadas

Antes de llamar, cada quien revisa que su extensión esté en verde en Linphone.

| Prueba | Quién y qué hace | Debe pasar |
|---|---|---|
| **TEL-01** entre redes | **B** (José) marca `5002` y contesta el Celular 2. Después el Celular 2 marca `4001` | Audio en los dos sentidos |
| **TEL-02** laptop con laptop | **B** (José) marca `5001` y contesta **A** (Isaac) | Audio en los dos sentidos entre una laptop de Admin y una de Voz |
| **TEL-04** espera | **B** está en llamada con el Celular 2. Toca el botón de pausa y luego lo retoma | El Celular 2 escucha la música de CMH |
| **TEL-06** transferencia ciega | El Celular 2 marca `4001`. **B** toca *Transferir*, escribe `3001` y transfiere (o marca `##3001`) | El Celular 1 queda hablando con el Celular 2 |
| **TEL-07** transferencia atendida | El Celular 2 marca `4001`. **B** consulta a `3001`, avisa y completa (o marca `*2`) | El Celular 1 queda hablando con el Celular 2 |
| **TEL-08 y TEL-10** buzón | **B** marca `3001` y nadie contesta. Deja un mensaje. Después el Celular 1 marca `*97` y su PIN | Se escucha el mensaje |
| **TEL-11** IVR | El Celular 2 marca `7000`, escucha el menú y marca `4` | Bienvenida en español y suena la 4001 |

Opciones del IVR. 1 Recepción, 2 Consulta Externa, 3 Enfermería (3001), 4 Administración (4001), 0 operadora.

Mientras hay una llamada, **A** (Isaac) abre en el navegador:
```
http://127.0.0.1:18080/admin/config.php?display=asteriskinfo&module=peers
```
Ahí se ven las extensiones registradas con su IP 172.16.x.

---

## 7. Prueba 4. Reglas del router (ACL) a mano

Aquí se prueba que el router bloquea lo que debe bloquear. No se usa ningún script.

| # | Quién | Qué hace | Debe pasar |
|---|---|---|---|
| 1 | **C** (Regi) | Abre en el navegador `http://172.16.20.10` | Carga el login de la PBX. Desde Gestión sí se puede entrar |
| 2 | **B** (José) | Llama de `4001` a `5001` o a `5002` | Funciona. El router deja pasar el SIP y el audio |
| 3 | **B** (José) | Escribe `ping 172.16.20.10` | Sin respuesta |
| 4 | **B** (José) | Escribe `ping 172.16.20.2` (el AP) | Sin respuesta |
| 5 | **B** (José) | Abre en el navegador `http://172.16.20.10` | No carga |
| 6 | **B** (José) | Intenta entrar al router con Winbox, a `172.16.10.1` | No conecta |
| 7 | **Celular 1** | Abre en el navegador `http://172.16.20.10` | No carga. La web de la PBX solo se abre desde Gestión |

Ahora **C** (Regi) mira los contadores en Winbox.
```
/ip firewall filter print stats where comment~"^M[1-6]"
```
Debe verse así.
- **M2** y **M3** con paquetes. Son las llamadas entre Admin y la PBX.
- **M6** con paquetes. Son los pings y las páginas que se bloquearon.

**Decir.** Desde Admin se llega a la PBX solo para llamar. No se puede hacer ping, ni abrir su web, ni entrar al router. Esas puertas solo se abren desde Gestión.

---

## 8. Prueba 5. Invitados

**C** (Regi) cambia su cable de lugar un momento.

1. **C** saca el cable de ether3 y lo pone en **ether5**. Escribe `ipconfig /renew`.
2. Escribe `ipconfig | findstr IPv4`. Debe dar **172.16.40.1xx**.
3. Abre una página de internet. **Debe cargar.**
4. Escribe `ping 172.16.20.10`. **Debe fallar.**
5. Regresa el cable a **ether3** y escribe `ipconfig /renew`.
6. Vuelve a abrir Winbox por la MAC en *Neighbors*. Se había cerrado al cambiar de cable.

**Decir.** Los invitados tienen internet con velocidad limitada a 5 Mbps y no ven nada de la red interna.

---

## 9. Prueba 6. QoS con y sin prioridad

**Preparar.**

**A** (Isaac) abre dos PowerShell, una con cada servidor.
```powershell
iperf3 -s -p 5201
```
```powershell
iperf3 -s -p 5202
```

**C** (Regi) pega en Winbox, *New Terminal*.
```
/ip firewall filter enable [find comment~"^PRUEBA-QOS"]
/ip firewall mangle add chain=forward src-address-list=net-admin dst-address-list=iperf-srv protocol=udp dst-port=5202 action=change-dscp new-dscp=46 passthrough=yes comment="TEMP-PRUEBA-QOS: flujo de voz simulado -> EF" place-before=[find comment="QoS: marca INVITADOS"]
/queue tree reset-counters-all
```

### Ronda 1. Con QoS

1. **B** (José) y el **Celular 2** hacen una llamada `4001` ↔ `5002` y la ponen en altavoz.
2. **B** abre una PowerShell y satura el enlace.
   ```powershell
   iperf3 -c 172.16.20.20 -p 5201 -u -b 20M -t 75
   ```
3. A los 5 segundos, **B** abre una segunda PowerShell que imita la voz.
   ```powershell
   iperf3 -c 172.16.20.20 -p 5202 -u -b 69k -l 172 -t 60 -i 10
   ```
4. **C** mira las colas en Winbox.
   ```
   /queue tree print stats where name~"q-voz"
   ```

**Debe pasar.** La llamada se escucha limpia. La segunda PowerShell marca cerca de **0 % de pérdida**. La cola `q-voz-ef` no descarta paquetes.

### Ronda 2. Sin QoS

**C** pega en Winbox.
```
/queue tree disable [find comment="QOS-PRIO"]; /queue tree enable [find comment="QOS-FIFO"]; /queue tree reset-counters-all
```
Repetir los pasos 1 a 4 de la ronda 1.

**Debe pasar.** La llamada se corta o se escucha robótica y la pérdida sube. El 26 de octubre dio **9,4 %** y el límite del PDF es 1 %.

### Dejar el router como estaba

**C** pega en Winbox.
```
/queue tree disable [find comment="QOS-FIFO"]; /queue tree enable [find comment="QOS-PRIO"]
/ip firewall filter disable [find comment~"^PRUEBA-QOS"]
/ip firewall mangle remove [find comment~"TEMP-PRUEBA-QOS"]
```

**Decir.** El enlace de prueba se limitó a 2 Mbps para poder saturarlo. Con prioridad el router descarta la saturación y deja pasar la voz. Sin prioridad todo va a una sola cola y la voz se pierde junto con lo demás. El resultado del 26 de octubre está en `pruebas/resultados/qos-20261026.md`.

---

## 10. Prueba 7. Extras

### E1. Llamada desde red pública (8 puntos)

1. **Celular 2** (5002). **Apaga el Wi-Fi.** Deja los datos móviles, abre **Tailscale** y conéctalo.
2. En Linphone activa la cuenta 5002 con dominio `100.91.176.16`.
3. El 5002 marca `4001`. **B** contesta y hablan.
4. **A** abre en el navegador:
   ```
   http://127.0.0.1:18080/admin/config.php?display=asteriskinfo&module=peers
   ```
   La 5002 aparece con una IP **100.x**, la de Tailscale.

**Decir.** El celular está fuera de la red del centro médico. Entra por un túnel cifrado WireGuard sin abrir puertos en el router.

### E3. Troncal SIP con sip2sip (5 puntos)

**A** abre la troncal y su registro.
```
http://127.0.0.1:18080/admin/config.php?display=trunks
```
```
http://127.0.0.1:18080/admin/config.php?display=asteriskinfo&module=registries
```
Debe decir **Registered**.

**Llamada saliente.** **B** marca `9100`. Suena el celular que tiene la cuenta externa `cmh-orizonte-ext`.

**Llamada entrante.** Desde la cuenta `cmh-orizonte-ext` (con datos móviles) llamar a `cmh-horizonte@sip2sip.info`. Contesta el IVR del centro médico.

La ruta entrante se ve en:
```
http://127.0.0.1:18080/admin/config.php?display=did
```

### E4. Funciones avanzadas (4 puntos)

**Condición de horario.** El horario de atención es de lunes a viernes de 7:00 a 19:00 y el sábado de 7:00 a 12:00. Si la demostración es dentro de ese horario, el `7000` contesta el menú normal y hay que cerrar el changarro a mano.

**Cerrar el changarro.** **A** pega en PowerShell.
```powershell
ssh -t -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "sudo asterisk -rx 'database put TC 1 false_sticky'"
```
Después cualquiera marca `7000`. Contesta el menú de fuera de horario.

**Abrir otra vez.**
```powershell
ssh -t -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "sudo asterisk -rx 'database del TC 1'"
```

**Desde un teléfono.** Marcar `*271` cambia al estado contrario del que tiene. Si está abierto lo cierra y si está cerrado lo abre. Antes de cerrar, llamar al `7000` para saber en qué estado está.

Ruta web:
```
http://127.0.0.1:18080/admin/config.php?display=timeconditions
```

Si piden otra función.

| Función | Cómo | Ruta web |
|---|---|---|
| Música en espera | Ya se oyó en TEL-04 | `config.php?display=music` |
| Buzón por correo | **B** marca `3001`, nadie contesta y deja mensaje. Abrir el correo en el teléfono | `config.php?display=voicemail` |
| Escuchar el buzón | Desde 3001 marcar `*97` y el PIN | `config.php?display=asteriskinfo&module=voicemail` |
| Cola | Marcar `8010` (necesita 2001 y 2002 registradas) | `config.php?display=queues` |
| Grupo de timbrado | Marcar `8000` (necesita 1000 y 1001 registradas) | `config.php?display=ringgroups` |

---

## 11. Cierre

**Registro de llamadas.** **A** abre y toca **Search**.
```
http://127.0.0.1:18080/admin/config.php?display=cdr
```
Se ven todas las llamadas de la demostración con hora, origen, destino y duración.

**Al terminar, apagar la VM** antes de desconectar, para no dañar la base de datos. **A** pega en PowerShell.
```powershell
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" controlvm CMH-FreePBX acpipowerbutton
```

---

## Si algo falla

| Problema | Solución |
|---|---|
| Un teléfono no se registra después de varios intentos | **A** desbloquea su IP. `ssh -t -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "sudo fail2ban-client set asterisk-iptables unbanip IP_DEL_TELEFONO"` |
| La troncal no dice Registered | **A** pega `ssh -t -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "sudo asterisk -rx 'pjsip send register sip2sip'"` |
| La web de la PBX no abre | Esperar a que termine de arrancar la VM (4 minutos) |
| Una extensión no suena | Cada extensión admite un solo equipo a la vez. Revisar que no esté abierta en otro |
| Winbox no conecta | Elegir el router por su MAC en la pestaña *Neighbors*, no por IP |
| Una laptop no tiene la IP de su red | Escribir `ipconfig /renew` con el Wi-Fi apagado |
| No hay internet en el router | Revisar en el Xiaomi que siga activo el *Anclaje USB* |
| Una laptop avisa de otra salida a internet | Apagar su Wi-Fi y repetir |

La lista completa de pruebas con sus códigos está en `pruebas/MATRIZ-DE-PRUEBAS.md`.