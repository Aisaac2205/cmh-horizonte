# Escenarios de prueba para la demostración

Complemento de `PRUEBAS-ENTREGA.md`, que sigue siendo el guion principal con todos los comandos. Este archivo solo explica cómo repartir los equipos con 3 o con 4 laptops y cómo hacer la matriz de ACL a mano, sin ejecutar el script. Los pasos son los mismos en los dos escenarios y solo cambia quién prueba la VLAN de Invitados.

Datos que se usan en todos los pasos. La PBX está en `172.16.20.10`. El router es el hEX y su puerta de enlace en Gestión es `172.16.10.1`. El internet entra por el celular Android conectado al USB del hEX.

## Antes de empezar (10 minutos)

| Quién | Qué revisa |
|---|---|
| A (Isaac) | Encender la VM y esperar 4 minutos. Confirmar con el comando de la sección 0 de `PRUEBAS-ENTREGA.md` que 4001, 5001, 3001 y 5002 salen en Avail |
| A (Isaac) | Linphone 5001 en verde, web de la PBX abierta e iperf3 listo en dos PowerShell |
| B | Linphone con la extensión 4001 en verde |
| C | Winbox abierto, conectado al router por su MAC con el usuario `cmh-ti` |
| Celulares | Wi-Fi CMH-Voz y Linphone con la cuenta que apunta a `172.16.20.10` |
| Todos | Usar la contraseña correcta. Varios intentos fallidos bloquean el equipo por fail2ban |

## Escenario 1. Tres laptops

| Equipo | Dónde se conecta | Lleva abierto | Extensión |
|---|---|---|---|
| A (Isaac) | Cable al puerto LAN del AP (Voz) | VM, web de la PBX, Linphone, 2 PowerShell con iperf3 | 5001 |
| B | ether4 del hEX (Admin) | Linphone y PowerShell con iperf3 | 4001 |
| C | ether3 del hEX (Gestión) | Winbox | Ninguna |
| Celular 1 | Wi-Fi CMH-Voz | Linphone | 3001 |
| Celular 2 | Wi-Fi CMH-Voz | Linphone y Tailscale | 5002 |

La prueba de Invitados la hace C. Después de usar Winbox pasa su cable de ether3 a ether5, hace la prueba y lo regresa a ether3.

## Escenario 2. Cuatro laptops

Hace falta un cable de red más para ether5.

| Equipo | Dónde se conecta | Lleva abierto | Extensión |
|---|---|---|---|
| A (Isaac) | Cable al puerto LAN del AP (Voz) | VM, web de la PBX, Linphone, 2 PowerShell con iperf3 | 5001 |
| B | ether4 del hEX (Admin) | Linphone y PowerShell con iperf3 | 4001 |
| C | ether3 del hEX (Gestión) | Winbox | Ninguna |
| D | ether5 del hEX (Invitados) | Navegador y PowerShell | Ninguna |
| Celular 1 | Wi-Fi CMH-Voz | Linphone | 3001 |
| Celular 2 | Wi-Fi CMH-Voz | Linphone y Tailscale | 5002 |

La prueba de Invitados la hace D, y nadie mueve cables.

## Pasos (iguales en los dos escenarios)

### Paso 1. Llamadas y funciones de la PBX

| # | Quién | Qué hace | Debe pasar |
|---|---|---|---|
| 1.1 | A | Llama a 4001 | Suena en B y hay audio en los dos sentidos (llamada entre Voz y Admin) |
| 1.2 | B | Llama a 3001 | Suena en el celular 1 y hay audio en los dos sentidos |
| 1.3 | Celular 1 | Llama a 7000 | Contesta el menú de voz y recorre todas sus opciones |
| 1.4 | A | Llama a 3001, la pone en espera, la reanuda y la transfiere a 4001 | La llamada pasa a B. Ciega con `##` y atendida con `*2` |
| 1.5 | B | Llama a 3001 y nadie contesta | Entra el buzón. El celular 1 escucha el mensaje con `*97` |

### Paso 2. ACL a mano (sin script)

| # | Quién | Qué hace | Debe pasar |
|---|---|---|---|
| 2.1 | C | En Winbox entra a IP, Firewall, Filter Rules y pulsa Reset Counters. Abre `http://172.16.20.10` en el navegador | La web de la PBX carga |
| 2.2 | B | Ejecuta `ping 172.16.20.10` | Sin respuesta |
| 2.3 | B | Abre `http://172.16.20.10` en el navegador | No carga |
| 2.4 | B | Intenta entrar al router con Winbox | No conecta |
| 2.5 | B | Llama de 4001 a 5001 | Funciona, porque el SIP y el audio sí están permitidos |
| 2.6 | Celular 1 | Abre `http://172.16.20.10` en el navegador | No carga |
| 2.7 | C | Mira los contadores en Winbox | Las reglas M2 y M3 subieron por la llamada y la M6 por el ping bloqueado |

### Paso 3. Invitados

| Escenario | Quién | Qué hace | Debe pasar |
|---|---|---|---|
| 1 | C | Pasa el cable a ether5, abre una página de internet y hace `ping 172.16.20.10`. Después regresa a ether3 | Internet carga y el ping a la PBX falla |
| 2 | D | Abre una página de internet y hace `ping 172.16.20.10` | Internet carga y el ping a la PBX falla |

### Paso 4. QoS

Se sigue la sección 5 de `PRUEBAS-ENTREGA.md`. El reparto es el siguiente.

| Quién | Qué hace |
|---|---|
| B y celular 2 | Mantienen una llamada activa entre 4001 y 5002, en altavoz |
| B | Satura el enlace con iperf3 hacia la laptop A y lanza la segunda terminal que imita la voz |
| C | Prepara y cambia las colas en Winbox entre con QoS y sin QoS |
| A | Tiene los dos servidores de iperf3 encendidos |

Debe pasar. Con QoS la llamada se oye limpia y la pérdida de voz queda cerca de 0 %. Sin QoS la llamada se corta. La medición del 26 de octubre quedó en `pruebas/resultados/qos-20261026.md` (0 % con QoS contra 9,4 % sin QoS).

### Paso 5. Extras

| # | Quién | Qué hace | Debe pasar |
|---|---|---|---|
| 5.1 | Celular 2 | Apaga el Wi-Fi, usa solo datos móviles con Tailscale activo y la cuenta de Linphone con dominio `100.91.176.16`. Llama a 5001 | Suena en la laptop A con audio en los dos sentidos (E1) |
| 5.2 | A | Muestra en la web de la PBX la troncal SIP, los ring groups, la cola, el horario, la grabación y el buzón a correo | Todo configurado, sin repetir las pruebas (E3 y E4) |

## Si algo falla

| Síntoma | Qué hacer |
|---|---|
| Linphone en rojo | Revisar usuario, contraseña y dominio. Si siguen mal, la PBX bloquea el equipo |
| Equipo bloqueado por fail2ban | A usa el comando de desbloqueo de la tabla "Si algo falla" de `PRUEBAS-ENTREGA.md` |
| Una extensión no suena | Solo admite un dispositivo a la vez. Revisar que no esté registrada en otro equipo |
| Winbox no conecta en ether3 | Entrar por la MAC en la pestaña Neighbors, no por IP |

## Respaldo opcional

El script `Probar-Vlan.ps1` no se ejecuta frente al catedrático. Conviene correrlo una vez antes de la demostración para confirmar que todo da Cumple, y guardar su informe por si hace falta.