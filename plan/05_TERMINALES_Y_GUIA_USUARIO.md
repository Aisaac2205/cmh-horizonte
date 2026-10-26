# 05 · Terminales (softphones) y guía rápida de usuario
**Responsable:** Terminales y experiencia de usuario
**Criterio:** E (10 pts) + RN-02 y RN-06 · **Tiempo estimado:** 2–3 h
**Se puede adelantar YA:** instalar las aplicaciones, probarlas contra una copia de la VM en casa y redactar la guía.

---

## 1. Asignación de terminales

| Ext. | Integrante | Dispositivo | Aplicación | Conexión | VLAN |
|---|---|---|---|---|---|
| 1000 | Isaac Sarceño | Laptop host | MicroSIP | Cable a un puerto LAN del AP | 20 VOZ |
| 1001 | José Arnaldo | Celular | Linphone | Wi-Fi CMH-Voz | 20 VOZ |
| 2001 | Leonardo Zepeda | Celular | Linphone / Zoiper | Wi-Fi CMH-Voz | 20 VOZ |
| 2002 | Omar Godoy | Celular (Android) | Linphone | Wi-Fi CMH-Voz | 20 VOZ |
| 3001 | Ernesto Grijalva | Celular | Zoiper | Wi-Fi CMH-Voz | 20 VOZ |
| 3002 | Reginaldo | Celular | Linphone | Wi-Fi CMH-Voz | 20 VOZ |
| 4001 | Anthony | Laptop (o celular) | MicroSIP o Linphone | Cable ether4 | 30 ADMIN |
| 5001 | Romeo | Laptop (o celular) | MicroSIP o Linphone | Cable ether3 | 10 GESTION |
| 5002 | Isaac Sarceño | Celular (datos móviles) | Linphone + Tailscale | Internet | E1 |

> **19/10.** Asignación por integrante, configuración remota por Tailscale y pruebas por persona en `GUIA-CELULARES.md`. Las columnas *Conexión* y *VLAN* aplican el día de la integración con el hEX RB750Gr3 y el AP Mercusys MW325R (un solo Wi-Fi, `CMH-Voz`, en la VLAN 20). La 4001 y la 5001 van en una laptop por cable para tener terminales en ADMIN y GESTION. Si Anthony o Romeo no llevan laptop, otro integrante la usa con esa extensión. Hasta entonces, todos se conectan por Tailscale con el dominio `100.91.176.16`. Las llamadas entre VLAN (TER-05) se hacen entre los celulares (VLAN 20) y las laptops conectadas por cable a Gestión (VLAN 10) o Administrativa (VLAN 30).

Datos comunes para todos: **Servidor/Dominio:** `172.16.20.10` · **Puerto:** 5060 · **Transporte:** UDP · **Usuario y autenticación:** el número de extensión · **Contraseña:** la del gestor de contraseñas.

---

## 2. Configuración por aplicación

### 2.1 MicroSIP (Windows), recomendado para laptops
1. Descargar de microsip.org (versión instalable o portable).
2. Menú ▾ → **Agregar cuenta**:
   | Campo | Valor |
   |---|---|
   | Nombre de cuenta | `CMH 1000` |
   | Servidor SIP | `172.16.20.10` |
   | Usuario | `1000` |
   | Dominio | `172.16.20.10` |
   | Login | `1000` |
   | Contraseña | (secret de la extensión) |
   | Nombre a mostrar | `Operadora Recepcion` |
   | Transporte | UDP |
3. Menú → **Configuración**: códecs **G.711 u-law, G.711 a-law, G.722** (quitar los demás) · DTMF: **RFC 2833** · Desactivar *Video*.
4. El ícono queda verde = registrado.
5. **Firewall de Windows**: permitir MicroSIP en redes privadas cuando lo pregunte.

### 2.2 Linphone (Android / iOS / Windows)
1. Abrir la app → **Usar una cuenta SIP** (no "crear cuenta Linphone").
2. Usuario `2001`, contraseña, dominio `172.16.20.10`, transporte **UDP**.
3. Ajustes → Audio → Códecs: activar **PCMU, PCMA, G722, opus**; desactivar los demás.
4. Ajustes → Red: desactivar *IPv6* si da problemas; activar **Keep alive**.
5. **Android:** Ajustes del teléfono → Batería → Linphone → **Sin restricciones** (si no, se duerme y no recibe llamadas).

### 2.3 Zoiper (Android / iOS)
1. **Ya tengo una cuenta** → usuario `3001@172.16.20.10` y contraseña.
2. Hostname `172.16.20.10` → *Skip* en proxy → elegir **SIP UDP**.
3. Settings → Audio → Codecs: G.711 u-law/a-law, G.722.

### 2.4 Verificación del registro
En la PBX:
```bash
asterisk -rx "pjsip show contacts"
```
- [ ] **≥ 4 extensiones `Avail` a la vez**, incluyendo **al menos 1 laptop y 1 móvil** (requisito §5.7). Captura obligatoria.

---

## 3. Matriz de llamadas entre tipos de terminal y VLAN

| # | Origen | Destino | Tipo | VLAN origen → destino | Audio bidireccional |
|---|---|---|---|---|---|
| L1 | 1000 laptop | 2001 móvil | Escritorio ↔ móvil | 30 → 20 | [ ] |
| L2 | 2002 laptop | 3002 laptop | Escritorio ↔ escritorio | 30 → 30 | [ ] |
| L3 | 1001 móvil | 3001 móvil | Móvil ↔ móvil | 20 → 20 | [ ] |
| L4 | 5001 laptop | 4001 PC | Escritorio ↔ escritorio | 10 → 30 | [ ] |
| L5 | 3001 móvil | 5001 laptop | Móvil ↔ escritorio | 20 → 10 | [ ] |
| L6 | 4001 PC | 1001 móvil | Escritorio ↔ móvil | 30 → 20 | [ ] |
| L7 | 5002 móvil remoto | 1000 laptop | Remoto ↔ escritorio (E1) | Internet → 30 | [ ] |

En cada llamada: hablar 30 s, confirmar que **ambos se escuchan**, calificar la calidad del audio (1–5) y anotarla. Captura del softphone en llamada + CDR.

---

## 4. Guía rápida de usuario final (1 página, anexo del informe)

> Copiar, ajustar con capturas de las aplicaciones reales y exportar a PDF en **una sola página**.

---

### 📞 Centro Médico Horizonte: cómo usar su teléfono en la computadora o el celular

**1. Configure su teléfono (solo la primera vez)**
- En la **computadora**, abra *MicroSIP*. En el **celular**, abra *Linphone*.
- Escriba los datos que le entregó TI: **su número de extensión**, **su contraseña** y el **servidor** `172.16.20.10`.
- Cuando el indicador esté **en verde**, ya puede llamar y recibir llamadas.
- En el celular, conéctese a la red Wi-Fi **CMH-Voz**.

**2. Llamar a un compañero**
- Marque los **4 números** de su extensión y presione el botón verde.
  | Área | Números |
  |---|---|
  | Recepción (operadora) | **1000** |
  | Consulta Externa | 2001, 2002 |
  | Enfermería y Emergencias | 3001, 3002 |
  | Administración | 4001 |
  | TI | 5001 |

**3. Poner una llamada en espera**
- Presione **Espera** (⏸). La otra persona escuchará música.
- Para continuar, presione **Reanudar** (▶).

**4. Pasar (transferir) una llamada**
- **Transferir directo:** presione **Transferir**, marque la extensión y confirme.
- **Avisar antes de transferir:** ponga la llamada en **Espera**, llame a su compañero, avísele, y luego presione **Transferir**.

**5. Escuchar sus mensajes de voz**
- Marque **\*97** y escriba su **PIN**.
- Presione **1** para escuchar sus mensajes.
- Para cambiar su saludo: **0** y siga las instrucciones.

**6. ¿Problemas?**
- Si el indicador está en **rojo**, revise que esté conectado al Wi-Fi correcto.
- Llame a **TI: 5001**.
- **Nunca** comparta su contraseña.

---

## Lista de verificación final (Terminales)
- [ ] MicroSIP, Linphone y Zoiper configurados y documentados (capturas sin contraseñas)
- [ ] ≥ 4 extensiones registradas a la vez (laptop + móvil) con captura de `pjsip show contacts`
- [ ] Llamadas L1–L6 con audio bidireccional; L7 cuando esté E1
- [ ] Calidad de audio calificada en cada prueba
- [ ] Guía rápida de 1 página revisada por alguien no técnico
