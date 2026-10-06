using { ComprasService as service } from './compras-service';

// Anotaciones de UI. Fiori Elements las lee en $metadata y arma la lista y el registro.
// No hay controlador UI5: la pantalla sale de estas declaraciones.

annotate service.OrdenesCompra with @(
    UI.HeaderInfo : {
        TypeName : 'Orden de compra',
        TypeNamePlural : 'Órdenes de compra',
        Title : { Value : folio }
    },
    UI.SelectionFields : [
        folio,
        estado
    ],
    UI.LineItem : [
        { Value : folio, Label : 'Folio' },
        { Value : estado, Label : 'Estado' },
        { Value : importeTotal, Label : 'Importe total' },
        { Value : createdAt, Label : 'Fecha creación' },
        {
            $Type : 'UI.DataFieldForAction',
            Action : 'ComprasService.aprobar',
            Label : 'Aprobar',
            Inline : true
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action : 'ComprasService.rechazar',
            Label : 'Rechazar',
            Inline : true
        }
    ],
    UI.Identification : [
        {
            $Type : 'UI.DataFieldForAction',
            Action : 'ComprasService.aprobar',
            Label : 'Aprobar'
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action : 'ComprasService.rechazar',
            Label : 'Rechazar'
        }
    ],
    UI.FieldGroup #Cabecera : {
        Data : [
            { Value : folio, Label : 'Folio' },
            { Value : estado, Label : 'Estado' },
            { Value : importeTotal, Label : 'Importe total' }
        ]
    },
    UI.Facets : [
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'Datos generales',
            Target : '@UI.FieldGroup#Cabecera'
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'Artículos',
            Target : 'posiciones/@UI.LineItem'
        }
    ]
);

annotate service.OrdenesCompra with {
    // El handler asigna el estado. El usuario no lo escribe en el registro.
    estado @Common.FieldControl : #ReadOnly;
    // Se calcula al leer. En el formulario no es editable.
    importeTotal @Common.FieldControl : #ReadOnly;
};

annotate service.Posiciones with @(
    UI.LineItem : [
        { Value : material, Label : 'Material' },
        { Value : cantidad, Label : 'Cantidad' },
        { Value : precioUnitario, Label : 'Precio unitario' }
    ],
    UI.HeaderInfo : {
        TypeName : 'Artículo',
        TypeNamePlural : 'Artículos',
        Title : { Value : material }
    }
);
