@EndUserText.label: 'Malzeme Parti Stokları VH'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.dataCategory: #VALUE_HELP
@ObjectModel.representativeKey: 'Batch'
@ObjectModel.supportedCapabilities: [#VALUE_HELP_PROVIDER]


//@Search.searchable: true
@UI.presentationVariant: [
  {
    sortOrder: [
      {
        by: 'Batch',
        direction: #ASC
      }
    ]
  }
]

define view entity ZPP_I_BATCH_STOCK_VH
  as select from I_MaterialStock_2 as _matStock

  association [0..1] to I_ProductText as _ProductText on  _matStock.Material    = _ProductText.Product
                                                      and _ProductText.Language = $session.system_language

{
      @Search.defaultSearchElement: true
      @Consumption.filter.mandatory: true
      @Consumption.filter.selectionType: #SINGLE
  key _matStock.Material as Product,
      @Consumption.filter.mandatory: true
      @Consumption.filter.selectionType: #SINGLE
  key _matStock.StorageLocation                     as StorageLocation,
  key _matStock.Batch                               as Batch,

      max( _ProductText.ProductName )               as ProductName,

      @Semantics.quantity.unitOfMeasure: 'MaterialBaseUnit'
      sum( _matStock.MatlWrhsStkQtyInMatlBaseUnit ) as StockQty,

      _matStock.MaterialBaseUnit                    as MaterialBaseUnit
}
where
      _matStock.Batch              is not initial
  and _matStock.InventoryStockType = '01'

group by
  _matStock.Material,
  _matStock.StorageLocation,
  _matStock.Batch,
  _matStock.MaterialBaseUnit
having
  sum( _matStock.MatlWrhsStkQtyInMatlBaseUnit ) > 0
