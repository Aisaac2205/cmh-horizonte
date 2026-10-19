# GUÍA TELÉFONOS · Extensiones del equipo con Tailscale y Linphone
**Centro Médico Horizonte, S.A. · PF-TEL-001-2026**
Última actualización: 19/10/2026

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

Duración estimada de 50 minutos. Todos conectados a una videollamada para coordinar, con Tailscale activo y Linphone abierto en pantalla. Isaac anuncia cada prueba.

| # | Prueba | Quién llama | Quién contesta o actúa |
|---|---|---|---|
| 1 | Todos registrados (TER-01) | Cada uno abre su softphone | Isaac captura Asterisk Info |
| 2 | Marcación entre áreas (FUN-01) | 1000 → 2001, Ernesto → 4001, Romeo → 1001 | Leonardo, Anthony y José |
| 3 | Espera desde laptop (FUN-02) | 1000 → 2001 | Isaac pone en espera y reanuda |
| 4 | Espera desde móvil (FUN-03) | 1000 → 2001 | Leonardo pone en pausa y reanuda |
| 5 | Segunda llamada (FUN-04) | 1000 en llamada con 2001, Ernesto → 1000 | Isaac alterna entre las dos |
| 6 | Transferencia ciega T1 (FUN-05) | Ernesto → 1000 | Isaac `##` → 2002, contesta Omar |
| 7 | Transferencia atendida T2 (FUN-06) | Anthony → 1000 | Isaac `*2` → 2001, consulta con Leonardo y completa |
| 8 | Transferencia ciega T3 (FUN-07) | 1000 → 1001 | José `##` → 3002, contesta Reginaldo |
| 9 | Transferencia atendida T4 (FUN-08) | Omar → 2001 | Leonardo `*2` → 3001, consulta con Ernesto y completa |
| 10 | Buzón sin respuesta (FUN-09) | Anthony → 1000 | Isaac no contesta, Anthony deja mensaje |
| 11 | Buzón ocupado (FUN-10) | Isaac \*71 y llama a 2001, Ernesto → 1000 | Saludo de ocupado. Al final Isaac \*70 |
| 12 | Consultar buzones (FUN-11) | Omar → 2001 sin respuesta | Leonardo y luego Isaac escuchan con \*97 |
| 13 | Recorrido del IVR (FUN-12 a 16) | Omar → 7000 | Contestan según la opción |
| 14 | Grupo de timbrado (EXT-06) | Leonardo → 8000 | Suenan 1000 y 1001 |
| 15 | Cola con 3 llamadas (EXT-07) | José, Ernesto y Romeo → 8010 a la vez | Leonardo y Omar contestan, la tercera espera |
| 16 | Fuera de horario (EXT-08) | Isaac \*271, Reginaldo → 7000 → 3 | Ernesto. Al final Isaac \*271 |
| 17 | Llamadas entre terminales (L2, L4, L5, L6) | Omar → 3002, Romeo → 4001, Ernesto → 5001, Anthony → 1001 | Reginaldo, Anthony, Romeo y José |
| 18 | E1 desde red pública (EXT-02) | 1000 → 5002 | Isaac en el iPhone con datos móviles |
| 19 | Evidencias finales | | Isaac captura el CDR con todas las llamadas |
| 20 | Seguridad (SEG-04) | Romeo con contraseña incorrecta | Isaac confirma el bloqueo y lo libera |

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
