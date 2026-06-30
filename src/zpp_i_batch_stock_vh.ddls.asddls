@EndUserText.label: 'Malzeme Parti Stokları VH'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.dataCategory: #VALUE_HELP
@ObjectModel.representativeKey: 'Batch'
@ObjectModel.supportedCapabilities: [#VALUE_HELP_PROVIDER]

@Search.searchable: true
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

      @EndUserText.label: 'Malzeme'
      @UI.lineItem: [{ position: 10, label: 'Malzeme' }]
  key _matStock.Material                            as Product,

      @EndUserText.label: 'Depo Yeri'
      @UI.lineItem: [{ position: 20, label: 'Depo Yeri' }]
  key _matStock.StorageLocation                     as StorageLocation,

      @EndUserText.label: 'Parti'
      @Search.defaultSearchElement: true
      @UI.lineItem: [{ position: 30, label: 'Parti' }]
  key _matStock.Batch                               as Batch,

      @EndUserText.label: 'Malzeme Tanımı'
      //      @Semantics.text: true
      @UI.lineItem: [{ position: 40, label: 'Malzeme Tanımı' }]
      max( _ProductText.ProductName )               as ProductName,

      @EndUserText.label: 'Stok Miktarı'
      @Semantics.quantity.unitOfMeasure: 'MaterialBaseUnit'
      @UI.lineItem: [{ position: 50, label: 'Stok Miktarı' }]
      sum( _matStock.MatlWrhsStkQtyInMatlBaseUnit ) as StockQty,

      @EndUserText.label: 'Temel Ölçü Birimi'
      @UI.lineItem: [{ position: 60, label: 'Ölçü Birimi' }]
      _matStock.MaterialBaseUnit                    as MaterialBaseUnit

}
where
      _matStock.Batch                        is not initial
//  and _matStock.MatlWrhsStkQtyInMatlBaseUnit > 0
  and _matStock.InventoryStockType = '01'

group by
  _matStock.Material,
  _matStock.StorageLocation,
  _matStock.Batch,
  _matStock.MaterialBaseUnit
