# 08 · Componentes extra: E1, E3 y E4 (hasta 17 pts)
**Responsable:** Componentes extra · **Apoyo:** Telefonía y Seguridad
**Requisito:** la calificación base debe estar completa (§6).
**E2 (SDN): no se implementa** por decisión del grupo; en la trazabilidad RN-09 queda como "no implementado" con su justificación.

**Se puede adelantar YA (cuentas y materiales):**
- [ ] Cuenta de **Tailscale** del proyecto (con Google o GitHub del grupo) **con 2FA**. *(cuenta creada el 19/10 con el Google del proyecto. Confirmar que tenga verificación en dos pasos)*
- [ ] **Dos** cuentas en **sip2sip.info** (una para la troncal y otra para el "teléfono externo" de prueba).
- [ ] Cuenta **Gmail** del proyecto con 2FA y **contraseña de aplicación** (para el buzón por correo).
- [x] 1–2 pistas de **música libre de derechos** (por ejemplo, de la biblioteca de audio de YouTube) en MP3/WAV. *(hecho 17/10)*
- [x] Grabaciones `ivr-fuera-horario` y `aviso-grabacion` (textos en el archivo 04). *(hecho 17/10)*

---

## E1 · Conectividad desde una red pública (8 pts) con Tailscale

**Mecanismo:** VPN de usuario hacia el servidor (admitido en §6.1). Tailscale crea un túnel WireGuard cifrado entre el celular y la VM de FreePBX. **No se abren puertos en el router** y funciona aunque el proveedor de internet use CGNAT.

### Paso 1. Activar Tailscale en la VM de FreePBX
Tailscale **ya viene instalado** en la VM, así que no hace falta el `curl` de instalación. Solo se activa:
```bash
sudo tailscale up
```
(Si se instaló la VM desde cero sin Tailscale: `curl -fsSL https://tailscale.com/install.sh | sh` y luego `tailscale up`.)
- Abrir el enlace que aparece, iniciar sesión con la cuenta del proyecto y autorizar el equipo.
- Ver la IP asignada: `tailscale ip -4` → anotarla (por ejemplo `100.101.102.103`).
- En la consola web de Tailscale (**Machines**), en el equipo `cmh-pbx` → **Disable key expiry** (para que no se desconecte el día de la demo).

### Paso 2. Ajustes en FreePBX
- [x] **Asterisk SIP Settings → Local Networks** incluye `100.64.0.0/10` (hecho en el archivo 03). *(hecho 17/10)*
- [x] **Firewall → Interfaces**: `tailscale0` en zona **Local** (puede usar SIP, **no** la administración web). *(hecho 19/10)*
- [x] Apply Config. *(hecho 19/10, el firewall aplica solo)*

### Paso 3. Restringir con la política de Tailscale (endurecimiento)
Consola de Tailscale → **Access Controls**. Reemplazar la política por:
```json
{
  "tagOwners": {
    "tag:pbx": ["autogroup:admin"]
  },
  "grants": [
    {
      "src": ["autogroup:member"],
      "dst": ["tag:pbx"],
      "ip":  ["udp:5060", "udp:10000-20000"]
    },
    {
      "src": ["tag:pbx"],
      "dst": ["autogroup:member"],
      "ip":  ["udp:*"]
    }
  ]
}
```
Luego, en la VM: `tailscale up --advertise-tags=tag:pbx --reset` (si pide reautenticar, aceptar).
Resultado: los dispositivos remotos **solo** pueden hablar SIP y RTP con la PBX (no SSH, no web).

### Paso 4. Celular remoto (extensión 5002)
1. Instalar la app **Tailscale** e iniciar sesión con la cuenta del proyecto.
2. **Apagar el Wi-Fi** y usar **datos móviles** (red distinta = requisito).
3. En Linphone: cuenta `5002`, dominio = **IP de Tailscale de la PBX** (`100.x.y.z`), transporte UDP.
4. Llamar a 1000 (laptop interna) y luego de 1000 a 5002. **Audio bidireccional en ambas.**

### Evidencias E1
- [ ] Captura del celular con datos móviles (sin Wi-Fi) en llamada.
- [x] `tailscale status` en la VM (muestra el celular conectado). *(hecho 19/10, ver `DOCUMENTACION.md` sección 7 y `CONFIG.md` sección 6)*
- [x] `asterisk -rx "pjsip show contacts"` → 5002 con dirección `100.x.y.z`. *(hecho 19/10, la 5002 se registró desde 100.68.20.81, ver `DOCUMENTACION.md` sección 7)*
- [ ] CDR de las llamadas 5002 ↔ 1000. *(19/10: 5002 → 1000 hecha, captura 24. Falta 1000 → 5002)*
- [ ] Captura de la política de acceso de Tailscale.

### Análisis de riesgos E1 (requisito de documentación)
| Riesgo | Mitigación |
|---|---|
| Robo de la cuenta de Tailscale | 2FA obligatoria; solo los integrantes tienen acceso |
| Dispositivo remoto perdido | Desautorizarlo desde la consola de Tailscale (revocación inmediata) |
| El túnel evita el firewall del router | Política de Tailscale (solo SIP/RTP) + firewall de FreePBX (zona Local, sin web) |
| Dependencia de un servicio externo | Alternativa documentada: WireGuard en el hEX con redirección de puertos si existe IP pública |
| Calidad de la red celular | Códec Opus o G.711 según la cobertura; medir jitter con `pjsip show channelstats` |

---

## E3 · Troncal SIP y rutas de entrada y salida (5 pts) con sip2sip.info

> La disponibilidad de los proveedores gratuitos cambia. Si sip2sip no funciona, usen el servicio SIP de Linphone (sip.linphone.org) con los mismos pasos.

### Paso 1. Cuentas
- **Cuenta A** (troncal), por ejemplo `cmh_troncal@sip2sip.info`.
- **Cuenta B** ("teléfono externo"), por ejemplo `cmh_externo@sip2sip.info`. Se registra **directo** a sip2sip en Linphone, en un celular **con datos móviles** (fuera de la red del proyecto).

### Paso 2. Crear la troncal en FreePBX
**Connectivity → Trunks → Add Trunk → Add SIP (chan_pjsip) Trunk**

| Pestaña | Campo | Valor |
|---|---|---|
| General | Trunk Name | `sip2sip` |
| General | Outbound CallerID | `cmh_troncal` |
| General | Maximum Channels | `2` |
| pjsip Settings → General | Username / Auth username | usuario de la cuenta A |
| | Secret | contraseña de la cuenta A |
| | Authentication | Outbound |
| | Registration | Send |
| | SIP Server | `sip2sip.info` |
| | SIP Server Port | `5060` |
| | Context | `from-pstn` |
| | Transport | `0.0.0.0-udp` |
| pjsip Settings → Advanced | From Domain | `sip2sip.info` |
| | From User | usuario de la cuenta A |
| | Qualify Frequency | `60` (mantiene abierto el NAT) |
| | Rewrite Contact / RTP Symmetric / Force rport | **Yes** |
| pjsip Settings → Codecs | | ulaw, alaw, g722, opus |

**Submit → Apply Config.** Verificar:
```bash
asterisk -rx "pjsip show registrations"
```
Debe decir **Registered**.

> Si la troncal registra pero las **llamadas entrantes** no llegan, revisar `/var/log/asterisk/full`. Es común que sip2sip envíe el INVITE desde un servidor con IP distinta a la del registro y FreePBX lo rechace como anónimo. En ese caso agregar esas IP en la troncal → **pjsip Settings → Advanced → Match (Permit)**.

### Paso 3. Ruta de salida (prefijo 9)
**Connectivity → Outbound Routes → Add**
- Route Name: `Externas-sip2sip`
- Dial Patterns: **prefix** `9` · **match pattern** `.` (cualquier cosa después del 9)
- Trunk Sequence: `sip2sip`
- Prueba: desde 1000 marcar **`9cmh_externo`** (MicroSIP y Linphone permiten letras) → suena el celular de la cuenta B.

### Paso 4. Ruta de entrada
**Connectivity → Inbound Routes → Add**
- Description: `Entrada-sip2sip`
- DID Number: vacío (cualquiera) o el usuario de la cuenta A
- Destination: **Time Conditions → TC-Horario** (con E4) o **IVR → IVR-Principal**
- Prueba: desde la cuenta B llamar a `cmh_troncal@sip2sip.info` → escucha el IVR → marca 1 → contesta 1000.

### Evidencias E3
- [ ] `pjsip show registrations` = Registered.
- [ ] Llamada de salida 1000 → cuenta B (captura + CDR con la troncal).
- [ ] Llamada de entrada cuenta B → IVR → extensión (captura + CDR).
- [ ] **Limitaciones documentadas:** doble NAT (hEX + router de casa), dependencia del proveedor gratuito, calidad variable, imposibilidad de llamar a la red telefónica pública sin un proveedor de pago, y por qué no se usó SIP ALG.

---

## E4 · Funciones avanzadas (4 pts; mínimo 2, implementamos las 5 de la §6.4)

> En el PDF, "grupos de timbrado **y** colas" es **una sola** función. Las 5 funciones de la §6.4 son: (1) grupos de timbrado y colas, (2) grabación de llamadas, (3) música en espera personalizada, (4) condiciones horarias y (5) buzón por correo. Como los puntos son proporcionales, la grabación (E4.6) es **obligatoria** en este plan.

### E4.1 Grupo de timbrado 8000 (Recepción)
**Applications → Ring Groups → Add**
- Ring-Group Number `8000` · Description `Recepcion`
- Extension List: `1000`, `1001` · Ring Strategy: **ringall** · Ring Time: 20
- Destination if no answer: **Voicemail → 1000 (unavailable)**
- Prueba: llamar al 8000 → suenan 1000 y 1001 a la vez.

### E4.2 Cola de llamadas 8010 (Consulta Externa)
**Applications → Queues → Add**
- Queue Number `8010` · Queue Name `Consulta-Externa`
- Static Agents: `2001,0` y `2002,0`
- Ring Strategy: **rrmemory** (reparto rotativo con memoria). Justificar: distribuye la carga entre clínicas.
- Music on Hold Class: `CMH` (E4.4) · Join Announcement: `aviso-grabacion`
- Announce Position: Yes · Max Wait Time: 120 s · Fail Over Destination: Voicemail 1000
- Prueba: 3 llamadas simultáneas al 8010 → se reparten entre 2001 y 2002; la tercera espera con música y escucha su posición.

**Actualizar el IVR (archivo 04):** opción 1 → Ring Group 8000 · opción 2 → Queue 8010.

### E4.3 Condiciones horarias
1. **Applications → Time Groups → Add** `Horario-Atencion`:
   - Lunes–Viernes 07:00–19:00
   - Sábado 07:00–12:00
2. **Applications → IVR → Add** `IVR-FueraHorario`: Announcement `ivr-fuera-horario`; opción 3 → 3001 (Emergencias); opción 1 → Voicemail 1000.
3. **Applications → Time Conditions → Add** `TC-Horario`:
   - Time Group: `Horario-Atencion`
   - Destination if time matches: **IVR-Principal**
   - Destination if time does not match: **IVR-FueraHorario**
   - Anotar el **código de anulación** (*Override Code*, por ejemplo `*271`) para la demostración.
4. Cambiar destinos: la ruta de entrada (E3) y el **7000** (Misc Application) → **Time Conditions → TC-Horario**.
5. Prueba: llamar al 7000 en horario (IVR normal) → marcar el código de anulación → llamar al 7000 (IVR fuera de horario) → volver a marcar el código para restaurar.

### E4.4 Música en espera personalizada
**Settings → Music on Hold → Add Category** `CMH` → subir las pistas → usarla en la cola 8010 y en las extensiones (Advanced → Music on Hold = CMH).
- Prueba: poner en espera una llamada → se escucha la música personalizada.

### E4.5 Buzón de voz por correo electrónico
1. En la VM, configurar Postfix para enviar por Gmail (contraseña de aplicación, **nunca** la contraseña real):
```bash
apt -y install postfix libsasl2-modules mailutils
```
Agregar al final de `/etc/postfix/main.cf`:
```
relayhost = [smtp.gmail.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
```
Crear `/etc/postfix/sasl_passwd`:
```
[smtp.gmail.com]:587 cuenta.proyecto@gmail.com:CONTRASENA_DE_APLICACION
```
```bash
chmod 600 /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd
systemctl restart postfix
echo "Prueba de correo CMH" | mail -s "Prueba FreePBX" correo.destino@gmail.com
```
2. **Settings → Voicemail Admin → Settings**: *Server Email* = la cuenta del proyecto; *Attach* = yes.
3. En las extensiones con buzón → Voicemail → **Email Address** y **Email Attachment = Yes**.
- Prueba: dejar un mensaje a 1000 → llega el correo con el audio adjunto (captura con la hora).

### E4.6 Grabación de llamadas con acceso restringido (obligatoria, cuenta como 1 de las 5)
- Extensión 1000 → **Advanced → Recording Options**: Inbound/Outbound Internal = **Force**.
- Las grabaciones se escuchan en **Reports → CDR Reports** (ícono de reproducir) o **Reports → Call Recordings**, solo accesible para administradores desde GESTION (firewall).
- Se anuncia con `aviso-grabacion` en la cola (buena práctica legal). Documentar la restricción de acceso.

### Evidencias E4
- [ ] Captura de configuración + prueba demostrada de cada función.
- [ ] CDR de las llamadas al grupo y a la cola.
- [ ] Correo recibido con el mensaje de voz adjunto.

---

## Lista de verificación final (Extras)
- [ ] E1: llamadas remotas con datos móviles + registros + análisis de riesgos
- [ ] E3: troncal registrada, salida con prefijo 9, entrada al IVR, limitaciones documentadas
- [ ] E4: ring group y cola, grabación de llamadas, condiciones horarias, música personalizada y buzón por correo (las 5 de la §6.4)
- [ ] E2: justificación escrita de por qué no se implementó (RN-09)
