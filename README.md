# 🧾 Trabajo Final - Módulo 2  
## Subasta: Smart Contract

Debes crear un smart contract y desplegarlo desde tu propia dirección.

---

## 🎯 Requisitos Generales

Cada smart contract debe estar:

- ✅ Publicado en la red **Sepolia**.  
- ✅ Verificado (con el código fuente accesible).  

La URL del contrato publicado y verificado deben incluirse en esta sección:  
**TRABAJO FINAL MÓDULO 2**

También se debe incluir una URL del repositorio público en **GitHub**.

---

## ⚙️ Funcionalidades Requeridas

### 📦 Constructor  
Inicializa la subasta con los parámetros necesarios para su funcionamiento.

### 🏷️ Función para ofertar  
Permite a los participantes ofertar por el artículo.  
Una oferta es válida si:
- Es mayor en **al menos 5%** que la mayor oferta actual.
- Se realiza **mientras la subasta está activa**.

### 🥇 Mostrar ganador  
Devuelve el oferente ganador y el valor de la oferta ganadora.

### 📜 Mostrar ofertas  
Devuelve la lista de oferentes y sus respectivos montos ofrecidos.

### 💸 Devolver depósitos  
Al finalizar la subasta:
- Se devuelve el depósito a los oferentes no ganadores.
- Se descuenta una comisión del **2%**.

### 💰 Manejo de depósitos  
Las ofertas deben:
- Ser **depositadas en el contrato**.
- Estar **asociadas a las direcciones** de los oferentes.

### 📢 Eventos requeridos
- **Nueva Oferta**: Emitido cuando se realiza una nueva oferta.
- **Subasta Finalizada**: Emitido cuando finaliza
