# 04 · Funcionalidades de telefonía (obligatorias)
**Responsable:** Funcionalidades de telefonía · **Apoyo:** Telefonía y Terminales
**Criterio:** D (**18 pts**, el de mayor peso) · **Tiempo estimado:** 3–4 h
**Se puede practicar YA** en una copia de la VM (archivo 03, paso 4).

> Cada función debe demostrarse desde **laptop Y móvil** (§5.4, criterio de calidad). Llenen la matriz de pruebas del archivo 09 a medida que avanzan.

---

## 1. Marcación de 4 dígitos y plan de numeración

Ya queda cubierta al crear las extensiones con los rangos del archivo 01. Además:

- [x] **Admin → Feature Codes**: verificar que estén habilitados: *(hecho 17/10)*
  | Código | Función |
  |---|---|
  | `*97` | Mi buzón de voz |
  | `*98` | Buzón de voz (cualquiera) |
  | `*43` | Prueba de eco (para QoS) |
  | `##` | Transferencia ciega (en llamada) |
  | `*2` | Transferencia atendida (en llamada) |
  | `*70` / `*71` | Activar / desactivar llamada en espera |
- [x] **Settings → Advanced Settings → Asterisk Dial Options**: debe contener `T` y `t` (por ejemplo `Ttr`). Así ambos lados pueden transferir. *(hecho 17/10)*
- [ ] Probar: 1000 → 2001, 3001 → 4001, 5001 → 1001 (llamadas entre áreas).

---

## 2. Llamada en espera (hold) y segunda llamada entrante

### 2.1 Música en espera
- **Settings → Music on Hold**: la categoría `default` ya existe. La música personalizada se agrega en el archivo 08 (E4).

### 2.2 Llamada en espera (call waiting)
- En cada extensión: **Advanced → Call Waiting = Enable** (hecho en el archivo 03).

### 2.3 Prueba (dos escenarios obligatorios)
| Escenario | Pasos | Esperado |
|---|---|---|
| A. Poner en espera y reanudar | 1000 llama a 2001 → 1000 pulsa **Hold** en su softphone → 2001 escucha música → 1000 pulsa **Resume** | Música para quien espera; se retoma la conversación |
| B. Segunda llamada | 1000 habla con 2001 → 3001 llama a 1000 → 1000 escucha el aviso de llamada en espera → contesta (la primera queda en espera) → cambia entre ambas | Gestiona las 2 llamadas |

- [ ] Repetir A y B con un **móvil** como extensión que pone en espera (Linphone: botón *Pausa*).

---

## 3. Transferencia de llamadas

| Tipo | Cómo se hace | Desde laptop (MicroSIP) | Desde móvil (Linphone) |
|---|---|---|---|
| **Ciega** | Durante la llamada marcar `##` + extensión destino, o botón **Transfer** + número | Botón *Transfer* | Botón *Transferir* |
| **Atendida (consultiva)** | Marcar `*2` + extensión → hablar con el destino → colgar para completar | `*2` o *Attended transfer* | Poner en pausa → nueva llamada → *Transferir* a la llamada activa |

### Pruebas obligatorias (con registros de llamada)
| # | Origen | Recibe | Transfiere a | Tipo | Tipos de terminal |
|---|---|---|---|---|---|
| T1 | 3001 (móvil) | 1000 (laptop) | 2002 (laptop) | Ciega | móvil → laptop → laptop |
| T2 | 4001 (PC) | 1000 (laptop) | 2001 (móvil) | Atendida | escritorio → laptop → móvil |
| T3 | 1000 (laptop) | 1001 (móvil) | 3002 (laptop) | Ciega | laptop → móvil → laptop |
| T4 | 2002 (laptop) | 2001 (móvil) | 3001 (móvil) | Atendida | laptop → móvil → móvil |

- [ ] Captura del **CDR** que muestre las transferencias (Reports → CDR Reports).

---

## 4. Buzón de voz (mínimo 2 extensiones; implementamos 4: 1000, 2001, 3001, 4001)

### 4.1 Configuración
- En la extensión → **Voicemail**: Enabled, PIN, *Email Attachment* (para E4).
- El desvío a buzón **cuando está ocupado o no contesta** viene activo por defecto al habilitar el buzón. Verificar en la extensión → **Advanced → Optional Destinations**: *No Answer* y *Busy* → **Voicemail (unavailable / busy)**.
- **Ring Time**: 20 segundos antes de ir al buzón.

### 4.2 Saludo personalizado (desde el teléfono)
1. Desde la extensión 1000 marcar `*97` → ingresar el PIN.
2. Opción **0** (opciones de buzón) → **1** grabar mensaje de *no disponible* → **2** grabar mensaje de *ocupado* → **3** grabar el nombre.
3. Texto sugerido: *"Ha llamado a Recepción del Centro Médico Horizonte. En este momento no podemos atenderle. Deje su nombre, número y motivo de su llamada después del tono. Gracias."*

### 4.3 Pruebas
| Prueba | Pasos | Esperado |
|---|---|---|
| No contesta | 4001 llama a 1000 y nadie contesta 20 s | Escucha el saludo personalizado y deja un mensaje |
| Ocupado | 1000 en llamada; 3001 llama a 1000 con call waiting desactivado (`*71`) | Va al buzón con el saludo de ocupado |
| Escuchar | En 1000 marcar `*97` + PIN → **1** | Reproduce el mensaje |
| Desde otro terminal | Desde 2001 (móvil) marcar `*98` → buzón 1000 → PIN | Reproduce el mensaje |

---

## 5. Menú de voz interactivo (IVR)

### 5.1 Grabaciones (pueden hacerse YA)
Grábenlas con voz clara, en un lugar silencioso, a ritmo pausado. Formato: WAV mono (FreePBX convierte el resto).

| Archivo | Texto |
|---|---|
| `ivr-bienvenida` | "Gracias por llamar al Centro Médico Horizonte. Para Recepción y citas, marque 1. Para Consulta Externa, marque 2. Para Enfermería y Emergencias, marque 3. Para Administración y Contabilidad, marque 4. Para hablar con una operadora, marque 0 o permanezca en la línea." |
| `ivr-invalida` | "La opción que marcó no es válida. Por favor, intente de nuevo." |
| `ivr-fuera-horario` (E4) | "Gracias por llamar al Centro Médico Horizonte. Nuestro horario de atención es de lunes a viernes de siete de la mañana a siete de la noche, y sábados de siete de la mañana a doce del mediodía. Si se trata de una emergencia, marque 3. Para dejarnos un mensaje, marque 1." |
| `aviso-grabacion` (E4) | "Para mejorar nuestro servicio, esta llamada puede ser grabada." |

**Admin → System Recordings → Add Recording** → subir el archivo, o usar **Record via phone** (escribir la extensión, FreePBX llama y graba).

### 5.2 Crear el IVR
**Applications → IVR → Add IVR**
| Campo | Valor |
|---|---|
| IVR Name | `IVR-Principal` |
| Announcement | `ivr-bienvenida` |
| Enable Direct Dial | **Extensions** (permite marcar la extensión directamente) |
| Timeout | 7 segundos |
| Invalid Retries | 2 · Invalid Retry Recording: `ivr-invalida` |
| Invalid Destination | Extension → 1000 (Operadora) |
| Timeout Retries | 1 · Timeout Destination: Extension → 1000 (Operadora) |
| Return to IVR after VM | No |

**Entradas del IVR:**
| Dígito | Destino (base) | Destino con E4 (archivo 08) |
|---|---|---|
| 1 | Extension 1000 | Ring Group 8000 (Recepción) |
| 2 | Extension 2001 | Queue 8010 (Consulta Externa) |
| 3 | Extension 3001 | Extension 3001 |
| 4 | Extension 4001 | Extension 4001 |
| 0 | Extension 1000 (Operadora) | Extension 1000 |

### 5.3 Número interno 7000 para llegar al IVR
**Applications → Misc Applications → Add**: Name `IVR`, Feature Code **7000**, Destination: **IVR → IVR-Principal**. (Con E4, el destino cambia a la condición horaria.)

**Submit → Apply Config.**

### 5.4 Pruebas del IVR (recorrer TODAS las opciones)
| Prueba | Esperado |
|---|---|
| Llamar al 7000 desde la laptop 4001 | Se escucha la bienvenida completa y clara |
| Marcar 1, 2, 3, 4 (una llamada por opción) | Llega a la extensión correcta |
| Marcar 0 | Llega a la operadora 1000 |
| Marcar 8 (inválida) dos veces | Escucha "opción no válida" y luego pasa a la operadora |
| No marcar nada | Tras el tiempo de espera pasa a la operadora |
| Marcar 2002 directo | Llega a la extensión 2002 (direct dial) |
| Repetir desde un **móvil** | Igual |

- [ ] Que un integrante **no técnico** (o un familiar) escuche el IVR y confirme que se entiende (criterio de calidad §5.4). Anotarlo en el informe.

---

## Lista de verificación final (Funcionalidades)
- [ ] Llamadas de 4 dígitos entre las 5 áreas
- [ ] Hold y reanudar + segunda llamada entrante (laptop y móvil)
- [ ] Transferencia ciega y atendida entre tipos de terminal distintos (T1–T4) con CDR
- [ ] Buzón en 4 extensiones con saludo personalizado, desvío por ocupado/no contesta y consulta con PIN *(17/10: saludos instalados en los 4. Falta probar dejar y escuchar un mensaje)*
- [x] IVR con bienvenida en español, 4 opciones + operadora, manejo de inválida y sin respuesta *(hecho 17/10)*
- [ ] Todas las pruebas registradas en la matriz (archivo 09) con evidencia
