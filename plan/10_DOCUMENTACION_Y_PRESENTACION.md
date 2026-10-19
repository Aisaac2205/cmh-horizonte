# 10 · Documentación, evidencias, presentación y entrega
**Responsables:** Documentación y calidad + Coordinador (carga en Canvas)
**Criterios:** G (12 pts) y H (5 pts, ajustable individualmente)
**Se puede empezar YA:** plantilla del informe, investigación (archivo 01), bitácora y carpeta de evidencias.

---

## 1. Carpeta compartida (Drive)

```
CMH-ProyectoFinal/
├── 00-Plan/                 ← estos archivos .md
├── 01-Investigacion/        ← fuentes, comparativas (criterio A)
├── 02-Diagramas/            ← .drawio y .png
├── 03-Evidencias/
│   ├── RED/  PBX/  FUN/  TER/  QOS/  SEG/  EXT/
├── 04-Respaldos/            ← /export del router, backup de FreePBX (SIN contraseñas)
├── 05-Audios/               ← grabaciones del IVR, música en espera
├── 06-Informe/              ← borradores y PDF final
├── 07-Presentacion/         ← diapositivas y video de respaldo
└── Bitacora.xlsx
```

## 2. Reglas para las evidencias (§8.1, sección 7)
1. **Fecha y hora visibles** en cada captura: dejar a la vista el reloj de la barra de tareas de Windows o del celular.
2. **Contraseñas ocultas:** tapar secrets, PIN, claves Wi-Fi y tokens antes de guardar.
3. **Nombre del archivo:** `E-<ÁREA>-<NN>_<descripcion>_<AAAAMMDD-HHMM>.png`
   Ejemplo: `E-FUN-06_transferencia-atendida-4001-2001_20261019-1530.png`
4. El **ID de la evidencia** se anota en la matriz de pruebas (archivo 09).
5. Cada captura lleva un pie de figura en el informe: *"Figura 12. Transferencia atendida de 4001 a 2001 (CDR)"*.

## 3. Bitácora de trabajo (anexo obligatorio)

| Fecha | Hito | Integrante | Rol | Actividad realizada | Horas | Evidencia / resultado |
|---|---|---|---|---|---|---|
| 15/10 | H2 | | Telefonía | Instalación de Debian 12 + FreePBX 17 | 2 | E-PBX-01 |
| | | | | | | |

> El criterio H puede ajustarse **individualmente** según la bitácora. Cada integrante registra sus propios aportes **el mismo día**.

---

## 4. Estructura del informe técnico (PDF), sección por sección

| # | Sección (§8.1) | Responsable | Fuente en este plan | Contenido clave |
|---|---|---|---|---|
| 1 | Portada | Documentación | — | Universidad, Facultad, Campus, Curso, Grupo, integrantes (nombre, carné, rol), fecha, catedrático |
| 2 | Resumen ejecutivo | Coordinador | Todo | **1 página, sin tecnicismos**: el problema del cliente, qué se implementó, beneficios, cómo se usa |
| 3 | Descripción general | Documentación | 00, 01 | Objetivo, alcance realizado (base + E1/E3/E4), modalidad local, herramientas y **versiones** |
| 4 | Investigación y alternativas | Documentación | 01 §1 | Matrices comparativas, criterios, justificación, costos referenciales |
| 5 | Diseño | Red + QoS | 01 | Diagramas lógico y físico, VLAN, direccionamiento, numeración, matriz entre VLAN, política de QoS, ancho de banda |
| 6 | Implementación | Cada rol | 02–08 | Decisiones y parámetros clave **explicados** (no tutorial). Ej.: por qué Direct Media = No, por qué marcar en `forward`, por qué SIP ALG desactivado |
| 7 | Evidencias gráficas | Todos | 03-Evidencias | Capturas con fecha y hora, sin credenciales |
| 8 | Pruebas y verificación | Documentación | 09 §1, 06 §6, 07 §2 | Matriz de pruebas, tabla y gráfico de QoS, pruebas de seguridad |
| 9 | Componentes extra | Extras | 08 | E1, E3, E4 con evidencia; E2 no implementado (justificación breve) |
| 10 | Trazabilidad | Documentación | 09 §2 | RN-01 a RN-10 → prueba → evidencia |
| 11 | Riesgos, limitaciones y lecciones | Seguridad + todos | 07 §3 | Problemas encontrados y cómo se resolvieron |
| 12 | Conclusiones y recomendaciones | Coordinador | — | Técnicas + dirigidas al cliente (SRTP/TLS, UPS, crecimiento a 31 usuarios, SDN a futuro) |
| 13 | Referencias (APA 7) | Documentación | — | RFC 3261, 3550, 2474, 3246, 4594, 6716; IEEE 802.1Q; ITU-T G.114 y G.711; documentación de MikroTik, FreePBX y Tailscale |

**Anexos (archivo ZIP aparte):**
- [ ] Guía rápida de usuario (1 página), del archivo 05 §4
- [ ] `cmh-rb4011-export.rsc` (sin contraseñas)
- [ ] Respaldo de FreePBX o documentación de configuración (credenciales retiradas)
- [ ] Bitácora de trabajo
- [ ] Diagramas `.drawio`

### Frases útiles para justificar decisiones (adaptar)
- *"Se eligió la modalidad local porque permite medir la QoS dentro de la red del cliente y evita costos recurrentes; el acceso remoto se resolvió con una VPN de usuario sin exponer puertos."*
- *"La marcación DSCP la realiza el router con base en IP y puertos, porque los softphones móviles no marcan de forma confiable; además impide que las visitas se autoasignen prioridad."*
- *"Se deshabilitó el SIP ALG porque reescribe los mensajes SIP de forma incompatible con el manejo de NAT de Asterisk."*

---

## 5. Presentación y demostración (≈ 20 min, participan los 9)

### 5.1 Guion sugerido
| Min | Bloque | Presenta | Qué se muestra |
|---|---|---|---|
| 0:00–1:30 | El cliente y su problema | Coordinador | Red plana, llamadas perdidas; objetivos |
| 1:30–3:00 | Investigación y decisión | Documentación | Matriz de modalidades y plataformas |
| 3:00–5:30 | Diseño y red | Red y VLAN | Diagrama, VLAN, matriz de ACL. **En vivo:** el invitado no ve la red interna |
| 5:30–7:00 | Seguridad | Seguridad | Endurecimiento. **En vivo:** bloqueo por fail2ban o la web de la PBX inaccesible desde ADMIN |
| 7:00–8:30 | PBX | Telefonía | Interfaz de FreePBX, extensiones, plan de numeración, códecs, CDR |
| 8:30–11:30 | Funcionalidades | Funcionalidades | **En vivo:** llamar al 7000 (IVR), espera, transferencia ciega y atendida, buzón |
| 11:30–13:00 | Terminales | Terminales | **En vivo:** llamada móvil ↔ laptop entre VLAN; guía de usuario |
| 13:00–15:30 | QoS | QoS | Tabla y gráfico con/sin QoS. **En vivo** (si da tiempo): saturar y llamar |
| 15:30–18:30 | Extras | Extras | **En vivo:** celular con datos móviles (E1), llamada externa por la troncal (E3), cola y condición horaria (E4) |
| 18:30–20:00 | Cierre | Coordinador | Beneficios para el cliente, lecciones, recomendaciones |

Después vienen las **preguntas del catedrático a integrantes al azar**. Todos deben poder explicar cualquier parte.

### 5.2 Preguntas probables (practicar)
- ¿Qué pasa si un invitado marca su tráfico como EF?
- ¿Por qué el audio de una llamada entre dos celulares de la VLAN de voz no pasa por las colas del router?
- ¿Cuánto ancho de banda usa una llamada G.711 y cómo se calcula?
- ¿Qué diferencia hay entre transferencia ciega y atendida a nivel de SIP (REFER)?
- ¿Por qué se deshabilitó el SIP ALG? ¿Qué es el NAT traversal?
- ¿Cómo se evita que alguien administre la PBX desde la red administrativa?
- ¿Qué haría falta para escalar a los 31 colaboradores?
- ¿Por qué Tailscale y no redirección de puertos?
- ¿Por qué la pérdida de paquetes se midió en la PBX y no en la laptop que hizo la llamada de eco?
- ¿Para qué sirve el puerto interno de gestión de la VM y por qué no rompe la regla de administrar solo desde Gestión?

### 5.3 Video de respaldo (grabar el jueves 22 o el viernes 23)
Grabar con OBS (pantalla + audio) o con el celular, de 3 a 6 minutos:
- [ ] Recorrido del IVR y transferencia atendida
- [ ] Buzón: dejar y escuchar un mensaje
- [ ] Llamada desde datos móviles (E1)
- [ ] Prueba de QoS sin/con (Winbox + softphone)
- [ ] Llamada externa por la troncal (E3)

### 5.4 Lista para el día de la demostración
- [ ] RB4011, fuente, 6 cables, regleta
- [ ] Laptop host con la VM **encendida 15 min antes** (y `.ova` de respaldo en otra laptop)
- [ ] Laptops y celulares **cargados**, softphones registrados (`pjsip show contacts`)
- [ ] Celular E1 con **datos móviles** y Tailscale conectado
- [ ] Suspensión y ahorro de energía **desactivados** en la laptop host
- [ ] Video de respaldo en una USB y en Drive
- [ ] Router de la universidad o hotspot para internet en ether1 (verificar antes)

---

## 6. Entrega en Canvas (el coordinador)

| Archivo | Contenido |
|---|---|
| `PF-TEL-001-2026_GrupoX_Informe.pdf` | Informe técnico completo |
| `PF-TEL-001-2026_GrupoX_Anexos.zip` | Guía, respaldos sin contraseñas, bitácora, diagramas |

- [ ] Revisión final por 2 integrantes: ortografía, numeración de figuras, **ninguna contraseña visible**
- [ ] Carga **el miércoles 28 antes de las 20:00** (límite: 23:30)
- [ ] Captura del comprobante de carga, compartida en el grupo

> **Condición indispensable:** ningún proyecto se presenta si la documentación no fue cargada a tiempo por el coordinador (§10).
