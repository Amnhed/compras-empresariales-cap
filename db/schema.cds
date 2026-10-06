// Modelo de dominio. CAP lee este archivo y crea las tablas en SQLite.
// Aquí no hay URLs ni pantallas: solo qué se guarda y cómo se relacionan las entidades.
namespace sap.compras;

using { cuid, managed } from '@sap/cds/common';

// Cabecera de la orden.
// cuid agrega la clave ID (UUID). managed agrega createdAt, createdBy, modifiedAt y modifiedBy.
entity OrdenesCompra : cuid, managed {
    folio       : String(20) not null;
    // Pendiente es solo el valor inicial. El handler de CREATE lo reemplaza al guardar.
    estado      : String(30) default 'Pendiente';

    // Composición: las posiciones no existen sin su orden.
    // Si se borra la orden, CAP borra también sus posiciones.
    posiciones  : Composition of many Posiciones on posiciones.orden = $self;

    // Virtual: no tiene columna en la base. El after READ lo calcula al responder.
    virtual importeTotal : Decimal(15, 2);
}

// Detalle de la orden. Cada fila es un artículo.
entity Posiciones : cuid {
    // Asociación hacia la cabecera. El lado "muchos" de la composición.
    orden          : Association to OrdenesCompra;
    material       : String(100) not null;
    cantidad       : Integer not null;
    precioUnitario : Decimal(10, 2) not null;
}
