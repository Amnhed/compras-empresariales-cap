namespace sap.compras;
using { cuid, managed } from '@sap/cds/common';

// CABECERA: Datos generales del documento
entity OrdenesCompra : cuid, managed {
    folio       : String(20) not null;
    estado      : String(30) default 'Pendiente';
    
    // La magia de la Composición:
    posiciones  : Composition of many Posiciones on posiciones.orden = $self;
    
    // Campo Virtual: No se guarda en el disco duro, se calcula al vuelo
    virtual importeTotal : Decimal(15, 2);
}

// DETALLE: Los artículos dentro de la orden
entity Posiciones : cuid {
    orden          : Association to OrdenesCompra; // Relación hacia arriba
    material       : String(100) not null;
    cantidad       : Integer not null;
    precioUnitario : Decimal(10, 2) not null;
}