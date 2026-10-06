using { sap.compras as db } from '../db/schema';

// Proyección: el cliente OData ve este servicio, no las tablas de db/ de forma directa.
// CAP genera el CRUD en /odata/v4/compras/. Las acciones no son CRUD: son operaciones de negocio.
// requires corta la petición si no hay usuario. restrict decide qué puede hacer cada rol.
service ComprasService @(requires: 'authenticated-user') {
    // El borrador deja llenar folio y artículos antes de validar.
    // Guardar activa el borrador y entonces corre el before CREATE.
    @odata.draft.enabled
    @(restrict: [
        { grant: ['READ'], to: ['Comprador', 'Aprobador'] },
        { grant: ['CREATE', 'UPDATE', 'DELETE'], to: ['Comprador'] },
        { grant: ['aprobar', 'rechazar'], to: ['Aprobador'] }
    ])
    entity OrdenesCompra as projection on db.OrdenesCompra actions {
        // Ligadas a una orden concreta: POST .../OrdenesCompra(<id>)/ComprasService.aprobar
        action aprobar();
        action rechazar();
    };

    // Misma regla en el detalle, para que el expand y la tabla de artículos no queden abiertos.
    @(restrict: [
        { grant: ['READ'], to: ['Comprador', 'Aprobador'] },
        { grant: ['CREATE', 'UPDATE', 'DELETE'], to: ['Comprador'] }
    ])
    entity Posiciones as projection on db.Posiciones;
}
