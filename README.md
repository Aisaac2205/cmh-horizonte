# CMH Horizonte · Proyecto final de Telecomunicaciones I

Central telefónica IP (PBX) con VLAN, QoS y acceso seguro para el **Centro Médico Horizonte, S.A.**, la empresa ficticia del enunciado **PF-TEL-001-2026**. Universidad Mariano Gálvez, Campus Jutiapa.

> **Este repositorio tiene solo la documentación.** Las contraseñas, la máquina virtual y los archivos de trabajo no se suben (ver [Lo que no está aquí](#lo-que-no-está-aquí)).

## Fechas clave

| Qué | Cuándo |
|---|---|
| Hito H3: QoS, seguridad, extras y matriz de pruebas | 15 al 21 de octubre |
| Hito H4: informe final, ensayo y carga | 22 al 28 de octubre |
| **Entrega en Canvas** (PDF del informe y comprimido de anexos) | **Miércoles 28 de octubre de 2026, 23:30**. Solo la sube el coordinador |
| Presentación y demostración | En la fecha que calendarice el catedrático, después de la entrega |

Si la documentación no está cargada a tiempo, el proyecto **no se presenta** (§10 del PDF).

## Por dónde empezar

| Si quieres... | Lee |
|---|---|
| Ver todo lo que se configuró, con capturas y qué se hizo en cada una | [`GUIA-DEMO.md`](GUIA-DEMO.md) |
| Tu extensión, cómo configurar tu celular o laptop y qué pruebas te tocan | [`GUIA-CELULARES.md`](GUIA-CELULARES.md) |
| Encender la VM, rutas de FreePBX, comandos y reparación rápida | [`CONFIG.md`](CONFIG.md) |
| Saber cómo vamos frente a la rúbrica y qué falta | [`CONFIG.md`](CONFIG.md), secciones 11 y 12 |
| Tu rol, tus tareas y el cronograma | [`plan/00_INDICE_Y_CRONOGRAMA.md`](plan/00_INDICE_Y_CRONOGRAMA.md) |
| El diseño de la red: VLAN, direcciones y plan de numeración | [`plan/01_DISENO_DE_LA_SOLUCION.md`](plan/01_DISENO_DE_LA_SOLUCION.md) |

## Estructura

```
cmh-horizonte/
├── README.md        Esta portada
├── GUIA-DEMO.md     Documentación de lo realizado (PBX, E1, router y AP) con capturas
├── GUIA-CELULARES.md  Extensión de cada integrante, configuración de Tailscale y Linphone, y pruebas por persona
├── CONFIG.md        Operación de la PBX: encender, rutas, comandos, respaldos, estado y pendientes
├── PRUEBAS-ENTREGA.md  Pruebas de VLAN, ACL, llamadas, QoS y extras para el día de la entrega
├── CHECKLIST-SABADO.md Orden para armar, probar y capturar en la réplica del 31/10
├── capturas/        Capturas de FreePBX, del hEX, del AP y de las sesiones de prueba (sin contraseñas)
├── pruebas/         Scripts de prueba y captura (Probar-Vlan, Evidencia-Router, Captura) y sus resultados
└── plan/            Plan del grupo, validado contra el PDF
    ├── 00  Índice, roles y cronograma
    ├── 01  Diseño de la solución (investigación, VLAN, IP, numeración)
    ├── 02  Router MikroTik hEX (RB750Gr3) y AP Mercusys MW325R
    ├── 03  Instalación de la PBX (FreePBX)
    ├── 04  Funcionalidades de la PBX
    ├── 05  Terminales y guía de usuario
    ├── 06  QoS y mediciones
    ├── 07  Seguridad
    ├── 08  Extras E1, E3 y E4
    ├── 09  Pruebas y trazabilidad
    └── 10  Documentación y presentación
```

## La solución en breve

- **Red.** Un router físico **MikroTik RB750Gr3 (hEX)** separa la red en VLAN: 10 Gestión, 20 Voz, 30 Administrativa y 40 Invitados. Un punto de acceso **Mercusys MW325R** da el Wi-Fi para los celulares. Controla quién habla con quién (firewall entre VLAN) y le da prioridad a la voz (QoS, marcado EF).
- **PBX.** **FreePBX 17.0.33 con Asterisk 22.11** sobre Debian 12.15, en una máquina virtual de VirtualBox. En la integración queda en la VLAN de Voz con la IP **172.16.20.10**.
- **Telefonía.** 9 extensiones de 4 dígitos, IVR en español (marcando **7000**), grupo de timbrado **8000**, cola **8010**, condiciones de horario y 4 buzones con saludo personalizado.
- **Teléfonos.** MicroSIP en laptops y Linphone en celulares.
- **Extras.** E1 acceso desde red pública con Tailscale, E3 troncal SIP con sip2sip y E4 funciones avanzadas. E2 (SDN) no se implementa.

## Estado al 27/10

- **La PBX está completa.** Extensiones, IVR, buzones, firewall, respaldos y sistema al día. Redes del firewall y de SIP ya en clase B.
- **Extras listos:** E1 (Tailscale), E3 (troncal sip2sip, entrante al IVR y saliente con 9100) y E4 (5 de 5, incluido el buzón por correo).
- **Router y AP:** migrados a clase B (172.16.0.0/12) el 26/10, con el celular por USB como WAN. Llamadas entre VLAN, matriz de ACL (8 de 8 desde Voz y 11 de 11 desde Admin) y QoS bajo congestión (0 % de pérdida de voz con QoS y 9,4 % sin QoS) probadas.
- **Por hacer:** réplica del 31/10 con las capturas de Winbox en clase B ([`CHECKLIST-SABADO.md`](CHECKLIST-SABADO.md)), informe y presentación.

El detalle por criterio está en [`CONFIG.md`, sección 11](CONFIG.md#11-estado-frente-al-pdf).

## Lo que no está aquí

Lo maneja el responsable técnico del grupo en la laptop que corre la VM. Si lo necesitas, pídelo por un canal privado, nunca por el chat del grupo.

| Archivo | Por qué no se sube |
|---|---|
| `CREDENCIALES-ACTUALES.md` | Tiene todas las contraseñas (§11 del PDF) |
| `CMH-FreePBX-final.ova` | La VM completa. Pesa unos 5.7 GB y lleva contraseñas |
| `router/` | Scripts del router con las contraseñas de Wi-Fi. La configuración está explicada en `plan/02` y `plan/06` |
| `respaldos/` | Respaldos de FreePBX, con las contraseñas de las extensiones |
| `audios/` | Audios del IVR, música en espera y saludos. Ya están cargados en la PBX |
| `.iso` y `crear-vm-cmh.ps1` | Instalación de la VM desde cero |

## Si vas a correr la VM en tu laptop

1. Instala **VirtualBox 7.2.x** desde https://www.virtualbox.org/wiki/Downloads. Necesitas 8 GB de RAM o más y unos 35 GB libres.
2. **Archivo → Importar servicio virtualizado** → `CMH-FreePBX-final.ova`.
3. En **Configuración → Red**, pon el **adaptador 1** en *Adaptador puente* a tu Wi-Fi o Ethernet. El adaptador 2 no se toca.
4. Enciende la VM y abre **http://127.0.0.1:18080/admin**. Comandos y rutas en [`CONFIG.md`](CONFIG.md).

Si la VM va muy lenta, revisa si Windows tiene activo su propio hipervisor (*Integridad de memoria*, Hyper-V, WSL2 o Docker Desktop). Con eso VirtualBox corre en modo de compatibilidad. Se puede bajar la VM a 2 CPU con la VM apagada, o desactivar *Seguridad de Windows → Seguridad del dispositivo → Aislamiento del núcleo → Integridad de memoria* y reiniciar.

## Reglas del grupo

- **Ninguna contraseña** en el repositorio, en el informe, en los anexos ni en las capturas (§11 del PDF).
- Las capturas de evidencia llevan el **reloj de Windows visible**.
- Se puede usar IA como apoyo, pero **cada integrante debe poder explicar cualquier parte** del proyecto en la defensa (§11 del PDF).
- Cualquier cambio en la PBX se avisa al grupo y se documenta con captura en `GUIA-DEMO.md`.
