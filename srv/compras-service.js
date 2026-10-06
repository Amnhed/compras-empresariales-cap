const cds = require('@sap/cds');

// Estados que el servicio escribe. El esquema solo declara el campo.
const RETENIDA = 'Retenida - Requiere Revisión';
const APROBADA_AUTO = 'Aprobada Automáticamente';
const APROBADA = 'Aprobada';
const RECHAZADA = 'Rechazada';
const UMBRAL = 15000;

// Una orden cerrada ya no se edita ni se borra.
const EDITABLES = new Set(['Pendiente', RETENIDA]);

module.exports = cds.service.impl(async function () {
    const { OrdenesCompra, Posiciones } = this.entities;

    // before CREATE corre antes del INSERT.
    // En un alta directa, req.data trae folio y posiciones.
    // Con borrador, corre al pulsar Guardar (activación), no al abrir el formulario vacío.
    this.before('CREATE', OrdenesCompra, async (req) => {
        const orden = req.data;
        const posiciones = await posicionesDe(orden, Posiciones);

        if (posiciones.length === 0) {
            return req.reject(400, 'Una orden debe tener artículos.');
        }

        let totalAcumulado = 0;
        for (const item of posiciones) {
            if (Number(item.cantidad) <= 0 || Number(item.precioUnitario) <= 0) {
                return req.reject(400, 'Cantidades y precios deben ser mayores a cero.');
            }
            totalAcumulado += Number(item.cantidad) * Number(item.precioUnitario);
        }

        // El cliente no decide el estado: lo fija esta regla.
        orden.estado = totalAcumulado > UMBRAL ? RETENIDA : APROBADA_AUTO;
    });

    // after READ corre cuando la fila ya se leyó y antes de serializar el JSON.
    // importeTotal no está en SQLite; hay que rellenarlo en cada respuesta.
    this.after('READ', OrdenesCompra, async (ordenes) => {
        const registros = Array.isArray(ordenes) ? ordenes : [ordenes];

        for (const orden of registros) {
            if (!orden) continue;
            const items = Array.isArray(orden.posiciones)
                ? orden.posiciones
                : await SELECT.from(Posiciones).where({ orden_ID: orden.ID });
            const suma = items.reduce((acc, item) => acc + (Number(item.cantidad) * Number(item.precioUnitario)), 0);
            orden.importeTotal = Number(suma.toFixed(2));
        }
    });

    // before UPDATE corre antes del UPDATE en la base.
    // Leemos el estado guardado: req.data puede traer solo los campos que cambiaron.
    this.before('UPDATE', OrdenesCompra, async (req) => {
        await exigirEditable(req, OrdenesCompra, 'editar');
    });

    // before DELETE corre antes del DELETE. La composición borra las posiciones después,
    // si esta validación deja pasar la orden.
    this.before('DELETE', OrdenesCompra, async (req) => {
        await exigirEditable(req, OrdenesCompra, 'borrar');
    });

    // on sustituye la implementación genérica. Una action no tiene INSERT propio:
    // el handler decide el cambio de estado y hace el UPDATE.
    this.on('aprobar', OrdenesCompra, async (req) => {
        await cambiarEstado(req, OrdenesCompra, APROBADA, 'aprobar');
    });

    this.on('rechazar', OrdenesCompra, async (req) => {
        await cambiarEstado(req, OrdenesCompra, RECHAZADA, 'rechazar');
    });
});

// Prefiere las posiciones que vinieron en la petición. Si no vienen, las busca por el ID de la orden.
async function posicionesDe(orden, Posiciones) {
    if (Array.isArray(orden.posiciones) && orden.posiciones.length > 0) {
        return orden.posiciones;
    }
    if (!orden.ID) return [];
    return SELECT.from(Posiciones).where({ orden_ID: orden.ID });
}

// aprobar y rechazar solo aplican a una orden que el alta dejó retenida por monto.
async function cambiarEstado(req, OrdenesCompra, estadoNuevo, accion) {
    const id = req.params?.[0]?.ID || req.params?.[0];
    const actual = await SELECT.one.from(OrdenesCompra).where({ ID: id });
    if (!actual) return req.reject(404, 'Orden no encontrada.');
    if (actual.estado !== RETENIDA) {
        return req.reject(409, `Solo se puede ${accion} una orden retenida.`);
    }
    await UPDATE(OrdenesCompra).set({ estado: estadoNuevo }).where({ ID: id });
}

async function exigirEditable(req, OrdenesCompra, accion) {
    const id = req.data?.ID || req.params?.[0]?.ID || req.params?.[0];
    const actual = await SELECT.one.from(OrdenesCompra).where({ ID: id });
    if (!actual) return req.reject(404, 'Orden no encontrada.');
    if (!EDITABLES.has(actual.estado)) {
        return req.reject(409, `No se puede ${accion} una orden en estado ${actual.estado}.`);
    }
}
