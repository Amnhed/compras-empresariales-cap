using { sap.compras as db } from '../db/schema';

// Proyección: el cliente OData ve este servicio, no las tablas de db/ de forma directa.
// CAP genera el CRUD en /odata/v4/compras/. Las acciones no son CRUD: son operaciones de negocio.
service ComprasService {
    entity OrdenesCompra as projection on db.OrdenesCompra actions {
        // Ligadas a una orden concreta: POST .../OrdenesCompra(<id>)/ComprasService.aprobar
        action aprobar();
        action rechazar();
    };
    entity Posiciones as projection on db.Posiciones;
}
