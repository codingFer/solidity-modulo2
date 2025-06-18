// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Declaración del contrato de subasta
contract Subasta {
    // Dirección del dueño del contrato (quien lo despliega)
    address public owner;

    // Dirección del ganador actual
    address public ganador;

    // Monto de la oferta ganadora
    uint256 public ofertaGanadora;

    // Tiempo en que finaliza la subasta
    uint256 public finSubasta;

    // Indica si la subasta ya fue finalizada
    bool public finalizada;

    // Constante que representa 10 minutos (para extender la subasta)
    uint256 public constanteTiempo = 10 minutes;

    // Porcentaje mínimo (5%) por el cual una nueva oferta debe superar la anterior
    uint256 public porcentajeMinimoIncremento = 5;

    // Estructura para guardar cada oferta
    struct Oferta {
        address oferente;
        uint256 monto;
    }

    // Mapeo para registrar cuánto ha depositado cada dirección
    mapping(address => uint256) public depositos;

    // Mapeo que guarda el historial de ofertas de cada dirección
    mapping(address => Oferta[]) public historialOfertas;

    // Lista de todas las direcciones que han ofertado
    address[] public oferentes;

    // Evento emitido cuando se hace una nueva oferta válida
    event NuevaOferta(address indexed oferente, uint256 monto);

    // Evento emitido cuando se finaliza la subasta
    event SubastaFinalizada(address ganador, uint256 monto);

    // Modificador para restringir funciones solo mientras la subasta esté activa
    modifier soloMientrasActiva() {
        require(block.timestamp < finSubasta && !finalizada, "La subasta no esta activa");
        _;
    }

    // Modificador para permitir solo al dueño ejecutar ciertas funciones
    modifier soloOwner() {
        require(msg.sender == owner, "Solo el propietario puede ejecutar esta funcion");
        _;
    }

    // Constructor que inicializa la subasta con una duración en minutos
    constructor(uint256 duracionEnMinutos) {
        owner = msg.sender; // Asigna el dueño del contrato
        finSubasta = block.timestamp + duracionEnMinutos * 1 minutes; // Calcula la hora de finalización
    }

    // Función para hacer una oferta
    function ofertar() external payable soloMientrasActiva {
        require(msg.value > 0, "Debes enviar ETH para ofertar");

        // Calcula el total ofertado hasta ahora por esta persona (incluyendo esta oferta)
        uint256 nuevaOferta = msg.value;

        // Requiere que la nueva oferta sea al menos un 5% mayor a la actual
        require(
            nuevaOferta >= ofertaGanadora + (ofertaGanadora * porcentajeMinimoIncremento) / 100 || ofertaGanadora == 0,
            "La oferta debe superar al menos en 5% la oferta actual"
        );

        // Si es su primera oferta, lo agregamos a la lista de oferentes
        if (historialOfertas[msg.sender].length == 0) {
            oferentes.push(msg.sender);
        }

        // Guardamos la oferta en su historial
        historialOfertas[msg.sender].push(Oferta(msg.sender, msg.value));

        // Actualizamos su depósito total
        depositos[msg.sender] = nuevaOferta;

        // Se convierte en el nuevo ganador
        ganador = msg.sender;
        ofertaGanadora = nuevaOferta;

        // Si la oferta se hace en los últimos 10 minutos, extendemos la subasta
        if (block.timestamp > finSubasta - constanteTiempo) {
            finSubasta += constanteTiempo;
        }

        // Emitimos evento de nueva oferta
        emit NuevaOferta(msg.sender, nuevaOferta);
    }

    // Devuelve la dirección del ganador y el monto de su oferta
    function mostrarGanador() external view returns (address, uint256) {
        return (ganador, ofertaGanadora);
    }

    // Devuelve el historial de ofertas de una dirección
    function mostrarOfertas(address usuario) external view returns (Oferta[] memory) {
        return historialOfertas[usuario];
    }

    function imprimirHistorial() public view returns (Oferta[] memory) {
        // Crear un array para almacenar todas las ofertas
        uint totalOfertas = 0;
        for (uint i = 0; i < oferentes.length; i++) {
            totalOfertas += historialOfertas[oferentes[i]].length;
        }

        Oferta[] memory todasLasOfertas = new Oferta[](totalOfertas);
        uint index = 0;

        for (uint i = 0; i < oferentes.length; i++) {
            address dir = oferentes[i];
            for (uint j = 0; j < historialOfertas[dir].length; j++) {
                todasLasOfertas[index] = historialOfertas[dir][j];
                index++;
            }
        }

        return todasLasOfertas;
    }

    // Permite a un usuario retirar el exceso de ETH que ya no es parte de su última oferta válida
    function retirarExceso() external {
        // El historial de ofertas del usuario
        Oferta[] storage ofertas = historialOfertas[msg.sender];
        require(ofertas.length > 1, "No hay ofertas anteriores para retirar");

        uint256 exceso = 0;

        // Sumar todas las ofertas anteriores a la última
        for (uint256 i = 0; i < ofertas.length - 1; i++) {
            exceso += ofertas[i].monto;
        }

        require(exceso > 0, "No hay exceso disponible");

        // Restar el exceso del total depositado
        depositos[msg.sender] -= exceso;

        // Borrar las ofertas anteriores (opcional: para evitar múltiples retiros)
        // Guardar la última oferta antes de borrar todo
        Oferta memory ultima = ofertas[ofertas.length - 1];

        // Eliminar todas las ofertas del historial
        delete historialOfertas[msg.sender];

        // Conservar únicamente la última oferta
        historialOfertas[msg.sender].push(ultima);

        // Enviar el exceso al usuario
        payable(msg.sender).transfer(exceso);
    }   


    // Finaliza la subasta (solo el dueño puede hacerlo)
    function finalizarSubasta() external soloOwner {
        require(!finalizada, "Subasta ya finalizada");
        require(block.timestamp >= finSubasta, "Subasta aun no termina");

        finalizada = true;

        // Calculamos una comisión del 2%
        uint256 comision = (ofertaGanadora * 2) / 100;

        // Enviamos la comisión al dueño
        payable(owner).transfer(comision);

        // Transferimos el resto de la oferta ganadora al ganador
        payable(ganador).transfer(ofertaGanadora - comision);

        // Devolvemos el depósito a todos los oferentes no ganadores
        for (uint256 i = 0; i < oferentes.length; i++) {
            address participante = oferentes[i];

            if (participante != ganador && depositos[participante] > 0) {
                payable(participante).transfer(depositos[participante]);
                depositos[participante] = 0; // Reseteamos su saldo
            }
        }

        // Emitimos evento de subasta finalizada
        emit SubastaFinalizada(ganador, ofertaGanadora);
    }
    
     //Ver el tiempo para el fin de la subasta en minutos
    function verFinSubastaMin() public view  returns (uint256) {

        
        // Convertir en minutos
        return finSubasta / 60;
    }
}
