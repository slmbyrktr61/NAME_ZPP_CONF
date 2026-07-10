@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Teyit Bileşen Projection Entity'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZPP_C_CONF_I
  as projection on ZPP_I_CONF_I
{
  key ItemUuid,
      ConfUuid,
      ItemNo,

      @Consumption.valueHelpDefinition: [
        {
          entity: {
            name: 'ZI_PRODUCT_VH',
            element: 'Product'
          },
          additionalBinding: [
            {
              localElement: 'ComponentDescription',
              element: 'ProductName',
              usage: #RESULT
            },
            {
              localElement: 'Unit',
              element: 'BaseUnit',
              usage: #RESULT
            },
            {
              localElement: 'StorageLocation',
              element: 'StorageLoc',
              usage: #RESULT
            }
          ]
        }
      ]
      ComponentMaterial,

      ComponentDescription,
      StorageLocation,

            @Consumption.valueHelpDefinition: [
              {
              
                entity: {
                  name: 'ZPP_I_BATCH_STOCK_VH',
                  element: 'Batch'
                }
//                additionalBinding: [
//                  {
//                    localElement: 'ComponentMaterial',
//                    element: 'Product',
//                    usage: #FILTER_AND_RESULT
//                  },
//                  {
//                    localElement: 'StorageLocation',
//                    element: 'StorageLocation',
//                    usage: #FILTER_AND_RESULT
//                  }
//                ]
              }
            ]
      Batch,

      @Semantics.quantity.unitOfMeasure: 'Unit'
      Quantity,

      Unit,
      CarCount,

      @Semantics.quantity.unitOfMeasure: 'Unit'
      ActualStockQuantity,

      HideActualStockQuantity,

      BomItemCat,

      IsBatchMngmntRequired,

      LocalLastChangedAt,

      _Header : redirected to parent ZPP_C_CONF_H
}
