# GUÍA TELÉFONOS · Extensiones del equipo con Tailscale y Linphone
**Centro Médico Horizonte, S.A. · PF-TEL-001-2026**
Última actualización: 20/10/2026

Procedimiento para que cada integrante convierta su celular en una **extensión de la PBX** del proyecto, y lista de las pruebas que le corresponden a cada uno. Se usan aplicaciones gratuitas.

| Aplicación | Función | Editor oficial |
|---|---|---|
| **Tailscale** | Crea un túnel VPN cifrado (WireGuard) entre el equipo y la PBX, desde cualquier red, incluso con datos móviles | Tailscale Inc. |
| **Linphone** | Softphone SIP. Registra el celular como extensión. También existe para macOS y Windows | Belledonne Communications |
| **MicroSIP** | Softphone SIP para Windows. Solo lo usa la laptop host | microsip.org |

> **Requisito previo.** La PBX corre en una máquina virtual dentro de la laptop del responsable técnico. Para que los teléfonos se registren, esa laptop debe estar **encendida, con internet y con la VM en ejecución**. Las pruebas se hacen en sesiones coordinadas (sección 6).

---

## 1. Asignación de extensiones

Cada extensión admite **un solo dispositivo a la vez**. Si la misma extensión se registra en dos equipos, uno queda desconectado.

| Extensión | Puesto en el diseño | Integrante | Dispositivo | Buzón |
|---|---|---|---|---|
| 1000 | Operadora Recepción | Isaac Sarceño | Laptop host (MicroSIP) | Sí |
| 1001 | Recepción Móvil | **José Arnaldo** | Celular (Linphone) | No |
| 2001 | Clínica 1 | **Leonardo Zepeda** | Celular (Linphone) | Sí |
| 2002 | Clínica 2 | **Omar Godoy** | Celular Android (Linphone) | No |
| 3001 | Enfermería | **Ernesto Grijalva** | Celular (Linphone) | Sí |
| 3002 | Emergencias | **Reginaldo** | Celular (Linphone) | No |
| 4001 | Administración | **Anthony** | Celular (Linphone) | Sí |
| 5001 | TI Gerencia | **Romeo** | Celular (Linphone) | No |
| 5002 | TI Remoto | **Isaac Sarceño** | iPhone por datos móviles (extra E1) | No |

La laptop host (1000) es la terminal de escritorio. Las demás son celulares, así las transferencias y llamadas cruzan **tipos de terminal distintos** (laptop y móvil), como pide el PDF. Si algún integrante con extensión 3002, 4001 o 5001 tiene laptop con Windows, puede usar MicroSIP en lugar del celular (sección 4.2) y suma otra terminal de escritorio a las pruebas.

---

## 2. Datos que se reciben por canal privado

El responsable técnico entrega a cada integrante, **por mensaje privado y nunca por el chat del grupo**:

1. El acceso a la **cuenta de Google del proyecto**, que es la cuenta de Tailscale.
2. La **contraseña SIP** de su extensión.
3. El **PIN del buzón**, solo para 2001, 3001 y 4001.

Ninguno de estos datos se escribe en el repositorio, en el informe ni en capturas (§11 del PDF).

> **Inicio de sesión con la cuenta compartida.** Si la cuenta tiene verificación en dos pasos, Google pide aprobar cada inicio de sesión en el teléfono del responsable técnico. Conviene coordinar el momento de conectarse.

---

## 3. Instalar y conectar Tailscale

1. Descargar **Tailscale** desde la App Store (iPhone) o Google Play (Android). Verificar que el editor sea **Tailscale Inc.**
2. Abrir la aplicación y seleccionar **Sign in with Google**.
3. Iniciar sesión con la **cuenta de Google del proyecto**.
4. Aceptar el permiso para **agregar una configuración de VPN** (en Android aparece como *Solicitud de conexión*, tocar **Aceptar**).
5. Activar el interruptor. El estado debe quedar en **Connected**.
6. Comprobar que en la lista de equipos aparece **cmh-pbx** con la IP **100.91.176.16**.

> Tailscale solo envía por el túnel el tráfico hacia los equipos del proyecto (direcciones `100.x.x.x`). El resto de la navegación no pasa por la VPN.

---

## 4. Configurar el softphone

### 4.1 Linphone en el celular

1. Descargar **Linphone** desde la App Store o Google Play. Verificar que el editor sea **Belledonne Communications**.
2. Abrir la aplicación y elegir **Usar una cuenta SIP**. En versiones recientes aparece como *Cuenta SIP de terceros*. **No** crear una cuenta de Linphone.
3. Completar los campos.

| Campo | Valor |
|---|---|
| Nombre de usuario | El número de extensión asignado |
| Contraseña | La contraseña SIP recibida por canal privado |
| Dominio | **`100.91.176.16`** |
| Nombre para mostrar | Nombre del integrante |
| Transporte | **UDP** |

4. Guardar. La cuenta debe mostrarse en **verde** (registrada).

**Ajustes adicionales en Android** (José, Omar y quien tenga Android)
- Conceder a Linphone los permisos de **micrófono** y **notificaciones** cuando los pida.
- Excluir Linphone y Tailscale del ahorro de batería. En **Ajustes → Aplicaciones → Linphone → Batería**, elegir **Sin restricciones**. Repetir con Tailscale. El nombre exacto del menú cambia según la marca del teléfono.
- No cerrar Linphone desde la lista de aplicaciones recientes durante las pruebas.

### 4.2 MicroSIP en una laptop con Windows (opcional)

Solo si un integrante prefiere usar su laptop con Windows en lugar del celular. Antes se instala **Tailscale para Windows** desde https://tailscale.com/download/windows y se inicia sesión con la cuenta del proyecto.

1. Descargar MicroSIP desde **https://www.microsip.org/downloads** e instalarlo.
2. Menú **▼ → Agregar cuenta** y completar.

| Campo | Valor |
|---|---|
| Nombre de la cuenta | `CMH` y la extensión |
| Servidor SIP | **`100.91.176.16`** |
| Proxy SIP | Vacío |
| Usuario | La extensión |
| Dominio | **`100.91.176.16`** |
| Login | La extensión |
| Contraseña | La contraseña SIP recibida por canal privado |
| Nombre para mostrar | Nombre del integrante |
| Transporte | **UDP** |

3. Guardar. Abajo debe aparecer **En línea**. Si Windows pregunta por el firewall, permitir el acceso.

En **macOS** se usa Linphone para escritorio (https://www.linphone.org) con los mismos datos de la tabla 4.1, junto con Tailscale para macOS.

> **Dominio según el escenario.** Con Tailscale, desde cualquier red, el dominio es `100.91.176.16`. El día de la integración con el router, conectados a la red de la VLAN de Voz, el dominio cambia a **`192.168.20.10`** y Tailscale se desactiva. Así las llamadas cruzan el router y pasan por la QoS que se va a medir.

### 4.3 Comprobación individual

Cada integrante, al terminar la configuración, hace estas tres llamadas y avisa en el grupo que su extensión está lista.

| # | Marcar | Resultado esperado |
|---|---|---|
| 1 | **\*43** | Prueba de eco. Se escucha la propia voz con un pequeño retraso |
| 2 | **7000** | Contesta el IVR del Centro Médico Horizonte en español |
| 3 | **1000** | Suena MicroSIP en la laptop host, si el responsable técnico está conectado |

---

## 5. Instrucciones por integrante

Las claves entre paréntesis (FUN-05, EXT-07, etc.) son los identificadores de la **matriz de pruebas** (`plan/09_PRUEBAS_Y_TRAZABILIDAD.md`). Las claves L1 a L6 son las llamadas entre tipos de terminal del archivo 05. Cada integrante anota su resultado en la matriz, con la fecha, la calificación del audio de 1 a 5 y el nombre de su captura.

### 5.1 José Arnaldo · Extensión 1001 · Recepción Móvil

**Papel en la demostración.** Es el teléfono móvil de la recepción. Forma parte del **grupo de timbrado 8000** junto con la operadora (1000), así que suena cada vez que alguien llama a Recepción.

**Configuración.** Tailscale y Linphone en el celular (secciones 3 y 4.1), usuario `1001`.

| Prueba | Qué hacer | Resultado esperado |
|---|---|---|
| Grupo de timbrado (EXT-06) | Esperar con Linphone abierto mientras Leonardo marca **8000** | Suenan a la vez la 1001 y la 1000. Contestar y hablar |
| Transferencia ciega T3 (FUN-07) | Contestar la llamada de la 1000. Durante la llamada marcar **`##`** y luego **3002** | La llamada pasa a Reginaldo sin que José hable con él |
| Llamadas entre áreas (FUN-01, L3, L6) | Contestar las llamadas de Romeo y de Anthony. Llamar a Ernesto (**3001**) | Audio en los dos sentidos |
| Llamada en cola (EXT-07) | Cuando se indique, marcar **8010** al mismo tiempo que Ernesto y Romeo | Aviso de grabación y música. Si queda en espera, se anuncia su posición en la fila |

**Evidencias.** Captura del celular sonando por el 8000 y captura de la transferencia en curso, con la hora visible.

### 5.2 Leonardo Zepeda · Extensión 2001 · Clínica 1

**Papel en la demostración.** Es la Clínica 1 de Consulta Externa. Es **agente de la cola 8010** junto con la Clínica 2 (Omar) y tiene **buzón de voz** con saludo personalizado.

**Configuración.** Tailscale y Linphone en el celular (secciones 3 y 4.1), usuario `2001`. Además recibe el **PIN del buzón**.

| Prueba | Qué hacer | Resultado esperado |
|---|---|---|
| Espera desde el móvil (FUN-03) | Durante una llamada con la 1000, tocar **Pausa** y luego reanudar | Isaac escucha la música en espera y la llamada se retoma |
| Grupo de timbrado (EXT-06) | Marcar **8000** | Suenan la 1000 y la 1001 al mismo tiempo |
| Transferencia atendida T2, destino (FUN-06) | Contestar cuando Isaac consulte desde la 1000 | Isaac le explica la llamada, cuelga y queda conectado con Anthony |
| Transferencia atendida T4 (FUN-08) | Contestar la llamada de Omar. Marcar **`*2`** y luego **3001**, hablar con Ernesto y colgar para completar | Omar queda conectado con Ernesto |
| Cola, agente (EXT-07) | Tener Linphone abierto cuando lleguen las llamadas al 8010 | Recibe una de las llamadas. La siguiente va a Omar |
| Buzón (FUN-11) | No contestar cuando Omar llame. Después marcar **\*97**, escribir el PIN y escuchar el mensaje | Suena el saludo de la Clínica 1 y luego se reproduce el mensaje de Omar |

**Evidencias.** Captura del celular en una llamada de la cola y captura del buzón reproduciendo el mensaje.

### 5.3 Omar Godoy · Extensión 2002 · Clínica 2 (Android)

**Papel en la demostración.** Es la Clínica 2 de Consulta Externa, el **segundo agente de la cola 8010**. Además hace el **recorrido completo del IVR**.

**Configuración.** Tailscale y Linphone en su celular **Android** (secciones 3 y 4.1), usuario `2002`. Aplicar los **ajustes adicionales de Android** de la sección 4.1 antes de la sesión.

| Prueba | Qué hacer | Resultado esperado |
|---|---|---|
| Recorrido del IVR (FUN-12 a FUN-16) | Marcar **7000** y probar, en llamadas separadas, las opciones **1, 2, 3, 4 y 0**, una opción inválida (**8** dos veces) y no marcar nada | 1 suena el grupo 8000. 2 entra a la cola. 3 suena Ernesto. 4 suena Anthony. 0, inválida y sin respuesta pasan a la operadora (1000) |
| Transferencia ciega T1, destino (FUN-05) | Esperar la llamada que Isaac transfiere desde la 1000 | Le llega la llamada de Ernesto |
| Transferencia atendida T4, origen (FUN-08) | Marcar **2001** y esperar a que Leonardo lo transfiera | Termina hablando con Ernesto |
| Dejar un mensaje (FUN-11) | Marcar **2001**, no contestan, dejar un mensaje corto después del tono | El mensaje queda en el buzón de Leonardo |
| Llamada entre terminales (L2) | Marcar **3002** | Suena Reginaldo y se escuchan los dos |
| Cola, agente (EXT-07) | Tener Linphone abierto cuando lleguen las llamadas al 8010 | Recibe una de las llamadas de la cola |

**Evidencias.** Capturas del celular durante el recorrido del IVR y durante la transferencia, con la hora visible.

### 5.4 Ernesto Grijalva · Extensión 3001 · Enfermería

**Papel en la demostración.** Es Enfermería, la **opción 3 del IVR** y el destino de emergencias **fuera de horario**. Tiene **buzón de voz** y participa en varias transferencias.

**Configuración.** Tailscale y Linphone en el celular (secciones 3 y 4.1), usuario `3001`. Además recibe el **PIN del buzón**.

| Prueba | Qué hacer | Resultado esperado |
|---|---|---|
| Marcación entre áreas (FUN-01) | Marcar **4001** | Suena Anthony y se escuchan los dos |
| Segunda llamada entrante (FUN-04) | Marcar **1000** mientras Isaac está en otra llamada | Isaac escucha el aviso de llamada en espera y alterna entre las dos |
| Transferencia ciega T1, origen (FUN-05) | Marcar **1000** y esperar | Isaac transfiere con `##` y la llamada llega a Omar (2002) |
| Transferencia atendida T4, destino (FUN-08) | Contestar cuando Leonardo consulte | Leonardo le explica la llamada y queda conectado con Omar |
| Buzón ocupado (FUN-10) | Marcar **1000** cuando Isaac avise que está ocupado | Se escucha el saludo de ocupado de Recepción |
| Llamada en cola (EXT-07) | Marcar **8010** al mismo tiempo que José y Romeo | Aviso de grabación, música y anuncio de posición si queda en espera |
| Fuera de horario, destino (EXT-08) | Contestar cuando Reginaldo marque la opción 3 del IVR de fuera de horario | Le llega la llamada de emergencia |
| Llamada a TI (L5) | Marcar **5001** | Suena Romeo y se escuchan los dos |

**Evidencias.** Captura del celular durante la transferencia ciega y captura del mensaje de ocupado.

### 5.5 Reginaldo · Extensión 3002 · Emergencias

**Papel en la demostración.** Es el puesto de Emergencias. Es el **destino de la transferencia ciega T3** y prueba el **IVR fuera de horario**.

**Configuración.** Tailscale y Linphone en el celular (secciones 3 y 4.1), usuario `3002`.

| Prueba | Qué hacer | Resultado esperado |
|---|---|---|
| Transferencia ciega T3, destino (FUN-07) | Contestar cuando llegue la llamada transferida por José | Habla con Isaac (la 1000), que fue quien llamó a José |
| Llamada entre terminales (L2) | Contestar la llamada de Omar | Audio en los dos sentidos |
| Fuera de horario (EXT-08) | Después de que Isaac marque \*271, marcar **7000**, escuchar el mensaje y marcar **3** | Contesta el IVR de fuera de horario y la opción 3 lleva a Enfermería (Ernesto) |

**Evidencias.** Captura del celular con la llamada transferida y captura de la llamada al IVR de fuera de horario.

### 5.6 Anthony · Extensión 4001 · Administración

**Papel en la demostración.** Es Administración y Contabilidad, la **opción 4 del IVR**. Tiene **buzón de voz**. Inicia la **transferencia atendida T2** y prueba el **buzón sin respuesta** de Recepción.

**Configuración.** Tailscale y Linphone en el celular (secciones 3 y 4.1), usuario `4001`. Además recibe el **PIN del buzón**.

| Prueba | Qué hacer | Resultado esperado |
|---|---|---|
| Transferencia atendida T2, origen (FUN-06) | Marcar **1000** y esperar | Isaac consulta con Leonardo (`*2` 2001) y Anthony termina hablando con Leonardo |
| Buzón sin respuesta (FUN-09) | Marcar **1000**. Isaac no contesta. Dejar un mensaje después del saludo | Suena el saludo personalizado de Recepción y el mensaje queda grabado |
| IVR opción 4 (FUN-13) | Contestar cuando Omar marque la opción 4 | Le llega la llamada |
| Llamadas entre terminales (L4, L6) | Contestar a Romeo. Marcar **1001** | Audio en los dos sentidos |

**Evidencias.** Captura del celular durante la transferencia atendida y captura de la llamada que termina en el buzón.

### 5.7 Romeo · Extensión 5001 · TI Gerencia

**Papel en la demostración.** Es TI Gerencia. Hace llamadas entre áreas, es **tercer llamante de la cola** y, al final, ejecuta la **prueba de seguridad** contra intentos de contraseña.

**Configuración.** Tailscale y Linphone en el celular (secciones 3 y 4.1), usuario `5001`.

| Prueba | Qué hacer | Resultado esperado |
|---|---|---|
| Marcación entre áreas (FUN-01) | Marcar **1001** | Suena José y se escuchan los dos |
| Llamada entre terminales (L4) | Marcar **4001** | Suena Anthony y se escuchan los dos |
| Llamada entre terminales (L5) | Contestar la llamada de Ernesto | Audio en los dos sentidos |
| Llamada en cola (EXT-07) | Marcar **8010** al mismo tiempo que José y Ernesto | Uno de los tres queda esperando con música y escucha su posición |
| Seguridad, fuerza bruta SIP (SEG-04) | **Solo al final de la sesión.** Cambiar en Linphone la contraseña de la 5001 por una incorrecta y forzar el registro 5 o 6 veces | La PBX bloquea su equipo durante 30 minutos (fail2ban). Isaac lo confirma en la consola. Luego se vuelve a poner la contraseña correcta |

**Evidencias.** Captura de la llamada en cola y captura del error de registro durante la prueba de seguridad.

### 5.8 Isaac Sarceño · Extensiones 1000 y 5002 · Operadora y TI Remoto

**Papel en la demostración.** Es el **responsable técnico**. Opera la laptop host con la PBX y la extensión **1000** (MicroSIP), coordina la sesión y prueba el acceso remoto con la **5002** en el iPhone por datos móviles (extra E1).

**Configuración.** La 5002 ya está en Linphone con dominio `100.91.176.16`. La cuenta **2001** se elimina de su Linphone porque ahora es de Leonardo.

| Prueba | Qué hacer | Resultado esperado |
|---|---|---|
| Espera desde la laptop (FUN-02) | En llamada con Leonardo, poner en espera en MicroSIP y reanudar | Leonardo escucha la música en espera |
| Segunda llamada (FUN-04) | En llamada con Leonardo, contestar a Ernesto y alternar entre las dos | Dos llamadas atendidas a la vez |
| Transferencia ciega T1 (FUN-05) | Contestar a Ernesto, marcar **`##`** y luego **2002** | La llamada pasa a Omar |
| Transferencia atendida T2 (FUN-06) | Contestar a Anthony, marcar **`*2`** y luego **2001**, hablar con Leonardo y colgar | Anthony queda conectado con Leonardo |
| Iniciar la T3 (FUN-07) | Marcar **1001** y quedarse en la línea | José transfiere y Reginaldo contesta |
| Buzón ocupado (FUN-10) | Marcar **\*71**, llamar a Leonardo y avisar a Ernesto que llame. Al terminar, marcar **\*70** | Ernesto escucha el saludo de ocupado |
| Buzón sin respuesta y consulta (FUN-09, FUN-11) | No contestar la llamada de Anthony. Después marcar **\*97**, PIN y escuchar | Se reproduce el mensaje de Anthony |
| Horario (EXT-08) | Marcar **\*271** antes de la prueba de Reginaldo y otra vez al terminar | El 7000 cambia a fuera de horario y vuelve a la normalidad |
| E1 (EXT-02) | Con el iPhone solo con datos móviles y Linphone abierto, recibir en la 5002 una llamada de la 1000 | Audio en los dos sentidos |
| Seguridad (SEG-04) | Mientras Romeo hace la prueba, revisar `sudo fail2ban-client status asterisk-iptables` y luego desbloquearlo | Aparece la IP de Tailscale de Romeo como bloqueada |
| Evidencias de la PBX (TER-01, PBX-05, EXT-11) | Capturar **Reports → Asterisk Info** con todas las extensiones en *Avail* y **Reports → CDR Reports** con todas las llamadas | Al menos 4 extensiones registradas a la vez y las grabaciones de la 1000 en el CDR |

---

## 6. Guion de la sesión de pruebas conjunta

Duración estimada de 60 minutos. Todos entran a una videollamada para coordinar, con Tailscale activo y Linphone abierto en pantalla. Isaac anuncia cada prueba por su número y dice quién empieza.

### 6.1 Reglas de la sesión

- **Todas las extensiones pueden llamarse entre sí.** Con Tailscale no hay restricciones por área. Las restricciones entre redes (VLAN) solo existen el día del router.
- En cada prueba **solo actúan las personas de su tabla**. Los demás no llaman a nadie y tienen el micrófono de la videollamada apagado.
- Se marca **solo cuando Isaac lo indique**. Si alguien llama antes, la extensión de destino aparece ocupada y la prueba se repite.
- Al terminar cada prueba, **todos cuelgan** antes de pasar a la siguiente.
- Quien tiene una captura asignada la toma **con la hora visible** y la nombra con el número de prueba, por ejemplo `prueba06-omar.png`.

### 6.2 Directorio

| Extensión | Integrante | Área | Notas |
|---|---|---|---|
| 1000 | Isaac (laptop, MicroSIP) | Operadora Recepción | Buzón. Coordina la sesión |
| 1001 | José | Recepción Móvil | Suena junto con la 1000 en el grupo 8000 |
| 2001 | Leonardo | Clínica 1 | Buzón. Agente de la cola 8010 |
| 2002 | Omar | Clínica 2 | Agente de la cola 8010 |
| 3001 | Ernesto | Enfermería | Buzón |
| 3002 | Reginaldo | Emergencias | |
| 4001 | Anthony | Administración | Buzón |
| 5001 | Romeo | TI Gerencia | |
| 5002 | Isaac (iPhone, datos móviles) | TI Remoto | Solo en la prueba 18 |

| Número especial | Qué hace |
|---|---|
| 7000 | IVR del Centro Médico |
| 8000 | Grupo de timbrado de Recepción (1000 y 1001) |
| 8010 | Cola de Consulta Externa (agentes 2001 y 2002) |
| \*97 | Escuchar el buzón propio (pide el PIN) |
| `##` | Durante una llamada, transferencia ciega |
| `*2` | Durante una llamada, transferencia atendida (con consulta) |

### 6.3 Pruebas paso a paso

#### Prueba 1 · Todos registrados (TER-01)

| Paso | Quién | Qué hace |
|---|---|---|
| 1 | Todos | Abren Linphone y confirman en la videollamada que su cuenta está en verde |
| 2 | Isaac | Captura *Reports → Asterisk Info* con todas las extensiones en *Avail* |

**Resultado esperado.** Las 9 extensiones registradas a la vez.

#### Prueba 2 · Llamadas entre áreas (FUN-01)

Son tres llamadas, una después de otra.

| Paso | Quién llama | Marca | Quién contesta |
|---|---|---|---|
| 1 | Isaac (1000) | **2001** | Leonardo |
| 2 | Ernesto (3001) | **4001** | Anthony |
| 3 | Romeo (5001) | **1001** | José |

**Resultado esperado.** En cada llamada los dos se escuchan. Se dicen su nombre y área y cuelgan.

#### Prueba 3 · Espera desde la laptop (FUN-02)

| Paso | Quién | Qué hace |
|---|---|---|
| 1 | Isaac (1000) | Marca **2001** |
| 2 | Leonardo (2001) | Contesta |
| 3 | Isaac | Pone la llamada **en espera** en MicroSIP, cuenta 10 segundos y la reanuda |

**Resultado esperado.** Leonardo escucha la música en espera y luego vuelve a escuchar a Isaac. **No cuelguen**, la prueba 4 sigue en la misma llamada.

#### Prueba 4 · Espera desde el celular (FUN-03)

| Paso | Quién | Qué hace |
|---|---|---|
| 1 | Leonardo (2001) | En la misma llamada, toca **Pausa** en Linphone, cuenta 10 segundos y la reanuda |

**Resultado esperado.** Isaac escucha la música en espera y la llamada se retoma. **No cuelguen**, la prueba 5 sigue en la misma llamada.

#### Prueba 5 · Segunda llamada entrante (FUN-04)

| Paso | Quién | Qué hace |
|---|---|---|
| 1 | Isaac (1000) | Sigue en llamada con Leonardo |
| 2 | Ernesto (3001) | Marca **1000** |
| 3 | Isaac | Escucha el aviso de llamada en espera, contesta a Ernesto y luego vuelve con Leonardo |
| 4 | Todos | Cuelgan |

**Resultado esperado.** Isaac atiende dos llamadas a la vez y alterna entre ellas.

#### Prueba 6 · Transferencia ciega T1 (FUN-05)

| Paso | Quién | Qué hace |
|---|---|---|
| 1 | Ernesto (3001) | Marca **1000** |
| 2 | Isaac (1000) | Contesta, marca **`##`** y luego **2002** |
| 3 | Omar (2002) | Contesta. Habla con Ernesto |

**Resultado esperado.** Ernesto termina hablando con Omar sin que Isaac hable antes con Omar. **Captura** Omar, con la llamada de Ernesto en pantalla.

#### Prueba 7 · Transferencia atendida T2 (FUN-06)

| Paso | Quién | Qué hace |
|---|---|---|
| 1 | Anthony (4001) | Marca **1000** |
| 2 | Isaac (1000) | Contesta, marca **`*2`** y luego **2001**. Anthony queda en espera |
| 3 | Leonardo (2001) | Contesta. Isaac le explica que le pasa una llamada de Administración |
| 4 | Isaac | Cuelga para completar la transferencia |
| 5 | Leonardo y Anthony | Hablan entre ellos |

**Resultado esperado.** Anthony termina conectado con Leonardo después de la consulta. **Captura** Anthony.

#### Prueba 8 · Transferencia ciega T3 (FUN-07)

| Paso | Quién | Qué hace |
|---|---|---|
| 1 | Isaac (1000) | Marca **1001** |
| 2 | José (1001) | Contesta, marca **`##`** y luego **3002** |
| 3 | Reginaldo (3002) | Contesta. Habla con Isaac |

**Resultado esperado.** La llamada de Isaac pasa de José a Reginaldo. **Captura** José, durante la transferencia, y Reginaldo, con la llamada recibida.

#### Prueba 9 · Transferencia atendida T4 (FUN-08)

| Paso | Quién | Qué hace |
|---|---|---|
| 1 | Omar (2002) | Marca **2001** |
| 2 | Leonardo (2001) | Contesta, marca **`*2`** y luego **3001**. Omar queda en espera |
| 3 | Ernesto (3001) | Contesta. Leonardo le explica que le pasa una llamada de la Clínica 2 |
| 4 | Leonardo | Cuelga para completar la transferencia |
| 5 | Omar y Ernesto | Hablan entre ellos |

**Resultado esperado.** Omar termina conectado con Ernesto. Esta transferencia se hace entre dos celulares. **Captura** Omar.

#### Prueba 10 · Buzón cuando no contestan (FUN-09)

| Paso | Quién | Qué hace |
|---|---|---|
| 1 | Anthony (4001) | Marca **1000** |
| 2 | Isaac (1000) | **No contesta** |
| 3 | Anthony | Escucha el saludo de Recepción y deja un mensaje corto después del tono. Cuelga |

**Resultado esperado.** Se escucha el saludo personalizado de Recepción y el mensaje queda grabado. **Captura** Anthony.

#### Prueba 11 · Buzón cuando está ocupado (FUN-10)

| Paso | Quién | Qué hace |
|---|---|---|
| 1 | Isaac (1000) | Marca **\*71** para apagar la llamada en espera |
| 2 | Isaac | Marca **2001** |
| 3 | Leonardo (2001) | Contesta y se queda en la llamada |
| 4 | Ernesto (3001) | Marca **1000** |
| 5 | Ernesto | Escucha el saludo de ocupado y cuelga sin dejar mensaje |
| 6 | Isaac y Leonardo | Cuelgan. Isaac marca **\*70** para volver a encender la llamada en espera |

**Resultado esperado.** Ernesto escucha el saludo de **ocupado** de Recepción, distinto al de la prueba 10. **Captura** Ernesto.

#### Prueba 12 · Dejar y escuchar mensajes (FUN-11)

| Paso | Quién | Qué hace |
|---|---|---|
| 1 | Omar (2002) | Marca **2001** |
| 2 | Leonardo (2001) | **No contesta** |
| 3 | Omar | Deja un mensaje corto después del tono y cuelga |
| 4 | Leonardo | Marca **\*97**, escribe su PIN y escucha el mensaje de Omar |
| 5 | Isaac (1000) | Marca **\*97**, escribe su PIN y escucha el mensaje de Anthony (prueba 10) |

**Resultado esperado.** Cada uno escucha el mensaje que le dejaron. **Captura** Leonardo, con el buzón reproduciendo el mensaje.

#### Prueba 13 · Recorrido del IVR (FUN-12 a FUN-16)

Omar hace **siete llamadas** al **7000**, una por opción. Antes de cada una, Isaac avisa quién debe contestar.

| Llamada | Omar marca en el IVR | Quién contesta |
|---|---|---|
| 1 | **1** | Suenan Isaac (1000) y José (1001). Contesta José |
| 2 | **2** | Entra a la cola. Contesta Leonardo (2001) o Omar no, porque es él quien llama. Contesta Leonardo |
| 3 | **3** | Ernesto (3001) |
| 4 | **4** | Anthony (4001) |
| 5 | **0** | Isaac (1000), como operadora |
| 6 | **8**, y otra vez **8** cuando lo pida | Isaac (1000), después del segundo error |
| 7 | No marca nada | Isaac (1000), después de los reintentos |

**Resultado esperado.** Cada opción llega a quien dice la tabla. **Captura** Omar, de al menos una llamada en el menú.

#### Prueba 14 · Grupo de timbrado (EXT-06)

| Paso | Quién | Qué hace |
|---|---|---|
| 1 | Leonardo (2001) | Marca **8000** |
| 2 | Isaac (1000) y José (1001) | Sus teléfonos suenan al mismo tiempo. **Contesta José** |

**Resultado esperado.** Suenan los dos a la vez y al contestar José la 1000 deja de sonar. **Captura** José, con el celular sonando.

#### Prueba 15 · Cola con tres llamadas (EXT-07)

| Paso | Quién | Qué hace |
|---|---|---|
| 1 | Leonardo (2001) y Omar (2002) | Tienen Linphone abierto. Son los agentes y van a contestar |
| 2 | José (1001), Ernesto (3001) y Romeo (5001) | Cuando Isaac diga "ya", los tres marcan **8010** al mismo tiempo |
| 3 | Leonardo y Omar | Contestan la llamada que les llegue |
| 4 | El tercero que llamó | Se queda escuchando música y el anuncio de su posición. No cuelga |
| 5 | Leonardo u Omar | Cuando termine su llamada, cuelga y le entra la del tercero |

**Resultado esperado.** Se escucha el aviso de grabación, la cola reparte las llamadas entre los dos agentes y la tercera espera su turno. **Captura** Romeo, o quien quede en espera.

#### Prueba 16 · Fuera de horario (EXT-08)

| Paso | Quién | Qué hace |
|---|---|---|
| 1 | Isaac (1000) | Marca **\*271** para pasar a modo fuera de horario |
| 2 | Reginaldo (3002) | Marca **7000**, escucha el mensaje de fuera de horario y marca **3** |
| 3 | Ernesto (3001) | Contesta la llamada de emergencia |
| 4 | Isaac | Marca **\*271** otra vez para volver al horario normal |

**Resultado esperado.** El 7000 responde con el mensaje de fuera de horario y la opción 3 llega a Enfermería. **Captura** Reginaldo.

#### Prueba 17 · Llamadas entre celulares (L2, L4, L5, L6)

Son cuatro llamadas, una después de otra.

| Paso | Quién llama | Marca | Quién contesta |
|---|---|---|---|
| 1 | Omar (2002) | **3002** | Reginaldo |
| 2 | Romeo (5001) | **4001** | Anthony |
| 3 | Ernesto (3001) | **5001** | Romeo |
| 4 | Anthony (4001) | **1001** | José |

**Resultado esperado.** Audio en los dos sentidos en las cuatro. Cada quien califica el audio de 1 a 5.

#### Prueba 18 · Acceso desde red pública, E1 (EXT-02)

| Paso | Quién | Qué hace |
|---|---|---|
| 1 | Isaac | Apaga el Wi-Fi del iPhone y deja solo datos móviles, con Tailscale y Linphone (5002) abiertos |
| 2 | Isaac (1000) | Desde la laptop marca **5002** |
| 3 | Isaac (5002) | Contesta en el iPhone |

**Resultado esperado.** Audio en los dos sentidos por datos móviles. **Captura** Isaac, del iPhone sin Wi-Fi y en llamada.

#### Prueba 19 · Evidencias de la PBX

| Paso | Quién | Qué hace |
|---|---|---|
| 1 | Isaac | Captura *Reports → CDR Reports* con todas las llamadas de la sesión |

#### Prueba 20 · Seguridad, intentos de contraseña (SEG-04)

Va al final porque deja bloqueado el equipo de Romeo un rato.

| Paso | Quién | Qué hace |
|---|---|---|
| 1 | Romeo (5001) | En Linphone cambia su contraseña por una incorrecta y fuerza el registro 5 o 6 veces |
| 2 | Isaac | Revisa en la PBX que la IP de Tailscale de Romeo aparece bloqueada y la desbloquea |
| 3 | Romeo | Vuelve a poner la contraseña correcta y confirma que queda en verde |

**Resultado esperado.** La PBX bloquea el equipo de Romeo después de los intentos fallidos. **Captura** Romeo, del error de registro.

### 6.4 Resumen de participación

Para que cada uno sepa en qué pruebas tiene que estar atento.

| Integrante | Pruebas |
|---|---|
| Isaac (1000 y 5002) | Todas |
| José (1001) | 1, 2, 8, 13, 14, 15, 17 |
| Leonardo (2001) | 1, 2, 3, 4, 5, 7, 9, 11, 12, 13, 14, 15 |
| Omar (2002) | 1, 6, 9, 12, 13, 15, 17 |
| Ernesto (3001) | 1, 2, 5, 6, 9, 11, 13, 15, 16, 17 |
| Reginaldo (3002) | 1, 8, 16, 17 |
| Anthony (4001) | 1, 2, 7, 10, 13, 17 |
| Romeo (5001) | 1, 2, 15, 17, 20 |

> **Pruebas que esperan al router.** Las llamadas **entre VLAN** (TER-05) y las mediciones de **QoS** se hacen el día de la integración, con los teléfonos conectados a la red del router en lugar de Tailscale.

---

## 7. Recomendaciones de uso

- **Mantener Linphone abierto en pantalla** durante las pruebas. Con un servidor propio, iOS y la mayoría de Android no notifican llamadas entrantes cuando la aplicación está en segundo plano, y la extensión se desconecta.
- Usar **auriculares** en llamadas entre equipos cercanos, para evitar el eco y el acople.
- Calificar la calidad de audio de cada llamada de **1 a 5** y anotarla en la matriz (TER-06).
- Con datos móviles, el retardo de la red celular más el túnel ronda los 150 a 200 ms. Si el audio se corta, buscar mejor señal.

---

## 8. Solución de problemas

| Síntoma | Causa probable | Acción |
|---|---|---|
| Linphone queda en rojo o "Error" | Tailscale desconectado, o la laptop con la PBX apagada | Activar Tailscale y confirmar con el responsable técnico que la VM está en ejecución |
| "Forbidden" o "401 Unauthorized" | Contraseña o extensión incorrecta | Revisar los datos. Tras **5 intentos fallidos en 10 minutos**, la PBX bloquea ese equipo durante 30 minutos |
| Al llamar sale "Servicio no disponible" | La extensión de destino no está registrada | Pedir al otro integrante que abra su softphone y espere a que esté en verde |
| Se escucha en un solo sentido | Pérdida de paquetes de audio o la app en segundo plano | Mantener la app en pantalla y probar de nuevo con mejor señal |
| En Android la extensión se desconecta sola | Ahorro de batería cerrando Linphone o Tailscale | Aplicar los ajustes adicionales de Android (sección 4.1) |
| No aparece **cmh-pbx** en Tailscale | Sesión iniciada con otra cuenta | Cerrar sesión en Tailscale y entrar con la cuenta del proyecto |
| La extensión se desconecta al registrarla en otro equipo | La misma extensión está en dos dispositivos | Dejarla configurada en un solo dispositivo |

---

## 9. Seguridad de la cuenta compartida

- La cuenta de Google del proyecto se usa **solo en la aplicación Tailscale**. No se agrega al correo ni a otras aplicaciones del celular.
- Su contraseña no se comparte por el chat del grupo ni se guarda en notas sin protección.
- Cada equipo conectado aparece en la consola de Tailscale. El responsable técnico puede **desconectar cualquier equipo** desde ahí si se pierde un teléfono.
- Al finalizar el proyecto se cierran las sesiones, se retiran los equipos de la consola y se cambia la contraseña de la cuenta (§11 del PDF, uso responsable de recursos en la nube).
