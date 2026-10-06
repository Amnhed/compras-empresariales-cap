const cds = require('@sap/cds');

module.exports = cds.service.impl(async function() {
    
    // EVENTO 1: Antes de crear (guardar) en la base de datos
    this.before('CREATE', 'OrdenesCompra', (req) => {
        const orden = req.data; // Lo que el usuario intenta guardar
        let totalAcumulado = 0;

        if (!orden.posiciones || orden.posiciones.length === 0) {
            return req.error(400, 'Una orden debe tener artículos.');
        }

        // Iteramos sobre las herramientas o equipos que vienen en el JSON
        for (const item of orden.posiciones) {
            if (item.cantidad <= 0 || item.precioUnitario <= 0) {
                return req.error(400, 'Cantidades y precios deben ser mayores a cero.');
            }
            // Multiplicamos cantidad por precio y lo sumamos al total
            totalAcumulado += (item.cantidad * item.precioUnitario);
        }

        // Asignación de estado dinámico según el monto
        if (totalAcumulado > 15000) {
            orden.estado = 'Retenida - Requiere Revisión';
        } else {
            orden.estado = 'Aprobada Automáticamente';
        }
    });

    // EVENTO 2: Después de leer (para llenar el campo virtual)
    this.after('READ', 'OrdenesCompra', async (ordenes) => {
        const registros = Array.isArray(ordenes) ? ordenes : [ordenes];
        const { Posiciones } = this.entities;

        for (const orden of registros) {
            if (!orden) continue;
            // Busca las posiciones de ESTA orden específica
            const items = await SELECT.from(Posiciones).where({ orden_ID: orden.ID });
            // Reduce el array a un solo número (la suma)
            const suma = items.reduce((acc, item) => acc + (item.cantidad * item.precioUnitario), 0);
            orden.importeTotal = Number(suma.toFixed(2));
        }
    });
});