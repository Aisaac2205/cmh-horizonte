# GUÍA DEMO · Documentación de lo realizado
**Centro Médico Horizonte, S.A. · PF-TEL-001-2026**
Última actualización: 19/10/2026

Registro visual de todo lo configurado en el proyecto, para el equipo y para la defensa. Cada captura indica su ruta dentro del sistema y explica qué se hizo y por qué. El avance se agrega por componente.

| Componente | Estado | Sección |
|---|---|---|
| PBX FreePBX en máquina virtual | Configurada y probada con llamadas reales | 2 a 7 |
| Router MikroTik RB750Gr3 (hEX) | Pendiente de configurar | 8 |
| Punto de acceso Mercusys MW325R | Pendiente de configurar | 9 |

> Las capturas están en la carpeta `capturas/` y no muestran contraseñas. Para verlas dentro de este documento se recomienda un visor de Markdown, por ejemplo GitHub o VS Code (**Ctrl+Shift+V**). Las extensiones de cada integrante y las pruebas por persona están en `GUIA-CELULARES.md`.

---

## 1. La solución en breve

| Elemento | Valor |
|---|---|
| Plataforma | FreePBX 17.0.33 y Asterisk 22.11 sobre Debian 12.15, en VirtualBox |
| Nombre del sistema | `CMH-PBX Centro Medico Horizonte` |
| Extensiones | 9, de 4 dígitos, numeradas por área (1xxx Recepción, 2xxx Consulta Externa, 3xxx Enfermería y Emergencias, 4xxx Administración, 5xxx TI) |
| Números especiales | 7000 IVR, 8000 grupo de Recepción, 8010 cola de Consulta Externa |
| IP de la PBX con el router | 192.168.20.10 (VLAN 20, Voz) |
| IP de la PBX por Tailscale | 100.91.176.16, fija desde cualquier red |
| Idioma | Español latino (`es_419`), con respaldo en español estándar |

---

## 2. Plataforma de la PBX (criterio C)

**Figura 1. Panel principal.** Ruta: *Dashboard*

![Dashboard con la versión de FreePBX y los servicios en verde](capturas/01-dashboard.png)

> **Qué se hizo.** Es la pantalla de inicio después de entrar. Arriba se ve el nombre asignado al sistema (*CMH-PBX Centro Medico Horizonte*) y la versión, FreePBX 17.0.33.2. En la lista de servicios, Asterisk, la base de datos, el servidor web, fail2ban y el firewall están en verde, es decir, la PBX está en funcionamiento. Abajo se ve el tráfico de las dos tarjetas de red de la VM (`enp0s3` para teléfonos y `enp0s8` para administración).

**Figura 2. Extensiones.** Ruta: *Connectivity → Extensions*

![Lista de las 9 extensiones](capturas/02-extensiones.png)

> **Qué se hizo.** Se crearon las 9 extensiones del plan de numeración, una por puesto de trabajo. El primer dígito indica el área. Todas son de tipo **pjsip**, el protocolo SIP actual de Asterisk, y tienen la llamada en espera activa (columna CW). Cada una tiene una contraseña aleatoria de 32 caracteres, distinta de las demás.

**Figura 3. Opciones avanzadas de una extensión.** Ruta: *Connectivity → Extensions → 1000 → Advanced*

![Extensión 1000 con Direct Media en No](capturas/03-ext1000-avanzado.png)

> **Qué se hizo.** Se configuró **Direct Media en No** en las 9 extensiones. Así el audio de las llamadas siempre pasa por la PBX en lugar de ir directo entre teléfonos. Esto permite que el audio cruce el router y reciba la prioridad de QoS, y que las llamadas funcionen aunque haya NAT de por medio.

**Figura 4. Ajustes SIP.** Ruta: *Settings → Asterisk SIP Settings*

![Ajustes SIP con redes locales y rango RTP](capturas/04-ajustes-sip.png)

> **Qué se hizo.** Se dejaron en **No** las llamadas anónimas y los invitados, para que nadie use la PBX sin usuario y contraseña. En *Local Networks* se declararon las redes del proyecto (192.168.0.0/16 para las VLAN, 100.64.0.0/10 para Tailscale y 172.16.0.0/12 para pruebas), así Asterisk identifica qué teléfonos están en la red interna. Abajo está el rango de puertos del audio (RTP 10000 a 20000), el mismo que usan las reglas del router. Los códecs habilitados son ulaw, alaw, g722 y opus.

---

## 3. Funcionalidades de telefonía (criterio D)

**Figura 5. Códigos de transferencia y llamada en espera.** Ruta: *Admin → Feature Codes*

![Códigos de servicio de transferencia y llamada en espera](capturas/05a-codigos-transferencia.png)

> **Qué se hizo.** Se verificó que estén activos los códigos de servicio, que son números que empiezan con `*` o `#` y activan funciones desde el teléfono. Llamada en espera **\*70** (activar) y **\*71** (desactivar). En la sección *Core*, **##** para la transferencia ciega y **\*2** para la atendida. Empiezan con símbolos para no chocar con las extensiones de 4 dígitos.

**Figura 6. Prueba de eco y acceso al IVR.** Ruta: *Admin → Feature Codes*

![Códigos de eco y del número 7000](capturas/05b-codigos-eco-y-servicios.png)

> **Qué se hizo.** **\*43** es la prueba de eco, donde quien llama escucha su propia voz y se comprueba el audio. **7000** es el número interno para entrar al IVR.

**Figura 7. Códigos de horario y buzón.** Ruta: *Admin → Feature Codes*

![Códigos del horario y del buzón](capturas/05c-codigos-horario-y-buzon.png)

> **Qué se hizo.** **\*271** cambia a mano el modo de horario (normal o fuera de horario) y se usa en la demostración. **\*97** entra al buzón de la propia extensión y **\*98** a cualquier buzón, con su número y su PIN.

**Figura 8. Grabaciones del sistema.** Ruta: *Admin → System Recordings*

![Las 4 grabaciones en español](capturas/06-grabaciones-sistema.png)

> **Qué se hizo.** Se cargaron 4 locuciones en español: bienvenida del IVR, opción no válida, mensaje de fuera de horario y aviso de grabación de la llamada. Se generaron con la voz de Windows *Sabina* (español de México), en formato telefónico de 8 kHz. Pueden reemplazarse por voz humana grabando desde un teléfono con los mismos nombres.

**Figura 9. Menú de voz principal.** Ruta: *Applications → IVR → IVR-Principal*

![Configuración del IVR principal](capturas/07-ivr-principal.png)

> **Qué se hizo.** Se creó el IVR con la bienvenida como anuncio, **7 segundos** para marcar y hasta **2 intentos** ante una opción no válida. Si la persona se equivoca dos veces o no marca, la llamada pasa a la **operadora (1000)**. Opciones: 1 Recepción (grupo 8000), 2 Consulta Externa (cola 8010), 3 Enfermería (3001), 4 Administración (4001) y 0 operadora. Cumple §5.4 del PDF: tres o más opciones, operadora, opción inválida y falta de respuesta.

**Figura 10. Número interno del IVR.** Ruta: *Applications → Misc Applications*

![Número 7000](capturas/12-numero-7000.png)

> **Qué se hizo.** Se creó el número **7000** para llegar al IVR desde cualquier extensión. Apunta a la condición de horario (figura 15), que decide qué IVR contesta según la hora.

**Figura 11. Idiomas del sistema.** Ruta: *Admin → Sound Languages*

![Paquetes de idioma instalados](capturas/14-idiomas.png)

> **Qué se hizo.** Se instalaron los sonidos del sistema en español, que son los mensajes que la PBX dice por su cuenta (por ejemplo "deje su mensaje después del tono" y los números). Quedó **español latino (es_419)** como idioma principal y el español estándar (es) como respaldo, porque al paquete latino le faltan algunos audios.

**Buzones de voz (sin captura).** Las extensiones 1000, 2001, 3001 y 4001 tienen buzón con PIN propio y **saludo personalizado** de no disponible, de ocupado y de nombre, en la misma voz del IVR. Si nadie contesta en 20 segundos, o la extensión está ocupada, la llamada pasa al buzón. Los mensajes se escuchan con \*97.

---

## 4. Funciones avanzadas, extra E4

**Figura 12. Grupo de timbrado de Recepción.** Ruta: *Applications → Ring Groups → 8000*

![Grupo de timbrado 8000](capturas/08-grupo-8000.png)

> **Qué se hizo.** Se creó el grupo **8000 (Recepción)** con las extensiones **1000 y 1001**. La estrategia *ringall* hace que suenen las dos a la vez y la primera que contesta toma la llamada. Si nadie contesta en **20 segundos**, la llamada va al buzón de la 1000. Es la opción 1 del IVR.

**Figura 13. Cola de Consulta Externa.** Ruta: *Applications → Queues → 8010*

![Cola 8010](capturas/09-cola-8010.png)

> **Qué se hizo.** Se creó la cola **8010 (Consulta Externa)** con las extensiones 2001 y 2002 como agentes. La estrategia **rrmemory** reparte las llamadas por turnos y recuerda a quién le tocó la última, así la carga queda pareja entre las dos clínicas. Al entrar se escucha el aviso de grabación, se anuncia la posición en la fila cada 30 segundos y suena la música propia (**CMH**). Después de 2 minutos sin respuesta, la llamada pasa al buzón. Es la opción 2 del IVR.

**Figura 14. Horario de atención.** Ruta: *Applications → Time Groups → Horario-Atencion*

![Grupo horario](capturas/10-grupo-horario.png)

> **Qué se hizo.** Se definió el horario de atención del centro médico, **lunes a viernes de 7:00 a 19:00** y **sábado de 7:00 a 12:00**.

**Figura 15. Condición de horario.** Ruta: *Applications → Time Conditions → TC-Horario*

![Condición de horario TC-Horario](capturas/11-condicion-horaria.png)

> **Qué se hizo.** Se creó la condición **TC-Horario**, con zona horaria de Guatemala. Dentro del horario de la figura 14 contesta el **IVR-Principal**. Fuera de ese horario contesta el **IVR-FueraHorario**, que solo ofrece Emergencias (3, Enfermería) o dejar un mensaje (1). El código **\*271** cambia el modo a mano para la demostración.

**Figura 16. Música en espera propia.** Ruta: *Settings → Music on Hold → CMH*

![Categoría de música CMH](capturas/13-musica-cmh.png)

> **Qué se hizo.** Se creó la categoría **CMH** con la pista `moh-cmh-tema1`, compuesta con código para el proyecto. Es original, así que no tiene problemas de derechos de autor. Suena en la cola 8010.

**Figura 17. Grabación de llamadas.** Ruta: *Connectivity → Extensions → 1000 → Advanced → Recording Options*

![Grabación forzada en la extensión 1000](capturas/03b-ext1000-grabacion.png)

> **Qué se hizo.** En la extensión 1000 (Recepción) se configuró la grabación en **Force** para todas las llamadas, entrantes y salientes, internas y externas. Las grabaciones solo se escuchan desde la administración web, que está restringida a la red de Gestión. Así se cumple el acceso restringido que pide E4.

**Figura 18. Registro de llamadas.** Ruta: *Reports → CDR Reports*

![Registro de llamadas de prueba](capturas/21-cdr-tabla.png)

> **Qué se hizo.** El CDR registra cada llamada con fecha, hora, origen (*CallerID*), destino (*App* y *Destination*), si se contestó (*ANSWERED*) y su duración. Aquí se ven las primeras llamadas de prueba del 17/10 desde un celular (extensión 2001) al IVR. Es la evidencia de llamadas para el informe y la matriz de pruebas. Las llamadas de la 1000 incluyen el botón para escuchar la grabación.

**Pendiente de E4.** Notificación de mensajes de buzón por correo, con la cuenta de Google del proyecto.

---

## 5. Seguridad de la PBX (§5.8)

**Figura 19. Redes de confianza del firewall.** Ruta: *Connectivity → Firewall → Networks*

![Redes Trusted y Local](capturas/15-firewall-redes.png)

> **Qué se hizo.** Se activó el firewall de FreePBX y se definieron las redes de confianza. En **Trusted** (acceso total) quedaron la laptop que administra la VM (10.0.2.2) y la VLAN 10 de Gestión. En **Local** (solo teléfonos) quedaron la VLAN 20 de Voz, la VLAN 30 Administrativa, Tailscale y las redes de prueba. Cualquier otra red cae en la zona *Internet*, sin acceso.

**Figura 20. Servicios permitidos por zona.** Ruta: *Connectivity → Firewall → Services*

![Servicios por zona](capturas/17-firewall-servicios.png)

> **Qué se hizo.** **SSH** y la **web de administración** no tienen ninguna zona marcada, así que solo se usan desde las redes *Trusted*. **SIP** está marcado solo en **Local**, para que los teléfonos puedan registrarse. Los demás servicios quedaron cerrados porque no se usan.

**Figura 21. Responsive Firewall.** Ruta: *Connectivity → Firewall → Responsive Firewall*

![Responsive Firewall activo con SIP en Disabled](capturas/16-firewall-responsive.png)

> **Qué se hizo.** El *Responsive Firewall* está activo, con **SIP (pjsip) en Disabled**. El SIP que llega desde redes no confiables se rechaza siempre, sin darle intentos. Es la opción más estricta y no afecta a los teléfonos, porque todos entran por redes *Local*. Contra intentos repetidos de contraseña actúa **fail2ban**, que bloquea 30 minutos al equipo que falla 5 veces en 10 minutos.

**Figura 22. Contraseñas débiles.** Ruta: *Reports → Weak Password Detection*

![Sin contraseñas débiles](capturas/19-claves-debiles.png)

> **Qué se hizo.** El revisor de FreePBX indica *No weak secrets detected*. Ninguna extensión tiene una contraseña débil. Además, el administrador web no se llama `admin` y las contraseñas de Linux que traía la VM base se cambiaron.

**Figura 23. Respaldos automáticos.** Ruta: *Admin → Backup & Restore*

![Tarea de respaldo diaria](capturas/18-respaldos.png)

> **Qué se hizo.** Se creó la tarea **CMH-diario**, que guarda toda la configuración de FreePBX cada día a las 2:00 y conserva los últimos 7. Además se exportó la VM completa en un archivo `.ova` como respaldo para la demostración.

---

## 6. Teléfonos registrados (criterio E)

**Figura 24. Estado de las extensiones.** Ruta: *Reports → Asterisk Info → PJSIP*

![Estado de los teléfonos en Asterisk](capturas/20-telefonos-registrados.png)

> **Qué se hizo.** Es el estado de los teléfonos visto desde Asterisk. Cada *Endpoint* es una extensión. Un teléfono conectado aparece con una línea *Contact*, su IP y el estado **Avail**, como la 1000 de esta captura (MicroSIP en la laptop). Las que dicen *Unavailable* no tienen un teléfono registrado en ese momento. En la demostración se muestran al menos 4 en *Avail*, con una laptop y un celular.

Los teléfonos usados son **MicroSIP** en laptop y **Linphone** en celulares. La asignación por integrante está en `GUIA-CELULARES.md`.

---

## 7. Acceso desde una red pública, extra E1

**Cómo funciona.** El PDF pide que un teléfono **fuera de la red del centro médico** pueda llamar a la PBX (§6.1). Se usó **Tailscale**, una VPN que crea un túnel cifrado (WireGuard) entre el celular y la PBX. No requiere abrir puertos en el router y funciona aunque el proveedor de internet use CGNAT.

| Equipo | IP en Tailscale |
|---|---|
| PBX (`cmh-pbx`) | 100.91.176.16 |
| iPhone de prueba (extensión 5002) | 100.68.20.81 |

**Figura 25. Interfaz de Tailscale en el firewall.** Ruta: *Connectivity → Firewall → Interfaces*

![tailscale0 en zona Local](capturas/22-e1-firewall-interfaces.png)

> **Qué se hizo.** Al activar Tailscale apareció en la VM la tarjeta `tailscale0`, con la IP 100.91.176.16. Se le asignó la zona **Local**. Los teléfonos que llegan por el túnel pueden usar **SIP**, pero no la web de administración ni el SSH.

**Figura 26. Redes con Tailscale y pruebas.** Ruta: *Connectivity → Firewall → Networks*

![Redes de Tailscale y de prueba](capturas/23-e1-firewall-redes.png)

> **Qué se hizo.** La red de Tailscale (**100.64.0.0/10**) está en zona Local. Se agregó también la red **192.168.1.0/24** para pruebas fuera del router. Con el router instalado, los teléfonos entran por las VLAN 20 y 30, que ya están en la lista.

**Figura 27. Llamada de prueba desde datos móviles.** Ruta: *Reports → CDR Reports*

![Llamada desde la 5002 por Tailscale](capturas/24-e1-cdr-5002.png)

> **Qué se hizo.** La primera fila es la prueba de E1 del 19/10 a las 9:54. El iPhone, **solo con datos móviles** y con Tailscale activo, se registró como la extensión **5002 (TI Remoto)** y llamó a la **1000** (MicroSIP en la laptop). La llamada se contestó y duró 40 segundos con audio en los dos sentidos. El retardo medido fue de 157 a 201 ms, propio de la red celular más el túnel.

---

## 8. Router MikroTik RB750Gr3 (hEX)

*Pendiente.* Esta sección documentará, con capturas de Winbox, las VLAN 10, 20, 30 y 40, el direccionamiento y DHCP por VLAN, la matriz de reglas entre VLAN, el NAT con SIP ALG desactivado y la QoS con sus mediciones con y sin priorización.

## 9. Punto de acceso Mercusys MW325R

*Pendiente.* Esta sección documentará la configuración del Wi-Fi para los celulares en la VLAN de Voz.

---

## 10. Cumplimiento del PDF

| Sección del PDF | Requisito | Cómo se cumple | Figuras |
|---|---|---|---|
| 5.3 | PBX operativa con versiones documentadas | FreePBX 17.0.33.2 y Asterisk 22.11.0 en Debian 12.15 | 1 |
| 5.3 | Al menos 5 extensiones con contraseñas robustas | 9 extensiones con secretos aleatorios de 32 caracteres | 2, 22 |
| 5.3 | Códecs justificados | ulaw, alaw, g722 y opus. G.711 usa unos 87 kbps por sentido con Ethernet | 4 |
| 5.3 | Registro de eventos | CDR con cada llamada y su grabación | 18, 27 |
| 5.3 | Administración solo desde la red de gestión | Web y SSH solo para redes Trusted | 19, 20 |
| 5.4 | Llamada en espera y transferencias | \*70, \*71, ## y \*2 activos en todas las extensiones | 5 |
| 5.4 | Buzón en al menos 2 extensiones | 4 buzones con PIN propio y saludo personalizado | 7 |
| 5.4 | IVR en español con 3 o más opciones, operadora, inválida y sin respuesta | IVR-Principal con 4 opciones y 0, dos reintentos y paso a la operadora | 8, 9, 10 |
| 5.8 | Sin credenciales predeterminadas | Contraseñas nuevas en Linux y FreePBX, sin usuario `admin` | 22 |
| 5.8 | Firewall y protección contra intentos repetidos | Firewall por zonas, SIP cerrado a redes no confiables y fail2ban | 19, 20, 21 |
| 5.8 | Respaldos | Respaldo diario y VM exportada | 23 |
| 6.1 | E1, acceso desde una red pública | Tailscale y llamada desde datos móviles | 25, 26, 27 |
| 6.4 | E4, funciones avanzadas (mínimo 2) | Grupo y cola, horario, música propia y grabación (4 de 5) | 12 a 17 |

---

## 11. Registro de avance

| Fecha | Avance |
|---|---|
| 16/10 | VM base con Debian 12.15 y FreePBX 17 lista |
| 17/10 | Acceso seguro a la VM y contraseñas nuevas. Asistente inicial, ajustes SIP, 9 extensiones con buzones, firewall y fail2ban. Idioma español latino, audios, IVR y número 7000. Respaldo diario |
| 17/10 | Primeros teléfonos registrados (MicroSIP y Linphone) y primera llamada real al IVR |
| 17/10 | E4: grupo 8000, cola 8010, horarios, grabación y música propia. Saludos de los 4 buzones |
| 19/10 | VM completa exportada en `.ova`. E1 con Tailscale y llamada desde datos móviles |
| 19/10 | Asignación de extensiones por integrante y guion de pruebas (`GUIA-CELULARES.md`) |
