using { sap.compras as db } from '../db/schema';

service ComprasService {
    entity OrdenesCompra as projection on db.OrdenesCompra;
    entity Posiciones as projection on db.Posiciones;
}