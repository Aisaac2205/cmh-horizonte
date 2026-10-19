# GUÍA DEMO · Arrancar la PBX y mostrar lo realizado
**Centro Médico Horizonte, S.A. · PF-TEL-001-2026**
Última actualización: 19/10/2026

Esta guía sirve para **encender la máquina virtual, entrar a FreePBX y recorrer todo lo que ya está configurado**. Sirve para revisar el trabajo en grupo y para la demostración ante el catedrático. Cómo se hizo cada cosa está en `CONFIG.md`. Las contraseñas están en `CREDENCIALES-ACTUALES.md`.

> Los nombres de menú de esta guía se tomaron del propio FreePBX instalado (17.0.33), así que coinciden con lo que se ve en pantalla.
>
> Las **capturas** de la sección 4 están en la carpeta `capturas\` (tomadas el 17/10/2026, sin contraseñas visibles). Para verlas dentro de la guía, abre este archivo con un visor de Markdown, por ejemplo VS Code con **Ctrl+Shift+V**.

---

## 1. Antes de empezar

| Necesitas | Dónde está o para qué |
|---|---|
| La laptop host con VirtualBox 7.2.20 | Ya instalado |
| La VM `CMH-FreePBX` | Lista en VirtualBox |
| La contraseña del usuario web `cmh-ti` | `CREDENCIALES-ACTUALES.md` (empieza con **Z mayúscula**) |
| La laptop conectada por **Wi-Fi** (casa u hotspot) | Solo para que los teléfonos lleguen a la PBX. La administración funciona igual sin red |
| MicroSIP abierto en la laptop (ext. 1000) y Linphone en el celular (ext. 2001) | Solo para las pruebas con llamadas |

> La VM usa el **Wi-Fi** de la laptop (adaptador en puente). Si la laptop está solo por cable, los teléfonos no se registran hasta el día del router, cuando el puente pasa a la tarjeta Ethernet (`CONFIG.md`, Paso 16).

---

## 2. Encender la máquina virtual

1. Abre **VirtualBox**.
2. Selecciona **CMH-FreePBX** y haz clic en **Start** (flecha verde). Si no quieres ver la ventana negra, usa la flechita junto a Start y elige **Headless Start**.
3. Espera **unos 2 minutos**. Si abriste la ventana, al final aparece `cmh-pbx login:`. No hace falta iniciar sesión ahí.
4. Abre el navegador en **http://127.0.0.1:18080/admin**. Si todavía no carga, espera otro minuto.

Lo mismo desde PowerShell:
```powershell
& "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" startvm CMH-FreePBX --type headless
```

> **Modo seguro del firewall.** Durante los **primeros 5 minutos** después de encender, el firewall de FreePBX todavía no aplica sus reglas. Es una protección normal contra bloqueos. Si vas a mostrar que el firewall bloquea la web, espera a que pasen.

**IP de la PBX para los teléfonos.** Cambia según la red de la laptop. En el hotspot del iPhone ha sido `172.20.10.7`. Para verla en cualquier momento:
```powershell
ssh -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1 "ip -br -4 addr show enp0s3"
```
Si la IP cambió, hay que ponerla como servidor y dominio en MicroSIP y en Linphone.

---

## 3. Entrar a FreePBX

1. En **http://127.0.0.1:18080/admin**, clic en **FreePBX Administration**.
2. Usuario **`cmh-ti`** y su contraseña.
3. Se abre el **Dashboard**.

**Por qué `127.0.0.1:18080` y no la IP de la PBX.** La administración solo se permite desde la red de Gestión (VLAN 10) o desde el **puerto interno de gestión** de la VM, que solo existe dentro de la laptop host. Desde la red de los teléfonos la web está **bloqueada a propósito** por el firewall (requisito 5.3 del PDF).

> Si aparece *"Potential Security Breach"*, es porque se escribió a mano una dirección con `&action=...`. Navegando con los menús y botones de FreePBX no pasa.

**Menús principales:**

| Menú | Qué hay ahí |
|---|---|
| **Applications** | IVR, grupos de timbrado, colas, horarios y el número 7000 (Misc Applications) |
| **Connectivity** | Extensiones y firewall |
| **Admin** | Grabaciones del sistema, idiomas, respaldos, códigos de servicio y la consola de Asterisk |
| **Reports** | Registro de llamadas (CDR), grabaciones, estado de Asterisk, registros del sistema y contraseñas débiles |
| **Settings** | Ajustes SIP, música en espera y configuración avanzada |

---

## 4. Recorrido para mostrar lo realizado

Orden sugerido para la demostración, unos 8 a 10 minutos. Cada fila dice **dónde ir**, **qué mostrar** y **qué explicar**.

### 4.1 La plataforma (criterio C)
| Dónde | Qué mostrar | Qué explicar |
|---|---|---|
| **Dashboard** | Versión de FreePBX y servicios en verde | FreePBX 17.0.33 con Asterisk 22.11 sobre Debian 12.15, en una VM local (modalidad Stand-alone) |
| **Connectivity → Extensions** | Las 9 extensiones, de la 1000 a la 5002 | Plan de 4 dígitos por área. 1xxx Recepción, 2xxx Consulta Externa, 3xxx Enfermería y Emergencias, 4xxx Administración, 5xxx TI |
| Abrir la **1000**, pestaña **Advanced** | *Direct Media* en No y *Call Waiting* activo | El audio pasa por la PBX para atravesar la QoS del router y funcionar con NAT |
| La misma 1000, pestaña **General** | El campo *Secret* (sin mostrar el valor) | Contraseñas aleatorias de 32 caracteres, una distinta por extensión |
| **Settings → Asterisk SIP Settings** | Códecs ulaw, alaw, g722 y opus, redes locales, RTP 10000 a 20000 | G.711 usa unos 87 kbps por sentido con Ethernet (cálculo en el archivo 01 del plan, §5) |

**Figura 1.** Dashboard con la versión de FreePBX y los servicios en verde

![Dashboard con la versión de FreePBX y los servicios en verde](capturas/01-dashboard.png)

> **Qué se hizo.** Es la pantalla de inicio después de entrar. Arriba a la izquierda se ve el nombre que le pusimos al sistema (*CMH-PBX Centro Medico Horizonte*) y la versión, FreePBX 17.0.33.2. En la lista de servicios, Asterisk, la base de datos, el servidor web, fail2ban y el firewall están en verde, o sea que la PBX está funcionando. A la izquierda abajo se ve el tráfico de las dos tarjetas de red de la VM (`enp0s3` para teléfonos y `enp0s8` para administración).

**Figura 2.** Connectivity → Extensions con las 9 extensiones

![Connectivity → Extensions con las 9 extensiones](capturas/02-extensiones.png)

> **Qué se hizo.** Aquí se crearon las 9 extensiones del plan de numeración, una por puesto de trabajo. El primer dígito indica el área: 1 Recepción, 2 Consulta Externa, 3 Enfermería y Emergencias, 4 Administración y 5 TI. Todas son de tipo **pjsip** (el protocolo SIP moderno de Asterisk) y tienen la llamada en espera activa (columna CW marcada).

**Figura 3.** Extensión 1000, pestaña Advanced, con Direct Media en No

![Extensión 1000, pestaña Advanced, con Direct Media en No](capturas/03-ext1000-avanzado.png)

> **Qué se hizo.** Dentro de la extensión 1000, en la pestaña *Advanced*, se puso **Direct Media en No**. Así el audio de las llamadas siempre pasa por la PBX en lugar de ir directo entre teléfonos. Lo hicimos para que el audio cruce el router y le aplique la QoS, y para que funcione aunque haya NAT de por medio. Se hizo igual en las 9 extensiones.

**Figura 4.** Asterisk SIP Settings con las redes locales y el rango RTP

![Asterisk SIP Settings con las redes locales y el rango RTP](capturas/04-ajustes-sip.png)

> **Qué se hizo.** Son los ajustes SIP generales. Arriba se dejaron en **No** las llamadas anónimas y los invitados, para que nadie use la PBX sin usuario y contraseña. En *Local Networks* se agregaron las redes del proyecto (192.168.0.0/16 para las VLAN, 100.64.0.0/10 para Tailscale y 172.16.0.0/12 para pruebas con hotspot), así Asterisk sabe qué teléfonos están en la red interna. Abajo está el rango de puertos del audio (RTP 10000 a 20000), el mismo que usan las reglas del router.

### 4.2 Funcionalidades obligatorias (criterio D, el de más peso)
| Dónde | Qué mostrar | Qué explicar |
|---|---|---|
| **Admin → Feature Codes** | \*97, \*98, \*43, ## (transferencia ciega), \*2 (atendida), \*70 y \*71 | Los códigos de servicio empiezan con `*`, así no chocan con las extensiones |
| **Admin → System Recordings** | Las 4 grabaciones | Locución en español generada con la voz de Windows. Se puede reemplazar por voz humana con los mismos nombres |
| **Applications → IVR → IVR-Principal** | Bienvenida, opciones 1 a 4 y 0, 2 reintentos, sin respuesta a la operadora | Cumple §5.4 del PDF. Tres o más opciones, operadora, opción inválida y falta de respuesta |
| **Applications → Misc Applications** | 7000 apunta a TC-Horario | Número interno para llegar al IVR |
| Extensión **1000**, pestaña **Voicemail** | Buzón activo con PIN | Hay buzón en 1000, 2001, 3001 y 4001, cada uno con su PIN |
| **Admin → Sound Languages** | Español latino (`es_419`) por defecto | Si al paquete latino le falta un audio (por ejemplo los números), Asterisk lo toma del español estándar |

**Figura 5.** Feature Codes, sección Core: ## transferencia ciega y *2 atendida (abajo) y llamada en espera *70 y *71

![Feature Codes, sección Core: ## transferencia ciega y *2 atendida (abajo) y llamada en espera *70 y *71](capturas/05a-codigos-transferencia.png)

> **Qué se hizo.** Son los *códigos de servicio*, números que empiezan con `*` o `#` y activan funciones desde el teléfono. Aquí se revisó que estén activos los de llamada en espera (**\*70** activa y **\*71** desactiva) y, en la sección *Core*, los de transferencia: **##** para la transferencia ciega y **\*2** para la atendida. Empiezan con símbolos para que no choquen con las extensiones de 4 dígitos.

**Figura 6.** Feature Codes: *43 prueba de eco y 7000 del IVR

![Feature Codes: *43 prueba de eco y 7000 del IVR](capturas/05b-codigos-eco-y-servicios.png)

> **Qué se hizo.** Sigue la lista de códigos. Aquí se ven **\*43**, la prueba de eco (uno habla y se escucha a sí mismo, sirve para revisar el audio), y el **7000**, que es el número interno para entrar al IVR.

**Figura 7.** Feature Codes: *271 del horario y *97 y *98 del buzón

![Feature Codes: *271 del horario y *97 y *98 del buzón](capturas/05c-codigos-horario-y-buzon.png)

> **Qué se hizo.** Final de la lista de códigos. **\*271** cambia a mano el modo de horario (normal o fuera de horario), y sirve para la demostración. **\*97** entra al buzón de la propia extensión y **\*98** a cualquier buzón, pidiendo el número y su PIN.

**Figura 8.** Admin → System Recordings con las 4 grabaciones en español

![Admin → System Recordings con las 4 grabaciones en español](capturas/06-grabaciones-sistema.png)

> **Qué se hizo.** Son los 4 audios que se subieron a FreePBX: la bienvenida del IVR, el aviso de opción no válida, el mensaje de fuera de horario y el aviso de que la llamada puede ser grabada. Se generaron en español con la voz de Windows y están en idioma *Spanish*. Si el grupo prefiere voz humana, se pueden regrabar desde un teléfono con los mismos nombres.

**Figura 9.** Applications → IVR → IVR-Principal

![Applications → IVR → IVR-Principal](capturas/07-ivr-principal.png)

> **Qué se hizo.** Es el menú de voz principal. Se eligió la grabación de bienvenida como anuncio, se dejan **7 segundos** para marcar y hasta **2 intentos** si se marca una opción no válida. Si la persona se equivoca dos veces o no marca nada, la llamada pasa a la **extensión 1000 (Operadora)**. Más abajo en la misma página están las opciones: 1 Recepción, 2 Consulta Externa, 3 Enfermería, 4 Administración y 0 Operadora.

**Figura 10.** Applications → Misc Applications con el número 7000

![Applications → Misc Applications con el número 7000](capturas/12-numero-7000.png)

> **Qué se hizo.** Aquí se creó el número **7000** para entrar al IVR desde cualquier extensión. Apunta a la condición de horario (figura 15), que decide qué IVR contesta según la hora.

**Figura 11.** Admin → Sound Languages con español (es) y español latino (es_419)

![Admin → Sound Languages con español (es) y español latino (es_419)](capturas/14-idiomas.png)

> **Qué se hizo.** Se instalaron los sonidos del sistema en español, que son los mensajes que dice la PBX por su cuenta ("deje su mensaje después del tono", los números, etc.). Quedó **español latino (es_419)** como idioma principal y el español estándar (es) como respaldo, porque al paquete latino le faltan algunos audios, como los números. El inglés viene de fábrica.

### 4.3 Extras E4
| Dónde | Qué mostrar | Qué explicar |
|---|---|---|
| **Applications → Ring Groups → 8000** | 1000 y 1001, estrategia ringall, buzón si nadie contesta | Recepción. Suenan todos a la vez |
| **Applications → Queues → 8010** | 2001 y 2002, rrmemory, aviso de grabación, posición y música CMH | Consulta Externa. Reparte las llamadas por turnos |
| **Applications → Time Groups** y **Time Conditions** | `Horario-Atencion` y `TC-Horario` | Lunes a viernes de 7:00 a 19:00 y sábado de 7:00 a 12:00. Fuera de horario contesta otro IVR |
| **Settings → Music on Hold → CMH** | La pista propia | Compuesta con código, así que es original y sin derechos de autor |
| Extensión **1000**, pestaña **Advanced**, *Recording Options* | Force en todo | Se graban todas sus llamadas |
| **Reports → Call Recordings** o **CDR Reports** | Grabaciones y registros de las llamadas de prueba | Auditoría y registro de eventos (§5.3). Solo se ven desde la administración |

**Figura 12.** Grupo de timbrado 8000 (Recepción)

![Grupo de timbrado 8000 (Recepción)](capturas/08-grupo-8000.png)

> **Qué se hizo.** Se creó el grupo de timbrado **8000 (Recepción)** con las extensiones **1000 y 1001**. La estrategia *ringall* hace que suenen las dos al mismo tiempo, y la primera que contesta se queda con la llamada. Si nadie contesta en **20 segundos**, la llamada va al buzón de la 1000. Es la opción 1 del IVR.

**Figura 13.** Cola 8010 (Consulta Externa) con rrmemory, música CMH y aviso de grabación

![Cola 8010 (Consulta Externa) con rrmemory, música CMH y aviso de grabación](capturas/09-cola-8010.png)

> **Qué se hizo.** Se creó la cola **8010 (Consulta Externa)** con las extensiones 2001 y 2002 como agentes. La estrategia **rrmemory** reparte las llamadas por turnos y recuerda a quién le tocó la última, así la carga queda pareja entre las dos clínicas. Al entrar se escucha el aviso de grabación, y mientras se espera suena nuestra música (**CMH**). Es la opción 2 del IVR.

**Figura 14.** Time Groups: Horario-Atencion

![Time Groups: Horario-Atencion](capturas/10-grupo-horario.png)

> **Qué se hizo.** Se definió el horario de atención del centro médico: **lunes a viernes de 7:00 a 19:00** y **sábado de 7:00 a 12:00**. Este grupo de horario lo usa la condición de la figura siguiente.

**Figura 15.** Time Conditions: TC-Horario (*271)

![Time Conditions: TC-Horario (*271)](capturas/11-condicion-horaria.png)

> **Qué se hizo.** Es la condición de horario **TC-Horario**, con zona horaria de Guatemala. Si la llamada entra **dentro** del horario de la figura 14, contesta el **IVR-Principal**. Si entra **fuera** de ese horario, contesta el **IVR-FueraHorario**, que solo ofrece Emergencias (3) o dejar un mensaje (1). El título muestra el código **\*271** para cambiar el modo a mano en la demostración.

**Figura 16.** Music on Hold: categoría CMH con la pista propia

![Music on Hold: categoría CMH con la pista propia](capturas/13-musica-cmh.png)

> **Qué se hizo.** Se creó la categoría de música en espera **CMH** y se subió la pista `moh-cmh-tema1`. La compusimos con código, así que es original y no tiene problemas de derechos de autor. Es la que suena en la cola 8010.

**Figura 17.** Extensión 1000, Recording Options en Force

![Extensión 1000, Recording Options en Force](capturas/03b-ext1000-grabacion.png)

> **Qué se hizo.** En la extensión 1000 (Recepción) se puso la grabación en **Force** para todas las llamadas, entrantes y salientes, internas y externas. Las grabaciones solo se pueden escuchar desde la administración web, que está restringida a la red de Gestión (requisito de acceso restringido de E4).

**Figura 18.** Reports → CDR Reports con las llamadas de prueba del 17/10

![Reports → CDR Reports con las llamadas de prueba del 17/10](capturas/21-cdr-tabla.png)

> **Qué se hizo.** Es el registro de llamadas (CDR). Cada fila es una llamada con fecha, hora, quién llamó (CallerID), a dónde fue (*App* y *Destination*), si se contestó (*ANSWERED*) y cuánto duró. Aquí se ven las primeras llamadas de prueba del 17/10 desde el iPhone (extensión 2001) al IVR. Sirve como evidencia para el informe y para la matriz de pruebas.

### 4.4 Seguridad (§5.8)
| Dónde | Qué mostrar | Qué explicar |
|---|---|---|
| **Connectivity → Firewall → Main → Networks** | Trusted: 10.0.2.2 y 192.168.10.0/24. Local: VOZ, ADMIN, Tailscale y hotspot | Zonas de confianza |
| **Connectivity → Firewall → Services** | Web y SSH sin zonas (solo Trusted). SIP solo en Local | Solo se exponen los servicios necesarios |
| **Connectivity → Firewall → Main → Responsive Firewall** | Activado en general, con *SIP Protocol (pjsip)* en Disabled | El SIP que llega de redes no confiables se rechaza por completo. Solo las redes Local (voz, ADMIN y Tailscale) pueden registrar teléfonos, y fail2ban bloquea los intentos repetidos |
| **Reports → Weak Password Detection** | Sin contraseñas débiles | Credenciales robustas |
| **Admin → Backup & Restore** | Tarea `CMH-diario` (2:00, guarda 7) | Respaldos automáticos |
| En vivo (opcional) | Abrir `http://<IP de la PBX>` desde el celular | No abre. La administración está protegida |

**Figura 19.** Firewall → Networks con las zonas Trusted y Local

![Firewall → Networks con las zonas Trusted y Local](capturas/15-firewall-redes.png)

> **Qué se hizo.** Se activó el firewall de FreePBX y se definieron las redes de confianza. En **Trusted** (acceso total) quedaron la laptop que administra la VM (10.0.2.2) y la VLAN 10 de Gestión. En **Local** (solo teléfonos) quedaron la VLAN 20 de Voz, la VLAN 30 Administrativa, Tailscale para E1 y la red de pruebas del hotspot. Cualquier otra red cae en la zona *Internet*, que no tiene acceso.

**Figura 20.** Firewall → Services: SSH y web sin zonas, SIP solo en Local

![Firewall → Services: SSH y web sin zonas, SIP solo en Local](capturas/17-firewall-servicios.png)

> **Qué se hizo.** Aquí se decide qué servicio puede usar cada zona. **SSH** y la **web de administración** no tienen ninguna zona marcada, así que solo se pueden usar desde las redes *Trusted* (Gestión y la laptop que administra). **SIP** está marcado solo en **Local**, para que los teléfonos de las VLAN puedan registrarse. Los demás servicios quedaron cerrados porque no se usan.

**Figura 21.** Firewall → Responsive Firewall activo, con SIP (pjsip) en Disabled

![Firewall → Responsive Firewall activo, con SIP (pjsip) en Disabled](capturas/16-firewall-responsive.png)

> **Qué se hizo.** El *Responsive Firewall* está activo, pero con **SIP (pjsip) en Disabled**. Eso significa que el SIP que llega desde redes que no son de confianza se rechaza siempre, sin darle intentos. Es la opción más estricta, y los teléfonos no se ven afectados porque todos entran por redes *Local*. Contra intentos repetidos de contraseña sigue trabajando fail2ban.

**Figura 22.** Reports → Weak Password Detection sin contraseñas débiles

![Reports → Weak Password Detection sin contraseñas débiles](capturas/19-claves-debiles.png)

> **Qué se hizo.** Es el revisor de contraseñas de FreePBX. Dice *No weak secrets detected*, o sea que ninguna extensión tiene una contraseña débil. Las contraseñas SIP son aleatorias de 32 caracteres y distintas en cada extensión.

**Figura 23.** Admin → Backup & Restore con la tarea CMH-diario

![Admin → Backup & Restore con la tarea CMH-diario](capturas/18-respaldos.png)

> **Qué se hizo.** Se creó la tarea de respaldo **CMH-diario**. Guarda toda la configuración de FreePBX todos los días a las 2:00 y conserva los últimos 7. Con el botón ▶ se puede ejecutar a mano antes de un cambio grande.

### 4.5 Estado de los teléfonos (criterio E)
| Dónde | Qué mostrar |
|---|---|
| **Reports → Asterisk Info** | Las líneas *Contact* de las extensiones registradas, en estado **Avail** y con su IP |
| **Admin → Asterisk CLI** | Escribir `pjsip show contacts` y ejecutar. Muestra lo mismo en texto |

**Figura 24.** Reports → Asterisk Info, sección PJSIP. La 1000 aparece Avail. Las demás salen Unavailable hasta que se registra su teléfono

![Reports → Asterisk Info, sección PJSIP. La 1000 aparece Avail. Las demás salen Unavailable hasta que se registra su teléfono](capturas/20-telefonos-registrados.png)

> **Qué se hizo.** Es el estado de los teléfonos visto desde Asterisk. Cada *Endpoint* es una extensión. Cuando un teléfono está conectado aparece una línea *Contact* con su IP y el estado **Avail** (disponible), como la 1000 de esta captura, que es MicroSIP en la laptop. Las que dicen *Unavailable* todavía no tienen un teléfono registrado. En la demostración hay que mostrar al menos 4 en *Avail*, con una laptop y un celular.

---

## 5. Demostración con llamadas

Con MicroSIP (1000) y Linphone (2001) registrados. **Linphone debe estar abierto en pantalla**, porque en iOS no recibe llamadas en segundo plano con un servidor propio.

| # | Desde | Marcar | Qué debe pasar |
|---|---|---|---|
| 1 | Laptop (1000) | **2001** | Suena el celular y se escucha en los dos sentidos |
| 2 | Celular (2001) | **7000** | IVR en español. Marcar **1** lleva al grupo 8000 y suena la laptop |
| 3 | Laptop | **\*271**, luego **7000** | Contesta el IVR de fuera de horario. Marcar \*271 otra vez para regresar |
| 4 | Laptop | **8010** | Aviso de grabación, música CMH y luego suena el celular (2001) |
| 5 | En una llamada 1000 ↔ 2001 | Botón **Espera** y luego **Reanudar** | El otro escucha música mientras espera |
| 6 | Laptop | **\*43** | Prueba de eco. Se escucha la propia voz |
| 7 | Laptop | **\*97**, PIN, 0 y 1 | Grabar el saludo del buzón de la 1000 |
| 8 | Celular | **1000** y no contestar 20 s | Va al buzón con el saludo grabado |
| 9 | Laptop | **\*97**, PIN y 1 | Escuchar el mensaje |
| 10 | Con un tercer teléfono | **##** (ciega) o **\*2** (atendida) durante la llamada | La llamada pasa a la otra extensión |

> La transferencia necesita tres teléfonos. Sirve el celular de alguien del grupo, conectado al mismo Wi-Fi o hotspot, con la 3001 o la 4001.

Después de las llamadas, abrir **Reports → CDR Reports**. Ahí aparecen todas, con origen, destino y duración. Las de la 1000 tienen el botón para escuchar la grabación.

> **Evidencias para el informe.** Toma las capturas con el **reloj de Windows visible** y sin mostrar contraseñas (archivo 10 del plan).

---

## 6. Por consola (opcional)

Desde PowerShell en la laptop:
```powershell
ssh -i "$env:USERPROFILE\.ssh\cmh_pbx_ed25519" -p 2222 cmhadmin@127.0.0.1
```
Ya dentro de la VM. Los que llevan `sudo` piden la contraseña de `cmhadmin`.

| Comando | Qué muestra |
|---|---|
| `sudo asterisk -rx "pjsip show contacts"` | Teléfonos registrados |
| `sudo asterisk -rx "core show channels"` | Llamadas en curso |
| `sudo asterisk -rx "pjsip show channelstats"` | Jitter, pérdida y RTT de las llamadas activas (sirve para la QoS) |
| `sudo fail2ban-client status` | Protecciones activas contra intentos repetidos |
| `sudo tail -f /var/log/asterisk/full` | Lo que hace Asterisk en vivo. Se sale con Ctrl+C |
| `ip -br -4 addr` | IPs de la VM |

---

## 7. Apagar correctamente

- En VirtualBox, clic derecho en **CMH-FreePBX → Stop → ACPI Shutdown**. Es el apagado limpio y tarda unos 20 segundos.
- O en PowerShell:
  ```powershell
  & "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" controlvm CMH-FreePBX acpipowerbutton
  ```
- **No usar "Power Off"**, salvo que la VM no responda.
- **Los snapshots se sacan siempre con la VM apagada.** Con la VM encendida, VirtualBox puede trabarla.

**Volver a un punto anterior** (con la VM apagada). En VirtualBox, CMH-FreePBX, ícono de lista, **Snapshots**. Elegir `03-antes-de-modo-puente` o `02-antes-de-config-sip` y luego **Restore**. Todo lo hecho después de ese snapshot se pierde, así que antes conviene un respaldo de FreePBX (**Admin → Backup & Restore**, botón de ejecutar en `CMH-diario`).

---

## 8. Si algo falla

| Problema | Qué hacer |
|---|---|
| `127.0.0.1:18080` no abre | Esperar 2 o 3 minutos después de encender. Revisar en VirtualBox que la VM diga *Running* |
| El SSH se queda colgado | Bloqueo de fail2ban. Ver `CONFIG.md`, Parte C, C4 |
| El teléfono no se registra | Revisar la IP de la PBX (sección 2), que la laptop y el celular estén en la misma red y que Linphone esté abierto |
| Se escucha en un solo sentido | Revisar que la extensión tenga Direct Media en No y que la red del teléfono esté en *Local Networks* |
| Cambié de red y no se registra | Si la red nueva no es `192.168.x.x` ni `172.16` a `172.31`, agregarla en **Settings → Asterisk SIP Settings → Local Networks** y en **Connectivity → Firewall → Main → Networks** como Local |
| Me equivoqué de contraseña varias veces | Con 5 intentos fallidos en 10 minutos, fail2ban bloquea ese equipo 30 minutos. La administración por `127.0.0.1` nunca se bloquea, pero MicroSIP y el celular sí. Se espera o se desbloquea con `sudo fail2ban-client unban <IP>` por SSH |

Más casos en `CONFIG.md`, Parte C, **C4. Reparación rápida**.
